#!/bin/bash
BASE_URL="http://localhost:8080"
REPORT_FILE="teste-api-$(date +%Y-%m-%d_%H-%M-%S).txt"
exec > >(tee "$REPORT_FILE") 2>&1
echo "======================================"
echo " TESTE DA API VISIONFLOW"
echo " Data: $(date)"
echo " URL: $BASE_URL"
echo "======================================"
echo
echo "[1] GET /health"
curl -s -o /tmp/visionflow_response.json -w "HTTP %{http_code}\n" "$BASE_URL/health"
cat /tmp/visionflow_response.json
echo
echo
echo "[2] POST /auth/login"
LOGIN_RESPONSE=$(curl -s -X POST "$BASE_URL/auth/login" -H "Content-Type: application/json" -d '{"email":"admin@visionflow.app","senha":"123456"}')
echo "$LOGIN_RESPONSE"
echo
TOKEN=$(echo "$LOGIN_RESPONSE" | sed -n 's/.*"token":"\([^"]*\)".*/\1/p')
if [ -z "$TOKEN" ]; then echo "ERRO: não foi possível obter o JWT."; exit 1; fi
echo "JWT obtido com sucesso."
echo
test_get() { NAME="$1"; URL="$2"; echo "[$NAME] GET $URL"; curl -s -o /tmp/visionflow_response.json -w "HTTP %{http_code}\n" -H "Authorization: Bearer $TOKEN" "$BASE_URL$URL"; cat /tmp/visionflow_response.json; echo; echo; }
test_get "3" "/home/indicadores"
test_get "4" "/clientes"
test_get "5" "/clientes/24129"
test_get "6" "/clientes/cnpj/61186888000193"
test_get "7" "/pedidos"
test_get "8" "/pedidos/1001"
test_get "9" "/orcamentos"
test_get "10" "/agenda"
test_get "11" "/tarefas"
test_get "12" "/notificacoes"
test_get "13" "/shell/empresa"
test_get "14" "/shell/notificacoes"
echo "======================================"
echo " TESTES FINALIZADOS"
echo " Relatório salvo em: $REPORT_FILE"
echo "======================================"