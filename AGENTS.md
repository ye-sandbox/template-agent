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

### 2. Padrão Conventional Commits (em inglês)
- `feat(service): add victorialogs service with healthcheck`
- `fix(network): resolve port collision on reverse proxy`
- `docs(topology): document uptime-kuma volume persistence in SERVICES.md`
- `refactor(compose): standardize resource limits across monitoring stack`
- `chore(deps): bump postgres image tag to v16.3`
