<script lang="ts">
  import "@hitslop/pop/base.css";
  import "./styles.css";
  import type { CaptureProps } from "@hitslop/pop/svelte";
  import type schema from "./schema";
  import { intakeView } from "./intake";

  let { snapshot }: CaptureProps<typeof schema> = $props();
  const percent = $derived(intakeView(snapshot).percent);
  const iconFill = $derived(Math.max(24, Math.min(84, percent || 45)));
  const liquidTop = $derived(Math.round(448 - (iconFill / 100) * 286));
</script>

<svg class="pop-free-icon" width="512" height="512" viewBox="0 0 512 512" fill="none" aria-hidden="true">
  <defs>
    <linearGradient id="wt-cap" x1="196" y1="36" x2="316" y2="112" gradientUnits="userSpaceOnUse">
      <stop offset="0%" stop-color="#67e8f9" />
      <stop offset="100%" stop-color="#0891b2" />
    </linearGradient>
    <linearGradient id="wt-body" x1="126" y1="110" x2="386" y2="472" gradientUnits="userSpaceOnUse">
      <stop offset="0%" stop-color="#0f3444" />
      <stop offset="100%" stop-color="#04151e" />
    </linearGradient>
    <linearGradient id="wt-liquid" x1="256" y1="220" x2="256" y2="458" gradientUnits="userSpaceOnUse">
      <stop offset="0%" stop-color="#67e8f9" />
      <stop offset="55%" stop-color="#22d3ee" />
      <stop offset="100%" stop-color="#0284c7" />
    </linearGradient>
    <clipPath id="wt-clip">
      <rect x="142" y="138" width="228" height="316" rx="64" />
    </clipPath>
  </defs>
  <!-- Protruding bottle cap & carry loop -->
  <path d="M222 60 C222 38 290 38 290 60" stroke="#0891b2" stroke-width="12" stroke-linecap="round" />
  <rect x="190" y="58" width="132" height="50" rx="18" fill="url(#wt-cap)" />
  <rect x="208" y="102" width="96" height="26" rx="10" fill="#164e63" />
  <!-- Freestanding rounded canteen / flask silhouette -->
  <rect x="126" y="122" width="260" height="348" rx="78" fill="url(#wt-body)" stroke="#22d3ee" stroke-opacity="0.45" stroke-width="8" />
  <!-- Dynamic glowing water level inside bottle -->
  <g clip-path="url(#wt-clip)">
    <path
      d={`M136 ${liquidTop} Q196 ${liquidTop - 22} 256 ${liquidTop} T376 ${liquidTop} V460 H136 Z`}
      fill="url(#wt-liquid)"
    />
    <path
      d={`M136 ${liquidTop + 4} Q196 ${liquidTop - 16} 256 ${liquidTop + 4} T376 ${liquidTop + 4}`}
      stroke="#ecfeff"
      stroke-opacity="0.65"
      stroke-width="6"
      fill="none"
    />
  </g>
  <!-- Crisp falling droplet -->
  <path d="M256 178 C256 178 232 212 232 228 C232 241 243 252 256 252 C269 252 280 241 280 228 C280 212 256 178 256 178 Z" fill="#a5f3fc" />
  <!-- Vertical specular glass highlight -->
  <line x1="164" y1="184" x2="164" y2="394" stroke="#ffffff" stroke-opacity="0.22" stroke-width="14" stroke-linecap="round" />
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
