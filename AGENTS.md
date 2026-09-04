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

| Prefixo | Ciclo / Fase | Foco Operacional | Exemplos Típicos |
| :---: | :--- | :--- | :--- |
| **`00.x`** | **Discovery & Sessão** | Mapeamento inicial do sistema-alvo, isolamento de login, cookies de sessão e anti-CSRF. | `[00.1] Mapear autenticação e ciclo de sessão`<br>`[00.2] Mapear primeiro endpoint de negócio` |
| **`01.x`** | **Cliente Base & Resiliência** | Criação do cliente HTTP base, gerenciamento de pool de conexões, retries e backoff exponencial. | `[01.1] Criar cliente HTTP resiliente com sessão`<br>`[01.2] Implementar parser robusto de HTML/DOM` |
| **`02.x` .. `89.x`** | **Épicos de Endpoints & Fluxos** | Mapeamento e implementação de fluxos de negócio específicos (ex: processos, anexos, assinaturas). | `[02.1] Endpoint de consulta de processos`<br>`[02.2] Download e validação de documentos PDF` |
| **`90.x`** | **Otimização & Caching** | Cache de respostas, deduplicação de requisições, otimização de parsers. | `[90.1] Cache em memória de tokens de sessão` |
| **`99.x`** | **Hardening & Auditoria** | Auditoria de vazamento de credenciais, sanitização de fixtures e documentação final. | `[99.1] Auditoria de segredos e release v1.0` |

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

- **Padrão Conventional Commits (em inglês):**
  - `feat(auth): implement automatic session refresh for sei`
  - `feat(endpoints): add process tree parser and fixture`
  - `fix(client): handle 302 redirect on session expiration`
  - `docs(endpoints): document sei document download endpoint`
  - `test(fixtures): add mock response for protocol search`
