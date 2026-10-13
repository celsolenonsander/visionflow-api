package httpapi

import (
	"encoding/json"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/celsolenonsander/visionflow-api/internal/models"
	"github.com/celsolenonsander/visionflow-api/internal/service"
	"github.com/golang-jwt/jwt/v5"
)

type Handler struct {
	Service   *service.Service
	JWTSecret string
}

func NewHandler(s *service.Service, jwtSecret string) *Handler {
	return &Handler{
		Service:   s,
		JWTSecret: jwtSecret,
	}
}

func writeJSON(w http.ResponseWriter, status int, data interface{}, err *models.APIError) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)

	_ = json.NewEncoder(w).Encode(
		models.APIResponse{
			Success: err == nil,
			Data:    data,
			Error:   err,
		},
	)
}

func bad(w http.ResponseWriter, status int, code, msg string) {
	writeJSON(
		w,
		status,
		nil,
		&models.APIError{
			Code:    code,
			Message: msg,
		},
	)
}

func decode(w http.ResponseWriter, r *http.Request, v interface{}) bool {
	if err := json.NewDecoder(r.Body).Decode(v); err != nil {
		bad(
			w,
			http.StatusBadRequest,
			"REQUISICAO_INVALIDA",
			"JSON inválido.",
		)
		return false
	}

	return true
}

func (h *Handler) Login(w http.ResponseWriter, r *http.Request) {
	var req models.LoginRequest

	if !decode(w, r, &req) {
		return
	}

	u, err := h.Service.Login(req.Email, req.Senha)
	if err != nil {
		bad(
			w,
			http.StatusUnauthorized,
			"CREDENCIAIS_INVALIDAS",
			err.Error(),
		)
		return
	}

	token := jwt.NewWithClaims(
		jwt.SigningMethodHS256,
		jwt.MapClaims{
			"sub": u.ID,
			"iat": time.Now().Unix(),
			"exp": time.Now().Add(8 * time.Hour).Unix(),
		},
	)

	signedToken, err := token.SignedString([]byte(h.JWTSecret))
	if err != nil {
		bad(
			w,
			http.StatusInternalServerError,
			"TOKEN_ERRO",
			"Não foi possível gerar o token.",
		)
		return
	}

	u.Token = signedToken

	writeJSON(
		w,
		http.StatusOK,
		models.LoginData{
			Usuario: u,
		},
		nil,
	)
}

func (h *Handler) Logout(w http.ResponseWriter, r *http.Request) {
	writeJSON(
		w,
		http.StatusOK,
		map[string]bool{"ok": true},
		nil,
	)
}

func (h *Handler) Indicadores(w http.ResponseWriter, r *http.Request) {
	writeJSON(w, 200, h.Service.Indicadores(), nil)
}

func (h *Handler) Clientes(w http.ResponseWriter, r *http.Request) {
	writeJSON(w, 200, h.Service.Clientes(), nil)
}

func (h *Handler) Cliente(w http.ResponseWriter, r *http.Request) {
	id, err := strconv.Atoi(
		pathParam(r.URL.Path, "/clientes/"),
	)

	if err != nil {
		bad(
			w,
			400,
			"ID_INVALIDO",
			"ID do cliente inválido.",
		)
		return
	}

	c, ok := h.Service.Cliente(id)

	if !ok {
		bad(
			w,
			404,
			"CLIENTE_NAO_ENCONTRADO",
			"Cliente não encontrado.",
		)
		return
	}

	writeJSON(w, 200, c, nil)
}

func (h *Handler) ClienteCNPJ(w http.ResponseWriter, r *http.Request) {
	cnpj := pathParam(
		r.URL.Path,
		"/clientes/cnpj/",
	)

	c, ok := h.Service.ClienteCNPJ(cnpj)

	if !ok {
		bad(
			w,
			404,
			"CNPJ_NAO_ENCONTRADO",
			"CNPJ não encontrado.",
		)
		return
	}

	writeJSON(w, 200, c, nil)
}

func (h *Handler) Pedidos(w http.ResponseWriter, r *http.Request) {
	writeJSON(w, 200, h.Service.Pedidos(), nil)
}

func (h *Handler) Pedido(w http.ResponseWriter, r *http.Request) {
	id, err := strconv.Atoi(
		pathParam(r.URL.Path, "/pedidos/"),
	)

	if err != nil {
		bad(
			w,
			400,
			"ID_INVALIDO",
			"ID do pedido inválido.",
		)
		return
	}

	p, ok := h.Service.Pedido(id)

	if !ok {
		bad(
			w,
			404,
			"PEDIDO_NAO_ENCONTRADO",
			"Pedido não encontrado.",
		)
		return
	}

	writeJSON(w, 200, p, nil)
}

func (h *Handler) SalvarPedido(w http.ResponseWriter, r *http.Request) {
	var req models.PedidoRequest

	if !decode(w, r, &req) {
		return
	}

	if req.ClienteID <= 0 {
		bad(
			w,
			400,
			"CLIENTE_OBRIGATORIO",
			"cliente_id deve ser maior que zero.",
		)
		return
	}

	writeJSON(
		w,
		200,
		h.Service.SalvarPedido(req),
		nil,
	)
}

func (h *Handler) Orcamentos(w http.ResponseWriter, r *http.Request) {
	writeJSON(w, 200, h.Service.Orcamentos(), nil)
}

func (h *Handler) Agenda(w http.ResponseWriter, r *http.Request) {
	writeJSON(w, 200, h.Service.Agenda(), nil)
}

func (h *Handler) Tarefas(w http.ResponseWriter, r *http.Request) {
	writeJSON(w, 200, h.Service.Tarefas(), nil)
}

func (h *Handler) Notificacoes(w http.ResponseWriter, r *http.Request) {
	writeJSON(w, 200, h.Service.Notificacoes(), nil)
}

func (h *Handler) ShellEmpresa(w http.ResponseWriter, r *http.Request) {
	writeJSON(w, 200, h.Service.ShellEmpresa(), nil)
}

func (h *Handler) ShellNotificacoes(w http.ResponseWriter, r *http.Request) {
	writeJSON(w, 200, h.Service.NotificacoesCount(), nil)
}

func pathParam(path, prefix string) string {
	return strings.TrimPrefix(path, prefix)
}
