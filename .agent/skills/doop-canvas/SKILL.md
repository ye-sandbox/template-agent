---
name: doop-canvas
description: Standardizes greenfield visual prototyping and post-launch UI evolution using a Doop HTML/CSS canvas via MCP (seed anchor frames, propose screens beside anchors, implement using existing repository components).
---

# Doop Visual Alignment & Feature Prototyping (`doop-canvas`)

Standard operational playbook for preventing visual drift when prototyping new screens or making structural layout changes, using a **Doop** (`kgoedecke/doop`) canvas connected via MCP.

> **Greenfield Note:** The legacy `ui-prototype` workflow is deprecated/unused. In greenfield projects, Doop handles visual prototyping directly before component-mapped code implementation.

---

## 1. Scope & Blast Radius

- **MUTABLE PATHS (Code Implementation Phase Only):** Application UI files explicitly authorized by the active task (`src/**`, `app/**`, `components/**`), plus `.agent/NOTES.md` (only when recording a newly seeded `Doop Canvas Contract`).
- **IMMUTABLE PATHS:** `.env`, secrets/credentials, backend API contracts unless explicitly in scope.
- **FORBIDDEN ACTIONS:**
  - MUST NOT create a duplicate canvas when a `Canvas ID` is already declared in `.agent/NOTES.md` or `.agent/INTERFACE.md`.
  - MUST NOT overwrite an existing anchor or baseline frame in-place during `propose`; always preserve the `Before` state and place the `After` proposal side-by-side.
  - MUST NOT dump raw HTML/CSS copied verbatim from a Doop frame into production React/Svelte/Compose files when equivalent repository components already exist.
  - MUST NOT ask the human to review a Doop frame before calling `get_frame_screenshot` to visually self-verify alignment against anchor frames.
  - MUST NOT commit or log MCP authentication tokens or credentials.

---

## 2. When to Use (Triggers)

Activate this skill whenever:
- Creating a **new screen, modal, drawer, or workflow** (both greenfield prototyping and post-launch evolution) where visual consistency matters.
- Refactoring layout density, navigation hierarchy, or visual structure across multiple screens side by side.
- Initializing (`seed`) a project's Doop Design Memory with representative anchor frames and CSS/Tailwind tokens.

Do NOT activate this skill when:
- Executing purely backend/API/database changes with zero UI impact.
- Performing trivial 1-line copy or CSS token fixes where a canvas round-trip adds unnecessary friction.

---

## 3. Prerequisites & Project Contract

Every repository participating in the Doop workflow declares a compact contract in `.agent/NOTES.md` (or `.agent/INTERFACE.md`):

```markdown
## Doop Canvas Contract
- **Canvas ID:** `/c/<canvas-id>`
- **Anchor Frames (Design Memory):** `Dashboard`, `ListView`, `StandardModal`
- **Token Source:** `src/app.css`
```

- **MCP Server:** `doop` (configured in the active agent/IDE environment).
- **Mandatory First Call in Any Canvas Session:** Invoke Doop's `get_guide` tool before mutating frames so canvas formatting and review conventions are loaded fresh.

---

## 4. Operational Procedure (3 Modes)

### Mode A: `seed` (One-Time Anchor Setup)

Run once per repository (or after a major visual redesign) so agents have real visual references instead of guessing:

1. **Extract Real Design Tokens:** Read the project's stylesheet / Tailwind theme (`Token Source`, e.g. `src/index.css`, `src/app.css`, `tailwind.config.*`) and extract exact palette variables, typography scale, border radii, shadows, and surface hierarchy.
2. **Select 2–3 Representative Anchor Screens:** Pick screens that cover the app's recurring patterns (e.g., primary dashboard/workspace, table/list view, form/modal view). Do NOT mirror every screen in the codebase.
3. **Create & Pin Anchor Frames:**
   - Call `get_guide` on the Doop MCP.
   - Create or reuse the project canvas and record its `/c/<canvas-id>` in `.agent/NOTES.md`.
   - Render each anchor screen as an HTML/CSS frame (`create_frame` / `set_frame_html`) faithfully reflecting the app's tokens and layout proportions.
   - Call `get_frame_screenshot` on each anchor frame to confirm rendering fidelity, then pin them as **Design Memory / Exemplars**.

### Mode B: `propose` (New Feature / Existing Screen Evolution)

Use BEFORE editing production UI files whenever a new screen or substantive layout change to an existing screen is requested:

1. **Resolve Context:** Read `Canvas ID` and `Anchor Frames` from `.agent/NOTES.md`. Never guess or create a duplicate canvas.
2. **Load Playbook & Inspect Anchors:** Call `get_guide` and inspect the pinned anchor frames/tokens on the canvas.
3. **Build Candidate Frame(s) Side-by-Side:**
   - **New Screen / Modal / Flow:** Place the proposed new screen **directly adjacent to the anchor frames** so spacing, header height, card radius, typography weight, and color contrast can be compared side by side.
   - **Existing Screen Change (`Before / After`):** Never overwrite the current frame in-place. If the target screen is not already an anchor on the canvas, first mirror its current production UI as `<Screen> (Before)`. Then place `<Screen> (After)` directly side-by-side with the `(Before)` / anchor frame so the exact visual delta is immediately clear.
   - If the layout direction is ambiguous, generate at most **2 clearly labeled variants** (`Variant A` / `Variant B`, or `(After - A)` / `(After - B)`) instead of guessing silently.
4. **Mandatory Visual Self-Audit:**
   - Call `get_frame_screenshot` on the proposed frame(s) (and on `<Screen> (Before)` if newly created).
   - Check explicitly for: header/sidebar mismatch, inconsistent border radii, overcrowded density, contrast issues, unaligned buttons/inputs, and (for Before/After pairs) unintended regressions in unchanged regions. Fix defects before handing over.
5. **Human Sign-Off Gate:**
   - Share the direct canvas URL (`/c/<canvas-id>`) with the user and summarize what was placed beside which anchor or `(Before)` frame.
   - Wait for human approval, canvas comments, or direct visual inspector edits before starting Mode C.

### Mode C: `implement` (Component-Mapped Code Integration)

Run AFTER the human approves (or edits) the proposed frame on Doop:

1. **Read Final Canvas State:** Fetch the approved frame HTML/CSS and any resolved comments from Doop via MCP (the human may have tweaked spacing/copy directly in the visual inspector).
2. **Map to Real Repository Components:**
   - Audit existing UI primitives (`src/components/**`, `src/layout/**`, shadcn/bits-ui wrappers) before writing JSX/Svelte/Compose.
   - Translate the approved frame's layout structure, spacing, and visual hierarchy using **existing project components and semantic tokens** — never paste standalone prototype `<style>` blocks or raw unstyled divs where shared components exist.
3. **Verify Live UI:**
   - Run the repository's build/typecheck/tests.
   - Verify the rendered app via interactive preview (`preview_*` or `agent-browser` with zero console errors), comparing visually against the approved Doop frame.
4. **Promote / Tidy Canvas:**
   - Once shipped and verified, update the corresponding anchor frame to reflect the new production state (or remove a temporary one-off `(Before)` frame) so the canvas stays clean and free of stale duplicates.

---

## 5. Contrast Pairs

```markdown
// BAD: Creating a fresh unnamed canvas every feature and pasting raw frame HTML into React
1. Agent creates a new Doop canvas for "Settings v2" (orphaned from anchor frames)
2. Agent skips get_frame_screenshot and asks user to review broken overflow
3. After approval, agent pastes raw iframe HTML + inline <style> directly into src/pages/Settings.tsx

// GOOD: Anchored side-by-side proposal (or Before/After pair) + component-mapped implementation
1. Agent reads Canvas ID `/c/proj-alpha` from .agent/NOTES.md and calls get_guide
2. For an existing screen redesign, agent preserves `Settings (Before)` and renders `Settings (After)` beside it, verifying parity with get_frame_screenshot
3. Human compares Before/After, tweaks card padding directly in Doop inspector, and approves
4. Agent reads updated frame via MCP, implements Settings.tsx using existing <PageHeader>, <Card>, and <Button> primitives, and promotes the shipped state on the canvas
```

---

## 6. Fail-Stop & Fallback Protocol

- **Unrequested & Unconfigured Fallback:** If the `doop` MCP server is unavailable AND the task did **NOT** explicitly request canvas alignment AND no `Canvas ID` is declared in `.agent/NOTES.md`, proceed normally with standard UI implementation without failing.
- **Active or Requested Fail-Stop:** If canvas alignment was explicitly requested by the user OR a `Canvas ID` is active in `.agent/NOTES.md`, and the `doop` MCP server is unreachable or returns an authentication/connection error after **2 retries**, halt canvas steps immediately and report the MCP unavailability cleanly (error message and tool failure details, never printing tokens or secrets). Do NOT silently fall back to coding an unapproved layout.

---

## 7. Completion Checklist

- [ ] `Doop Canvas Contract` (`Canvas ID`, `Anchor Frames`, `Token Source`) present in `.agent/NOTES.md`
- [ ] `get_guide` invoked before frame mutations
- [ ] Proposed frame visually verified via `get_frame_screenshot` beside anchor frames (or as a `Before / After` pair for existing screens)
- [ ] Human approval / inspector edits synced via MCP prior to code implementation
- [ ] Production code maps frame layout to existing repository components (zero raw prototype HTML dumps)
- [ ] Build, tests, and live UI check pass
- [ ] Canvas tidied after implementation (anchor updated / temporary `Before` frame promoted)
