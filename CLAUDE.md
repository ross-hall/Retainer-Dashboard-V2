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
CURRENT_USER_NAME = 'Ross Hall'   // ~line 1277 — links Home to team member
APP_VERSION = '0.10.0'            // ~line 3547
PALETTE = [8 hex colours]         // ~line 513 — dot/avatar colours
DEFAULT_TASK_STATUSES = [...]      // ~line 539 — fallback if v13 migration not run
ANIM_DEFAULT_STEPS = [...]         // ~line 3699 — seeded on first animation use
ANIM_CELL_STATUSES = {...}         // ~line 3700 — status → {color, text, short}

state = {
  view, projView, projClientId, projProjectId,
  clients[], members[], tasks[], projects[], stages[], projTasks[],
  projectTypes[], taskStatuses[], stageCategories[], stageLinks[],
  animShots[], animSteps[], animCells[], animFeedback[], animDeps[],
  animProjectId, animTab,           // animation page state
  projTaskEntries[],                // per-person time entries (v18)
  taskCols,                         // Set of visible column keys
  taskColWidths:{}, tasksAheadColWidths:{},  // drag-resized widths (session-only)
  clientListGroup, clientListSort,  // 'client'|'type', 'alpha'|'started'
  retainerView,                     // 'dashboard'|'calendar'
  homeCols,                         // Set of visible Home columns
  milestoneViewMode, milestoneAnchor, milestoneShowProjects, milestoneShowRetainer,
  milestoneHidden, milestoneTypeHidden,
  dashSearch, dashSort, calMonth, clientId, calHidden,
}
```

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

`mutedBg(hex)` JS helper (next to `contrastText`, ~line 563) converts a status's stored hex into a `rgba(r,g,b,.14)` tint — this is what makes `.status-pill`/`.status-select` render as muted chips instead of solid vivid fills, since those two call sites set `background` via inline style (which overrides the CSS class).

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

**Explicitly deferred** (per user's chosen phasing — "visual polish + core nav" only, not the full wishlist): command palette (Cmd/Ctrl+K), global search, reorderable dashboard widgets, dark mode, tablet-specific responsive pass, inline editing, illustrated empty states, project-page restructuring. Full list and rationale in `rs-function-index.md`'s "Redesign status" section.

Prior versions recoverable via git history: v0.9.0 (sharp 3px corners, top-header-nav already replaced by sidebar) is the commit right before this session; v0.8.2 (original top nav, Rubik, 14px radius) is commit `5664307` or earlier.

---

## Team members (for context)
Ross Hall, Louis Rush, Yaatzil Ceballos, Ranjani Tavargeri, Myrto Tsouma, Nafisa Ahmed, Yumna, Michal

---

## Known issues
- `renderAnimation` is defined twice (lines ~3726 and ~4285). Second definition wins — first is a stub leftover. Safe but should be cleaned up. (`openAnimCellModal` has the same duplicate pattern at ~3979 and ~4642.)
- Column widths (taskColWidths) reset on page refresh — session-only, no persistence yet.
- RLS is fully open — flagged as risk now that client-facing dashboard URLs are live.

---

## Migration files (all in outputs/)
- v1–v12: core tables
- v13: rs_task_statuses
- v14: client dashboard fields + rs_stage_categories + rs_stage_links
- v15: stage_categories.stage_id made nullable, project_id added
- v16: animation tables (rs_anim_shots, rs_anim_steps, rs_anim_cells)
- v17: rs_anim_feedback + rs_anim_deps
- v18: rs_proj_task_entries
