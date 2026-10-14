package httpapi

import (
	"context"
	"net/http"
	"os"
	"strings"

	"github.com/celsolenonsander/visionflow-api/internal/logger"
	"github.com/celsolenonsander/visionflow-api/internal/service"
	"github.com/go-chi/chi/v5"
	"github.com/go-chi/cors"
)

// Chave usada para guardar o tenant no context da request.
type ctxKey string

const (
	ctxKeyTenant     ctxKey = "tenant"      // subdomínio do tenant (ex: "cliente1")
	ctxKeyTenantHost ctxKey = "tenant_host" // host completo (ex: "cliente1.programadordelphi.com.br")
)

// TenantFromContext devolve o subdomínio do tenant associado à request.
// Retorna string vazia se não houver tenant (ex: chamadas diretas ao api.*).
func TenantFromContext(ctx context.Context) string {
	if v, ok := ctx.Value(ctxKeyTenant).(string); ok {
		return v
	}
	return ""
}

// TenantHostFromContext devolve o host completo associado à request.
func TenantHostFromContext(ctx context.Context) string {
	if v, ok := ctx.Value(ctxKeyTenantHost).(string); ok {
		return v
	}
	return ""
}

// TenantMiddleware identifica o tenant a partir do Host da request.
//
// Ordem de precedência para descobrir o host:
//  1. Header X-Tenant-Host (injetado pelo Cloudflare Worker ao repassar
//     a request para api.programadordelphi.com.br)
//  2. Header X-Forwarded-Host (proxies reversos)
//  3. r.Host (padrão)
//
// O subdomínio é a primeira label do host, exceto quando for "www" ou "api",
// que não representam tenants e portanto são ignorados.
func TenantMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		host := r.Header.Get("X-Tenant-Host")
		if host == "" {
			host = r.Header.Get("X-Forwarded-Host")
		}
		if host == "" {
			host = r.Host
		}

		// Remove porta, se houver.
		if i := strings.Index(host, ":"); i != -1 {
			host = host[:i]
		}
		host = strings.ToLower(strings.TrimSpace(host))

		subdomain := ""
		if host != "" {
			parts := strings.Split(host, ".")
			if len(parts) > 0 {
				first := parts[0]
				// www e api não são tenants.
				if first != "www" && first != "api" && first != "localhost" {
					subdomain = first
				}
			}
		}

		ctx := context.WithValue(r.Context(), ctxKeyTenant, subdomain)
		ctx = context.WithValue(ctx, ctxKeyTenantHost, host)

		next.ServeHTTP(w, r.WithContext(ctx))
	})
}

func Routes(h *Handler, secret string, log *logger.Logger) http.Handler {
	r := chi.NewRouter()

	// CORS precisa vir ANTES de qualquer outra coisa para responder
	// ao preflight OPTIONS antes do roteador chi devolver 405.
	r.Use(cors.Handler(cors.Options{
		AllowedOrigins: allowedOrigins(),
		AllowedMethods: []string{
			"GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS",
		},
		AllowedHeaders: []string{
			"Accept",
			"Authorization",
			"Content-Type",
			"X-CSRF-Token",
			"X-Tenant-Host",
			"X-Forwarded-Host",
			"Origin",
		},
		ExposedHeaders:   []string{"Link"},
		AllowCredentials: false,
		MaxAge:           300,
	}))

	// Tenant precisa vir ANTES do Logging para que o log já
	// consiga enxergar o tenant no contexto.
	r.Use(TenantMiddleware)
	r.Use(LoggingMiddleware(log))

	r.Get("/", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "text/html; charset=utf-8")

		html := `<!DOCTYPE html>
	<html lang="pt-BR">
	<head>
		<meta charset="UTF-8">
		<meta name="viewport" content="width=device-width, initial-scale=1.0">
		<title>VisionFlow API</title>

		<style>
			* {
				box-sizing: border-box;
			}

			body {
				margin: 0;
				min-height: 100vh;
				display: flex;
				align-items: center;
				justify-content: center;
				padding: 24px;
				font-family: Arial, Helvetica, sans-serif;
				background: #0f172a;
				color: #f8fafc;
			}

			.container {
				width: 100%;
				max-width: 620px;
				padding: 48px 32px;
				text-align: center;
				background: #1e293b;
				border: 1px solid #334155;
				border-radius: 20px;
				box-shadow: 0 20px 60px rgba(0, 0, 0, 0.25);
			}

			.logo {
				display: inline-flex;
				align-items: center;
				justify-content: center;
				width: 68px;
				height: 68px;
				margin-bottom: 20px;
				border-radius: 18px;
				background: #0284c7;
				font-size: 32px;
				font-weight: bold;
			}

			h1 {
				margin: 0 0 16px;
				font-size: 36px;
				letter-spacing: -1px;
			}

			h1 span {
				color: #38bdf8;
			}

			.description {
				margin: 0 auto 28px;
				max-width: 440px;
				color: #cbd5e1;
				font-size: 16px;
				line-height: 1.7;
			}

			.status {
				display: inline-flex;
				align-items: center;
				gap: 8px;
				padding: 10px 16px;
				margin-bottom: 28px;
				border-radius: 30px;
				background: #064e3b;
				color: #a7f3d0;
				font-size: 14px;
			}

			.status-dot {
				width: 8px;
				height: 8px;
				border-radius: 50%;
				background: #34d399;
			}

			.button {
				display: block;
				width: 100%;
				padding: 15px 20px;
				border-radius: 10px;
				background: #0284c7;
				color: white;
				font-size: 15px;
				font-weight: bold;
				text-decoration: none;
				transition: background 0.2s;
			}

			.button:hover {
				background: #0369a1;
			}

			.health-link {
				display: inline-block;
				margin-top: 20px;
				color: #94a3b8;
				font-size: 14px;
				text-decoration: none;
			}

			.health-link:hover {
				color: #38bdf8;
			}

			.footer {
				margin-top: 36px;
				padding-top: 20px;
				border-top: 1px solid #334155;
				color: #64748b;
				font-size: 12px;
			}

			@media (max-width: 480px) {
				.container {
					padding: 36px 22px;
				}

				h1 {
					font-size: 30px;
				}
			}
		</style>
	</head>

	<body>
		<main class="container">
			<div class="logo">V</div>

			<h1>Vision<span>Flow</span> API</h1>

			<p class="description">
				Plataforma de integração do VisionFlow.
				API desenvolvida para conectar aplicações
				e disponibilizar os recursos do sistema.
			</p>

			<div class="status">
				<span class="status-dot"></span>
				Serviço respondendo
			</div>

			<a class="button" href="/swagger/index.html">
				Acessar documentação Swagger →
			</a>

			<a class="health-link" href="/health">
				Verificar endpoint de saúde
			</a>

			<div class="footer">
				VisionFlow API · Go · REST
			</div>
		</main>
	</body>
	</html>`

		_, _ = w.Write([]byte(html))
	})

	r.Get("/health", func(w http.ResponseWriter, r *http.Request) {
		writeJSON(w, 200, map[string]string{"status": "ok"}, nil)
	})

	// Debug temporário: mostra o que o middleware conseguiu extrair.
	// Remova em produção ou proteja com token.
	r.Get("/debug/host", func(w http.ResponseWriter, r *http.Request) {
		writeJSON(w, 200, map[string]any{
			"host_header":      r.Host,
			"x_tenant_host":    r.Header.Get("X-Tenant-Host"),
			"x_forwarded_host": r.Header.Get("X-Forwarded-Host"),
			"tenant":           TenantFromContext(r.Context()),
			"tenant_host":      TenantHostFromContext(r.Context()),
		}, nil)
	})

	r.Get("/swagger.yaml", swaggerYAML)
	r.Get("/swagger/index.html", swaggerUI)

	r.Route("/auth", func(r chi.Router) {
		r.Post("/login", h.Login)
		r.With(JWTMiddleware(secret)).Post("/logout", h.Logout)
	})

	r.Group(func(r chi.Router) {
		r.Use(JWTMiddleware(secret))

		r.Get("/home/indicadores", h.Indicadores)

		r.Get("/clientes", h.Clientes)
		r.Get("/clientes/{id}", h.Cliente)
		r.Get("/clientes/cnpj/{cnpj}", h.ClienteCNPJ)

		r.Get("/pedidos", h.Pedidos)
		r.Post("/pedidos", h.SalvarPedido)
		r.Get("/pedidos/{id}", h.Pedido)

		r.Get("/orcamentos", h.Orcamentos)
		r.Get("/agenda", h.Agenda)
		r.Get("/tarefas", h.Tarefas)
		r.Get("/notificacoes", h.Notificacoes)

		r.Get("/shell/empresa", h.ShellEmpresa)
		r.Get("/shell/notificacoes", h.ShellNotificacoes)
	})

	return r
}

// allowedOrigins devolve a lista de origens permitidas para CORS.
//
// Lê da variável de ambiente CORS_ALLOWED_ORIGINS (separada por vírgula).
// Se a variável não estiver definida, usa um fallback com os domínios
// de desenvolvimento e produção do front VisionFlow.
func allowedOrigins() []string {
	raw := strings.TrimSpace(os.Getenv("CORS_ALLOWED_ORIGINS"))
	if raw != "" {
		parts := strings.Split(raw, ",")
		origins := make([]string, 0, len(parts))
		for _, p := range parts {
			p = strings.TrimSpace(p)
			if p != "" {
				origins = append(origins, p)
			}
		}
		if len(origins) > 0 {
			return origins
		}
	}

	return []string{
		"http://localhost:5173",
		"https://visionflow.celsolsander.workers.dev",
		"https://app.programadordelphi.com.br",
	}
}

var _ = service.New
