---
description: Turn your daily logs into a short standup-format update, saved in team-updates/ and ready to paste into Slack, email, or a 1:1 doc.
argument-hint: [today | yesterday | this-week | last-week]
---

# /personal-os:team-update

Write a status update from this repo's `daily-logs/`.

A session-start hook already writes last week's update automatically (`team-updates/week-of-<monday>.md`) if you forgot. This command is the manual, reviewed version: use it for any period, and to edit what the hook wrote.

## 1. Resolve the period

`$ARGUMENTS` is `today`, `yesterday`, `this-week`, or `last-week`. If it is missing or unclear, ask. Never guess.

With `date +%F` as today:
- `today`: today. `yesterday`: the previous weekday.
- `this-week`: Monday of this week to today. `last-week`: Monday to Sunday of last week.

Label: the date for a single day, `week-of-<monday>` for a week.

## 2. Gather the logs

Read every `daily-logs/*.md` whose filename starts with a date in the period (skip `*-lint.md` and `lint-exceptions.md`). If the period includes today, also use this session. If there are no logs, say "no daily logs found for <period>" and stop. **Never write an update from memory.**

If `team-updates/<label>.md` already exists (the hook may have written it), read it and offer to revise it rather than starting over.

## 3. Draft in standup format

```markdown
# Team update: <period>

## What did I do?
- Concrete, finished outcomes. One bullet per outcome, not per session.

## What's next?
- Next steps stated or clearly implied in the logs.

## Blockers, help or discussion
- Anything blocked, waiting on someone, or needing a decision. "None." if nothing.
```

Condense hard: people skim this. At most 8 bullets per section. Outcomes, not activity ("launched the webinar page", not "worked on the webinar page"). No em dashes, no secrets, no email addresses.

**Show the draft and wait for the user to confirm or edit.**

## 4. Save it

Write the confirmed version to `team-updates/<label>.md`, overwriting only after the user confirmed. Then print it once more in a fenced block so it is easy to copy into Slack or email.
