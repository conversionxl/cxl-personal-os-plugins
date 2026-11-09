# .claude/agents/

An agent is a specialist Claude **hands a whole job to**. It runs with its own instructions, its own tool list, and a fresh context, then reports back. Good for jobs that read a lot of material and only need to return the conclusion.

Each agent is one Markdown file: frontmatter (`name`, `description`, `tools`) plus its instructions. Claude picks the agent whose description matches the task, or you can ask for it by name ("use the researcher agent to...").

`researcher.md` is an example. Build agents around your projects: which multi-step jobs do you hand off again and again?
