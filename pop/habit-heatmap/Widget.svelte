<script lang="ts">
  import "@hitslop/pop/base.css";
  import "./styles.css";
  import type { CaptureProps, WidgetProps } from "@hitslop/pop/svelte";
  import type schema from "./schema";
  import { COLOR_HEX, dayKey, isCompleteOn, shiftDay } from "./calendar";

  let { snapshot, family }: CaptureProps<typeof schema> & WidgetProps = $props();
  const today = dayKey(new Date());
  const days = $derived(
    Array.from({ length: family === "large" ? 10 : 7 }, (_, i) => shiftDay(today, -(family === "large" ? 9 : 6) + i)),
  );
  const completed = $derived(snapshot.habits.filter((h) => isCompleteOn(h, today)).length);
  const habits = $derived(snapshot.habits.slice(0, family === "large" ? 4 : family === "medium" ? 2 : 1));
</script>

<main class="hk-widget">
  <header class="hk-w-head">
    <strong>Habits</strong>
    <span>{completed}/{snapshot.habits.length}</span>
  </header>
  <div class="hk-w-list">
    {#each habits as h (h.$id)}
      {@const hex = COLOR_HEX[h.color] ?? "#9be931"}
      <div class="hk-w-row">
        <span class="hk-w-name">{h.name}</span>
        <div class="hk-w-cells">
          {#each days as d}
            <span class="hk-w-cell" style={`background:${isCompleteOn(h, d) ? hex : "rgba(255,255,255,0.08)"}`}></span>
          {/each}
        </div>
      </div>
    {/each}
  </div>
</main>

<style>
  .hk-widget { width: 100%; height: 100%; padding: 14px; background: #0e0e14; color: #f5f5f8; display: flex; flex-direction: column; gap: 10px; font-family: -apple-system, sans-serif; }
  .hk-w-head { display: flex; justify-content: space-between; align-items: baseline; }
  .hk-w-head strong { font-size: 16px; font-weight: 800; }
  .hk-w-head span { font-size: 12px; color: #9494a6; font-weight: 700; }
  .hk-w-list { display: flex; flex-direction: column; gap: 8px; }
  .hk-w-row { display: flex; flex-direction: column; gap: 4px; }
  .hk-w-name { font-size: 12px; font-weight: 650; }
  .hk-w-cells { display: flex; gap: 4px; }
  .hk-w-cell { flex: 1; height: 14px; border-radius: 4px; }
</style>
