---
description: End-of-day reconciliation. Marks what got done, routes new commitments into project files, writes the daily log, and offers to push the repo to GitHub.
---

# /personal-os:shutdown

We are ending the working session. Before saving anything, ask three questions in one message and wait for the answers:

1. What got done today?
2. What didn't get done, and why?
3. Any new commitments made today?

Then do the following.

## 1. Classify today's work

Using the answers and the session, mark every task or planned item:
- ✅ Done
- 🔄 Partial (what remains)
- ⏭️ Deferred (why)

## 2. Route new commitments into project files

For every new commitment, action item, or follow-up:
- Decide which project in `projects/` it belongs to.
- Add it to that project file under `## Open tasks`. Update `next_action` in the frontmatter if it changed.
- If no project fits, record it in the daily log as a standalone task.

Show the user which project files you changed.

## 3. Close out decisions

Mark decisions made this session as decided, with the outcome. Carry anything still open forward as an open question.

## 4. Write the roll-forward

- What slipped today and why
- Top 3 priorities for tomorrow
- Prep needed for tomorrow's meetings or deadlines

## 5. Save the daily log

**One file per day, one block per session. Never overwrite.**

The file is `daily-logs/YYYY-MM-DD-convo.md` (get the date with `date +%F`).
- If it does not exist, create it.
- If it exists, read its tail first. If the last block already covers this session, update that block. Otherwise append, separated by `---` and opened with `# Session Log: YYYY-MM-DD (<short label>)`.

Use this structure:

```
# Session Log: YYYY-MM-DD

## Session Summary
## What Got Done
## New Commitments
## Decisions
## Roll-Forward for Tomorrow
## Blockers / Help Needed
## Project Updates
## New Ideas
## Commands or Systems Created
## Important Context for Future Sessions
```

Use wikilinks for projects, people, and frameworks that exist in the repo. No em dashes. No email addresses or secrets.

## 6. Update memory

If the session surfaced a durable fact (a preference, a key person, where something lives), save it to `.claude/memory/` and add it to `MEMORY.md`, writing both with the shell (a heredoc), not the file-edit tools: in Cowork the file tools cannot write inside `.claude/`. Skip this if nothing durable came up. Daily detail belongs in the log, not in memory.

## 7. Offer to sync to GitHub

An unpushed repo is out of date on every other machine. **Always offer the push. Never push without asking.**

1. **Show what changed:** `git status --short`, with a one-line summary grouped by area (projects, logs, drafts, system).
2. **Scan before staging.** Search the changes for email addresses, API keys, tokens, and passwords. Read `daily-logs/lint-exceptions.md` and skip anything already cleared there. If you find something new: stop, show each hit with file and line, and ask how to handle it. Confirm `.gitignore` still covers `.claude/settings.local.json` and `.env`.
3. **Ask to confirm**, showing the proposed commit message. Only on a yes: `git add -A`, commit, `git push`.
4. **Report plainly:** the commit SHA and what was pushed, or why the push failed and what to do. Never force-push.

If the user declines, say in one line what stays uncommitted.

## End with

A one-paragraph summary of the day and the single most important thing to pick up tomorrow.
