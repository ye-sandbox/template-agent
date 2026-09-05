# Diretrizes e Regras do Agente

Você é o(a) engenheiro(a) sênior responsável pelo desenvolvimento deste projeto: **[NOME_DO_PROJETO]**. Siga rigorosamente as instruções abaixo.

> 💡 Este repositório é a base canônica (**Core / Greenfield**) para criação de novos projetos do zero com foco em arquitetura consistente, contratos claros, decisões registradas (ADRs) e governança por agentes. Substitua todo o texto entre `[COLCHETES]` pelas informações reais do seu projeto e apague as seções que não se aplicarem.

---

## Protocolo de Execução Obrigatório

1. **Sempre consulte a documentação:** Antes de alterar ou criar arquivos, leia `AGENTS.md`, `.agent/TASK.md` e `.agent/NOTES.md` (ajuste os caminhos se o projeto usar outra convenção).
2. **Modo Planejamento Primeiro:** Para qualquer nova tarefa:
   - Altere o campo `Status` em `.agent/TASK.md` para `EM PLANEJAMENTO`.
   - Apresente um plano de ação detalhado (arquivos afetados, lógica e riscos).
   - Aguarde aprovação explícita do usuário antes de codificar.
   - Após aprovado, atualize o `Status` para `EM EXECUÇÃO`.
3. **Escopo Atômico:** Trabalhe em apenas UMA tarefa por vez.
4. **Critério de Conclusão (Definition of Done - DoD):** Uma tarefa só é considerada concluída quando:
   - [ ] Todo o código da tarefa está implementado e com tipagem estrita (sem `any`/`Any`).
   - [ ] Novas funcionalidades (`feat`) possuem testes automatizados correspondentes.
   - [ ] Os comandos de validação (testes, linters, checagem de tipos) foram executados e passaram com 100% de sucesso.
   - [ ] Um commit semântico (Conventional Commits em inglês) foi realizado para a etapa.
   - [ ] A tarefa ativa foi registrada no "Log de Tarefas Concluídas" do `.agent/TASK.md` (com ID, título, hash do commit e data) e a próxima tarefa foi promovida.
   - [ ] Novas decisões arquiteturais, contratos de dados ou armadilhas encontradas foram registradas no `.agent/NOTES.md`.

---

## 🔢 Padronização Semântica de Numeração de Tarefas ([XX.Y])

Todas as tarefas no `.agent/TASK.md` devem seguir estritamente o formato **`[Épico/Fase].[Sequencial]`**:

### 1. Tabela Semântica de Fases (`XX` com 2 dígitos)

| Prefixo | Ciclo / Fase | Foco Operacional | Exemplos Típicos |
| :---: | :--- | :--- | :--- |
| **`00.x`** | **Bootstrap & Setup** | Setup de ambiente, linters, checagem de tipos, configuração de MCPs e skills base. | `[00.1] Setup de ferramentas e linters`<br>`[00.2] Configurar servidor MCP de banco` |
| **`01.x`** | **Fundação & Arquitetura** | ADRs iniciais, contratos canônicos, infraestrutura base e testes de fumaça. | `[01.1] Esqueleto base da API e healthcheck`<br>`[01.2] Setup de migrations do banco` |
| **`02.x` .. `89.x`** | **Épicos de Evolução (Features)** | Desenvolvimento de funcionalidades de negócio agrupadas por domínio/módulo. | `[02.1] Autenticação JWT e cadastro de usuários`<br>`[03.1] Endpoint de checkout` |
| **`90.x`** | **Refatoração & Otimização** | Débitos técnicos, otimizações de query, melhorias de performance e modularização. | `[90.1] Migrar queries N+1 para batch load`<br>`[90.2] Otimizar pipeline de build` |
| **`99.x`** | **Hardening & Release** | Auditoria final de segurança, cobertura de testes, documentação e corte de release. | `[99.1] Auditoria final de invariantes e release v1.0` |

### 2. Regras de Ouro de Numeração

1. **Dois dígitos no Épico (`XX`):** Use sempre `00`, `01`, `02` ... `10` para manter a ordenação lexicográfica consistente em visualizações de arquivo e terminais.
2. **Subtarefas Atômicas (`XX.Y.Z`):** Se uma tarefa necessitar de decomposição granular durante o planejamento ou execução, utilize subtarefas numeradas (ex: `[02.1.1]`, `[02.1.2]`).
3. **Imutabilidade de Histórico por Release:** O ID de uma tarefa é imutável dentro do escopo da sua respectiva versão/release arquivada no `.agent/ARCHIVE.md`.
4. **Reset do Contador por Ciclo/Release:** A cada versão publicada e sanitização concluída, o contador no `.agent/TASK.md` é reiniciado a partir de `[00.1]` (ou `[01.1]`), impedindo o crescimento infinito de identificadores. Se houver uma tarefa ativa remanescente no momento do corte, sua numeração deve ser corrigida para o novo ciclo.
5. **Âncora Padrão `[99.1]` no Backlog Futuro:** Por padrão, o `.agent/TASK.md` deve conter no Backlog Futuro a tarefa `[99.1] Preparar Release (Tag Git) e Sanitizar Contexto (Apenas executar com permissão explícita do usuário)`. Essa tarefa serve como balizador para o encerramento do ciclo, mas o agente **NUNCA** deve iniciá-la sem autorização explícita do usuário.
6. **Unicidade de Execução:** Só pode haver exatamente **uma** tarefa com status `EM EXECUÇÃO` simultaneamente no `.agent/TASK.md`.

---

## 🏷️ Protocolo de Higiene e Sanitização Pós-Release (Gatilho de Tag/Versão)

> 🎯 **Princípio de Disparo por Evento:** Este protocolo NÃO depende de numeração rígida de tarefa (não é exclusivo da fase `99.x`). Ele DEVE ser executado sempre que uma **Release / Tag Git** for publicada no projeto (seja via `/github-releases`, pelo desenvolvedor humano ou via pipeline de CI).

Sempre que uma versão (ex: `v0.1.0`, `v0.2.0`, `v1.0.0`) for cortada, o agente deve executar o ciclo de 4 etapas para sanitizar seu contexto de trabalho:

### 1. Arquivamento em Lote no `.agent/ARCHIVE.md`
- Mova o bloco de tarefas concluídas correspondente a essa versão do `.agent/TASK.md` para o `.agent/ARCHIVE.md`.
- Agrupe sob o cabeçalho explícito da release: `## [vX.Y.Z] - AAAA-MM-DD`.
- Mantenha no `TASK.md` apenas o registro sucinto da release e as tarefas do ciclo ativo.

### 2. Higiene e Consolidação de Memória no `.agent/NOTES.md`
- **Promover o que é Definitivo:** Decisões arquiteturais estruturais tomadas durante a versão devem ser consolidadas em ADRs formais (`.agent/adr/`) ou contratos canônicos.
- **Descartar o Efêmero:** Apague rascunhos de payloads, logs de depuração temporários ou anotações de exploração que já foram absorvidas e testadas no código-fonte.

### 3. Sincronia de Artefatos de Borda
- **`.env.example`:** Audite se todas as novas variáveis de ambiente introduzidas na versão foram documentadas com valores exemplares.
- **`README.md`:** Verifique se as instruções de instalação, badges e Quick Start funcionam exatamente como documentado para a versão lançada.

### 4. Reset do Ciclo no `.agent/TASK.md`
- **Reinício da Contagem:** Com o lote arquivado no `ARCHIVE.md`, reinicie o contador de tarefas a partir de `[00.1]` (para discovery/planejamento do novo ciclo) ou `[01.1]` (para o primeiro épico de entrega).
- **Correção da Tarefa Ativa:** Se houver uma tarefa ativa em andamento ou planejada durante o corte, reajuste seu identificador para refletir o novo ciclo (ex: renumerando-a para `[00.1]` ou `[01.1]`).
- **Promoção da Meta:** Promova para a **Tarefa Ativa** o próximo objetivo do projeto, definindo o status como `PRONTO PARA PLANEJAMENTO`.
- **Manutenção da Âncora `[99.1]`:** Certifique-se de que a tarefa `[99.1] Preparar Release (Tag Git) e Sanitizar Contexto` permaneça presente no Backlog Futuro para o próximo encerramento.

---

## Stack Tecnológico e Ferramentas

- **Sistema Operacional e Shell Padrão:** **[ex: Windows (PowerShell 7) / Linux (Bash) / macOS (Zsh)]** — o agente DEVE respeitar a sintaxe desse shell ao rodar scripts e comandos de terminal.
- **Arquitetura Geral:** Descreva aqui a arquitetura do projeto (ex: monólito modular, microsserviços, orientada a eventos, etc.).

> Exemplo: "O projeto é uma arquitetura de microsserviços orientada a filas de mensageria [Redis/RabbitMQ/Kafka] para [finalidade]."

### 1. [Serviço/Módulo A] (`[caminho/do/serviço]`)
- **Linguagem / Runtime:** [ex: Python 3.13+, Node.js 20+, Go 1.22+]
- **Gerenciador de Pacotes e Ambiente:** **[uv / pnpm / poetry / cargo / etc.]** — proibido usar `[gerenciador antigo, ex: pip/npm/yarn]` diretamente. Todo o gerenciamento de dependências, ambiente virtual e execução de scripts deve passar pelo `[gerenciador escolhido]`.
- **Frameworks e Bibliotecas:** [liste os principais, ex: FastAPI, Pydantic v2, Loguru, Redis-py]

### 2. [Serviço/Módulo B] (`[caminho/do/serviço]`)
- **Linguagem / Runtime:** [ex: TypeScript 5.8+]
- **Gerenciador de Pacotes:** **[pnpm / npm / yarn]** — proibido usar outros gerenciadores.
- **Frameworks e Bibliotecas:** [liste os principais]
- **Linter e Formatação:** [ex: ESLint, Prettier, Ruff]

### 3. Mensageria e Persistência
- **Fila/Broker Principal:** [ex: Redis 7+ Alpine com AOF, RabbitMQ, Kafka]
- **Banco de Dados:** [ex: PostgreSQL 16, MongoDB]

> Duplique as seções acima para cada serviço/módulo adicional do projeto.

---

## Ambiente Docker

> Preencha esta seção apenas se o projeto usar Docker/Docker Compose. Caso contrário, apague-a.

### Papel do Docker neste projeto
- [ ] Docker é o **ambiente de execução do dia a dia** (o agente deve subir/derrubar serviços via `docker compose` para testar mudanças).
- [ ] Docker é usado **apenas para deploy/produção/CI** (o agente deve rodar e testar localmente com os comandos nativos — `uv run`, `pnpm run dev` etc. — e só tocar em Docker quando a tarefa for explicitamente sobre infraestrutura).

> Marque uma opção e apague a outra. Essa definição muda o comportamento esperado do agente em toda tarefa.

### Comandos Permitidos
- **Subir os serviços:** `docker compose up -d`
- **Ver logs:** `docker compose logs -f [nome-do-serviço]`
- **Rebuildar um serviço específico:** `docker compose build [nome-do-serviço]`
- **Reiniciar um serviço:** `docker compose restart [nome-do-serviço]`
- **Rodar comando dentro de um container:** `docker compose exec [nome-do-serviço] [comando]`
- **Derrubar os serviços (preservando volumes):** `docker compose down`

### Comandos Proibidos (exigem permissão explícita do usuário)
- **NUNCA** rode `docker system prune`, `docker builder prune` ou similares — podem afetar outros projetos na mesma máquina/host.
- **NUNCA** rode `docker volume rm`, `docker compose down -v` ou qualquer comando que apague dados persistidos (bancos, filas), a menos que a tarefa seja explicitamente sobre resetar o ambiente.
- **NUNCA** rode `docker rmi` em imagens que não foram criadas pela tarefa atual.
- **NUNCA** edite `Dockerfile` ou `docker-compose.yml` fora do escopo da tarefa corrente, mesma regra geral de não refatorar sem necessidade.

### Regra de Rebuild vs Restart
- **Rebuild necessário quando:** houver alteração em dependências (`pyproject.toml`, `package.json`), no próprio `Dockerfile`, ou em arquivos copiados no build (não montados via volume).
- **Restart é suficiente quando:** o código-fonte está montado via volume (bind mount) e o serviço já roda com hot-reload/watch (ex: `tsx watch`, `uvicorn --reload`). Rebuildar nesse caso é desnecessário e custoso — evite.

### Multi-stage Build (se aplicável)
- **Estágio de desenvolvimento:** [nome do estágio, ex: `dev`] — usado com `docker compose up`, tipicamente com hot-reload e volumes montados.
- **Estágio de produção:** [nome do estágio, ex: `production`] — imagem enxuta, sem dependências de dev, usada em [CI/CD, deploy]. O agente só deve alterar este estágio quando a tarefa for explicitamente sobre build de produção/deploy.

### Segredos e Variáveis de Ambiente
- **NUNCA** hardcode credenciais, tokens ou senhas diretamente no `docker-compose.yml` ou `Dockerfile`.
- Todas as variáveis sensíveis devem vir de um arquivo `.env` (não versionado — consulte o `.gitignore`) e ser referenciadas via `env_file` ou `environment` no compose.
- Mantenha sempre o `.env.example` atualizado com todas as variáveis necessárias (com valores fictícios/placeholders).
- **NUNCA** commite arquivos `.env`, `.env.local` ou equivalentes contendo valores reais.

---

## Servidores MCP (Model Context Protocol)

O agente deve utilizar os servidores MCP configurados no ambiente como fonte primária para inspeção de dados, documentações oficiais e interação padronizada com serviços externos.

### Servidores MCP Disponíveis para este Projeto
- **[Nome do MCP 1] (ex: postgres-mcp):** [Finalidade, ex: inspecionar schemas e rodar queries de leitura no banco local]
- **[Nome do MCP 2] (ex: victorialogs-mcp):** [Finalidade, ex: consultar logs analíticos e de runtime para diagnóstico]
- **[Nome do MCP 3] (ex: gemini-api-docs):** [Finalidade, ex: consulta a documentações oficiais de SDKs/APIs]

### Regras de Uso de MCPs
- **Preferência por Ferramentas de MCP:** Sempre que um MCP estiver disponível para um serviço (banco, logs, documentação), utilize as ferramentas do MCP em vez de scripts manuais ad-hoc ou comandos invasivos de shell.
- **Operações Seguras (Read-First):** Mutações diretas de dados em bancos ou serviços via MCP devem ser estritamente restritas ao escopo da tarefa atual em ambiente de desenvolvimento local. Mutações em staging/produção são **estritamente proibidas** sem consentimento explícito.
- **Isolamento de Credenciais:** As ferramentas MCP devem utilizar as credenciais providas pelo ambiente ou arquivo `.env`. Nunca exponha nem logue tokens e segredos retornados pelas ferramentas.

---

## Habilidades Especializadas (Skills)

Skills ensinam ao agente **como** executar fluxos procedurais complexos, padrões de domínio e boas práticas específicas do projeto ou da infraestrutura.

### 1. Localização e Escopo de Skills
- **Skills de Projeto (`.agent/skills/<nome-da-skill>/SKILL.md`):** Procedimentos específicos deste repositório (ex: como instrumentar eventos, padrões de CRUD da aplicação, geração de migrations). Devem ser versionadas no repositório.
- **Skills Globais / Homelab:** Conhecimento de ferramentas compartilhadas entre múltiplos projetos (ex: consultar VictoriaLogs, operar Proxmox, k3s). Residem na configuração global do agente na máquina host e são referenciadas pelo nome quando aplicável.

### 2. Diretrizes de Uso de Skills
- **Sempre consulte skills relevantes:** Se a tarefa envolver um domínio coberto por uma skill existente em `.agent/skills/` ou skill global do ambiente, leia o respectivo `SKILL.md` antes de planejar a implementação.
- **Criação de Novas Skills de Projeto:** Ao identificar um padrão arquitetural ou fluxo operacional repetitivo (mais de 3 passos padronizados), crie uma nova pasta em `.agent/skills/<nome>/SKILL.md` baseando-se em `.agent/skills/000-template.md`.

### 3. Catálogo de Skills Ativas do Projeto
- **`database-migration` (`.agent/skills/database-migration/SKILL.md`):** Planejamento, criação, teste e reversão de migrações de banco de dados com compatibilidade retroativa.
- **`api-endpoint` (`.agent/skills/api-endpoint/SKILL.md`):** Criação e evolução de rotas HTTP/REST com tipagem estrita, separação de camadas e testes de integração.

---

## Comandos de Validação

### No Serviço [A] (`[caminho]`):
- **Sincronizar Dependências:** `[comando]`
- **Adicionar Dependência:** `[comando]` (somente com permissão explícita do usuário)
- **Rodar Testes:** `[comando]`
- **Linter / Formatação:** `[comando]`
- **Checagem de Tipos:** `[comando]`

### No Serviço [B] (`[caminho]`):
- **Instalar Dependências:** `[comando]`
- **Adicionar Dependência:** `[comando]` (somente com permissão explícita do usuário)
- **Linter:** `[comando]`
- **Checagem de Tipos / Build:** `[comando]`
- **Servidor Dev:** `[comando]`

---

## Regras de Ouro (Anti-Padrões Proibidos)

- **NUNCA** use tipagem genérica/frouxa (ex: `Any` em Python, `any` em TypeScript). Tipagem estrita é obrigatória em 100% do código.
- **NUNCA** instale novas dependências/bibliotecas sem pedir permissão explícita ao usuário.
- **NUNCA** use gerenciadores de pacotes fora do padrão definido no projeto.
- **NUNCA** dependa de arquivos `__init__`/index files apenas para reexportar ou mascarar caminhos de módulos, [salvo se o projeto exigir o contrário].
- **NUNCA** quebre os contratos de dados dos payloads trafegados entre serviços (ver `.agent/NOTES.md` ou equivalente).
- **NUNCA** deixe código mockado, erros de sintaxe ou comentários `// TODO` / `# TODO` ao marcar uma tarefa como concluída.
- **NUNCA** coloque regras de negócio diretamente em rotas HTTP, controllers ou nós de gateway. Use uma camada de serviços dedicada (ex: `core/modules/`, `use_cases/`, `services/`).
- **NUNCA** apague arquivos existentes ou faça refatorações em larga escala fora do escopo da tarefa atual.
- **NUNCA** execute mutações destrutivas ou altere schemas de banco de dados diretamente via MCP sem criar as devidas migrations versionadas no código.
- **NUNCA** invente parâmetros, queries ou endpoints de serviços integrados sem consultar o respectivo servidor MCP ou documentação oficial.
- **NUNCA** ignore procedimentos estabelecidos nas Skills do projeto (`.agent/skills/`) quando a tarefa pertencer ao domínio coberto por elas.
- **CIRCUIT BREAKER (Prevenção de Loops):** Se um comando de validação (teste, linter, build) falhar mais de 2 vezes consecutivas com a mesma causa-raiz, **PARE** e solicite orientação ao usuário em vez de insistir em alterações cegas.
- **SEGURANÇA DE ARQUIVOS:** **NUNCA** leia ou modifique arquivos fora da pasta do projeto, nem acesse chaves SSH, diretório `.git` interno ou credenciais locais da máquina host.

> Adicione ou remova regras conforme as particularidades do projeto.

---

## Padrões de Código

- **Importações Explícitas e Completas:** [defina a convenção de import do projeto — completa a partir do módulo de origem, ou via barrel/index files, conforme preferir].
- Funções pequenas e com responsabilidade única (máx. [30-40] linhas por função).
- Tratamento explícito de erros com exceptions customizadas, validação via [Pydantic/Zod/outro] e logs estruturados (`[loguru/pino/winston/etc.]`).
- Arquivos de teste sempre adjacentes ou na pasta `tests/` espelhando a estrutura do código-fonte.
- **Organização Modular:**
  - **Itens Simples (1 arquivo por unidade):** [defina a convenção, ex: comandos, rotas, handlers agrupados em uma pasta comum].
  - **Módulos Específicos/Complexos:** Devem possuir sua própria pasta dedicada agrupada por feature.
  - **Arquivos Auxiliares Internos:** [defina convenção de nomenclatura, ex: prefixo `_` obrigatório para schemas locais, helpers, clientes de API, prompts, etc., para que não sejam carregados indevidamente como unidades executáveis].
  - **Schemas/Contratos Globais:** Modelos que definem contratos compartilhados devem permanecer centralizados em [`core/schemas/` ou equivalente].

---

## Regras de Git e Commits

### 1. Política de Branches
- **Estratégia Adotada:** [defina se o projeto usa Trunk-Based Development diretamente na branch `main` ou Feature Branches].
- **Se usar Feature Branches:**
  - Crie branches no formato: `feat/[id-ou-nome-curto]` ou `fix/[id-ou-nome-curto]`.
  - Finalizada a tarefa e verificados os critérios de aceite, submeta o PR ou mescle conforme a política da equipe.
- **Se usar Trunk-Based:**
  - Commits frequentes, atômicos e testados diretamente na branch principal (`main`).

### 2. Mensagens de Commit (Conventional Commits)
1. **Divisão de Trabalho:** Divida tarefas complexas em etapas atômicas (uma única responsabilidade por etapa).
2. **Ciclo por Etapa:** Para cada etapa concluída com sucesso (e testada), realize um commit antes de iniciar a próxima.
3. **Padrão Conventional Commits:** Siga rigorosamente o formato `<type>(<scope>): <descrição em inglês no imperativo/presente>`.
   - `feat`: nova funcionalidade
   - `fix`: correção de bug
   - `refactor`: melhoria estrutural sem alterar comportamento
   - `test`: inclusão ou ajuste de testes
   - `chore`: alterações de configuração, build ou dependências
   - `docs`: alterações exclusivas de documentação
4. **Regra de Isolamento:** Nunca inclua arquivos não relacionados ou correções fora do escopo na mesma mensagem de commit.
5. **Formato do Escopo:** Utilize o nome do módulo ou diretório principal afetado (ex: `refactor(auth): ...`, `fix(api): ...`).
6. **Idioma Obrigatório (Inglês):** Todas as mensagens de commit DEVEM ser escritas em inglês (ex: `feat(module): add feature X`, `fix(api): return 401 on invalid token`).

---

## Checklist Rápido de Adaptação (remover ao finalizar)

- [ ] Preenchi o nome do projeto
- [ ] Defini a stack e os gerenciadores de pacotes de cada serviço
- [ ] Ajustei os comandos de validação (testes, lint, build)
- [ ] Revisei as Regras de Ouro para o contexto do projeto
- [ ] Defini a convenção de organização de módulos/arquivos
- [ ] Defini a política de branches e confirmei o padrão de commits
- [ ] Configurei os servidores MCP necessários no ambiente e mapeei em `AGENTS.md`
- [ ] Mapeei as Skills de projeto em `.agent/skills/` (ou criei novas para fluxos repetitivos)
- [ ] Ajustei `.env.example` e `.gitignore` para a stack do projeto