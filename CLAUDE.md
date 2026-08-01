# RS Retainer Tracker — Claude Code Context

## Project overview
Single-file HTML app: `index.html` (~5,010 lines) — note: this CLAUDE.md previously referred to it as `rs-retainer-tracker.html`; the file on disk is `index.html`, same structure described below.
Function index: `rs-function-index.md` — **always read this before grepping the main file**
Current version: **v0.11.0**

Backend: Supabase (PostgreSQL)
- URL: `https://glbfuurfebepqzvlkjwa.supabase.co`
- Anon key: `sb_publishable_q6qhoNXd38nRDKhhXxBf7w_DD38UMaj`
- RLS is fully open (anon key can read/write everything — known risk, flagged)
- ⚠️ **Pending manual step:** `outputs/v19_add_animator.sql` has not been run yet — Animator assignments won't persist server-side until it is. See "v0.11.0 additions" below.

Stack: Vanilla JS · No framework · No build step · Supabase JS v2 via CDN · Inter font · Notion + Linear + Arc-inspired visual system with a dark-mode variant — see Design tokens section. v0.10.0 shipped the visual redesign + collapsible sidebar + Quick Add; v0.11.0 shipped command palette/global search, dark mode, tablet responsive, inline editing, better empty states, clearer modal layouts, and an Animator role. Deferred: reorderable dashboard widgets, project-page restructuring (progress/milestones/links/activity grouped together).

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
   - `APP_VERSION` constant (~line 3830): `const APP_VERSION = 'X.X.X';`
   - Badge in HTML body (~line 527): `<div id="versionBadge" ...>vX.X.X</div>`
6. **Previous versions are tracked via git**, not a manual outputs copy — commit when the user asks, and the prior `index.html` stays recoverable from git history/log.

---

## Architecture

```
HTML structure:
  <style>        CSS (~450 lines) — design tokens incl. dark theme, all component styles
  <body>         .app-shell (collapsible #sidebar + #main) + #quickAddFab + #modalRoot + #toast (#cmdPalette is created dynamically, not static markup)
  <script>       All app logic (~4,550 lines)

Nav views (state.view):
  'home'         → renderHome()
  'projects'     → renderProjects() → dispatches on state.projView
  'dashboard'    → renderDashboard()  [Retainers]
  'animation'    → renderAnimation()  [Animation Beta]
  'tasksahead'   → renderTasksAhead() [Week Tasks]
  'milestones'   → renderMilestones()
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
| `rs_anim_feedback` | v17 | Timestamped feedback thread per cell |
| `rs_anim_deps` | v17 | Shot dependency chains |
| `rs_proj_task_entries` | v18 | Per-person time entries on retainer tasks |

---

## Key constants and state

```js
CURRENT_USER_NAME = 'Ross Hall'   // ~line 1389 — links Home to team member
APP_VERSION = '0.11.0'            // ~line 3830
PALETTE = [8 hex colours]         // ~line 623 — dot/avatar colours
DEFAULT_TASK_STATUSES = [...]      // ~line 649 — fallback if v13 migration not run
ANIM_DEFAULT_STEPS = [...]         // ~line 3982 — seeded on first animation use
ANIM_CELL_STATUSES = {...}         // ~line 3983 — status → {color, text, short}

state = {
  view, projView, projClientId, projProjectId,
  clients[], members[], tasks[], projects[], stages[], projTasks[],
  projectTypes[], taskStatuses[], stageCategories[], stageLinks[],
  animShots[], animSteps[], animCells[], animFeedback[], animDeps[],
  animProjectId, animTab,           // animation page state
  projTaskEntries[],                // per-person time entries (v18)
  taskCols,                         // Set of visible column keys — now defaults to include 'animator'
  taskColWidths:{}, tasksAheadColWidths:{},  // drag-resized widths (session-only)
  clientListGroup, clientListSort,  // 'client'|'type', 'alpha'|'started'
  retainerView,                     // 'dashboard'|'calendar'
  homeCols,                         // Set of visible Home columns
  milestoneViewMode, milestoneAnchor, milestoneShowProjects, milestoneShowRetainer,
  milestoneHidden, milestoneTypeHidden,
  dashSearch, dashSort, calMonth, clientId, calHidden,
}
```
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

Full technical detail (exact line numbers, which functions touch what) is in `rs-function-index.md`'s "v0.11.0 — this session's additions" section.

Prior versions recoverable via git history: v0.10.0 (no dark mode/command palette/inline editing) is the commit right before this session; v0.9.0 (sharp 3px corners) and v0.8.2 (original top nav, Rubik, 14px radius) are further back — `5664307` or earlier for the pre-redesign baseline.

---

## Team members (for context)
Ross Hall, Louis Rush, Yaatzil Ceballos, Ranjani Tavargeri, Myrto Tsouma, Nafisa Ahmed, Yumna, Michal

---

## Known issues
- `renderAnimation` is defined twice (lines ~4009 and ~4573). Second definition wins — first is a stub leftover. Safe but should be cleaned up. (`openAnimCellModal` has the same duplicate pattern at ~4262 and ~4930.)
- Column widths (taskColWidths) reset on page refresh — session-only, no persistence yet.
- RLS is fully open — flagged as risk now that client-facing dashboard URLs are live.
- `outputs/v19_add_animator.sql` has not been run against the live Supabase DB yet — Animator picks in the UI don't persist until it is (app degrades gracefully in the meantime, treating every member as animator-eligible).

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
