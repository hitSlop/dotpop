<script lang="ts">
  import "@hitslop/pop/base.css";
  import "./styles.css";
  import type { CaptureProps } from "@hitslop/pop/svelte";
  import type schema from "./schema";
  import { countdownView } from "./countdown";

  let { snapshot }: CaptureProps<typeof schema> = $props();
  const view = $derived(countdownView(snapshot, Date.now()));
  const daysText = $derived.by(() => {
    const s = view.state;
    if (s.kind === "counting" && s.days > 0) return String(Math.min(999, s.days));
    return "16";
  });
  const fontSize = $derived(daysText.length >= 3 ? 132 : 168);
</script>

<svg class="pop-free-icon" width="512" height="512" viewBox="0 0 512 512" fill="none" aria-hidden="true">
  <defs>
    <linearGradient id="cd-body" x1="74" y1="86" x2="438" y2="462" gradientUnits="userSpaceOnUse">
      <stop offset="0%" stop-color="#ffffff" />
      <stop offset="100%" stop-color="#dfeeff" />
    </linearGradient>
    <linearGradient id="cd-top" x1="74" y1="86" x2="438" y2="188" gradientUnits="userSpaceOnUse">
      <stop offset="0%" stop-color="#ff7163" />
      <stop offset="100%" stop-color="#dc4438" />
    </linearGradient>
    <linearGradient id="cd-flap" x1="112" y1="210" x2="400" y2="416" gradientUnits="userSpaceOnUse">
      <stop offset="0%" stop-color="#292434" />
      <stop offset="100%" stop-color="#17141f" />
    </linearGradient>
  </defs>
  <!-- Freestanding split-flap desk countdown tile -->
  <rect x="70" y="88" width="372" height="374" rx="64" fill="url(#cd-body)" stroke="#b7d3f5" stroke-width="7" />
  <!-- Coral header band -->
  <path d="M134 91 H378 C411 91 438 118 438 151 V186 H74 V151 C74 118 101 91 134 91 Z" fill="url(#cd-top)" />
  <!-- Twin protruding metallic flip-calendar rings -->
  <rect x="148" y="42" width="38" height="80" rx="19" fill="#fffaf2" stroke="#9e2a21" stroke-width="8" />
  <rect x="326" y="42" width="38" height="80" rx="19" fill="#fffaf2" stroke="#9e2a21" stroke-width="8" />
  <!-- Recessed split-flap dark numeral plate -->
  <rect x="108" y="212" width="296" height="210" rx="34" fill="url(#cd-flap)" />
  <text
    x="256"
    y="356"
    text-anchor="middle"
    fill="#ffffff"
    font-family="-apple-system, BlinkMacSystemFont, SF Pro Rounded, sans-serif"
    font-weight="800"
    font-size={fontSize}
    letter-spacing="-6"
  >{daysText}</text>
  <!-- Crisp horizontal split-flap hinge crease -->
  <line x1="108" y1="316" x2="404" y2="316" stroke="#0b0910" stroke-width="7" />
  <rect x="98" y="302" width="16" height="28" rx="6" fill="#f2d94e" />
  <rect x="398" y="302" width="16" height="28" rx="6" fill="#f2d94e" />
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
