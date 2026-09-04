---
name: compose-service
description: Procedimento padronizado para adicionar ou atualizar serviços no Docker Compose garantindo isolamento de portas, persistência segura, healthcheck e limites de recursos.
---

# Procedimento: Adicionar / Atualizar Serviço no Docker Compose

> 💡 **Objetivo:** Adicionar ou modificar serviços em arquivos `compose.yaml` (ou `docker-compose.yml`) de forma idempotente, segura e documentada, sem conflito de portas ou riscos de perda de dados.

---

## Pré-requisitos e Invariantes Obrigatórios

1. **Consulta Prévia da Topologia:** O agente DEVE ler [.agent/SERVICES.md](../../SERVICES.md) antes de alterar qualquer linha de configuração.
2. **Imagens Pinadas:** Proibido o uso da tag `:latest`. Use sempre tags semânticas estáveis (ex: `v1.2.3`, `1.23-alpine`).
3. **Healthcheck Obrigatório:** Todo contêiner deve possuir bloco explícito de `healthcheck`.
4. **Limites de Recursos:** Todo contêiner deve possuir diretivas de contenção (`cpus` e `memory`).
5. **Zero Segredos em Plaintext:** Senhas e tokens devem ser consumidos via variáveis de ambiente (`${VAR_NAME}`).

---

## Procedimento Passo a Passo

### Etapa 1: Verificação de Disponibilidade de Portas
1. Consulte a tabela de "Alocação de Portas no Host" em [.agent/SERVICES.md](../../SERVICES.md).
2. Se o serviço necessita expor portas no host, certifique-se de que a porta escolhida não está em uso.
3. No host local (se comandos de shell estiverem liberados), valide se a porta já não está sendo ouvida por outro processo:
   ```bash
   ss -tuln | grep ":<PORTA>" || echo "Porta livre"
   ```

### Etapa 2: Estruturação de Redes e Persistência
1. Determine a segregação de rede:
   - Serviços expostos ao usuário devem conectar-se à rede do reverse-proxy (ex: `proxy_public`).
   - Serviços de backend (bancos, filas, storage) devem residir exclusivamente em redes isoladas (ex: `db_isolated`).
2. Defina os volumes:
   - Para dados de banco ou escrita pesada, prefira **Named Volumes** declarados no final do `compose.yaml`.
   - Para arquivos de configuração estáticos, utilize **Bind Mounts** com a flag de somente-leitura `:ro`.

### Etapa 3: Definição do Bloco do Serviço no `compose.yaml`
Escreva o bloco do serviço seguindo a anatomia canônica:

```yaml
  nome-do-servico:
    image: vendor/imagem:v1.0.0
    container_name: nome-do-servico
    restart: unless-stopped
    security_opt:
      - no-new-privileges:true
    networks:
      - proxy_public
      - monitoring_internal
    ports:
      - "${SERVICO_PORT:-8080}:8080"
    environment:
      - TZ=${TZ:-UTC}
      - APP_SECRET=${APP_SECRET}
    volumes:
      - servico_data:/caminho/no/container
      - ./config/servico.conf:/etc/servico/servico.conf:ro
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
      interval: 30s
      timeout: 5s
      retries: 3
      start_period: 20s
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 512M
```

### Etapa 4: Atualização de Variáveis de Ambiente
1. Inclua as novas variáveis necessárias no arquivo `.env.example` com valores mockados e seguros.
2. Nunca coloque senhas de produção no `.env.example`.

### Etapa 5: Atualização do `.agent/SERVICES.md`
1. Atualize a tabela de portas em `.agent/SERVICES.md`.
2. Registre o volume e caminho na tabela de persistência.
3. Adicione a especificação do serviço no catálogo.

### Etapa 6: Validação Sintática e Idempotência
1. Valide a sintaxe do arquivo de composição:
   ```bash
   docker compose config --quiet
   ```
2. Caso a validação retorne erros, corrija o alinhamento ou nomes de variáveis antes de prosseguir.
3. Se autorizado a iniciar o serviço:
   ```bash
   docker compose up -d nome-do-servico
   docker compose ps nome-do-servico
   ```
