package tarefa

import (
	"context"
	"fmt"
	"time"

	"github.com/jackc/pgx/v5"

	"github.com/celsolenonsander/visionflow-api/internal/db"
	"github.com/celsolenonsander/visionflow-api/internal/models"
)

type Repository struct{}

func NewRepository() *Repository {
	return &Repository{}
}

func (r *Repository) List(ctx context.Context, tx pgx.Tx, tenantID, empresaID, userID, limit, cursor int, completed *bool, priority string) ([]map[string]any, error) {
	rows, err := tx.Query(ctx, `
		SELECT codigo AS id,cod_usuario,titulo,descricao,concluida,
		       to_char(dt_inclusao AT TIME ZONE 'UTC','YYYY-MM-DD"T"HH24:MI:SS"Z"') AS dt_inclusao,
		       to_char(dt_alteracao AT TIME ZONE 'UTC','YYYY-MM-DD"T"HH24:MI:SS"Z"') AS dt_alteracao,
		       CASE WHEN prazo IS NULL THEN NULL ELSE to_char(prazo::timestamp AT TIME ZONE 'UTC','YYYY-MM-DD"T"HH24:MI:SS"Z"') END AS prazo,
		       prioridade
		FROM tarefa
		WHERE cod_tenant=$1 AND cod_empresa=$2 AND cod_usuario=$3 AND codigo>$4
		  AND ($5::boolean IS NULL OR concluida=$5) AND ($6='' OR prioridade=$6)
		ORDER BY codigo LIMIT $7`, tenantID, empresaID, userID, cursor, completed, priority, limit+1)
	if err != nil {
		return nil, fmt.Errorf("listar tarefas: %w", err)
	}
	return db.ReadRows(rows)
}

func (r *Repository) Get(ctx context.Context, tx pgx.Tx, tenantID, empresaID, userID, id int) (map[string]any, error) {
	rows, err := tx.Query(ctx, `
		SELECT codigo AS id,cod_usuario,titulo,descricao,
		       CASE WHEN prazo IS NULL THEN NULL ELSE to_char(prazo::timestamp AT TIME ZONE 'UTC','YYYY-MM-DD"T"HH24:MI:SS"Z"') END AS prazo,
		       prioridade,concluida,
		       to_char(dt_inclusao AT TIME ZONE 'UTC','YYYY-MM-DD"T"HH24:MI:SS"Z"') AS dt_inclusao,
		       to_char(dt_alteracao AT TIME ZONE 'UTC','YYYY-MM-DD"T"HH24:MI:SS"Z"') AS dt_alteracao
		FROM tarefa WHERE cod_tenant=$1 AND cod_empresa=$2 AND codigo=$3 AND cod_usuario=$4`,
		tenantID, empresaID, id, userID)
	if err != nil {
		return nil, fmt.Errorf("consultar tarefa: %w", err)
	}
	items, err := db.ReadRows(rows)
	if err != nil {
		return nil, fmt.Errorf("ler tarefa: %w", err)
	}
	if len(items) == 0 {
		return nil, pgx.ErrNoRows
	}
	return items[0], nil
}

func (r *Repository) Create(ctx context.Context, tx pgx.Tx, tenantID, empresaID, userID int, input models.TarefaCreate, due *time.Time) (map[string]any, error) {
	var id int
	if err := tx.QueryRow(ctx, `
		INSERT INTO tarefa (cod_tenant,cod_empresa,cod_usuario,titulo,descricao,prazo,prioridade)
		VALUES ($1,$2,$3,$4,$5,$6,$7) RETURNING codigo`,
		tenantID, empresaID, userID, input.Titulo, input.Descricao, due, input.Prioridade).Scan(&id); err != nil {
		return nil, fmt.Errorf("criar tarefa: %w", err)
	}
	return r.Get(ctx, tx, tenantID, empresaID, userID, id)
}

func (r *Repository) Update(ctx context.Context, tx pgx.Tx, tenantID, empresaID, userID, id int, input models.TarefaCreate, due *time.Time) (map[string]any, error) {
	tag, err := tx.Exec(ctx, `
		UPDATE tarefa SET titulo=$5,descricao=$6,prazo=$7,prioridade=$8
		WHERE cod_tenant=$1 AND cod_empresa=$2 AND codigo=$3 AND cod_usuario=$4`,
		tenantID, empresaID, id, userID, input.Titulo, input.Descricao, due, input.Prioridade)
	if err != nil {
		return nil, fmt.Errorf("atualizar tarefa: %w", err)
	}
	if tag.RowsAffected() == 0 {
		return nil, pgx.ErrNoRows
	}
	return r.Get(ctx, tx, tenantID, empresaID, userID, id)
}

func (r *Repository) Complete(ctx context.Context, tx pgx.Tx, tenantID, empresaID, userID, id int) (map[string]any, error) {
	tag, err := tx.Exec(ctx, `UPDATE tarefa SET concluida=true
		WHERE cod_tenant=$1 AND cod_empresa=$2 AND codigo=$3 AND cod_usuario=$4`, tenantID, empresaID, id, userID)
	if err != nil {
		return nil, fmt.Errorf("concluir tarefa: %w", err)
	}
	if tag.RowsAffected() == 0 {
		return nil, pgx.ErrNoRows
	}
	return r.Get(ctx, tx, tenantID, empresaID, userID, id)
}
