package models

type APIResponse struct {
	Success bool        `json:"success"`
	Data    interface{} `json:"data"`
	Error   *APIError   `json:"error"`
}

type APIError struct {
	Code    string `json:"code"`
	Message string `json:"message"`
}

type LoginRequest struct {
	Email string `json:"email"`
	Senha string `json:"senha"`
}

type Usuario struct {
	ID    int    `json:"id"`
	Nome  string `json:"nome"`
	Email string `json:"email"`
	Token string `json:"token"`
}

type LoginData struct {
	Usuario Usuario `json:"usuario"`
}

type Indicadores struct {
	VendasMes                  float64 `json:"vendas_mes"`
	VendasHoje                 float64 `json:"vendas_hoje"`
	PedidosEmDigitacao         int     `json:"pedidos_em_digitacao"`
	OrcamentosEmDigitacao      int     `json:"orcamentos_em_digitacao"`
	ClientesEmDigitacao        int     `json:"clientes_em_digitacao"`
	PedidosAguardandoAprovacao int     `json:"pedidos_aguardando_aprovacao"`
	AgendasPendentes            int     `json:"agendas_pendentes"`
	TarefasPendentes            int     `json:"tarefas_pendentes"`
	NotificacoesNaoLidas        int     `json:"notificacoes_nao_lidas"`
}

type Cliente struct {
	ID                int     `json:"id"`
	Nome              string  `json:"nome"`
	Fantasia          string  `json:"fantasia"`
	RazaoSocial       string  `json:"razao_social"`
	CPFCNPJ           string  `json:"cpf_cnpj"`
	TipoPessoa        string  `json:"tipo_pessoa"`
	Status            string  `json:"status"`
	SituacaoCadastro  string  `json:"situacao_cadastro"`
	SituacaoCompra    string  `json:"situacao_compra"`
	DataAbertura      string  `json:"data_abertura"`
	CorIndicador      string  `json:"cor_indicador,omitempty"`
	EnderecoResumo    string  `json:"endereco_resumo,omitempty"`
	EnderecoCompleto  string  `json:"endereco_completo,omitempty"`
	UltimoPedido      *string `json:"ultimo_pedido"`
	UltimoAtendimento *string `json:"ultimo_atendimento"`
}

type Endereco struct {
	Logradouro  string `json:"logradouro"`
	Numero      string `json:"numero"`
	Complemento string `json:"complemento"`
	Bairro      string `json:"bairro"`
	Cidade      string `json:"cidade"`
	Estado      string `json:"estado"`
	CEP         string `json:"cep"`
}

type ClienteCNPJ struct {
	CNPJ              string   `json:"cnpj"`
	RazaoSocial       string   `json:"razao_social"`
	NomeFantasia      string   `json:"nome_fantasia"`
	InscricaoEstadual string   `json:"inscricao_estadual"`
	Email             string   `json:"email"`
	Telefone          string   `json:"telefone"`
	Endereco          Endereco `json:"endereco"`
}

type PedidoResumo struct {
	ID           int     `json:"id"`
	Numero       string  `json:"numero"`
	Tipo         string  `json:"tipo"`
	ClienteNome  string  `json:"cliente_nome"`
	DataEmissao  string  `json:"data_emissao"`
	TotalLiquido float64 `json:"total_liquido"`
	Status       string  `json:"status"`
}

type PedidoRequest struct {
	ClienteID           int         `json:"cliente_id"`
	Tipo                string      `json:"tipo"`
	CondicaoPagamentoID int         `json:"condicao_pagamento_id"`
	FormaPagamentoID   int         `json:"forma_pagamento_id"`
	TransportadoraID    int         `json:"transportadora_id"`
	Observacoes         string      `json:"observacoes"`
	Itens               []ItemInput `json:"itens"`
}

type ItemInput struct {
	ProdutoID     int     `json:"produto_id"`
	Quantidade    float64 `json:"quantidade"`
	PrecoVenda    float64 `json:"preco_venda"`
	ValorDesconto float64 `json:"valor_desconto"`
}

type PedidoSalvo struct {
	ID     int    `json:"id"`
	Numero string `json:"numero"`
	Status string `json:"status"`
}

type PedidoDetalhe struct {
	ID                int               `json:"id"`
	Tipo              string            `json:"tipo"`
	Numero            string            `json:"numero"`
	NumeroCliente     string            `json:"numero_cliente"`
	Status            string            `json:"status"`
	DataEmissao       string            `json:"data_emissao"`
	DataEntrega       string            `json:"data_entrega"`
	Empresa           EmpresaRef       `json:"empresa"`
	Cliente           ClienteRef       `json:"cliente"`
	CondicaoPagamento DescricaoRef     `json:"condicao_pagamento"`
	FormaPagamento    DescricaoRef     `json:"forma_pagamento"`
	Transportadora    NomeRef          `json:"transportadora"`
	ValorFrete        float64          `json:"valor_frete"`
	Itens             []PedidoItem     `json:"itens"`
	Totais            PedidoTotais     `json:"totais"`
}

type EmpresaRef struct { ID int `json:"id"`; Nome string `json:"nome"` }
type ClienteRef struct { ID int `json:"id"`; Nome string `json:"nome"`; CPFCNPJ string `json:"cpf_cnpj"` }
type DescricaoRef struct { ID int `json:"id"`; Descricao string `json:"descricao"` }
type NomeRef struct { ID int `json:"id"`; Nome string `json:"nome"` }

type PedidoItem struct {
	Sequencia    int         `json:"sequencia"`
	Produto      ProdutoRef  `json:"produto"`
	Quantidade   float64     `json:"quantidade"`
	PrecoVenda   float64     `json:"preco_venda"`
	ValorDesconto float64    `json:"valor_desconto"`
	TotalItem    float64     `json:"total_item"`
}

type ProdutoRef struct {
	ID        int    `json:"id"`
	Codigo    string `json:"codigo"`
	Descricao string `json:"descricao"`
	Unidade   string `json:"unidade"`
}

type PedidoTotais struct {
	TotalBruto    float64 `json:"total_bruto"`
	TotalDesconto float64 `json:"total_desconto"`
	TotalLiquido  float64 `json:"total_liquido"`
}

type Orcamento struct {
	ID           int     `json:"id"`
	Numero       string  `json:"numero"`
	Tipo         string  `json:"tipo"`
	ClienteNome  string  `json:"cliente_nome"`
	DataEmissao  string  `json:"data_emissao"`
	TotalLiquido float64 `json:"total_liquido"`
	Status       string  `json:"status"`
}

type Agenda struct {
	ID           int    `json:"id"`
	Titulo       string `json:"titulo"`
	Data         string `json:"data"`
	Status       string `json:"status"`
	ClienteNome  string `json:"cliente_nome"`
}

type Tarefa struct {
	ID            int    `json:"id"`
	Titulo        string `json:"titulo"`
	Status        string `json:"status"`
	DataVencimento string `json:"data_vencimento"`
}

type Notificacao struct {
	ID     int    `json:"id"`
	Titulo string `json:"titulo"`
	Lida   bool   `json:"lida"`
	Data   string `json:"data"`
}

type ShellEmpresa struct {
	Nome         string       `json:"nome"`
	CNPJ         string       `json:"cnpj"`
	Regional     string       `json:"regional"`
	Contato      string       `json:"contato"`
	UsuarioLogado UsuarioShell `json:"usuario_logado"`
}

type UsuarioShell struct {
	ID    int    `json:"id"`
	Nome  string `json:"nome"`
	Email string `json:"email"`
}

type NotificacaoCount struct {
	NaoLidas int `json:"nao_lidas"`
}
