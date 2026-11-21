# TASK.md — Current Task and Roadmap

> WHAT to do now. Detailed history lives in `git log`. User requests during conversation
> take precedence — report discrepancies before acting.

---

## Active Task

### [00.1] Project Bootstrap & Python/FastAPI Stack Setup

Initialize the Python 3.12+ (`uv`) workspace, `pyproject.toml`, canonical test harness (`pytest`), linter/formatter (`ruff`), strict typing (`mypy`), and `/health` endpoint skeleton for `offgrid-voice`.

- [ ] Initialize `pyproject.toml` (`uv`, Python 3.12+, `fastapi`, `pydantic>=2`, `httpx`, `pipecat-ai`, `wyoming`, `pytest`, `ruff`, `mypy`).
- [ ] Create minimal `src/offgrid_voice/` package with `/health` endpoint (probe access log suppression enabled) and smoke test.
- [ ] Verify `uv run pytest`, `uv run ruff check .`, `uv run mypy src tests`, and `git diff --check` exit 0.

---

## Completed Tasks Log

| Task | Title | Commit(s) | Date |
|---|---|---|---|
| `[00.0]` | Initial repository scaffolding (`template-agent:greenfield` + architecture) | *(initial)* | 2026-11-21 |

---

## Backlog (Upcoming, in priority order)

- [ ] **[01.1]** **Phase 1: Core Voice Server & Audio Pipeline** — FastAPI WebSocket + Wyoming protocol server + `Pipecat` pipeline with `barge-in`, `Silero VAD` + `Smart Turn`, CPU `whisper-large-v3-turbo` (`INT8`/`Q8_0`) / `Qwen3-ASR-1.7B-gguf` STT, `hydra-llm-router` (`fast` alias), and CPU `Piper TTS` (`pt_BR-faber-medium`) / `Kokoro-82M` TTS, validated with local Linux Wyoming / Android client.
- [ ] **[02.1]** **Phase 2: Tools & `sqlite-vec` Memory** — `Pydantic v2` modular tool registry (Home Assistant / MQTT control, homelab status, `whatsapp-api` via Redis / `POST /send`) + `sqlite-vec` semantic memory (`bge-m3` / `Qwen3-Embedding-0.6B` on CPU).
- [ ] **[03.1]** **Phase 3: Hardware Acquisition & Satellite Jailbreak** — Verify Echo board/bootloader revisions before purchase; provision Echo Show 5/8 (`amonet 2` + LineageOS/`View Assist`) and Echo Dot 2/3 (`Firebreak`/Wyoming bridge) satellites.
- [ ] **[04.1]** **Phase 4: 24/7 HA & CPU Fallback on Mini PC `i5-11400`** — Deploy 24/7 on Mini PC `i5-11400` (`32 GB RAM`) and verify automatic CPU fallback (`Qwen3-4B` / `Gemma-3-4B`) via `hydra-llm-router` when the `RTX 5060 Ti 16 GB` workstation is busy (`--parallel 1` coding jobs) or powered off.

---

## Release / Cycle Wrap-up (Not the next task)

Release/tag only with explicit human request. When triggered, the ID is `[99.1]`. Do not number feature, hygiene, or CI tasks as `99.x`. Do not calculate next task ID from this section.

---

## Future Backlog / Ideas (Unprioritized)

*(empty)*
