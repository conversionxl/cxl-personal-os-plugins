You are generating an end-of-session daily log for the repository this session ran in, automatically. No user is available to answer questions. You are given the session transcript (JSONL) below.

Produce ONLY the markdown content of the daily log file. No preamble, no code fences, no commentary before or after, and do NOT use any tools: just output the markdown. It will be written directly to `daily-logs/<date>-convo.md`.

**Never use em dashes (—).** This repo bans them in every file, daily logs included. Before you output, scan your text for `—` and rewrite each one with whichever punctuation reads best: a full stop for a clean break between two clauses, a colon for a lead-in or definition, a comma for a brief aside. Do not reflexively default to a comma. Also avoid "real" and "actually" as filler words.

**Never copy secrets or customer PII into the log.** No API keys, tokens, passwords, and no email addresses. Refer to customers by role or company, not by name and email.

Infer everything from the transcript. Use this exact structure:

# Session Log: <use the date given in the context line>

## Session Summary
High-level overview of what happened this session.

## What Got Done
Work completed, classified ✅ Done / 🔄 Partial / ⏭️ Deferred.

## New Commitments
Action items or follow-ups surfaced, each tagged with the project or workstream it belongs to. Use the names that appear in the transcript, matching them to folders under `projects/` where the repo has one, and tag anything that fits no project as "general". You cannot edit project files here, just record them.

## Decisions
Decisions made, or still open.

## Roll-Forward for Tomorrow
- What slipped and why
- Top 3 priorities for tomorrow
- Prep needed

## Blockers / Help Needed
Anything blocked, waiting on someone, or worth raising with the team. Write "None" if nothing.

## Project Updates
Updates grouped by project.

## New Ideas
Notable concepts or workflows discussed.

## Commands or Systems Created
Commands, automations, or files created or updated.

## Important Context for Future Sessions
Anything the next session should know.

Rules:
- If the repo uses wikilinks (an Obsidian vault), use them for stable entities mentioned in the transcript. Otherwise use plain names. Never invent a link to something that was not mentioned.
- Be concise and operational. If the session was trivial, keep it short. Never invent work that didn't happen.
- End with a one-paragraph executive summary and the single most important thing to pick up next session.
