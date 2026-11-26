# n8n templates

Workflow files that a personal-os command imports into n8n by address.

| File | Used by | What it is |
|---|---|---|
| `ai-visibility-tracker-template.json` | `/personal-os:aeo-goingdeep-instructions`, step 4 | The AI Visibility Tracker: asks ChatGPT, Claude, Perplexity and Gemini your prompts each week and saves the answers and mention rates to a Google Sheet. Built by Tarek Reslan for CXL. |

The command gives members the raw address of the file on the `main` branch. Renaming or moving a file here breaks that step, so change the address in the command in the same pull request.

The file holds no keys. The credential names inside it are labels from the n8n account it was exported from; members connect their own accounts after importing.
