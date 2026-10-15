package shell

import (
	"context"
	"errors"
	"fmt"

	"github.com/jackc/pgx/v5"
)

type Repository struct{}

func NewRepository() *Repository {
	return &Repository{}
}

func (r *Repository) Get(ctx context.Context, tx pgx.Tx, tenantID, empresaID, userID int) (map[string]any, error) {
	const query = `
		SELECT COALESCE(e.nome_fantasia,e.razao_social) AS nome,e.cnpj,
		       e.regional,COALESCE(e.email,e.telefone) AS contato,
		       u.cod_usuario AS usuario_id,u.nome AS usuario_nome,u.email AS usuario_email
		FROM empresa e JOIN usuario u ON u.cod_usuario=$3 AND u.cod_tenant=$1
		WHERE e.cod_tenant=$1 AND e.cod_empresa=$2 AND COALESCE(e.ativo,true)
		  AND COALESCE(u.ativo,true)`
	var nome, cnpj, userName, email string
	var regional, contact *string
	var user int
	if err := tx.QueryRow(ctx, query, tenantID, empresaID, userID).Scan(
		&nome, &cnpj, &regional, &contact, &user, &userName, &email); err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, pgx.ErrNoRows
		}
		return nil, fmt.Errorf("consultar shell da empresa: %w", err)
	}
	return map[string]any{
		"nome": nome, "cnpj": cnpj, "regional": regional, "contato": contact,
		"usuario_logado": map[string]any{"id": user, "nome": userName, "email": email},
	}, nil
}
