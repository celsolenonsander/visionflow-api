package logger

import (
	"fmt"
	"io"
	"log"
	"os"
	"path/filepath"
	"strings"
	"sync"
	"time"
)

const (
	defaultLogDir      = "logs"
	logFilePrefix      = "api-"
	logFileExtension   = ".log"
	logRetentionDays   = 30
	logDateFormat      = "2006-01-02"
	logTimestampFormat = "2006/01/02 15:04:05"
)

type Logger struct {
	mu          sync.Mutex
	logDir      string
	currentDate string
	file        *os.File
	logger      *log.Logger
}

// New cria um novo logger.
//
// Os logs são enviados simultaneamente para:
//   - terminal
//   - arquivo logs/api-YYYY-MM-DD.log
//
// Também remove automaticamente arquivos com mais de 30 dias.
func New() (*Logger, error) {
	return NewWithDir(defaultLogDir)
}

// NewWithDir permite definir uma pasta personalizada para os logs.
func NewWithDir(logDir string) (*Logger, error) {
	if logDir == "" {
		logDir = defaultLogDir
	}

	if err := os.MkdirAll(logDir, 0755); err != nil {
		return nil, fmt.Errorf("criar diretório de logs: %w", err)
	}

	l := &Logger{
		logDir: logDir,
	}

	if err := l.openTodayFile(); err != nil {
		return nil, err
	}

	// Limpa logs antigos ao iniciar a aplicação.
	if err := l.cleanOldLogs(); err != nil {
		// A limpeza dos logs não deve impedir a API de iniciar.
		log.Printf("WARN: não foi possível limpar logs antigos: %v", err)
	}

	return l, nil
}

// openTodayFile abre o arquivo correspondente ao dia atual.
func (l *Logger) openTodayFile() error {
	today := time.Now().Format(logDateFormat)

	// Se já estamos usando o arquivo do dia, não precisamos fazer nada.
	if l.file != nil && l.currentDate == today {
		return nil
	}

	// Fecha o arquivo anterior.
	if l.file != nil {
		if err := l.file.Close(); err != nil {
			return fmt.Errorf("fechar arquivo de log anterior: %w", err)
		}

		l.file = nil
	}

	filename := filepath.Join(
		l.logDir,
		logFilePrefix+today+logFileExtension,
	)

	file, err := os.OpenFile(
		filename,
		os.O_CREATE|os.O_APPEND|os.O_WRONLY,
		0644,
	)
	if err != nil {
		return fmt.Errorf(
			"abrir arquivo de log %s: %w",
			filename,
			err,
		)
	}

	l.file = file
	l.currentDate = today

	// MultiWriter envia a mesma mensagem para:
	// 1. terminal
	// 2. arquivo
	output := io.MultiWriter(os.Stdout, file)

	l.logger = log.New(
		output,
		"",
		0,
	)

	return nil
}

// Printf escreve uma mensagem formatada no log.
func (l *Logger) Printf(format string, args ...interface{}) {
	l.mu.Lock()
	defer l.mu.Unlock()

	if err := l.openTodayFile(); err != nil {
		log.Printf("ERRO LOGGER: %v", err)
		return
	}

	l.logger.Printf(
		"%s %s",
		time.Now().Format(logTimestampFormat),
		fmt.Sprintf(format, args...),
	)
}

// Println escreve uma mensagem no log.
func (l *Logger) Println(args ...interface{}) {
	l.mu.Lock()
	defer l.mu.Unlock()

	if err := l.openTodayFile(); err != nil {
		log.Printf("ERRO LOGGER: %v", err)
		return
	}

	l.logger.Printf(
		"%s %s",
		time.Now().Format(logTimestampFormat),
		strings.TrimSuffix(fmt.Sprintln(args...), "\n"),
	)
}

// cleanOldLogs remove arquivos de log com mais de 30 dias.
func (l *Logger) cleanOldLogs() error {
	entries, err := os.ReadDir(l.logDir)
	if err != nil {
		return fmt.Errorf("ler diretório de logs: %w", err)
	}

	cutoff := time.Now().AddDate(0, 0, -logRetentionDays)

	for _, entry := range entries {
		if entry.IsDir() {
			continue
		}

		name := entry.Name()

		// Só processa arquivos no padrão:
		// api-YYYY-MM-DD.log
		if !strings.HasPrefix(name, logFilePrefix) ||
			!strings.HasSuffix(name, logFileExtension) {
			continue
		}

		dateString := strings.TrimPrefix(
			name,
			logFilePrefix,
		)

		dateString = strings.TrimSuffix(
			dateString,
			logFileExtension,
		)

		fileDate, err := time.Parse(
			logDateFormat,
			dateString,
		)
		if err != nil {
			// Ignora arquivos que não seguem o padrão esperado.
			continue
		}

		if fileDate.Before(cutoff) {
			path := filepath.Join(l.logDir, name)

			if err := os.Remove(path); err != nil {
				log.Printf(
					"WARN: não foi possível remover log antigo %s: %v",
					path,
					err,
				)
				continue
			}

			log.Printf(
				"Log antigo removido: %s",
				path,
			)
		}
	}

	return nil
}

// Close fecha o arquivo de log.
func (l *Logger) Close() error {
	l.mu.Lock()
	defer l.mu.Unlock()

	if l.file == nil {
		return nil
	}

	err := l.file.Close()
	l.file = nil

	return err
}
