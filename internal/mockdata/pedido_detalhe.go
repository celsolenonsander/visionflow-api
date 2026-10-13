package mockdata

import "github.com/celsolenonsander/visionflow-api/internal/models"

func Pedido(id int) (models.PedidoDetalhe, bool) {
	pedidos := map[int]models.PedidoDetalhe{
		1001: {
			ID:            1001,
			Tipo:          "pedido",
			Numero:        "1001",
			NumeroCliente: "OC-2026-045",
			Status:        "em_digitacao",
			DataEmissao:   "2026-10-05T08:15:00Z",
			DataEntrega:   "2026-10-10T00:00:00Z",
			Empresa: models.EmpresaRef{
				ID:   1,
				Nome: "Vision Flow Distribuidora",
			},
			Cliente: models.ClienteRef{
				ID:      24129,
				Nome:    "ALESSANDRO SILVA TOMAZ",
				CPFCNPJ: "039.441.526-46",
			},
			CondicaoPagamento: models.DescricaoRef{
				ID:        3,
				Descricao: "30/60/90 dias",
			},
			FormaPagamento: models.DescricaoRef{
				ID:        2,
				Descricao: "Boleto",
			},
			Transportadora: models.NomeRef{
				ID:   7,
				Nome: "Transportes Silva",
			},
			ValorFrete: 120.00,
			Itens: []models.PedidoItem{
				{
					Sequencia: 1,
					Produto: models.ProdutoRef{
						ID:        555,
						Codigo:    "P555",
						Descricao: "Cabo Flexível 2,5mm",
						Unidade:   "MT",
					},
					Quantidade:    50,
					PrecoVenda:    4.75,
					ValorDesconto: 10.00,
					TotalItem:     227.50,
				},
				{
					Sequencia: 2,
					Produto: models.ProdutoRef{
						ID:        556,
						Codigo:    "P556",
						Descricao: "Cabo Flexível 4mm",
						Unidade:   "MT",
					},
					Quantidade:    20,
					PrecoVenda:    6.50,
					ValorDesconto: 5.00,
					TotalItem:     125.00,
				},
			},
			Totais: models.PedidoTotais{
				TotalBruto:    362.50,
				TotalDesconto: 15.00,
				TotalLiquido:  347.50,
			},
		},

		1002: {
			ID:            1002,
			Tipo:          "pedido",
			Numero:        "1002",
			NumeroCliente: "PED-CLIENTE-2026-102",
			Status:        "aguardando_aprovacao",
			DataEmissao:   "2026-10-04T09:30:00Z",
			DataEntrega:   "2026-10-12T00:00:00Z",
			Empresa: models.EmpresaRef{
				ID:   1,
				Nome: "Vision Flow Distribuidora",
			},
			Cliente: models.ClienteRef{
				ID:      24130,
				Nome:    "MERCADO BOM PREÇO LTDA",
				CPFCNPJ: "12.345.678/0001-10",
			},
			CondicaoPagamento: models.DescricaoRef{
				ID:        4,
				Descricao: "28 dias",
			},
			FormaPagamento: models.DescricaoRef{
				ID:        2,
				Descricao: "Boleto",
			},
			Transportadora: models.NomeRef{
				ID:   8,
				Nome: "Expresso Rio Claro",
			},
			ValorFrete: 85.00,
			Itens: []models.PedidoItem{
				{
					Sequencia: 1,
					Produto: models.ProdutoRef{
						ID:        601,
						Codigo:    "P601",
						Descricao: "Lâmpada LED 9W",
						Unidade:   "UN",
					},
					Quantidade:    100,
					PrecoVenda:    8.50,
					ValorDesconto: 25.00,
					TotalItem:     825.00,
				},
				{
					Sequencia: 2,
					Produto: models.ProdutoRef{
						ID:        602,
						Codigo:    "P602",
						Descricao: "Lâmpada LED 12W",
						Unidade:   "UN",
					},
					Quantidade:    80,
					PrecoVenda:    11.25,
					ValorDesconto: 25.00,
					TotalItem:     875.00,
				},
			},
			Totais: models.PedidoTotais{
				TotalBruto:    1750.00,
				TotalDesconto: 50.00,
				TotalLiquido:  1700.00,
			},
		},

		1003: {
			ID:            1003,
			Tipo:          "pedido",
			Numero:        "1003",
			NumeroCliente: "OC-4587",
			Status:        "aprovado",
			DataEmissao:   "2026-10-03T14:20:00Z",
			DataEntrega:   "2026-10-09T00:00:00Z",
			Empresa: models.EmpresaRef{
				ID:   1,
				Nome: "Vision Flow Distribuidora",
			},
			Cliente: models.ClienteRef{
				ID:      24131,
				Nome:    "DISTRIBUIDORA SÃO PAULO LTDA",
				CPFCNPJ: "23.456.789/0001-21",
			},
			CondicaoPagamento: models.DescricaoRef{
				ID:        5,
				Descricao: "21/42 dias",
			},
			FormaPagamento: models.DescricaoRef{
				ID:        2,
				Descricao: "Boleto",
			},
			Transportadora: models.NomeRef{
				ID:   9,
				Nome: "Translog Brasil",
			},
			ValorFrete: 150.00,
			Itens: []models.PedidoItem{
				{
					Sequencia: 1,
					Produto: models.ProdutoRef{
						ID:        710,
						Codigo:    "P710",
						Descricao: "Disjuntor 20A",
						Unidade:   "UN",
					},
					Quantidade:    100,
					PrecoVenda:    18.50,
					ValorDesconto: 50.00,
					TotalItem:     1800.00,
				},
				{
					Sequencia: 2,
					Produto: models.ProdutoRef{
						ID:        711,
						Codigo:    "P711",
						Descricao: "Disjuntor 32A",
						Unidade:   "UN",
					},
					Quantidade:    100,
					PrecoVenda:    22.80,
					ValorDesconto: 70.00,
					TotalItem:     2210.00,
				},
				{
					Sequencia: 3,
					Produto: models.ProdutoRef{
						ID:        712,
						Codigo:    "P712",
						Descricao: "Disjuntor 40A",
						Unidade:   "UN",
					},
					Quantidade:    50,
					PrecoVenda:    24.50,
					ValorDesconto: 40.00,
					TotalItem:     1185.00,
				},
			},
			Totais: models.PedidoTotais{
				TotalBruto:    3600.00,
				TotalDesconto: 160.00,
				TotalLiquido:  3440.00,
			},
		},
	}

	pedido, ok := pedidos[id]
	return pedido, ok
}
