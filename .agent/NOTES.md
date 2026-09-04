# NOTES.md — Decisões, Contexto e Contratos de Infraestrutura

> Guarda o PORQUÊ, não o QUE nem o COMO.
> Para decisões de arquitetura de infraestrutura, trade-offs de redes/volumes e armadilhas descobertas.

---

## Como usar este arquivo (para o agente)

1. **Leia antes de planejar qualquer tarefa:** Decisões aqui registradas evitam retrabalho ou escolhas que geram conflitos no host.
2. **Registre uma nova entrada quando:**
   - Uma decisão estrutural for tomada (ex: escolha entre Docker Compose vs Nomad/K3s, Traefik vs Caddy).
   - Um comportamento não-óbvio de uma imagem de contêiner for identificado (ex: UID específico exigido para bind mount).
   - Uma política de retenção de dados ou logs for alterada.

---

## Decisões Rápidas e Contexto Técnico

### [AAAA-MM-DD] [Padrão de Volumes Nominais vs Bind Mounts]
- **Contexto:** Necessidade de garantir alta performance de I/O e facilidade de backup sem quebrar permissões de usuário entre host e contêiner.
- **Decisão:** Adotados **Named Volumes** para bancos de dados e mecanismos de storage de escrita intensa (VictoriaLogs, Postgres, SQLite do Uptime Kuma), e **Bind Mounts** estritos (`:ro`) para arquivos de configuração versionados no Git.
- **Consequências:** Evita problemas crônicos de permissão de escrita (`Permission denied`) em diretórios mapeados no host.

---

## Armadilhas e Comportamentos Não-Óbvios

- **Permissões em Volumes de Log/DB:** Algumas imagens rodam como usuário não-root (ex: UID 1000 ou 65534). Se usar bind mount, o diretório no host deve possuir permissão compatível.
- **Remoção de Volumes com `down`:** NUNCA execute `docker compose down -v`. A flag `-v` remove os volumes persistentes destruindo os dados de produção.
- **Conflito de Portas no Host:** Sempre consulte `.agent/SERVICES.md` antes de atribuir uma porta no `ports:`.

---

## Débitos Técnicos Assumidos

| Débito | Motivo da decisão | Quando revisitar |
|---|---|---|
| `[ex: Sem replicação de banco de dados]` | `[Setup simplificado de nó único]` | `[Ao atingir limites de escala]` |
