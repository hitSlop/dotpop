<script lang="ts">
  import "@hitslop/pop/base.css";
  import "./styles.css";
</script>

<svg class="pop-free-icon" width="512" height="512" viewBox="0 0 512 512" fill="none" aria-hidden="true">
  <defs>
    <linearGradient id="wp-body" x1="76" y1="92" x2="436" y2="462" gradientUnits="userSpaceOnUse">
      <stop offset="0%" stop-color="#ffffff" />
      <stop offset="100%" stop-color="#e8effc" />
    </linearGradient>
    <linearGradient id="wp-head" x1="76" y1="92" x2="436" y2="188" gradientUnits="userSpaceOnUse">
      <stop offset="0%" stop-color="#3563d8" />
      <stop offset="100%" stop-color="#203f96" />
    </linearGradient>
  </defs>
  <!-- Freestanding desk flip calendar silhouette -->
  <rect x="68" y="88" width="376" height="376" rx="56" fill="url(#wp-body)" stroke="#c7d5ec" stroke-width="7" />
  <!-- Cobalt top header -->
  <path d="M124 91 H388 C417 91 440 114 440 143 V186 H72 V143 C72 114 95 91 124 91 Z" fill="url(#wp-head)" />
  <!-- Twin protruding metallic spiral rings -->
  <rect x="148" y="42" width="38" height="82" rx="19" fill="#f1f5fd" stroke="#1d3880" stroke-width="8" />
  <rect x="326" y="42" width="38" height="82" rx="19" fill="#f1f5fd" stroke="#1d3880" stroke-width="8" />
  <!-- Subtle day column lines -->
  <line x1="194" y1="208" x2="194" y2="432" stroke="#dce5f4" stroke-width="4" />
  <line x1="318" y1="208" x2="318" y2="432" stroke="#dce5f4" stroke-width="4" />
  <!-- Color-coded schedule blocks -->
  <rect x="94" y="218" width="84" height="72" rx="18" fill="#c8e7ff" />
  <rect x="94" y="308" width="84" height="96" rx="18" fill="#e0d7fc" />
  <rect x="210" y="242" width="92" height="114" rx="18" fill="#ffd2c8" />
  <rect x="334" y="218" width="84" height="86" rx="18" fill="#c6eedb" />
  <rect x="334" y="322" width="84" height="82" rx="18" fill="#c8e7ff" />
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
