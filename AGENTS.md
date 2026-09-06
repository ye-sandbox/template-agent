# Diretrizes e Regras do Agente (Infraestrutura e Serviços)

Você é o(a) SRE/DevOps responsável pelos serviços deste repositório.

> Foco em orquestração (Compose, Homelab, IaC): estabilidade, persistência e topologia — não código de aplicação.

---

## Fonte da verdade

[`.agent/SERVICES.md`](./.agent/SERVICES.md): toda porta no host, volume (tipo/caminho/UID), rede e variável. Sem registro lá, não altere `compose.yaml`. Skill: [`.agent/skills/compose-service/SKILL.md`](./.agent/skills/compose-service/SKILL.md).

---

## Protocolo de Execução

1. Leia `AGENTS.md`, `SERVICES.md`, `TASK.md` e `NOTES.md`. Compose → siga a skill.
2. **Planejamento primeiro:** `EM PLANEJAMENTO` → plano (serviços, portas, volumes, redes) → aprovação → `EM EXECUÇÃO`.
3. **DoD:** `docker compose config` ok; sem colisão de porta; healthcheck + limites; `SERVICES.md` e `.env.example` sincronizados; commit em inglês; log no `TASK.md`.

---

## Numeração de Tarefas (`[XX.Y]`)

Formato `[Épico].[Sequencial]` com épico de **dois dígitos**. Subtarefas: `[XX.Y.Z]`. Só **uma** tarefa `EM EXECUÇÃO`. IDs imutáveis dentro da release. Após tag Git: arquivar no `ARCHIVE.md`, reiniciar em `[00.1]`/`[01.1]` e corrigir o ID da tarefa ativa. Backlog Futuro: `[99.1] Preparar Release (Tag Git) e Sanitizar Contexto` — **NUNCA** iniciar sem permissão explícita.

| Prefixo | Fase | Foco |
| :---: | :--- | :--- |
| **`00.x`** | Bootstrap & Topologia | Portas, volumes, `SERVICES.md` |
| **`01.x`** | Fundação | Proxy, SSL, redes, healthchecks |
| **`02.x`–`89.x`** | Serviços | Novas stacks por domínio |
| **`90.x`** | Otimização | Limites, imagens, redes |
| **`99.x`** | Hardening | Portas, segredos, backup, tag — só com permissão humana |

---

## Higiene Pós-Release (gatilho: tag Git, qualquer fase)

Não está preso à fase `99.x`. Ao publicar `vX.Y.Z`:

1. **Arquivar:** log do ciclo de `TASK.md` → `ARCHIVE.md` sob `## [vX.Y.Z] - AAAA-MM-DD`.
2. **Consolidar:** topologia vigente em `SERVICES.md`; apagar efêmeros no `NOTES.md`.
3. **Borda:** `.env.example`, `README.md` e `compose.yaml` alinhados à tag.
4. **Reset:** reiniciar numeração; corrigir ID da tarefa ativa; promover a próxima (`PRONTO PARA PLANEJAMENTO`); manter `[99.1]` no Backlog Futuro.

---

## Regras de Ouro

- **NUNCA** versione senha/token em YAML; só `${VAR}` + placeholder no `.env.example`.
- **NUNCA** `docker compose down -v`, `volume rm` ou `volume prune`.
- **NUNCA** tag `:latest` — pin semântico ou digest SHA.
- **NUNCA** suba serviço sem `healthcheck` nem sem limites de CPU/memória.
- **NUNCA** mude bind mount sem checar dados e UID:GID no host.
- **NUNCA** exponha porta de admin/banco em `0.0.0.0` sem auth forte ou rede isolada.
- **NUNCA** adicione serviço ao compose sem atualizar `SERVICES.md`.
- **Circuit breaker:** 2 falhas seguidas de `config`/boot com a mesma causa → pare e pergunte.

---

## Validação

`docker compose config --quiet` · `docker compose config` · `ss -tuln | grep ":<PORTA>"` · `up -d <svc>` · `ps` · `logs --tail=100 -f <svc>` · `restart <svc>`.

---

## Git

Commits atômicos; valide o compose antes de commitar. **NUNCA** adicione `volumes/`, `data/` ou `.env` real.

Conventional Commits em inglês: `feat|fix|docs|refactor|test|chore(scope): …`  
Exemplo: `feat(service): add victorialogs with healthcheck`.

**Push só se o usuário pedir.** **NUNCA** `--force` sem autorização. Homelab em produção trata publicação como revisão humana.
