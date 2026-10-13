package main

import (
	"log"
	"net/http"
	"os"

	"github.com/celsolenonsander/visionflow-api/internal/httpapi"
	"github.com/celsolenonsander/visionflow-api/internal/logger"
	"github.com/celsolenonsander/visionflow-api/internal/service"
)

func main() {
	port := getenv("APP_PORT", "8080")
	secret := getenv("JWT_SECRET", "troque-esta-chave-em-producao")

	logFile, err := logger.New()
	if err != nil {
		log.Fatalf("Erro ao inicializar logger: %v", err)
	}
	defer logFile.Close()

	svc := service.New()

	// O Handler precisa conhecer o mesmo JWT_SECRET
	// usado pelo middleware para validar os tokens.
	h := httpapi.NewHandler(svc, secret)

	router := httpapi.Routes(h, secret, logFile)

	addr := ":" + port

	logFile.Printf(
		"VisionFlow API rodando em http://localhost%s",
		addr,
	)

	logFile.Printf(
		"Swagger: http://localhost%s/swagger/index.html",
		addr,
	)

	if err := http.ListenAndServe(addr, router); err != nil {
		logFile.Printf(
			"Erro ao iniciar servidor: %v",
			err,
		)
	}
}

func getenv(key, fallback string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}

	return fallback
}
