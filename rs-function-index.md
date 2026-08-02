# RS Retainer Tracker — Function Index
**Current version: v0.13.0** | **File: index.html** | **Lines: ~4,808**

Use this as a starting point each session to avoid grepping the whole file.
Update the version and any changed line numbers when making edits.

⚠️ **This index predates the v0.13.0 retainer/All Projects restructure and v0.11.1/v0.12.x patches — line numbers throughout are stale (the file shrank ~215 lines in v0.13.0 alone). Function names for anything not listed below are still a reasonable starting point (`grep -n "^function name"`), but the following no longer exist or changed shape:**

**Deleted in v0.13.0** (the standalone Retainers nav page is gone — confirmed with the user before deleting, since it removed a working ad-hoc hour-logging feature): `renderDashboard()`, `renderRetainer()`, `renderCalendar()`, `openQuickLogModal()`, `openTaskModal()` (the legacy rs_tasks edit modal — not the same as `openProjTaskModal`), and the `'dashboard'` nav button/`state.view` value. State fields `retainerView`, `dashSearch`, `dashSort`, `calMonth`, `calHidden` are gone too — they were only used by the deleted code. `meterHtml()` and `clientUsage()` survived (still used by the retainer client cards and the merged tabs).

**Changed shape in v0.13.0:**
- `clientRetainerHeaderHtml(c)` — dropped the `mode` param and the "Retainers /" breadcrumb variant; there's only one entry point now.
- `renderClientTasksView(c)` — now renders a shared header + `retainerTabsHtml(tab)` toggle + tab body, instead of being one of two separate page functions. Split into `renderRetainerTasksBodyHtml(c)` / `wireRetainerTasksBody(c)` (sync, the to-do list) and `loadRetainerAllowanceBody(c)` (async, the monthly-allowance history — was `renderClientAllowanceView`, same logic, now writes into `#retainerTabBody` instead of `main` directly).
- `renderProjects()` dispatcher — the `'retainerAllowance'` `projView` branch is gone; both tabs live under `'retainerTasks'` now, switched via `state.retainerTab`.
- `clientCardHtml(c)` — the retainer branch now includes `meterHtml()`, a colored remaining/over status line, and the renewal cycle dates (previously just showed the open-task count).
- `refreshCurrentView()` — re-checks `state.projView==='retainerTasks' && state.retainerTab==='allowance'` (was `state.projView==='retainerAllowance'`) to decide whether to re-run the async allowance fetch after a data refresh.

**Prior patch notes (v0.11.1, pre-dates v0.13.0 too):**
1. Animator column/section conditional on `project_type==='Animations'` via a `showAnimator` param threaded through `taskGridColumns`/`taskRowHtml`/`taskTableHtml`.
2. Fixed "Could not save task" — `assigned_animator_ids` is only sent to Supabase for animation tasks now, with a retry-on-`42703` fallback for when migration v19 hasn't been run yet.

**Patch 2** (Home page pass, this session):
1. Greeting shows first name only (`me.name.split(/\s+/)[0]`).
2. "To do" card now renders before "To review" (was the reverse).
3. `.home-cols` 2-column breakpoint raised from `max-width:800px` to `max-width:1300px` — stacks to one column much sooner.
4. Home task rows now navigate to the project/retainer-task view only, no modal — new shared `navigateToTaskContext(taskId)` (extracted from `jumpToProjTask`, which still opens the modal after navigating, used by the command palette). Wired via a new `wireTaskRows(root, {onRowClick})` option.
5. New `miroIconBtnHtml(client)` (next to `miroButtonsHtml`) — icon-only yellow Miro shortcut, shown per-row on Home when that task's client has a Miro link. `.miro-icon-btn` CSS class.
6. `homeTaskTableHtml` rewritten to reuse the shared inline-edit system: rows now carry `data-projtask` (was `data-hometask`, now gone) plus `data-taskname`/`data-statusinline`/`data-priorityinline`, and `renderHome()` calls `wireTaskRows(main, {onRowClick: navigateToTaskContext})` instead of its own bespoke click wiring. Status is now always a visible inline-editable column (previously just a color dot).

---

## Quick orientation

```
HTML structure:
  <style>        CSS (~450 lines) — design tokens (incl. dark theme), all component styles
  <body>         .app-shell (collapsible #sidebar + #main) + #quickAddFab + #cmdPalette (dynamic) + modal root + toast
  <script>       Everything else (~4,550 lines)
    Line 531     Constants
    Line 536     State initialisation
    Line 549     Theme (resolveTheme / applyTheme / toggleTheme) — runs immediately, before boot()
    Line 564     Empty-state helper (EMPTY_ICONS, emptyStateHtml)
    Line 623     PALETTE, status/task constants
    Line 666     Utility helpers (contrastText, mutedBg, avatars, clientUsage)
    Line 714     loadAll()
    Line 754     Modal / UI primitives (showModal now takes an optional {wide:true})
    Line 1019    Quick Add (openQuickAddMenu, quickAddPickClient)
    Line 1054    Client modals (new/edit)
    Line 1367    render() dispatcher
    Line 1425    Page render functions (Home, Retainers, Projects, Milestones, Settings)
    Line 1595    Command palette (openCommandPalette, closeCommandPalette, cmdPaletteHighlight)
    Line 2511    Task time-entry helpers
    Line 2671    Task / stage helpers (blankProjTask, taskClient, taskRowHtml)
    Line 2787    ASSIGN_ROLE_FIELD / ASSIGN_ROLE_CAN (designer/reviewer/animator inline-edit maps)
    Line 2790    wireTaskRows() — all inline-edit wiring lives here now
    Line 2923    Week Tasks page
    Line 2962    openProjTaskModal()
    Line 3080    renderProjDetail()
    Line 3830    Developer settings / import
    Line 3944    initColumnResize()
    Line 3982    Animation constants
    Line 3993    Animation helpers
    Line 4009    renderAnimation() — DUPLICATE (see note below)
    Line 4304    bootPublicDashboard()
    Line 4340    renderPublicDashboard()
    Line 4491    boot()
    Line 4573    renderAnimation() — REAL one (overrides line 4009)
```

⚠️ **Known issue:** `renderAnimation` is defined twice (4009 and 4573) and `openAnimCellModal` twice (4262 and 4930) — second definition wins at runtime in both cases. Pre-existing, not touched this session.

---

## v0.11.0 — this session's additions

Big feature batch on top of v0.10.0's visual redesign. Requires one manual step: **run `outputs/v19_add_animator.sql` in the Supabase SQL editor** before Animator assignments will actually persist (adds `rs_members.can_animate` and `rs_proj_tasks.assigned_animator_ids`). Until then the UI still works — it just always treats every member as animator-eligible and can't save animator picks server-side.

1. **Animator category** — third assignment role alongside Designer/Reviewer. Touches: `TASK_COLUMNS`/`TASK_COL_DEFAULTS` (line 659, 2691), default `state.taskCols` (line 538), `blankProjTask` (2671), `taskRowHtml`/`taskGridColumns`/`taskTableHtml` header (2701–2760), `duplicateProjTask` (2761), `openProjTaskModal`'s `animatorPool` + pill selector + save (2962), Settings team table `can_animate` checkbox (~3564, reuses the existing field-agnostic `data-mrole` handler unchanged).
2. **Inline editing** — `wireTaskRows` (2790) now wires: status (pre-existing), priority (`data-priorityinline`, a native `<select class="priority-select">` mirroring status), designer/reviewer/animator (`data-assigninline="taskId:role"`, opens the existing generic `openCheckboxDropdown` popover, stays open across multiple picks since it re-renders the table in the background via `refreshProjectView()` without touching the popover's own DOM), retainer toggle (`data-retainerinline`, flips `counts_toward_retainer` then re-runs `syncProjTaskRetainer`), and task-name rename (`data-taskname`, swaps the title span for an `<input>` on click, commits on blur/Enter, cancels on Escape). New shared helper `taskClient(t)` (2695) replaces 3 copies of the same inline client-lookup.
3. **Modal layout clarity** — `showModal(html, opts)` now accepts `{wide:true}` (`.modal-card.wide{max-width:660px}`). New `.modal-section-label` divider class groups fields visually (Team / Dates & hours in the task modal at 2962; Basics / Links / Client dashboard in the client edit modal at 1108).
4. **Empty states** — `emptyStateHtml({icon,title,subtitle,actionLabel,actionAttr})` + `EMPTY_ICONS` (564) render a circular icon + title + subtitle + optional CTA button. Applied to: `taskTableHtml`'s shared empty fallback (covers every project stage and the client to-do/completed lists automatically), `homeTaskTableHtml` (now takes an optional `emptyLabel` — 2 call sites pass "Nothing to review"/"Nothing to do"), Week Tasks' whole-page empty, and `renderProjClients`' "no clients yet" state (with a working "+ New client" CTA).
5. **Command palette / global search** — one component serves both asks (they're the same underlying need). `Cmd/Ctrl+K` anywhere (bound in `boot()`, 4491) or the visible "Search ⌘K" sidebar button (`#sidebarSearchBtn`) opens it. Fuzzy-ish substring search across active clients/projects/tasks, grouped results, arrow-key nav + Enter, click-outside/Escape to close. Task results reuse `jumpToProjTask` (1581) so selecting one navigates to the right view *and* opens the full task modal.
6. **Responsive tablet layout** — new `@media(min-width:761px) and (max-width:1080px)` block narrows the sidebar to 192px, tightens main padding, drops `.grid`'s card minmax to 250px, and forces `.home-cols`/calendar cells to be less cramped. Below 760px, the new search button collapses to icon-only alongside the existing icon-only nav row. Dense task tables still rely on `.task-grid{overflow-x:auto}` (confirmed it scrolls *within* the card, not the page) rather than hiding columns.
7. **Dark mode** — `:root[data-theme="dark"]` token override block (right after the light `:root` block, ~line 12). `resolveTheme()`/`applyTheme()`/`toggleTheme()` (549) run `applyTheme(resolveTheme())` as one of the very first statements in `<script>`, before `boot()`, to avoid a flash — resolution order is explicit `localStorage['rs_theme']` → OS `prefers-color-scheme` → light. Toggle button is the sun/moon icon in the sidebar's `.side-top` row (`#themeToggleBtn`), icon swap is pure CSS (`:root[data-theme="dark"] #themeToggleBtn .icon-sun{display:none}` etc). Also swapped every remaining hardcoded `background:#fff` in internal-app CSS to `var(--card)` (modal-card, popovers, inputs, filter-pill, member-pill, cmd-box, etc.) so the token layer actually reaches them — the one exception left alone is the public client-dashboard's "Copy client link" button (~line 4383, that page has its own client-accent-driven scheme, unrelated to this toggle).

---

## Constants

| Line | Name | Value/purpose |
|------|------|---------------|
| 531 | `SUPABASE_URL` | `https://glbfuurfebepqzvlkjwa.supabase.co` |
| 564 | `EMPTY_ICONS` | Lucide-style SVG strings keyed by name, used by `emptyStateHtml` |
| 623 | `PALETTE` | 8 default dot colours (client-distinguishing, unrelated to theme tokens) |
| 649 | `DEFAULT_TASK_STATUSES` | Fallback if migration-v13 not run |
| 659 | `TASK_COLUMNS` | Column key/label pairs — now includes `['animator','Animator']` |
| 1389 | `CURRENT_USER_NAME` | `'Ross Hall'` — links Home to team member |
| 2691 | `TASK_COL_DEFAULTS` | Default px widths per task column, incl. `animator:88` |
| 2787–2788 | `ASSIGN_ROLE_FIELD` / `ASSIGN_ROLE_CAN` | Maps `'designer'\|'reviewer'\|'animator'` → DB field / eligibility flag, used by inline assign popovers |
| 3830 | `APP_VERSION` | `'0.11.0'` — also update badge at ~line 527 |
| 3982 | `ANIM_DEFAULT_STEPS` | Pipeline step names seeded on first animation use |
| 3983 | `ANIM_CELL_STATUSES` | Status → {color, text, short} map |

---

## CSS design tokens (`:root`, top of `<style>`)

```css
--accent:#2383e2 / --accent-hover:#1a6fc4 / --accent-soft:#eaf3fd
--ink:#37352f / --ink-light:#9a988f
--paper:#fbfaf8 / --card:#ffffff / --sidebar-bg:#fbfaf7
--line:#eae7e1 / --line-soft:#f0eee9 / --muted:#8a877e
--radius:12px / --radius-sm:8px
--shadow-card / --shadow-pop / --shadow-sm
--fast:150ms / --dur:200ms / --ease
```
`:root[data-theme="dark"]{ ... }` immediately follows with dark equivalents (warm charcoal `--paper:#1e1d1b`, `--card:#282725`, brighter `--accent:#4a9eeb`, higher-alpha black shadows since the light theme's warm-grey shadows disappear against a dark surface). `--navy`/`--navy-soft` are still declared but unreferenced by any rule — legacy from before the accent-blue redesign.

Utility helper `mutedBg(hex)` (line 673) turns a status's stored hex into a `rgba(r,g,b,.14)` tint for muted-chip backgrounds — works in both themes since it's alpha-composited over whatever `--card`/`--track` is underneath.

---

## State object (line 536)

Unchanged shape from v0.10.0 except `taskCols` now defaults to include `'animator'`. Theme choice is deliberately **not** in `state` — it's read/written straight to `localStorage` (`rs_theme`) and applied via a `data-theme` attribute on `<html>`, since it doesn't affect any `render()` output, same pattern as sidebar-collapsed.

---

## Database tables

| Table | Migration | Purpose |
|-------|-----------|---------|
| `rs_clients` | v1 + v14 | Clients. Added: slug, dash_* branding fields |
| `rs_members` | v1, **v19** | Team members with billing weight. v19 adds `can_animate` |
| `rs_tasks` | v1 | Legacy retainer hour-log entries |
| `rs_client_settings_history` | v1 | Retainer terms history per client |
| `rs_projects` | v4 | Projects. Has: review_days (v12), anim_total_seconds (v16) |
| `rs_project_stages` | v4 | Stages per project with due_date |
| `rs_proj_tasks` | v4, **v19** | Tasks (retainer to-do + project stage tasks). v19 adds `assigned_animator_ids` |
| `rs_project_types` | v4 | Editable project types with stage templates |
| `rs_task_statuses` | v13 | Editable status names, colours, is_complete flag |
| `rs_stage_categories` | v14+v15 | Asset link categories per stage or project |
| `rs_stage_links` | v14 | Individual asset links within categories |
| `rs_anim_shots` | v16 | Shots per animation project |
| `rs_anim_steps` | v16 | Pipeline steps per animation project |
| `rs_anim_cells` | v16 | Status per (shot, step) pair |
| `rs_anim_feedback` | v17 | Timestamped feedback thread per cell |
| `rs_anim_deps` | v17 | Shot dependency chains |
| `rs_proj_task_entries` | v18 | Per-person time entries on retainer tasks |

**v19 migration file:** `outputs/v19_add_animator.sql` — not yet run against the live DB as of this session. Run it in the Supabase SQL editor whenever convenient; the app degrades gracefully until then (see "v0.11.0 additions" above).

---

## Page render functions

| Line | Function | Nav / projView |
|------|----------|----------------|
| 1367 | `render()` | Root dispatcher — nav highlight + `main.fade-in` trigger |
| 1425 | `renderHome()` | Home |
| 1475 | `renderDashboard()` | Retainers (card grid or calendar) |
| 1706 | `renderClientTasksView(c)` | Retainers → client to-do list (passes `{simpleRetainerPopup:true}` to `wireTaskRows`) |
| 1748 | `renderClientAllowanceView(c)` | Retainers → allowance history |
| 1860 | `renderProjects()` | All Projects dispatcher |
| 2381 | `renderProjClients()` | All Projects — card grid, illustrated empty state |
| 2276 | `renderClientListTable()` | All Projects → Client list table |
| 2438 | `renderProjClientProjects()` | All Projects → client's project cards |
| 3080 | `renderProjDetail()` | All Projects → project Kanban |
| 2923 | `renderTasksAhead()` | Week Tasks |
| 2171 | `renderMilestones()` | Milestones (week/month/year/Gantt) |
| 4573 | `renderAnimation()` | Animation Beta (tabs: Grid/Snapshot/Deps) |
| 3564 | `renderSettings()` | Settings — team table now has a Designer/Reviewer/Animator checkbox row |
| 3509 | `renderArchived()` | Archived clients/projects |
| 4304 | `bootPublicDashboard(slug, isAdmin)` | Public client dashboard entry point |
| 4340 | `renderPublicDashboard(...)` | Public dashboard renderer |

---

## UI primitives (line 754–1018)

| Line | Function | Purpose |
|------|----------|---------|
| 754 | `closeModal()` | Clears `#modalRoot` |
| 755 | `showModal(html, opts)` | `opts.wide` → `.modal-card.wide` (660px instead of 480px) |
| 839 | `openColumnDropdown(anchor)` | Column-visibility popover, driven by `TASK_COLUMNS` |
| 861 | `openCheckboxDropdown(anchor, items, isChecked, onToggle)` | Generic multi-select popover — reused by inline designer/reviewer/animator editing, and by client/type filters elsewhere |

---

## Quick Add

| Line | Function | Purpose |
|------|----------|---------|
| 1019 | `openQuickAddMenu(anchorBtn)` | 3-item popover from `#quickAddFab` |
| 1026 | `quickAddPickClient(kind)` | Searchable client-picker modal; `kind` is `'project'` or `'task'` |

---

## Command palette / global search

| Line | Function | Purpose |
|------|----------|---------|
| 1595 | `closeCommandPalette()` | Removes `#cmdPalette`, detaches its keydown listener |
| 1600 | `cmdPaletteHighlight()` | Applies `.active` to the current arrow-key selection, scrolls it into view |
| 1606 | `openCommandPalette()` | Builds the overlay, wires input/keyboard/click; results grouped Clients → Projects → Tasks |

---

## Task system

| Line | Function | Purpose |
|------|----------|---------|
| 2511 | `taskEntriesFor(taskId)` | Time entries for a task from state |
| 2513 | `taskEntriesHtml(taskId)` | Renders entries list HTML |
| 2532 | `openRetainerTaskTimeModal(taskId)` | Minimal time-tracker — only reached from the retainer page now (see `simpleRetainerPopup`) |
| 2613 | `openTaskEntryModal(taskId, entryId, onDone)` | Add/edit individual time entry |
| 2671 | `blankProjTask(ctx)` | New task defaults, incl. `assigned_animator_ids:[]` |
| 2685 | `stageStatus(stageId)` | `'Complete'` / `'Active'` / `'Pending'` |
| 2695 | `taskClient(t)` | **New** — shared client-lookup for a task (client_id or via project), replaces 3 duplicated inline copies |
| 2701 | `taskGridColumns()` | CSS grid-template-columns string, incl. animator |
| 2715 | `taskRowHtml(t)` | One grid row — inline-editable title/priority/designer/reviewer/animator/retainer |
| 2742 | `taskTableHtml(tasks, n, empty)` | Full grid with header; empty case renders `emptyStateHtml` with no header row at all |
| 2761 | `duplicateProjTask(id)` | Copy a task, incl. `assigned_animator_ids` |
| 2777 | `deleteProjTaskQuick(id)` | Delete with confirm |
| 2790 | `wireTaskRows(root, opts)` | All row-level click/inline-edit wiring — see "v0.11.0 additions" above |
| 2884 | `tasksAheadColumns()` | Column widths for Week Tasks (unchanged — no animator column there, kept compact) |
| 2962 | `openProjTaskModal(taskId, ctx)` | Full task edit modal — now sectioned (Team / Dates & hours), wide, has Animators pill selector |
| 3284 | `syncProjTaskRetainer(task)` | Syncs proj_task to rs_tasks for retainer tracking — also called from the new inline retainer toggle |

---

## Project system

| Line | Function | Purpose |
|------|----------|---------|
| 3178 | `projExtraFieldHtml(type, details)` | Type-specific fields (slides, pages, etc) |
| 3231 | `openProjectModal(projectId, clientId)` | Create/edit project |
| 3311 | `openProjectTypeModal(id?)` | Create/edit project type + stage template |

---

## Client dashboard

| Line | Function | Purpose |
|------|----------|---------|
| 1918 | `openStageCategoryModal(ctx, onDone)` | Add link category to stage or project |
| 1945 | `openStageLinkModal(catId, linkId, onDone)` | Add/edit asset link |
| 4304 | `bootPublicDashboard(slug, isAdmin)` | Data-fetch entry point for ?client= URLs |
| 4351 | `categoryBlockHtml(cat)` | Renders one category with links (read-only or admin) |

---

## Animation (Beta)

Unchanged this session apart from line-number drift. Main entries: `animProjects` (3993), `renderAnimation` (4009 stub / 4573 real), `openAnimShotModal` (4171), `openAnimCellModal` (4262 stub / 4930 real), `renderAnimGrid` (4579), `renderAnimSnapshot` (4758), `renderAnimDeps` (4851).

---

## Settings / dev tools

| Line | Function | Purpose |
|------|----------|---------|
| 3564 | `renderSettings()` | Settings page — team table has 3 role checkboxes now (Designer/Reviewer/Animator) |
| 3813 | `showSetup()` | First-run Supabase connection screen |
| 3832 | `handleVersionClick()` | Click version badge 8× to open dev panel |
| 3841 | `openDevSettingsModal()` | Developer settings (disconnect, import) |
| 3864 | `openImportModal()` | JSON import tool |
| 3879 | `runImport(data)` | Execute a JSON import payload |
| 1329 | `exportAllData()` | Full JSON backup download |
| 1347 | `exportTasksCsv()` | Tasks CSV export |

---

## Body markup structure

```
<div class="app-shell">
  <aside id="sidebar">
    <div class="side-top">
      <button id="brandBtn" class="brand">…</button>
      <button id="themeToggleBtn">sun/moon icon, CSS-only swap on [data-theme]</button>
      <button id="sidebarCollapseBtn">…</button>
    </div>
    <button id="sidebarSearchBtn">Search ⌘K — opens command palette</button>
    <nav id="nav">…7 buttons…</nav>
  </aside>
  <main id="main"></main>               — render() toggles .fade-in on this each view switch
</div>
<button id="quickAddFab" class="fab">…</button>
<div id="modalRoot"></div>              — showModal()/closeModal()
<div class="toast" id="toast"></div>
<div id="versionBadge" class="version-badge">v0.11.0</div>
<!-- #cmdPalette is created/destroyed dynamically by openCommandPalette/closeCommandPalette, not static markup -->
```

---

## CSS classes quick reference (new/changed this session)

| Class | Purpose |
|-------|---------|
| `.modal-card.wide` | 660px modal variant, opt-in via `showModal(html, {wide:true})` |
| `.modal-section-label` | Small-caps divider label grouping modal form fields |
| `.inline-editable` | Hover affordance for click-to-edit table cells (designer/reviewer/animator/retainer) |
| `.inline-rename-input` | The input that replaces a task title span during inline rename |
| `select.priority-select` | Native `<select>` styled as a priority pill, mirrors `.status-select` |
| `.empty-state` / `.empty-state-icon` / `.empty-state-title` / `.empty-state-sub` | Illustrated empty state, built by `emptyStateHtml()` |
| `.sidebar-search-btn` | Visible "Search ⌘K" trigger in the sidebar |
| `.cmd-backdrop` / `.cmd-box` / `.cmd-input-wrap` / `.cmd-results` / `.cmd-item` / `.cmd-group-label` / `.cmd-sub` / `.cmd-tag` | Command palette overlay |
| `:root[data-theme="dark"]` | Dark theme token overrides |
| `#themeToggleBtn .icon-sun` / `.icon-moon` | CSS-only (no JS) icon swap based on `[data-theme]` |

---

## Sessions tips

- **Find a function:** `grep -n "^function functionName" index.html`
- **Version bump:** update `APP_VERSION` constant (~line 3830) and the badge text in the HTML body (~line 527) together
- **Verify before shipping:** `node --check app.js` catches syntax errors; brace/paren counts should both be 0
- **Note:** the file on disk is `index.html`, not `rs-retainer-tracker.html` as CLAUDE.md's editing-rules section names it — same structure, different filename.
- **Browser-pane click quirk:** in this dev environment, `computer` tool clicks and cross-call DOM state (e.g. a focused inline-rename `<input>`) sometimes don't survive between separate tool calls — confirmed harmless (a preview-pane quirk, not an app bug). Prefer doing multi-step interactions inside a single `javascript_exec` call when verifying anything involving focus/blur.
- **Pending manual step:** `outputs/v19_add_animator.sql` needs to be run in Supabase before Animator assignments persist server-side.
