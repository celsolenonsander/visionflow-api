package service

import (
	"errors"
	"time"

	"github.com/celsolenonsander/visionflow-api/internal/mockdata"
	"github.com/celsolenonsander/visionflow-api/internal/models"
)

type Service struct{}

func New() *Service {
	return &Service{}
}

func (s *Service) Login(email, senha string) (models.Usuario, error) {
	usuario, ok := mockdata.Login(email, senha)
	if !ok {
		return models.Usuario{}, errors.New("credenciais inválidas")
	}

	return usuario, nil
}

func (s *Service) Indicadores() models.Indicadores {
	return mockdata.Indicadores()
}

func (s *Service) Clientes() []models.Cliente {
	return mockdata.Clientes()
}

func (s *Service) Cliente(id int) (models.Cliente, bool) {
	for _, c := range s.Clientes() {
		if c.ID == id {
			return c, true
		}
	}

	return models.Cliente{}, false
}

func (s *Service) ClienteCNPJ(cnpj string) (models.ClienteCNPJ, bool) {
	return mockdata.ClienteCNPJ(cnpj)
}

func (s *Service) Pedidos() []models.PedidoResumo {
	return mockdata.Pedidos()
}

func (s *Service) Pedido(id int) (models.PedidoDetalhe, bool) {
	return mockdata.Pedido(id)
}

func (s *Service) Orcamentos() []models.Orcamento {
	return mockdata.Orcamentos()
}

func (s *Service) Agenda() []models.Agenda {
	return mockdata.Agenda()
}

func (s *Service) Tarefas() []models.Tarefa {
	return mockdata.Tarefas()
}

func (s *Service) Notificacoes() []models.Notificacao {
	return mockdata.Notificacoes()
}

func (s *Service) ShellEmpresa() models.ShellEmpresa {
	return mockdata.ShellEmpresa()
}

func (s *Service) NotificacoesCount() models.NotificacaoCount {
	return mockdata.NotificacoesCount()
}

func (s *Service) SalvarPedido(req models.PedidoRequest) models.PedidoSalvo {
	return mockdata.SalvarPedido(req)
}

func Now() string {
	return time.Now().UTC().Format(time.RFC3339)
}
