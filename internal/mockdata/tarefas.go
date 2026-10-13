package mockdata

import "github.com/celsolenonsander/visionflow-api/internal/models"

func Tarefas() []models.Tarefa {
	return []models.Tarefa{
		{
			ID:             1,
			Titulo:         "Aprovar pedido 1001",
			Status:         "pendente",
			DataVencimento: "2026-10-08T00:00:00Z",
		},
		{
			ID:             2,
			Titulo:         "Retornar ligação do cliente",
			Status:         "pendente",
			DataVencimento: "2026-10-08T14:00:00Z",
		},
		{
			ID:             3,
			Titulo:         "Enviar orçamento 9002",
			Status:         "em_andamento",
			DataVencimento: "2026-10-09T00:00:00Z",
		},
		{
			ID:             4,
			Titulo:         "Confirmar visita comercial",
			Status:         "pendente",
			DataVencimento: "2026-10-09T10:00:00Z",
		},
		{
			ID:             5,
			Titulo:         "Atualizar cadastro do cliente",
			Status:         "pendente",
			DataVencimento: "2026-10-10T00:00:00Z",
		},
		{
			ID:             6,
			Titulo:         "Conferir pedido 1007",
			Status:         "concluida",
			DataVencimento: "2026-10-05T00:00:00Z",
		},
		{
			ID:             7,
			Titulo:         "Enviar proposta comercial",
			Status:         "em_andamento",
			DataVencimento: "2026-10-10T15:00:00Z",
		},
		{
			ID:             8,
			Titulo:         "Verificar limite de crédito",
			Status:         "pendente",
			DataVencimento: "2026-10-11T00:00:00Z",
		},
		{
			ID:             9,
			Titulo:         "Confirmar condição de pagamento",
			Status:         "pendente",
			DataVencimento: "2026-10-11T14:30:00Z",
		},
		{
			ID:             10,
			Titulo:         "Revisar pedidos em digitação",
			Status:         "em_andamento",
			DataVencimento: "2026-10-12T00:00:00Z",
		},
		{
			ID:             11,
			Titulo:         "Entrar em contato com cliente inativo",
			Status:         "pendente",
			DataVencimento: "2026-10-13T09:00:00Z",
		},
		{
			ID:             12,
			Titulo:         "Conferir documentos cadastrais",
			Status:         "concluida",
			DataVencimento: "2026-10-04T00:00:00Z",
		},
		{
			ID:             13,
			Titulo:         "Preparar reunião comercial",
			Status:         "pendente",
			DataVencimento: "2026-10-14T10:00:00Z",
		},
		{
			ID:             14,
			Titulo:         "Atualizar tabela de preços",
			Status:         "em_andamento",
			DataVencimento: "2026-10-15T00:00:00Z",
		},
		{
			ID:             15,
			Titulo:         "Verificar pedidos aguardando aprovação",
			Status:         "pendente",
			DataVencimento: "2026-10-15T16:00:00Z",
		},
	}
}
