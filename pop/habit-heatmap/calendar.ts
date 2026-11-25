import { dateLabel } from "../_shared/format";
import { refuse, type RowRef, type Tx, type Value } from "@hitslop/pop";
import type schema from "./schema";
import type { colors, icons, kinds } from "./schema";

export type Edit = Tx<typeof schema>;
export type Data = Value<typeof schema.descriptor>;
export type Habit = Data["habits"][number];
export type HabitColor = (typeof colors)[number];
export type HabitIcon = (typeof icons)[number];
export type HabitKind = (typeof kinds)[number];

export const COLOR_HEX: Record<HabitColor, string> = {
  lime: "#9be931",
  cyan: "#32c5ff",
  amber: "#f6b73c",
  violet: "#9e8cfc",
  mint: "#34d399",
  pink: "#f472b6",
  coral: "#fb7185",
  blue: "#60a5fa",
};

/** Local calendar dates, deliberately independent of UTC offsets and 24-hour durations. */
export function dayKey(date: Date): string {
  return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, "0")}-${String(date.getDate()).padStart(2, "0")}`;
}

export function localDate(day: string): Date {
  const match = /^(\d{4})-(\d{2})-(\d{2})$/.exec(day);
  if (!match) throw new RangeError("Expected a local calendar date");
  const date = new Date(0);
  date.setFullYear(Number(match[1]), Number(match[2]) - 1, Number(match[3]));
  date.setHours(12, 0, 0, 0);
  if (dayKey(date) !== day) throw new RangeError("Invalid calendar date");
  return date;
}

export function shiftDay(day: string, offset: number): string {
  const date = localDate(day);
  date.setDate(date.getDate() + offset);
  return dayKey(date);
}

/** 20 Monday–Sunday columns (140 days), ending with the current calendar week. */
export function calendarDays(today: string, weekCount = 20): string[] {
  const weekday = (localDate(today).getDay() + 6) % 7;
  const start = shiftDay(today, -weekday - (weekCount - 1) * 7);
  return Array.from({ length: weekCount * 7 }, (_, index) => shiftDay(start, index));
}

export function recentDays(today: string, count = 5): string[] {
  return Array.from({ length: count }, (_, i) => shiftDay(today, -(count - 1 - i)));
}

export function calendarWeeks(today: string, weekCount = 20) {
  const days = calendarDays(today, weekCount);
  const weeks = days.filter((_, i) => i % 7 === 0);
  const labels = weeks.map((day, index) =>
    index === 0 || day.slice(0, 7) !== weeks[index - 1]!.slice(0, 7)
      ? dateLabel(localDate(day), { month: "short" })
      : "",
  );
  return { days, weeks, labels };
}

export const weekdays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];

export function shortWeekday(day: string): string {
  return dateLabel(localDate(day), { weekday: "short" }).slice(0, 2);
}

export function dayNumber(day: string): string {
  return String(localDate(day).getDate());
}

export function monthGrid(year: number, monthIndex: number): Array<{ day: string; inMonth: boolean; num: number }> {
  const first = new Date(year, monthIndex, 1, 12);
  const startOffset = (first.getDay() + 6) % 7; // Monday = 0
  const start = new Date(year, monthIndex, 1 - startOffset, 12);
  return Array.from({ length: 42 }, (_, i) => {
    const d = new Date(start.getFullYear(), start.getMonth(), start.getDate() + i, 12);
    return {
      day: dayKey(d),
      inMonth: d.getMonth() === monthIndex,
      num: d.getDate(),
    };
  });
}

export function monthTitle(year: number, monthIndex: number): string {
  return dateLabel(new Date(year, monthIndex, 1, 12), { month: "short", year: "numeric" });
}

export function isCompleteOn(habit: Habit, day: string): boolean {
  return (habit.checkins[day] ?? 0) >= Math.max(1, habit.goal);
}

export function progressOn(habit: Habit, day: string): number {
  const count = habit.checkins[day] ?? 0;
  return Math.min(1, count / Math.max(1, habit.goal));
}

export function streak(habit: Habit, today: string): number {
  let day = isCompleteOn(habit, today) ? today : shiftDay(today, -1);
  let count = 0;
  while (isCompleteOn(habit, day)) {
    count++;
    day = shiftDay(day, -1);
  }
  return count;
}

export function bestStreak(habit: Habit, today: string): number {
  const keys = Object.keys(habit.checkins)
    .filter((d) => d <= today && isCompleteOn(habit, d))
    .sort();
  let best = 0;
  let run = 0;
  let prev = "";
  for (const d of keys) {
    if (prev && shiftDay(prev, 1) === d) run++;
    else run = 1;
    if (run > best) best = run;
    prev = d;
  }
  return best;
}

export function monthlySeries(habit: Habit, today: string, months = 6): Array<{ label: string; count: number }> {
  const base = localDate(today);
  const out: Array<{ label: string; count: number }> = [];
  for (let i = months - 1; i >= 0; i--) {
    const d = new Date(base.getFullYear(), base.getMonth() - i, 1, 12);
    const prefix = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}`;
    let count = 0;
    for (const [k, v] of Object.entries(habit.checkins)) {
      if (k.startsWith(prefix) && v >= Math.max(1, habit.goal)) count++;
    }
    out.push({ label: dateLabel(d, { month: "short" }), count });
  }
  return out;
}

export function completedDays(habit: Habit, days: readonly string[], today: string): number {
  return days.filter((day) => day <= today && isCompleteOn(habit, day)).length;
}

export function totalCompletions(habit: Habit, today: string): number {
  return Object.entries(habit.checkins).filter(([day, count]) => day <= today && count >= Math.max(1, habit.goal)).length;
}

export function completionRate(habit: Habit, today: string, windowDays = 30): number {
  let done = 0;
  for (let i = 0; i < windowDays; i++) {
    if (isCompleteOn(habit, shiftDay(today, -i))) done++;
  }
  return Math.round((done / windowDays) * 100);
}

export const labelDay = (day: string) =>
  dateLabel(localDate(day), { weekday: "long", month: "long", day: "numeric", year: "numeric" });

export const shortDay = (day: string) =>
  dateLabel(localDate(day), { month: "short", day: "numeric" });

export const noteDayLabel = (day: string, today: string) =>
  day === today ? "Today" : dateLabel(localDate(day), { weekday: "short", month: "short", day: "numeric" });

export function heatmapView(data: Data, today: string) {
  const { days, labels } = calendarWeeks(today, 20);
  const last5 = recentDays(today, 5);
  return {
    days,
    labels,
    last5,
    habits: data.habits.map((habit) => ({
      habit,
      streak: streak(habit, today),
      bestStreak: bestStreak(habit, today),
      completed: completedDays(habit, days, today),
      total: totalCompletions(habit, today),
      rate: completionRate(habit, today, 30),
      monthly: monthlySeries(habit, today, 6),
    })),
  };
}

function validDay(day: string): string {
  try {
    localDate(day);
  } catch {
    refuse("Use a calendar date written YYYY-MM-DD.");
  }
  return day;
}

export function addHabit(
  tx: Edit,
  name: string,
  color: HabitColor,
  options?: { subtitle?: string; icon?: HabitIcon; kind?: HabitKind; goal?: number },
) {
  if (!name.trim()) refuse("Give this habit a name.");
  return tx.fields.habits.insert({
    name: name.trim(),
    subtitle: (options?.subtitle ?? "").trim(),
    icon: options?.icon ?? "sparkles",
    color,
    kind: options?.kind ?? "build",
    goal: Math.max(1, Math.min(99, Math.round(options?.goal ?? 1))),
    checkins: {},
    notes: {},
  });
}

export function editHabit(
  tx: Edit,
  habit: RowRef,
  name: string,
  color: HabitColor,
  options?: { subtitle?: string; icon?: HabitIcon; kind?: HabitKind; goal?: number },
) {
  if (!name.trim()) refuse("Give this habit a name.");
  const row = tx.fields.habits.item(habit);
  row.name.set(name.trim());
  row.color.set(color);
  if (options?.subtitle !== undefined) row.subtitle.set(options.subtitle.trim());
  if (options?.icon !== undefined) row.icon.set(options.icon);
  if (options?.kind !== undefined) row.kind.set(options.kind);
  if (options?.goal !== undefined) row.goal.set(Math.max(1, Math.min(99, Math.round(options.goal))));
}

/** Mark or clear one day. Days after `today` cannot be checked in. */
export function setCheckin(tx: Edit, habit: RowRef, day: string, done: boolean, today: string, count = 1) {
  validDay(day);
  if (day > today) refuse("That day has not happened yet.");
  const checkins = tx.fields.habits.item(habit).checkins;
  if (done) checkins.put(day, Math.max(1, Math.round(count)));
  else checkins.delete(day);
}

/** Increment a daily habit count; wraps back to cleared once it exceeds goal. */
export function tapCheckin(tx: Edit, habit: Habit, day: string, today: string) {
  validDay(day);
  if (day > today) refuse("That day has not happened yet.");
  const checkins = tx.fields.habits.item(habit.$id).checkins;
  const current = habit.checkins[day] ?? 0;
  const goal = Math.max(1, habit.goal);
  if (current >= goal) checkins.delete(day);
  else checkins.put(day, current + 1);
}

export function setNote(tx: Edit, habit: RowRef, day: string, text: string) {
  validDay(day);
  const notes = tx.fields.habits.item(habit).notes;
  const clean = text.trim();
  if (clean) notes.put(day, clean);
  else notes.delete(day);
}

export function removeHabit(tx: Edit, habit: RowRef) {
  tx.fields.habits.remove(habit);
}
