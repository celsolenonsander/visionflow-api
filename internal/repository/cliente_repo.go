package repository

import (
	"context"
	"fmt"

	"github.com/celsolenonsander/visionflow-api/internal/db"
	"github.com/celsolenonsander/visionflow-api/internal/models"
)

type ClienteRepo struct{}

func NewClienteRepo() *ClienteRepo {
	return &ClienteRepo{}
}

// Listar retorna clientes paginados por cursor.
//
// O RLS injeta cod_tenant/cod_empresa automaticamente via Session,
// por isso a query NÃO filtra por tenant/empresa.
func (r *ClienteRepo) Listar(
	ctx context.Context,
	sess *db.Session,
	limit int,
	cursor int, // 0 = primeira página
) ([]models.Cliente, string, error) {
	const q = `
		SELECT
			codigo,
			codigo_erp,
			nome_razao_social,
			COALESCE(nome_fantasia, '')       AS fantasia,
			COALESCE(cnpj_cpf, '')            AS cpf_cnpj,
			COALESCE(tipo_pessoa, '')         AS tipo_pessoa,
			COALESCE(prospect, false)         AS prospect,
			COALESCE(ativo, true)             AS ativo,
			COALESCE(limite_credito_total, 0) AS limite_credito_total,
			COALESCE(anotacao_erp, '')        AS anotacao_erp,
			COALESCE(data_inclusao, '1900-01-01'::date)::text AS data_inclusao
		FROM cliente
		WHERE codigo > $1
		ORDER BY codigo ASC
		LIMIT $2
	`

	// Pega um a mais pra saber se tem próximo
	rows, err := sess.Tx.Query(ctx, q, cursor, limit+1)
	if err != nil {
		return nil, "", fmt.Errorf("listar clientes: %w", err)
	}
	defer rows.Close()

	var clientes []models.Cliente
	for rows.Next() {
		var c models.Cliente
		if err := rows.Scan(
			&c.ID,
			&c.CodigoErp,
			&c.RazaoSocial,
			&c.Fantasia,
			&c.CPFCNPJ,
			&c.TipoPessoa,
			&c.Prospect,
			&c.Status,
			&c.LimiteCreditoTotal,
			&c.AnotacaoErp,
			&c.DataAbertura,
		); err != nil {
			return nil, "", fmt.Errorf("scan cliente: %w", err)
		}

		// "ativo" é bool no banco → string no JSON
		if c.Status == "true" {
			c.Status = "ativo"
		} else {
			c.Status = "inativo"
		}

		// Nome = Razão social (o front usa "nome" e "razao_social")
		c.Nome = c.RazaoSocial

		clientes = append(clientes, c)
	}
	if err := rows.Err(); err != nil {
		return nil, "", fmt.Errorf("iterar clientes: %w", err)
	}

	// Cursor: se veio limit+1, tem próximo
	var nextCursor string
	if len(clientes) > limit {
		nextCursor = fmt.Sprintf("%d", clientes[limit-1].ID)
		clientes = clientes[:limit]
	}

	return clientes, nextCursor, nil
}

// BuscarPorID retorna um cliente pelo codigo (id público).
func (r *ClienteRepo) BuscarPorID(
	ctx context.Context,
	sess *db.Session,
	id int,
) (*models.Cliente, error) {
	const q = `
		SELECT
			codigo,
			codigo_erp,
			nome_razao_social,
			COALESCE(nome_fantasia, '')       AS fantasia,
			COALESCE(cnpj_cpf, '')            AS cpf_cnpj,
			COALESCE(tipo_pessoa, '')         AS tipo_pessoa,
			COALESCE(prospect, false)         AS prospect,
			COALESCE(ativo, true)             AS ativo,
			COALESCE(limite_credito_total, 0) AS limite_credito_total,
			COALESCE(anotacao_erp, '')        AS anotacao_erp,
			COALESCE(data_inclusao, '1900-01-01'::date)::text AS data_inclusao
		FROM cliente
		WHERE codigo = $1
	`

	var c models.Cliente
	err := sess.Tx.QueryRow(ctx, q, id).Scan(
		&c.ID,
		&c.CodigoErp,
		&c.RazaoSocial,
		&c.Fantasia,
		&c.CPFCNPJ,
		&c.TipoPessoa,
		&c.Prospect,
		&c.Status,
		&c.LimiteCreditoTotal,
		&c.AnotacaoErp,
		&c.DataAbertura,
	)
	if err != nil {
		return nil, err
	}

	if c.Status == "true" {
		c.Status = "ativo"
	} else {
		c.Status = "inativo"
	}
	c.Nome = c.RazaoSocial

	return &c, nil
}
