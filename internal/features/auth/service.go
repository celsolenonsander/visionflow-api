package auth

import (
	"context"
	"errors"
	"fmt"

	"github.com/jackc/pgx/v5"

	"github.com/celsolenonsander/visionflow-api/internal/db"
	"github.com/celsolenonsander/visionflow-api/internal/models"
)

var ErrInvalidCredentials = errors.New("E-mail ou senha incorretos.")

type loginRepository interface {
	Authenticate(context.Context, string, string) (models.Usuario, error)
}

type Service struct {
	repository loginRepository
}

func New(pool *db.Pool) *Service {
	return &Service{repository: NewRepository(pool)}
}

func (s *Service) Login(ctx context.Context, email, password string) (models.Usuario, error) {
	user, err := s.repository.Authenticate(ctx, email, password)
	if errors.Is(err, pgx.ErrNoRows) {
		return models.Usuario{}, ErrInvalidCredentials
	}
	if err != nil {
		return models.Usuario{}, fmt.Errorf("autenticar usuário: %w", err)
	}
	return user, nil
}
