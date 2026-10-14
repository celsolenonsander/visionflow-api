package httpapi

import (
	"context"
	"net/http"
	"strings"
	"time"

	"github.com/celsolenonsander/visionflow-api/internal/logger"
	"github.com/go-chi/chi/v5/middleware"
	"github.com/golang-jwt/jwt/v5"
)

type contextKey string

const userContextKey contextKey = "user_id"

type statusResponseWriter struct {
	http.ResponseWriter
	status int
}

func (w *statusResponseWriter) WriteHeader(status int) {
	w.status = status
	w.ResponseWriter.WriteHeader(status)
}

func (w *statusResponseWriter) Write(data []byte) (int, error) {
	if w.status == 0 {
		w.status = http.StatusOK
	}

	return w.ResponseWriter.Write(data)
}

// LoggingMiddleware registra todas as requisições HTTP.
func LoggingMiddleware(log *logger.Logger) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			start := time.Now()
			ww := middleware.NewWrapResponseWriter(w, r.ProtoMajor)

			next.ServeHTTP(ww, r)

			tenant := TenantFromContext(r.Context())
			if tenant == "" {
				tenant = "-"
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

func JWTMiddleware(secret string) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			auth := r.Header.Get("Authorization")

			if !strings.HasPrefix(auth, "Bearer ") {
				bad(
					w,
					http.StatusUnauthorized,
					"TOKEN_AUSENTE",
					"Token Bearer não informado.",
				)
				return
			}

			tokenString := strings.TrimPrefix(auth, "Bearer ")

			token, err := jwt.Parse(
				tokenString,
				func(t *jwt.Token) (interface{}, error) {
					if _, ok := t.Method.(*jwt.SigningMethodHMAC); !ok {
						return nil, jwt.ErrSignatureInvalid
					}

					return []byte(secret), nil
				},
			)

			if err != nil || !token.Valid {
				bad(
					w,
					http.StatusUnauthorized,
					"TOKEN_INVALIDO",
					"Token inválido ou expirado.",
				)
				return
			}

			claims, ok := token.Claims.(jwt.MapClaims)

			if ok {
				ctx := context.WithValue(
					r.Context(),
					userContextKey,
					claims["sub"],
				)

				r = r.WithContext(ctx)
			}

			next.ServeHTTP(w, r)
		})
	}
}
