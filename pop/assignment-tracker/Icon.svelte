<script lang="ts">
  import "@hitslop/pop/base.css";
  import "./styles.css";
</script>

<svg class="pop-free-icon" width="512" height="512" viewBox="0 0 512 512" fill="none" aria-hidden="true">
  <defs>
    <linearGradient id="asg-board" x1="88" y1="68" x2="396" y2="466" gradientUnits="userSpaceOnUse">
      <stop offset="0%" stop-color="#6b3f80" />
      <stop offset="100%" stop-color="#3f2150" />
    </linearGradient>
    <linearGradient id="asg-sheet" x1="118" y1="116" x2="368" y2="432" gradientUnits="userSpaceOnUse">
      <stop offset="0%" stop-color="#ffffff" />
      <stop offset="100%" stop-color="#f2ebf8" />
    </linearGradient>
    <linearGradient id="asg-badge" x1="286" y1="264" x2="442" y2="420" gradientUnits="userSpaceOnUse">
      <stop offset="0%" stop-color="#a8ebd0" />
      <stop offset="100%" stop-color="#6cc7a3" />
    </linearGradient>
  </defs>
  <g transform="rotate(-4 240 264)">
    <!-- Freestanding plum clipboard body -->
    <rect x="82" y="76" width="318" height="392" rx="44" fill="url(#asg-board)" />
    <!-- Protruding clipboard top clip -->
    <rect x="176" y="42" width="130" height="58" rx="22" fill="#e5d6f4" stroke="#3e224c" stroke-width="6" />
    <circle cx="241" cy="66" r="10" fill="#533163" />
    <!-- Paper sheet inside clipboard -->
    <rect x="114" y="114" width="254" height="320" rx="24" fill="url(#asg-sheet)" />
    <!-- Due lines & coral tag -->
    <rect x="142" y="152" width="84" height="22" rx="11" fill="#ffc1ae" />
    <line x1="142" y1="210" x2="332" y2="210" stroke="#472d58" stroke-width="14" stroke-linecap="round" />
    <line x1="142" y1="256" x2="296" y2="256" stroke="#b6a4c5" stroke-width="12" stroke-linecap="round" />
    <line x1="142" y1="302" x2="262" y2="302" stroke="#b6a4c5" stroke-width="12" stroke-linecap="round" />
    <line x1="142" y1="348" x2="228" y2="348" stroke="#d9cbe5" stroke-width="12" stroke-linecap="round" />
  </g>
  <!-- Protruding mint completion badge -->
  <rect x="282" y="266" width="164" height="164" rx="46" fill="url(#asg-badge)" stroke="#ffffff" stroke-width="10" />
  <path d="M326 350 L354 378 L406 320" stroke="#1f5745" stroke-width="18" stroke-linecap="round" stroke-linejoin="round" />
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
