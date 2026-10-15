package service

import (
	"testing"
	"time"
)

func TestValidPage(t *testing.T) {
	tests := []struct {
		name       string
		limit      string
		cursor     string
		wantLimit  int
		wantCursor int
		wantErr    bool
	}{
		{name: "defaults", wantLimit: 20},
		{name: "valid values", limit: "50", cursor: "24129", wantLimit: 50, wantCursor: 24129},
		{name: "limit too large", limit: "101", wantErr: true},
		{name: "nonpositive cursor", cursor: "0", wantErr: true},
		{name: "malformed cursor", cursor: "x", wantErr: true},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			limit, cursor, err := validPage(test.limit, test.cursor)
			if (err != nil) != test.wantErr {
				t.Fatalf("validPage() error = %v, wantErr %t", err, test.wantErr)
			}
			if err == nil && (limit != test.wantLimit || cursor != test.wantCursor) {
				t.Fatalf("validPage() = (%d, %d), want (%d, %d)",
					limit, cursor, test.wantLimit, test.wantCursor)
			}
		})
	}
}

func TestParseDateTime(t *testing.T) {
	input := "2026-10-14T15:30:00-03:00"
	got, err := parseDateTime(input)
	if err != nil {
		t.Fatalf("parseDateTime(%q) error = %v", input, err)
	}
	want := time.Date(2026, 10, 14, 18, 30, 0, 0, time.UTC)
	if !got.Equal(want) {
		t.Fatalf("parseDateTime(%q) = %s, want %s", input, got, want)
	}

	if _, err := parseDateTime("2026-10-14T15:30:00"); err == nil {
		t.Fatal("parseDateTime accepted a datetime without timezone")
	}
}

func TestCalcularTotais(t *testing.T) {
	items := []map[string]any{
		{
			"product": map[string]any{
				"id": 88, "_volumes": 1, "_cubagem": 0.008,
				"peso_liquido": 2.0, "peso_bruto": 2.1,
			},
			"quantidade_informada":     10.0,
			"sale_price":               8.5,
			"valor_desconto_comercial": 5.0,
		},
	}
	totals := calcularTotais(items)
	if got := number(totals["valor_bruto"]); got != 85 {
		t.Fatalf("valor_bruto = %v, want 85", got)
	}
	if got := number(totals["valor_desconto"]); got != 5 {
		t.Fatalf("valor_desconto = %v, want 5", got)
	}
	if got := number(totals["valor_liquido"]); got != 80 {
		t.Fatalf("valor_liquido = %v, want 80", got)
	}
	if got := totals["quantidade_mix"]; got != 1 {
		t.Fatalf("quantidade_mix = %v, want 1", got)
	}
}
