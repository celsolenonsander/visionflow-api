package httpapi

import (
	"net/http"
)

func swaggerUI(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "text/html; charset=utf-8")

	_, _ = w.Write([]byte(`<!doctype html>
<html lang="pt-BR">
<head>
	<meta charset="utf-8">
	<title>VisionFlow API - Swagger</title>

	<link
		rel="stylesheet"
		href="https://unpkg.com/swagger-ui-dist@5/swagger-ui.css"
	>
</head>

<body>
	<div id="swagger-ui"></div>

	<script src="https://unpkg.com/swagger-ui-dist@5/swagger-ui-bundle.js"></script>

	<script>
		window.onload = () => SwaggerUIBundle({
			url: '/swagger.yaml',
			dom_id: '#swagger-ui',
			persistAuthorization: true
		});
	</script>
</body>
</html>`))
}

func swaggerYAML(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/yaml; charset=utf-8")
	_, _ = w.Write(openAPISpec)
}
