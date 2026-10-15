package service

import (
	"context"
	"errors"
	"fmt"
	"strconv"
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
	return db.ReadRows(rows)
}

func cursorPage(rows []map[string]any, limit int, cursorKey string) ([]map[string]any, string) {
	return db.CursorPage(rows, limit, cursorKey)
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

func parseDateTime(value string) (time.Time, error) {
	parsed, err := time.Parse(time.RFC3339, value)
	if err != nil {
		return time.Time{}, InvalidInput("data deve estar no formato ISO 8601 com timezone")
	}
	return parsed.UTC(), nil
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
			"data_entrega":                 row["data_entrega"], "observacao_item": row["observacao_item"],
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
