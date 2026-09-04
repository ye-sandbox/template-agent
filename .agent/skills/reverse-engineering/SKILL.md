---
name: reverse-engineering
description: Metodologia e protocolo de dissecação, validação, documentação e implementação de integrações com APIs e portais legados sem documentação (Engenharia Reversa de Caixa Preta).
---

# Metodologia de Engenharia Reversa de APIs e Portais Legados

Esta skill define o procedimento operacional padrão para agentes que precisam interagir com sistemas sem documentação oficial (ex: SEI, SIP, portais estatais, ERPs monolíticos).

---

## 🧭 O Ciclo de 6 Etapas

```text
┌─────────────────┐     ┌──────────────────┐     ┌──────────────────┐
│  1. Captura de  │ ──> │ 2. Isolamento de │ ──> │ 3. Minimização & │
│     Tráfego     │     │   Autenticação   │     │   Validação cURL │
└─────────────────┘     └──────────────────┘     └──────────────────┘
                                                           │
                                                           ▼
┌─────────────────┐     ┌──────────────────┐     ┌──────────────────┐
│ 6. Cliente HTTP │ <── │  5. Fixtures de  │ <── │ 4. Documentação  │
│   Tipado Final  │     │  Teste Mockadas  │     │ em ENDPOINTS.md  │
└─────────────────┘     └──────────────────┘     └──────────────────┘
```

---

## Passo 1: Captura e Inspecção de Tráfego

1. **Abra as ferramentas de desenvolvedor (DevTools Network) ou proxy (mitmproxy):**
   - Marque "Preserve log" para não perder redirecionamentos.
   - Execute a ação manualmente na interface gráfica ou via script de automação.
2. **Identifique a requisição crítica:**
   - Filtre por `Fetch/XHR` ou `Doc` (caso seja formulário HTML tradicional com `POST`).
   - Identifique qual requisição realmente carrega ou envia a informação de negócio.
3. **Exporte a chamada:**
   - Copie como cURL (`Copy as cURL (bash)`).
   - NUNCA salve arquivos HAR contendo credenciais de produção no repositório.

---

## Passo 2: Isolamento de Sessão e Autenticação

Sistemas legados raramente usam tokens estáticos Bearer. Identifique:
1. **Cookies de Sessão:** Quais cookies são fundamentais? (Ex: teste remover um por um no cURL até descobrir qual é o cookie de autenticação real).
2. **Tokens de Proteção (Anti-CSRF / Hash):**
   - Verifique se a requisição envia parâmetros como `infra_hash`, `csrf_token`, `__VIEWSTATE`, `authenticity_token`.
   - Localize em qual requisição anterior esse token foi fornecido (geralmente em campos `<input type="hidden">` do HTML da tela anterior).
3. **Mapeamento do Ciclo de Vida da Sessão:**
   - Qual a validade da sessão?
   - O que o servidor responde quando a sessão morre? (Redirecionamento 302 para login, ou 200 com HTML de erro?).

---

## Passo 3: Minimização e Validação via cURL

Antes de criar qualquer código:
1. **Elimine o Ruído:**
   - Remova headers dispensáveis gerados pelo navegador (`Sec-Ch-Ua`, `Accept-Language`, `Sec-Fetch-*`).
   - Mantenha apenas o estritamente necessário (`Cookie`, `Content-Type`, `User-Agent`, `Referer` quando exigido).
2. **Teste a Resiliência:**
   - Execute o comando via terminal:
     ```bash
     curl -s -i -X POST "URL" -H "..." -d "..."
     ```
   - Garanta que a chamada funciona de forma consistente em chamadas repetidas (respeitando rate-limits).

---

## Passo 4: Registro Imediato no `.agent/ENDPOINTS.md`

Assim que a chamada for validada no terminal:
1. Adicione a rota na tabela de **Matriz de Cobertura**.
2. Crie a **Ficha Detalhada** com:
   - Método e URL exata.
   - Headers mandatórios.
   - Parâmetros obrigatórios e opcionais.
   - Snippet cURL reproduzível testado.
   - Identificação de pegadinhas (ex: encoding ISO-8859-1, parâmetros obrigatórios porém ocultos).

---

## Passo 5: Criação de Fixtures Mockadas para Testes

**Regra de Ouro:** O código de teste automatizado nunca deve bater no sistema real em execução contínua de CI.

1. Salve o corpo da resposta obtida no Passo 3 em `tests/fixtures/<sistema>_<acao>_sucesso.<json|html>`.
2. **Sanitize os dados:** Substitua nomes de pessoas, números de documentos (CPF, RG) e chaves sensíveis por valores fictícios (`111.222.333-44`, `João da Silva`, etc.).
3. Salve também um cenário de erro típico (ex: `tests/fixtures/<sistema>_sessao_expirada.html`).

---

## Passo 6: Implementação do Cliente HTTP Tipado

Ao construir o código na aplicação:
1. **Tipagem Estrita:** Crie modelos (Pydantic / Zod / Dataclasses) para os dados de entrada e para os dados extraídos da resposta.
2. **Resiliência e Retry:**
   - Implemente retry apenas para erros transitórios (status 502, 503, 504, 429 ou `TimeoutException`).
   - NUNCA dê retry automático em erros de autenticação (401/403) sem re-autenticar primeiro.
3. **Detecção de Sessão Inválida:**
   - Inspecione se o HTML retornado contém sinais de deslogamento antes de tentar fazer parsing dos dados esperados.
   - Se a sessão expirou, levante uma exceção explícita (`SessionExpiredError`) para permitir renovação automática.
4. **Respeito aos Limites:**
   - Inclua delays e controle de concorrência (`asyncio.Semaphore` ou fila de requisições) para evitar derrubar ou ser bloqueado pelo sistema legado.
