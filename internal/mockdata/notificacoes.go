package mockdata

import "github.com/celsolenonsander/visionflow-api/internal/models"

func Notificacoes() []models.Notificacao {
	return []models.Notificacao{
		{
			ID:     1,
			Titulo: "Pedido 1001 aguardando aprovação",
			Lida:   false,
			Data:   "2026-10-06T08:15:00Z",
		},
		{
			ID:     2,
			Titulo: "Novo cliente cadastrado",
			Lida:   false,
			Data:   "2026-10-06T08:05:00Z",
		},
		{
			ID:     3,
			Titulo: "Pedido 1002 aprovado",
			Lida:   true,
			Data:   "2026-10-05T16:30:00Z",
		},
		{
			ID:     4,
			Titulo: "Orçamento 9002 aguardando aprovação",
			Lida:   false,
			Data:   "2026-10-05T14:20:00Z",
		},
		{
			ID:     5,
			Titulo: "Novo orçamento recebido",
			Lida:   true,
			Data:   "2026-10-05T11:45:00Z",
		},
		{
			ID:     6,
			Titulo: "Pedido 1004 faturado",
			Lida:   true,
			Data:   "2026-10-04T17:10:00Z",
		},
		{
			ID:     7,
			Titulo: "Cliente com cadastro pendente",
			Lida:   false,
			Data:   "2026-10-04T15:30:00Z",
		},
		{
			ID:     8,
			Titulo: "Nova tarefa atribuída",
			Lida:   false,
			Data:   "2026-10-04T13:15:00Z",
		},
		{
			ID:     9,
			Titulo: "Visita comercial confirmada",
			Lida:   true,
			Data:   "2026-10-03T16:40:00Z",
		},
		{
			ID:     10,
			Titulo: "Pedido 1007 aguardando aprovação",
			Lida:   false,
			Data:   "2026-10-03T10:25:00Z",
		},
		{
			ID:     11,
			Titulo: "Orçamento 9006 aprovado",
			Lida:   true,
			Data:   "2026-10-02T17:00:00Z",
		},
		{
			ID:     12,
			Titulo: "Cliente solicitou contato",
			Lida:   false,
			Data:   "2026-10-02T14:50:00Z",
		},
		{
			ID:     13,
			Titulo: "Pedido 1013 faturado",
			Lida:   true,
			Data:   "2026-10-01T16:15:00Z",
		},
		{
			ID:     14,
			Titulo: "Nova agenda cadastrada",
			Lida:   false,
			Data:   "2026-10-01T09:30:00Z",
		},
		{
			ID:     15,
			Titulo: "Tarefa próxima do vencimento",
			Lida:   false,
			Data:   "2026-09-30T08:45:00Z",
		},
	}
}
