# Contrato de Endpoints e Integrações Descobertas (Engenharia Reversa)

> 🎯 **Finalidade Deste Arquivo:** Fonte canônica viva de contratos e comportamento do sistema-alvo.
> **Regra Mandatória:** NUNCA implemente chamadas de API no código de produção sem antes validar e catalogar o endpoint neste documento com um exemplo mínimo de `curl`.

---

## 1. Contexto Global do Sistema-Alvo

- **Nome do Sistema:** [ex: Sistema Eletrônico de Informações - SEI]
- **Host Base:** `[ex: https://sei.orgao.gov.br/sei/]`
- **Mecanismo de Autenticação / Sessão:**
  - [ex: Cookie de sessão `SEI_SESSION` + token anti-CSRF `infra_hash` gerado em formulários HTML]
- **Particularidades HTTP Globais:**
  - **Headers Mandatórios:** `[ex: User-Agent: Mozilla/5.0 (...), X-Requested-With: XMLHttpRequest para AJAX]`
  - **Content-Types Padrão:** `[ex: application/x-www-form-urlencoded para formulários legados]`
  - **Tempo de Expiração de Sessão:** `[ex: 20 minutos de inatividade]`
  - **Comportamento de Sessão Expirada:** `[ex: HTTP 302 Redirecionando para login.php ou 200 com HTML de login]`

---

## 2. Matriz de Cobertura de Endpoints

| Método | Endpoint / Ação | Propósito | Status | Auth? | Última Validação |
| :---: | :--- | :--- | :---: | :---: | :---: |
| `POST` | `controlador.php?acao=procedimento_trabalhar` | Abrir árvore do processo e listar IDs de documentos | Validado | Sim | 2026-09-04 |
| `POST` | `controlador.php?acao=documento_download` | Baixar PDF original anexado ao processo | Em Mapeamento | Sim | - |
| `GET` | `controlador.php?acao=procedimento_consultar` | Consultar andamento público sem login | Descoberto | Não | - |

*(Status possíveis: `Descoberto` -> `Em Mapeamento` -> `Validado` -> `Deprecado`)*

---

## 3. Especificação Detalhada por Endpoint

### 📌 [POST] `controlador.php?acao=procedimento_trabalhar`

- **Descrição:** Abre o painel de trabalho de um processo eletrônico específico e renderiza o HTML contendo a árvore documental e metadados.
- **Headers Mandatórios:**
  - `Cookie: SEI_SESSION=<token-sessao>`
  - `Content-Type: application/x-www-form-urlencoded`
  - `User-Agent: Mozilla/5.0 (...)`

- **Parâmetros de Entrada:**
  | Campo | Tipo | Local | Obrigatório? | Descrição / Exemplo |
  | :--- | :---: | :---: | :---: | :--- |
  | `acao` | `string` | Query | Sim | `procedimento_trabalhar` |
  | `id_procedimento` | `int` | Body (Form) | Sim | ID numérico interno do processo (ex: `1234567`) |
  | `infra_hash` | `string` | Body (Form) | Sim | Token CSRF coletado na tela anterior |

- **Respostas Conhecidas:**
  - **Sucesso (`200 OK`):**
    - `Content-Type`: `text/html; charset=iso-8859-1`
    - **Seletores Chave no DOM:**
      - `#divArvoreHtml`: Contém os links de cada documento com o atributo `data-id-documento`.
      - `#txtNumeroProcesso`: Contém o número formatado do protocolo.
  - **Sessão Inválida / Expirada (`302 Found` ou `200 OK` com tela de login):**
    - Identificador: Tag `<input id="txtUsuario" ...>` presente na resposta.
  - **Processo Inexistente ou Sem Acesso (`200 OK`):**
    - Identificador: `div.infraAlerta` com a mensagem *"Processo não encontrado ou usuário sem permissão"*.

- **Snippet cURL Mínimo Reproduzível:**
  ```bash
  curl -s -X POST "https://sei.orgao.gov.br/sei/controlador.php?acao=procedimento_trabalhar" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -b "SEI_SESSION=$TARGET_SESSION_COOKIE" \
    -d "id_procedimento=1234567&infra_hash=$TARGET_CSRF_HASH"
  ```

- **Fixture de Teste Associada:** `tests/fixtures/sei_processo_sucesso.html`
- **Invariantes e Pegadinhas:**
  - A codificação da resposta é frequentemente `ISO-8859-1` e requer decodificação explícita antes de rodar o parser DOM.
  - O parâmetro `id_procedimento` precisa ser numérico estrito; enviar string vazia causa erro silencioso que retorna tela inicial.

---

## 4. Template para Novos Endpoints (Copie e Preencha)

```markdown
### 📌 [MÉTODO] `caminho/do/endpoint`

- **Descrição:** [O que a chamada faz e para que serve]
- **Headers Mandatórios:**
  - `Header-Name: value`
- **Parâmetros de Entrada:**
  | Campo | Tipo | Local (Query/Body/Header) | Obrigatório? | Descrição |
  | :--- | :---: | :---: | :---: | :--- |
  | `campo` | `string` | Query | Sim | Exemplo |
- **Respostas Conhecidas:**
  - **Sucesso (200 OK):** [Estrutura JSON esperada ou seletores DOM para HTML]
  - **Erros Típicos:** [Status e formato de erro]
- **Snippet cURL Mínimo:**
  ```bash
  curl -s -X METHOD "https://host/endpoint" -H "..." -d "..."
  ```
- **Fixture de Teste Associada:** `tests/fixtures/nome_da_fixture.json`
- **Invariantes e Pegadinhas:** [Comportamentos inesperados, encodings, rate-limits, etc.]
```
