# Inventário das operações da API

Atualizado em 2026-10-15. Fonte do contrato: `docs/openapi.yaml`; a cópia embarcada está em `internal/httpapi/openapi.yaml`.

**Resumo:** 40 operações de negócio no OpenAPI, todas com rota/handler, além de `/health` e dos dois caminhos Swagger. Os fluxos de dados usam PostgreSQL; auth, catálogo, cliente, agenda, tarefa, home, shell e notificações estão em `internal/features`. Pedidos/orçamentos permanecem em `internal/service`. Nenhum mock de runtime foi encontrado. Nenhuma operação de negócio tem teste de integração executado.

| # | Operação | Handler → service | Tabelas ou dependência | Estado verificado | Testes atuais |
|---:|---|---|---|---|---|
| 1 | `POST /auth/login` | `Login` → `features/auth.Service.Login` → `Repository.Authenticate` | `usuario`, `usuario_empresa`, `empresa`, `tenant`, `pgcrypto` | SQL parametrizado e JWT implementados; login bloqueado no banco atual porque V011/pgcrypto está pendente | Query/args com fake pgx row, mapeamento de usuário/erros e JWT parser; sem login contra PostgreSQL |
| 2 | `POST /auth/logout` | `Logout` | Nenhuma; stateless conforme contrato | Implementado como resposta 200, sem blacklist | Envelope/logout |
| 3 | `GET /home/indicadores` | `HomeIndicadores` → `features/home.Service.Indicators` → `Repository.Indicators` | `pedido`, `pedido_item`, `agenda`, `tarefa`, `notificacao` | SQL e fórmulas atuais; tenant/empresa/user explícitos | Sem teste de consulta |
| 4 | `GET /shell/empresa` | `ShellEmpresaAPI` → `features/shell.Service.Get` → `Repository.Get` | `empresa`, `usuario` | SQL implementado; `contato` escolhe email antes de telefone; usuário restrito ao tenant | Sem teste de consulta |
| 5 | `GET /shell/notificacoes` | `HomeShellNotificacoes` → `features/notificacao.Service.CountUnread` | `notificacao` | Alias do contador, rota deprecated no OpenAPI | Sem teste de integração |
| 6 | `GET /notificacoes` | `NotificacoesAPI` → `features/notificacao.Service.List` → `Repository.List` | `notificacao` | SQL, cursor e filtro implementados | Sem teste de persistência |
| 7 | `GET /notificacoes/nao-lidas/count` | `ContagemNotificacoesAPI` → `features/notificacao.Service.CountUnread` → `Repository.CountUnread` | `notificacao` | SQL implementado | Sem teste de persistência |
| 8 | `GET /clientes` | `Clientes` → `features/cliente.Service.List` → `Repository.List` | `cliente` | SQL, busca, status e cursor implementados | Validador de paginação/cliente; sem SQL real testado |
| 9 | `POST /clientes` | `CriarCliente` → `features/cliente.Service.Create` → `Repository.Create` | `cliente`, sequence, advisory lock | INSERT transacional e duplicidade implementados; `codigo_erp` provisório `API-*` | Validação unitária; sem teste de persistência |
| 10 | `GET /clientes/{id}` | `Cliente` → `features/cliente.Service.Get` → `Repository.Get` | `cliente`, `cliente_endereco_adicional`, `cliente_conta_receber` | Consultas e agregação implementadas | Sem teste de persistência |
| 11 | `PUT /clientes/{id}` | `AtualizarCliente` → `features/cliente.Service.Update` → `Repository.Update` | `cliente` | UPDATE implementado; payload estrito snake_case do contrato | Validação unitária; sem teste de persistência |
| 12 | `DELETE /clientes/{id}` | `RemoverCliente` → `features/cliente.Service.Deactivate` → `Repository.Deactivate` | `cliente` | Exclusão lógica `ativo=false`; contrato ainda descreve a decisão como TODO | Sem teste de persistência |
| 13 | `GET /clientes/cnpj/{cnpj}` | `ClienteCNPJ` → `features/cliente.Service.ConsultarCNPJ` | BrasilAPI | HTTP externo, mapeamento e erros implementados | Mock de transporte para sucesso/erros; sem chamada externa real |
| 14 | `GET /clientes/{id}/enderecos` | `EnderecosCliente` → `features/cliente.Service.ListAddresses` → `Repository.ListAddresses` | `cliente`, `cliente_endereco_adicional` | Consulta implementada e tipo C/E/A convertido | Sem teste de persistência |
| 15 | `POST /clientes/{id}/enderecos` | `CriarEndereco` → `features/cliente.Service.CreateAddress` → `Repository.CreateAddress` | `cliente`, `cliente_endereco_adicional`, sequence | INSERT e transação implementados; endereço padrão limpa os anteriores | Validação de tipo; sem teste de persistência |
| 16 | `DELETE /clientes/{id}/enderecos/{enderecoId}` | `RemoverEndereco` → `features/cliente.Service.RemoveAddress` → `Repository.RemoveAddress` | `cliente`, `cliente_endereco_adicional` | DELETE físico conforme operação de endereço do contrato | Sem teste de persistência |
| 17 | `GET /clientes/{id}/contas-receber` | `ContasReceberCliente` → `features/cliente.Service.Receivables` → `Repository.ListReceivables` | `cliente`, `cliente_conta_receber` | Consulta read-only e situação derivada implementadas | Sem teste de persistência |
| 18 | `GET /cep/{cep}` | `ConsultarCEP` → `features/cliente.Service.ConsultarCEP` | ViaCEP | HTTP externo, validação e erros implementados | Mock de transporte para sucesso/erros; sem chamada externa real |
| 19 | `GET /pedidos` | `PedidosAPI` → `PedidosListarAPI` | `pedido`, `pedido_item`, `cliente` | SQL, filtro, cursor e total implementados | Sem teste de persistência |
| 20 | `POST /pedidos` | `SalvarPedidoAPI` → `CriarPedido` | `pedido`, `pedido_item`, `cliente`, `item`, catálogos e endereço | INSERT transacional; cria sempre, não atualiza apesar do summary do contrato | Totais puros; sem teste de transação |
| 21 | `GET /pedidos/{id}` | `PedidoAPI` → `PedidoObterAPI` | `pedido`, `pedido_item`, `cliente`, `empresa`, catálogos, item/estoque | Consulta e mapeamento implementados | Sem teste de persistência |
| 22 | `DELETE /pedidos/{id}` | `RemoverPedido` → `RemoverPedido` | `pedido` | Exclusão lógica por `apagar_dados_pedido=true` | Sem teste de persistência |
| 23 | `GET /orcamentos` | `OrcamentosAPI` → `PedidosListarAPI` | Mesmas de pedidos | Reusa listagem filtrando `e_um_orcamento` | Sem teste de persistência |
| 24 | `GET /orcamentos/{id}` | `OrcamentoAPI` → `PedidoObterAPI` | Mesmas de pedido | Reusa detalhe e valida o tipo após consultar | Sem teste de persistência |
| 25 | `GET /empresas` | `Catalogo` → `features/catalogo.Service.List` → `Repository.List` | `empresa`, `usuario_empresa` | SQL read-only e cursor implementados | Whitelist de recurso; sem query executada no PostgreSQL |
| 26 | `GET /condicoes-pagamento` | `Catalogo` → `features/catalogo.Service.List` → `Repository.List` | `condicao_pagamento` | SQL read-only e cursor implementados | Whitelist de recurso; sem query executada no PostgreSQL |
| 27 | `GET /formas-pagamento` | `Catalogo` → `features/catalogo.Service.List` → `Repository.List` | `forma_pagamento` | SQL read-only e cursor implementados | Whitelist de recurso; sem query executada no PostgreSQL |
| 28 | `GET /transportadoras` | `Catalogo` → `features/catalogo.Service.List` → `Repository.List` | `transportadora` | SQL read-only e cursor implementados | Whitelist de recurso; sem query executada no PostgreSQL |
| 29 | `GET /tabelas-preco` | `Catalogo` → `features/catalogo.Service.List` → `Repository.List` | `tabela_preco`, `tabela_preco_item` | SQL read-only; `vigencia` deriva do menor início e segue decisão pendente | Whitelist de recurso; sem query executada no PostgreSQL |
| 30 | `GET /produtos` | `Catalogo` → `features/catalogo.Service.List` → `Repository.List` | `item`, `unidade_medida`, `item_estoque`, `tabela_preco`, `tabela_preco_item` | SQL read-only, busca e cursor implementados; tabela padrão é inferida | Whitelist de recurso; sem query executada no PostgreSQL |
| 31 | `GET /agenda` | `AgendaListar` → `features/agenda.Service.List` → `Repository.List` | `agenda` | SQL, filtro e cursor; tenant/empresa/user explícitos | Validação isolada; sem SQL real |
| 32 | `POST /agenda` | `AgendaCriar` → `features/agenda.Service.Create` → `Repository.Create` | `agenda`, `cliente` | INSERT transacional e validações | Data/hora isolada; sem SQL real |
| 33 | `GET /agenda/{id}` | `AgendaObter` → `features/agenda.Service.Get` → `Repository.Get` | `agenda` | Consulta por id e usuário | Sem teste de persistência |
| 34 | `PUT /agenda/{id}` | `AgendaAtualizar` → `features/agenda.Service.Update` → `Repository.Update` | `agenda`, `cliente` | UPDATE transacional | Sem teste de persistência |
| 35 | `PATCH /agenda/{id}/concluir` | `AgendaConcluir` → `features/agenda.Service.Complete` → `Repository.Complete` | `agenda` | UPDATE `concluida=true` | Sem teste de persistência |
| 36 | `GET /tarefas` | `TarefasListarAPI` → `features/tarefa.Service.List` → `Repository.List` | `tarefa` | SQL, filtros e cursor; tenant/empresa/user explícitos | Validação isolada; sem SQL real |
| 37 | `POST /tarefas` | `TarefaCriar` → `features/tarefa.Service.Create` → `Repository.Create` | `tarefa` | INSERT transacional e validações | Validação isolada; sem SQL real |
| 38 | `GET /tarefas/{id}` | `TarefaObter` → `features/tarefa.Service.Get` → `Repository.Get` | `tarefa` | Consulta por id e usuário | Sem teste de persistência |
| 39 | `PUT /tarefas/{id}` | `TarefaAtualizar` → `features/tarefa.Service.Update` → `Repository.Update` | `tarefa` | UPDATE | Validação isolada; sem SQL real |
| 40 | `PATCH /tarefas/{id}/concluir` | `TarefaConcluir` → `features/tarefa.Service.Complete` → `Repository.Complete` | `tarefa` | UPDATE `concluida=true` | Sem teste de persistência |

## Pendências transversais

- `internal/service/api_service.go` ainda mistura cliente, CEP/CNPJ, shell, home, agenda/tarefa e pedido. Handlers igualmente concentram todos os domínios em `internal/httpapi/handlers_api.go`.
- Auth, catálogo, cliente, agenda, tarefa, home, shell e notificações agora têm repository/service em `internal/features`. Pedidos/orçamentos permanecem no service compartilhado.
- A suíte não tem teste de integração do fluxo handler → service → PostgreSQL; as operações de escrita e leitura do banco não foram exercitadas por testes.
- O usuário `epare` do Compose é superuser e ignora RLS; isolamento real não está demonstrado nesse ambiente.
- O banco observado tem migrations aplicadas até V010; V011 (`pgcrypto`) está pendente, então autenticação real não foi validada.
- O contrato não define identificador/semântica para atualização por `POST /pedidos`; implementação atual apenas cria.
- O frontend React não está neste workspace; compatibilidade foi cotejada somente com os relatórios disponíveis. Payloads antigos camelCase, `residencial`, e campos sem origem (`userNotes`, `lastVisit`, `lastAttendance`, `purchaseStatus`) continuam pendentes.
- Decisões ainda abertas incluem `tabela_preco.vigencia`, seleção de inscrição estadual no CNPJ e a reconciliação de códigos provisórios `API-*` com ERP.
