# Idioma Svelte 5 no porte

Companion de [`SKILL.md`](SKILL.md). Default do `ui-port`: **Svelte 5** (SPA + Vite; SvelteKit só se o repo já for Kit). Outra stack só com ADR no repo alvo.

O proto é HTML/CSS. Svelte é o destino porque o markup quase não muda: classes, âncoras e tokens entram no template; estado e peças viram runes e componentes. Não reescreva o HTML em JSX nem em um design system inventado.

---

## Runes (obrigatório)

```svelte
<script lang="ts">
  type Props = { label: string; busy?: boolean };
  let { label, busy = false }: Props = $props();

  let count = $state(0);
  const caption = $derived(busy ? '…' : label);

  $effect(() => {
    document.title = caption;
  });
</script>

<button type="button" disabled={busy} onclick={() => (count += 1)}>
  {caption} ({count})
</button>
```

- Props: `$props()`, nunca `export let`.
- Estado: `$state` / `$derived`. Sem stores novos só para um valor local.
- Efeito reativo: `$effect` (poll, `data-theme`, título). `onMount` só para APIs do browser que não são reativas (ex. `addEventListener('popstate')`).
- Sem `export let`, sem Svelte 4 `$:`, sem misturar os dois idiomas na mesma peça.

---

## Chrome e átomos

Não cole `code.html` inteiro numa página. Extraia nesta ordem:

| Peça | Onde | O que entra |
| :--- | :--- | :--- |
| Header, nav, footer | `src/layout/` | chrome repetido em todo `scr-*` |
| Botão, badge, card | `src/components/` | markup que aparece 2+ vezes **ou** `cmp-*` do `COMPONENTS.md` |
| Página | `src/pages/` (SPA) ou `src/routes/` (Kit) | composição + bindings da ficha `scr-*` |

Âncoras `id` / `name` / `data-state` da seção 9 **permanecem no DOM** (no componente dono, não “renomeadas para ficar Svelte”).

```svelte
<!-- src/components/PrimaryButton.svelte — classes copiadas do proto -->
<script lang="ts">
  type Props = { id?: string; busy?: boolean; onclick: () => void; children?: import('svelte').Snippet };
  let { id, busy = false, onclick, children }: Props = $props();
</script>

<button {id} class="…do proto…" type="button" disabled={busy} {onclick}>
  {@render children?.()}
</button>
```

```svelte
<!-- src/layout/AppShell.svelte -->
<script lang="ts">
  import type { Snippet } from 'svelte';
  type Props = { children: Snippet };
  let { children }: Props = $props();
</script>

<header id="app-header">{/* nav do proto, uma vez */}</header>
<main>{@render children()}</main>
<footer id="app-footer">{/* footer do proto, uma vez */}</footer>
```

A página **usa** as peças; não duplica o header.

A **casca** (`grid`, `col-span-*`, `max-w-[…]`) fica na página, copiada do proto. O componente **não** inventa outro `grid-cols-*`. A string `class="…"` do botão/card no HTML vai inteira para o `.svelte` (incluindo `absolute`, `animate-*`, `blur-*`). `@keyframes` do `<style>` do proto: mesmo nome, mesma classe no mesmo tipo de nó.

---

## Anti-exemplos

```svelte
<!-- NÃO: HTML Stitch num único arquivo de rota, export let, onMount para poll -->
<script>
  export let status;
  import { onMount } from 'svelte';
  onMount(() => {
    const t = setInterval(load, 10000);
    return () => clearInterval(t);
  });
</script>
<!-- 400 linhas de header+footer+botões colados -->
```

```svelte
<!-- SIM: poll reativo + peças -->
<script lang="ts">
  let { status }: { status: Status | null } = $props();
  const intervalMs = $derived((status?.current_interval_seconds ?? 10) * 1000);
  $effect(() => {
    void load();
    const id = setInterval(() => void load(), intervalMs);
    return () => clearInterval(id);
  });
</script>
```
