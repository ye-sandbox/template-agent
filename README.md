# Blackbox Template — Reverse Engineering, Scrapers & Closed Integrations (ADD)

🌐 **English | [Português](README.pt-br.md)**

This template is the canonical ADD starter kit for agent-driven engineering on systems **lacking official API documentation** (e.g., legacy ERPs, state/enterprise portals, internal web portals, and closed mobile APIs).

---

## 🎯 Why a Dedicated Template for Blackbox?

AI coding agents often fail in reverse engineering workflows because they:
1. **Hallucinate form parameters:** In legacy forms, hidden fields, hash tokens, and state keys are frequently omitted or misnamed.
2. **Overlook session lifecycles:** Cookies and anti-CSRF tokens expire, causing subsequent requests to fail silently.
3. **Execute live network calls during CI:** Without static mocked fixtures, test suites break on network hiccups or session invalidation.

This template solves these failure modes with:
- **`.agent/ENDPOINTS.md`:** Living canonical catalog of all discovered endpoints, cookies, headers, and form schemas.
- **`.agent/skills/reverse-engineering/SKILL.md`:** Strict 6-step lifecycle (Capture $\rightarrow$ Isolation $\rightarrow$ Minimization $\rightarrow$ Catalog $\rightarrow$ Fixtures $\rightarrow$ Typed Client).
- **Fixtures-First Standard:** Mandatory recording of sanitized mock responses before authoring production client code.
- **HTTP Defensiveness:** Exponential backoff, concurrency pacing, and automated session expiry handling.

---

## 📁 File Structure

```text
├── .agent/
│   ├── ENDPOINTS.md                 # Living catalog of discovered routes, payloads, and cookies
│   ├── TASK.md                      # Roadmap and active agent task
│   ├── NOTES.md                     # Target system invariants, quirks, and gotchas
│   ├── ARCHIVE.md                   # Archived task history
│   └── skills/
│       └── reverse-engineering/
│           └── SKILL.md             # Step-by-step reverse engineering protocol
├── .env.example                     # Connection variable and credential templates
├── .gitignore                       # Ignores .env, *.har, *.pcap, and session dumps
├── AGENTS.md                        # Agent guidelines and golden rules
├── init.sh                          # Quick initialization script (removed in project instance)
└── README.md                        # Project documentation
```

---

## 🚀 How to Initialize a New Blackbox Project

Via one-line script:

```bash
curl -fsSL https://raw.githubusercontent.com/ye-sandbox/template-agent/blackbox/init.sh | bash -s -- my-blackbox-project
cd my-blackbox-project
```

*Or via manual Git clone:*
```bash
git clone --depth 1 -b blackbox https://github.com/ye-sandbox/template-agent.git my-blackbox-project
cd my-blackbox-project
rm -rf .git && git init -b main && git add . && git commit -m "chore: initial blackbox setup"
```

---

## 🤖 First Prompt for the AI Agent

Open the project folder in your AI coding environment (Cursor, Windsurf, VS Code, Antigravity) and send:

> *"Read AGENTS.md, .agent/TASK.md, .agent/ENDPOINTS.md, and .agent/skills/reverse-engineering/SKILL.md. Present your implementation plan for Task [00.1] Authentication Discovery before running live requests."*

---

## 🛡️ Core Rules of this Template

1. **Inspect before Coding:** Always reproduce a minimal working cURL call before writing production client code.
2. **Catalog in `.agent/ENDPOINTS.md`:** No route enters application code without prior documentation.
3. **Mocked Test Fixtures:** Automated CI tests must never make live external requests.
4. **Protect the Target System:** Enforce request pacing, rate-limiting, and exponential backoff to avoid IP blocks.
5. **Credential Security:** Session cookies, passwords, and tokens live strictly in `.env`.
