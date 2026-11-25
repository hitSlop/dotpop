<script lang="ts">
  import "@hitslop/pop/base.css";
  import "./styles.css";
</script>

<svg class="pop-free-icon" width="512" height="512" viewBox="0 0 512 512" fill="none" aria-hidden="true">
  <defs>
    <linearGradient id="se-paper" x1="120" y1="48" x2="392" y2="464" gradientUnits="userSpaceOnUse">
      <stop offset="0%" stop-color="#fffdf8" />
      <stop offset="100%" stop-color="#f2eadc" />
    </linearGradient>
    <linearGradient id="se-band" x1="124" y1="68" x2="388" y2="160" gradientUnits="userSpaceOnUse">
      <stop offset="0%" stop-color="#b4633e" />
      <stop offset="100%" stop-color="#7c4227" />
    </linearGradient>
  </defs>
  <g transform="rotate(-3 256 256)">
    <!-- Freestanding serrated receipt silhouette -->
    <path
      d="M116 64 L138 46 L160 64 L182 46 L204 64 L226 46 L248 64 L270 46 L292 64 L314 46 L336 64 L358 46 L380 64 L396 52 V456 L374 438 L352 456 L330 438 L308 456 L286 438 L264 456 L242 438 L220 456 L198 438 L176 456 L154 438 L132 456 L116 442 Z"
      fill="url(#se-paper)"
      stroke="#d4c7b4"
      stroke-width="6"
      stroke-linejoin="round"
    />
    <!-- Terracotta top stamp band -->
    <rect x="142" y="88" width="228" height="72" rx="18" fill="url(#se-band)" />
    <!-- Crisp $ emblem & header bar -->
    <circle cx="182" cy="124" r="21" fill="#fffaf2" fill-opacity="0.22" />
    <path d="M182 108 V140 M191 115 C189 111 174 111 174 118 C174 125 191 123 191 131 C191 138 175 138 173 133" stroke="#fffaf2" stroke-width="5.5" stroke-linecap="round" />
    <line x1="220" y1="114" x2="342" y2="114" stroke="#fffaf2" stroke-width="10" stroke-linecap="round" />
    <line x1="220" y1="136" x2="300" y2="136" stroke="#fffaf2" stroke-opacity="0.72" stroke-width="8" stroke-linecap="round" />
    <!-- Itemized rows -->
    <g stroke="#b8ab9a" stroke-width="12" stroke-linecap="round">
      <line x1="152" y1="204" x2="264" y2="204" />
      <line x1="312" y1="204" x2="358" y2="204" stroke="#6f6257" />
      <line x1="152" y1="250" x2="242" y2="250" />
      <line x1="312" y1="250" x2="358" y2="250" stroke="#6f6257" />
      <line x1="152" y1="296" x2="274" y2="296" />
      <line x1="312" y1="296" x2="358" y2="296" stroke="#6f6257" />
    </g>
    <!-- Perforated divider -->
    <line x1="150" y1="340" x2="362" y2="340" stroke="#cbbda9" stroke-width="6" stroke-dasharray="10 12" stroke-linecap="round" />
    <!-- Bold total bar -->
    <line x1="152" y1="386" x2="226" y2="386" stroke="#312c29" stroke-width="14" stroke-linecap="round" />
    <rect x="278" y="366" width="84" height="38" rx="12" fill="#8b4e31" />
    <line x1="298" y1="385" x2="342" y2="385" stroke="#fffaf2" stroke-width="10" stroke-linecap="round" />
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
