package mockdata

import "github.com/celsolenonsander/visionflow-api/internal/models"

func Indicadores() models.Indicadores {
	return models.Indicadores{
		VendasMes:                  128450.75,
		VendasHoje:                 3240.0,
		PedidosEmDigitacao:         3,
		OrcamentosEmDigitacao:      1,
		ClientesEmDigitacao:        5,
		PedidosAguardandoAprovacao: 2,
		AgendasPendentes:           4,
		TarefasPendentes:           7,
		NotificacoesNaoLidas:       2,
	}
}
