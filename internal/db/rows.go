package db

import (
	"fmt"
	"strings"

	"github.com/jackc/pgx/v5"
)

func ReadRows(rows pgx.Rows) ([]map[string]any, error) {
	defer rows.Close()
	fields := rows.FieldDescriptions()
	result := make([]map[string]any, 0)
	for rows.Next() {
		values := make([]any, len(fields))
		targets := make([]any, len(fields))
		for i := range values {
			targets[i] = &values[i]
		}
		if err := rows.Scan(targets...); err != nil {
			return nil, err
		}
		item := make(map[string]any, len(fields))
		for i, field := range fields {
			value := values[i]
			if bytes, ok := value.([]byte); ok {
				value = string(bytes)
			}
			item[strings.ToLower(string(field.Name))] = value
		}
		result = append(result, item)
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}
	return result, nil
}

func CursorPage(rows []map[string]any, limit int, cursorKey string) ([]map[string]any, string) {
	var next string
	if len(rows) > limit {
		next = fmt.Sprint(rows[limit-1][cursorKey])
		rows = rows[:limit]
	}
	return rows, next
}
