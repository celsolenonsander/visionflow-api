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
	_, _ = w.Write([]byte(swaggerSpec))
}

const swaggerSpec = `openapi: 3.0.3

info:
  title: VisionFlow API
  version: 1.0.0
  description: |
    API REST do sistema VisionFlow.

    ## Autenticação

    A API utiliza JSON Web Token (JWT) para autenticação.

    O fluxo de autenticação funciona da seguinte forma:

    1. Envie e-mail e senha para POST /auth/login.
    2. Se as credenciais forem válidas, a API retorna um JWT.
    3. Clique em "Authorize" no Swagger.
    4. Informe o token recebido.
    5. O Swagger enviará automaticamente o token nas requisições protegidas.
    6. O token deve ser enviado no cabeçalho HTTP:

       Authorization: Bearer <token>

    ## Expiração do token

    O token JWT atualmente possui validade de 8 horas.

    Após a expiração, será necessário realizar um novo login para obter
    outro token.

    ## Endpoints públicos

    Os seguintes endpoints não exigem autenticação:

    - GET /health
    - POST /auth/login
    - GET /swagger.yaml
    - GET /swagger/index.html

    Todos os demais endpoints exigem um JWT válido.

servers:
  - url: http://localhost:8080
    description: Ambiente local

tags:
  - name: Health
    description: Verificação de disponibilidade da API

  - name: Auth
    description: Autenticação e sessão

  - name: Home
    description: Indicadores do dashboard

  - name: Clientes
    description: Operações relacionadas a clientes

  - name: Pedidos
    description: Operações relacionadas a pedidos

  - name: Orcamentos
    description: Operações relacionadas a orçamentos

  - name: Agenda
    description: Operações relacionadas à agenda

  - name: Tarefas
    description: Operações relacionadas a tarefas

  - name: Notificacoes
    description: Operações relacionadas a notificações

  - name: Shell
    description: Dados utilizados pelo shell da aplicação

components:

  securitySchemes:

    BearerAuth:
      type: http
      scheme: bearer
      bearerFormat: JWT
      description: |
        Informe somente o JWT recebido no login.

        Exemplo:

        eyJhbGciOiJIUzI1NiIs...

        O Swagger adicionará automaticamente:

        Authorization: Bearer <token>

  schemas:

    APIError:
      type: object
      description: Estrutura padrão de erro da API.
      properties:
        code:
          type: string
          description: Código interno do erro.
          example: CREDENCIAIS_INVALIDAS

        message:
          type: string
          description: Mensagem descritiva do erro.
          example: Credenciais inválidas

    APIResponse:
      type: object
      description: Estrutura padrão de resposta da API.
      properties:
        success:
          type: boolean
          description: Indica se a operação foi realizada com sucesso.
          example: true

        data:
          description: Dados retornados pela operação.

        error:
          nullable: true
          allOf:
            - $ref: '#/components/schemas/APIError'

    LoginRequest:
      type: object
      required:
        - email
        - senha

      properties:
        email:
          type: string
          format: email
          description: E-mail utilizado para autenticação.
          example: admin@visionflow.app

        senha:
          type: string
          format: password
          description: Senha utilizada para autenticação.
          example: "123456"

    Usuario:
      type: object
      properties:
        id:
          type: integer
          description: Identificador do usuário.
          example: 1

        nome:
          type: string
          description: Nome do usuário.
          example: Régys Borges

        email:
          type: string
          format: email
          description: E-mail do usuário.
          example: admin@visionflow.app

        token:
          type: string
          description: JWT utilizado para autenticar as próximas requisições.
          example: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

    LoginData:
      type: object
      properties:
        usuario:
          $ref: '#/components/schemas/Usuario'

    LoginResponse:
      type: object
      properties:
        success:
          type: boolean
          example: true

        data:
          $ref: '#/components/schemas/LoginData'

        error:
          nullable: true
          example: null

    PedidoItemRequest:
      type: object
      properties:
        produto_id:
          type: integer
          example: 555

        quantidade:
          type: number
          example: 50

        preco_venda:
          type: number
          example: 4.75

        valor_desconto:
          type: number
          example: 10

    PedidoRequest:
      type: object
      required:
        - cliente_id
        - tipo
        - itens

      properties:
        cliente_id:
          type: integer
          description: ID do cliente do pedido.
          example: 24129

        tipo:
          type: string
          description: Tipo do documento.
          example: pedido

        condicao_pagamento_id:
          type: integer
          description: ID da condição de pagamento.
          example: 3

        forma_pagamento_id:
          type: integer
          description: ID da forma de pagamento.
          example: 2

        transportadora_id:
          type: integer
          description: ID da transportadora.
          example: 7

        observacoes:
          type: string
          description: Observações do pedido.
          example: Entrega urgente

        itens:
          type: array
          description: Itens do pedido.
          items:
            $ref: '#/components/schemas/PedidoItemRequest'

paths:

  /health:
    get:
      tags:
        - Health

      summary: Verificar disponibilidade da API

      description: |
        Endpoint público utilizado para verificar se a API está disponível.

        Não exige autenticação.

      responses:

        '200':
          description: API disponível
          content:
            application/json:
              example:
                success: true
                data:
                  status: ok
                error: null


  /auth/login:
    post:
      tags:
        - Auth

      summary: Autenticar usuário

      description: |
        Autentica o usuário utilizando e-mail e senha.

        Em caso de sucesso, a API gera um JWT com validade de 8 horas.

        O token retornado deve ser utilizado nas próximas requisições
        protegidas através do cabeçalho:

        Authorization: Bearer <token>

        Este endpoint não exige JWT.

      requestBody:
        required: true

        content:
          application/json:
            schema:
              $ref: '#/components/schemas/LoginRequest'

            example:
              email: admin@visionflow.app
              senha: "123456"

      responses:

        '200':
          description: Login realizado com sucesso

          content:
            application/json:
              schema:
                $ref: '#/components/schemas/LoginResponse'

              example:
                success: true
                data:
                  usuario:
                    id: 1
                    nome: Régys Borges
                    email: admin@visionflow.app
                    token: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
                error: null

        '400':
          description: JSON da requisição inválido

          content:
            application/json:
              example:
                success: false
                data: null
                error:
                  code: REQUISICAO_INVALIDA
                  message: JSON inválido.

        '401':
          description: Credenciais inválidas

          content:
            application/json:
              example:
                success: false
                data: null
                error:
                  code: CREDENCIAIS_INVALIDAS
                  message: credenciais inválidas


  /auth/logout:
    post:
      tags:
        - Auth

      summary: Encerrar sessão

      description: |
        Endpoint protegido por JWT.

        Na implementação atual, o logout confirma o encerramento
        da sessão no cliente, mas não mantém uma lista de tokens
        revogados no servidor.

        Portanto, o JWT continua tecnicamente válido até sua expiração
        de 8 horas.

        O cliente deve descartar o token após realizar o logout.

      security:
        - BearerAuth: []

      responses:

        '200':
          description: Logout realizado

          content:
            application/json:
              example:
                success: true
                data:
                  ok: true
                error: null

        '401':
          description: Token ausente, inválido ou expirado


  /home/indicadores:
    get:
      tags:
        - Home

      summary: Obter indicadores do dashboard

      security:
        - BearerAuth: []

      responses:

        '200':
          description: Indicadores retornados

        '401':
          description: Token ausente, inválido ou expirado


  /clientes:
    get:
      tags:
        - Clientes

      summary: Listar clientes

      security:
        - BearerAuth: []

      responses:

        '200':
          description: Lista de clientes

        '401':
          description: Token ausente, inválido ou expirado


  /clientes/{id}:
    get:
      tags:
        - Clientes

      summary: Consultar cliente por ID

      security:
        - BearerAuth: []

      parameters:
        - name: id
          in: path
          required: true
          description: ID do cliente.
          schema:
            type: integer
          example: 24129

      responses:

        '200':
          description: Cliente encontrado

        '400':
          description: ID do cliente inválido

        '401':
          description: Token ausente, inválido ou expirado

        '404':
          description: Cliente não encontrado


  /clientes/cnpj/{cnpj}:
    get:
      tags:
        - Clientes

      summary: Consultar cliente por CNPJ

      security:
        - BearerAuth: []

      parameters:
        - name: cnpj
          in: path
          required: true
          description: CNPJ do cliente. Pode ser enviado somente com números.
          schema:
            type: string
          example: "61186888000193"

      responses:

        '200':
          description: Cliente encontrado

        '401':
          description: Token ausente, inválido ou expirado

        '404':
          description: CNPJ não encontrado


  /pedidos:
    get:
      tags:
        - Pedidos

      summary: Listar pedidos

      security:
        - BearerAuth: []

      responses:

        '200':
          description: Lista de pedidos

        '401':
          description: Token ausente, inválido ou expirado

    post:
      tags:
        - Pedidos

      summary: Criar ou atualizar pedido

      security:
        - BearerAuth: []

      requestBody:
        required: true

        content:
          application/json:
            schema:
              $ref: '#/components/schemas/PedidoRequest'

      responses:

        '200':
          description: Pedido salvo

        '400':
          description: Dados do pedido inválidos

        '401':
          description: Token ausente, inválido ou expirado


  /pedidos/{id}:
    get:
      tags:
        - Pedidos

      summary: Consultar pedido por ID

      security:
        - BearerAuth: []

      parameters:
        - name: id
          in: path
          required: true
          description: ID do pedido.
          schema:
            type: integer
          example: 1001

      responses:

        '200':
          description: Pedido encontrado

        '400':
          description: ID do pedido inválido

        '401':
          description: Token ausente, inválido ou expirado

        '404':
          description: Pedido não encontrado


  /orcamentos:
    get:
      tags:
        - Orcamentos

      summary: Listar orçamentos

      security:
        - BearerAuth: []

      responses:

        '200':
          description: Lista de orçamentos

        '401':
          description: Token ausente, inválido ou expirado


  /agenda:
    get:
      tags:
        - Agenda

      summary: Listar agenda pendente

      security:
        - BearerAuth: []

      responses:

        '200':
          description: Agenda

        '401':
          description: Token ausente, inválido ou expirado


  /tarefas:
    get:
      tags:
        - Tarefas

      summary: Listar tarefas

      security:
        - BearerAuth: []

      responses:

        '200':
          description: Tarefas

        '401':
          description: Token ausente, inválido ou expirado


  /notificacoes:
    get:
      tags:
        - Notificacoes

      summary: Listar notificações

      security:
        - BearerAuth: []

      responses:

        '200':
          description: Notificações

        '401':
          description: Token ausente, inválido ou expirado


  /shell/empresa:
    get:
      tags:
        - Shell

      summary: Obter dados da empresa

      description: Dados utilizados pelo shell da aplicação.

      security:
        - BearerAuth: []

      responses:

        '200':
          description: Dados da empresa

        '401':
          description: Token ausente, inválido ou expirado


  /shell/notificacoes:
    get:
      tags:
        - Shell

      summary: Obter contador de notificações não lidas

      security:
        - BearerAuth: []

      responses:

        '200':
          description: Contador de notificações não lidas

        '401':
          description: Token ausente, inválido ou expirado
`
