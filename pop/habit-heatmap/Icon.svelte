<script lang="ts">
  import "@hitslop/pop/base.css";
  import "./styles.css";
  import type { CaptureProps } from "@hitslop/pop/svelte";
  import type schema from "./schema";
  import { COLOR_HEX, dayKey, isCompleteOn, shiftDay } from "./calendar";

  let { snapshot }: CaptureProps<typeof schema> = $props();
  const today = dayKey(new Date());

  const dots = $derived.by(() => {
    const habits = snapshot.habits;
    const palette = ["#9be931", "#32c5ff", "#f6b73c", "#9e8cfc", "#34d399"];
    return Array.from({ length: 20 }, (_, i) => {
      const row = Math.floor(i / 5);
      const col = i % 5;
      const habit = habits[row];
      const day = shiftDay(today, -(4 - col));
      if (habit) {
        const hex = COLOR_HEX[habit.color] ?? palette[row % palette.length]!;
        const done = isCompleteOn(habit, day);
        return { fill: hex, opacity: done ? 1 : 0.22 };
      }
      return { fill: palette[row % palette.length]!, opacity: (i * 3 + 1) % 4 === 0 ? 0.22 : 0.9 };
    });
  });
</script>

<svg class="pop-free-icon" width="512" height="512" viewBox="0 0 512 512" fill="none" aria-hidden="true">
  <defs>
    <linearGradient id="hh-dark" x1="72" y1="64" x2="440" y2="462" gradientUnits="userSpaceOnUse">
      <stop offset="0%" stop-color="#262634" />
      <stop offset="100%" stop-color="#111118" />
    </linearGradient>
    <linearGradient id="hh-inner" x1="100" y1="120" x2="412" y2="430" gradientUnits="userSpaceOnUse">
      <stop offset="0%" stop-color="#1b1b25" />
      <stop offset="100%" stop-color="#0d0d13" />
    </linearGradient>
  </defs>
  <!-- Top rounded pebble loop handle -->
  <rect x="186" y="42" width="140" height="54" rx="22" fill="#262634" />
  <rect x="224" y="61" width="64" height="14" rx="7" fill="#9e8cfc" fill-opacity="0.72" />
  <!-- Freestanding dark tactile habit board -->
  <rect x="66" y="76" width="380" height="388" rx="68" fill="url(#hh-dark)" stroke="#38384c" stroke-width="6" />
  <!-- Recessed dark dot-matrix tray -->
  <rect x="96" y="112" width="320" height="318" rx="40" fill="url(#hh-inner)" />
  <!-- 5x4 live glowing habit dots -->
  {#each dots as dot, i}
    {@const col = i % 5}
    {@const row = Math.floor(i / 5)}
    <rect
      x={122 + col * 55}
      y={144 + row * 66}
      width="44"
      height="48"
      rx="14"
      fill={dot.fill}
      fill-opacity={dot.opacity}
    />
  {/each}
</svg>

<style>
  :global(html[data-pop-capture="icon"]),
  :global(html[data-pop-capture="icon"] body) {
    background: transparent !important;
  }
  .pop-free-icon {
    display: block;
    width: 512px;
    height: 512px;
    background: transparent;
  }
</style>
