package service

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/jackc/pgx/v5"

	"github.com/celsolenonsander/visionflow-api/internal/db"
	"github.com/celsolenonsander/visionflow-api/internal/models"
)

const defaultPageSize = 20

func (s *Service) withSession(ctx context.Context, tenantID, empresaID int, fn func(pgx.Tx) error) error {
	sess, err := db.NewSession(ctx, s.pool, tenantID, empresaID)
	if err != nil {
		return err
	}
	defer sess.Rollback(ctx)
	if err := fn(sess.Tx); err != nil {
		return err
	}
	return sess.Commit(ctx)
}

func readRows(rows pgx.Rows) ([]map[string]any, error) {
	defer rows.Close()
	fields := rows.FieldDescriptions()
	result := make([]map[string]any, 0)
	for rows.Next() {
		values := make([]any, len(fields))
		targets := make([]any, len(fields))
		for i := range values {
			targets[i] = &values[i]
		}
		if err := rows.Scan(targets...); err != nil {
			return nil, err
		}
		item := make(map[string]any, len(fields))
		for i, field := range fields {
			value := values[i]
			if bytes, ok := value.([]byte); ok {
				value = string(bytes)
			}
			item[strings.ToLower(string(field.Name))] = value
		}
		result = append(result, item)
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}
	return result, nil
}

func cursorPage(rows []map[string]any, limit int, cursorKey string) ([]map[string]any, string) {
	var next string
	if len(rows) > limit {
		next = fmt.Sprint(rows[limit-1][cursorKey])
		rows = rows[:limit]
	}
	return rows, next
}

func validPage(limitText, cursorText string) (int, int, error) {
	limit := defaultPageSize
	if limitText != "" {
		n, err := strconv.Atoi(limitText)
		if err != nil || n < 1 || n > 100 {
			return 0, 0, errors.New("limit deve estar entre 1 e 100")
		}
		limit = n
	}
	cursor := 0
	if cursorText != "" {
		n, err := strconv.Atoi(cursorText)
		if err != nil || n < 1 {
			return 0, 0, errors.New("cursor deve ser um identificador positivo")
		}
		cursor = n
	}
	return limit, cursor, nil
}

func validString(value, field string, max int) error {
	if len([]rune(value)) > max {
		return InvalidInput(fmt.Sprintf("%s excede %d caracteres", field, max))
	}
	return nil
}

func validCliente(input models.ClienteCreate) error {
	if strings.TrimSpace(input.NomeRazaoSocial) == "" {
		return InvalidInput("nome_razao_social é obrigatório")
	}
	if input.TipoPessoa != "PF" && input.TipoPessoa != "PJ" {
		return InvalidInput("tipo_pessoa deve ser PF ou PJ")
	}
	for _, field := range []struct {
		value string
		name  string
		max   int
	}{
		{input.NomeRazaoSocial, "nome_razao_social", 100},
		{input.NomeFantasia, "nome_fantasia", 100},
		{input.CNPJCPF, "cnpj_cpf", 20},
		{input.InscricaoEstadualRG, "inscricao_estadual_rg", 20},
		{input.Telefone1, "telefone1", 20},
		{input.Telefone2, "telefone2", 20},
		{input.Celular, "celular", 20},
		{input.NomeContatoComprador, "nome_contato_comprador", 100},
		{input.EmailContatoComprador, "email_contato_comprador", 100},
		{input.NomeContatoFaturamento, "nome_contato_faturamento", 100},
		{input.EmailContatoFaturamento, "email_contato_faturamento", 100},
		{input.CEP, "cep", 10},
		{input.Logradouro, "logradouro", 100},
		{input.NumeroEndereco, "numero_endereco", 20},
		{input.Complemento, "complemento", 100},
		{input.Bairro, "bairro", 100},
		{input.Cidade, "cidade", 100},
		{input.Estado, "estado", 2},
	} {
		if err := validString(field.value, field.name, field.max); err != nil {
			return err
		}
	}
	return nil
}

func clienteTipoPessoa(value string) string {
	switch value {
	case "F":
		return "PF"
	case "J":
		return "PJ"
	default:
		return value
	}
}

func bancoTipoPessoa(value string) string {
	switch value {
	case "PF":
		return "F"
	case "PJ":
		return "J"
	default:
		return value
	}
}

func (s *Service) ClientesAPI(ctx context.Context, tenantID, empresaID int, busca, status string, limit, cursor int) ([]map[string]any, string, error) {
	var result []map[string]any
	var next string
	err := s.withSession(ctx, tenantID, empresaID, func(tx pgx.Tx) error {
		const query = `
			SELECT codigo AS id, codigo_erp,
			       nome_razao_social,
			       nome_fantasia,
			       cnpj_cpf,
			       CASE tipo_pessoa WHEN 'F' THEN 'PF' WHEN 'J' THEN 'PJ' ELSE NULL END AS tipo_pessoa,
			       cidade, estado, COALESCE(ativo, true) AS ativo
			FROM cliente
			WHERE codigo > $1
			  AND ($2 = '' OR nome_razao_social ILIKE '%' || $2 || '%'
			       OR COALESCE(nome_fantasia, '') ILIKE '%' || $2 || '%'
			       OR COALESCE(cnpj_cpf, '') ILIKE '%' || $2 || '%')
			  AND ($3 = '' OR
			       ($3 = 'ativo' AND COALESCE(ativo, true) AND NOT COALESCE(prospect, false)) OR
			       ($3 = 'inativo' AND NOT COALESCE(ativo, true)) OR
			       ($3 = 'prospect' AND COALESCE(prospect, false)))
			ORDER BY codigo ASC
			LIMIT $4`
		rows, err := tx.Query(ctx, query, cursor, busca, status, limit+1)
		if err != nil {
			return fmt.Errorf("listar clientes: %w", err)
		}
		result, err = readRows(rows)
		if err != nil {
			return fmt.Errorf("ler clientes: %w", err)
		}
		result, next = cursorPage(result, limit, "id")
		return nil
	})
	return result, next, err
}

const clienteDetailQuery = `
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
	       anotacao_erp,
	       cep, logradouro, numero_endereco, complemento, bairro, cidade, estado,
	       CASE WHEN data_inclusao IS NULL THEN NULL ELSE
	         to_char(data_inclusao::timestamp AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"Z"') END AS data_inclusao
	FROM cliente WHERE codigo = $1`

func clientePorID(ctx context.Context, tx pgx.Tx, id int) (map[string]any, error) {
	rows, err := tx.Query(ctx, clienteDetailQuery, id)
	if err != nil {
		return nil, fmt.Errorf("consultar cliente: %w", err)
	}
	items, err := readRows(rows)
	if err != nil {
		return nil, fmt.Errorf("ler cliente: %w", err)
	}
	if len(items) == 0 {
		return nil, pgx.ErrNoRows
	}
	return items[0], nil
}

func clienteDuplicado(ctx context.Context, tx pgx.Tx, tenantID, empresaID int, cnpjCPF string, excludeID int) (bool, error) {
	document := strings.Map(func(r rune) rune {
		if r >= '0' && r <= '9' {
			return r
		}
		return -1
	}, cnpjCPF)
	if document == "" {
		return false, nil
	}
	lockKey := fmt.Sprintf("%d:%d:%s", tenantID, empresaID, document)
	if _, err := tx.Exec(ctx, `SELECT pg_advisory_xact_lock(hashtextextended($1,0))`, lockKey); err != nil {
		return false, fmt.Errorf("sincronizar validação de documento duplicado: %w", err)
	}
	var duplicate bool
	err := tx.QueryRow(ctx, `
		SELECT EXISTS(
			SELECT 1 FROM cliente
			WHERE cod_tenant=$1 AND cod_empresa=$2 AND codigo<>$3
			  AND regexp_replace(COALESCE(cnpj_cpf,''),'[^0-9]','','g')=$4
		)`, tenantID, empresaID, excludeID, document).Scan(&duplicate)
	if err != nil {
		return false, fmt.Errorf("validar documento duplicado de cliente: %w", err)
	}
	return duplicate, nil
}

func (s *Service) ClienteAPI(ctx context.Context, tenantID, empresaID, id int) (map[string]any, error) {
	var result map[string]any
	err := s.withSession(ctx, tenantID, empresaID, func(tx pgx.Tx) error {
		item, err := clientePorID(ctx, tx, id)
		if err != nil {
			return err
		}
		addresses, err := enderecosDoCliente(ctx, tx, id)
		if err != nil {
			return err
		}
		titles, err := contasReceber(ctx, tx, id)
		if err != nil {
			return err
		}
		item["enderecos"] = addresses
		item["contas_receber"] = titles
		result = item
		return nil
	})
	return result, err
}

func (s *Service) CriarCliente(ctx context.Context, tenantID, empresaID int, input models.ClienteCreate) (map[string]any, error) {
	if err := validCliente(input); err != nil {
		return nil, err
	}
	var result map[string]any
	err := s.withSession(ctx, tenantID, empresaID, func(tx pgx.Tx) error {
		duplicate, err := clienteDuplicado(ctx, tx, tenantID, empresaID, input.CNPJCPF, 0)
		if err != nil {
			return err
		}
		if duplicate {
			return ErrDuplicateResource
		}
		var id int
		if err := tx.QueryRow(ctx, "SELECT nextval('public.cliente_codigo_seq')").Scan(&id); err != nil {
			return fmt.Errorf("gerar identificador de cliente: %w", err)
		}
		const query = `
			INSERT INTO cliente (
				cod_tenant, cod_empresa, codigo, codigo_erp,
				nome_razao_social, nome_fantasia, cnpj_cpf, inscricao_estadual_rg,
				tipo_pessoa, prospect, telefone1, telefone2, celular,
				nome_contato_comprador, email_contato_comprador,
				nome_contato_faturamento, email_contato_faturamento,
				limite_credito_total, anotacao_erp, cep, logradouro,
				numero_endereco, complemento, bairro, cidade, estado
			) VALUES (
				$1, $2, $3, $4, $5, NULLIF($6,''), NULLIF($7,''),
				NULLIF($8,''), $9, $10, NULLIF($11,''), NULLIF($12,''),
				NULLIF($13,''), NULLIF($14,''), NULLIF($15,''),
				NULLIF($16,''), NULLIF($17,''), $18, NULLIF($19,''),
				NULLIF($20,''), NULLIF($21,''), NULLIF($22,''),
				NULLIF($23,''), NULLIF($24,''), NULLIF($25,''),
				NULLIF($26,'')
			)`
		_, err := tx.Exec(ctx, query,
			tenantID, empresaID, id, fmt.Sprintf("API-%d", id),
			input.NomeRazaoSocial, input.NomeFantasia, input.CNPJCPF,
			input.InscricaoEstadualRG, bancoTipoPessoa(input.TipoPessoa),
			input.Prospect, input.Telefone1, input.Telefone2, input.Celular,
			input.NomeContatoComprador, input.EmailContatoComprador,
			input.NomeContatoFaturamento, input.EmailContatoFaturamento,
			input.LimiteCreditoTotal, input.AnotacaoERP, input.CEP,
			input.Logradouro, input.NumeroEndereco, input.Complemento,
			input.Bairro, input.Cidade, input.Estado)
		if err != nil {
			return fmt.Errorf("criar cliente: %w", err)
		}
		result, err = clientePorID(ctx, tx, id)
		return err
	})
	return result, err
}

func (s *Service) AtualizarCliente(ctx context.Context, tenantID, empresaID, id int, input models.ClienteCreate) (map[string]any, error) {
	if err := validCliente(input); err != nil {
		return nil, err
	}
	var result map[string]any
	err := s.withSession(ctx, tenantID, empresaID, func(tx pgx.Tx) error {
		duplicate, err := clienteDuplicado(ctx, tx, tenantID, empresaID, input.CNPJCPF, id)
		if err != nil {
			return err
		}
		if duplicate {
			return ErrDuplicateResource
		}
		const query = `
			UPDATE cliente SET
				nome_razao_social=$3, nome_fantasia=NULLIF($4,''), cnpj_cpf=NULLIF($5,''),
				inscricao_estadual_rg=NULLIF($6,''), tipo_pessoa=$7, prospect=$8,
				telefone1=NULLIF($9,''), telefone2=NULLIF($10,''), celular=NULLIF($11,''),
				nome_contato_comprador=NULLIF($12,''), email_contato_comprador=NULLIF($13,''),
				nome_contato_faturamento=NULLIF($14,''), email_contato_faturamento=NULLIF($15,''),
				limite_credito_total=$16, anotacao_erp=NULLIF($17,''), cep=NULLIF($18,''),
				logradouro=NULLIF($19,''), numero_endereco=NULLIF($20,''),
				complemento=NULLIF($21,''), bairro=NULLIF($22,''), cidade=NULLIF($23,''),
				estado=NULLIF($24,'')
			WHERE cod_tenant=$1 AND cod_empresa=$2 AND codigo=$25`
		tag, err := tx.Exec(ctx, query, tenantID, empresaID,
			input.NomeRazaoSocial, input.NomeFantasia, input.CNPJCPF,
			input.InscricaoEstadualRG, bancoTipoPessoa(input.TipoPessoa),
			input.Prospect, input.Telefone1, input.Telefone2, input.Celular,
			input.NomeContatoComprador, input.EmailContatoComprador,
			input.NomeContatoFaturamento, input.EmailContatoFaturamento,
			input.LimiteCreditoTotal, input.AnotacaoERP, input.CEP,
			input.Logradouro, input.NumeroEndereco, input.Complemento,
			input.Bairro, input.Cidade, input.Estado, id)
		if err != nil {
			return fmt.Errorf("atualizar cliente: %w", err)
		}
		if tag.RowsAffected() == 0 {
			return pgx.ErrNoRows
		}
		result, err = clientePorID(ctx, tx, id)
		return err
	})
	return result, err
}

func (s *Service) RemoverCliente(ctx context.Context, tenantID, empresaID, id int) error {
	return s.withSession(ctx, tenantID, empresaID, func(tx pgx.Tx) error {
		tag, err := tx.Exec(ctx, `
			UPDATE cliente SET ativo=false
			WHERE cod_tenant=$1 AND cod_empresa=$2 AND codigo=$3`, tenantID, empresaID, id)
		if err != nil {
			return fmt.Errorf("inativar cliente: %w", err)
		}
		if tag.RowsAffected() == 0 {
			return pgx.ErrNoRows
		}
		return nil
	})
}

func enderecosDoCliente(ctx context.Context, tx pgx.Tx, clienteID int) ([]map[string]any, error) {
	rows, err := tx.Query(ctx, `
		SELECT codigo AS id, codigo_erp_endereco AS codigo_erp,
		       CASE tipo_endereco WHEN 'C' THEN 'cobranca'
		            WHEN 'E' THEN 'entrega' WHEN 'A' THEN 'ambos' ELSE NULL END AS tipo_endereco,
		       endereco_padrao, cep, logradouro, numero_endereco,
		       complemento_endereco, bairro, cidade, estado,
		       ponto_referencia, restricoes_horarios
		FROM cliente_endereco_adicional
		WHERE codigo_erp_cliente = (SELECT codigo_erp FROM cliente WHERE codigo=$1)
		ORDER BY endereco_padrao DESC, codigo ASC`, clienteID)
	if err != nil {
		return nil, fmt.Errorf("listar endereços do cliente: %w", err)
	}
	return readRows(rows)
}

func contasReceber(ctx context.Context, tx pgx.Tx, clienteID int) ([]map[string]any, error) {
	rows, err := tx.Query(ctx, `
		SELECT codigo AS id, codigo_erp, titulo_numero_documento,
		       titulo_especie_documento, titulo_serie, titulo_numero_parcela,
		       CASE WHEN data_emissao IS NULL THEN NULL ELSE
		         to_char(data_emissao::timestamp AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"Z"') END AS data_emissao,
		       CASE WHEN data_vencimento IS NULL THEN NULL ELSE
		         to_char(data_vencimento::timestamp AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"Z"') END AS data_vencimento,
		       COALESCE(valor_total_aberto, 0) AS valor_total_aberto,
		       CASE WHEN data_liquidacao IS NOT NULL THEN 'pago'
		            WHEN data_vencimento < CURRENT_DATE THEN 'vencido'
		            ELSE 'aberto' END AS situacao
		FROM cliente_conta_receber
		WHERE codigo_erp_cliente = (SELECT codigo_erp FROM cliente WHERE codigo=$1)
		ORDER BY (data_liquidacao IS NULL AND data_vencimento < CURRENT_DATE) DESC,
		         data_vencimento ASC NULLS LAST, codigo ASC`, clienteID)
	if err != nil {
		return nil, fmt.Errorf("listar contas a receber: %w", err)
	}
	return readRows(rows)
}

func (s *Service) EnderecosCliente(ctx context.Context, tenantID, empresaID, id int) ([]map[string]any, error) {
	var result []map[string]any
	err := s.withSession(ctx, tenantID, empresaID, func(tx pgx.Tx) error {
		if _, err := clientePorID(ctx, tx, id); err != nil {
			return err
		}
		var err error
		result, err = enderecosDoCliente(ctx, tx, id)
		return err
	})
	return result, err
}

func bancoTipoEndereco(value string) (string, error) {
	switch value {
	case "cobranca":
		return "C", nil
	case "entrega":
		return "E", nil
	case "ambos":
		return "A", nil
	default:
		return "", InvalidInput("tipo_endereco deve ser cobranca, entrega ou ambos")
	}
}

func (s *Service) CriarEndereco(ctx context.Context, tenantID, empresaID, clienteID int, input models.EnderecoCreate) (map[string]any, error) {
	if strings.TrimSpace(input.CEP) == "" || strings.TrimSpace(input.Logradouro) == "" ||
		strings.TrimSpace(input.NumeroEndereco) == "" || strings.TrimSpace(input.Bairro) == "" ||
		strings.TrimSpace(input.Cidade) == "" || len(input.Estado) != 2 {
		return nil, InvalidInput("campos obrigatórios do endereço ausentes ou inválidos")
	}
	tipo, err := bancoTipoEndereco(input.TipoEndereco)
	if err != nil {
		return nil, err
	}
	var result map[string]any
	err = s.withSession(ctx, tenantID, empresaID, func(tx pgx.Tx) error {
		cliente, err := clientePorID(ctx, tx, clienteID)
		if err != nil {
			return err
		}
		if input.EnderecoPadrao {
			_, err = tx.Exec(ctx, `UPDATE cliente_endereco_adicional SET endereco_padrao=false
				WHERE codigo_erp_cliente=$1`, cliente["codigo_erp"])
			if err != nil {
				return fmt.Errorf("limpar endereço padrão: %w", err)
			}
		}
		var id int
		if err := tx.QueryRow(ctx, "SELECT nextval('public.cliente_endereco_adicional_codigo_seq')").Scan(&id); err != nil {
			return fmt.Errorf("gerar identificador de endereço: %w", err)
		}
		_, err = tx.Exec(ctx, `
			INSERT INTO cliente_endereco_adicional (
				cod_tenant,cod_empresa,codigo,codigo_erp_cliente,codigo_erp_endereco,
				identificacao_endereco,cep,logradouro,numero_endereco,complemento_endereco,
				bairro,cidade,estado,tipo_endereco,endereco_padrao,ponto_referencia,restricoes_horarios
			) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,NULLIF($10,''),$11,$12,$13,$14,$15,NULLIF($16,''),NULLIF($17,''))`,
			tenantID, empresaID, id, cliente["codigo_erp"], fmt.Sprintf("API-%d", id),
			fmt.Sprintf("API-%d", id), input.CEP, input.Logradouro, input.NumeroEndereco,
			input.ComplementoEndereco, input.Bairro, input.Cidade, input.Estado,
			tipo, input.EnderecoPadrao, input.PontoReferencia, input.RestricoesHorarios)
		if err != nil {
			return fmt.Errorf("criar endereço: %w", err)
		}
		addresses, err := enderecosDoCliente(ctx, tx, clienteID)
		if err != nil {
			return err
		}
		for _, address := range addresses {
			if address["id"] == int32(id) || address["id"] == int64(id) || address["id"] == id {
				result = address
				break
			}
		}
		if result == nil {
			return errors.New("endereço criado não foi retornado pela consulta")
		}
		return nil
	})
	return result, err
}

func (s *Service) RemoverEndereco(ctx context.Context, tenantID, empresaID, clienteID, enderecoID int) error {
	return s.withSession(ctx, tenantID, empresaID, func(tx pgx.Tx) error {
		tag, err := tx.Exec(ctx, `
			DELETE FROM cliente_endereco_adicional
			WHERE cod_tenant=$1 AND cod_empresa=$2 AND codigo=$3
			  AND codigo_erp_cliente=(SELECT codigo_erp FROM cliente WHERE codigo=$4)`,
			tenantID, empresaID, enderecoID, clienteID)
		if err != nil {
			return fmt.Errorf("remover endereço: %w", err)
		}
		if tag.RowsAffected() == 0 {
			return pgx.ErrNoRows
		}
		return nil
	})
}

func (s *Service) ContasReceberCliente(ctx context.Context, tenantID, empresaID, clienteID int) ([]map[string]any, error) {
	var result []map[string]any
	err := s.withSession(ctx, tenantID, empresaID, func(tx pgx.Tx) error {
		if _, err := clientePorID(ctx, tx, clienteID); err != nil {
			return err
		}
		var err error
		result, err = contasReceber(ctx, tx, clienteID)
		return err
	})
	return result, err
}

func (s *Service) ConsultarCEP(ctx context.Context, cep string) (map[string]any, error) {
	digits := strings.Map(func(r rune) rune {
		if r >= '0' && r <= '9' {
			return r
		}
		return -1
	}, cep)
	if len(digits) != 8 {
		return nil, InvalidInput("CEP deve conter 8 dígitos")
	}
	client := &http.Client{Timeout: 5 * time.Second}
	request, err := http.NewRequestWithContext(ctx, http.MethodGet, "https://viacep.com.br/ws/"+digits+"/json/", nil)
	if err != nil {
		return nil, fmt.Errorf("criar requisição de CEP: %w", err)
	}
	response, err := client.Do(request)
	if err != nil {
		return nil, fmt.Errorf("consultar serviço de CEP: %w", err)
	}
	defer response.Body.Close()
	if response.StatusCode == http.StatusNotFound {
		return nil, pgx.ErrNoRows
	}
	if response.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("serviço de CEP retornou status %d", response.StatusCode)
	}
	var payload struct {
		CEP        string `json:"cep"`
		Logradouro string `json:"logradouro"`
		Bairro     string `json:"bairro"`
		Localidade string `json:"localidade"`
		UF         string `json:"uf"`
		Erro       bool   `json:"erro"`
	}
	if err := json.NewDecoder(response.Body).Decode(&payload); err != nil {
		return nil, fmt.Errorf("decodificar resposta do serviço de CEP: %w", err)
	}
	if payload.Erro {
		return nil, pgx.ErrNoRows
	}
	return map[string]any{
		"cep": payload.CEP, "logradouro": payload.Logradouro, "bairro": payload.Bairro,
		"cidade": payload.Localidade, "estado": payload.UF,
	}, nil
}

func (s *Service) ConsultarCNPJ(ctx context.Context, cnpj string) (map[string]any, error) {
	digits := strings.Map(func(r rune) rune {
		if r >= '0' && r <= '9' {
			return r
		}
		return -1
	}, cnpj)
	if len(digits) != 14 {
		return nil, InvalidInput("CNPJ deve conter 14 dígitos")
	}
	client := &http.Client{Timeout: 8 * time.Second}
	request, err := http.NewRequestWithContext(ctx, http.MethodGet, "https://brasilapi.com.br/api/cnpj/v1/"+digits, nil)
	if err != nil {
		return nil, fmt.Errorf("criar requisição de CNPJ: %w", err)
	}
	response, err := client.Do(request)
	if err != nil {
		return nil, fmt.Errorf("consultar serviço de CNPJ: %w", err)
	}
	defer response.Body.Close()
	if response.StatusCode == http.StatusNotFound {
		return nil, pgx.ErrNoRows
	}
	if response.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("serviço de CNPJ retornou status %d", response.StatusCode)
	}
	var payload struct {
		CNPJ               string `json:"cnpj"`
		RazaoSocial        string `json:"razao_social"`
		NomeFantasia       string `json:"nome_fantasia"`
		Email              string `json:"email"`
		Telefone           string `json:"ddd_telefone_1"`
		CEP                string `json:"cep"`
		Logradouro         string `json:"logradouro"`
		Numero             string `json:"numero"`
		Complemento        string `json:"complemento"`
		Bairro             string `json:"bairro"`
		Cidade             string `json:"municipio"`
		Estado             string `json:"uf"`
		InscricoesEstaduais []struct {
			InscricaoEstadual string `json:"inscricao_estadual"`
			Ativo              bool   `json:"ativo"`
		} `json:"inscricoes_estaduais"`
	}
	if err := json.NewDecoder(response.Body).Decode(&payload); err != nil {
		return nil, fmt.Errorf("decodificar resposta do serviço de CNPJ: %w", err)
	}
	inscricaoEstadual := ""
	for _, inscricao := range payload.InscricoesEstaduais {
		if inscricao.Ativo && inscricao.InscricaoEstadual != "" {
			inscricaoEstadual = inscricao.InscricaoEstadual
			break
		}
		if inscricaoEstadual == "" {
			inscricaoEstadual = inscricao.InscricaoEstadual
		}
	}
	return map[string]any{
		"cnpj": payload.CNPJ,
		"razao_social": payload.RazaoSocial,
		"nome_fantasia": payload.NomeFantasia,
		"inscricao_estadual": inscricaoEstadual,
		"email": payload.Email,
		"telefone": payload.Telefone,
		"endereco": map[string]any{
			"cep": payload.CEP, "logradouro": payload.Logradouro, "numero": payload.Numero,
			"complemento": payload.Complemento, "bairro": payload.Bairro,
			"cidade": payload.Cidade, "estado": payload.Estado,
		},
	}, nil
}

func (s *Service) Catalogo(ctx context.Context, tenantID, empresaID, userID int, recurso, busca string, limit, cursor int) ([]map[string]any, string, error) {
	queries := map[string]string{
		"empresas": `SELECT e.cod_empresa AS id, COALESCE(e.nome_fantasia, e.razao_social) AS nome
			FROM empresa e JOIN usuario_empresa ue ON ue.cod_tenant=e.cod_tenant
			  AND ue.cod_empresa=e.cod_empresa AND ue.cod_usuario=$4
			WHERE e.cod_tenant=$3 AND e.cod_empresa > $1 AND COALESCE(e.ativo, true)
			ORDER BY e.cod_empresa LIMIT $2`,
		"condicoes-pagamento": `SELECT codigo AS id, codigo_erp, descricao, quantidade_parcelas, prazo_medio
			FROM condicao_pagamento WHERE codigo > $1 AND COALESCE(ativo, true)
			ORDER BY codigo LIMIT $2`,
		"formas-pagamento": `SELECT codigo AS id, codigo_erp, descricao
			FROM forma_pagamento WHERE codigo > $1 AND COALESCE(ativo, true)
			ORDER BY codigo LIMIT $2`,
		"transportadoras": `SELECT codigo AS id, codigo_erp, nome_razao, cnpj_cpf
			FROM transportadora WHERE codigo > $1 AND COALESCE(ativo, true)
			ORDER BY codigo LIMIT $2`,
		"tabelas-preco": `SELECT t.codigo AS id, t.codigo_erp, t.descricao,
			  CASE WHEN MIN(i.validade_inicial) IS NULL THEN NULL ELSE
			    to_char(MIN(i.validade_inicial)::timestamp AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"Z"') END AS vigencia
			FROM tabela_preco t LEFT JOIN tabela_preco_item i
			  ON i.cod_tenant=t.cod_tenant AND i.cod_empresa=t.cod_empresa
			  AND i.codigo_erp_tabela_preco=t.codigo_erp
			WHERE t.codigo > $1 AND COALESCE(t.ativo, true)
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
			ORDER BY i.codigo LIMIT $3`,
	}
	query, ok := queries[recurso]
	if !ok {
		return nil, "", fmt.Errorf("catálogo desconhecido: %s", recurso)
	}
	var result []map[string]any
	var next string
	err := s.withSession(ctx, tenantID, empresaID, func(tx pgx.Tx) error {
		var rows pgx.Rows
		var err error
		if recurso == "produtos" {
			rows, err = tx.Query(ctx, query, cursor, busca, limit+1)
		} else if recurso == "empresas" {
			rows, err = tx.Query(ctx, query, cursor, limit+1, tenantID, userID)
		} else {
			rows, err = tx.Query(ctx, query, cursor, limit+1)
		}
		if err != nil {
			return fmt.Errorf("consultar catálogo %s: %w", recurso, err)
		}
		result, err = readRows(rows)
		if err != nil {
			return fmt.Errorf("ler catálogo %s: %w", recurso, err)
		}
		result, next = cursorPage(result, limit, "id")
		return nil
	})
	return result, next, err
}

func (s *Service) ShellEmpresaAPI(ctx context.Context, tenantID, empresaID, userID int) (map[string]any, error) {
	var result map[string]any
	err := s.withSession(ctx, tenantID, empresaID, func(tx pgx.Tx) error {
		const query = `
			SELECT COALESCE(e.nome_fantasia,e.razao_social) AS nome, e.cnpj,
			       e.regional, COALESCE(e.email,e.telefone) AS contato,
			       u.cod_usuario AS usuario_id, u.nome AS usuario_nome, u.email AS usuario_email
			FROM empresa e JOIN usuario u ON u.cod_usuario=$3
			WHERE e.cod_tenant=$1 AND e.cod_empresa=$2 AND COALESCE(e.ativo,true)
			  AND COALESCE(u.ativo,true)`
		var nome, cnpj, userName, email string
		var regional, contato *string
		var uid int
		err := tx.QueryRow(ctx, query, tenantID, empresaID, userID).Scan(
			&nome, &cnpj, &regional, &contato, &uid, &userName, &email)
		if err != nil {
			if errors.Is(err, pgx.ErrNoRows) {
				return pgx.ErrNoRows
			}
			return fmt.Errorf("consultar shell da empresa: %w", err)
		}
		result = map[string]any{
			"nome": nome, "cnpj": cnpj, "regional": regional, "contato": contato,
			"usuario_logado": map[string]any{"id": uid, "nome": userName, "email": email},
		}
		return nil
	})
	return result, err
}

func (s *Service) NotificacoesAPI(ctx context.Context, tenantID, empresaID, userID, limit, cursor int, lida *bool) ([]map[string]any, string, error) {
	var result []map[string]any
	var next string
	err := s.withSession(ctx, tenantID, empresaID, func(tx pgx.Tx) error {
		const query = `
			SELECT n.codigo AS id,n.titulo,n.mensagem,n.tipo,n.lida,
			       to_char(n.data_evento AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"Z"') AS data_evento,
			       n.origem_tabela,n.origem_id
			FROM notificacao n
			WHERE n.cod_usuario=$1
			  AND ($2::boolean IS NULL OR n.lida=$2)
			  AND ($3=0 OR (n.data_evento,n.codigo) <
			      (SELECT data_evento,codigo FROM notificacao WHERE codigo=$3 AND cod_usuario=$1))
			ORDER BY n.data_evento DESC,n.codigo DESC LIMIT $4`
		rows, err := tx.Query(ctx, query, userID, lida, cursor, limit+1)
		if err != nil {
			return fmt.Errorf("listar notificações: %w", err)
		}
		result, err = readRows(rows)
		if err != nil {
			return fmt.Errorf("ler notificações: %w", err)
		}
		result, next = cursorPage(result, limit, "id")
		return nil
	})
	return result, next, err
}

func (s *Service) ContagemNotificacoes(ctx context.Context, tenantID, empresaID, userID int) (int, error) {
	var count int
	err := s.withSession(ctx, tenantID, empresaID, func(tx pgx.Tx) error {
		err := tx.QueryRow(ctx, `SELECT COUNT(*) FROM notificacao WHERE cod_usuario=$1 AND lida=false`, userID).Scan(&count)
		if err != nil {
			return fmt.Errorf("contar notificações não lidas: %w", err)
		}
		return nil
	})
	return count, err
}

func (s *Service) AgendaListar(ctx context.Context, tenantID, empresaID, userID, limit, cursor int, concluida *bool) ([]map[string]any, string, error) {
	return s.listaPessoal(ctx, "agenda", tenantID, empresaID, userID, limit, cursor, concluida, "")
}

func (s *Service) TarefasListar(ctx context.Context, tenantID, empresaID, userID, limit, cursor int, concluida *bool, prioridade string) ([]map[string]any, string, error) {
	return s.listaPessoal(ctx, "tarefa", tenantID, empresaID, userID, limit, cursor, concluida, prioridade)
}

func (s *Service) listaPessoal(ctx context.Context, tabela string, tenantID, empresaID, userID, limit, cursor int, concluida *bool, prioridade string) ([]map[string]any, string, error) {
	query := `SELECT codigo AS id,cod_usuario,titulo,descricao,concluida,
		to_char(dt_inclusao AT TIME ZONE 'UTC','YYYY-MM-DD"T"HH24:MI:SS"Z"') AS dt_inclusao,
		to_char(dt_alteracao AT TIME ZONE 'UTC','YYYY-MM-DD"T"HH24:MI:SS"Z"') AS dt_alteracao,`
	if tabela == "agenda" {
		query += `to_char(data_agendada::timestamp AT TIME ZONE 'UTC','YYYY-MM-DD"T"HH24:MI:SS"Z"') AS data_agendada,
			CASE WHEN hora_agendada IS NULL THEN NULL ELSE to_char(hora_agendada,'HH24:MI:SS') END AS hora_agendada,
			codigo_erp_cliente`
	} else {
		query += `CASE WHEN prazo IS NULL THEN NULL ELSE to_char(prazo::timestamp AT TIME ZONE 'UTC','YYYY-MM-DD"T"HH24:MI:SS"Z"') END AS prazo,
			prioridade`
	}
	query += fmt.Sprintf(` FROM %s WHERE cod_usuario=$1 AND codigo>$2
		AND ($3::boolean IS NULL OR concluida=$3)`, tabela)
	args := []any{userID, cursor, concluida}
	if tabela == "tarefa" {
		query += " AND ($4='' OR prioridade=$4)"
		args = append(args, prioridade)
	}
	query += fmt.Sprintf(" ORDER BY codigo LIMIT $%d", len(args)+1)
	args = append(args, limit+1)
	var result []map[string]any
	var next string
	err := s.withSession(ctx, tenantID, empresaID, func(tx pgx.Tx) error {
		rows, err := tx.Query(ctx, query, args...)
		if err != nil {
			return fmt.Errorf("listar %s: %w", tabela, err)
		}
		result, err = readRows(rows)
		if err != nil {
			return fmt.Errorf("ler %s: %w", tabela, err)
		}
		result, next = cursorPage(result, limit, "id")
		return nil
	})
	return result, next, err
}

func (s *Service) IndicadoresAPI(ctx context.Context, tenantID, empresaID, userID int) (map[string]any, error) {
	var result map[string]any
	err := s.withSession(ctx, tenantID, empresaID, func(tx pgx.Tx) error {
		const query = `
			SELECT
			  COALESCE((SELECT SUM(pi.valor_total_produtos_liquido)
			    FROM pedido p JOIN pedido_item pi ON pi.cod_tenant=p.cod_tenant
			      AND pi.cod_empresa=p.cod_empresa AND pi.codigo_erp_pedido=p.codigo_erp
			    WHERE COALESCE(p.apagar_dados_pedido,false)=false AND p.e_um_orcamento=false
			      AND p.data_emissao >= date_trunc('month',CURRENT_DATE)::date
			      AND p.data_emissao < (date_trunc('month',CURRENT_DATE)+interval '1 month')::date),0) AS vendas_mes,
			  COALESCE((SELECT SUM(pi.valor_total_produtos_liquido)
			    FROM pedido p JOIN pedido_item pi ON pi.cod_tenant=p.cod_tenant
			      AND pi.cod_empresa=p.cod_empresa AND pi.codigo_erp_pedido=p.codigo_erp
			    WHERE COALESCE(p.apagar_dados_pedido,false)=false AND p.e_um_orcamento=false
			      AND p.data_emissao=CURRENT_DATE),0) AS vendas_hoje,
			  (SELECT COUNT(*) FROM pedido WHERE COALESCE(apagar_dados_pedido,false)=false
			    AND situacao_app='em_digitacao' AND e_um_orcamento=false) AS pedidos_em_digitacao,
			  (SELECT COUNT(*) FROM pedido WHERE COALESCE(apagar_dados_pedido,false)=false
			    AND situacao_app='em_digitacao' AND e_um_orcamento=true) AS orcamentos_em_digitacao,
			  (SELECT COUNT(DISTINCT codigo_erp_cliente) FROM pedido
			    WHERE COALESCE(apagar_dados_pedido,false)=false
			      AND situacao_app='em_digitacao' AND codigo_erp_cliente IS NOT NULL) AS clientes_em_digitacao,
			  (SELECT COUNT(*) FROM pedido WHERE COALESCE(apagar_dados_pedido,false)=false
			    AND situacao_app='aguardando_aprovacao' AND e_um_orcamento=false) AS pedidos_aguardando_aprovacao,
			  (SELECT COUNT(*) FROM agenda WHERE cod_usuario=$1 AND concluida=false) AS agendas_pendentes,
			  (SELECT COUNT(*) FROM tarefa WHERE cod_usuario=$1 AND concluida=false) AS tarefas_pendentes,
			  (SELECT COUNT(*) FROM notificacao WHERE cod_usuario=$1 AND lida=false) AS notificacoes_nao_lidas`
		rows, err := tx.Query(ctx, query, userID)
		if err != nil {
			return fmt.Errorf("consultar indicadores: %w", err)
		}
		items, err := readRows(rows)
		if err != nil {
			return fmt.Errorf("ler indicadores: %w", err)
		}
		if len(items) != 1 {
			return errors.New("consulta de indicadores não retornou uma linha")
		}
		result = items[0]
		return nil
	})
	return result, err
}

func parseDateTime(value string) (time.Time, error) {
	parsed, err := time.Parse(time.RFC3339, value)
	if err != nil {
		return time.Time{}, InvalidInput("data deve estar no formato ISO 8601 com timezone")
	}
	return parsed.UTC(), nil
}

func validAgendaInput(input models.AgendaCreate) (time.Time, error) {
	if strings.TrimSpace(input.Titulo) == "" {
		return time.Time{}, InvalidInput("titulo é obrigatório")
	}
	if err := validString(input.Titulo, "titulo", 200); err != nil {
		return time.Time{}, err
	}
	agendada, err := parseDateTime(input.DataAgendada)
	if err != nil {
		return time.Time{}, err
	}
	if input.HoraAgendada != nil {
		if _, err := time.Parse("15:04:05", *input.HoraAgendada); err != nil {
			if _, err = time.Parse("15:04", *input.HoraAgendada); err != nil {
				return time.Time{}, InvalidInput("hora_agendada deve usar HH:MM ou HH:MM:SS")
			}
		}
	}
	return agendada, nil
}

func validAgendaCliente(ctx context.Context, tx pgx.Tx, codigoERP *string) error {
	if codigoERP == nil || *codigoERP == "" {
		return nil
	}
	var exists bool
	if err := tx.QueryRow(ctx, `SELECT EXISTS(
		SELECT 1 FROM cliente WHERE codigo_erp=$1 AND COALESCE(ativo,true))`,
		*codigoERP).Scan(&exists); err != nil {
		return fmt.Errorf("validar cliente da agenda: %w", err)
	}
	if !exists {
		return pgx.ErrNoRows
	}
	return nil
}

func (s *Service) CriarAgenda(ctx context.Context, tenantID, empresaID, userID int, input models.AgendaCreate) (map[string]any, error) {
	agendada, err := validAgendaInput(input)
	if err != nil {
		return nil, err
	}
	var result map[string]any
	err = s.withSession(ctx, tenantID, empresaID, func(tx pgx.Tx) error {
		if err := validAgendaCliente(ctx, tx, input.CodigoERPCliente); err != nil {
			return err
		}
		var id int
		err := tx.QueryRow(ctx, `
			INSERT INTO agenda (cod_tenant,cod_empresa,cod_usuario,codigo_erp_cliente,
				titulo,descricao,data_agendada,hora_agendada)
			VALUES ($1,$2,$3,$4,$5,$6,$7,$8) RETURNING codigo`,
			tenantID, empresaID, userID, input.CodigoERPCliente, input.Titulo,
			input.Descricao, agendada, input.HoraAgendada).Scan(&id)
		if err != nil {
			return fmt.Errorf("criar compromisso: %w", err)
		}
		result, err = resourceByID(ctx, tx, "agenda", id, userID)
		return err
	})
	return result, err
}

func (s *Service) ObterAgenda(ctx context.Context, tenantID, empresaID, userID, id int) (map[string]any, error) {
	var result map[string]any
	err := s.withSession(ctx, tenantID, empresaID, func(tx pgx.Tx) error {
		var err error
		result, err = resourceByID(ctx, tx, "agenda", id, userID)
		return err
	})
	return result, err
}

func (s *Service) AtualizarAgenda(ctx context.Context, tenantID, empresaID, userID, id int, input models.AgendaCreate) (map[string]any, error) {
	agendada, err := validAgendaInput(input)
	if err != nil {
		return nil, err
	}
	var result map[string]any
	err = s.withSession(ctx, tenantID, empresaID, func(tx pgx.Tx) error {
		if err := validAgendaCliente(ctx, tx, input.CodigoERPCliente); err != nil {
			return err
		}
		tag, err := tx.Exec(ctx, `
			UPDATE agenda SET titulo=$4,descricao=$5,data_agendada=$6,hora_agendada=$7,
			  codigo_erp_cliente=$8
			WHERE cod_tenant=$1 AND cod_empresa=$2 AND codigo=$3 AND cod_usuario=$9`,
			tenantID, empresaID, id, input.Titulo, input.Descricao, agendada,
			input.HoraAgendada, input.CodigoERPCliente, userID)
		if err != nil {
			return fmt.Errorf("atualizar compromisso: %w", err)
		}
		if tag.RowsAffected() == 0 {
			return pgx.ErrNoRows
		}
		result, err = resourceByID(ctx, tx, "agenda", id, userID)
		return err
	})
	return result, err
}

func (s *Service) ConcluirAgenda(ctx context.Context, tenantID, empresaID, userID, id int) (map[string]any, error) {
	return s.concluirPessoal(ctx, "agenda", tenantID, empresaID, userID, id)
}

func (s *Service) CriarTarefa(ctx context.Context, tenantID, empresaID, userID int, input models.TarefaCreate) (map[string]any, error) {
	if strings.TrimSpace(input.Titulo) == "" {
		return nil, InvalidInput("titulo é obrigatório")
	}
	if err := validString(input.Titulo, "titulo", 200); err != nil {
		return nil, err
	}
	if input.Prioridade == "" {
		input.Prioridade = "media"
	}
	if input.Prioridade != "baixa" && input.Prioridade != "media" && input.Prioridade != "alta" {
		return nil, InvalidInput("prioridade deve ser baixa, media ou alta")
	}
	var prazo *time.Time
	if input.Prazo != nil {
		value, err := parseDateTime(*input.Prazo)
		if err != nil {
			return nil, err
		}
		prazo = &value
	}
	var result map[string]any
	err := s.withSession(ctx, tenantID, empresaID, func(tx pgx.Tx) error {
		var id int
		err := tx.QueryRow(ctx, `
			INSERT INTO tarefa (cod_tenant,cod_empresa,cod_usuario,titulo,descricao,prazo,prioridade)
			VALUES ($1,$2,$3,$4,$5,$6,$7) RETURNING codigo`,
			tenantID, empresaID, userID, input.Titulo, input.Descricao, prazo, input.Prioridade).Scan(&id)
		if err != nil {
			return fmt.Errorf("criar tarefa: %w", err)
		}
		result, err = resourceByID(ctx, tx, "tarefa", id, userID)
		return err
	})
	return result, err
}

func (s *Service) ObterTarefa(ctx context.Context, tenantID, empresaID, userID, id int) (map[string]any, error) {
	var result map[string]any
	err := s.withSession(ctx, tenantID, empresaID, func(tx pgx.Tx) error {
		var err error
		result, err = resourceByID(ctx, tx, "tarefa", id, userID)
		return err
	})
	return result, err
}

func (s *Service) AtualizarTarefa(ctx context.Context, tenantID, empresaID, userID, id int, input models.TarefaCreate) (map[string]any, error) {
	if strings.TrimSpace(input.Titulo) == "" {
		return nil, InvalidInput("titulo é obrigatório")
	}
	if err := validString(input.Titulo, "titulo", 200); err != nil {
		return nil, err
	}
	if input.Prioridade == "" {
		input.Prioridade = "media"
	}
	if input.Prioridade != "baixa" && input.Prioridade != "media" && input.Prioridade != "alta" {
		return nil, InvalidInput("prioridade deve ser baixa, media ou alta")
	}
	var prazo *time.Time
	if input.Prazo != nil {
		value, err := parseDateTime(*input.Prazo)
		if err != nil {
			return nil, err
		}
		prazo = &value
	}
	var result map[string]any
	err := s.withSession(ctx, tenantID, empresaID, func(tx pgx.Tx) error {
		tag, err := tx.Exec(ctx, `
			UPDATE tarefa SET titulo=$4,descricao=$5,prazo=$6,prioridade=$7
			WHERE cod_tenant=$1 AND cod_empresa=$2 AND codigo=$3 AND cod_usuario=$8`,
			tenantID, empresaID, id, input.Titulo, input.Descricao, prazo, input.Prioridade, userID)
		if err != nil {
			return fmt.Errorf("atualizar tarefa: %w", err)
		}
		if tag.RowsAffected() == 0 {
			return pgx.ErrNoRows
		}
		result, err = resourceByID(ctx, tx, "tarefa", id, userID)
		return err
	})
	return result, err
}

func (s *Service) ConcluirTarefa(ctx context.Context, tenantID, empresaID, userID, id int) (map[string]any, error) {
	return s.concluirPessoal(ctx, "tarefa", tenantID, empresaID, userID, id)
}

func (s *Service) concluirPessoal(ctx context.Context, tabela string, tenantID, empresaID, userID, id int) (map[string]any, error) {
	var result map[string]any
	err := s.withSession(ctx, tenantID, empresaID, func(tx pgx.Tx) error {
		tag, err := tx.Exec(ctx, fmt.Sprintf(`
			UPDATE %s SET concluida=true
			WHERE cod_tenant=$1 AND cod_empresa=$2 AND codigo=$3 AND cod_usuario=$4`,
			tabela), tenantID, empresaID, id, userID)
		if err != nil {
			return fmt.Errorf("concluir %s: %w", tabela, err)
		}
		if tag.RowsAffected() == 0 {
			return pgx.ErrNoRows
		}
		result, err = resourceByID(ctx, tx, tabela, id, userID)
		return err
	})
	return result, err
}

func resourceByID(ctx context.Context, tx pgx.Tx, tabela string, id, userID int) (map[string]any, error) {
	var query string
	switch tabela {
	case "agenda":
		query = `SELECT codigo AS id,cod_usuario,titulo,descricao,
			to_char(data_agendada::timestamp AT TIME ZONE 'UTC','YYYY-MM-DD"T"HH24:MI:SS"Z"') AS data_agendada,
			CASE WHEN hora_agendada IS NULL THEN NULL ELSE to_char(hora_agendada,'HH24:MI:SS') END AS hora_agendada,
			codigo_erp_cliente,concluida,
			to_char(dt_inclusao AT TIME ZONE 'UTC','YYYY-MM-DD"T"HH24:MI:SS"Z"') AS dt_inclusao,
			to_char(dt_alteracao AT TIME ZONE 'UTC','YYYY-MM-DD"T"HH24:MI:SS"Z"') AS dt_alteracao
			FROM agenda WHERE codigo=$1 AND cod_usuario=$2`
	case "tarefa":
		query = `SELECT codigo AS id,cod_usuario,titulo,descricao,
			CASE WHEN prazo IS NULL THEN NULL ELSE to_char(prazo::timestamp AT TIME ZONE 'UTC','YYYY-MM-DD"T"HH24:MI:SS"Z"') END AS prazo,
			prioridade,concluida,
			to_char(dt_inclusao AT TIME ZONE 'UTC','YYYY-MM-DD"T"HH24:MI:SS"Z"') AS dt_inclusao,
			to_char(dt_alteracao AT TIME ZONE 'UTC','YYYY-MM-DD"T"HH24:MI:SS"Z"') AS dt_alteracao
			FROM tarefa WHERE codigo=$1 AND cod_usuario=$2`
	default:
		return nil, fmt.Errorf("recurso não suportado: %s", tabela)
	}
	rows, err := tx.Query(ctx, query, id, userID)
	if err != nil {
		return nil, fmt.Errorf("consultar %s: %w", tabela, err)
	}
	items, err := readRows(rows)
	if err != nil {
		return nil, fmt.Errorf("ler %s: %w", tabela, err)
	}
	if len(items) == 0 {
		return nil, pgx.ErrNoRows
	}
	return items[0], nil
}

func (s *Service) PedidosListarAPI(ctx context.Context, tenantID, empresaID int, status string, clienteID *int, limit, cursor int, orcamento bool) ([]map[string]any, string, error) {
	var result []map[string]any
	var next string
	err := s.withSession(ctx, tenantID, empresaID, func(tx pgx.Tx) error {
		const query = `
			SELECT p.codigo AS id, COALESCE(p.nosso_codigo_pedido,p.codigo_erp) AS numero,
			       CASE WHEN p.e_um_orcamento THEN 'orcamento' ELSE 'pedido' END AS tipo,
			       c.nome_razao_social AS cliente_nome,
			       CASE WHEN p.data_emissao IS NULL THEN NULL ELSE
			         to_char(p.data_emissao::timestamp AT TIME ZONE 'UTC','YYYY-MM-DD"T"HH24:MI:SS"Z"') END AS data_emissao,
			       p.situacao_app AS status,p.situacao_pedido AS status_erp,
			       CASE p.situacao_pedido
			         WHEN '1' THEN 'Aberto' WHEN '2' THEN 'Cancelado'
			         WHEN '3' THEN 'Faturado Total' WHEN '4' THEN 'Expedido'
			         WHEN '5' THEN 'Entregue' WHEN '7' THEN 'Faturado Parcial/Encerrado'
			         WHEN '8' THEN 'Faturado Parcial/Aberto' WHEN '11' THEN 'Orçamento Revisado'
			         WHEN '12' THEN 'Orçamento Aprovado' ELSE NULL END AS status_erp_label,
			       COALESCE(SUM(pi.valor_total_produtos_liquido),0) AS total_liquido
			FROM pedido p
			LEFT JOIN cliente c ON c.cod_tenant=p.cod_tenant AND c.cod_empresa=p.cod_empresa
			  AND c.codigo_erp=p.codigo_erp_cliente
			LEFT JOIN pedido_item pi ON pi.cod_tenant=p.cod_tenant AND pi.cod_empresa=p.cod_empresa
			  AND pi.codigo_erp_pedido=p.codigo_erp
			WHERE p.codigo > $1 AND p.e_um_orcamento=$2
			  AND ($3='' OR p.situacao_app=$3)
			  AND ($4::integer IS NULL OR c.codigo=$4)
			  AND COALESCE(p.apagar_dados_pedido,false)=false
			GROUP BY p.codigo,p.nosso_codigo_pedido,p.codigo_erp,p.e_um_orcamento,
			         c.nome_razao_social,p.data_emissao,p.situacao_app,p.situacao_pedido
			ORDER BY p.codigo ASC LIMIT $5`
		rows, err := tx.Query(ctx, query, cursor, orcamento, status, clienteID, limit+1)
		if err != nil {
			return fmt.Errorf("listar pedidos: %w", err)
		}
		result, err = readRows(rows)
		if err != nil {
			return fmt.Errorf("ler pedidos: %w", err)
		}
		result, next = cursorPage(result, limit, "id")
		return nil
	})
	return result, next, err
}

func (s *Service) PedidoObterAPI(ctx context.Context, tenantID, empresaID, id int) (map[string]any, error) {
	var result map[string]any
	err := s.withSession(ctx, tenantID, empresaID, func(tx pgx.Tx) error {
		var err error
		result, err = pedidoDetalhe(ctx, tx, id)
		return err
	})
	return result, err
}

func pedidoDetalhe(ctx context.Context, tx pgx.Tx, id int) (map[string]any, error) {
	rows, err := tx.Query(ctx, `
		SELECT p.codigo AS id,p.codigo_erp,
		       COALESCE(p.nosso_codigo_pedido,p.codigo_erp) AS numero,
		       p.nro_pedido_cliente AS numero_cliente,
		       CASE WHEN p.e_um_orcamento THEN 'orcamento' ELSE 'pedido' END AS tipo,
		       p.situacao_app AS status,p.situacao_pedido AS status_erp,
		       CASE p.situacao_pedido
		         WHEN '1' THEN 'Aberto' WHEN '2' THEN 'Cancelado' WHEN '3' THEN 'Faturado Total'
		         WHEN '4' THEN 'Expedido' WHEN '5' THEN 'Entregue'
		         WHEN '7' THEN 'Faturado Parcial/Encerrado' WHEN '8' THEN 'Faturado Parcial/Aberto'
		         WHEN '11' THEN 'Orçamento Revisado' WHEN '12' THEN 'Orçamento Aprovado' ELSE NULL END AS status_erp_label,
		       CASE WHEN p.data_emissao IS NULL THEN NULL ELSE
		         to_char(p.data_emissao::timestamp AT TIME ZONE 'UTC','YYYY-MM-DD"T"HH24:MI:SS"Z"') END AS data_emissao,
		       c.codigo AS cliente_id,c.nome_razao_social AS cliente_nome,c.cnpj_cpf AS cliente_cnpj_cpf,
		       p.valor_frete,p.observacoes_pedido,p.observacoes_nota_fiscal,
		       e.cod_empresa AS empresa_id,
		       COALESCE(e.nome_fantasia,e.razao_social) AS empresa_nome,
		       cp.codigo AS condicao_pagamento_id,cp.descricao AS condicao_pagamento_descricao,
		       fp.codigo AS forma_pagamento_id,fp.descricao AS forma_pagamento_descricao,
		       tr.codigo AS transportadora_id,tr.nome_razao AS transportadora_nome
		FROM pedido p
		LEFT JOIN cliente c ON c.cod_tenant=p.cod_tenant AND c.cod_empresa=p.cod_empresa
		  AND c.codigo_erp=p.codigo_erp_cliente
		LEFT JOIN empresa e ON e.cod_tenant=p.cod_tenant AND e.cod_empresa=p.cod_empresa
		LEFT JOIN condicao_pagamento cp ON cp.cod_tenant=p.cod_tenant AND cp.cod_empresa=p.cod_empresa
		  AND cp.codigo_erp=p.codigo_erp_condicao_pagamento
		LEFT JOIN forma_pagamento fp ON fp.cod_tenant=p.cod_tenant AND fp.cod_empresa=p.cod_empresa
		  AND fp.codigo_erp=p.codigo_erp_forma_pagamento
		LEFT JOIN transportadora tr ON tr.cod_tenant=p.cod_tenant AND tr.cod_empresa=p.cod_empresa
		  AND tr.codigo_erp=p.codigo_erp_transportadora
		WHERE p.codigo=$1 AND COALESCE(p.apagar_dados_pedido,false)=false`, id)
	if err != nil {
		return nil, fmt.Errorf("consultar pedido: %w", err)
	}
	orders, err := readRows(rows)
	if err != nil {
		return nil, fmt.Errorf("ler pedido: %w", err)
	}
	if len(orders) == 0 {
		return nil, pgx.ErrNoRows
	}
	order := orders[0]
	if customerID, ok := order["cliente_id"]; ok && customerID != nil {
		order["cliente"] = map[string]any{
			"id": customerID, "nome_razao_social": order["cliente_nome"], "cnpj_cpf": order["cliente_cnpj_cpf"],
		}
	} else {
		delete(order, "cliente")
	}
	delete(order, "cliente_id")
	delete(order, "cliente_nome")
	delete(order, "cliente_cnpj_cpf")
	order["empresa"] = map[string]any{"id": order["empresa_id"], "nome": order["empresa_nome"]}
	delete(order, "empresa_id")
	delete(order, "empresa_nome")
	for _, reference := range []struct {
		key         string
		idKey       string
		description string
		name        string
	}{
		{key: "condicao_pagamento", idKey: "condicao_pagamento_id", description: "condicao_pagamento_descricao"},
		{key: "forma_pagamento", idKey: "forma_pagamento_id", description: "forma_pagamento_descricao"},
		{key: "transportadora", idKey: "transportadora_id", name: "transportadora_nome"},
	} {
		id, exists := order[reference.idKey]
		if !exists || id == nil {
			order[reference.key] = nil
		} else if reference.name != "" {
			order[reference.key] = map[string]any{"id": id, "nome": order[reference.name]}
		} else {
			order[reference.key] = map[string]any{"id": id, "descricao": order[reference.description]}
		}
		delete(order, reference.idKey)
		delete(order, reference.description)
		delete(order, reference.name)
	}

	items, err := pedidoItens(ctx, tx, fmt.Sprint(order["codigo_erp"]))
	if err != nil {
		return nil, err
	}
	order["itens"] = items
	order["totais"] = calcularTotais(items)
	for _, item := range items {
		if product, ok := item["product"].(map[string]any); ok {
			delete(product, "_cubagem")
			delete(product, "_volumes")
		}
	}
	return order, nil
}

func pedidoItens(ctx context.Context, tx pgx.Tx, codigoErpPedido string) ([]map[string]any, error) {
	rows, err := tx.Query(ctx, `
		SELECT pi.codigo AS id,COALESCE(NULLIF(pi.codigo_erp_item_pedido,''),'0') AS sequence,
		       i.codigo AS product_id,i.codigo_erp AS product_codigo_erp,i.descricao AS product_descricao,
		       COALESCE(i.descricao_categoria_nivel1,i.descricao_categoria_nivel2,i.descricao_categoria_nivel3) AS product_familia,
		       i.apelido_fantasia_fabricante AS product_marca,u.sigla AS product_unidade,
		       COALESCE(i.preco_venda,0) AS product_preco_venda,
		       COALESCE((SELECT SUM(ie.quantidade) FROM item_estoque ie
		         WHERE ie.cod_tenant=i.cod_tenant AND ie.cod_empresa=i.cod_empresa
		           AND ie.codigo_erp_item=i.codigo_erp),0) AS product_stock,
		       COALESCE(i.peso_liquido,0) AS product_peso_liquido,
		       COALESCE(i.peso_bruto,0) AS product_peso_bruto,
		       COALESCE(i.cubagem_embalagem,0) AS product_cubagem,
		       COALESCE(i.qtde_volumes_embalagem,0) AS product_volumes,
		       pi.codigo_erp_tabela_preco,pi.preco_venda_praticado_digitado AS sale_price,
		       pi.preco_venda_original_sugerido AS original_price,
		       pi.quantidade_informada,pi.valor_desconto_comercial,
		       pi.valor_total_produtos_liquido,
		       CASE WHEN pi.data_entrega IS NULL THEN NULL ELSE
		         to_char(pi.data_entrega::timestamp AT TIME ZONE 'UTC','YYYY-MM-DD"T"HH24:MI:SS"Z"') END AS data_entrega,
		       pi.observacao_item,
		       tp.codigo AS price_table_id,tp.descricao AS price_table_name,
		       CASE WHEN validity.validade_inicial IS NULL THEN NULL ELSE
		         to_char(validity.validade_inicial::timestamp AT TIME ZONE 'UTC',
		           'YYYY-MM-DD"T"HH24:MI:SS"Z"') END AS price_table_validity
		FROM pedido_item pi
		LEFT JOIN pedido p ON p.cod_tenant=pi.cod_tenant AND p.cod_empresa=pi.cod_empresa
		  AND p.codigo_erp=pi.codigo_erp_pedido
		LEFT JOIN item i ON i.cod_tenant=pi.cod_tenant AND i.cod_empresa=pi.cod_empresa
		  AND i.codigo_erp=pi.codigo_erp_produto
		LEFT JOIN unidade_medida u ON u.cod_tenant=i.cod_tenant AND u.cod_empresa=i.cod_empresa
		  AND u.codigo_erp=i.codigo_erp_unidade_medida
		LEFT JOIN tabela_preco tp ON tp.cod_tenant=pi.cod_tenant AND tp.cod_empresa=pi.cod_empresa
		  AND tp.codigo_erp=pi.codigo_erp_tabela_preco
		LEFT JOIN LATERAL (
		  SELECT tpi.validade_inicial
		  FROM tabela_preco_item tpi
		  WHERE tpi.cod_tenant=pi.cod_tenant AND tpi.cod_empresa=pi.cod_empresa
		    AND tpi.codigo_erp_item=pi.codigo_erp_produto
		    AND tpi.codigo_erp_tabela_preco=pi.codigo_erp_tabela_preco
		    AND (tpi.validade_inicial IS NULL OR p.data_emissao IS NULL
		         OR tpi.validade_inicial<=p.data_emissao)
		    AND (tpi.validade_final IS NULL OR p.data_emissao IS NULL
		         OR tpi.validade_final>=p.data_emissao)
		  ORDER BY tpi.validade_inicial DESC NULLS LAST LIMIT 1
		) validity ON true
		WHERE pi.codigo_erp_pedido=$1
		ORDER BY pi.codigo_erp_item_pedido,pi.codigo`, codigoErpPedido)
	if err != nil {
		return nil, fmt.Errorf("consultar itens do pedido: %w", err)
	}
	rowsAsMaps, err := readRows(rows)
	if err != nil {
		return nil, fmt.Errorf("ler itens do pedido: %w", err)
	}
	items := make([]map[string]any, 0, len(rowsAsMaps))
	for _, row := range rowsAsMaps {
		product := map[string]any{
			"id": row["product_id"], "codigo_erp": row["product_codigo_erp"],
			"descricao": row["product_descricao"], "familia": row["product_familia"],
			"marca": row["product_marca"], "unidade": row["product_unidade"],
			"preco_venda": row["product_preco_venda"], "stock": row["product_stock"],
			"peso_liquido": row["product_peso_liquido"], "peso_bruto": row["product_peso_bruto"],
			"_cubagem": row["product_cubagem"], "_volumes": row["product_volumes"],
		}
		item := map[string]any{
			"id": row["id"], "sequence": parseSequence(row["sequence"]), "product": product,
			"price_table_id": row["price_table_id"], "price_table_name": row["price_table_name"],
			"quantidade_informada": row["quantidade_informada"], "sale_price": row["sale_price"],
			"original_price": row["original_price"], "valor_desconto_comercial": row["valor_desconto_comercial"],
			"valor_total_produtos_liquido": row["valor_total_produtos_liquido"],
			"data_entrega": row["data_entrega"], "observacao_item": row["observacao_item"],
		}
		if row["price_table_validity"] != nil {
			item["price_table_validity"] = row["price_table_validity"]
		}
		items = append(items, item)
	}
	return items, nil
}

func parseSequence(value any) int {
	parsed, _ := strconv.Atoi(fmt.Sprint(value))
	return parsed
}

func number(value any) float64 {
	switch v := value.(type) {
	case int:
		return float64(v)
	case int32:
		return float64(v)
	case int64:
		return float64(v)
	case float32:
		return float64(v)
	case float64:
		return v
	default:
		n, _ := strconv.ParseFloat(fmt.Sprint(value), 64)
		return n
	}
}

func calcularTotais(items []map[string]any) map[string]any {
	var qty, volumeQty, cubic, netWeight, grossWeight, gross, discount float64
	products := make(map[any]struct{})
	for _, item := range items {
		product, _ := item["product"].(map[string]any)
		quantity := number(item["quantidade_informada"])
		qty += quantity
		volumeQty += quantity * number(product["_volumes"])
		cubic += quantity * number(product["_cubagem"])
		netWeight += number(product["peso_liquido"]) * quantity
		grossWeight += number(product["peso_bruto"]) * quantity
		discount += number(item["valor_desconto_comercial"])
		gross += number(item["sale_price"]) * quantity
		products[product["id"]] = struct{}{}
	}
	net := gross - discount
	return map[string]any{
		"quantidade_mix": len(products), "quantidade_volume": volumeQty, "volume_total_cubico": cubic,
		"peso_liquido": netWeight, "peso_bruto": grossWeight, "valor_bruto": gross,
		"valor_desconto": discount, "valor_liquido": net,
	}
}

func resolveERPCode(ctx context.Context, tx pgx.Tx, table string, id *int) (*string, error) {
	if id == nil {
		return nil, nil
	}
	allowed := map[string]bool{
		"cliente": true, "condicao_pagamento": true, "forma_pagamento": true,
		"transportadora": true, "tabela_preco": true,
	}
	if !allowed[table] {
		return nil, fmt.Errorf("referência não suportada: %s", table)
	}
	var code string
	err := tx.QueryRow(ctx, fmt.Sprintf("SELECT codigo_erp FROM %s WHERE codigo=$1 AND COALESCE(ativo,true)", table), *id).Scan(&code)
	if err != nil {
		return nil, err
	}
	return &code, nil
}

func (s *Service) CriarPedido(ctx context.Context, tenantID, empresaID int, input models.PedidoCreate) (map[string]any, error) {
	if input.Tipo != "pedido" && input.Tipo != "orcamento" {
		return nil, InvalidInput("tipo deve ser pedido ou orcamento")
	}
	emissao, err := parseDateTime(input.DataEmissao)
	if err != nil {
		return nil, err
	}
	var orderDelivery *time.Time
	if input.DataEntrega != nil {
		value, err := parseDateTime(*input.DataEntrega)
		if err != nil {
			return nil, err
		}
		orderDelivery = &value
	}
	status := "em_digitacao"
	if input.Status != nil {
		status = *input.Status
	}
	switch status {
	case "em_digitacao", "aguardando_aprovacao", "aprovado", "cancelado":
	default:
		return nil, InvalidInput("status inválido")
	}
	if input.EmpresaID != nil && *input.EmpresaID != empresaID {
		return nil, InvalidInput("empresa_id deve corresponder à empresa da sessão")
	}
	var result map[string]any
	err = s.withSession(ctx, tenantID, empresaID, func(tx pgx.Tx) error {
		customerCode, err := resolveERPCode(ctx, tx, "cliente", input.ClienteID)
		if err != nil {
			return fmt.Errorf("cliente não encontrado: %w", err)
		}
		conditionCode, err := resolveERPCode(ctx, tx, "condicao_pagamento", input.CondicaoPagamentoID)
		if err != nil {
			return fmt.Errorf("condição de pagamento não encontrada: %w", err)
		}
		methodCode, err := resolveERPCode(ctx, tx, "forma_pagamento", input.FormaPagamentoID)
		if err != nil {
			return fmt.Errorf("forma de pagamento não encontrada: %w", err)
		}
		carrierCode, err := resolveERPCode(ctx, tx, "transportadora", input.TransportadoraID)
		if err != nil {
			return fmt.Errorf("transportadora não encontrada: %w", err)
		}
		addressCodes := make([]*string, 3)
		for i, addressID := range []*int{input.EnderecoFaturamentoID, input.EnderecoEntregaID, input.EnderecoCobrancaID} {
			if addressID == nil {
				continue
			}
			if customerCode == nil {
				return InvalidInput("endereços de pedido exigem cliente_id")
			}
			var code string
			if err := tx.QueryRow(ctx, `SELECT e.identificacao_endereco
				FROM cliente_endereco_adicional e
				WHERE e.codigo=$1 AND e.codigo_erp_cliente=$2`, *addressID, *customerCode).Scan(&code); err != nil {
				return fmt.Errorf("endereço do cliente não encontrado: %w", err)
			}
			addressCodes[i] = &code
		}
		var orderID int
		if err := tx.QueryRow(ctx, "SELECT nextval('public.pedido_codigo_seq')").Scan(&orderID); err != nil {
			return fmt.Errorf("gerar identificador do pedido: %w", err)
		}
		orderERP := fmt.Sprintf("API-%d", orderID)
		orderNumber := strconv.Itoa(orderID)
		_, err = tx.Exec(ctx, `
			INSERT INTO pedido (
				cod_tenant,cod_empresa,codigo,codigo_erp,nosso_codigo_pedido,nro_pedido_cliente,
				e_um_orcamento,data_emissao,codigo_erp_cliente,cliente_cnpj_cpf,
				codigo_erp_condicao_pagamento,codigo_erp_forma_pagamento,codigo_erp_transportadora,
				endereco_ident_faturamento,endereco_ident_entrega,endereco_ident_cobranca,
				valor_frete,observacoes_pedido,observacoes_nota_fiscal,situacao_app
			) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,
				(SELECT cnpj_cpf FROM cliente WHERE codigo=$10),
				$11,$12,$13,$14,$15,$16,$17,$18,$19,$20)`,
			tenantID, empresaID, orderID, orderERP, orderNumber, input.NumeroCliente,
			input.Tipo == "orcamento", emissao, customerCode, input.ClienteID,
			conditionCode, methodCode, carrierCode, addressCodes[0], addressCodes[1],
			addressCodes[2], input.ValorFrete, input.ObservacoesPedido,
			input.ObservacoesNotaFiscal, status)
		if err != nil {
			return fmt.Errorf("criar pedido: %w", err)
		}
		sequences := make(map[int]struct{}, len(input.Itens))
		for index, item := range input.Itens {
			if item.Sequence <= 0 || item.QuantidadeInformada <= 0 || item.SalePrice < 0 {
				return InvalidInput(fmt.Sprintf("item %d: sequence, quantidade e preço devem ser válidos", index+1))
			}
			if _, exists := sequences[item.Sequence]; exists {
				return InvalidInput(fmt.Sprintf("item %d: sequence duplicada", index+1))
			}
			sequences[item.Sequence] = struct{}{}
			var productCode string
			productQuery := `SELECT codigo_erp FROM item WHERE COALESCE(ativo,true) AND `
			var productQueryValue any
			if item.Product.ID > 0 {
				productQuery += "codigo=$1"
				productQueryValue = item.Product.ID
			} else if item.Product.CodigoERP != "" {
				productQuery += "codigo_erp=$1"
				productQueryValue = item.Product.CodigoERP
			} else {
				return InvalidInput(fmt.Sprintf("item %d: product.id ou product.codigo_erp é obrigatório", index+1))
			}
			if err := tx.QueryRow(ctx, productQuery, productQueryValue).Scan(&productCode); err != nil {
				return fmt.Errorf("produto não encontrado: %w", err)
			}
			if item.Product.CodigoERP != "" && item.Product.CodigoERP != productCode {
				return InvalidInput("codigo_erp do produto não corresponde ao id")
			}
			priceCode, err := resolveERPCode(ctx, tx, "tabela_preco", item.PriceTableID)
			if err != nil {
				return fmt.Errorf("tabela de preço não encontrada: %w", err)
			}
			total := item.QuantidadeInformada*item.SalePrice - item.ValorDescontoComercial
			if total < 0 {
				return InvalidInput(fmt.Sprintf("item %d: desconto excede o valor bruto", index+1))
			}
			var dataEntrega any = orderDelivery
			if item.DataEntrega != nil {
				data, err := parseDateTime(*item.DataEntrega)
				if err != nil {
					return err
				}
				dataEntrega = data
			}
			_, err = tx.Exec(ctx, `
				INSERT INTO pedido_item (
					cod_tenant,cod_empresa,codigo_erp_pedido,codigo_erp_item_pedido,
					codigo_erp_produto,codigo_erp_tabela_preco,preco_venda_original_sugerido,
					preco_venda_praticado_digitado,quantidade_informada,
					valor_desconto_comercial,valor_total_produtos_liquido,data_entrega,observacao_item
				) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13)`,
				tenantID, empresaID, orderERP, strconv.Itoa(item.Sequence), productCode,
				priceCode, item.OriginalPrice, item.SalePrice, item.QuantidadeInformada,
				item.ValorDescontoComercial, total, dataEntrega, item.ObservacaoItem)
			if err != nil {
				return fmt.Errorf("salvar item %d: %w", index+1, err)
			}
		}
		result, err = pedidoDetalhe(ctx, tx, orderID)
		return err
	})
	return result, err
}

func (s *Service) RemoverPedido(ctx context.Context, tenantID, empresaID, id int) error {
	return s.withSession(ctx, tenantID, empresaID, func(tx pgx.Tx) error {
		tag, err := tx.Exec(ctx, `UPDATE pedido SET apagar_dados_pedido=true
			WHERE cod_tenant=$1 AND cod_empresa=$2 AND codigo=$3
			  AND COALESCE(apagar_dados_pedido,false)=false`, tenantID, empresaID, id)
		if err != nil {
			return fmt.Errorf("marcar pedido para remoção: %w", err)
		}
		if tag.RowsAffected() == 0 {
			return pgx.ErrNoRows
		}
		return nil
	})
}
