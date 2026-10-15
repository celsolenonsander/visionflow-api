package tarefa

import (
	"errors"
	"strings"
	"testing"

	"github.com/celsolenonsander/visionflow-api/internal/models"
	"github.com/celsolenonsander/visionflow-api/internal/platform/apperrors"
)

func TestValidateInput(t *testing.T) {
	tests := []struct {
		name      string
		input     models.TarefaCreate
		wantDue   bool
		wantError bool
	}{
		{name: "default priority", input: models.TarefaCreate{Titulo: "Tarefa"}},
		{name: "valid due date", input: models.TarefaCreate{Titulo: "Tarefa", Prazo: stringPointer("2026-10-14T15:30:00-03:00")}, wantDue: true},
		{name: "missing title", input: models.TarefaCreate{Prioridade: "media"}, wantError: true},
		{name: "title exceeds database length", input: models.TarefaCreate{Titulo: strings.Repeat("x", 201)}, wantError: true},
		{name: "invalid priority", input: models.TarefaCreate{Titulo: "Tarefa", Prioridade: "urgente"}, wantError: true},
		{name: "invalid due date", input: models.TarefaCreate{Titulo: "Tarefa", Prazo: stringPointer("2026-10-14")}, wantError: true},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			due, err := validateInput(&test.input)
			if (err != nil) != test.wantError {
				t.Fatalf("validateInput() error = %v, wantError %t", err, test.wantError)
			}
			if test.wantError && !errors.Is(err, apperrors.ErrInvalidInput) {
				t.Fatalf("validateInput() error = %v, want invalid input", err)
			}
			if (due != nil) != test.wantDue {
				t.Fatalf("validateInput() due = %v, wantDue %t", due, test.wantDue)
			}
		})
	}
}

func stringPointer(value string) *string {
	return &value
}
