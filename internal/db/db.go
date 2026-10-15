package db

import (
	"context"
	"fmt"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/celsolenonsander/visionflow-api/internal/config"
)

// Pool é o pool de conexões do Postgres.
// Exposto como wrapper pra permitir helpers futuros.
type Pool struct {
	*pgxpool.Pool
}

// NewPool cria e valida o pool de conexões.
func NewPool(ctx context.Context, cfg *config.Config) (*Pool, error) {
	poolCfg, err := pgxpool.ParseConfig(cfg.DSN())
	if err != nil {
		return nil, fmt.Errorf("parse DSN: %w", err)
	}

	poolCfg.MaxConns = cfg.DBPoolMaxConns
	poolCfg.MinConns = cfg.DBPoolMinConns
	poolCfg.MaxConnLifetime = cfg.DBPoolMaxLifetime
	poolCfg.MaxConnIdleTime = 5 * time.Minute
	poolCfg.HealthCheckPeriod = 1 * time.Minute

	pool, err := pgxpool.NewWithConfig(ctx, poolCfg)
	if err != nil {
		return nil, fmt.Errorf("criar pool: %w", err)
	}

	// Ping inicial com timeout pra falhar cedo se o banco estiver inacessível.
	pingCtx, cancel := context.WithTimeout(ctx, 5*time.Second)
	defer cancel()

	if err := pool.Ping(pingCtx); err != nil {
		pool.Close()
		return nil, fmt.Errorf("ping no banco: %w", err)
	}

	return &Pool{Pool: pool}, nil
}

// Close fecha o pool.
func (p *Pool) Close() {
	p.Pool.Close()
}
