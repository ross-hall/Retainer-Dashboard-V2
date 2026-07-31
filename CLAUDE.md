# RS Retainer Tracker — Claude Code Context

## Project overview
Single-file HTML app: `index.html` (~4,720 lines) — note: this CLAUDE.md previously referred to it as `rs-retainer-tracker.html`; the file on disk is `index.html`, same structure described below.
Function index: `rs-function-index.md` — **always read this before grepping the main file**
Current version: **v0.10.0**

Backend: Supabase (PostgreSQL)
- URL: `https://glbfuurfebepqzvlkjwa.supabase.co`
- Anon key: `sb_publishable_q6qhoNXd38nRDKhhXxBf7w_DD38UMaj`
- RLS is fully open (anon key can read/write everything — known risk, flagged)

Stack: Vanilla JS · No framework · No build step · Supabase JS v2 via CDN · Inter font · Notion + Linear + Arc-inspired visual system (warm off-white canvas, soft blue accent, 12px radius, muted status chips) — see Design tokens section. Collapsible sidebar + global Quick Add shipped in v0.10.0; command palette, global search, dashboard widget reordering, dark mode, and tablet-specific responsive work are intentionally deferred (see rs-function-index.md's "Redesign status" section for the full checklist).

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
   - `APP_VERSION` constant (~line 3547): `const APP_VERSION = 'X.X.X';`
   - Badge in HTML body (~line 445): `<div id="versionBadge" ...>vX.X.X</div>`
6. **Previous versions are tracked via git**, not a manual outputs copy — commit when the user asks, and the prior `index.html` stays recoverable from git history/log.

---

## Architecture

```
HTML structure:
  <style>        CSS (~350 lines) — design tokens, all component styles
  <body>         .app-shell (left #sidebar nav + #main) + #modalRoot + #toast
  <script>       All app logic (~4,270 lines)

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
| `rs_members` | v1 | Team members with billing weight |
| `rs_tasks` | v1 | Legacy retainer hour-log entries |
| `rs_client_settings_history` | v1 | Retainer terms history per client |
| `rs_projects` | v4 | Projects. Has: review_days, anim_total_seconds |
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

## Key constants and state

```js
CURRENT_USER_NAME = 'Ross Hall'   // ~line 1188 — links Home to team member
APP_VERSION = '0.9.0'             // ~line 3458
PALETTE = [8 hex colours]         // ~line 466 — dot/avatar colours
DEFAULT_TASK_STATUSES = [...]      // ~line 492 — fallback if v13 migration not run
ANIM_DEFAULT_STEPS = [...]         // ~line 3610 — seeded on first animation use
ANIM_CELL_STATUSES = {...}         // ~line 3611 — status → {color, text, short}

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

## Design tokens (current, as of v0.9.0 — Notion-style redesign, phase 1 done)

```css
--navy: #040e6b        /* kept as sole accent — retainer meter fill, active nav state, focus rings */
--navy-soft: #2a37a8
--ink: #37352f          /* was #16183a */
--paper: #f7f7f5        /* was #f6f6f3 — Notion canvas */
--card: #ffffff
--line: #e3e3e0          /* was #e4e4de */
--muted: #7b7a77         /* was #7b7d92 */
--amber: #c98a2b         /* was #e08c00 — desaturated */
--red: #c4554d           /* was #c9372c — desaturated */
--green: #448361         /* was #1d7a4d — desaturated */
--track: #f1f1ef         /* was #ecedf5 — neutral instead of blue-tinted */
--radius: 3px            /* was 14px — Notion-sharp corners */
Font: Inter (400/500/600/700), replacing Rubik in the Google Fonts link, body, .pd-tab, and both inline public-dashboard style strings
```

Left sidebar nav (`#sidebar` inside `.app-shell`) replaced the top `<header>`/`<nav>` bar — icon + label buttons, collapses to icon-only horizontal bar under 760px. See `rs-function-index.md`'s "Redesign status" section for exactly what changed and what's still pending.

**Not yet done (deliberately left for a follow-up session):**
- Buttons (`.btn`) are still solid navy pills, not neutral/grey with hover-revealed actions
- Status pills (`.status-pill`, `.status-todo` etc.) are still vivid hardcoded solid fills, not muted dot+label chips
- Tables still use the existing styled-grid look, not a plain spreadsheet feel
- These components use hardcoded radius/color values rather than the token vars, so the token-block swap didn't reach them automatically

Prior version (v0.8.2 — top nav header, Rubik, 14px radius) is recoverable via git history, commit `5664307` or earlier.

---

## Team members (for context)
Ross Hall, Louis Rush, Yaatzil Ceballos, Ranjani Tavargeri, Myrto Tsouma, Nafisa Ahmed, Yumna, Michal

---

## Known issues
- `renderAnimation` is defined twice (lines ~3637 and ~4187). Second definition wins — first is a stub leftover. Safe but should be cleaned up. (`openAnimCellModal` has the same duplicate pattern at ~3890 and ~4544.)
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
