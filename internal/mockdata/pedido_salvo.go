package mockdata

import "github.com/celsolenonsander/visionflow-api/internal/models"

func SalvarPedido(req models.PedidoRequest) models.PedidoSalvo {
	return models.PedidoSalvo{
		ID:     1001,
		Numero: "1001",
		Status: "em_digitacao",
	}
}
