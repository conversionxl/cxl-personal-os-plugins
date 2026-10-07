---
description: Weekly health check. Finds contradictions, stale claims, orphan notes, missing concepts, neglected projects, unsourced claims, folder-map drift, and loose or temp files, then suggests a folder cleanup. Reports first, fixes only on confirmation.
argument-hint: [check name | folder]
---

# /personal-os:lint

Run the repo health check. Find the errors that quietly rot a second brain, and the clutter that buries it, before they surface at the worst moment. Report everything, propose fixes, change nothing without confirmation.

- If `$ARGUMENTS` names one check (for example `contradictions`, `neglected projects` or `loose files`), run only that check.
- If `$ARGUMENTS` names a folder, run all checks but report only findings whose fix lives in that folder.

## Before you start

- **Read the folder map.** If `.claude/folders.json` exists, run `bash "${CLAUDE_PLUGIN_ROOT}/hooks/folder-map.sh" show`. Folder names in this command are the standard ones: use the mapped folder wherever one is named, subfolders included.
- **Read `daily-logs/lint-exceptions.md`.** Everything listed there was reviewed and accepted. Do not report it again unless the facts behind it changed, and then say what changed.
- **File modification dates are not a staleness signal.** Cloning, syncing, and earlier lint runs all reset them. Judge recency only from dates written inside files and from mentions in `daily-logs/`.

## Scope

- **Content checks (1 to 6):** `projects/`, `frameworks/`, `wiki/`, `drafts/`, and `CLAUDE.md`.
- **Read for evidence, don't lint:** `daily-logs/` (historical, allowed to be old) and `raw/` (unprocessed by definition; that is `/personal-os:ingest`'s job).
- `.claude/` counts as a source of links when judging orphans, but is not linted itself.
- **Housekeeping checks (7 to 9):** the whole folder, except `.git/`. Inside `.claude/`, look only for temp files.

## The checks

1. **Contradictions.** The same fact stated differently in two places: a number, a deadline, a decision open in one file and closed in another. Quote both with file paths and say which one recent evidence supports.
2. **Stale claims.** Any number, status, or "current state" statement older than 60 days with no refresh. Ask the real question: is the work stuck, or is the file out of date?
3. **Orphan notes.** Files nothing links to. Recommend connecting (from where) or removing (why it is safe).
4. **Missing concepts.** Terms, names, or ideas in 3 or more files with no page of their own. Propose where the page belongs (`wiki/` for concepts and people, `frameworks/` for methods). Skip generic vocabulary.
5. **Neglected projects.** Judge each `status: active` project against its own `cadence`:
   - Last real activity = the later of its latest in-text date and its latest mention in `daily-logs/`.
   - Budget: weekly 7 days, monthly 30, quarterly 90. Flag when past budget plus half again (weekly at 10+ days, monthly at 45+).
   - Say how many cadence cycles were missed, not only the day count.
   - Is `next_action` still right, or overtaken?
   - A project with no `cadence` field is its own finding.
   - Then the honest question: done, paused, or ignored? Propose updating `status` or `cadence` so the file tells the truth.
6. **Unsourced claims.** Stats, benchmarks, quotes, or external dates with no source. Hand-written opinion and strategy need no citation. Performance numbers always do.
7. **Folder map.** Only when `.claude/folders.json` exists.
   - A mapped folder that does not exist, or a value that is not a relative path inside this folder (the hooks ignore those and fall back to the standard name).
   - **Split folders:** a standard folder that still holds files next to its mapped replacement (`projects/` beside `PROJECTS/`). Notes land in both and half go unread. Propose merging into the mapped one.
   - **Local-only folders leaking:** every folder `.gitignore` keeps local under its standard name (for example `raw/voc/`, `raw/strategy/`, `raw/performance/`, `raw/campaigns/`) must be local-only under its mapped name too. The `Git` column of `show` says so. Any that reads `committed` is 🔴: the fix is `bash "${CLAUDE_PLUGIN_ROOT}/hooks/folder-map.sh" gitignore`, and if files are already tracked, `git rm --cached` on them (the files stay on disk).
   - **General instructions in a subfolder:** an about-me file, or a subfolder `CLAUDE.md` holding rules that apply everywhere (who the user is, tone of voice, how they work). A subfolder `CLAUDE.md` loads only when Claude works in that folder, so general rules there are missed everywhere else. Propose moving those parts into the root `CLAUDE.md`. A subfolder `CLAUDE.md` with conventions for that folder only (a landing page folder's rules, say) is how nested `CLAUDE.md` files are meant to be used: leave it alone and do not report it.
   - A folder that is plainly the user's own version of a standard slot but is not mapped (a `Resources/` beside an empty `wiki/`). Propose mapping it rather than moving it.
8. **Loose and temp files.** List them with `git status --porcelain --ignored` plus a `find` of the folder. Sort each into one of three groups:
   - **Junk** (safe to delete): `.DS_Store`, `Thumbs.db`, `desktop.ini`, `*~`, `*.swp`, `*.swo`, `*.tmp`, `*.temp`, `*.bak`, `*.orig`, `*.rej`, `~$*` (Office lock files), `.~lock.*`, `npm-debug.log`, empty files, and empty folders (a folder holding only `.gitkeep` is not empty). Also `daily-logs/.quarantine/` files older than 30 days and `.claude/state/` snapshots older than 30 days.
   - **Duplicates:** names like `* copy.*`, `*(1).*`, `*-old.*`, `*-final-final.*`, `Untitled*`, or two files with the same content. Compare before calling one a duplicate; say which copy to keep and why.
   - **Loose files:** anything at the top of the folder other than `CLAUDE.md`, `AGENTS.md`, `README.md`, `LICENSE`, `.gitignore`, `.gitattributes`, `CLAUDE.local.md`, `.env`, and the standard or mapped folders; plus files sitting directly in a folder whose convention is subfolders (a project note loose in `projects/` instead of `projects/<name>/`). Propose where each belongs, the way `/personal-os:ingest` routes a dump. Untracked files outside `raw/` are worth a look: they are often work that never got filed.
   - Also flag tracked files over 10 MB (they bloat git history forever) and anything in `raw/` older than 30 days (suggest `/personal-os:ingest`).
9. **Folder cleanup.** Step back and judge the structure as a whole, then suggest one tidy plan:
   - Folders outside the standard set and the map, folders with overlapping jobs (`Notes/`, `notes/`, `Misc/`, `Stuff/`), folders holding a single file, nesting deeper than three levels, and finished projects (`status: done`) still mixed in with active ones.
   - **Reroute before restructure.** When a folder is the user's own system, map it in `.claude/folders.json` instead of moving it. Move files only where the map cannot help.
   - Give the plan as a before and after tree, with every move and merge listed. Moves use `git mv` so history follows the file, and every wikilink or path pointing at a moved file is updated in the same change.

## Report

```
# Lint: YYYY-MM-DD

## Summary
<one line per check: count + 🔴 fix now / 🟡 fix soon / 🟢 clean>

## 1. Contradictions
| Fact | File A says | File B says | Which is right (evidence) |
## 2. Stale claims
| File | Claim | Age | Stuck or stale |
## 3. Orphan notes
| File | Connect from / remove | Why |
## 4. Missing concepts
| Term | Appears in | Proposed page |
## 5. Neglected projects
| Project | Cadence | Last activity | Cycles missed | next_action still right? | Verdict |
## 6. Unsourced claims
| File | Claim | What a source would look like |
## 7. Folder map
| Finding | Folder | Fix |
## 8. Loose and temp files
| File | Group (junk / duplicate / loose / large) | Tracked? | Proposed action |
## 9. Folder cleanup
<before and after tree, then the moves and map changes as a list>
```

Then a numbered fix plan, smallest safe change per finding. Junk files go in one numbered item, so the user can approve them in one go. **Wait for confirmation.** The user may approve all, some, or none by number. Apply only what was approved, additively where possible. Before deleting an orphan, a duplicate or a loose file, show a summary of its content. Delete junk only when it matches the junk list exactly; anything else gets moved or asked about, never deleted on a guess.

## Finish

- What was fixed, by number.
- **Append every declined finding to `daily-logs/lint-exceptions.md`**: date, finding, file, and the user's reason. If no reason was given, ask for one in a single line. This is what stops next week's lint from repeating itself.
- **Save the report to `daily-logs/YYYY-MM-DD-lint.md`, even on a clean run.** The session-start reminder uses this file to know when the last lint ran.
- Compare with the previous lint report: what got worse, what stayed fixed, and any finding appearing for the third time (the fix is not holding; change the approach, not the file).
