package mockdata

import "github.com/celsolenonsander/visionflow-api/internal/models"

func ClienteCNPJ(cnpj string) (models.ClienteCNPJ, bool) {
	return models.ClienteCNPJ{
		CNPJ:              "61.186.888/0001-93",
		RazaoSocial:       "EMPRESA EXEMPLO LTDA",
		NomeFantasia:      "Exemplo",
		InscricaoEstadual: "123.456.789.012",
		Email:             "contato@exemplo.com.br",
		Telefone:          "(34) 98822-1845",
		Endereco: models.Endereco{
			Logradouro:  "AVENIDA 52",
			Numero:      "S/N",
			Complemento: "",
			Bairro:      "ALTO DO SANTANA",
			Cidade:      "RIO CLARO",
			Estado:      "SP",
			CEP:         "13504-185",
		},
	}, true
}
