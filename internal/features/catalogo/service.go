package catalogo

import (
	"context"
	"fmt"

	"github.com/celsolenonsander/visionflow-api/internal/db"
)

type Service struct {
	pool       *db.Pool
	repository *Repository
}

func New(pool *db.Pool) *Service {
	return &Service{pool: pool, repository: NewRepository()}
}

func (s *Service) List(ctx context.Context, tenantID, empresaID, userID int, resource, search string, limit, cursor int) ([]map[string]any, string, error) {
	if _, ok := queryFor(resource); !ok {
		return nil, "", fmt.Errorf("catálogo desconhecido: %s", resource)
	}
	session, err := db.NewSession(ctx, s.pool, tenantID, empresaID)
	if err != nil {
		return nil, "", err
	}
	defer session.Rollback(ctx)

	items, err := s.repository.List(ctx, session.Tx, tenantID, empresaID, userID, cursor, limit, resource, search)
	if err != nil {
		return nil, "", err
	}
	items, next := db.CursorPage(items, limit, "id")
	if err := session.Commit(ctx); err != nil {
		return nil, "", err
	}
	return items, next, nil
}
