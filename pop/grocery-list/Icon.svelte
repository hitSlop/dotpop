<script lang="ts">
  import "@hitslop/pop/base.css";
  import "./styles.css";
  import type { CaptureProps } from "@hitslop/pop/svelte";
  import type schema from "./schema";
  let { snapshot }: CaptureProps<typeof schema> = $props();

  const doneCount = $derived(snapshot.items.filter((item) => item.done).length);
  const totalCount = $derived(snapshot.items.length);
  const checkedRows = $derived(totalCount > 0 ? Math.min(4, Math.round((doneCount / totalCount) * 4)) : 2);
</script>

<svg class="pop-free-icon" width="512" height="512" viewBox="0 0 512 512" fill="none" aria-hidden="true">
  <defs>
    <linearGradient id="gl-pad" x1="100" y1="84" x2="412" y2="472" gradientUnits="userSpaceOnUse">
      <stop offset="0%" stop-color="#fffef9" />
      <stop offset="100%" stop-color="#efe8da" />
    </linearGradient>
    <linearGradient id="gl-clip" x1="196" y1="24" x2="316" y2="112" gradientUnits="userSpaceOnUse">
      <stop offset="0%" stop-color="#ef6059" />
      <stop offset="100%" stop-color="#c43b37" />
    </linearGradient>
  </defs>
  <!-- Freestanding notepad body -->
  <rect x="86" y="76" width="340" height="398" rx="46" fill="url(#gl-pad)" stroke="#cfc5b4" stroke-width="6" />
  <!-- Protruding coral binder clip at top -->
  <path d="M214 58 C214 34 298 34 298 58" stroke="#992c28" stroke-width="14" stroke-linecap="round" />
  <rect x="172" y="54" width="168" height="52" rx="20" fill="url(#gl-clip)" />
  <rect x="206" y="70" width="100" height="12" rx="6" fill="#ffffff" fill-opacity="0.32" />
  <!-- Subtle horizontal ruled lines -->
  <g stroke="#e4dac8" stroke-width="4">
    <line x1="118" y1="186" x2="394" y2="186" />
    <line x1="118" y1="252" x2="394" y2="252" />
    <line x1="118" y1="318" x2="394" y2="318" />
    <line x1="118" y1="384" x2="394" y2="384" />
  </g>
  <!-- Grocery checklist rows driven by snapshot -->
  {#each [0, 1, 2, 3] as row}
    {@const y = 154 + row * 66}
    {@const checked = row < checkedRows}
    {#if checked}
      <rect x="128" y={y - 16} width="32" height="32" rx="10" fill="#2c9a6c" />
      <path d={`M136 ${y + 1} L142 ${y + 7} L153 ${y - 6}`} stroke="#ffffff" stroke-width="5.5" stroke-linecap="round" stroke-linejoin="round" />
      <line x1="180" y1={y} x2={row % 2 === 0 ? 334 : 302} y2={y} stroke="#9b9488" stroke-width="12" stroke-linecap="round" />
    {:else}
      <rect x="128" y={y - 16} width="32" height="32" rx="10" fill="#fffdf8" stroke="#c3b9a8" stroke-width="5" />
      <line x1="180" y1={y} x2={row === 2 ? 350 : 284} y2={y} stroke="#36322d" stroke-width="12" stroke-linecap="round" />
    {/if}
  {/each}
  <!-- Protruding cheerful yellow star magnet badge on bottom-right corner -->
  <circle cx="388" cy="410" r="56" fill="#facc15" stroke="#ffffff" stroke-width="8" />
  <path
    d="M388 374 L397 396 L420 398 L402 413 L408 436 L388 424 L368 436 L374 413 L356 398 L379 396 Z"
    fill="#854d0e"
  />
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
