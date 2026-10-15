package httpapi

import (
	"net/http"

	"github.com/go-chi/chi/v5"
	"github.com/go-chi/cors"
)

// Routes monta o roteador HTTP com todas as rotas.
func (h *Handler) Routes() http.Handler {
	r := chi.NewRouter()

	// ─── Middlewares globais ─────────────────────────────
	r.Use(cors.Handler(cors.Options{
		AllowedOrigins:   []string{"http://localhost:5173", "http://localhost:3000"},
		AllowedMethods:   []string{"GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"},
		AllowedHeaders:   []string{"Accept", "Authorization", "Content-Type"},
		ExposedHeaders:   []string{"Link"},
		AllowCredentials: true,
		MaxAge:           300,
	}))

	// ─── Health check (público) ──────────────────────────
	r.Get("/health", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		w.Write([]byte(`{"status":"ok"}`))
	})

	// ─── Autenticação (pública) ──────────────────────────
	r.Post("/auth/login", h.Login)
	r.Post("/auth/logout", h.Logout)

	// ─── Rotas autenticadas ──────────────────────────────
	r.Group(func(r chi.Router) {
		r.Use(h.Auth)

		// Home
		r.Get("/home/indicadores", h.Indicadores)

		// Shell
		r.Get("/shell/empresa", h.ShellEmpresa)
		r.Get("/shell/notificacoes", h.ShellNotificacoes)

		// Notificações
		r.Get("/notificacoes", h.Notificacoes)

		// Clientes
		r.Get("/clientes", h.Clientes)
		r.Get("/clientes/cnpj/{cnpj}", h.ClienteCNPJ)
		r.Get("/clientes/{id}", h.Cliente)

		// Pedidos
		r.Get("/pedidos", h.Pedidos)
		r.Get("/pedidos/{id}", h.Pedido)
		r.Post("/pedidos", h.SalvarPedido)

		// Orçamentos
		r.Get("/orcamentos", h.Orcamentos)

		// Agenda e tarefas
		r.Get("/agenda", h.Agenda)
		r.Get("/tarefas", h.Tarefas)
	})

	return r
}
