<script lang="ts">
  import "@hitslop/pop/base.css";
  import "./styles.css";

  const tones = [
    "#a8d3b5", "#f26a5a", "#a8d3b5", "#eee487", "#a8d3b5",
    "#83c7c1", "#a8d3b5", "#e7d8ce", "#f26a5a", "#a8d3b5",
    "#e7d8ce", "#a8d3b5", "#eee487", "#a8d3b5", "#83c7c1",
    "#a8d3b5", "#f26a5a", "#a8d3b5", "#e7d8ce", "#a8d3b5",
  ];
</script>

<svg class="pop-free-icon" width="512" height="512" viewBox="0 0 512 512" fill="none" aria-hidden="true">
  <defs>
    <linearGradient id="hh-shell" x1="72" y1="64" x2="440" y2="458" gradientUnits="userSpaceOnUse">
      <stop offset="0%" stop-color="#45314a" />
      <stop offset="100%" stop-color="#271a2a" />
    </linearGradient>
    <linearGradient id="hh-paper" x1="100" y1="120" x2="412" y2="424" gradientUnits="userSpaceOnUse">
      <stop offset="0%" stop-color="#f7f2e8" />
      <stop offset="100%" stop-color="#e8dfd0" />
    </linearGradient>
  </defs>
  <!-- Top rounded tab handle giving a distinctive punch-card/pebble silhouette -->
  <rect x="182" y="44" width="148" height="56" rx="24" fill="#45314a" />
  <rect x="224" y="64" width="64" height="14" rx="7" fill="#eee8dd" fill-opacity="0.55" />
  <!-- Freestanding tactile plum board -->
  <rect x="66" y="78" width="380" height="384" rx="64" fill="url(#hh-shell)" />
  <!-- Warm cream inner dot-matrix card -->
  <rect x="98" y="114" width="316" height="314" rx="38" fill="url(#hh-paper)" />
  <!-- 5x4 vibrant habit heatmap dots -->
  {#each tones as fill, i}
    {@const col = i % 5}
    {@const row = Math.floor(i / 5)}
    <rect
      x={124 + col * 55}
      y={146 + row * 64}
      width="42"
      height="46"
      rx="13"
      {fill}
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
