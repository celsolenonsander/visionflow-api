package agenda

import (
	"errors"
	"testing"

	"github.com/celsolenonsander/visionflow-api/internal/models"
	"github.com/celsolenonsander/visionflow-api/internal/platform/apperrors"
)

func TestValidateInput(t *testing.T) {
	hour := "14:30"
	tests := []struct {
		name    string
		input   models.AgendaCreate
		wantErr bool
	}{
		{name: "valid", input: models.AgendaCreate{Titulo: "Visita", DataAgendada: "2026-10-14T00:00:00-03:00", HoraAgendada: &hour}},
		{name: "missing title", input: models.AgendaCreate{DataAgendada: "2026-10-14T00:00:00Z"}, wantErr: true},
		{name: "date without timezone", input: models.AgendaCreate{Titulo: "Visita", DataAgendada: "2026-10-14T00:00:00"}, wantErr: true},
		{name: "invalid hour", input: models.AgendaCreate{Titulo: "Visita", DataAgendada: "2026-10-14T00:00:00Z", HoraAgendada: stringPointer("25:00")}, wantErr: true},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			_, err := validateInput(test.input)
			if (err != nil) != test.wantErr {
				t.Fatalf("validateInput() error = %v, wantErr %t", err, test.wantErr)
			}
			if test.wantErr && !errors.Is(err, apperrors.ErrInvalidInput) {
				t.Fatalf("validateInput() error = %v, want invalid input", err)
			}
		})
	}
}

func stringPointer(value string) *string {
	return &value
}
