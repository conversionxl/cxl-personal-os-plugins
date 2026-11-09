---
description: Fast context brief on a person, project, company, or topic, from the repo plus email and calendar when connected.
argument-hint: [person | project | company | topic]
---

# /personal-os:brief

Generate a contextual brief for: **$ARGUMENTS**

If no subject was given, ask for one and stop.

The goal is to quickly understand what this is, what changed recently, what is open, and what to prepare before engaging.

## Steps

1. **Search the repo first.** Look in:
   - `projects/` (the matching project file and its folder)
   - `daily-logs/` (the last 14 days, newest first)
   - `wiki/` (people, concepts, glossary)
   - `drafts/` and `frameworks/` for anything related
   - `team-updates/` for recent status
2. **Then connected tools, best effort.** If Gmail or Google Calendar tools are available in this session, check recent threads and upcoming or recent meetings about this subject. If they are not available, say so in one line and continue from the repo alone. Never pretend to have checked a source you could not reach.
3. **Identify:** latest updates, pending tasks, unresolved questions, blockers, recent decisions, deadlines, and what other people are expecting.
4. **If it is a person or a meeting:** who they are, previous interactions, likely discussion topics, and anything not to forget.
5. **If it is a project:** status, current priorities, risks, next steps, and what is slowing it down.

## Output

Keep it concise and skimmable. Use wikilinks for projects, people, and frameworks that exist in the repo. Never invent a link.

```
# Brief: <subject>

## Overview
## Latest updates
## Open tasks and follow-ups
## Risks and blockers
## Prepare before engaging
## Sources
<which files, threads, and events this brief used>
```

End with:
- Top 3 things to know
- Top 3 things to do next

If the repo has little or nothing on the subject, say so plainly and suggest what to capture (for example: "create `wiki/people/<name>.md`" or "drop your notes from the last call into `raw/`").
