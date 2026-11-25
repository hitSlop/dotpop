<script lang="ts">
  import "@hitslop/pop/base.css";
  import "./styles.css";
  import type { CaptureProps } from "@hitslop/pop/svelte";
  import type schema from "./schema";
  import { COLOR_HEX, dayKey, heatmapView, progressOn, shortDay } from "./calendar";

  let { snapshot, preview = false }: CaptureProps<typeof schema> & { preview?: boolean } = $props();
  const today = dayKey(new Date());
  const view = $derived(heatmapView(snapshot, today));
  const items = $derived(preview ? view.habits.slice(0, 3) : view.habits);
</script>

<article class="hk-shell">
  <header class="hk-top">
    <h1>Habits</h1>
    <span class="hk-today-pill">{shortDay(view.days[0]!)} — {shortDay(today)}</span>
  </header>
  <div class="hk-card-list">
    {#each items as entry (entry.habit.$id)}
      {@const h = entry.habit}
      {@const hex = COLOR_HEX[h.color] ?? "#9be931"}
      <section class="hk-habit-card" style={`--hk-tone:${hex}`}>
        <div class="hk-habit-row">
          <div class="hk-habit-meta">
            <h2>{h.name}</h2>
            <p>{entry.total} completions · {entry.streak} day streak · {entry.rate}% (30d)</p>
          </div>
        </div>
        <div class="hk-matrix" style={`--hk-tone:${hex}`}>
          {#each view.days as day}
            {@const ratio = progressOn(h, day)}
            <span class="hk-dot" style={ratio > 0 ? `opacity:${0.34 + ratio * 0.66};background:var(--hk-tone)` : undefined}></span>
          {/each}
        </div>
      </section>
    {/each}
  </div>
</article>
