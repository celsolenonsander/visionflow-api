package service

import (
	"context"
	"errors"
	"fmt"

	"github.com/jackc/pgx/v5"
	"github.com/celsolenonsander/visionflow-api/internal/db"
	"github.com/celsolenonsander/visionflow-api/internal/models"
	"github.com/celsolenonsander/visionflow-api/internal/repository"
)

var ErrInvalidCredentials = errors.New("E-mail ou senha incorretos.")
var ErrInvalidInput = errors.New("requisição inválida")
var ErrDuplicateResource = errors.New("recurso duplicado")

func InvalidInput(message string) error {
	return fmt.Errorf("%w: %s", ErrInvalidInput, message)
}

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
	const query = `
		SELECT u.cod_usuario, u.nome, u.email
		FROM usuario u
		JOIN usuario_empresa ue ON ue.cod_usuario=u.cod_usuario
		JOIN empresa e ON e.cod_tenant=ue.cod_tenant AND e.cod_empresa=ue.cod_empresa
		JOIN tenant t ON t.cod_tenant=u.cod_tenant
		WHERE lower(u.email)=lower($1)
		  AND u.ativo=true AND e.ativo=true AND t.ativo=true
		  AND ue.cod_tenant=u.cod_tenant
		  AND crypt($2,u.senha_hash)=u.senha_hash
		ORDER BY ue.empresa_padrao DESC, ue.cod_empresa ASC
		LIMIT 1`
	var user models.Usuario
	err := s.pool.QueryRow(ctx, query, email, senha).Scan(&user.ID, &user.Nome, &user.Email)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return models.Usuario{}, ErrInvalidCredentials
		}
		return models.Usuario{}, fmt.Errorf("autenticar usuário: %w", err)
	}
	return user, nil
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
