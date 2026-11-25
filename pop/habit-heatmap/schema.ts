import { defineDocument, s } from "@hitslop/pop";

export const colors = [
  "lime",
  "cyan",
  "amber",
  "violet",
  "mint",
  "pink",
  "coral",
  "blue",
] as const;

export const icons = [
  "run",
  "water",
  "book",
  "leaf",
  "flame",
  "pen",
  "dumbbell",
  "moon",
  "music",
  "heart",
  "ban",
  "sparkles",
] as const;

export const kinds = ["build", "quit"] as const;

// Deterministic initial check-ins anchored to a fixed calendar baseline (schema evaluation is pure).
function seedCheckins(offsets: readonly number[], value = 1): Record<string, number> {
  const baseDay = Date.UTC(2026, 10, 25); // 2026-11-25
  const out: Record<string, number> = {};
  for (const offset of offsets) {
    const d = new Date(baseDay - offset * 86_400_000);
    const key = `${d.getUTCFullYear()}-${String(d.getUTCMonth() + 1).padStart(2, "0")}-${String(d.getUTCDate()).padStart(2, "0")}`;
    out[key] = value;
  }
  return out;
}

export default defineDocument(
  {
    habits: s.list(
      s.object({
        name: s.text(),
        subtitle: s.text(),
        icon: s.enum(icons),
        color: s.enum(colors),
        kind: s.enum(kinds),
        goal: s.integer({ min: 1 }),
        checkins: s.record(s.integer({ min: 1 }), { description: "Completed counts keyed by YYYY-MM-DD." }),
        notes: s.record(s.string(), { description: "Daily reflection notes keyed by YYYY-MM-DD." }),
      }),
    ),
  },
  {
    initial: {
      habits: [
        {
          name: "Morning Run",
          subtitle: "Start the day outside",
          icon: "run",
          color: "lime",
          kind: "build",
          goal: 1,
          checkins: seedCheckins([0, 1, 2, 4, 5, 6, 8, 9, 11, 13, 14, 15, 18, 20, 22, 24, 27, 29, 31, 35, 38, 42, 45, 50, 54, 60, 65]),
          notes: {},
        },
        {
          name: "Drink Water",
          subtitle: "4 bottles through the day",
          icon: "water",
          color: "cyan",
          kind: "build",
          goal: 4,
          checkins: {
            ...seedCheckins([1, 2, 3, 4, 6, 7, 8, 10, 11, 12, 14, 16, 17, 19, 21, 23, 25, 28, 30, 33, 36, 40, 44], 4),
            ...seedCheckins([0, 5, 9, 13, 18], 2),
          },
          notes: {},
        },
        {
          name: "Read 20 Pages",
          subtitle: "Make time for a good book",
          icon: "book",
          color: "violet",
          kind: "build",
          goal: 1,
          checkins: seedCheckins([0, 1, 3, 4, 5, 7, 9, 10, 12, 15, 16, 19, 21, 22, 26, 28, 32, 36, 39, 43, 48]),
          notes: {},
        },
        {
          name: "No Sugar",
          subtitle: "Skip sweet snacks today",
          icon: "ban",
          color: "coral",
          kind: "quit",
          goal: 1,
          checkins: seedCheckins([1, 2, 3, 4, 5, 8, 9, 10, 14, 15, 16, 17, 20, 21, 25, 26, 30]),
          notes: {},
        },
      ],
    },
  },
);
