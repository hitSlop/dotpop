import { defineCommands } from "@hitslop/pop/commands";
import { s } from "@hitslop/pop";
import schema, { colors, icons, kinds } from "./schema";
import { addHabit, dayKey, editHabit, removeHabit, setCheckin, setNote } from "./calendar";

export default defineCommands(schema, {
  addHabit: {
    description: "Add a habit with optional subtitle, icon, build/quit kind, and daily goal.",
    args: {
      name: s.string(),
      color: s.enum(colors),
      subtitle: s.optional(s.string()),
      icon: s.optional(s.enum(icons)),
      kind: s.optional(s.enum(kinds)),
      goal: s.optional(s.integer({ min: 1 })),
    },
    run: ({ tx }, { name, color, subtitle, icon, kind, goal }) =>
      addHabit(tx, name, color, { subtitle, icon, kind, goal }),
  },
  editHabit: {
    description: "Update a habit's name, color, subtitle, icon, kind, or daily goal.",
    args: {
      habit: s.string({ description: "The habit's $id." }),
      name: s.string(),
      color: s.enum(colors),
      subtitle: s.optional(s.string()),
      icon: s.optional(s.enum(icons)),
      kind: s.optional(s.enum(kinds)),
      goal: s.optional(s.integer({ min: 1 })),
    },
    run: ({ tx }, { habit, name, color, subtitle, icon, kind, goal }) =>
      editHabit(tx, habit, name, color, { subtitle, icon, kind, goal }),
  },
  checkIn: {
    description: "Log completion (or a specific count) for a habit on a YYYY-MM-DD day.",
    args: {
      habit: s.string({ description: "The habit's $id." }),
      day: s.string({ description: "Local calendar day, YYYY-MM-DD." }),
      count: s.optional(s.integer({ min: 1 })),
    },
    run: (ctx, { habit, day, count }) =>
      setCheckin(ctx.tx, habit, day, true, dayKey(new Date(ctx.now)), count ?? 1),
  },
  clearCheckIn: {
    description: "Clear one day's check-in for a habit.",
    args: { habit: s.string({ description: "The habit's $id." }), day: s.string({ description: "Local calendar day, YYYY-MM-DD." }) },
    run: (ctx, { habit, day }) => setCheckin(ctx.tx, habit, day, false, dayKey(new Date(ctx.now))),
  },
  setNote: {
    description: "Add or update a daily reflection note for a habit on a YYYY-MM-DD day.",
    args: {
      habit: s.string({ description: "The habit's $id." }),
      day: s.string({ description: "Local calendar day, YYYY-MM-DD." }),
      text: s.string(),
    },
    run: ({ tx }, { habit, day, text }) => setNote(tx, habit, day, text),
  },
  removeHabit: {
    description: "Remove a habit and all its check-in history.",
    args: { habit: s.string({ description: "The habit's $id." }) },
    run: ({ tx }, { habit }) => removeHabit(tx, habit),
  },
});
