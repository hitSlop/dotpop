<script lang="ts">
  import "@hitslop/pop/base.css";
  import "./styles.css";
  import { bindText, getDocument } from "@hitslop/pop/svelte";
  import type { Value } from "@hitslop/pop";
  import { Checkbox, Dialog, Progress } from "bits-ui";
  import { onDestroy, onMount } from "svelte";
  import { bindPolkaHandlers, minimizePolkaKeyboard, showPolkaKeyboard, syncPolkaDeck } from "../_shared/polka";
  import schema from "./schema";
  import { addMilestone, countdownView, moveMilestone, removeMilestone, setCountdown, setMilestoneDone } from "./countdown";
  import CountdownFace from "./CountdownFace.svelte";
  import DatePicker from "./DatePicker.svelte";
  import { grow } from "./grow";
  const doc = getDocument(schema);
  type Milestone = Value<typeof schema.descriptor>["milestones"][number];

  let now = $state(Date.now());
  const view = $derived(countdownView(doc.current, now));
  let editing = $state(false);
  let editingSteps = $state(false);
  let title = $state("");
  let date = $state("");
  let time = $state("");
  let error = $state("");
  let newTitle = $state("");

  onMount(() => {
    const update = () => {
      now = Date.now();
    };
    const timer = setInterval(update, 1000);
    document.addEventListener("visibilitychange", update);
    return () => {
      clearInterval(timer);
      document.removeEventListener("visibilitychange", update);
    };
  });

  function edit() {
    title = doc.current.title;
    date = doc.current.targetDate;
    time = doc.current.targetTime;
    error = "";
    editing = true;
  }

  async function save() {
    try {
      await doc.change((tx) => setCountdown(tx, title, date, time));
    } catch (e) {
      error = e instanceof Error ? e.message : "Choose a valid date and local time.";
      return;
    }
    now = Date.now();
    editing = false;
  }

  async function add() {
    if (!newTitle.trim() || view.full) return;
    await doc.change((tx) => addMilestone(tx, doc.current, newTitle));
    newTitle = "";
  }

  function move(id: string, step: number) {
    return doc.change((tx) => moveMilestone(tx, doc.current, id, step));
  }

  let addingStep = $state(false);

  onDestroy(bindPolkaHandlers({
    onSubmit: async (text) => {
      const clean = text.trim();
      if (!clean || view.full) return;
      await doc.change((tx) => addMilestone(tx, doc.current, clean));
      addingStep = false;
      minimizePolkaKeyboard();
    },
    onAction: (id) => {
      if (id === "add-step") {
        addingStep = !addingStep;
        if (addingStep) showPolkaKeyboard();
        else minimizePolkaKeyboard();
      } else if (id === "edit-date") {
        addingStep = false;
        minimizePolkaKeyboard();
        edit();
      } else if (id === "toggle-reorder") {
        editingSteps = !editingSteps;
      }
    },
  }));

  $effect(() => {
    syncPolkaDeck({
      field: addingStep
        ? { kind: "entry", placeholder: "Add a milestone…", submit: { label: "Add", button: "check" }, canSubmit: true }
        : { kind: "none" },
      input: addingStep ? "keys" : "none",
      minimizesOnEntry: !addingStep,
      keyboard: { kind: addingStep ? "qwerty" : "none" },
      bar: [
        { id: "add-step", title: "Step", symbol: "plus.circle.fill", selected: addingStep, isEnabled: !view.full, role: addingStep ? "primary" : "normal" },
        { id: "edit-date", title: "Date", symbol: "calendar" },
        { id: "toggle-reorder", title: editingSteps ? "Done" : "Reorder", symbol: "arrow.up.arrow.down", selected: editingSteps },
      ],
    });
  });
</script>

{#snippet milestoneList(items: readonly Milestone[], editable: boolean)}
  <ol class="list">
    {#each items as item, index (item.$id)}
      <li class="row">
        {#if editable}
          <Checkbox.Root
            class="check"
            checked={item.done}
            onCheckedChange={(checked) => doc.change((tx) => setMilestoneDone(tx, item.$id, checked))}
            aria-label={`Complete ${item.title || "milestone"}`}
          >
            {#snippet children()}{item.done ? "✓" : ""}{/snippet}
          </Checkbox.Root>
          <textarea
            class="milestone"
            data-done={item.done}
            aria-label={`Milestone ${index + 1} title`}
            rows="1"
            use:bindText={doc.at(item).title}
            use:grow={item.title}
          ></textarea>
          {#if editingSteps}
            <div class="tools" data-pop-export="hide">
              <button class="smallButton" aria-label={`Move ${item.title} up`} disabled={index === 0} onclick={() => move(item.$id, -1)}>↑</button>
              <button class="smallButton" aria-label={`Move ${item.title} down`} disabled={index === items.length - 1} onclick={() => move(item.$id, 1)}>↓</button>
              <button class="smallButton" aria-label={`Delete ${item.title}`} onclick={() => doc.change((tx) => removeMilestone(tx, item.$id))}>×</button>
            </div>
          {/if}
        {:else}
          <span class="check" data-state={item.done ? "checked" : "unchecked"} aria-label={item.done ? "Complete" : "Incomplete"}>{item.done ? "✓" : ""}</span>
          <span class="milestone" data-done={item.done}>{item.title}</span>
        {/if}
      </li>
    {:else}
      {#if !editable}<li class="empty">No milestones yet.</li>{/if}
    {/each}
  </ol>
{/snippet}

  <main class="shell" aria-label="Countdown and milestones">
    <header class="header">
      <span class="eyebrow">A date to remember</span>
      <button class="button" data-pop-export="hide" onclick={edit}>Edit countdown</button>
    </header>
    <CountdownFace data={doc.current} state={view.state} onEdit={edit} />
    <section aria-label="Milestones">
      <div class="sectionHead">
        <h2 class="sectionTitle">Along the way</h2>
        <button class="smallButton" data-pop-export="hide" onclick={() => (editingSteps = !editingSteps)} aria-pressed={editingSteps}>
          {editingSteps ? "Done editing" : "Edit steps"}
        </button>
      </div>
      <div class="progressRow">
        <span>{view.done} of {view.total} complete</span>
        <Progress.Root class="track" value={view.done} max={Math.max(1, view.total)} aria-label="Milestone completion">
          <div class="fill" style:width={`${view.ratio}%`}></div>
        </Progress.Root>
      </div>
      {@render milestoneList(doc.current.milestones, true)}
      {#if !view.total}
        <p class="empty">Anything to do before the big day? Add your first step.</p>
      {/if}
      <form
        class="add"
        data-pop-export="hide"
        onsubmit={(event) => {
          event.preventDefault();
          add();
        }}
      >
        <input
          class="addInput"
          bind:value={newTitle}
          maxlength="120"
          placeholder="Add a milestone…"
          aria-label="New milestone"
          disabled={view.full}
        />
        <button class="addButton" type="submit" disabled={!newTitle.trim() || view.full}>+ Add</button>
      </form>
      {#if view.full}
        <p class="empty">All 25 milestone spaces are filled.</p>
      {/if}
    </section>
  </main>

  <Dialog.Root bind:open={editing}>
    <Dialog.Portal>
      <Dialog.Overlay class="overlay" data-pop-export="hide" />
      <Dialog.Content class="dialog" data-pop-export="hide">
        <Dialog.Title class="dialogTitle">Something to look forward to.</Dialog.Title>
        <Dialog.Description class="description">Choose the date and time in your local timezone.</Dialog.Description>
        <form
          onsubmit={(event) => {
            event.preventDefault();
            save();
          }}
        >
          <label class="field">
            Event name
            <input class="input" bind:value={title} maxlength="100" required />
          </label>
          <div class="field">
            <span>Target date</span>
            <DatePicker bind:value={date} />
          </div>
          <label class="field">
            Time
            <input class="input" type="time" bind:value={time} required />
          </label>
          {#if error}<p class="error" role="alert">{error}</p>{/if}
          <div class="actions">
            <Dialog.Close class="button" type="button">Cancel</Dialog.Close>
            <button class="save" type="submit">Save countdown</button>
          </div>
        </form>
      </Dialog.Content>
    </Dialog.Portal>
  </Dialog.Root>
