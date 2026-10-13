package httpapi

import (
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/celsolenonsander/visionflow-api/internal/logger"
	"github.com/celsolenonsander/visionflow-api/internal/service"
)

func TestHealth(t *testing.T) {
	appLogger, err := logger.NewWithDir(t.TempDir())
	if err != nil {
		t.Fatalf("erro ao criar logger: %v", err)
	}
	defer appLogger.Close()

	r := Routes(
		NewHandler(service.New(), "secret"),
		"secret",
		appLogger,
	)

	req := httptest.NewRequest(
		http.MethodGet,
		"/health",
		nil,
	)

	rec := httptest.NewRecorder()

	r.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("status = %d", rec.Code)
	}
}
