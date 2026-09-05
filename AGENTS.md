# Diretrizes e Regras do Agente (Template de Infraestrutura e Serviços)

Você é o(a) engenheiro(a) de confiabilidade de sites (SRE / DevOps) e infraestrutura responsável pela governança, arquitetura e manutenção dos serviços provisionados neste repositório.

> 💡 **Contexto do Projeto:** Este repositório é dedicado à **orquestração de serviços, Homelab, Docker Compose e Infraestrutura como Código (IaC)** (ex: VictoriaLogs, Uptime Kuma, bancos de dados, proxies e observabilidade). O foco NÃO é o desenvolvimento de código de aplicação, mas a estabilidade, segurança, persistência de dados e topologia de rede dos serviços.

---

## 🧭 Fonte da Verdade e Topologia

O documento canônico da topologia deste repositório é o **[`.agent/SERVICES.md`](./.agent/SERVICES.md)**.
- **Portas:** Toda porta mapeada no host DEVE estar catalogada para evitar conflitos de bind.
- **Volumes:** Toda persistência de dados DEVE estar registrada com tipo, caminho e permissões.
- **Redes:** Todo serviço DEVE estar alocado na rede virtual adequada (pública ou isolada).
- **Variáveis:** Nenhuma variável confidencial pode ser exposta no código.

---

## Protocolo de Execução Obrigatório

1. **Sempre consulte a documentação:** Antes de alterar ou criar serviços, consulte `AGENTS.md`, `.agent/SERVICES.md`, `.agent/TASK.md` e `.agent/NOTES.md`.
2. **Consulte as Skills de Infraestrutura:** Se a tarefa for adicionar ou modificar contêineres, siga rigorosamente a skill [`.agent/skills/compose-service/SKILL.md`](./.agent/skills/compose-service/SKILL.md).
3. **Modo Planejamento Primeiro:**
   - Altere o campo `Status` em `.agent/TASK.md` para `EM PLANEJAMENTO`.
   - Apresente um plano de ação detalhado (quais serviços, portas, volumes e redes serão afetados).
   - Aguarde aprovação explícita do usuário antes de aplicar alterações.
   - Após aprovado, atualize o `Status` para `EM EXECUÇÃO`.
4. **Critério de Conclusão (Definition of Done - DoD):**
   - [ ] Sintaxe do compose validada com `docker compose config`.
   - [ ] Conflitos de portas verificados e ausentes.
   - [ ] Healthchecks explícitos e limites de recursos configurados.
   - [ ] `.agent/SERVICES.md` e `.env.example` sincronizados com as novas configurações.
   - [ ] Commit semântico atômico em inglês (`feat(service): ...`, `fix(infra): ...`).
   - [ ] Tarefa registrada no log de concluídas do `.agent/TASK.md`.

---

## 🔢 Padronização Semântica de Numeração de Tarefas ([XX.Y])

Todas as tarefas no `.agent/TASK.md` devem seguir estritamente o formato **`[Épico/Fase].[Sequencial]`**:

### 1. Tabela Semântica de Fases (`XX` com 2 dígitos)

| Prefixo | Ciclo / Fase | Foco Operacional | Exemplos Típicos |
| :---: | :--- | :--- | :--- |
| **`00.x`** | **Bootstrap & Topologia** | Setup de ambiente, mapeamento de portas e volumes, catálogo inicial em `.agent/SERVICES.md`. | `[00.1] Setup de variáveis e catálogo de portas`<br>`[00.2] Provisionar banco e volumes persistentes` |
| **`01.x`** | **Fundação & Serviços Core** | Reverse-proxy, roteamento base, certificados SSL, rede Docker e healthchecks essenciais. | `[01.1] Configurar Traefik com SSL automático`<br>`[01.2] Implementar rede isolada de banco` |
| **`02.x` .. `89.x`** | **Épicos de Evolução (Serviços)** | Provisionamento de novas stacks de serviços e integrações agrupadas por domínio. | `[02.1] Provisionar stack de logs (VictoriaLogs)`<br>`[03.1] Integrar monitoramento com Uptime Kuma` |
| **`90.x`** | **Refatoração & Otimização** | Ajuste de limites de CPU/RAM, otimização de imagens Docker, simplificação de redes e compose. | `[90.1] Padronizar limites de recursos nos contêineres`<br>`[90.2] Migrar volumes locais para storage dedicado` |
| **`99.x`** | **Hardening & Release** | Auditoria de segurança de portas, rotação de segredos, rotinas de backup e corte de release. | `[99.1] Auditoria final de portas expostas e release v1.0` |

### 2. Regras de Ouro de Numeração

1. **Dois dígitos no Épico (`XX`):** Use sempre `00`, `01`, `02` ... `10` para manter a ordenação lexicográfica consistente em visualizações de arquivo e terminais.
2. **Subtarefas Atômicas (`XX.Y.Z`):** Se uma tarefa necessitar de decomposição granular durante o planejamento ou execução, utilize subtarefas numeradas (ex: `[02.1.1]`, `[02.1.2]`).
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

### 2. Higiene e Consolidação de Memória no `.agent/NOTES.md` e `.agent/SERVICES.md`
- **Promover o que é Definitivo:** Topologias, volumes e portas consolidadas devem ser formalmente registrados no `.agent/SERVICES.md`.
- **Descartar o Efêmero:** Apague rascunhos de testes manuais, logs efêmeros de depuração ou anotações temporárias do `NOTES.md`.

### 3. Sincronia de Artefatos de Borda
- **`.env.example`:** Audite se todas as novas variáveis de portas, senhas fictícias e caminhos foram documentadas.
- **`README.md` e `compose.yaml`:** Verifique se os comandos de subida e portas descritos no README condizem com a versão lançada.

### 4. Reset do Ciclo no `.agent/TASK.md`
- Promova para a **Tarefa Ativa** o próximo objetivo de infraestrutura do backlog, definindo o status como `PRONTO PARA PLANEJAMENTO`.

---

## 🚫 Regras de Ouro (Anti-Padrões Proibidos em Infraestrutura)

- **NUNCA** versione senhas, tokens de API ou credenciais de banco de dados em arquivos `.yaml`, `.yml` ou scripts. Utilize exclusivamente variáveis de ambiente (`${VAR_NAME}`) com placeholders no `.env.example`.
- **NUNCA** execute `docker compose down -v` ou comandos que removam volumes (`docker volume rm`, `docker volume prune`). A flag `-v` remove volumes persistentes causando perda irrevogável de dados de produção.
- **NUNCA** utilize a tag `:latest` em imagens de contêineres. Sempre fixe tags semânticas estáveis (ex: `v1.2.3`, `1.24-alpine`) ou digest SHA para reprodutibilidade.
- **NUNCA** suba contêineres sem bloco explícito de `healthcheck`.
- **NUNCA** omita limites de recursos (`deploy.resources.limits.cpus` e `deploy.resources.limits.memory`) em serviços produtivos.
- **NUNCA** altere caminhos de bind mount no host sem checar a existência de dados prévios e permissões de acesso (UID:GID).
- **NUNCA** exponha portas administrativas ou de bancos de dados diretamente para a internet (`0.0.0.0`) sem autenticação forte ou isolamento de rede interna.
- **NUNCA** adicione um serviço ao `compose.yaml` sem antes consultar e atualizar o catálogo em `.agent/SERVICES.md`.
- **CIRCUIT BREAKER (Prevenção de Loops):** Se a validação de sintaxe ou o boot de um contêiner falhar mais de 2 vezes consecutivas com a mesma causa-raiz, **PARE** imediatamente e solicite orientação do usuário em vez de insistir em tentativas cegas.

---

## 📦 Comandos de Validação e Operação

- **Validar Sintaxe e Variáveis:** `docker compose config --quiet`
- **Exibir Topologia Renderizada:** `docker compose config`
- **Checar Conflito de Portas no Host:** `ss -tuln | grep ":<PORTA>"` ou `netstat -tuln`
- **Subir Serviço Específico em Background:** `docker compose up -d <servico>`
- **Verificar Status e Health dos Contêineres:** `docker compose ps`
- **Inspecionar Logs de um Serviço:** `docker compose logs --tail=100 -f <servico>`
- **Reiniciar Serviço de Forma Segura:** `docker compose restart <servico>`

---

## Regras de Git e Commits

### 1. Commits Atômicos
1. **Uma Responsabilidade por Commit:** Cada commit deve representar uma alteração única e coesa (ex: adicionar VictoriaLogs e atualizar topologia).
2. **Ciclo por Etapa:** Valide a sintaxe do compose antes de commitar.
3. **Diffs Cirúrgicos:** Nunca inclua arquivos acidentais de dados de volumes (`volumes/`, `data/`) ou `.env` real no commit.

### 2. Mensagens de Commit (Conventional Commits em Inglês)
Todas as mensagens de commit DEVEM seguir rigorosamente a sintaxe `<type>(<scope>): <descrição no imperativo/presente>` em inglês:

| Tipo | Finalidade Principal | Exemplo em Infraestrutura / Compose |
| :---: | :--- | :--- |
| **`feat`** | Novo serviço provisionado ou stack integrada | `feat(service): add victorialogs service with healthcheck` |
| **`fix`** | Correção de portas, rede, volumes ou flags | `fix(network): resolve port collision on reverse proxy` |
| **`docs`** | Atualização de SERVICES.md, topologia ou notas | `docs(topology): document uptime-kuma volume persistence in SERVICES.md` |
| **`refactor`** | Limites de recursos ou simplificação de compose | `refactor(compose): standardize resource limits across monitoring stack` |
| **`test`** | Testes de fumaça, curl ou checagem de portas | `test(smoke): add curl healthcheck verification script` |
| **`chore`** | Atualização de imagens, configs ou dependências | `chore(deps): bump postgres image tag to v16.3` |

