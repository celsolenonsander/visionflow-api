package mockdata

import "github.com/celsolenonsander/visionflow-api/internal/models"

func NotificacoesCount() models.NotificacaoCount {
	return models.NotificacaoCount{
		NaoLidas: 8,
	}
}
