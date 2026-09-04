# Template Blackbox — Engenharia Reversa, Scrapers e Integrações Fechadas (ADD)

Este template é o starter kit canônico do ecossistema ADD para desenvolvimento orientado a agentes em sistemas **sem documentação oficial de API** (ex: SEI, SIP, ERPs legados, portais governamentais, portais web e APIs móveis fechadas).

---

## 🎯 Por que um template dedicado para Blackbox?

Agentes de IA frequentemente falham em engenharia reversa porque:
1. **Alucinam nomes de parâmetros:** Em formulários legados (como os do SEI), campos como `hdnInfraItemSelecionado` ou tokens de hash são omitidos ou inventados.
2. **Ignoram o ciclo de vida da sessão:** Cookies e tokens CSRF expiram, fazendo com que requisições subsequentes falhem silenciosamente.
3. **Fazem requisições reais durante o CI:** Sem fixtures mockadas, a suite de testes quebra toda vez que a rede oscila ou a sessão expira.

Este template resolve esses problemas com:
- **`.agent/ENDPOINTS.md`:** Catálogo vivo e canônico de todos os endpoints, cookies, headers e formulários descobertos.
- **`.agent/skills/reverse-engineering/SKILL.md`:** Metodologia estrita de 6 passos (Captura -> Isolamento -> Minimização -> Documentação -> Fixtures -> Cliente HTTP).
- **Fixtures Primeiro:** Política obrigatória de gravar respostas mockadas antes de codificar o cliente de produção.
- **Defensividade HTTP:** Backoff exponencial, rate-limiting e detecção automática de sessão expirada.

---

## 📁 Estrutura de Arquivos

```text
├── .agent/
│   ├── ENDPOINTS.md                 # Contrato vivo de rotas, payloads e cookies descobertos
│   ├── TASK.md                      # Roadmap e tarefa ativa do agente
│   ├── NOTES.md                     # Invariantes e pegadinhas do sistema-alvo
│   ├── ARCHIVE.md                   # Tarefas antigas arquivadas
│   └── skills/
│       └── reverse-engineering/
│           └── SKILL.md             # Instrução passo a passo de engenharia reversa
├── .env.example                     # Modelo de variáveis de conexão e credenciais
├── .gitignore                       # Ignora .env, dumps *.har, *.pcap e cookies
├── AGENTS.md                        # Diretrizes e regras de ouro do agente
├── init.sh                          # Script de inicialização rápida (removido no projeto final)
└── README.md                        # Documentação do projeto
```

---

## 🚀 Como Inicializar um Novo Projeto Blackbox

Via script rápido (One-Liner):

```bash
curl -fsSL https://raw.githubusercontent.com/ye-sandbox/template-agent/blackbox/init.sh | bash -s -- meu-projeto-sei
cd meu-projeto-sei
```

*Ou via clone manual do Git:*
```bash
git clone --depth 1 -b blackbox https://github.com/ye-sandbox/template-agent.git meu-projeto-sei
cd meu-projeto-sei
rm -rf .git && git init -b main && git add . && git commit -m "chore: initial blackbox setup"
```

---

## 🤖 Primeiro Prompt para o Agente de IA

Abra a pasta do projeto no seu editor (Cursor, Windsurf, VS Code, Antigravity) e envie:

> *"Leia o AGENTS.md, .agent/TASK.md, .agent/ENDPOINTS.md e a skill em .agent/skills/reverse-engineering/SKILL.md. Apresente seu plano de implementação para a Tarefa [00.1] de descoberta de autenticação antes de rodar requisições."*

---

## 🛡️ Regras de Ouro deste Template

1. **Inspecione antes de codificar:** Sempre obtenha uma chamada cURL mínima funcional antes de escrever código de produção.
2. **Alimente o `.agent/ENDPOINTS.md`:** Nenhuma rota vai para o código sem estar documentada.
3. **Fixtures Mockadas para Testes:** Testes automatizados nunca devem chamar o sistema real sem necessidade.
4. **Respeite o Sistema-Alvo:** Use delays, rate-limits e backoff exponencial para evitar bloqueios ou sobrecargas.
5. **Segurança de Credenciais:** Sessões e senhas residem exclusivamente no `.env`.
