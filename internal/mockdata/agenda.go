package mockdata

import "github.com/celsolenonsander/visionflow-api/internal/models"

func Agenda() []models.Agenda {
	return []models.Agenda{
		{
			ID:          1,
			Titulo:      "Visita a cliente",
			Data:        "2026-10-07T10:00:00Z",
			Status:      "pendente",
			ClienteNome: "ALESSANDRO SILVA TOMAZ",
		},
		{
			ID:          2,
			Titulo:      "Reunião comercial",
			Data:        "2026-10-07T14:30:00Z",
			Status:      "pendente",
			ClienteNome: "MERCADO BOM PREÇO LTDA",
		},
		{
			ID:          3,
			Titulo:      "Apresentação de orçamento",
			Data:        "2026-10-08T09:00:00Z",
			Status:      "pendente",
			ClienteNome: "DISTRIBUIDORA SÃO PAULO LTDA",
		},
		{
			ID:          4,
			Titulo:      "Retorno comercial",
			Data:        "2026-10-08T11:30:00Z",
			Status:      "confirmado",
			ClienteNome: "CASA DAS FERRAMENTAS LTDA",
		},
		{
			ID:          5,
			Titulo:      "Visita técnica",
			Data:        "2026-10-08T15:00:00Z",
			Status:      "pendente",
			ClienteNome: "ATACADO BRASIL COMERCIAL LTDA",
		},
		{
			ID:          6,
			Titulo:      "Reunião de negociação",
			Data:        "2026-10-09T09:30:00Z",
			Status:      "confirmado",
			ClienteNome: "REDE SUPERMERCADOS CENTRAL",
		},
		{
			ID:          7,
			Titulo:      "Ligação para cliente",
			Data:        "2026-10-09T13:00:00Z",
			Status:      "pendente",
			ClienteNome: "MARIA APARECIDA LIMA",
		},
		{
			ID:          8,
			Titulo:      "Apresentação de proposta",
			Data:        "2026-10-09T16:00:00Z",
			Status:      "pendente",
			ClienteNome: "COMERCIAL NOVA ERA LTDA",
		},
		{
			ID:          9,
			Titulo:      "Visita comercial",
			Data:        "2026-10-10T10:00:00Z",
			Status:      "confirmado",
			ClienteNome: "LOGÍSTICA EXPRESS LTDA",
		},
		{
			ID:          10,
			Titulo:      "Reunião com comprador",
			Data:        "2026-10-10T14:00:00Z",
			Status:      "pendente",
			ClienteNome: "PONTO CERTO MATERIAIS LTDA",
		},
		{
			ID:          11,
			Titulo:      "Retorno de orçamento",
			Data:        "2026-10-11T09:00:00Z",
			Status:      "pendente",
			ClienteNome: "INDÚSTRIA ALFA LTDA",
		},
		{
			ID:          12,
			Titulo:      "Visita a novo cliente",
			Data:        "2026-10-11T15:30:00Z",
			Status:      "pendente",
			ClienteNome: "SUPRIMENTOS BRASIL LTDA",
		},
	}
}
