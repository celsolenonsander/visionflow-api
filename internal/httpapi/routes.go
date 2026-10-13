package httpapi

import (
	"net/http"

	"github.com/celsolenonsander/visionflow-api/internal/logger"
	"github.com/celsolenonsander/visionflow-api/internal/service"
	"github.com/go-chi/chi/v5"
)

func Routes(h *Handler, secret string, log *logger.Logger) http.Handler {
	r := chi.NewRouter()

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

var _ = service.New
