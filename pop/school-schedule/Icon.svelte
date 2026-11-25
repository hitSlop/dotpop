<script lang="ts">
  import "@hitslop/pop/base.css";
  import "./styles.css";
</script>

<svg class="pop-free-icon" width="512" height="512" viewBox="0 0 512 512" fill="none" aria-hidden="true">
  <defs>
    <linearGradient id="ss-cover" x1="72" y1="74" x2="398" y2="454" gradientUnits="userSpaceOnUse">
      <stop offset="0%" stop-color="#ffffff" />
      <stop offset="100%" stop-color="#eaf0fb" />
    </linearGradient>
    <linearGradient id="ss-spine" x1="72" y1="74" x2="146" y2="454" gradientUnits="userSpaceOnUse">
      <stop offset="0%" stop-color="#3465e8" />
      <stop offset="100%" stop-color="#1e42b4" />
    </linearGradient>
  </defs>
  <!-- Protruding colored index tabs along right edge -->
  <rect x="380" y="114" width="66" height="72" rx="20" fill="#ff907f" />
  <rect x="380" y="214" width="66" height="72" rx="20" fill="#a7e3a1" />
  <rect x="380" y="314" width="66" height="72" rx="20" fill="#ffc999" />
  <!-- Freestanding binder silhouette -->
  <rect x="72" y="74" width="342" height="378" rx="46" fill="url(#ss-cover)" stroke="#c7d6ef" stroke-width="7" />
  <!-- Cobalt left spine -->
  <path d="M118 77 H144 V449 H118 C93 449 75 431 75 406 V120 C75 95 93 77 118 77 Z" fill="url(#ss-spine)" />
  <circle cx="110" cy="146" r="10" fill="#ffffff" fill-opacity="0.7" />
  <circle cx="110" cy="262" r="10" fill="#ffffff" fill-opacity="0.7" />
  <circle cx="110" cy="378" r="10" fill="#ffffff" fill-opacity="0.7" />
  <!-- Crisp color-coded timetable pills -->
  <rect x="172" y="118" width="102" height="62" rx="16" fill="#d8f2d5" />
  <rect x="288" y="118" width="96" height="62" rx="16" fill="#e1d9ff" />
  <rect x="172" y="196" width="96" height="62" rx="16" fill="#ffe0ca" />
  <rect x="282" y="196" width="102" height="62" rx="16" fill="#d8eafa" />
  <rect x="172" y="274" width="114" height="62" rx="16" fill="#f8d8e8" />
  <rect x="300" y="274" width="84" height="62" rx="16" fill="#c9eeeb" />
  <rect x="172" y="352" width="212" height="58" rx="16" fill="#2858db" />
  <line x1="202" y1="381" x2="314" y2="381" stroke="#ffffff" stroke-width="12" stroke-linecap="round" />
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
