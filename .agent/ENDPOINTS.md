# Contrato de Endpoints e Integrações Descobertas

> Fonte da verdade. Sem rota catalogada aqui + cURL mínimo, não há cliente de produção.
> Anatomia e exemplo SEI: [`.agent/skills/reverse-engineering/SKILL.md`](./skills/reverse-engineering/SKILL.md).

---

## 1. Contexto global

- **Nome do Sistema:** […]
- **Host Base:** `[https://…]`
- **Auth / sessão:** [cookie, CSRF, expiração, sinal de sessão morta]
- **Headers / Content-Type globais:** […]

---

## 2. Matriz

| Método | Endpoint / Ação | Propósito | Status | Auth? | Última Validação |
| :---: | :--- | :--- | :---: | :---: | :---: |
| | | | | | |

*(Status: `Descoberto` → `Em Mapeamento` → `Validado` → `Deprecado`)*

---

## 3. Ficha (copie por rota)

### 📌 [MÉTODO] `caminho`

- **Descrição:**
- **Headers:**
- **Parâmetros:** campo / tipo / local / obrigatório
- **Sucesso / erros típicos:**
- **cURL mínimo:**
  ```bash
  curl -s -X METHOD "$TARGET_BASE_URL/caminho" \
    -b "SESSION=$TARGET_SESSION_COOKIE" \
    -d "..."
  ```
- **Fixture:** `tests/fixtures/…`
- **Pegadinhas:**
