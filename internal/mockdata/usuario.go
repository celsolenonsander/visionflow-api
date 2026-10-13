package mockdata

import "github.com/celsolenonsander/visionflow-api/internal/models"

func Login(email, senha string) (models.Usuario, bool) {
	if email != "admin@visionflow.app" || senha != "123456" {
		return models.Usuario{}, false
	}

	return models.Usuario{
		ID:    1,
		Nome:  "Régys Borges",
		Email: email,
	}, true
}
