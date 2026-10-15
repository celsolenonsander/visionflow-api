package httpapi

import (
	"context"
	"encoding/json"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/go-chi/chi/v5/middleware"
	"github.com/golang-jwt/jwt/v5"

	"github.com/celsolenonsander/visionflow-api/internal/logger"
	"github.com/celsolenonsander/visionflow-api/internal/models"
)

// Auth valida o JWT e injeta userID, tenantID e empresaID no contexto.
func (h *Handler) Auth(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		tokenStr := extractBearerToken(r)
		if tokenStr == "" {
			unauthorized(w, "NAO_AUTENTICADO", "Token ausente.")
			return
		}

		claims, err := h.parseToken(tokenStr)
		if err != nil {
			unauthorized(w, "TOKEN_INVALIDO", "Token inválido ou expirado.")
			return
		}

		userID, err := extractUserID(claims)
		if err != nil {
			unauthorized(w, "TOKEN_INVALIDO", "Token sem sub válido.")
			return
		}

		tenantID, empresaID, err := h.resolveTenantEmpresa(r.Context(), userID)
		if err != nil {
			unauthorized(w, "SEM_EMPRESA", "Usuário sem empresa vinculada.")
			return
		}

		ctx := WithUserContext(r.Context(), userID, tenantID, empresaID)
		next.ServeHTTP(w, r.WithContext(ctx))
	})
}

// LoggingMiddleware registra todas as requisições HTTP.
func LoggingMiddleware(log *logger.Logger) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			start := time.Now()
			ww := middleware.NewWrapResponseWriter(w, r.ProtoMajor)

			next.ServeHTTP(ww, r)

			tenantID, _ := TenantID(r.Context())
			tenant := "-"
			if tenantID > 0 {
				tenant = strconv.Itoa(tenantID)
			}

			log.Printf("%s %s %d %s tenant=%s",
				r.Method,
				r.URL.Path,
				ww.Status(),
				time.Since(start),
				tenant,
			)
		})
	}
}

func extractBearerToken(r *http.Request) string {
	auth := r.Header.Get("Authorization")
	if auth == "" {
		return ""
	}
	parts := strings.SplitN(auth, " ", 2)
	if len(parts) != 2 || !strings.EqualFold(parts[0], "Bearer") {
		return ""
	}
	return strings.TrimSpace(parts[1])
}

func (h *Handler) parseToken(tokenStr string) (jwt.MapClaims, error) {
	token, err := jwt.Parse(tokenStr, func(t *jwt.Token) (interface{}, error) {
		if _, ok := t.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, jwt.ErrSignatureInvalid
		}
		return []byte(h.JWTSecret), nil
	})
	if err != nil {
		return nil, err
	}
	claims, ok := token.Claims.(jwt.MapClaims)
	if !ok || !token.Valid {
		return nil, jwt.ErrTokenInvalidClaims
	}
	return claims, nil
}

func extractUserID(claims jwt.MapClaims) (int, error) {
	sub, ok := claims["sub"]
	if !ok {
		return 0, jwt.ErrTokenInvalidClaims
	}
	switch v := sub.(type) {
	case float64:
		return int(v), nil
	case string:
		return strconv.Atoi(v)
	default:
		return 0, jwt.ErrTokenInvalidClaims
	}
}

// resolveTenantEmpresa consulta usuario_empresa e retorna a empresa padrão
// do usuário. Roda FORA do RLS (usa Pool direto).
func (h *Handler) resolveTenantEmpresa(ctx context.Context, userID int) (int, int, error) {
	const q = `
		SELECT cod_tenant, cod_empresa
		FROM usuario_empresa
		WHERE cod_usuario = $1
		ORDER BY empresa_padrao DESC, cod_empresa ASC
		LIMIT 1
	`
	var tenantID, empresaID int
	err := h.Pool.QueryRow(ctx, q, userID).Scan(&tenantID, &empresaID)
	if err != nil {
		return 0, 0, err
	}
	return tenantID, empresaID, nil
}

func unauthorized(w http.ResponseWriter, code, msg string) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusUnauthorized)
	_ = json.NewEncoder(w).Encode(models.APIResponse{
		Success: false,
		Data:    nil,
		Error:   &models.APIError{Code: code, Message: msg},
	})
}
