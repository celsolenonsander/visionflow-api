package catalogo

import "testing"

func TestQueryForCatalogResource(t *testing.T) {
	tests := []struct {
		resource string
		want     bool
	}{
		{resource: "empresas", want: true},
		{resource: "condicoes-pagamento", want: true},
		{resource: "formas-pagamento", want: true},
		{resource: "transportadoras", want: true},
		{resource: "tabelas-preco", want: true},
		{resource: "produtos", want: true},
		{resource: "not-a-catalog", want: false},
	}

	for _, test := range tests {
		t.Run(test.resource, func(t *testing.T) {
			query, ok := queryFor(test.resource)
			if ok != test.want {
				t.Fatalf("queryFor() found = %t, want %t", ok, test.want)
			}
			if ok && query == "" {
				t.Fatal("queryFor() returned an empty query")
			}
		})
	}
}
