---
name: qa-environment
description: Prepara e padroniza ambientes de teste e prompts estruturados para agentes de QA e automação de UI (Grok, Playwright, agentes autônomos com browser).
---

# Preparação de Ambiente e Prompt de QA (`qa-environment`)

## 1. Contexto e Objetivo

Quando submetemos uma aplicação web para validação por um agente ou bot de QA externo (ex: Grok com capacidade de navegação web, agentes com Playwright ou testers autônomos), é indispensável:
1. **Evitar disparos e efeitos colaterais em produção:** Isolar integrações reais (como gateways de WhatsApp, e-mail ou pagamentos) por meio de mocks rápidos que aceitam requisições sem erros.
2. **Carga inicial rica (Seeding):** Não deixar o agente testar uma interface completamente vazia — é preciso injetar dados representativos para validar listagens, ordenações, estados vazios e estados de domínio (sucesso, pendente, erro).
3. **Acesso e roteamento de rede:** Viabilizar o acesso caso o agente de teste rode fora da máquina do desenvolvedor (ex: bots em nuvem que exigem um túnel seguro como Cloudflare Tunnel, ngrok ou Tailscale Funnel).
4. **Prompt sistemático:** Fornecer um prompt com persona clara de Engenheiro de QA Sênior, credenciais de teste, rotas autorizadas do contrato de interface e uma matriz padronizada para o relatório de bugs e usabilidade.

---

## 2. Quando Utilizar (Gatilhos)

Ative as orientações desta skill sempre que:
- O usuário pedir para rodar testes manuais ou automatizados de UI via agente externo (ex: Grok bot, Claude com browser, Playwright).
- For necessário gerar o prompt ou briefing técnico de QA para avaliar uma aplicação web.
- For necessário preparar um ambiente de homologação/staging local efêmero com dados mockados e túnel de rede.
- Uma nova versão de UI for entregue e precisar de uma rodada de testes funcionais ponta a ponta antes da release.

---

## 3. Ferramentas e Infraestrutura de Apoio

- **Exposição de Rede (Túneis):**
  - Cloudflare Tunnel: `cloudflared tunnel --url http://localhost:<PORTA>`
  - Ngrok: `ngrok http <PORTA>`
  - Tailscale Funnel: `tailscale funnel <PORTA>`
- **Mocks de Serviço:**
  - Mock de gateway HTTP simples (ex: endpoint FastAPI ou Python `http.server` que responde `202 Accepted` ou `200 OK`).
- **Scripts de Seeding:**
  - Scripts Python/Node na pasta `scripts/` do projeto alvo que populam o banco de dados de teste via API ou direto no SQLite/Postgres.
- **Molde de Prompt:**
  - Arquivo local de referência [`prompt_template.md`](prompt_template.md).

---

## 4. Procedimento Operacional Passo a Passo

### Passo 1: Isolamento de Dependências Críticas (Mocking)
Antes de ligar o ambiente para o tester:
1. Verifique se a aplicação possui variáveis de ambiente que apontam para serviços externos (ex: `WHATSAPP_API_URL`, `WEBHOOK_URL`, `SMTP_HOST`).
2. Redirecione essas variáveis para um mock seguro ou porta local.
3. Se a aplicação disparar requisições em background (ex: loops de disparo, cron jobs), certifique-se de que o mock responda os códigos HTTP esperados (ex: `202` para gateway de fila, `200` para webhooks) sem falhar nem enviar payloads para a internet real.

### Passo 2: Carga de Dados Inicial (Seeding)
Uma interface vazia não permite testar paginação, busca nem comportamentos de clique.
Injete uma massa de dados de teste contendo pelo menos:
- **Entidades primárias:** 2 a 3 registros ativos (ex: contatos, usuários, produtos).
- **Entidades secundárias / detalhes:** Itens associados aos registros primários.
- **Variação de estados de domínio:**
  - Pelo menos um item em estado `pendente`/`agendado`.
  - Pelo menos um item em estado `concluído`/`sucesso`.
  - Pelo menos um item em estado `erro` (para testar a exibição de badges e mensagens de falha na UI).
- **Entidades imutáveis/somente leitura:** Se houver itens gerados por arquivo de configuração (ex: YAML/JSON), inclua-os para validar se a UI bloqueia ações indevidas (edição/cancelamento desabilitados).

### Passo 3: Exposição de Rede (quando aplicável)
Se o agente de QA rodar em infraestrutura externa/nuvem:
1. Inicie a aplicação na porta padrão (ex: `8003`).
2. Suba o túnel temporário:
   ```bash
   cloudflared tunnel --url http://localhost:8003
   # ou
   ngrok http 8003
   ```
3. Capture a URL HTTPS pública gerada pelo túnel (ex: `https://xyz.trycloudflare.com` ou `https://abc.ngrok-free.app`).

### Passo 4: Geração do Prompt de QA
1. Abra o arquivo [`prompt_template.md`](prompt_template.md).
2. Preencha os campos estruturados:
   - **URL Alvo:** URL do túnel (ou `localhost` se for tester local).
   - **Credenciais / Chave de API:** Preencha com a chave de teste configurada (ex: valor de `SCHEDULE_API_KEY` ou usuário/senha de teste).
   - **Escopo e Rotas:** Liste as telas com base no `.agent/INTERFACE.md` da aplicação.
   - **Restrições de Domínio:** Destaque regras específicas (ex: "itens com origem YAML não podem ser cancelados via UI").
3. Entregue o prompt final ao usuário para envio ao bot/agente de QA.

### Passo 5: Encerramento e Higienização
Após o agente concluir os testes e entregar o relatório:
1. Encerre o processo do túnel HTTP.
2. Limpe os dados do banco de testes ou reverta o volume SQLite/banco efêmero.
3. Restaure as variáveis de ambiente originais caso tenham sido alteradas.

---

## 5. Armadilhas Conhecidas e Anti-Padrões

- ⚠️ **NÃO execute o teste apontando para APIs externas de envio real:** O agente de QA pode clicar repetidamente em botões como "Disparar agora", "Enviar e-mail" ou "Checkout", gerando custos ou spam para pessoas reais.
- ⚠️ **NÃO realize testes contra o banco de produção:** Sempre utilize um banco isolado (ex: volume `schedule-test.sqlite` ou container de staging).
- ⚠️ **NÃO deixe o banco totalmente limpo:** Se a listagem estiver vazia, o agente apenas testará a tela de cadastro e não validará tabelas, ordenação, badges de status ou buscas.
- ⚠️ **NÃO mantenha o túnel aberto indefinidamente:** Túneis expõem serviços internos do homelab. Finalize o processo imediatamente após a bateria de testes.
- 💡 **FAÇA:** Use o contrato `.agent/INTERFACE.md` para alimentar o escopo do prompt. O agente de QA saberá com precisão quais telas existem e quais erros esperar.

---

## 6. Checklist de Conclusão da Preparação

- [ ] Mock de serviços externos iniciado e respondendo status esperado.
- [ ] Banco de testes populado com itens representativos de cada estado.
- [ ] Aplicação iniciada e respondendo `200` na rota inicial e `health`.
- [ ] Túnel HTTPS gerado e testado (se agente for externo).
- [ ] Prompt de teste gerado a partir de [`prompt_template.md`](prompt_template.md) com todas as variáveis preenchidas.
