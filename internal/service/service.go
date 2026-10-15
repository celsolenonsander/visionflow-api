package service

import (
	"context"
	"errors"

	"github.com/celsolenonsander/visionflow-api/internal/db"
	"github.com/celsolenonsander/visionflow-api/internal/models"
	"github.com/celsolenonsander/visionflow-api/internal/repository"
)

type Service struct {
	pool        *db.Pool
	clienteRepo *repository.ClienteRepo
}

func New(pool *db.Pool) *Service {
	return &Service{
		pool:        pool,
		clienteRepo: repository.NewClienteRepo(),
	}
}

// ─── AUTH ───────────────────────────────────────────────────

func (s *Service) Login(ctx context.Context, email, senha string) (models.Usuario, error) {
	// TODO: implementar no Bloco 5 (buscar usuario no banco, validar senha_hash)
	return models.Usuario{}, errors.New("login ainda não implementado no banco")
}

// ─── CLIENTES ───────────────────────────────────────────────

// Clientes retorna clientes paginados por cursor.
// A sessão do banco já vem com cod_tenant/cod_empresa (RLS filtra).
func (s *Service) Clientes(
	ctx context.Context,
	tenantID, empresaID int,
	limit int,
	cursor int,
) ([]models.Cliente, string, error) {
	sess, err := db.NewSession(ctx, s.pool, tenantID, empresaID)
	if err != nil {
		return nil, "", err
	}
	defer sess.Rollback(ctx)

	clientes, next, err := s.clienteRepo.Listar(ctx, sess, limit, cursor)
	if err != nil {
		return nil, "", err
	}

	if err := sess.Commit(ctx); err != nil {
		return nil, "", err
	}
	return clientes, next, nil
}

// Cliente busca um cliente por ID.
func (s *Service) Cliente(
	ctx context.Context,
	tenantID, empresaID int,
	id int,
) (*models.Cliente, error) {
	sess, err := db.NewSession(ctx, s.pool, tenantID, empresaID)
	if err != nil {
		return nil, err
	}
	defer sess.Rollback(ctx)

	c, err := s.clienteRepo.BuscarPorID(ctx, sess, id)
	if err != nil {
		return nil, err
	}

	if err := sess.Commit(ctx); err != nil {
		return nil, err
	}
	return c, nil
}

// ─── MOCKS PROVISÓRIOS (vão sair no Bloco 5) ────────────────

func (s *Service) Indicadores() models.Indicadores {
	return models.Indicadores{}
}

func (s *Service) ClienteCNPJ(cnpj string) (models.ClienteCNPJ, bool) {
	return models.ClienteCNPJ{}, false
}

func (s *Service) Pedidos() []models.PedidoResumo {
	return nil
}

func (s *Service) Pedido(id int) (models.PedidoDetalhe, bool) {
	return models.PedidoDetalhe{}, false
}

func (s *Service) Orcamentos() []models.Orcamento {
	return nil
}

func (s *Service) Agenda() []models.Agenda {
	return nil
}

func (s *Service) Tarefas() []models.Tarefa {
	return nil
}

func (s *Service) Notificacoes() []models.Notificacao {
	return nil
}

func (s *Service) ShellEmpresa() models.ShellEmpresa {
	return models.ShellEmpresa{}
}

func (s *Service) NotificacoesCount() models.NotificacaoCount {
	return models.NotificacaoCount{}
}

func (s *Service) SalvarPedido(req models.PedidoRequest) models.PedidoSalvo {
	return models.PedidoSalvo{}
}
