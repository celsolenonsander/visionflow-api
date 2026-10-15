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
		{name: "missing name", input: models.ClienteCreate{TipoPessoa: "PJ"}, wantErr: true},
		{name: "invalid person type", input: models.ClienteCreate{NomeRazaoSocial: "Empresa", TipoPessoa: "X"}, wantErr: true},
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
	}{{"cobranca", "C"}, {"entrega", "E"}, {"ambos", "A"}} {
		got, err := bancoTipoEndereco(test.input)
		if err != nil || got != test.want {
			t.Errorf("bancoTipoEndereco(%q) = %q, %v, want %q", test.input, got, err, test.want)
		}
	}
	if _, err := bancoTipoEndereco("residencial"); !errors.Is(err, apperrors.ErrInvalidInput) {
		t.Fatalf("bancoTipoEndereco(residencial) error = %v, want invalid input", err)
	}
}
