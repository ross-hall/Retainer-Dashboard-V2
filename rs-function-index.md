# RS Retainer Tracker — Function Index
**Current version: v0.10.0** | **File: index.html** | **Lines: ~4,719**

Use this as a starting point each session to avoid grepping the whole file.
Update the version and any changed line numbers when making edits.

---

## Quick orientation

```
HTML structure:
  <style>        CSS (~390 lines) — design tokens, all component styles
  <body>         .app-shell (collapsible #sidebar + #main) + #quickAddFab + modal root + toast
  <script>       Everything else (~4,320 lines)
    Line 449     Constants
    Line 453     State initialisation
    Line 467     Utility helpers
    Line 604     loadAll()
    Line 644     Modal / UI primitives
    Line 908     Quick Add (openQuickAddMenu, quickAddPickClient)
    Line 943     Client modals (new/edit)
    Line 1255    render() dispatcher
    Line 1313    Page render functions (Home, Retainers, Projects, Milestones, Settings)
    Line 2306    Task time-entry helpers
    Line 2466    Task / stage helpers
    Line 2571    wireTaskRows()
    Line 2648    Week Tasks page
    Line 2687    openProjTaskModal()
    Line 2798    renderProjDetail()
    Line 3547    Developer settings / import
    Line 3661    initColumnResize()
    Line 3699    Animation constants
    Line 3710    Animation helpers
    Line 3726    renderAnimation() — DUPLICATE (see note below)
    Line 4021    bootPublicDashboard()
    Line 4057    renderPublicDashboard()
    Line 4208    boot()
    Line 4239    Animation feature functions (feedback, deps, tabs, grid, snapshot)
    Line 4285    renderAnimation() — REAL one (overrides line 3726)
```

⚠️ **Known issue:** `renderAnimation` is defined twice (lines 3726 and 4285). The second definition (4285) wins at runtime — the first is a leftover stub. Safe to ignore but worth cleaning up. (`openAnimCellModal` has the same duplicate pattern at 3979 and 4642.)

---

## Redesign status (Notion + Linear + Arc direction)

**v0.9.0** shipped phase 1: CSS tokens (canvas/ink/line/radius) + top-header-nav → left sidebar.

**v0.10.0 (this session)** — visual system pass + core nav upgrade:
- ✅ Palette: warm off-white canvas (`--paper:#fbfaf8`), soft blue accent (`--accent:#2383e2`, `--accent-hover`, `--accent-soft`) replacing navy/navy-soft as the interactive color everywhere (buttons, links, focus rings, selected states, meter fill, calendar "today", breadcrumbs, badges). `--navy`/`--navy-soft` tokens still exist in `:root` but are no longer referenced by any rule — kept only in case something external expects them.
- ✅ Radius: `--radius` is now `12px` (was `3px` in v0.9.0), plus `--radius-sm:8px` for inputs/small controls.
- ✅ Shadows: `--shadow-sm`, `--shadow-card`, `--shadow-pop` tokens; cards got `box-shadow:var(--shadow-card)` + hover lift (`translateY(-1px)` + bigger shadow) instead of the old accent-border-on-hover treatment.
- ✅ Buttons (`.btn`): true pill (`border-radius:999px`), `--accent`→`--accent-hover` on hover, `:active` scale-down, `:focus-visible` ring. `.btn.ghost` hover now fills `var(--track)` instead of just changing border color.
- ✅ Status badges: `.status-pill`, `.status-select`, and the per-status classes (`.status-todo` etc.) are muted tint chips now, not solid vivid fills. The two dynamic call sites (task grid `status-select` at ~2503/2687, and the client-tasks `status-pill` in `renderClientTasksView`) use a new `mutedBg(hex)` helper (next to `contrastText`, ~line 563) to compute a `rgba(r,g,b,.14)` tint background from the status's stored hex, with the full-saturation hex used as the text color instead of white.
- ✅ Tables: lighter dividers (`--line-soft`), more row padding, `th`/`.task-grid-header` are `position:sticky;top:0` (sticky within whatever scroll container they're in — there's no fixed top bar anymore so this works against the page scroll).
- ✅ Progress bars: `.meter .fill` uses `--accent`; `.mini-progress .fill` stays `--green` (semantic "done" color, deliberately not switched to accent).
- ✅ Micro-animations: `--fast:150ms` / `--dur:200ms` / `--ease` tokens. Popovers (`.menu-popover`, `.col-dropdown`, `.mini-datepicker`, `.color-popover`) fade+translate in via `@keyframes popIn`. Modals fade+scale via `@keyframes modalIn` on `.modal-card` and `backdropIn` on `.modal-backdrop`. `render()` (line 1255) toggles a `main.fade-in` class (`main.classList.remove/add` with a forced reflow via `void main.offsetWidth`) so every view switch gets a small fade — this is the "page transition."
- ✅ Icons: kebab "more options" buttons (5 call sites — client cards ×2, project card, task grid ×2) now render an inline `more-horizontal` SVG instead of the `⋮` character. Nav icons (from v0.9.0) are already Lucide-style line icons.
- ✅ Collapsible sidebar: `#sidebarCollapseBtn` (in the new `.side-top` row alongside the brand button) toggles `#sidebar.collapsed` — width drops to 60px, labels hide, nav buttons center. State persists via `store` (`localStorage` key `rs_sidebar_collapsed`), restored in `boot()` (~line 4208). Each nav button now has a `title` attribute so collapsed icon-only mode still shows a native tooltip.
- ✅ Quick Add: `#quickAddFab` (bottom-right circular button, reuses/restyles the previously-dead `.fab` CSS class) opens `openQuickAddMenu()` (~line 908), a 3-item popover (New client / New project / New task). New client goes straight to `openNewClientModal()`. New project/task go through `quickAddPickClient(kind)` (~line 915) — a small searchable client-picker modal — then call the existing `openProjectModal(null, clientId)` / `openProjTaskModal(null, {clientId})`, since neither of those modals has its own client-selection UI.
- ⬜ Not done (explicitly out of scope for this session, per user's chosen phasing): command palette (Cmd/Ctrl+K), global search, reorderable dashboard widgets, dark mode, tablet-specific responsive layout beyond the existing 760px/800px breakpoints, inline editing, illustrated empty states, project-page restructuring (progress/milestones/links/activity grouped together).

---

## Constants (line 449–555)

| Line | Name | Value/purpose |
|------|------|---------------|
| 449 | `SUPABASE_URL` | `https://glbfuurfebepqzvlkjwa.supabase.co` |
| 513 | `PALETTE` | 8 default dot colours (unchanged by redesign — client-distinguishing colors, not theme tokens) |
| 533 | `PROJECT_TYPES` | `['Website','Branding','Animations','Deck projects']` |
| 539 | `DEFAULT_TASK_STATUSES` | Fallback if migration-v13 not run |
| 549 | `TASK_COLUMNS` | Column key/label pairs for task tables |
| 1277 | `CURRENT_USER_NAME` | `'Ross Hall'` — links Home page to team member |
| 2486 | `TASK_COL_DEFAULTS` | Default px widths per task column |
| 2487 | `TASKSAHEAD_COL_DEFAULTS` | Default px widths for Week Tasks columns |
| 3547 | `APP_VERSION` | `'0.10.0'` — also update badge at line ~445 |
| 3699 | `ANIM_DEFAULT_STEPS` | Pipeline step names seeded on first use |
| 3700 | `ANIM_CELL_STATUSES` | Status → {color, text, short} map |

---

## CSS design tokens (`:root`, top of `<style>`)

```css
--accent:#2383e2        /* primary interactive color — buttons, links, focus, selected states */
--accent-hover:#1a6fc4
--accent-soft:#eaf3fd    /* tint background for hover/selected chips */
--ink:#37352f
--ink-light:#9a988f      /* lighter secondary text, used in table headers */
--paper:#fbfaf8          /* warm off-white canvas */
--card:#ffffff
--line:#eae7e1
--line-soft:#f0eee9      /* lighter divider for table rows */
--muted:#8a877e
--radius:12px            /* was 3px pre-v0.10.0, 14px before that */
--radius-sm:8px
--shadow-card, --shadow-pop, --shadow-sm   /* neutral warm-grey shadows, no color tint */
--fast:150ms / --dur:200ms / --ease        /* animation timing */
--navy / --navy-soft     /* still defined, unreferenced by any rule — legacy */
```

Utility helper: `mutedBg(hex)` (~line 563, next to `contrastText`) — turns a status's stored hex into a `rgba(r,g,b,.14)` tint for muted-chip backgrounds.

---

## State object (line 454)

```js
state = {
  view, projView, projClientId, projProjectId,
  clients[], members[], tasks[], projects[], stages[], projTasks[], projectTypes[],
  taskStatuses[], stageCategories[], stageLinks[],
  animShots[], animSteps[], animCells[], animFeedback[], animDeps[],
  animProjectId, animTab, projTaskEntries[],
  taskCols, taskColWidths:{}, tasksAheadColWidths:{},
  clientListGroup, clientListSort, retainerView, homeCols,
  milestoneViewMode, milestoneAnchor, milestoneShowProjects, milestoneShowRetainer,
  milestoneHidden, milestoneTypeHidden,
  dashSearch, dashSort, calMonth, clientId, calHidden,
}
```
(Sidebar-collapsed state is NOT in `state` — it's read/written directly via `store`/`localStorage` and a DOM class toggle, since it doesn't affect any render() output.)

---

## Database tables

| Table | Migration | Purpose |
|-------|-----------|---------|
| `rs_clients` | v1 + v14 | Clients. Added: slug, dash_* branding fields |
| `rs_members` | v1 | Team members with billing weight |
| `rs_tasks` | v1 | Legacy retainer hour-log entries |
| `rs_client_settings_history` | v1 | Retainer terms history per client |
| `rs_projects` | v4 | Projects. Added: review_days (v12), anim_total_seconds (v16) |
| `rs_project_stages` | v4 | Stages per project with due_date |
| `rs_proj_tasks` | v4 | Tasks (retainer to-do + project stage tasks) |
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

---

## Utility helpers (line 467–643)

| Line | Function | Purpose |
|------|----------|---------|
| 467 | `toast(msg)` | Show brief notification |
| 468 | `esc(s)` | HTML-escape a string |
| 469 | `slugify(name)` | name → url-safe slug |
| 470 | `uniqueSlug(name)` | slug that doesn't collide with existing clients |
| 485 | `fmtH(h)` | Format hours: `2.5` → `"2h 30m"` |
| 486 | `iso(date)` | Date → `"YYYY-MM-DD"` |
| 487 | `fmtDate(date)` | Date → `"12 Jul"` |
| 488 | `fmtDateNatural(str)` | Date string → `"Today"` / `"Tomorrow"` / `"12 Jul"` |
| 500 | `fmtDateY(date)` | Date → `"12 Jul 2026"` |
| 501 | `ordinal(n)` | `1` → `"1st"`, `2` → `"2nd"` |
| 504 | `cycleFor(renewalDay, date?)` | Returns `{start, end, next}` for a retainer cycle |
| 515 | `clientColor(id)` | Deterministic colour from client id |
| 516 | `colorFor(client)` | Prefers `dash_accent_color` → `color` → deterministic |
| 550 | `taskStatusList()` | Sorted array of status records from state |
| 551 | `taskStatusNames()` | Just the name strings |
| 552 | `statusRecord(name)` | Full record for a status name |
| 553 | `statusColor(name)` | Hex colour for a status |
| 554 | `statusIcon(name)` | `'✓'` or `'○'` |
| 555 | `isCompleteStatus(name)` | Boolean — drives all "done" logic |
| 556 | `contrastText(hex)` | Black/white text colour (still used for status DOTS, not pills anymore) |
| 563 | `mutedBg(hex)` | **New in v0.10.0** — `rgba(r,g,b,.14)` tint for muted status-pill/select backgrounds |
| 570 | `initials(name)` | `"Ross Hall"` → `"RH"` |
| 571–573 | `avatarHtml`, `avatarWithName`, `avatarGroupHtml` | Avatar rendering |
| 589 | `clientUsage(client, tasks?)` | Returns `{used, pct, cyc, tasks}` for retainer meter |
| 604 | `loadAll()` | Fetches all 13 tables, populates state, calls render() |

---

## UI primitives (line 644–906)

| Line | Function | Purpose |
|------|----------|---------|
| 644 | `closeModal()` | Clears `#modalRoot` |
| 645 | `showModal(html)` | Shows modal card (now animates in via `modalIn`/`backdropIn`) |
| 652 | `closeDatePicker()` | Closes the mini calendar popover |
| 656 | `openMiniDatePicker(anchor, value, onSelect)` | Floating calendar |
| 699 | `dateFieldHtml(id, value, placeholder)` | Renders a date button field |
| 703 | `wireDateField(id, placeholder)` | Attaches date picker to a field |
| 728 | `openColumnDropdown(anchor)` | Column-visibility toggle popover |
| 774 | `openColorPicker(anchor, hex, onSelect)` | Colour swatch popover |
| 807 | `colorCircleHtml(id, color)` | Colour circle button + hidden input |
| 810 | `wireColorCircle(id)` | Attaches picker to circle button |
| 819 | `wireColorCircleCustom(id, onSelect)` | Like above but with callback |
| 831 | `openMenuPopover(anchor, items)` | Floating context menu (text-only items — no icon slot) |
| 848 | `openTaskModal(id)` | Legacy retainer task modal (rs_tasks) |
| 899, 906 | `refreshCurrentView`, `refreshProjectView` | Re-fetch + re-render |

---

## Quick Add (new in v0.10.0)

| Line | Function | Purpose |
|------|----------|---------|
| 908 | `openQuickAddMenu(anchorBtn)` | Opens the 3-item popover from `#quickAddFab` |
| 915 | `quickAddPickClient(kind)` | Searchable client-picker modal; `kind` is `'project'` or `'task'`; on pick, closes itself and opens `openProjectModal(null, clientId)` or `openProjTaskModal(null, {clientId})` |

`#quickAddFab` itself is wired in `boot()` (~line 4208): shown via `style.display='flex'` (default `none` in CSS so it doesn't flash on the public dashboard before `boot()` gates it), click opens `openQuickAddMenu`.

---

## Page render functions

| Line | Function | Nav / projView |
|------|----------|----------------|
| 1255 | `render()` | Root dispatcher — updates nav highlight + triggers `main.fade-in` |
| 1313 | `renderHome()` | Home |
| 1363 | `renderDashboard()` | Retainers (card grid or calendar) |
| 1502 | `renderClientTasksView(c)` | Retainers → client to-do list |
| 1544 | `renderClientAllowanceView(c)` | Retainers → allowance history |
| 1656 | `renderProjects()` | All Projects dispatcher |
| 2177 | `renderProjClients()` | All Projects — card grid |
| 2072 | `renderClientListTable()` | All Projects → Client list table |
| 2233 | `renderProjClientProjects()` | All Projects → client's project cards |
| 2798 | `renderProjDetail()` | All Projects → project Kanban |
| 2648 | `renderTasksAhead()` | Week Tasks |
| 1967 | `renderMilestones()` | Milestones (week/month/year/Gantt) |
| 4285 | `renderAnimation()` | Animation Beta (tabs: Grid/Snapshot/Deps) |
| 3282 | `renderSettings()` | Settings |
| 3227 | `renderArchived()` | Archived clients/projects |
| 4021 | `bootPublicDashboard(slug, isAdmin)` | Public client dashboard entry point |
| 4057 | `renderPublicDashboard(...)` | Public dashboard renderer |

---

## Client modals

| Line | Function | Purpose |
|------|----------|---------|
| 943 | `openNewClientModal()` | Create client (retainer or project) |
| 997 | `openClientEditModal(id)` | Edit client — includes dashboard branding + slug |
| 1481 | `dashboardLinkButtonHtml(c)` | "View dashboard ↗" button (opens admin mode) |
| 1486 | `clientRetainerHeaderHtml(c, mode)` | Header for retainer client pages |

---

## Task system

| Line | Function | Purpose |
|------|----------|---------|
| 2306 | `taskEntriesFor(taskId)` | Time entries for a task from state |
| 2308 | `taskEntriesHtml(taskId)` | Renders entries list HTML |
| 2327 | `openRetainerTaskTimeModal(taskId)` | Minimal time-tracker (click retainer task) |
| 2408 | `openTaskEntryModal(taskId, entryId, onDone)` | Add/edit individual time entry |
| 2466 | `blankProjTask(ctx)` | New task defaults — auto-ticks retainer for retainer clients; `ctx.clientId` (camelCase) is what Quick Add's task flow passes |
| 2480 | `stageStatus(stageId)` | `'Complete'` / `'Active'` / `'Pending'` |
| 2490 | `taskGridColumns()` | CSS grid-template-columns string for task table |
| 2503 | `taskRowHtml(t)` | One grid row for a task — status-select now uses `mutedBg()` |
| 2527 | `taskTableHtml(tasks, n, empty)` | Full grid with header |
| 2544 | `duplicateProjTask(id)` | Copy a task |
| 2561 | `deleteProjTaskQuick(id)` | Delete with confirm |
| 2571 | `wireTaskRows(root)` | Attach click/status/menu handlers to task rows |
| 2609 | `tasksAheadColumns()` | Column widths for Week Tasks |
| 2687 | `openProjTaskModal(taskId, ctx)` | Full task edit modal — `ctx.clientId` lets Quick Add open this with no project |
| 3002 | `syncProjTaskRetainer(task)` | Syncs proj_task to rs_tasks for retainer tracking |

---

## Project system

| Line | Function | Purpose |
|------|----------|---------|
| 2896 | `projExtraFieldHtml(type, details)` | Type-specific fields (slides, pages, etc) |
| 2904 | `projExtraFieldValue(type, details)` | Read-out of those fields |
| 2920 | `addBusinessDays(date, n)` | Skip weekends |
| 2930 | `reviewWindowLabel(dueDate, reviewDays)` | "Review opens X" label |
| 2937 | `projectDetailsSummary(p)` | One-line scope summary for client list |
| 2949 | `openProjectModal(clientId, projectId?)` | Create/edit project — Quick Add calls this with `clientId` pre-filled and no `projectId` |
| 3029 | `openProjectTypeModal(id?)` | Create/edit project type + stage template |

---

## Client dashboard

| Line | Function | Purpose |
|------|----------|---------|
| 1714 | `openStageCategoryModal(ctx, onDone)` | Add link category to stage or project |
| 1741 | `openStageLinkModal(catId, linkId, onDone)` | Add/edit asset link |
| 4021 | `bootPublicDashboard(slug, isAdmin)` | Data-fetch entry point for ?client= URLs |
| 4068 | `categoryBlockHtml(cat)` | Renders one category with links (read-only or admin) |

---

## Animation (Beta)

| Line | Function | Purpose |
|------|----------|---------|
| 3710 | `animProjects()` | Filters projects by animation type |
| 3714+ | `animShotsFor`, `animStepsFor`, `animCell`, `animCellStatus`, `animShotProgress` | Data accessors |
| 3888 | `openAnimShotModal(projectId, shotId?)` | Add/edit shot |
| 3931 | `openAnimStepModal(projectId)` | Add pipeline step |
| 3956 | `openAnimBudgetModal(p)` | Set total contracted seconds |
| 3979 | `openAnimCellModal(shotId, stepId)` | Edit cell — DUPLICATE, see 4642 |
| 4239 | `animFeedbackFor(shotId, stepId?)` | Feedback entries for a cell or shot |
| 4244–4245 | `animFeedbackCount`, `animAllFeedback` | Counts / all feedback for a shot |
| 4253 | `animIsBlocked(shotId)` | True if any blocker not yet Approved |
| 4285 | `renderAnimation()` | Main renderer — dispatches to Grid/Snapshot/Deps |
| 4291 | `renderAnimGrid(p, shots, steps)` | The shot × step grid |
| 4470 | `renderAnimSnapshot()` | "What changed" view |
| 4563 | `renderAnimDeps()` | Dependency management view |
| 4642 | `openAnimCellModal(shotId, stepId)` | DUPLICATE of 3979 — second definition wins at runtime |

---

## Settings / dev tools

| Line | Function | Purpose |
|------|----------|---------|
| 3282 | `renderSettings()` | Settings page (clients, team, types, statuses, data) |
| 3530 | `showSetup()` | First-run Supabase connection screen |
| 3549 | `handleVersionClick()` | Click version badge 8× to open dev panel |
| 3558 | `openDevSettingsModal()` | Developer settings (disconnect, import) |
| 3581 | `openImportModal()` | JSON import tool |
| 3596 | `runImport(data)` | Execute a JSON import payload |
| 1217 | `exportAllData()` | Full JSON backup download |
| 1235 | `exportTasksCsv()` | Tasks CSV export |

---

## Body markup structure

```
<div class="app-shell">
  <aside id="sidebar">                  — display:none until boot(), then 'flex'; .collapsed toggles icon-only rail
    <div class="side-top">
      <button id="brandBtn" class="brand">…</button>
      <button id="sidebarCollapseBtn">…</button>   — new in v0.10.0
    </div>
    <nav id="nav">…7 buttons, each has title=Label now…</nav>
  </aside>
  <main id="main"></main>               — render() toggles .fade-in on this each view switch
</div>
<button id="quickAddFab" class="fab">…</button>     — new in v0.10.0, display:none until boot()
<div id="modalRoot"></div>
<div class="toast" id="toast"></div>
<div id="versionBadge" class="version-badge">v0.10.0</div>
```

---

## CSS classes quick reference

| Class | Purpose |
|-------|---------|
| `.app-shell` | Flex wrapper around `#sidebar` + `#main` |
| `#sidebar` | Left nav column; `.collapsed` shrinks to 60px icon rail |
| `.collapse-btn` | Sidebar collapse/expand toggle, new in v0.10.0 |
| `#quickAddFab` / `.fab` | Bottom-right circular Quick Add trigger, new in v0.10.0 (CSS class existed since earlier but was unused until now) |
| `.card` | White card, 12px radius, `--shadow-card`, hover lift |
| `.btn` | Accent-blue pill button, hover/active/focus-visible states |
| `.btn.ghost` | Outlined pill, hover fills `--track` |
| `.btn.danger` | Red text-only, hover fills `--red-bg` |
| `.status-pill` / `.status-select` | Muted tint chip (bg via `mutedBg()`, text = full-saturation status color) |
| `.qa-client-row` | Quick Add's client-picker list row, new in v0.10.0 |
| `.task-grid-header` / `th` | `position:sticky;top:0` for in-place sticky headers |
| `.menu-popover`, `.col-dropdown`, `.mini-datepicker`, `.color-popover` | All animate in via `popIn` keyframe |
| `.modal-backdrop` / `.modal-card` | Animate in via `backdropIn`/`modalIn` |
| `.avatar` | Circular initials avatar |
| `.priority-pill` | Muted tint (was already close to this pre-redesign) |
| `.type-badge`, `.retainer-badge`, `.project-badge`, `.label-chip` | All muted tint chips using `--accent-soft`/`--green-bg`/`--amber-bg` |

---

## Nav views and routing

```
state.view values:
  'home'        → renderHome()
  'projects'    → renderProjects() → dispatches on state.projView:
                    'clients'            → renderProjClients()
                    'clientList'         → renderClientListTable()
                    'clientProjects'     → renderProjClientProjects()
                    'project'            → renderProjDetail()
                    'retainerTasks'      → renderClientTasksView(c)
                    'retainerAllowance'  → renderClientAllowanceView(c)
  'dashboard'   → renderDashboard() [Retainers]
  'animation'   → renderAnimation()
  'milestones'  → renderMilestones()
  'settings'    → renderSettings()
  'archived'    → renderArchived()

Public dashboard:
  ?client=slug          → read-only client view
  ?client=slug&admin=1  → admin view (add/edit links, copy client URL)

Sidebar order (top to bottom): Home · All Projects · Retainers · Week Tasks · Animation (Beta) · Milestones · ⚙ Settings
```

---

## Sessions tips

- **Find a function:** `grep -n "^function functionName" index.html`
- **Find a string:** `grep -n "text to find" index.html`
- **After any edit:** re-view the file around changed lines before a second edit — str_replace fails if context has shifted
- **Version bump:** update `APP_VERSION` constant (~line 3547) and the badge text in the HTML body (~line 445) together
- **Verify before shipping:** `node --check app.js` catches syntax errors; brace/paren counts should both be 0
- **Note:** the file on disk is `index.html`, not `rs-retainer-tracker.html` as CLAUDE.md's editing-rules section names it — same structure, different filename.
- **Browser-pane click quirk:** in this dev environment, `computer` tool clicks on nav/sidebar buttons sometimes don't register even when coordinates look correct (confirmed harmless — a preview-pane input-routing quirk, not an app bug). If a click doesn't seem to do anything, verify with `document.getElementById(...).click()` via the JS tool before assuming something broke.
