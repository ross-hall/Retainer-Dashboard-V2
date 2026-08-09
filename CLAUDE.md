# RS Retainer Tracker — Claude Code Context

## Project overview
Single-file HTML app: `index.html` (~4,810 lines) — note: this CLAUDE.md previously referred to it as `rs-retainer-tracker.html`; the file on disk is `index.html`, same structure described below.
Function index: `rs-function-index.md` — **always read this before grepping the main file**
Current version: **v0.25.0**

Backend: Supabase (PostgreSQL)
- URL: `https://glbfuurfebepqzvlkjwa.supabase.co`
- Anon key: `sb_publishable_q6qhoNXd38nRDKhhXxBf7w_DD38UMaj`
- RLS is fully open (anon key can read/write everything — known risk, flagged). **Caveat learned the hard way:** Supabase now enables RLS by default on tables created via the SQL editor, so every new migration must explicitly `alter table ... disable row level security;` to match — v21 initially shipped without this and silently blocked the anon key until a follow-up fix.
- ⚠️ **Pending manual steps:** `outputs/v19_add_animator.sql`, `outputs/v20_anim_cell_statuses.sql`, `outputs/v22_internal_task_multi_assignee.sql`, and `outputs/v23_qa_checklist.sql` have not been run yet — Animator assignments won't persist server-side, pipeline cell statuses aren't editable, the Internal Tasks assignee picker won't let you select more than one person, and the new Checklists feature (per-project, own page) degrades gracefully (toast "run migration v23") until each is run. `outputs/v21_internal_tasks.sql` **has been run** — Internal Tasks and Departments are live. Note: `outputs/v23_qa_checklist.sql` was rewritten mid-session before ever being run — it originally added a `qa_checklist` column to `rs_project_types` + a flat `rs_project_qa_items` table, but was replaced outright with the current `rs_checklists`/`rs_checklist_items` design once the user clarified they wanted standalone, multi-per-project checklists rather than one type-templated list. If you see references to `qa_checklist`/`rs_project_qa_items` anywhere stale, they're leftover from that abandoned draft.

Stack: Vanilla JS · No framework · No build step · Supabase JS v2 via CDN · Inter font · Notion + Linear + Arc-inspired visual system with a dark-mode variant. **The standalone "Retainers" nav page/dashboard is gone as of v0.13.0** — its content (allowance meter, remaining hours, renewal date) now lives directly on each retainer client's card on the All Projects page, and the client detail page merges what used to be two separate pages (to-do list / allowance history) into one page with a "To-do list" / "Monthly allowance" tab toggle. The old "Calendar view" for ad-hoc hour-logging (not tied to a task) was removed with it — hours are logged through the task modal (tick "counts toward retainer" + recorded hours) instead. See "What shipped in v0.13.0" below.

---

## Editing rules — follow these every time

1. **Read `rs-function-index.md` first.** It has line numbers for every function. Use it to navigate before touching the file.
2. **Always use `str_replace` for edits.** Never rewrite the whole file. Target the smallest possible change.
3. **Re-view lines around any change before a second edit.** A successful str_replace invalidates earlier view output — stale context causes missed replacements.
4. **After every JS edit, extract and check syntax:**
   ```bash
   python3 -c "
   import re
   content = open('index.html').read()
   m = re.search(r'<script>(.*?)</script>', content, re.S)
   open('app.js','w').write(m.group(1))
   "
   node --check app.js && echo "OK"
   python3 -c "
   js = open('app.js').read()
   print('braces', js.count('{')-js.count('}'))
   print('parens', js.count('(')-js.count(')'))
   "
   ```
   Both counts must be 0. Never ship if node --check fails.
5. **Bump the version on every session** — two places must match:
   - `APP_VERSION` constant (~line 3632): `const APP_VERSION = 'X.X.X';`
   - Badge in HTML body (~line 532): `<div id="versionBadge" ...>vX.X.X</div>`
6. **Previous versions are tracked via git**, not a manual outputs copy — commit when the user asks, and the prior `index.html` stays recoverable from git history/log.

---

## Architecture

```
HTML structure:
  <style>        CSS (~450 lines) — design tokens incl. dark theme, all component styles
  <body>         .app-shell (collapsible #sidebar + #main) + #quickAddFab + #modalRoot + #toast (#cmdPalette is created dynamically, not static markup)
  <script>       All app logic (~4,550 lines)

Nav views (state.view) — 'dashboard' (Retainers) is gone as of v0.13.0:
  'home'         → renderHome()
  'projects'     → renderProjects() → dispatches on state.projView
                     'retainerTasks' → renderClientTasksView(c) — now internally tabs Tasks/Allowance via state.retainerTab
                     'checklists'    → renderProjectChecklists(c) — one project's list of checklists [v0.25.0]
                     'checklist'     → renderChecklistDetail() — a single checklist's items, keyed by state.checklistId [v0.24.0]
  'animation'    → renderAnimation()  [Animation Beta]
  'tasksahead'   → renderTasksAhead() [Week Tasks]
  'milestones'   → renderMilestones()
  'internal'     → renderInternalTasks()  [Internal Tasks — new in v0.20.0]
  'checklists'   → renderChecklistsHub()  [global Checklists nav item — new in v0.25.0; same name as the projView above but a different state field, no collision]
  'settings'     → renderSettings()
  'archived'     → renderArchived()

Public dashboard (no internal nav):
  ?client=slug        → read-only client view
  ?client=slug&admin=1 → admin view (add/edit links)
```

---

## Database tables

| Table | Migration | Purpose |
|-------|-----------|---------|
| `rs_clients` | v1 + v14 | Clients. Has: slug, dash_accent_color, dash_logo_text, dash_greeting, dash_logo_url, dash_contact_email |
| `rs_members` | v1, **v19** | Team members with billing weight. v19 adds `can_animate` (not yet run) |
| `rs_tasks` | v1 | Legacy retainer hour-log entries |
| `rs_client_settings_history` | v1 | Retainer terms history per client |
| `rs_projects` | v4 | Projects. Has: review_days, anim_total_seconds |
| `rs_project_stages` | v4 | Stages per project with due_date |
| `rs_proj_tasks` | v4, **v19** | Tasks (retainer to-do + project stage tasks). v19 adds `assigned_animator_ids` (not yet run) |
| `rs_project_types` | v4 | Editable project types with stage templates |
| `rs_task_statuses` | v13 | Editable status names, colours, is_complete flag |
| `rs_stage_categories` | v14+v15 | Asset link categories per stage or project |
| `rs_stage_links` | v14 | Individual asset links within categories |
| `rs_anim_shots` | v16 | Shots per animation project |
| `rs_anim_steps` | v16 | Pipeline steps per animation project |
| `rs_anim_cells` | v16 | Status per (shot, step) pair |
| `rs_anim_feedback` | v17, **v20** | Timestamped feedback thread per cell. v20 adds `resolved` (not yet run) |
| `rs_anim_deps` | v17 | Shot dependency chains — **unused as of v0.16.0**, the Dependencies feature was removed from the app; table/rows left untouched in Supabase, nothing reads or writes it anymore |
| `rs_proj_task_entries` | v18 | Per-person time entries on retainer tasks |
| `rs_anim_cell_statuses` | **v20** | Editable pipeline cell statuses (name/color/short/behavior/position) — **not yet run**; until it is, `animStatusList()` falls back to the hardcoded `DEFAULT_ANIM_CELL_STATUSES` (the same 7 statuses the app always had) |
| `rs_departments` | **v21** | Editable label list for Internal Tasks (name/color/position) — same pattern as `rs_task_statuses`. **Run** |
| `rs_internal_tasks` | v21, **v22** | Non-client tasks: title, priority, due_date, department_id → `rs_departments`, is_done, position. v22 adds `assignee_ids uuid[]` (multi-select) alongside the original singular `assignee_id` (now unused by the app but left in place, non-destructive) — **v22 not yet run** |
| `rs_checklists` | **v23** | Named checklists, many per project, each with its own page (`renderChecklistDetail`). Created on demand via "+ New checklist" on the project page, not tied to project type. **Not yet run** |
| `rs_checklist_items` | **v23** | Items within a checklist: category (optional grouping label), label, detail (optional helper text), is_done, position. Optionally seeded from a hardcoded starter template (`WEBSITE_CHECKLIST_TEMPLATE`) at checklist-creation time; independent after that. **Not yet run** |

---

## Key constants and state

```js
CURRENT_USER_NAME = 'Ross Hall'   // ~line 1326 — links Home to team member
APP_VERSION = '0.13.0'            // ~line 3632
PALETTE = [8 hex colours]         // ~line 636 — dot/avatar colours
DEFAULT_TASK_STATUSES = [...]      // ~line 669 — fallback if v13 migration not run
ANIM_DEFAULT_STEPS = [...]         // ~line 3784 — seeded on first animation use
ANIM_CELL_STATUSES = {...}         // ~line 3785 — status → {color, text, short}

state = {
  view, projView, projClientId, projProjectId,
  retainerTab,                      // 'tasks'|'allowance' — new in v0.13.0, tab within the retainer client detail page
  clients[], members[], tasks[],    // tasks[] is still the legacy rs_tasks read side that clientUsage() sums — kept even though the manual quick-log UI that wrote to it is gone; task-based retainer sync still writes to it
  projects[], stages[], projTasks[],
  projectTypes[], taskStatuses[], stageCategories[], stageLinks[],
  animShots[], animSteps[], animCells[], animFeedback[], animDeps[],
  animProjectId, animTab,           // animation page state
  projTaskEntries[],                // per-person time entries (v18)
  taskCols,                         // Set of visible column keys — now defaults to include 'animator'
  taskColWidths:{}, tasksAheadColWidths:{},  // drag-resized widths (session-only)
  clientListGroup, clientListSort,  // 'client'|'type', 'alpha'|'started'
  homeCols,                         // Set of visible Home columns
  milestoneViewMode, milestoneAnchor, milestoneShowProjects, milestoneShowRetainer,
  milestoneHidden, milestoneTypeHidden,
}
```
Removed in v0.13.0 (were only used by the deleted Retainers dashboard/calendar): `retainerView`, `dashSearch`, `dashSort`, `calMonth`, `calHidden`.
Theme (light/dark) is deliberately **not** in `state` — it's a `data-theme` attribute on `<html>` plus a `localStorage['rs_theme']` value, same pattern as sidebar-collapsed, since it doesn't affect any `render()` output.

---

## Design tokens (current, as of v0.10.0 — Notion + Linear + Arc direction)

```css
--accent: #2383e2        /* primary interactive color — was navy/navy-soft pre-v0.10.0 */
--accent-hover: #1a6fc4
--accent-soft: #eaf3fd    /* tint bg for hover/selected states, muted-chip backgrounds */
--ink: #37352f
--ink-light: #9a988f      /* new — lighter secondary text (table headers) */
--paper: #fbfaf8          /* was #f7f7f5 — warmer off-white */
--card: #ffffff
--line: #eae7e1           /* was #e3e3e0 */
--line-soft: #f0eee9      /* new — lighter table-row dividers */
--muted: #8a877e          /* was #7b7a77 */
--amber: #c98a2b / --red: #c4554d / --green: #448361   /* unchanged from v0.9.0 */
--track: #f1f0ec
--radius: 12px            /* was 3px in v0.9.0, 14px before that — Notion/Linear card radius, not sharp corners */
--radius-sm: 8px          /* new — inputs, small controls */
--shadow-card / --shadow-pop / --shadow-sm   /* new — neutral warm-grey shadows (no color tint), replacing the old navy-tinted rgba(4,14,107,…) shadows */
--fast: 150ms / --dur: 200ms / --ease        /* new — animation timing tokens */
--navy / --navy-soft      /* still declared in :root but no longer referenced anywhere — legacy, safe to leave or remove */
Font: Inter (unchanged from v0.9.0)
```

`mutedBg(hex)` JS helper (next to `contrastText`, ~line 673) converts a status's stored hex into a `rgba(r,g,b,.14)` tint — this is what makes `.status-pill`/`.status-select` render as muted chips instead of solid vivid fills, since those two call sites set `background` via inline style (which overrides the CSS class).

**Dark mode (new in v0.11.0):** `:root[data-theme="dark"]{...}` immediately follows the light `:root` block with dark equivalents — warm charcoal canvas (`--paper:#1e1d1b`), `--card:#282725`, brighter `--accent:#4a9eeb`, higher-alpha black shadows (the light theme's warm-grey shadows vanish against a dark surface, so dark mode uses plain black at higher opacity instead). `resolveTheme()` / `applyTheme()` / `toggleTheme()` (~line 549) run `applyTheme(resolveTheme())` as one of the first statements in `<script>`, before `boot()`, to avoid a flash-of-light-theme. Resolution order: explicit `localStorage['rs_theme']` → OS `prefers-color-scheme` → light. Toggle is the sun/moon icon button in the sidebar (`#themeToggleBtn`); the icon swap itself is pure CSS keyed off `[data-theme]`, no JS needed. Every remaining hardcoded `background:#fff` in internal-app CSS got swapped to `var(--card)` so the token layer actually reaches modals/popovers/inputs/pills — the one intentional holdout is the public client-dashboard's "Copy client link" button, which has its own client-accent-driven scheme unrelated to this toggle.

**What shipped in v0.10.0** (on top of v0.9.0's tokens + sidebar):
- Soft blue accent replacing navy/navy-soft everywhere (buttons, links, focus rings, selected states, meter fill, badges)
- 12px radius across cards/modals/popovers/inputs (reversing v0.9.0's 3px "sharp corners" experiment — this direction won)
- Pill-shaped buttons with proper hover/active/focus states
- Muted status/priority/type badges (tint bg + saturated text, not solid fills)
- Sticky table headers, lighter row dividers, more row padding
- Popover/modal open animations (fade + slight scale/translate, 150–200ms)
- Lucide-style icon swap for kebab "more options" menus (was `⋮` text)
- **Collapsible sidebar** — toggle button, state persisted to `localStorage` (`rs_sidebar_collapsed`)
- **Global Quick Add** — `#quickAddFab` bottom-right button → New client/project/task, with a searchable client-picker for project/task since those modals need a client context

**What shipped in v0.11.0** (the rest of the deferred wishlist, plus new asks):
- **Command palette / global search** — `Cmd/Ctrl+K` or the sidebar's "Search ⌘K" button; one component serves both needs since they're the same underlying feature. Fuzzy-substring search across clients/projects/tasks, grouped results, arrow-key nav.
- **Dark mode** — see above.
- **Responsive tablet layout** — new breakpoint at 761–1080px (narrower sidebar, tighter grids); dense task tables rely on horizontal scroll within the card rather than hiding columns.
- **Inline editing** — status (already existed), priority, designer/reviewer/animator (popover multi-select), retainer toggle, and task-title rename, all directly in table rows — no modal required for quick edits.
- **Better empty states** — small circular icon illustration + title + subtitle + optional CTA (`emptyStateHtml()`), applied to Home, Week Tasks, project/client task lists, and the "no clients yet" first-run state.
- **Clearer modal layouts** — `showModal(html, {wide:true})` for a 660px variant, plus `.modal-section-label` dividers grouping the task and client-edit modals into named sections instead of one flat field dump.
- **Animator role** — third assignment category alongside Designer/Reviewer, mirroring that pattern exactly (own DB column, Settings checkbox, pill selector, avatar column). Needs `outputs/v19_add_animator.sql` run before it persists — see the pending-step note at the top of this file.

**What shipped in v0.13.0** (retainer/All Projects rejig — the standalone Retainers page is gone):
- **Retainer client cards on All Projects** (`clientCardHtml`) now show the allowance meter, a colored remaining/over-limit status line, and the renewal cycle dates — this is the content that used to live only on the separate Retainers dashboard grid.
- **Client detail page merged**: `renderClientTasksView` + `renderClientAllowanceView` are now one function with a shared header (`clientRetainerHeaderHtml`). The `'retainerAllowance'` `projView` no longer exists — everything routes through `'retainerTasks'`; every navigation site that jumps to a client's retainer view now also resets `state.retainerTab='tasks'` so switching clients doesn't strand you on the Allowance tab.
- **Retainers nav item removed**, along with `renderDashboard()` (the card-grid overview + flagged-clients/pending-hours banners + search/sort), `renderCalendar()` (the ad-hoc hour-logging calendar), and the legacy `openQuickLogModal()`/`openTaskModal()` modals that only that calendar used. This was a deliberate, user-confirmed deletion, not an oversight — retainer hours are logged via per-person time entries (`rs_proj_task_entries`), see v0.15.0 note below for how that superseded the older single-field/sync approach this bullet originally described.
- `render()`'s nav-active-state logic simplified (no more `effectiveNavView` special-casing for the old `'retainerAllowance'` → `'dashboard'` mapping, since both are gone).

**What shipped in v0.14.0–v0.16.0** (client palette, retainer-hours unification, animation page polish):
- **Client colour palette**: new `CLIENT_PALETTE` (15 lighter Notion-tag-style colours) replaces the old dark `PALETTE` for client dot/accent colours specifically (`clientColor()`, the client colour picker). `PALETTE` itself is unchanged and still used for members/task-status defaults.
- **Sidebar nav grouped**: Home/All Projects/Animation, a spacing gap, then Week Tasks/Milestones (`.nav-group-start` class marks the second group's first item).
- **Home page "Retainer hours to fill" card**: shows retainer tasks assigned to you as designer, filtered to the client's current billing cycle (or current+previous via a "Show last 2 months" toggle, `state.homeHoursExpanded`). Hours are logged inline via a 30-minute-increment stepper (`hoursStepperHtml`/`wireHoursSteppers`) that writes directly to *your own* `rs_proj_task_entries` row — never hides a task just because hours were logged, since people revisit tasks to add more time.
- **Hours-tracking unified onto `rs_proj_task_entries`** (v0.15.0): the old single `recorded_hours` field + `syncProjTaskRetainer()` (which mirrored hours into `rs_tasks` split evenly across assigned designers) is **deleted**. `clientUsage()` and `loadRetainerAllowanceBody()` now both sum legacy `rs_tasks` rows (old ad-hoc entries, pre-dating per-task entries) **plus** `rs_proj_task_entries`, gated on `pt.counts_toward_retainer` for the entries side. The "Tracked ✓/⚠" signal (`taskRowHtml`, the Monthly Allowance table) is now `counts_toward_retainer && taskEntriesFor(id).length>0`, not the old `retainer_task_ids` mirror-row check. `recorded_hours` still exists and is still used, but only for **non-retainer** client tasks (the modal only shows that field when `!client.is_retainer`).
- **Retainer client detail header simplified**: `clientRetainerHeaderHtml` now combines the name/badge/action-buttons card, the renewal line ("Renews in X days (date)") + allowance meter, and the Task list/Monthly allowance tab toggle into one card (no more separate `retainerTabsHtml`/`wireRetainerTabs` — that logic is inline in `clientRetainerHeaderHtml`/`wireClientRetainerHeader` now). To-do/Completed task groups on the Task list tab lost their outer border box.
- **Animation page**: Dependencies tab/feature removed entirely (`renderAnimDeps`, `animDepsFor`/`animIsBlocked`/`animBlockedBy`/`animBlocks`, the "blocked" flag chip and per-shot badge, and the `rs_anim_deps` load query are all gone — the table itself is untouched in Supabase, just unused). "Grid" tab relabelled "Pipeline" (internal `data-animtab`/`state.animTab` value is still `'grid'`, only the button text changed). New **Timeline** tab (`renderAnimTimeline`) lays shots out by cumulative screen-time instead of by row — shots play back-to-back in their existing pipeline `position` order, each a bar sized by `duration_seconds`, coloured by one collapsed per-shot status (`animShotTimelineStatus`: Overdue > Needs retakes > Awaiting client > Approved > Not started > In progress). All three tabs (Pipeline/Timeline/Today's snapshot) now share one `animViewToggleHtml(tab)` helper instead of three separately-maintained copies of the button row.

**What shipped in v0.17.0** (editable pipeline statuses + Feedback tab):
- **Pipeline cell statuses are now editable** (Settings > "Pipeline cell statuses", mirrors the existing Task Statuses editor exactly — add/remove/reorder/recolour/rename). The old hardcoded `ANIM_CELL_STATUSES` object is gone; `rs_anim_cell_statuses` is the new source of truth via `animStatusList()`/`animStatusRecord()`/`animStatusBehavior()`, with `DEFAULT_ANIM_CELL_STATUSES` as the pre-migration fallback (same 7 statuses as before). Every place that used to check a hardcoded status name (progress-%, flag chips, overdue check, unassigned check) now checks the status's `behavior` field instead (`'wip'|'waiting'|'retake'|'done'|'omitted'|'none'`) so custom/renamed statuses keep the app's logic working. Cell background is still the status colour, but the text colour is now computed live via `contrastText()` instead of being a stored field.
- **New Feedback tab** (`renderAnimFeedbackTab`) lists every outstanding (unresolved) feedback note across the project's shots, click-through to the cell modal, with a "Resolved" checkbox per note — resolved notes drop into a collapsed section below rather than disappearing. Needs `rs_anim_feedback.resolved` (v20 migration); the cell modal's feedback log also grew the same per-note "Resolved" checkbox.
- Both the dead `renderAnimation`/`openAnimCellModal` stubs from v0.16.0's known-issues note are unaffected — still there, still never called.

**What shipped in v0.18.0–v0.20.0** (bespoke inline-edit popovers, column persistence/reorder, Internal Tasks page):
- **Status/Priority are now a bespoke coloured-pill popover** (`openPillPopover`/`openStatusPopover`/`openPriorityPopover`), not a native `<select>` — every option renders as its own colour-coded pill so you see the name and colour together, Notion/Linear style. Reused inline in every task row (`statusPillBtnHtml`/`priorityPillBtnHtml`) **and** inside the task edit modal (`statusFieldHtml`/`priorityFieldHtml` + `wireStatusField`/`wirePriorityField`, a hidden input carries the value like `dateFieldHtml` does for dates); Priority sits top-right of the modal header next to the title.
- **Row/cell hover reworked**: `.task-row:hover` is a flat `--row-hover` tint (not the old barely-visible blue), `.inline-editable`/`.pill-btn` hover is a `var(--ink-light)` outline ring. Whole-row clicks do nothing everywhere — only the specific inline-editable cell responds — via `wireTaskRows(root)`, the single shared wiring function for every task-row table in the app.
- **Every task-row cell is inline-editable**: title (rename), status, priority, designer/reviewer/animator (popover multi-select), hours (`openInlineHoursEdit` for project tasks, the per-person time modal for retainer tasks), due date (`dueDateBtnHtml`/`openMiniDatePicker`, same pill-button styling as the existing "work date" field), retainer toggle.
- **Task grid columns are now ordered + persisted**: `TASK_COLUMN_DEFS` + `state.taskColOrder` (defaults to `DEFAULT_TASK_COL_ORDER`) drive `taskGridColumns()`/`taskRowHtml()`/`taskTableHtml()`, which all take a `showRetainer` flag so **project (non-retainer) clients no longer show a Retainer column**. The Columns popover (`openColumnDropdown`) got drag handles (⠿) to reorder columns live; both visibility (`state.taskCols`) and order persist to `localStorage` (`rs_task_cols`/`rs_task_col_order`/`rs_home_cols`) via `saveTaskCols()`/`saveTaskColOrder()`/`saveHomeCols()`.
- **Home page client names are clickable** (`data-clientlink`, wired in `wireTaskRows`) — jumps straight to that client's retainer/project page, with an accent-underline hover state (`.home-client-link`).
- **Team member names are editable after creation** (Settings > Team members, `data-membername` input) — since every downstream display (`avatarHtml`, assignment pickers, etc.) looks the member up fresh from `state.members` by id, a rename cascades everywhere automatically on the next `loadAll()`. Caveat: `CURRENT_USER_NAME` (Home page personalization) is still a hardcoded name constant, not an id — renaming "Ross Hall" specifically breaks that link until the constant is updated too.
- **New Internal Tasks page** (`renderInternalTasks`, nav item between Milestones and Settings) for non-client work — columns: Task (rename inline), Assignee (multi-select member popover, `openAssigneePopover` — see v0.22.0 note below), Priority, Due date, Department, plus a Done checkbox and drag-to-reorder. **Department is a new editable label list** (`rs_departments`, Settings > "Departments", mirrors the Task Statuses editor exactly) — you can also add a new department directly from the department popover on the Internal Tasks page itself (`openDepartmentPopover`'s "+ Add department" option) without going to Settings. Needs `outputs/v21_internal_tasks.sql` (**now run**) — see pending-step note at the top of this file.

**What shipped in v0.20.1–v0.22.0** (CSV import, consistent people-picker, Internal Tasks toolbar, multi-assignee):
- **CSV import** added alongside the existing JSON import. Lives in two places: the hidden dev "Import data" tool (Settings > click the version badge 8x) for clients/members/project-tasks, and a dedicated one on the Internal Tasks page behind its three-dot "More options" menu (`openInternalImportModal`/`runInternalImport`) for bulk-loading internal tasks. Both share `parseCsv()` (a small hand-rolled RFC4180-ish parser — no library) and a JSON/CSV toggle + file-upload control; the Internal Tasks importer auto-creates a department by name if it doesn't already exist, matching the inline picker's "+ Add department" behaviour.
- **One consistent people-picker everywhere**: `openMultiPillPopover` (new) is the multi-select sibling of `openPillPopover` — same avatar + coloured-pill rows and checkmarks, but stays open across clicks so multiple people can be toggled in one go. The designer/reviewer/animator assignment popover on every task row (`data-assigninline` in `wireTaskRows`) was switched from the old plain-checkbox `openCheckboxDropdown` to this, so it now looks and behaves exactly like the Internal Tasks assignee picker.
- **Internal Tasks gained a toolbar**: Sort (`state.internalSort`: manual/due/priority/title/assignee/department), Group by (`state.internalGroupBy`: none/department/assignee/priority/status — each renders as its own labelled section, and a task with multiple assignees appears once per assignee's group), and Columns (`state.internalCols`, visibility-only, no reorder). All three persist to `localStorage` (`rs_internal_sort`/`rs_internal_group`/`rs_internal_cols`). Manual drag-reordering only wires up when sort is Manual and grouping is None, since row order isn't meaningfully positional otherwise.
- **Internal tasks can now have multiple assignees** (`rs_internal_tasks.assignee_ids uuid[]`, migration v22) — the original singular `assignee_id` column is left in place but unused by the app. `openAssigneePopover` now uses `openMultiPillPopover`; the row cell renders `avatarGroupHtml(t.assignee_ids)` (same avatar-stack component used for designer/reviewer on project tasks) instead of a single name. The CSV/JSON importer's `assignee`/`assignee_names` field accepts multiple semicolon-separated names (or a JSON array). Needs `outputs/v22_internal_task_multi_assignee.sql` — see pending-step note at the top of this file; degrades gracefully (toasts "run migration v22") until then.
- **Fixed the Deck-projects "Number of slides" field not appearing**: `projExtraFieldHtml`/`projExtraFieldValue`/`projectDetailsSummary`/the project-detail type line all matched the project type name with an exact `===` against the hardcoded seed string `'Deck projects'`. Project type names are user-editable (Settings > Project types) and this project's actual type had been renamed to just `'Deck'`, so the field silently never rendered. Fixed via a new `isDeckType(type)` helper (`.toLowerCase().includes('deck')`) used at all four call sites — a lesson that any per-type-name branching needs to tolerate renames, not just match the v1 seed name.

**What shipped in v0.24.0–v0.25.0** (Checklists — own page, multiple per project, global hub):
- **Checklists are a standalone, multi-per-project entity, each with its own page** — not a single embedded card. Items support an optional `category` (section grouping label) and `detail` (muted helper subtext), rendered as grouped sections when present — richer than the flat label-only items used elsewhere (Internal Tasks), needed to faithfully carry over categorized starter templates.
- **Starter templates at creation time**: `openNewChecklistModal` offers "Blank" or a named template (currently just `WEBSITE_CHECKLIST_TEMPLATE`, in `CHECKLIST_TEMPLATES`) — picking one bulk-inserts that template's items into the new checklist; after creation the checklist is fully independent (editing it never touches the template, and there's no live link back). `WEBSITE_CHECKLIST_TEMPLATE` (50 items across 8 categories: Copy & Content, Links & Navigation, Visual & Brand, Responsive & Cross-Browser, Forms & Interactions, Performance & Technical, Accessibility Basics, Client Handover) was mined from the team's separate standalone QA checklist tool (a different Supabase project) — its `templates` table was empty, so the tool's actual hardcoded `DEFAULT_TEMPLATE` fallback (read from that tool's own `index.html` source) was the real in-use content, transcribed here verbatim.
- **Three-tier navigation** (v0.25.0, after the user saw the v0.24.0 bottom-of-page panel and asked for it to move): a **"✓ Checklists" button** in the project header next to the Miro buttons (`renderProjDetail`, `#checklistsBtn`, shows a count badge) opens **`renderProjectChecklists()`** — a full page (not a card) listing that project's checklists with "+ New checklist", breadcrumbed `All Projects > Client > Project > Checklists`. Clicking one of those goes to `renderChecklistDetail()` (`state.projView==='checklist'`), now breadcrumbed one level deeper through the Checklists list page. On top of that, a **global "Checklists" nav item** in the sidebar (`state.view==='checklists'` → `renderChecklistsHub()`) shows a card per project that has ≥1 checklist (project name, client, each checklist listed with a done-count), reading straight off `state.checklists`/`state.checklistItems` — clicking a checklist name jumps straight into its detail page, skipping the intermediate list. All three views share the exact same underlying data, so they're always in sync by construction, not by any explicit refresh logic.
- **Miro button text shortened**: `miroButtonsHtml()` now reads "Miro (Ext) ↗" / "Miro (Int) ↗" instead of spelling out "external"/"internal" — the settings-form field labels (`miroFieldsHtml`) were deliberately left spelled out, since those are form labels, not buttons.
- Internal-only by design — `rs_checklists`/`rs_checklist_items` are never fetched on the public client-dashboard path (`bootPublicDashboard`/`renderPublicDashboard` run their own separate fetch sequence and don't go through `loadAll()`), so no extra guarding was needed to keep checklists off the client-facing page. Needs `outputs/v23_qa_checklist.sql` — see pending-step note at the top of this file; degrades gracefully (toasts "run migration v23") until then.

Full technical detail for v0.11.0 (exact line numbers, which functions touch what) is in `rs-function-index.md` — note line numbers there predate the v0.13.0 restructure and have drifted further since; grep for function names rather than trusting them.

Prior versions recoverable via git history: v0.12.x/v0.11.x (Retainers page still present) are recent commits before this session; v0.10.0 (no dark mode/command palette/inline editing) and v0.9.0 (sharp 3px corners) are further back; v0.8.2 (original top nav, Rubik, 14px radius) is `5664307` or earlier for the pre-redesign baseline.

---

## Team members (for context)
Ross Hall, Louis Rush, Yaatzil Ceballos, Ranjani Tavargeri, Myrto Tsouma, Nafisa Ahmed, Yumna, Michal

---

## Known issues
- `renderAnimation` is defined twice — an early, simpler stub, and the real one further down that wins (function-declaration hoisting means the later one always shadows the first). Same duplicate pattern for `openAnimCellModal`. Both dead stubs are still in the file, deliberately left alone during the v0.16.0 animation-page pass (Dependencies removal, Timeline tab) to keep that change scoped — safe (never called) but still worth deleting in a future cleanup pass. `_origRenderAnimation`/`_origOpenAnimCellModal` (captured right before each second definition) are dead too, for the same hoisting reason: by the time that line executes, hoisting has already made the identifier point at the *second* definition, so each capture just references itself.
- Column widths (taskColWidths) reset on page refresh — session-only, no persistence yet.
- RLS is fully open — flagged as risk now that client-facing dashboard URLs are live.
- `outputs/v19_add_animator.sql` has not been run against the live Supabase DB yet — Animator picks in the UI don't persist until it is (app degrades gracefully in the meantime, treating every member as animator-eligible).
- `outputs/v20_anim_cell_statuses.sql` has not been run yet — the new Settings > "Pipeline cell statuses" editor will show "run migration v20, then reload" until it is; the app degrades gracefully in the meantime by falling back to `DEFAULT_ANIM_CELL_STATUSES` (the original hardcoded 7 statuses), and the Feedback tab's "Resolved" checkbox will toast an error until `rs_anim_feedback.resolved` exists.
- `outputs/v22_internal_task_multi_assignee.sql` has not been run yet — the Internal Tasks assignee picker degrades gracefully (toasts "run migration v22") until `rs_internal_tasks.assignee_ids` exists.
- `outputs/v23_qa_checklist.sql` has not been run yet — the "Checklists" section on project pages, "+ New checklist", and each checklist's own page all degrade gracefully (toasts "run migration v23") until `rs_checklists`/`rs_checklist_items` exist.

---

## Migration files (all in outputs/)
- v1–v12: core tables
- v13: rs_task_statuses
- v14: client dashboard fields + rs_stage_categories + rs_stage_links
- v15: stage_categories.stage_id made nullable, project_id added
- v16: animation tables (rs_anim_shots, rs_anim_steps, rs_anim_cells)
- v17: rs_anim_feedback + rs_anim_deps
- v18: rs_proj_task_entries
- v19: rs_members.can_animate + rs_proj_tasks.assigned_animator_ids — **not yet run**, do this in the Supabase SQL editor when convenient
- v20: rs_anim_cell_statuses (editable pipeline cell statuses) + rs_anim_feedback.resolved — **not yet run**, do this in the Supabase SQL editor when convenient
- v21: rs_departments + rs_internal_tasks (Internal Tasks page) — **run** (needed a follow-up RLS fix, see the RLS caveat above)
- v22: rs_internal_tasks.assignee_ids uuid[] (multiple assignees per internal task) — **not yet run**, do this in the Supabase SQL editor when convenient
- v23: rs_checklists + rs_checklist_items (standalone multi-per-project Checklists feature, each with its own page) — **not yet run**, do this in the Supabase SQL editor when convenient
