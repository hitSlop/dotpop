<script lang="ts">
  import "@hitslop/pop/base.css";
  import "./styles.css";
  import { onDestroy, onMount } from "svelte";
  import { getDocument, haptics } from "@hitslop/pop/svelte";
  import { bindPolkaHandlers, minimizePolkaKeyboard, showPolkaKeyboard, syncPolkaDeck } from "../_shared/polka";
  import Check from "@lucide/svelte/icons/check";
  import Plus from "@lucide/svelte/icons/plus";
  import Minus from "@lucide/svelte/icons/minus";
  import ChevronLeft from "@lucide/svelte/icons/chevron-left";
  import ChevronRight from "@lucide/svelte/icons/chevron-right";
  import Footprints from "@lucide/svelte/icons/footprints";
  import Droplets from "@lucide/svelte/icons/droplets";
  import BookOpen from "@lucide/svelte/icons/book-open";
  import Leaf from "@lucide/svelte/icons/leaf";
  import Flame from "@lucide/svelte/icons/flame";
  import PenLine from "@lucide/svelte/icons/pen-line";
  import Dumbbell from "@lucide/svelte/icons/dumbbell";
  import Moon from "@lucide/svelte/icons/moon";
  import Music from "@lucide/svelte/icons/music";
  import Heart from "@lucide/svelte/icons/heart";
  import Ban from "@lucide/svelte/icons/ban";
  import Sparkles from "@lucide/svelte/icons/sparkles";
  import Trash2 from "@lucide/svelte/icons/trash-2";
  import schema, { colors, icons, type colors as _c } from "./schema";
  import {
    COLOR_HEX,
    addHabit,
    dayKey,
    dayNumber,
    editHabit,
    heatmapView,
    isCompleteOn,
    localDate,
    monthGrid,
    monthTitle,
    noteDayLabel,
    progressOn,
    removeHabit as dropHabit,
    setNote,
    shortWeekday,
    tapCheckin,
    weekdays,
    type Habit,
    type HabitColor,
    type HabitIcon,
    type HabitKind,
  } from "./calendar";

  const doc = getDocument(schema);

  let today = $state(dayKey(new Date()));
  let mode = $state<"cards" | "matrix">("cards");
  let detailID = $state<string | null>(null);
  let detailTab = $state<"calendar" | "stats" | "notes" | "edit">("calendar");
  let addingHabit = $state(false);
  let draftColor = $state<HabitColor>("lime");
  let draftIcon = $state<HabitIcon>("sparkles");
  let draftKind = $state<HabitKind>("build");
  let draftGoal = $state(1);

  const todayDate = $derived(localDate(today));
  let calYear = $state(new Date().getFullYear());
  let calMonth = $state(new Date().getMonth());

  const view = $derived(heatmapView(doc.current, today));
  const detailEntry = $derived(detailID ? view.habits.find((e) => e.habit.$id === detailID) ?? null : null);
  const doneTodayCount = $derived(view.habits.filter((e) => isCompleteOn(e.habit, today)).length);
  const monthCells = $derived(monthGrid(calYear, calMonth));

  onMount(() => {
    const update = () => {
      today = dayKey(new Date());
    };
    const timer = setInterval(update, 30_000);
    window.addEventListener("focus", update);
    return () => {
      clearInterval(timer);
      window.removeEventListener("focus", update);
    };
  });

  function habitHex(habit: Habit): string {
    return COLOR_HEX[habit.color] ?? "#9be931";
  }

  async function onTapCheck(habit: Habit, day: string, event?: Event) {
    event?.stopPropagation();
    if (day > today) return;
    const wasComplete = isCompleteOn(habit, day);
    await doc.change((tx) => tapCheckin(tx, habit, day, today));
    const willBeComplete = !wasComplete && (habit.checkins[day] ?? 0) + 1 >= habit.goal;
    if (willBeComplete) haptics.notification("success");
    else haptics.selection();
  }

  function openDetail(id: string) {
    detailID = id;
    detailTab = "calendar";
    addingHabit = false;
    calYear = todayDate.getFullYear();
    calMonth = todayDate.getMonth();
    haptics.selection();
  }

  function closeDetail() {
    detailID = null;
    detailTab = "calendar";
    haptics.selection();
  }

  function shiftMonth(delta: number) {
    const next = new Date(calYear, calMonth + delta, 1, 12);
    calYear = next.getFullYear();
    calMonth = next.getMonth();
    haptics.selection();
  }

  function startAddingHabit() {
    addingHabit = !addingHabit;
    if (addingHabit) {
      const nextColor = colors[doc.current.habits.length % colors.length] ?? "lime";
      draftColor = nextColor;
      draftIcon = "sparkles";
      draftKind = "build";
      draftGoal = 1;
      showPolkaKeyboard();
    } else {
      minimizePolkaKeyboard();
    }
  }

  async function handlePolkaSubmit(raw: string) {
    const text = raw.trim();
    if (!text) return;
    if (detailEntry && detailTab === "notes") {
      await doc.change((tx) => setNote(tx, detailEntry.habit.$id, today, text));
      haptics.notification("success");
      return;
    }
    if (detailEntry && detailTab === "edit") {
      await doc.change((tx) => editHabit(tx, detailEntry.habit.$id, text, detailEntry.habit.color));
      haptics.notification("success");
      return;
    }
    if (addingHabit) {
      const { id } = await doc.change((tx) =>
        addHabit(tx, text, draftColor, { icon: draftIcon, kind: draftKind, goal: draftGoal }),
      );
      addingHabit = false;
      minimizePolkaKeyboard();
      haptics.notification("success");
      if (id) detailID = null;
    }
  }

  async function updateDetail(patch: Partial<{ name: string; subtitle: string; color: HabitColor; icon: HabitIcon; kind: HabitKind; goal: number }>) {
    if (!detailEntry) return;
    const h = detailEntry.habit;
    await doc.change((tx) =>
      editHabit(tx, h.$id, patch.name ?? h.name, patch.color ?? h.color, {
        subtitle: patch.subtitle ?? h.subtitle,
        icon: patch.icon ?? h.icon,
        kind: patch.kind ?? h.kind,
        goal: patch.goal ?? h.goal,
      }),
    );
    haptics.selection();
  }

  async function deleteCurrentHabit() {
    if (!detailEntry) return;
    const id = detailEntry.habit.$id;
    detailID = null;
    await doc.change((tx) => dropHabit(tx, id));
    haptics.impact("medium");
  }

  onDestroy(
    bindPolkaHandlers({
      onSubmit: (text) => void handlePolkaSubmit(text),
      onAction: (id) => {
        if (id === "view-cards") {
          detailID = null;
          mode = "cards";
          addingHabit = false;
          haptics.selection();
        } else if (id === "view-matrix") {
          detailID = null;
          mode = "matrix";
          addingHabit = false;
          haptics.selection();
        } else if (id === "add-habit") {
          detailID = null;
          startAddingHabit();
        } else if (id === "detail-back") {
          closeDetail();
        } else if (id === "tab-cal") {
          detailTab = "calendar";
          minimizePolkaKeyboard();
          haptics.selection();
        } else if (id === "tab-stats") {
          detailTab = "stats";
          minimizePolkaKeyboard();
          haptics.selection();
        } else if (id === "tab-notes") {
          detailTab = "notes";
          showPolkaKeyboard();
          haptics.selection();
        } else if (id === "tab-edit") {
          detailTab = "edit";
          haptics.selection();
        }
      },
    }),
  );

  $effect(() => {
    if (detailEntry) {
      const wantsNotes = detailTab === "notes";
      const wantsRename = detailTab === "edit";
      syncPolkaDeck({
        field: wantsNotes
          ? { kind: "entry", placeholder: `Note for ${detailEntry.habit.name}…`, submit: { label: "Save", button: "check" }, canSubmit: true }
          : wantsRename
            ? { kind: "entry", placeholder: `Rename ${detailEntry.habit.name}…`, submit: { label: "Save", button: "check" }, canSubmit: true }
            : { kind: "none" },
        input: wantsNotes || wantsRename ? "keys" : "none",
        minimizesOnEntry: !(wantsNotes || wantsRename),
        keyboard: { kind: wantsNotes || wantsRename ? "qwerty" : "none" },
        bar: [
          { id: "detail-back", title: "All", symbol: "chevron.left" },
          { id: "tab-cal", title: "Cal", symbol: "calendar", selected: detailTab === "calendar" },
          { id: "tab-stats", title: "Stats", symbol: "chart.xyaxis.line", selected: detailTab === "stats" },
          { id: "tab-notes", title: "Notes", symbol: "note.text", selected: detailTab === "notes" },
          { id: "tab-edit", title: "Edit", symbol: "slider.horizontal.3", selected: detailTab === "edit" },
        ],
      });
    } else {
      syncPolkaDeck({
        field: addingHabit
          ? { kind: "entry", placeholder: "New habit (e.g. Meditate)…", submit: { label: "Add", button: "check" }, canSubmit: true }
          : { kind: "none" },
        input: addingHabit ? "keys" : "none",
        minimizesOnEntry: !addingHabit,
        keyboard: { kind: addingHabit ? "qwerty" : "none" },
        bar: [
          { id: "view-cards", title: "Cards", symbol: "square.grid.2x2", selected: mode === "cards" },
          { id: "view-matrix", title: "5-Day", symbol: "list.bullet", selected: mode === "matrix" },
          { id: "add-habit", title: "Habit", symbol: "plus.circle.fill", selected: addingHabit, role: addingHabit ? "primary" : "normal" },
        ],
      });
    }
  });
</script>

{#snippet habitGlyph(icon: HabitIcon, size = 18)}
  {#if icon === "run"}<Footprints {size} strokeWidth={2.2} />
  {:else if icon === "water"}<Droplets {size} strokeWidth={2.2} />
  {:else if icon === "book"}<BookOpen {size} strokeWidth={2.2} />
  {:else if icon === "leaf"}<Leaf {size} strokeWidth={2.2} />
  {:else if icon === "flame"}<Flame {size} strokeWidth={2.2} />
  {:else if icon === "pen"}<PenLine {size} strokeWidth={2.2} />
  {:else if icon === "dumbbell"}<Dumbbell {size} strokeWidth={2.2} />
  {:else if icon === "moon"}<Moon {size} strokeWidth={2.2} />
  {:else if icon === "music"}<Music {size} strokeWidth={2.2} />
  {:else if icon === "heart"}<Heart {size} strokeWidth={2.2} />
  {:else if icon === "ban"}<Ban {size} strokeWidth={2.2} />
  {:else}<Sparkles {size} strokeWidth={2.2} />
  {/if}
{/snippet}

{#snippet checkControl(habit: Habit, day: string, size = 38)}
  {@const hex = habitHex(habit)}
  {@const count = habit.checkins[day] ?? 0}
  {@const ratio = progressOn(habit, day)}
  {@const done = ratio >= 1}
  {@const r = 14}
  {@const c = 2 * Math.PI * r}
  <button
    class="hk-check"
    class:done
    style={`--hk-tone:${hex};width:${size}px;height:${size}px`}
    aria-label={done ? `Completed ${habit.name}` : `Check in ${habit.name}`}
    onclick={(e) => onTapCheck(habit, day, e)}
  >
    {#if habit.goal > 1 && !done}
      <svg class="hk-ring" viewBox="0 0 36 36" aria-hidden="true">
        <circle cx="18" cy="18" r={r} class="hk-ring-track" />
        <circle
          cx="18"
          cy="18"
          r={r}
          class="hk-ring-fill"
          stroke-dasharray={c}
          stroke-dashoffset={c * (1 - ratio)}
        />
      </svg>
      <span class="hk-ring-label">{count > 0 ? count : "+"}</span>
    {:else if done}
      <Check size={size * 0.48} strokeWidth={3} />
    {:else}
      <Plus size={size * 0.44} strokeWidth={2.4} />
    {/if}
  </button>
{/snippet}

{#snippet dotMatrix(habit: Habit, days: readonly string[])}
  {@const hex = habitHex(habit)}
  <div class="hk-matrix" style={`--hk-tone:${hex}`} aria-label={`${habit.name} 20-week heatmap`}>
    {#each days as day}
      {@const ratio = progressOn(habit, day)}
      {@const future = day > today}
      <span
        class="hk-dot"
        class:future
        class:today={day === today}
        style={ratio > 0 ? `opacity:${0.34 + ratio * 0.66};background:var(--hk-tone)` : undefined}
      ></span>
    {/each}
  </div>
{/snippet}

<main class="hk-shell">
  {#if detailEntry}
    {@const h = detailEntry.habit}
    {@const hex = habitHex(h)}
    <section class="hk-detail" style={`--hk-tone:${hex}`}>
      <header class="hk-detail-head">
        <div class="hk-icon-badge lg" style={`--hk-tone:${hex}`}>
          {@render habitGlyph(h.icon, 22)}
        </div>
        <div class="hk-detail-titles">
          <h1>{h.name}</h1>
          <p>{h.subtitle || (h.kind === "quit" ? "Quit habit" : h.goal > 1 ? `${h.checkins[today] ?? 0}/${h.goal} today` : "Daily habit")}</p>
        </div>
        {@render checkControl(h, today, 42)}
      </header>

      <div class="hk-pill-row">
        <span class="hk-pill accent"><Flame size={13} /> {detailEntry.streak} streak</span>
        <span class="hk-pill">{h.kind === "quit" ? "Quit" : "Build"}</span>
        <span class="hk-pill">{h.goal > 1 ? `${h.goal}× / day` : "Daily"}</span>
        <span class="hk-pill">{detailEntry.rate}% (30d)</span>
      </div>

      {#if detailTab === "calendar"}
        <div class="hk-card">
          {@render dotMatrix(h, view.days)}
        </div>
        <div class="hk-card">
          <div class="hk-cal-nav">
            <button class="hk-cal-btn" aria-label="Previous month" onclick={() => shiftMonth(-1)}><ChevronLeft size={16} /></button>
            <strong>{monthTitle(calYear, calMonth)}</strong>
            <button class="hk-cal-btn" aria-label="Next month" onclick={() => shiftMonth(1)}><ChevronRight size={16} /></button>
          </div>
          <div class="hk-cal-weekdays">
            {#each weekdays as wd}<span>{wd}</span>{/each}
          </div>
          <div class="hk-cal-grid">
            {#each monthCells as cell}
              {@const ratio = progressOn(h, cell.day)}
              {@const hasNote = Boolean(h.notes[cell.day])}
              <button
                class="hk-cal-cell"
                class:outside={!cell.inMonth}
                class:today={cell.day === today}
                class:done={ratio >= 1}
                class:partial={ratio > 0 && ratio < 1}
                disabled={cell.day > today}
                onclick={() => onTapCheck(h, cell.day)}
              >
                <span>{cell.num}</span>
                {#if hasNote}<i class="hk-note-dot"></i>{/if}
              </button>
            {/each}
          </div>
        </div>
      {:else if detailTab === "stats"}
        {@const maxCount = Math.max(1, ...detailEntry.monthly.map((m) => m.count))}
        <div class="hk-stat-grid">
          <div class="hk-stat-tile">
            <strong>{detailEntry.total}</strong>
            <span>Completions</span>
          </div>
          <div class="hk-stat-tile">
            <strong>{detailEntry.rate}%</strong>
            <span>30-Day Rate</span>
          </div>
          <div class="hk-stat-tile">
            <strong>{detailEntry.streak}</strong>
            <span>Current Streak</span>
          </div>
          <div class="hk-stat-tile">
            <strong>{detailEntry.bestStreak}</strong>
            <span>Best Streak</span>
          </div>
        </div>
        <div class="hk-card">
          <div class="hk-chart-head"><strong>Completions / Month</strong></div>
          <div class="hk-bars">
            {#each detailEntry.monthly as bar}
              <div class="hk-bar-col">
                <div class="hk-bar-track">
                  <div class="hk-bar-fill" style={`height:${Math.max(8, Math.round((bar.count / maxCount) * 100))}%`}></div>
                </div>
                <span class="hk-bar-val">{bar.count}</span>
                <span class="hk-bar-lbl">{bar.label}</span>
              </div>
            {/each}
          </div>
        </div>
      {:else if detailTab === "notes"}
        {@const noteEntries = Object.entries(h.notes).sort((a, b) => b[0].localeCompare(a[0]))}
        <div class="hk-card hk-notes-prompt">
          <strong>Every day has a story</strong>
          <p>Type in Polka's bar below to save today's note for {h.name}.</p>
        </div>
        <div class="hk-notes-list">
          {#each noteEntries as [day, text] (day)}
            <article class="hk-note-card" class:today={day === today}>
              <span class="hk-note-date"><i></i>{noteDayLabel(day, today)}</span>
              <p>{text}</p>
            </article>
          {:else}
            <p class="hk-empty-inline">No notes yet. What went well today?</p>
          {/each}
        </div>
      {:else if detailTab === "edit"}
        <div class="hk-card hk-edit-stack">
          <div class="hk-edit-section">
            <span class="hk-label">COLOR</span>
            <div class="hk-swatch-grid">
              {#each colors as c}
                <button
                  class="hk-swatch"
                  class:selected={h.color === c}
                  style={`background:${COLOR_HEX[c]}`}
                  aria-label={c}
                  onclick={() => updateDetail({ color: c })}
                ></button>
              {/each}
            </div>
          </div>
          <div class="hk-edit-section">
            <span class="hk-label">ICON</span>
            <div class="hk-icon-grid">
              {#each icons as ic}
                <button
                  class="hk-icon-opt"
                  class:selected={h.icon === ic}
                  aria-label={ic}
                  onclick={() => updateDetail({ icon: ic })}
                >
                  {@render habitGlyph(ic, 17)}
                </button>
              {/each}
            </div>
          </div>
          <div class="hk-edit-row">
            <div class="hk-edit-section">
              <span class="hk-label">TYPE</span>
              <div class="hk-seg">
                <button class:selected={h.kind === "build"} onclick={() => updateDetail({ kind: "build" })}>Build</button>
                <button class:selected={h.kind === "quit"} onclick={() => updateDetail({ kind: "quit" })}>Quit</button>
              </div>
            </div>
            <div class="hk-edit-section">
              <span class="hk-label">DAILY GOAL</span>
              <div class="hk-stepper">
                <button onclick={() => updateDetail({ goal: Math.max(1, h.goal - 1) })} aria-label="Decrease goal"><Minus size={14} /></button>
                <strong>{h.goal}×</strong>
                <button onclick={() => updateDetail({ goal: Math.min(20, h.goal + 1) })} aria-label="Increase goal"><Plus size={14} /></button>
              </div>
            </div>
          </div>
          <button class="hk-danger-btn" onclick={deleteCurrentHabit}><Trash2 size={15} /> Remove Habit</button>
        </div>
      {/if}
    </section>
  {:else}
    <header class="hk-top">
      <div>
        <h1>Habits</h1>
      </div>
      <span class="hk-today-pill">{doneTodayCount}/{view.habits.length} today</span>
    </header>

    {#if addingHabit}
      <div class="hk-quick-config">
        <div class="hk-swatch-row">
          {#each colors as c}
            <button
              class="hk-swatch sm"
              class:selected={draftColor === c}
              style={`background:${COLOR_HEX[c]}`}
              aria-label={c}
              onclick={() => { draftColor = c; haptics.selection(); }}
            ></button>
          {/each}
        </div>
        <div class="hk-quick-meta">
          <button class="hk-mini-chip" class:selected={draftKind === "build"} onclick={() => { draftKind = "build"; haptics.selection(); }}>Build</button>
          <button class="hk-mini-chip" class:selected={draftKind === "quit"} onclick={() => { draftKind = "quit"; haptics.selection(); }}>Quit</button>
          <button class="hk-mini-chip" onclick={() => { draftGoal = draftGoal >= 8 ? 1 : draftGoal + 1; haptics.selection(); }}>Goal: {draftGoal}×</button>
        </div>
      </div>
    {/if}

    {#if mode === "cards"}
      <div class="hk-card-list">
        {#each view.habits as entry (entry.habit.$id)}
          {@const h = entry.habit}
          {@const hex = habitHex(h)}
          <article class="hk-habit-card" style={`--hk-tone:${hex}`}>
            <div class="hk-habit-row" role="button" tabindex="0" onclick={() => openDetail(h.$id)} onkeydown={(e) => e.key === "Enter" && openDetail(h.$id)}>
              <div class="hk-icon-badge" style={`--hk-tone:${hex}`}>
                {@render habitGlyph(h.icon, 18)}
              </div>
              <div class="hk-habit-meta">
                <h2>{h.name}</h2>
                <p>
                  {#if h.subtitle}{h.subtitle}
                  {:else if h.goal > 1}{h.checkins[today] ?? 0} of {h.goal} today
                  {:else}{entry.streak > 0 ? `${entry.streak} day streak` : "Tap check to begin"}
                  {/if}
                </p>
              </div>
              {@render checkControl(h, today, 38)}
            </div>
            <div class="hk-matrix-tap" role="button" tabindex="-1" onclick={() => openDetail(h.$id)}>
              {@render dotMatrix(h, view.days)}
            </div>
          </article>
        {:else}
          <div class="hk-empty">
            <h2>Start your first habit</h2>
            <p>Tap <strong>Habit</strong> on the Touch Bar to add one.</p>
          </div>
        {/each}
      </div>
    {:else}
      <div class="hk-table-card">
        <div class="hk-table-head">
          <span class="hk-table-title">{view.habits.length} HABITS</span>
          <div class="hk-table-days">
            {#each view.last5 as d}
              <div class="hk-day-col" class:today={d === today}>
                <span>{shortWeekday(d)}</span>
                <strong>{dayNumber(d)}</strong>
              </div>
            {/each}
          </div>
        </div>
        <div class="hk-table-rows">
          {#each view.habits as entry (entry.habit.$id)}
            {@const h = entry.habit}
            {@const hex = habitHex(h)}
            <div class="hk-table-row" style={`--hk-tone:${hex}`}>
              <button class="hk-table-name" onclick={() => openDetail(h.$id)}>
                <span class="hk-icon-badge sm" style={`--hk-tone:${hex}`}>{@render habitGlyph(h.icon, 14)}</span>
                <span>{h.name}</span>
              </button>
              <div class="hk-table-cells">
                {#each view.last5 as d}
                  {@const ratio = progressOn(h, d)}
                  {@const done = ratio >= 1}
                  <button
                    class="hk-day-sq"
                    class:done
                    class:partial={ratio > 0 && ratio < 1}
                    class:today={d === today}
                    aria-label={`${h.name} ${d}`}
                    onclick={() => onTapCheck(h, d)}
                  >
                    {#if ratio > 0 && ratio < 1}
                      <span class="hk-sq-partial">{h.checkins[d]}</span>
                    {/if}
                  </button>
                {/each}
              </div>
            </div>
          {/each}
        </div>
      </div>
    {/if}
  {/if}
</main>
