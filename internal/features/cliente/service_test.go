package cliente

import (
	"errors"
	"strings"
	"testing"

	"github.com/celsolenonsander/visionflow-api/internal/models"
	"github.com/celsolenonsander/visionflow-api/internal/platform/apperrors"
)

func TestClienteValidation(t *testing.T) {
	tests := []struct {
		name    string
		input   models.ClienteCreate
		wantErr bool
	}{
		{name: "valid PJ", input: models.ClienteCreate{NomeRazaoSocial: "Empresa", TipoPessoa: "PJ"}},
		{name: "valid formatted CNPJ", input: models.ClienteCreate{NomeRazaoSocial: "Empresa", TipoPessoa: "PJ", CNPJCPF: "11.111.111/1111-11", EmailContatoComprador: "compras@example.com"}},
		{name: "missing name", input: models.ClienteCreate{TipoPessoa: "PJ"}, wantErr: true},
		{name: "invalid person type", input: models.ClienteCreate{NomeRazaoSocial: "Empresa", TipoPessoa: "X"}, wantErr: true},
		{name: "invalid document length", input: models.ClienteCreate{NomeRazaoSocial: "Empresa", TipoPessoa: "PJ", CNPJCPF: "123"}, wantErr: true},
		{name: "invalid email", input: models.ClienteCreate{NomeRazaoSocial: "Empresa", TipoPessoa: "PJ", EmailContatoComprador: "invalid"}, wantErr: true},
		{name: "field exceeds database length", input: models.ClienteCreate{NomeRazaoSocial: strings.Repeat("x", 101), TipoPessoa: "PJ"}, wantErr: true},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			err := validCliente(test.input)
			if (err != nil) != test.wantErr {
				t.Fatalf("validCliente() error = %v, wantErr %t", err, test.wantErr)
			}
			if test.wantErr && !errors.Is(err, apperrors.ErrInvalidInput) {
				t.Fatalf("validCliente() error = %v, want invalid input", err)
			}
		})
	}
}

func TestDatabasePersonTypeMapping(t *testing.T) {
	for _, test := range []struct {
		input string
		want  string
	}{{"PF", "F"}, {"PJ", "J"}} {
		if got := bancoTipoPessoa(test.input); got != test.want {
			t.Errorf("bancoTipoPessoa(%q) = %q, want %q", test.input, got, test.want)
		}
	}
}

func TestDatabaseAddressTypeMapping(t *testing.T) {
	for _, test := range []struct {
		input string
		want  string
	}{{"C", "C"}, {"E", "E"}, {"A", "A"}, {"cobranca", "C"}, {"entrega", "E"}, {"ambos", "A"}} {
		got, err := bancoTipoEndereco(test.input)
		if err != nil || got != test.want {
			t.Errorf("bancoTipoEndereco(%q) = %q, %v, want %q", test.input, got, err, test.want)
		}
	}
	if _, err := bancoTipoEndereco("residencial"); !errors.Is(err, apperrors.ErrInvalidInput) {
		t.Fatalf("bancoTipoEndereco(residencial) error = %v, want invalid input", err)
	}
}

func TestValidEndereco(t *testing.T) {
	valid := models.EnderecoCreate{
		TipoEndereco: "entrega", CEP: "01310-100", Logradouro: "Avenida Paulista",
		NumeroEndereco: "1000", Bairro: "Bela Vista", Cidade: "São Paulo", Estado: "SP",
	}
	tests := []struct {
		name       string
		input      models.EnderecoCreate
		wantDBType string
		wantErr    bool
	}{
		{name: "valid", input: valid, wantDBType: "E"},
		{name: "missing address type", input: models.EnderecoCreate{
			CEP: valid.CEP, Logradouro: valid.Logradouro, NumeroEndereco: valid.NumeroEndereco,
			Bairro: valid.Bairro, Cidade: valid.Cidade, Estado: valid.Estado,
		}, wantErr: true},
		{name: "invalid address type", input: models.EnderecoCreate{
			TipoEndereco: "residencial", CEP: valid.CEP, Logradouro: valid.Logradouro,
			NumeroEndereco: valid.NumeroEndereco, Bairro: valid.Bairro, Cidade: valid.Cidade, Estado: valid.Estado,
		}, wantErr: true},
		{name: "missing required field", input: models.EnderecoCreate{
			TipoEndereco: valid.TipoEndereco, CEP: valid.CEP, Logradouro: valid.Logradouro,
			NumeroEndereco: valid.NumeroEndereco, Bairro: valid.Bairro, Cidade: valid.Cidade,
		}, wantErr: true},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			got, err := validEndereco(test.input)
			if (err != nil) != test.wantErr {
				t.Fatalf("validEndereco() error = %v, wantErr %t", err, test.wantErr)
			}
			if test.wantErr {
				if !errors.Is(err, apperrors.ErrInvalidInput) {
					t.Fatalf("validEndereco() error = %v, want invalid input", err)
				}
				return
			}
			if got != test.wantDBType {
				t.Fatalf("validEndereco() type = %q, want %q", got, test.wantDBType)
			}
		})
	}
}
