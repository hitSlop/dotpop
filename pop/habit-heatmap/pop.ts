import { definePop } from "@hitslop/pop";

export default definePop({
  slug: "habit-heatmap",
  title: "Habit Heatmap",
  description: "Track daily habits with glowing heatmaps, 5-day routines, streaks, and daily notes.",
  author: { name: "pop", url: "https://dotpop.click" },
  categories: ["personal", "productivity"],
  window: { kind: "standard", width: 420, height: 680 },
  widget: { refreshMinutes: 30 },
  theme: {
    bg: "#0b0b10",
    surface: "#16161e",
    control: "#22222d",
    text: "#f5f5f8",
    muted: "#9494a6",
    border: "#2a2a38",
    accent: "#8b7cf6",
    onAccent: "#ffffff",
  },
});
