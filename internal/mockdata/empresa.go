package mockdata

import "github.com/celsolenonsander/visionflow-api/internal/models"

func ShellEmpresa() models.ShellEmpresa {
	return models.ShellEmpresa{
		Nome:     "Vision Flow Distribuidora",
		CNPJ:     "12.345.678/0001-90",
		Regional: "Rio Claro - SP",
		Contato:  "(19) 3524-1234",
		UsuarioLogado: models.UsuarioShell{
			ID:    1,
			Nome:  "Régys Borges",
			Email: "admin@visionflow.app",
		},
	}
}
