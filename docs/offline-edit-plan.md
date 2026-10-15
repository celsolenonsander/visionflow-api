# Plano — Offline-first + Edição de Pedido e Cliente

**Última atualização:** 2026-10-15
**Status:** Planejado (não implementado)
**Prioridade:** Alta — diferencial competitivo pro cliente final

---

## 1. Contexto do projeto

### Stack atual
- **Front:** React + Vite + TypeScript + Tailwind + Zustand
- **Backend:** Go + chi + pgx + PostgreSQL 16
- **Banco:** RLS multi-tenant (cod_tenant + cod_empresa)
- **Auth:** JWT HS256 (8h de expiração)
- **Infra dev:** Cloudflare Tunnel expondo API local
  - API: `https://api.programadordelphi.com.br`
  - Front: Codespaces (`https://xxx-5173.app.github.dev`)
- **Testes:** Playwright E2E (11 passando)
- **Migrations:** Flyway (V001-V015)

### Domínios existentes
- `auth` — login, JWT, sessão
- `cliente` — CRUD + endereços + contas a receber
- `pedido` — CRUD + itens + endereços + status
- `home` — indicadores
- `shell` — empresa + notificações
- `notificacao`, `agenda`, `tarefa`
- `catalogo` — empresas, produtos, condições, formas, transportadoras, tabelas

### Estado atual do CRUD
- ✅ Online funciona (11 testes E2E passando)
- ✅ Cliente CRUD completo
- ✅ Pedido CRUD completo (com bugs recentes sendo corrigidos)
- ❌ **Offline NÃO existe**
- ❌ **Edição de pedido/cliente offline NÃO existe**

---

## 2. Objetivo

Permitir que o vendedor:
1. **Crie clientes offline** (sincroniza quando voltar)
2. **Edite clientes offline**
3. **Crie pedidos offline** (inclusive adicionar itens)
4. **Edite pedidos offline**
5. **Veja indicadores offline** (dados em cache)

Quando voltar online, tudo sincroniza automaticamente.

### Casos de uso reais
- Vendedor externo visitando cliente em área sem sinal
- Demonstração de app em local sem internet
- Fluxo de "salvar depois, enviar quando puder"

---

## 3. Arquitetura proposta

### 3.1 Camadas

```
┌─────────────────────────────────────────────────────┐
│  UI (React)                                         │
│  - Mostra badge "pendente" / "sincronizado"        │
│  - Detecta navigator.onLine                         │
└─────────────────────┬───────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────┐
│  Repository (ex: ApiClienteRepository)             │
│  - Escreve no IndexedDB PRIMEIRO                    │
│  - Enfileira operação                               │
│  - Tenta API se online; senão, deixa pendente       │
└─────────────────────┬───────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────┐
│  Sync Engine                                        │
│  - Lê fila do IndexedDB                             │
│  - Envia quando online                              │
│  - Resolve conflitos                                │
│  - Atualiza IDs temporários → reais                 │
└─────────────────────┬───────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────┐
│  IndexedDB (via Dexie.js ou react-offline-kit)     │
│  - Tabelas espelhando entidades                     │
│  - Tabela `syncQueue` (operações pendentes)         │
│  - Tabela `syncMeta` (última sincronização)         │
└─────────────────────────────────────────────────────┘
```

### 3.2 Fluxo de escrita offline

```
1. Usuário salva um pedido
2. Repository:
   a. Grava no IndexedDB com ID temporário (negativo ou UUID)
   b. Marca como "pending: true"
   c. Adiciona operação na syncQueue
3. Sync Engine (assíncrono):
   a. Se online → envia POST/PUT
   b. Substitui ID temporário pelo ID real
   c. Remove da fila, marca "synced"
   d. Se offline → mantém na fila
4. UI mostra estado em tempo real
```

### 3.3 Fluxo de leitura offline

```
1. Usuário abre lista de clientes
2. Repository:
   a. Lê do IndexedDB
   b. Dispara fetch da API em background
   c. Merge quando chega
3. UI nunca fica vazia (tem cache local)
```

---

## 4. Tecnologia recomendada

### Opção A — Biblioteca pronta (recomendada)

**`react-offline-kit`**
- Cobre IndexedDB + sync queue + conflict resolution
- Suporta `newer-wins`, `client-wins`, `server-wins`
- Hook `useOfflineData('pedidos')` que retorna `add`, `update`, `remove`

**Prós:**
- Rápido de integrar
- Resolve 80% do problema

**Contras:**
- Menos controle
- Pode não casar 100% com a arquitetura atual (Repository Pattern)

### Opção B — Dexie.js + sync manual

**`Dexie.js`** para IndexedDB + código próprio pro sync engine.

**Prós:**
- Controle total
- Integra limpo com `ApiClienteRepository` e `ApiPedidoRepository` atuais
- Você já tem Repository Pattern — só adiciona uma camada

**Contras:**
- Mais código
- Precisa implementar sync engine

### Recomendação

**Opção B (Dexie)** porque:
1. Você já tem `Repository` bem estruturado
2. Precisa de controle fino (multi-tenant, RLS)
3. `react-offline-kit` pode brigar com o `apiClient.ts` atual

---

## 5. Desafios técnicos

### 5.1 Multi-tenant no IndexedDB

**Problema:** um dispositivo pode ter múltiplos usuários/tenants.
**Solução:** prefixar tabelas do IndexedDB por `cod_tenant + cod_empresa`:

```ts
const dbName = `visionflow:${tenantId}:${empresaId}`
```

### 5.2 IDs temporários

**Problema:** criar pedido offline exige ID.
**Solução:** usar IDs negativos (`-1`, `-2`, ...) como temporários. Quando sincronizar, substitui pelo real.

**Atenção:** `codigo_erp` gerado pelo backend (`API-XXX`) também precisa ser atualizado.

### 5.3 Auth offline

**Problema:** JWT expira em 8h. Se o vendedor ficar 2 dias offline, perde auth.
**Solução:**
- Aceitar JWT expirado **localmente** (para leitura/escrita no IndexedDB)
- Validar de verdade quando voltar online
- Considerar refresh token de longa duração

### 5.4 Sincronização em cascata

**Problema:** cliente criado offline → pedido criado com ID temporário do cliente.
**Solução:** sync engine precisa reescrever referências quando IDs reais chegam.

```ts
// Depois de sync do cliente
await db.pedidos.where({ clienteTemporario: -1 }).modify({ clienteId: realId })
```

### 5.5 Conflitos

**Problema:** o mesmo pedido editado no servidor e offline.
**Estratégia recomendada:** `newer-wins` (mais recente vence), com log de conflito.

### 5.6 Endereços e itens

**Problema:** pedido tem `itens[]` e `enderecos[]`. Criação offline precisa criar tudo de uma vez.
**Solução:** operação atômica. Uma entrada na syncQueue com payload completo.

---

## 6. Escopo mínimo viável (MVP)

### Fase 1 — Preparação
- [ ] Adicionar `Dexie.js` no projeto
- [ ] Criar `src/core/offline/db.ts` com schemas das tabelas espelhadas
- [ ] Criar `src/core/offline/syncQueue.ts` (fila)
- [ ] Adicionar `useOnlineStatus` hook
- [ ] Ajustar `apiClient.ts` pra trabalhar com cache local

### Fase 2 — Clientes offline
- [ ] `ApiClienteRepository.list` lê do IndexedDB primeiro
- [ ] `ApiClienteRepository.save` grava no IndexedDB + enfileira
- [ ] Sync engine processa fila de clientes
- [ ] UI: badge "pendente" no card do cliente

### Fase 3 — Pedidos offline
- [ ] Mesmo padrão pra pedidos
- [ ] Cuidado com itens[] e enderecos[]
- [ ] Sync em cascata (cliente → pedido)

### Fase 4 — UI de sincronização
- [ ] Indicador global "X pendentes"
- [ ] Botão "Sincronizar agora"
- [ ] Tela de conflitos (se houver)
- [ ] Toast quando sincronizar

### Fase 5 — Testes E2E offline
- [ ] Playwright com `context.setOffline(true)`
- [ ] Criar cliente offline → voltar online → verificar sync
- [ ] Criar pedido offline → voltar online → verificar sync
- [ ] Editar offline → verificar conflito

---

## 7. Testes E2E planejados

### Exemplo com Playwright

```ts
test('criar cliente offline e sincronizar', async ({ page, context, loginTenant4 }) => {
    await loginTenant4()
    
    // 1. Fica offline
    await context.setOffline(true)
    
    // 2. Cria cliente
    await page.goto('/app/clientes/novo')
    await page.getByLabel('Nome / Razão Social').fill('[E2E-OFFLINE] Cliente')
    await page.getByRole('button', { name: 'Salvar' }).click()
    
    // 3. Deve funcionar e marcar como pendente
    await expect(page.getByText('[E2E-OFFLINE] Cliente')).toBeVisible()
    await expect(page.getByTestId('sync-status')).toHaveText('Pendente')
    
    // 4. Volta online
    await context.setOffline(false)
    
    // 5. Aguarda sync
    await expect(page.getByTestId('sync-status')).toHaveText('Sincronizado', { timeout: 15000 })
    
    // 6. Verifica via API
    const token = await page.evaluate(() => {
        const raw = localStorage.getItem('visionflow:auth')
        return JSON.parse(raw)?.state?.token
    })
    const res = await page.request.get('/clientes?busca=E2E-OFFLINE', {
        headers: { Authorization: `Bearer ${token}` }
    })
    const data = await res.json()
    expect(data.data.items.length).toBeGreaterThan(0)
})
```

---

## 8. Estado atual do CRUD (pra contexto)

### Funcionando
- ✅ Login online
- ✅ Cliente CRUD online
- ✅ Pedido CRUD online (11 testes E2E)
- ✅ Catálogos via API
- ✅ RLS multi-tenant
- ✅ Migrations V001-V015

### Bugs recentes (sendo corrigidos)
- ⚠️ `numero_cliente` não persiste → **corrigido**
- ⚠️ `data_entrega` não persiste → **corrigido** (backend V015)
- ⚠️ Frete trava save → **corrigido** (payload + ISO)
- ⚠️ Endereços cobrança/entrega não salvam → **em aberto**
- ⚠️ Data entrega mostra 1 dia a menos → **em aberto** (timezone)
- ⚠️ Frete trava tela → **em aberto**

---

## 9. Referências

- `src/core/api/apiClient.ts` — cliente HTTP atual
- `src/features/cliente/data/repositories/ApiClienteRepository.ts`
- `src/features/pedido/data/repositories/ApiPedidoRepository.ts`
- `src/core/shell/` — layout, providers
- `docs/openapi.yaml` — contrato
- `docs/relatorio-cruzamento-front-schema.txt` — inventário front × banco
- `docs/fluxo-auth.html` — fluxo de auth

---

## 10. Próximos passos

1. **Terminar correções atuais** (endereços, timezone, frete)
2. **Rodar 11 testes E2E** e confirmar verdes
3. **Commit + push** das correções
4. **Decidir**: implementar offline agora ou depois?
5. Se sim: começar pela Fase 1 (Dexie + sync queue)
```

---

## Como usar este documento

### 1. Salvar

```bash
cd ~/Documents/Eparé/visionflow-api/docs
nano offline-edit-plan.md
# cola o conteúdo acima
```

Ou no front:
```bash
cd /workspaces/VisionFlow/docs
nano offline-edit-plan.md
```

### 2. Commitar

```bash
git add docs/offline-edit-plan.md
git commit -m "docs: adiciona plano de offline-first + edição"
git push
```

### 3. Retomar depois

Quando quiser voltar a trabalhar nisso:

```
Leia docs/offline-edit-plan.md e me diga o estado atual
e o próximo passo da Fase 1.
```

Ou, pra rodar com Copilot:

```
Implemente a Fase 1 do docs/offline-edit-plan.md.
Leia o documento primeiro, confirme o escopo, e execute passo a passo.
```

---

## Resumo do que ficou documentado

| Seção | O que cobre |
|---|---|
| **1. Contexto** | Stack + infra + estado atual |
| **2. Objetivo** | O que o usuário poderá fazer offline |
| **3. Arquitetura** | Camadas + fluxos de leitura/escrita |
| **4. Tecnologia** | Dexie vs react-offline-kit |
| **5. Desafios** | Multi-tenant, IDs temporários, auth, cascata, conflitos |
| **6. MVP** | 5 fases, cada uma testável |
| **7. Testes E2E** | Exemplo Playwright com `setOffline` |
| **8. Estado do CRUD** | O que funciona + bugs em aberto |
| **9. Referências** | Arquivos-chave |
| **10. Próximos passos** | Ordem de execução |