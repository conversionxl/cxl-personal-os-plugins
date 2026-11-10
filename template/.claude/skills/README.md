# .claude/skills/

A skill is know-how Claude loads **automatically** when a task matches its `description`. You do not call it by name.

Each skill is a folder with a `SKILL.md`: frontmatter (`name`, `description`) plus instructions. The description decides when it fires, so write it as "Apply when...".

Use a skill when Claude should always do something a certain way (your writing voice, your brand rules, how to use a tool). Use a command in `.claude/commands/` when you want to trigger a task by name.

`my-voice/` is an example to edit and make your own.
