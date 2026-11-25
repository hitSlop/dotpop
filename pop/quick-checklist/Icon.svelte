<script lang="ts">
  import "@hitslop/pop/base.css";
  import "./styles.css";
  import type { CaptureProps } from "@hitslop/pop/svelte";
  import type schema from "./schema";
  import { checklistView } from "./tasks";
  let { snapshot }: CaptureProps<typeof schema> = $props();
  const { marks } = $derived(checklistView(snapshot));
</script>

<svg class="pop-free-icon" width="512" height="512" viewBox="0 0 512 512" fill="none" aria-hidden="true">
  <defs>
    <linearGradient id="qc-card" x1="80" y1="64" x2="432" y2="448" gradientUnits="userSpaceOnUse">
      <stop offset="0%" stop-color="#fffaf4" />
      <stop offset="100%" stop-color="#f7e8dc" />
    </linearGradient>
    <linearGradient id="qc-top" x1="80" y1="64" x2="432" y2="148" gradientUnits="userSpaceOnUse">
      <stop offset="0%" stop-color="#ef929f" />
      <stop offset="100%" stop-color="#d46377" />
    </linearGradient>
    <linearGradient id="qc-fold" x1="336" y1="354" x2="428" y2="446" gradientUnits="userSpaceOnUse">
      <stop offset="0%" stop-color="#f8d65a" />
      <stop offset="100%" stop-color="#e3b838" />
    </linearGradient>
  </defs>
  <g transform="rotate(-2 256 256)">
    <!-- Freestanding note card with curled bottom-right corner -->
    <path
      d="M114 68 H398 C422 68 440 86 440 110 V356 L354 442 H114 C90 442 72 424 72 400 V110 C72 86 90 68 114 68 Z"
      fill="url(#qc-card)"
      stroke="#56303d"
      stroke-width="10"
      stroke-linejoin="round"
    />
    <!-- Blush header strip clipped cleanly inside top edge -->
    <path
      d="M114 73 H398 C419 73 435 89 435 110 V150 H77 V110 C77 89 93 73 114 73 Z"
      fill="url(#qc-top)"
    />
    <line x1="116" y1="114" x2="278" y2="114" stroke="#fffaf4" stroke-width="14" stroke-linecap="round" />
    <circle cx="388" cy="114" r="14" fill="#f8d65a" />
    <!-- Curled corner triangle -->
    <path
      d="M354 442 V374 C354 362 364 352 376 352 H440 L354 442 Z"
      fill="url(#qc-fold)"
      stroke="#56303d"
      stroke-width="8"
      stroke-linejoin="round"
    />
    <!-- Checklist rows -->
    {#each [0, 1, 2] as idx}
      {@const y = 216 + idx * 68}
      {@const done = marks[idx] ?? idx === 0}
      {#if done}
        <rect x="116" y={y - 20} width="40" height="40" rx="12" fill="#8bd6bc" stroke="#432830" stroke-width="6" />
        <path d={`M126 ${y + 1} L134 ${y + 9} L148 ${y - 8}`} stroke="#432830" stroke-width="6.5" stroke-linecap="round" stroke-linejoin="round" />
        <line x1="180" y1={y} x2="328" y2={y} stroke="#9c7e85" stroke-width="14" stroke-linecap="round" />
      {:else}
        <rect x="116" y={y - 20} width="40" height="40" rx="12" fill="#fffdf9" stroke="#c7a999" stroke-width="6" />
        <line x1="180" y1={y} x2={idx === 1 ? 356 : 292} y2={y} stroke="#432830" stroke-width="14" stroke-linecap="round" />
      {/if}
    {/each}
  </g>
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
