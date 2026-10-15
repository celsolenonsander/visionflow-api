package catalogo

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

func (r *Repository) List(ctx context.Context, tx pgx.Tx, tenantID, empresaID, userID, cursor, limit int, resource, search string) ([]map[string]any, error) {
	query, ok := queryFor(resource)
	if !ok {
		return nil, fmt.Errorf("catálogo desconhecido: %s", resource)
	}

	var rows pgx.Rows
	var err error
	switch resource {
	case "produtos":
		rows, err = tx.Query(ctx, query, cursor, search, limit+1, tenantID, empresaID)
	case "empresas":
		rows, err = tx.Query(ctx, query, cursor, limit+1, tenantID, userID)
	default:
		rows, err = tx.Query(ctx, query, cursor, limit+1, tenantID, empresaID)
	}
	if err != nil {
		return nil, fmt.Errorf("consultar catálogo %s: %w", resource, err)
	}
	items, err := db.ReadRows(rows)
	if err != nil {
		return nil, fmt.Errorf("ler catálogo %s: %w", resource, err)
	}
	return items, nil
}

func queryFor(resource string) (string, bool) {
	query, ok := catalogQueries[resource]
	return query, ok
}

var catalogQueries = map[string]string{
	"empresas": `SELECT e.cod_empresa AS id, COALESCE(e.nome_fantasia, e.razao_social) AS nome
		FROM empresa e JOIN usuario_empresa ue ON ue.cod_tenant=e.cod_tenant
		  AND ue.cod_empresa=e.cod_empresa AND ue.cod_usuario=$4
		WHERE e.cod_tenant=$3 AND e.cod_empresa > $1 AND COALESCE(e.ativo, true)
		ORDER BY e.cod_empresa LIMIT $2`,
	"condicoes-pagamento": `SELECT codigo AS id, codigo_erp, descricao, quantidade_parcelas, prazo_medio
		FROM condicao_pagamento WHERE codigo > $1 AND COALESCE(ativo, true)
		  AND cod_tenant=$3 AND cod_empresa=$4
		ORDER BY codigo LIMIT $2`,
	"formas-pagamento": `SELECT codigo AS id, codigo_erp, descricao
		FROM forma_pagamento WHERE codigo > $1 AND COALESCE(ativo, true)
		  AND cod_tenant=$3 AND cod_empresa=$4
		ORDER BY codigo LIMIT $2`,
	"transportadoras": `SELECT codigo AS id, codigo_erp, nome_razao, cnpj_cpf
		FROM transportadora WHERE codigo > $1 AND COALESCE(ativo, true)
		  AND cod_tenant=$3 AND cod_empresa=$4
		ORDER BY codigo LIMIT $2`,
	"tabelas-preco": `SELECT t.codigo AS id, t.codigo_erp, t.descricao,
		  CASE WHEN MIN(i.validade_inicial) IS NULL THEN NULL ELSE
		    to_char(MIN(i.validade_inicial)::timestamp AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"Z"') END AS vigencia
		FROM tabela_preco t LEFT JOIN tabela_preco_item i
		  ON i.cod_tenant=t.cod_tenant AND i.cod_empresa=t.cod_empresa
		  AND i.codigo_erp_tabela_preco=t.codigo_erp
		WHERE t.codigo > $1 AND COALESCE(t.ativo, true)
		  AND t.cod_tenant=$3 AND t.cod_empresa=$4
		GROUP BY t.codigo,t.codigo_erp,t.descricao
		ORDER BY t.codigo LIMIT $2`,
	"produtos": `SELECT i.codigo AS id, i.codigo_erp, i.descricao,
		  COALESCE(i.descricao_categoria_nivel1,i.descricao_categoria_nivel2,i.descricao_categoria_nivel3) AS familia,
		  i.apelido_fantasia_fabricante AS marca, u.sigla AS unidade,
		  COALESCE((SELECT tpi.preco_venda FROM tabela_preco_item tpi
		    WHERE tpi.cod_tenant=i.cod_tenant AND tpi.cod_empresa=i.cod_empresa
		      AND tpi.codigo_erp_item=i.codigo_erp
		      AND tpi.codigo_erp_tabela_preco=i.codigo_integracao_tabela_preco
		      AND (tpi.validade_inicial IS NULL OR tpi.validade_inicial<=CURRENT_DATE)
		      AND (tpi.validade_final IS NULL OR tpi.validade_final>=CURRENT_DATE)
		    ORDER BY tpi.validade_inicial DESC NULLS LAST,tpi.codigo DESC LIMIT 1),
		    i.preco_venda,0) AS preco_venda,
		  (SELECT tp.codigo FROM tabela_preco tp
		   WHERE tp.cod_tenant=i.cod_tenant AND tp.cod_empresa=i.cod_empresa
		     AND tp.codigo_erp=i.codigo_integracao_tabela_preco LIMIT 1) AS tabela_preco_padrao_id,
		  COALESCE((SELECT SUM(ie.quantidade) FROM item_estoque ie
		    WHERE ie.cod_tenant=i.cod_tenant AND ie.cod_empresa=i.cod_empresa
		      AND ie.codigo_erp_item=i.codigo_erp),0) AS stock
		FROM item i LEFT JOIN unidade_medida u
		  ON u.cod_tenant=i.cod_tenant AND u.cod_empresa=i.cod_empresa
		  AND u.codigo_erp=i.codigo_erp_unidade_medida
		WHERE i.codigo > $1 AND COALESCE(i.ativo, true)
		  AND ($2='' OR i.codigo_erp ILIKE '%'||$2||'%' OR i.descricao ILIKE '%'||$2||'%')
		  AND i.cod_tenant=$4 AND i.cod_empresa=$5
		ORDER BY i.codigo LIMIT $3`,
}
