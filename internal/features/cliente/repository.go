package cliente

import (
	"context"
	"fmt"
	"strings"

	"github.com/jackc/pgx/v5"

	"github.com/celsolenonsander/visionflow-api/internal/db"
	"github.com/celsolenonsander/visionflow-api/internal/models"
)

type Repository struct{}

func NewRepository() *Repository {
	return &Repository{}
}

func (r *Repository) List(ctx context.Context, tx pgx.Tx, tenantID, empresaID int, search, status string, limit, cursor int) ([]map[string]any, error) {
	const query = `
		SELECT codigo AS id, codigo_erp, nome_razao_social, nome_fantasia, cnpj_cpf,
		       CASE tipo_pessoa WHEN 'F' THEN 'PF' WHEN 'J' THEN 'PJ' ELSE NULL END AS tipo_pessoa,
		       cidade, estado, COALESCE(ativo, true) AS ativo
		FROM cliente
		WHERE cod_tenant=$1 AND cod_empresa=$2 AND deletado_em IS NULL AND codigo > $3
		  AND ($4 = '' OR nome_razao_social ILIKE '%' || $4 || '%'
		       OR COALESCE(nome_fantasia, '') ILIKE '%' || $4 || '%'
		       OR COALESCE(cnpj_cpf, '') ILIKE '%' || $4 || '%')
		  AND ($5 = '' OR
		       ($5 = 'ativo' AND COALESCE(ativo, true) AND NOT COALESCE(prospect, false)) OR
		       ($5 = 'inativo' AND NOT COALESCE(ativo, true)) OR
		       ($5 = 'prospect' AND COALESCE(prospect, false)))
		ORDER BY codigo ASC LIMIT $6`
	rows, err := tx.Query(ctx, query, tenantID, empresaID, cursor, search, status, limit+1)
	if err != nil {
		return nil, fmt.Errorf("listar clientes: %w", err)
	}
	return db.ReadRows(rows)
}

const detailQuery = `
	SELECT codigo AS id, codigo_erp, nome_razao_social, nome_fantasia, cnpj_cpf,
	       inscricao_estadual_rg,
	       CASE tipo_pessoa WHEN 'F' THEN 'PF' WHEN 'J' THEN 'PJ' ELSE NULL END AS tipo_pessoa,
	       COALESCE(prospect, false) AS prospect, COALESCE(ativo, true) AS ativo,
	       COALESCE(telefone1, '') AS telefone1, COALESCE(telefone2, '') AS telefone2,
	       COALESCE(celular, '') AS celular,
	       COALESCE(nome_contato_comprador, '') AS nome_contato_comprador,
	       COALESCE(email_contato_comprador, '') AS email_contato_comprador,
	       COALESCE(nome_contato_faturamento, '') AS nome_contato_faturamento,
	       COALESCE(email_contato_faturamento, '') AS email_contato_faturamento,
	       COALESCE(limite_credito_total, 0) AS limite_credito_total,
	       anotacao_erp, cep, logradouro, numero_endereco, complemento, bairro, cidade, estado,
	       CASE WHEN data_inclusao IS NULL THEN NULL ELSE
	         to_char(data_inclusao::timestamp AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"Z"') END AS data_inclusao
	FROM cliente WHERE cod_tenant=$1 AND cod_empresa=$2 AND codigo=$3 AND deletado_em IS NULL`

func (r *Repository) Get(ctx context.Context, tx pgx.Tx, tenantID, empresaID, id int) (map[string]any, error) {
	rows, err := tx.Query(ctx, detailQuery, tenantID, empresaID, id)
	if err != nil {
		return nil, fmt.Errorf("consultar cliente: %w", err)
	}
	items, err := db.ReadRows(rows)
	if err != nil {
		return nil, fmt.Errorf("ler cliente: %w", err)
	}
	if len(items) == 0 {
		return nil, pgx.ErrNoRows
	}
	return items[0], nil
}

func (r *Repository) ListAddresses(ctx context.Context, tx pgx.Tx, tenantID, empresaID, customerID int) ([]map[string]any, error) {
	rows, err := tx.Query(ctx, `
		SELECT codigo AS id, codigo_erp_endereco AS codigo_erp,
		       CASE tipo_endereco WHEN 'C' THEN 'cobranca'
		            WHEN 'E' THEN 'entrega' WHEN 'A' THEN 'ambos' ELSE NULL END AS tipo_endereco,
		       endereco_padrao, cep, logradouro, numero_endereco,
		       complemento_endereco, bairro, cidade, estado, ponto_referencia, restricoes_horarios
		FROM cliente_endereco_adicional
		WHERE cod_tenant=$1 AND cod_empresa=$2 AND deletado_em IS NULL
		  AND codigo_erp_cliente = (SELECT codigo_erp FROM cliente WHERE cod_tenant=$1 AND cod_empresa=$2 AND codigo=$3 AND deletado_em IS NULL)
		ORDER BY endereco_padrao DESC, codigo ASC`, tenantID, empresaID, customerID)
	if err != nil {
		return nil, fmt.Errorf("listar endereços do cliente: %w", err)
	}
	return db.ReadRows(rows)
}

func (r *Repository) ListReceivables(ctx context.Context, tx pgx.Tx, tenantID, empresaID, customerID int) ([]map[string]any, error) {
	rows, err := tx.Query(ctx, `
		SELECT codigo AS id, codigo_erp, titulo_numero_documento,
		       titulo_especie_documento, titulo_serie, titulo_numero_parcela,
		       CASE WHEN data_emissao IS NULL THEN NULL ELSE
		         to_char(data_emissao::timestamp AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"Z"') END AS data_emissao,
		       CASE WHEN data_vencimento IS NULL THEN NULL ELSE
		         to_char(data_vencimento::timestamp AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"Z"') END AS data_vencimento,
		       COALESCE(valor_total_aberto, 0) AS valor_total_aberto,
		       CASE WHEN data_liquidacao IS NOT NULL THEN 'pago'
		            WHEN data_vencimento < CURRENT_DATE THEN 'vencido' ELSE 'aberto' END AS situacao
		FROM cliente_conta_receber
		WHERE cod_tenant=$1 AND cod_empresa=$2
		  AND codigo_erp_cliente = (SELECT codigo_erp FROM cliente WHERE cod_tenant=$1 AND cod_empresa=$2 AND codigo=$3)
		ORDER BY (data_liquidacao IS NULL AND data_vencimento < CURRENT_DATE) DESC,
		         data_vencimento ASC NULLS LAST, codigo ASC`, tenantID, empresaID, customerID)
	if err != nil {
		return nil, fmt.Errorf("listar contas a receber: %w", err)
	}
	return db.ReadRows(rows)
}

func (r *Repository) IsDuplicate(ctx context.Context, tx pgx.Tx, tenantID, empresaID int, document string, excludeID int) (bool, error) {
	digits := strings.Map(func(r rune) rune {
		if r >= '0' && r <= '9' {
			return r
		}
		return -1
	}, document)
	if digits == "" {
		return false, nil
	}
	lockKey := fmt.Sprintf("%d:%d:%s", tenantID, empresaID, digits)
	if _, err := tx.Exec(ctx, `SELECT pg_advisory_xact_lock(hashtextextended($1,0))`, lockKey); err != nil {
		return false, fmt.Errorf("sincronizar validação de documento duplicado: %w", err)
	}
	var duplicate bool
	err := tx.QueryRow(ctx, `
		SELECT EXISTS(SELECT 1 FROM cliente
		 WHERE cod_tenant=$1 AND cod_empresa=$2 AND codigo<>$3
		   AND regexp_replace(COALESCE(cnpj_cpf,''),'[^0-9]','','g')=$4)`,
		tenantID, empresaID, excludeID, digits).Scan(&duplicate)
	if err != nil {
		return false, fmt.Errorf("validar documento duplicado de cliente: %w", err)
	}
	return duplicate, nil
}

func (r *Repository) Create(ctx context.Context, tx pgx.Tx, tenantID, empresaID int, input models.ClienteCreate) (map[string]any, error) {
	var id int
	if err := tx.QueryRow(ctx, "SELECT nextval('public.cliente_codigo_seq')").Scan(&id); err != nil {
		return nil, fmt.Errorf("gerar identificador de cliente: %w", err)
	}
	_, err := tx.Exec(ctx, `
		INSERT INTO cliente (
			cod_tenant,cod_empresa,codigo,codigo_erp,nome_razao_social,nome_fantasia,cnpj_cpf,
			inscricao_estadual_rg,tipo_pessoa,prospect,telefone1,telefone2,celular,
			nome_contato_comprador,email_contato_comprador,nome_contato_faturamento,
			email_contato_faturamento,limite_credito_total,anotacao_erp,cep,logradouro,
			numero_endereco,complemento,bairro,cidade,estado
		) VALUES (
			$1,$2,$3,$4,$5,NULLIF($6,''),NULLIF($7,''),NULLIF($8,''),$9,$10,
			NULLIF($11,''),NULLIF($12,''),NULLIF($13,''),NULLIF($14,''),NULLIF($15,''),
			NULLIF($16,''),NULLIF($17,''),$18,NULLIF($19,''),NULLIF($20,''),NULLIF($21,''),
			NULLIF($22,''),NULLIF($23,''),NULLIF($24,''),NULLIF($25,''),NULLIF($26,'')
		)`, tenantID, empresaID, id, fmt.Sprintf("API-%d", id), input.NomeRazaoSocial,
		input.NomeFantasia, input.CNPJCPF, input.InscricaoEstadualRG, bancoTipoPessoa(input.TipoPessoa),
		input.Prospect, input.Telefone1, input.Telefone2, input.Celular, input.NomeContatoComprador,
		input.EmailContatoComprador, input.NomeContatoFaturamento, input.EmailContatoFaturamento,
		input.LimiteCreditoTotal, input.AnotacaoERP, input.CEP, input.Logradouro, input.NumeroEndereco,
		input.Complemento, input.Bairro, input.Cidade, input.Estado)
	if err != nil {
		return nil, fmt.Errorf("criar cliente: %w", err)
	}
	return r.Get(ctx, tx, tenantID, empresaID, id)
}

func (r *Repository) Update(ctx context.Context, tx pgx.Tx, tenantID, empresaID, id int, input models.ClienteCreate) (map[string]any, error) {
	tag, err := tx.Exec(ctx, `
		UPDATE cliente SET nome_razao_social=$3,nome_fantasia=NULLIF($4,''),cnpj_cpf=NULLIF($5,''),
			inscricao_estadual_rg=NULLIF($6,''),tipo_pessoa=$7,prospect=$8,
			telefone1=NULLIF($9,''),telefone2=NULLIF($10,''),celular=NULLIF($11,''),
			nome_contato_comprador=NULLIF($12,''),email_contato_comprador=NULLIF($13,''),
			nome_contato_faturamento=NULLIF($14,''),email_contato_faturamento=NULLIF($15,''),
			limite_credito_total=$16,anotacao_erp=NULLIF($17,''),cep=NULLIF($18,''),
			logradouro=NULLIF($19,''),numero_endereco=NULLIF($20,''),complemento=NULLIF($21,''),
			bairro=NULLIF($22,''),cidade=NULLIF($23,''),estado=NULLIF($24,'')
		WHERE cod_tenant=$1 AND cod_empresa=$2 AND codigo=$25 AND deletado_em IS NULL`,
		tenantID, empresaID, input.NomeRazaoSocial, input.NomeFantasia, input.CNPJCPF,
		input.InscricaoEstadualRG, bancoTipoPessoa(input.TipoPessoa), input.Prospect,
		input.Telefone1, input.Telefone2, input.Celular, input.NomeContatoComprador,
		input.EmailContatoComprador, input.NomeContatoFaturamento, input.EmailContatoFaturamento,
		input.LimiteCreditoTotal, input.AnotacaoERP, input.CEP, input.Logradouro, input.NumeroEndereco,
		input.Complemento, input.Bairro, input.Cidade, input.Estado, id)
	if err != nil {
		return nil, fmt.Errorf("atualizar cliente: %w", err)
	}
	if tag.RowsAffected() == 0 {
		return nil, pgx.ErrNoRows
	}
	return r.Get(ctx, tx, tenantID, empresaID, id)
}

func (r *Repository) Deactivate(ctx context.Context, tx pgx.Tx, tenantID, empresaID, id int) error {
	tag, err := tx.Exec(ctx, `UPDATE cliente SET deletado_em=now() WHERE cod_tenant=$1 AND cod_empresa=$2 AND codigo=$3 AND deletado_em IS NULL`, tenantID, empresaID, id)
	if err != nil {
		return fmt.Errorf("remover cliente: %w", err)
	}
	if tag.RowsAffected() == 0 {
		return pgx.ErrNoRows
	}
	return nil
}

func (r *Repository) CreateAddress(ctx context.Context, tx pgx.Tx, tenantID, empresaID, customerID int, input models.EnderecoCreate, dbType string) (map[string]any, error) {
	customerERP, err := r.lockCustomer(ctx, tx, tenantID, empresaID, customerID)
	if err != nil {
		return nil, err
	}
	if input.EnderecoPadrao {
		if _, err := tx.Exec(ctx, `
			UPDATE cliente_endereco_adicional SET endereco_padrao=false
			WHERE cod_tenant=$1 AND cod_empresa=$2 AND codigo_erp_cliente=$3
			  AND deletado_em IS NULL`, tenantID, empresaID, customerERP); err != nil {
			return nil, fmt.Errorf("limpar endereço padrão: %w", err)
		}
	}
	var id int
	if err := tx.QueryRow(ctx, "SELECT nextval('public.cliente_endereco_adicional_codigo_seq')").Scan(&id); err != nil {
		return nil, fmt.Errorf("gerar identificador de endereço: %w", err)
	}
	_, err = tx.Exec(ctx, `
		INSERT INTO cliente_endereco_adicional (
			cod_tenant,cod_empresa,codigo,codigo_erp_cliente,codigo_erp_endereco,identificacao_endereco,
			cep,logradouro,numero_endereco,complemento_endereco,bairro,cidade,estado,tipo_endereco,
			endereco_padrao,ponto_referencia,restricoes_horarios
		) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,NULLIF($10,''),$11,$12,$13,$14,$15,NULLIF($16,''),NULLIF($17,''))`,
		tenantID, empresaID, id, customerERP, fmt.Sprintf("API-%d", id), fmt.Sprintf("API-%d", id),
		input.CEP, input.Logradouro, input.NumeroEndereco, input.ComplementoEndereco, input.Bairro,
		input.Cidade, input.Estado, dbType, input.EnderecoPadrao, input.PontoReferencia, input.RestricoesHorarios)
	if err != nil {
		return nil, fmt.Errorf("criar endereço: %w", err)
	}
	return r.addressByID(ctx, tx, tenantID, empresaID, customerID, id)
}

func (r *Repository) UpdateAddress(ctx context.Context, tx pgx.Tx, tenantID, empresaID, customerID, addressID int, input models.EnderecoCreate, dbType string) (map[string]any, error) {
	customerERP, err := r.lockCustomer(ctx, tx, tenantID, empresaID, customerID)
	if err != nil {
		return nil, err
	}

	tag, err := tx.Exec(ctx, `
		UPDATE cliente_endereco_adicional
		SET cep=$1, logradouro=$2, numero_endereco=$3, complemento_endereco=NULLIF($4,''),
		    bairro=$5, cidade=$6, estado=$7, tipo_endereco=$8, endereco_padrao=$9,
		    ponto_referencia=NULLIF($10,''), restricoes_horarios=NULLIF($11,''), dt_alteracao=now()
		WHERE cod_tenant=$12 AND cod_empresa=$13 AND codigo=$14
		  AND codigo_erp_cliente=$15 AND deletado_em IS NULL`,
		input.CEP, input.Logradouro, input.NumeroEndereco, input.ComplementoEndereco,
		input.Bairro, input.Cidade, input.Estado, dbType, input.EnderecoPadrao,
		input.PontoReferencia, input.RestricoesHorarios, tenantID, empresaID, addressID, customerERP)
	if err != nil {
		return nil, fmt.Errorf("atualizar endereço: %w", err)
	}
	if tag.RowsAffected() == 0 {
		return nil, pgx.ErrNoRows
	}

	if input.EnderecoPadrao {
		if _, err := tx.Exec(ctx, `
			UPDATE cliente_endereco_adicional SET endereco_padrao=false
			WHERE cod_tenant=$1 AND cod_empresa=$2 AND codigo_erp_cliente=$3
			  AND codigo<>$4 AND deletado_em IS NULL`, tenantID, empresaID, customerERP, addressID); err != nil {
			return nil, fmt.Errorf("limpar endereços padrão: %w", err)
		}
	}

	return r.addressByID(ctx, tx, tenantID, empresaID, customerID, addressID)
}

func (r *Repository) lockCustomer(ctx context.Context, tx pgx.Tx, tenantID, empresaID, customerID int) (string, error) {
	var customerERP string
	err := tx.QueryRow(ctx, `
		SELECT codigo_erp FROM cliente
		WHERE cod_tenant=$1 AND cod_empresa=$2 AND codigo=$3 AND deletado_em IS NULL
		FOR UPDATE`, tenantID, empresaID, customerID).Scan(&customerERP)
	if err != nil {
		return "", fmt.Errorf("consultar cliente para endereço: %w", err)
	}
	return customerERP, nil
}

func (r *Repository) addressByID(ctx context.Context, tx pgx.Tx, tenantID, empresaID, customerID, addressID int) (map[string]any, error) {
	rows, err := tx.Query(ctx, `
		SELECT e.codigo AS id, e.codigo_erp_endereco AS codigo_erp,
		       CASE e.tipo_endereco WHEN 'C' THEN 'cobranca'
		            WHEN 'E' THEN 'entrega' WHEN 'A' THEN 'ambos' ELSE NULL END AS tipo_endereco,
		       e.endereco_padrao, e.cep, e.logradouro, e.numero_endereco,
		       e.complemento_endereco, e.bairro, e.cidade, e.estado,
		       e.ponto_referencia, e.restricoes_horarios
		FROM cliente_endereco_adicional e
		WHERE e.cod_tenant=$1 AND e.cod_empresa=$2 AND e.codigo=$3
		  AND e.deletado_em IS NULL
		  AND e.codigo_erp_cliente=(SELECT c.codigo_erp FROM cliente c
		    WHERE c.cod_tenant=$1 AND c.cod_empresa=$2 AND c.codigo=$4 AND c.deletado_em IS NULL)`,
		tenantID, empresaID, addressID, customerID)
	if err != nil {
		return nil, fmt.Errorf("consultar endereço atualizado: %w", err)
	}
	items, err := db.ReadRows(rows)
	if err != nil {
		return nil, fmt.Errorf("ler endereço atualizado: %w", err)
	}
	if len(items) == 0 {
		return nil, pgx.ErrNoRows
	}
	return items[0], nil
}

func (r *Repository) RemoveAddress(ctx context.Context, tx pgx.Tx, tenantID, empresaID, customerID, addressID int) error {
	tag, err := tx.Exec(ctx, `
		UPDATE cliente_endereco_adicional SET deletado_em=now()
		WHERE cod_tenant=$1 AND cod_empresa=$2 AND codigo=$3 AND deletado_em IS NULL
		  AND codigo_erp_cliente=(SELECT codigo_erp FROM cliente
		    WHERE cod_tenant=$1 AND cod_empresa=$2 AND codigo=$4 AND deletado_em IS NULL)`,
		tenantID, empresaID, addressID, customerID)
	if err != nil {
		return fmt.Errorf("remover endereço: %w", err)
	}
	if tag.RowsAffected() == 0 {
		return pgx.ErrNoRows
	}
	return nil
}
