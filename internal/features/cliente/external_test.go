package cliente

import (
	"context"
	"errors"
	"io"
	"net/http"
	"strings"
	"testing"

	"github.com/celsolenonsander/visionflow-api/internal/platform/apperrors"
	"github.com/jackc/pgx/v5"
)

func TestConsultarCEP(t *testing.T) {
	tests := []struct {
		name       string
		cep        string
		status     int
		body       string
		transport  error
		wantErr    error
		wantStatus string
	}{
		{name: "invalid CEP", cep: "123", wantErr: apperrors.ErrInvalidInput},
		{name: "success", cep: "01.001-000", status: http.StatusOK,
			body: `{"cep":"01001-000","logradouro":"Praça da Sé","bairro":"Sé","localidade":"São Paulo","uf":"SP"}`},
		{name: "not found", cep: "01001000", status: http.StatusOK, body: `{"erro":true}`, wantErr: pgx.ErrNoRows},
		{name: "provider error", cep: "01001000", status: http.StatusServiceUnavailable, body: `{}`, wantStatus: "503"},
		{name: "transport error", cep: "01001000", transport: errors.New("network unavailable"), wantStatus: "consultar serviço de CEP"},
		{name: "invalid provider JSON", cep: "01001000", status: http.StatusOK, body: `{`, wantStatus: "decodificar resposta do serviço de CEP"},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			service := &Service{httpTransport: roundTripperFunc(func(request *http.Request) (*http.Response, error) {
				if request.URL.Host != "viacep.com.br" || request.URL.Path != "/ws/01001000/json/" {
					t.Fatalf("unexpected CEP request URL: %s", request.URL)
				}
				if test.transport != nil {
					return nil, test.transport
				}
				return httpResponse(test.status, test.body), nil
			})}

			got, err := service.ConsultarCEP(context.Background(), test.cep)
			if test.wantErr != nil {
				if !errors.Is(err, test.wantErr) {
					t.Fatalf("ConsultarCEP() error = %v, want %v", err, test.wantErr)
				}
				return
			}
			if test.wantStatus != "" {
				if err == nil || !strings.Contains(err.Error(), test.wantStatus) {
					t.Fatalf("ConsultarCEP() error = %v, want substring %q", err, test.wantStatus)
				}
				return
			}
			if err != nil {
				t.Fatalf("ConsultarCEP() error = %v", err)
			}
			if got["cep"] != "01001-000" || got["cidade"] != "São Paulo" || got["estado"] != "SP" {
				t.Fatalf("ConsultarCEP() = %#v, unexpected mapped response", got)
			}
		})
	}
}

func TestConsultarCNPJ(t *testing.T) {
	tests := []struct {
		name       string
		cnpj       string
		status     int
		body       string
		wantErr    error
		wantStatus string
	}{
		{name: "invalid CNPJ", cnpj: "123", wantErr: apperrors.ErrInvalidInput},
		{name: "success", cnpj: "11.222.333/0001-81", status: http.StatusOK,
			body: `{"cnpj":"11222333000181","razao_social":"Empresa Exemplo","inscricoes_estaduais":[{"inscricao_estadual":"123","ativo":false},{"inscricao_estadual":"456","ativo":true}]}`},
		{name: "not found", cnpj: "11222333000181", status: http.StatusNotFound, body: `{}`, wantErr: pgx.ErrNoRows},
		{name: "provider error", cnpj: "11222333000181", status: http.StatusBadGateway, body: `{}`, wantStatus: "502"},
		{name: "invalid provider JSON", cnpj: "11222333000181", status: http.StatusOK, body: `{`, wantStatus: "decodificar resposta do serviço de CNPJ"},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			service := &Service{httpTransport: roundTripperFunc(func(request *http.Request) (*http.Response, error) {
				if request.URL.Host != "brasilapi.com.br" || request.URL.Path != "/api/cnpj/v1/11222333000181" {
					t.Fatalf("unexpected CNPJ request URL: %s", request.URL)
				}
				return httpResponse(test.status, test.body), nil
			})}

			got, err := service.ConsultarCNPJ(context.Background(), test.cnpj)
			if test.wantErr != nil {
				if !errors.Is(err, test.wantErr) {
					t.Fatalf("ConsultarCNPJ() error = %v, want %v", err, test.wantErr)
				}
				return
			}
			if test.wantStatus != "" {
				if err == nil || !strings.Contains(err.Error(), test.wantStatus) {
					t.Fatalf("ConsultarCNPJ() error = %v, want substring %q", err, test.wantStatus)
				}
				return
			}
			if err != nil {
				t.Fatalf("ConsultarCNPJ() error = %v", err)
			}
			if got["cnpj"] != "11222333000181" || got["inscricao_estadual"] != "456" {
				t.Fatalf("ConsultarCNPJ() = %#v, unexpected mapped response", got)
			}
		})
	}
}

type roundTripperFunc func(*http.Request) (*http.Response, error)

func (f roundTripperFunc) RoundTrip(request *http.Request) (*http.Response, error) {
	return f(request)
}

func httpResponse(status int, body string) *http.Response {
	return &http.Response{
		StatusCode: status,
		Body:       io.NopCloser(strings.NewReader(body)),
		Header:     make(http.Header),
	}
}
