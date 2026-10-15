package notificacao

import (
	"context"
	"fmt"

	"github.com/jackc/pgx/v5"

	"github.com/celsolenonsander/visionflow-api/internal/db"
)

type Repository struct{}

func NewRepository() *Repository {
	return &Repository{}
}

func (r *Repository) List(ctx context.Context, tx pgx.Tx, tenantID, empresaID, userID, cursor, limit int, read *bool) ([]map[string]any, error) {
	const query = `
		SELECT n.codigo AS id,n.titulo,n.mensagem,n.tipo,n.lida,
		       to_char(n.data_evento AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"Z"') AS data_evento,
		       n.origem_tabela,n.origem_id
		FROM notificacao n
		WHERE n.cod_tenant=$1 AND n.cod_empresa=$2 AND n.cod_usuario=$3
		  AND ($4::boolean IS NULL OR n.lida=$4)
		  AND ($5=0 OR (n.data_evento,n.codigo) <
		      (SELECT data_evento,codigo FROM notificacao
		       WHERE cod_tenant=$1 AND cod_empresa=$2 AND codigo=$5 AND cod_usuario=$3))
		ORDER BY n.data_evento DESC,n.codigo DESC LIMIT $6`
	rows, err := tx.Query(ctx, query, tenantID, empresaID, userID, read, cursor, limit+1)
	if err != nil {
		return nil, fmt.Errorf("listar notificações: %w", err)
	}
	items, err := db.ReadRows(rows)
	if err != nil {
		return nil, fmt.Errorf("ler notificações: %w", err)
	}
	return items, nil
}

func (r *Repository) CountUnread(ctx context.Context, tx pgx.Tx, tenantID, empresaID, userID int) (int, error) {
	var count int
	if err := tx.QueryRow(ctx, `SELECT COUNT(*) FROM notificacao WHERE cod_tenant=$1 AND cod_empresa=$2 AND cod_usuario=$3 AND lida=false`, tenantID, empresaID, userID).Scan(&count); err != nil {
		return 0, fmt.Errorf("contar notificações não lidas: %w", err)
	}
	return count, nil
}
