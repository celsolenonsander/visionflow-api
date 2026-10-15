package agenda

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

func (r *Repository) List(ctx context.Context, tx pgx.Tx, tenantID, empresaID, userID, limit, cursor int, completed *bool) ([]map[string]any, error) {
	rows, err := tx.Query(ctx, `
		SELECT codigo AS id,cod_usuario,titulo,descricao,concluida,
		       to_char(dt_inclusao AT TIME ZONE 'UTC','YYYY-MM-DD"T"HH24:MI:SS"Z"') AS dt_inclusao,
		       to_char(dt_alteracao AT TIME ZONE 'UTC','YYYY-MM-DD"T"HH24:MI:SS"Z"') AS dt_alteracao,
		       to_char(data_agendada::timestamp AT TIME ZONE 'UTC','YYYY-MM-DD"T"HH24:MI:SS"Z"') AS data_agendada,
		       CASE WHEN hora_agendada IS NULL THEN NULL ELSE to_char(hora_agendada,'HH24:MI:SS') END AS hora_agendada,
		       codigo_erp_cliente
		FROM agenda
		WHERE cod_tenant=$1 AND cod_empresa=$2 AND cod_usuario=$3 AND codigo>$4
		  AND deletado_em IS NULL AND ($5::boolean IS NULL OR concluida=$5)
		ORDER BY codigo LIMIT $6`, tenantID, empresaID, userID, cursor, completed, limit+1)
	if err != nil {
		return nil, fmt.Errorf("listar agenda: %w", err)
	}
	return db.ReadRows(rows)
}

func (r *Repository) Get(ctx context.Context, tx pgx.Tx, tenantID, empresaID, userID, id int) (map[string]any, error) {
	rows, err := tx.Query(ctx, `
		SELECT codigo AS id,cod_usuario,titulo,descricao,
		       to_char(data_agendada::timestamp AT TIME ZONE 'UTC','YYYY-MM-DD"T"HH24:MI:SS"Z"') AS data_agendada,
		       CASE WHEN hora_agendada IS NULL THEN NULL ELSE to_char(hora_agendada,'HH24:MI:SS') END AS hora_agendada,
		       codigo_erp_cliente,concluida,
		       to_char(dt_inclusao AT TIME ZONE 'UTC','YYYY-MM-DD"T"HH24:MI:SS"Z"') AS dt_inclusao,
		       to_char(dt_alteracao AT TIME ZONE 'UTC','YYYY-MM-DD"T"HH24:MI:SS"Z"') AS dt_alteracao
		FROM agenda
		WHERE cod_tenant=$1 AND cod_empresa=$2 AND codigo=$3 AND cod_usuario=$4 AND deletado_em IS NULL`,
		tenantID, empresaID, id, userID)
	if err != nil {
		return nil, fmt.Errorf("consultar compromisso: %w", err)
	}
	items, err := db.ReadRows(rows)
	if err != nil {
		return nil, fmt.Errorf("ler compromisso: %w", err)
	}
	if len(items) == 0 {
		return nil, pgx.ErrNoRows
	}
	return items[0], nil
}

func (r *Repository) ValidateCustomer(ctx context.Context, tx pgx.Tx, tenantID, empresaID int, code *string) error {
	if code == nil || *code == "" {
		return nil
	}
	var exists bool
	if err := tx.QueryRow(ctx, `SELECT EXISTS(
		SELECT 1 FROM cliente WHERE cod_tenant=$1 AND cod_empresa=$2
		AND codigo_erp=$3 AND COALESCE(ativo,true))`, tenantID, empresaID, *code).Scan(&exists); err != nil {
		return fmt.Errorf("validar cliente da agenda: %w", err)
	}
	if !exists {
		return pgx.ErrNoRows
	}
	return nil
}

func (r *Repository) Create(ctx context.Context, tx pgx.Tx, tenantID, empresaID, userID int, input models.AgendaCreate, scheduled time.Time) (map[string]any, error) {
	var id int
	if err := tx.QueryRow(ctx, `
		INSERT INTO agenda (cod_tenant,cod_empresa,cod_usuario,codigo_erp_cliente,titulo,descricao,data_agendada,hora_agendada)
		VALUES ($1,$2,$3,$4,$5,$6,$7,$8) RETURNING codigo`,
		tenantID, empresaID, userID, input.CodigoERPCliente, input.Titulo, input.Descricao,
		scheduled, input.HoraAgendada).Scan(&id); err != nil {
		return nil, fmt.Errorf("criar compromisso: %w", err)
	}
	return r.Get(ctx, tx, tenantID, empresaID, userID, id)
}

func (r *Repository) Update(ctx context.Context, tx pgx.Tx, tenantID, empresaID, userID, id int, input models.AgendaCreate, scheduled time.Time) (map[string]any, error) {
	tag, err := tx.Exec(ctx, `
		UPDATE agenda SET titulo=$5,descricao=$6,data_agendada=$7,hora_agendada=$8,codigo_erp_cliente=$9
		WHERE cod_tenant=$1 AND cod_empresa=$2 AND codigo=$3 AND cod_usuario=$4 AND deletado_em IS NULL`,
		tenantID, empresaID, id, userID, input.Titulo, input.Descricao, scheduled, input.HoraAgendada, input.CodigoERPCliente)
	if err != nil {
		return nil, fmt.Errorf("atualizar compromisso: %w", err)
	}
	if tag.RowsAffected() == 0 {
		return nil, pgx.ErrNoRows
	}
	return r.Get(ctx, tx, tenantID, empresaID, userID, id)
}

func (r *Repository) Complete(ctx context.Context, tx pgx.Tx, tenantID, empresaID, userID, id int) (map[string]any, error) {
	tag, err := tx.Exec(ctx, `UPDATE agenda SET concluida=true
		WHERE cod_tenant=$1 AND cod_empresa=$2 AND codigo=$3 AND cod_usuario=$4 AND deletado_em IS NULL`, tenantID, empresaID, id, userID)
	if err != nil {
		return nil, fmt.Errorf("concluir compromisso: %w", err)
	}
	if tag.RowsAffected() == 0 {
		return nil, pgx.ErrNoRows
	}
	return r.Get(ctx, tx, tenantID, empresaID, userID, id)
}

func (r *Repository) Delete(ctx context.Context, tx pgx.Tx, tenantID, empresaID, userID, id int) error {
	tag, err := tx.Exec(ctx, `UPDATE agenda SET deletado_em=now()
		WHERE cod_tenant=$1 AND cod_empresa=$2 AND codigo=$3 AND cod_usuario=$4 AND deletado_em IS NULL`,
		tenantID, empresaID, id, userID)
	if err != nil {
		return fmt.Errorf("remover compromisso: %w", err)
	}
	if tag.RowsAffected() == 0 {
		return pgx.ErrNoRows
	}
	return nil
}
