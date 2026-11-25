<script lang="ts">
  import "@hitslop/pop/base.css";
  import "./styles.css";
</script>

<svg class="pop-free-icon" width="512" height="512" viewBox="0 0 512 512" fill="none" aria-hidden="true">
  <defs>
    <linearGradient id="fc-back" x1="140" y1="64" x2="430" y2="412" gradientUnits="userSpaceOnUse">
      <stop offset="0%" stop-color="#4d73f5" />
      <stop offset="100%" stop-color="#2242be" />
    </linearGradient>
    <linearGradient id="fc-front" x1="60" y1="90" x2="380" y2="410" gradientUnits="userSpaceOnUse">
      <stop offset="0%" stop-color="#ffffff" />
      <stop offset="100%" stop-color="#edf2ff" />
    </linearGradient>
  </defs>
  <!-- Back fanned cobalt card -->
  <g transform="rotate(11 286 244)">
    <rect x="134" y="84" width="308" height="316" rx="42" fill="url(#fc-back)" />
    <line x1="176" y1="148" x2="398" y2="148" stroke="#ffffff" stroke-opacity="0.28" stroke-width="8" stroke-linecap="round" />
    <line x1="176" y1="196" x2="360" y2="196" stroke="#ffffff" stroke-opacity="0.22" stroke-width="8" stroke-linecap="round" />
  </g>
  <!-- Front ruled ivory index card -->
  <g transform="rotate(-5 224 256)">
    <rect x="64" y="102" width="320" height="312" rx="42" fill="url(#fc-front)" stroke="#c7d6ff" stroke-width="7" />
    <!-- Top blue index-card rule -->
    <line x1="94" y1="162" x2="354" y2="162" stroke="#284bd8" stroke-opacity="0.28" stroke-width="6" />
    <line x1="94" y1="226" x2="354" y2="226" stroke="#d8e2ff" stroke-width="5" />
    <line x1="94" y1="290" x2="354" y2="290" stroke="#d8e2ff" stroke-width="5" />
    <line x1="94" y1="354" x2="354" y2="354" stroke="#d8e2ff" stroke-width="5" />
    <!-- Bold question mark -->
    <path
      d="M190 218 C190 190 256 186 256 218 C256 240 224 246 224 274"
      stroke="#1e3db8"
      stroke-width="24"
      stroke-linecap="round"
    />
    <circle cx="224" cy="322" r="14" fill="#1e3db8" />
  </g>
  <!-- Protruding mint mastery seal -->
  <circle cx="386" cy="382" r="62" fill="#89e8c3" stroke="#ffffff" stroke-width="10" />
  <path d="M358 384 L378 404 L416 362" stroke="#163b52" stroke-width="15" stroke-linecap="round" stroke-linejoin="round" />
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
