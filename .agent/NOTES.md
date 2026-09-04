# NOTES.md — Memória de Longo Prazo e Invariantes do Sistema-Alvo

> 🧠 **Memória de Longo Prazo:** Registre aqui decisões de integração, particularidades do sistema legado que não são óbvias a partir do código, e restrições de infraestrutura.

---

## 1. Decisões Arquiteturais e de Biblioteca
- **Cliente HTTP Escolhido:** [ex: httpx com connection pooling e suporte a HTTP/2]
- **Estratégia de Parser:** [ex: selectolax / BeautifulSoup para páginas com encoding misto]
- **Gerenciamento de Sessão:** [ex: renovação automática via interceptor quando detectar status 302 para login]

---

## 2. Invariantes e Pegadinhas do Sistema-Alvo
- [ex: O portal derruba conexões que não enviam o header `User-Agent` exatamente como o Chrome no Linux.]
- [ex: Campos numéricos de ID no SEI retornam erro 500 caso passem zeros à esquerda.]
- [ex: O sistema exige intervalo mínimo de 250ms entre requisições consecutivas da mesma sessão.]

---

## 3. Registro de Descobertas Técnicas
*(Adicione notas curtas e datadas à medida que novos comportamentos forem observados)*

- **2026-09-04:** Inicialização do repositório de integração caixa preta.
