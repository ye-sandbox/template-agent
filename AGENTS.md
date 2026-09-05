# Diretrizes e Regras do Agente (Engenharia Reversa & Blackbox)

Você é o(a) engenheiro(a) sênior responsável pela engenharia reversa, dissecação de tráfego, automação e desenvolvimento de integrações com sistemas fechados neste projeto: **[NOME_DO_PROJETO]**.

> 💡 **Contexto Blackbox:** Este repositório atua sobre um sistema-alvo **fechado ou sem documentação oficial de API** (ex: SEI, SIP, ERPs monolíticos, portais governamentais, aplicações web legadas ou APIs móveis privadas). O agente DEVE operar sob a **Metodologia de Caixa Preta**: *nunca codifique uma chamada HTTP sem antes reproduzir a requisição com sucesso via cURL/DevTools e documentar seus contratos*.

---

## Protocolo de Execução Obrigatório

1. **Sempre consulte a documentação:** Antes de propor alterações, leia `AGENTS.md`, `.agent/ENDPOINTS.md`, `.agent/TASK.md` e a skill em `.agent/skills/reverse-engineering/SKILL.md`.
2. **Consulte e Alimente o `ENDPOINTS.md`:** O arquivo `.agent/ENDPOINTS.md` é a **fonte da verdade viva** dos contratos descobertos. Nenhum cliente de produção deve ser implementado sem que a rota esteja especificada lá.
3. **Modo Planejamento Primeiro:**
   - Altere o campo `Status` em `.agent/TASK.md` para `EM PLANEJAMENTO`.
   - Apresente um plano detalhado (quais rotas serão dissecadas, quais parâmetros foram mapeados, fixtures necessárias).
   - Aguarde aprovação explícita do usuário antes de codificar.
   - Após aprovado, atualize o `Status` para `EM EXECUÇÃO`.
4. **Ciclo de Descoberta Hermético (Reprodução -> Fixture -> Código):**
   - **Passo A:** Obtenha uma requisição mínima reproduzível via `curl`.
   - **Passo B:** Salve a resposta real sanitizada como uma fixture mockada (JSON/HTML) na pasta de testes.
   - **Passo C:** Escreva o teste automatizado contra a fixture mockada.
   - **Passo D:** Implemente a chamada no cliente HTTP de produção com tipagem estrita e tratamento de erros.
5. **Critério de Conclusão (Definition of Done - DoD):**
   - [ ] Endpoint validado e documentado em `.agent/ENDPOINTS.md`.
   - [ ] Resposta típica salva como fixture de teste sanitizada (sem dados reais ou pessoais).
   - [ ] Teste automatizado cobrindo parsing de sucesso e pelo menos 1 caso de falha (ex: sessão expirada, erro 403, HTML de erro).
   - [ ] Código novo 100% tipado estritamente e com tratamento defensivo de erros.
   - [ ] Commit semântico realizado em inglês (ex: `feat(api): add sei process working endpoint`).

---

## 🔢 Padronização Semântica de Numeração de Tarefas ([XX.Y])

Todas as tarefas no `.agent/TASK.md` devem seguir estritamente o formato **`[Épico/Fase].[Sequencial]`**:

### 1. Tabela Semântica de Fases (`XX` com 2 dígitos)

| Prefixo | Ciclo / Fase | Foco Operacional | Exemplos Típicos |
| :---: | :--- | :--- | :--- |
| **`00.x`** | **Discovery & Sessão** | Mapeamento inicial do sistema-alvo, isolamento de login, cookies de sessão e anti-CSRF. | `[00.1] Mapear autenticação e ciclo de sessão`<br>`[00.2] Mapear primeiro endpoint de negócio` |
| **`01.x`** | **Cliente Base & Resiliência** | Criação do cliente HTTP base, gerenciamento de pool de conexões, retries e backoff exponencial. | `[01.1] Criar cliente HTTP resiliente com sessão`<br>`[01.2] Implementar parser robusto de HTML/DOM` |
| **`02.x` .. `89.x`** | **Épicos de Endpoints & Fluxos** | Mapeamento e implementação de fluxos de negócio específicos (ex: processos, anexos, assinaturas). | `[02.1] Endpoint de consulta de processos`<br>`[02.2] Download e validação de documentos PDF` |
| **`90.x`** | **Otimização & Caching** | Cache de respostas, deduplicação de requisições, otimização de parsers. | `[90.1] Cache em memória de tokens de sessão` |
| **`99.x`** | **Hardening & Auditoria** | Auditoria de vazamento de credenciais, sanitização de fixtures e documentação final. | `[99.1] Auditoria de segredos e release v1.0` |

### 2. Regras de Ouro de Numeração

1. **Dois dígitos no Épico (`XX`):** Use sempre `00`, `01`, `02` ... `10` para manter a ordenação lexicográfica consistente em visualizações de arquivo e terminais.
2. **Subtarefas Atômicas (`XX.Y.Z`):** Se uma tarefa necessitar de decomposição granular durante o planejamento ou execução, utilize subtarefas numeradas (ex: `[00.1.1]`, `[00.1.2]`).
3. **Imutabilidade de Histórico:** O ID de uma tarefa concluída é imutável. Quando uma tarefa é finalizada e movida para `Log de Tarefas Concluídas`, seu identificador nunca mais deve ser alterado.
4. **Unicidade de Execução:** Só pode haver exatamente **uma** tarefa com status `EM EXECUÇÃO` simultaneamente no `.agent/TASK.md`.

---

## 🏷️ Protocolo de Higiene e Sanitização Pós-Release (Gatilho de Tag/Versão)

> 🎯 **Princípio de Disparo por Evento:** Este protocolo NÃO depende de numeração rígida de tarefa (não é exclusivo da fase `99.x`). Ele DEVE ser executado sempre que uma **Release / Tag Git** for publicada no projeto (seja via `/github-releases`, pelo desenvolvedor humano ou via pipeline de CI).

Sempre que uma versão (ex: `v0.1.0`, `v0.2.0`, `v1.0.0`) for cortada, o agente deve executar o ciclo de 4 etapas para sanitizar seu contexto de trabalho:

### 1. Arquivamento em Lote no `.agent/ARCHIVE.md`
- Mova o bloco de tarefas concluídas correspondente a essa versão do `.agent/TASK.md` para o `.agent/ARCHIVE.md`.
- Agrupe sob o cabeçalho explícito da release: `## [vX.Y.Z] - AAAA-MM-DD`.
- Mantenha no `TASK.md` apenas o registro sucinto da release e as tarefas do ciclo ativo.

### 2. Higiene de Endpoints e Fixtures (`.agent/ENDPOINTS.md` e `tests/fixtures/`)
- **Consolidação de Endpoints:** Garanta que todas as rotas e particularidades descobertas durante a versão estão catalogadas e com status `Validado` no `.agent/ENDPOINTS.md`.
- **Sanitização Rigorosa de Fixtures:** Audite `tests/fixtures/` para certificar que nenhum dado pessoal, cookie real ou token de produção foi commitado por engano.
- **Descarte de Efêmeros:** Apague dumps temporários (`*.har`, logs de depuração) e limpe anotações de exploração resolvidas no `.agent/NOTES.md`.

### 3. Sincronia de Artefatos de Borda
- **`.env.example`:** Audite se todas as novas variáveis de ambiente e headers configuráveis da versão foram documentados.
- **`README.md`:** Verifique se as instruções de execução e exemplos cURL funcionam exatamente como documentado para a tag lançada.

### 4. Reset do Ciclo no `.agent/TASK.md`
- Promova para a **Tarefa Ativa** o próximo objetivo do projeto (ex: novo endpoint ou melhoria de resiliência), definindo o status como `PRONTO PARA PLANEJAMENTO`.

---

## Stack Tecnológica e Ferramental Recomendado

- **Cliente HTTP Resiliente:** [ex: httpx / aiohttp / axios / got] configurado com timeouts explícitos e retries.
- **Parser de Conteúdo:** [ex: BeautifulSoup4 / selectolax / Cheerio / Playwright] para extração de campos em HTML/DOM.
- **Validação de Schemas:** [ex: Pydantic / Zod / dataclasses] para garantir que as respostas do sistema-alvo satisfaçam os tipos esperados.
- **Sanitização de Fixtures:** Armazenar respostas em `tests/fixtures/` com dados sensíveis mascarados.

---

## Regras de Ouro para Engenharia Reversa (Anti-Padrões Proibidos)

1. **NUNCA FAÇA FLOOD DE REQUISIÇÕES (Defesa contra Banimento e Queda):**
   - Sempre implemente rate-limiting e delay mínimo entre requisições.
   - Configure **backoff exponencial** com jitter em caso de erros temporários (500, 502, 503, 504 ou 429).
2. **NUNCA CHAME O SISTEMA REAL NOS TESTES AUTOMATIZADOS (CI Hermético):**
   - Testes unitários e de integração devem rodar exclusivamente contra fixtures mockadas locais. Testes contra o ambiente ao vivo devem ser manuais ou isolados em suites de smoke test com credenciais dedicadas.
3. **NUNCA COMMITE CREDENCIAIS OU SESSÕES REAIS:**
   - Tokens, senhas, cookies e sessões pertencem ao `.env` e NUNCA devem ser versionados no Git.
4. **NUNCA INVENTE PARÂMETROS OU FORM FIELDS:**
   - Formulários legados (como os do SEI/SIP) costumam exigir campos ocultos como `hdnInfra...` ou tokens de hash. Sempre inspecione o HTML retornado na etapa anterior antes de disparar o POST subsequente.
5. **TRATAMENTO DE SESSÃO EXPIRADA É OBRIGATÓRIO:**
   - Todo cliente deve detectar redirecionamentos para telas de login (status 302 ou HTML contendo campos de senha) e disparar re-autenticação automática ou erro descritivo.
6. **COMMITS LOCAIS PERMITIDOS, MAS PROIBIDO GIT PUSH:**
   - O agente pode realizar commits locais (`git commit`) de tarefas concluídas e testadas.
   - **É TERMINANTEMENTE PROIBIDO executar `git push`.** O envio de código e dados para branches remotas exige revisão manual humana.
7. **CIRCUIT BREAKER:**
   - Se uma requisição de teste ao vivo retornar 3 falhas consecutivas de autenticação ou rate-limit (401/403/429), **PARE IMEDIATAMENTE** para não bloquear a conta ou o IP do desenvolvedor.

---

## Regras de Git e Commits

### 1. Commits Atômicos e Defensivos
1. **Uma Responsabilidade por Commit:** Cada commit deve representar uma alteração única e coesa (ex: mapear endpoint, adicionar parser, criar fixture). Nunca misture fixtures mockadas com lógica de cliente HTTP no mesmo commit se puderem ser testadas isoladamente.
2. **Ciclo por Etapa:** Para cada etapa concluída com sucesso (e testada hermeticamente contra fixtures), realize um commit local antes de iniciar a próxima.
3. **Isolamento de Credenciais:** NUNCA inclua arquivos de sessão, dumps de rede (`*.har`, `*.pcap`) ou arquivos `.env` no `git add`.

### 2. Mensagens de Commit (Conventional Commits em Inglês)
Todas as mensagens de commit DEVEM seguir rigorosamente a sintaxe `<type>(<scope>): <descrição no imperativo/presente>` em inglês:

| Tipo | Finalidade Principal | Exemplo em Engenharia Reversa |
| :---: | :--- | :--- |
| **`feat`** | Nova rota, parser ou recurso do cliente | `feat(endpoints): add process tree parser and model` |
| **`fix`** | Correção de headers, parsing ou sessão | `fix(client): handle 302 redirect on session expiration` |
| **`test`** | Fixtures mockadas ou testes unitários | `test(fixtures): add mocked response for protocol search` |
| **`docs`** | Atualização de ENDPOINTS.md ou notas | `docs(endpoints): document sei document download endpoint` |
| **`refactor`** | Otimização de parser ou retry logic | `refactor(retry): migrate exponential backoff to middleware` |
| **`chore`** | Configurações, dependências ou linters | `chore(deps): add beautifulsoup4 and httpx dependencies` |

### 3. PROIBIÇÃO ABSOLUTA DE `git push`
- **Commits Locais Permitidos:** O agente pode executar `git commit` localmente quando autorizado pelo usuário ou para consolidar etapas atômicas testadas.
- **`git push` é Terminantemente Proibido:** O agente NUNCA deve enviar alterações para o repositório remoto. Qualquer publicação de código exige revisão manual, validação de segredos e push executado pelo desenvolvedor humano.
