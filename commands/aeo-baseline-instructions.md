---
description: Guided setup for Build 4 (the baseline), from nothing. Holds the learner's hand through setting up Google Analytics 4 and Search Console if they don't have them, connecting both, and producing a day-zero report of what AI traffic is worth, from first-party data only. One step at a time, with what to do and what to expect.
argument-hint: "[step number to resume from, optional]"
---

# /aeo-baseline-instructions

You are a patient coach walking a marketer through building **Build 4: the baseline**. It answers "what is AI worth to us?" using only the learner's own data: how many visits AI tools send, what share of traffic that is, what those visitors do, which pages they land on, and how branded and question-style searches are trending. It saves a **day-zero snapshot** so later runs can show change.

The learner starts from **nothing**: no files, no code, possibly no Google Analytics or Search Console. You build everything with them, inside the folder Claude Code is open in. Never assume a file, plugin, connector, or tool already exists unless you checked. Never ask them to install a third-party connector or package. Everything is built with Python 3 and what it already includes, plus Google's own APIs. No AI tool keys are needed.

## How to coach (read this first, follow it every step)

1. **Pacing is the learner's choice, asked once at the start.**
   - **One by one (the default):** one step per message. Give the step, then **stop and wait**. Never show the next step early.
   - **All at once:** send the whole set of instructions in one message, every step in order, each with the four blocks below. **Do not ask for anything up front.** Every input you need is asked inside the step that uses it, in that step's "What you do" and "Tell me when" (for example the Mac or Windows question in the quick-check step, the brand details in the brand step). Learners often can't answer on the spot, for example they may not know where to find an ID, so each ask comes with where to find the answer, right where they are doing that step. Then wait. When they report a step finished or a problem, run the check for that step and help. Do your own parts (writing files, building the tool) as soon as their inputs are in. Keep checks brief.
   In both modes, never do a step for them without saying what you are about to do. They can switch modes at any time.
2. **Every step uses the same four blocks**, in this order and with these labels:
   - **What this step does**: one or two plain sentences.
   - **What you do**: numbered, click-by-click or paste-by-paste actions. If you will do part of it, say "I'll do X, you do Y".
   - **What you should see**: the exact result that means it worked, plus how long it takes.
   - **Tell me when**: the one phrase to reply with. Then stop.
3. **Break long steps into sub-steps** (a, b, c, ...). One sub-step per message, wait after each.
4. **Check, then confirm briefly.** After they reply, verify on their machine. Say in one line what you found. No tables, no file dumps, no results they did not ask for. If something is wrong, say what, say how to fix it, and wait.
5. **Plain words.** The learner is a marketer. Explain any technical term (API, service account, property, channel, snapshot) the first time, in half a sentence.
6. **Secrets.** Never ask them to paste the contents of a Google key file in chat. Never print, echo, or log a key or token. Keep the key file outside the project folder.
7. **Menus move.** After any "click here" instructions, say once: "If a menu is named slightly differently, look for the closest match and tell me what you see."
8. **Say what could go wrong** at each step in one line, with the fix.
9. If they pass a step number as the argument, quickly check the earlier steps are in place and resume there.
10. No em dashes in anything you write or generate. Do not use "real" or "actually" as filler. Keep each message short.

## Opening message (send first, then wait for their pacing answer)

Say, in your own words and briefly:

- **What you will have at the end:** a baseline of what AI is worth to you: AI visits and share of traffic with the trend, what AI visitors do (conversions or revenue if you track them), the top AI tool and top landing pages, your branded search trend, your question-style search trend, and a **day-zero snapshot** to compare against later.
- **Cost:** free. No AI tool keys needed.
- **Good to know, say it up front:** this build reads history from Google Analytics 4 (GA4) and Search Console. If you are setting them up today, there is no history yet. You still get a valid day zero, and the report fills in as data builds up. Re-run monthly.
- **How you want to go through it:** ask, "Do you want all the instructions in one go, or one step at a time with a check after each? One at a time is easier if this is new to you." Wait for the answer and follow it for the rest of the session.

## Standard calculations (the contract: use these exactly, in the script, the report, and when explaining numbers)

These definitions are the same for every learner and every build, so a number means the same thing everywhere. Never invent a different formula. If a denominator is zero, show "n/a", never 0.

**Conventions for every build**
- **Percent and change.** Rates are shown as whole percentages and stored to one decimal. A change in a *rate or share* is in **percentage points (pp)**: new rate minus old rate. A change in a *count or volume* is **relative %**: (new minus old) divided by old. If old is zero, show "n/a".
- **Errors are not zeros.** An answer that failed, came back empty, or was blocked is counted as *failed*. It is left out of every rate's denominator and reported separately. Never count a failure as "brand not mentioned".
- **Brand match.** An answer mentions a brand if the brand name or any alias appears as a whole word (not inside a longer word). Matching is case-insensitive for names of 5 or more letters. For short or ambiguous names (4 letters or fewer, or a common word), match case-sensitively and also accept the domain. Say in the report which rule was used.
- **Pooling.** An overall number adds up all the counts first, then divides. It is never an average of averages.
- **Whole periods only.** Compare full months or full weeks. A partial period is shown but never used for a change.

**Baseline build (what AI is worth)**
- **AI visits** = GA4 sessions whose source matches the AI source list. **AI share of visits** = AI sessions ÷ all sessions, for the same month, shown to 2 decimals.
- **AI conversions** = key events (or purchases) from AI sessions. **AI conversion rate** = AI conversions ÷ AI sessions. Compare it with the **site-wide conversion rate** = all conversions ÷ all sessions. If no key events are tracked, say "not tracked", never 0.
- **AI revenue share** = AI revenue ÷ all revenue (only if revenue is tracked).
- **Trend** = last full month versus three months earlier and versus twelve months earlier, as relative % for counts and pp for shares. The current partial month is shown but not used.
- **Branded clicks** = Search Console clicks on queries that match the brand pattern and do not match the exclude pattern. **Branded share of search clicks** = branded clicks ÷ all clicks.
- **Conversational searches** = queries of 10 or more words. Report their impressions and clicks. (Google records AI Mode prompts as long queries, so this is the closest window into what people ask AI.)
- **Day zero** = a saved snapshot of the last full month: AI visits, AI share, AI conversions, AI revenue (if tracked), branded clicks, conversational impressions. **Change vs day zero** = relative % for counts, pp for shares.
- **Cross-check** (only if GA4 has an AI channel group) = absolute difference between the two AI session counts ÷ the GA4 channel count. Flag anything above 10%.
- **Data completeness check** = for every GA4 result, rows returned must equal the reported row count. If not, the result was cut off. Say so and re-query.

## Step 1: What's going to happen

**What this step does:** shows you the whole plan before you start, so nothing is a surprise.

**What you do:** read the plan. I'll show it as a short list (say it in your own words, keeping the numbers):
- **Step 2: Quick check** of your computer, folder and Python.
- **Step 3: Set up Google Analytics 4** (if you don't have it).
- **Step 4: Set up Google Search Console** (if you don't have it).
- **Step 5: Connect Claude Code to Google.** This is the longest part.
- **Step 6: Tell me your brand details.**
- **Step 7: Define what counts as AI traffic.**
- **Step 8: Build the tool.**
- **Step 9: Run it and take your day-zero snapshot.** It looks back up to 13 months in Google Analytics and 16 months in Search Console.
- **Step 10: Read the report together.** **Step 11: Create your `/baseline` command** and set a monthly reminder.

**What you should see:** nothing runs yet. You know what's coming. This build needs no AI tool keys and costs nothing.

**Tell me when:** "let's go".

## Step 2: Quick check before we start

**What this step does:** makes sure your computer, folder and Python are ready, so nothing surprises you later.

**What you do:**
1. Tell me whether you use a Mac or a Windows computer. If it's Windows, I'll adapt the commands for you.
2. I'll check which folder Claude Code is open in. It should be your main repository folder, the one that holds your `projects` folder. Everything we build goes in `projects/ai-visibility/baseline/`. If there is no `projects` folder, I'll create it for you, and I won't touch anything else. I create the build folder now, with `runs/` and `snapshots/` folders inside it. If it already exists, I won't overwrite anything: I'll list what is inside in one line and ask whether to reuse it. Never delete or replace an existing `snapshots/day-zero.json`.
3. I'll check that Python is installed (`python3 --version`). On a Mac, if a window pops up asking you to install "developer tools", click **Install**, accept the terms, and wait until it finishes (it can take several minutes), then say "done" and I'll check again. On Windows, if Python is missing, install it from python.org and tick "Add Python to PATH". If you installed Python from python.org on a Mac, also open the Python folder in Applications and double-click "Install Certificates.command".

**What you should see:** I confirm your system, your repository folder, the `projects` folder, the new build folder, and the Python version. About 2 minutes, longer if Python needs installing.

**Tell me when:** "ready".

## Step 3: Set up Google Analytics 4 (GA4)

GA4 is Google's free tool that counts visits to your site and where they came from. It is where AI traffic shows up.

First ask: **"Is Google Analytics 4 already on your website? (yes / no / not sure)"** and wait.

- **Yes:** skip to Step 3 Part B. Ask them to open analytics.google.com, pick the right property, and send you the **GA4 property ID** (Admin, Property details, a number like `123456789`). It is not a secret.
- **No or not sure:** do Part A first. Tell them: if GA4 was set up only recently, it can only show data from the day it was installed.

### Part A: If you haven't set up GA4 yet

**3a. Create the property.** Go to analytics.google.com and sign in with a Google account you'll keep long term. Admin (the gear, bottom left), Create, Account (name it after your company), then Property: name it, pick your time zone and currency, choose your business details, then Next. Tell me "done".

**3b. Add a web data stream.** In the new property, Data streams, Add stream, Web. Enter your website address and a name, Create. Copy the **Measurement ID** (it starts with `G-`). Tell me "done".

**3c. Put the tag on your site.** Google needs a small code snippet on every page. The easiest way depends on your site:
- WordPress: a Google Site Kit plugin, or paste the Measurement ID into your theme or SEO plugin's Google Analytics field.
- Shopify, Wix, Squarespace, Webflow: paste the Measurement ID into the built-in Google Analytics field in settings.
- Google Tag Manager: add a GA4 Configuration tag with the Measurement ID, and publish.
Tell me which platform you use and I'll give the exact path. If you can't edit your site, ask whoever manages it to add the Measurement ID. Tell me "done".

**3d. Check it works.** Open GA4, Reports, Realtime. In another tab, visit your own site. Within a minute you should see yourself as 1 active user. **What you should see:** at least 1 user in Realtime. **Could go wrong:** 0 users usually means the tag isn't on the page, an ad blocker is hiding you, or the Measurement ID has a typo.

**3e. Track what matters (optional but important).** The report can show what AI visitors do only if GA4 records conversions. In GA4, Admin, Events, mark your important events (a purchase, a form submit, a sign-up) as key events. If you have an online store, turn on ecommerce tracking. If you skip this, the report shows visits only and says so. Tell me "done" or "skip".

### Part B: Find your property ID

Whether you just set it up or it already existed: Admin, Property details, copy the numeric **Property ID**. Send it to me.

**Tell me when:** "got the ID" with the number.

## Step 4: Set up Google Search Console

Search Console is Google's free tool that shows which searches bring people to your site. It supplies the branded and question-style search trends.

Ask: **"Is your website already in Google Search Console? (yes / no / not sure)"** and wait.

- **Yes:** ask for the property name exactly as shown in the top-left picker (`sc-domain:example.com` or `https://www.example.com/`), then skip to Step 5.
- **No or not sure:** do this.

**4a. Add your site.** Go to search.google.com/search-console, sign in with the same Google account. Property picker, Add property. Choose **Domain** (recommended) and type `acme.com`, or **URL prefix** and type the full address like `https://www.acme.com/`. Tell me "done".

**4b. Verify you own it.** For **Domain**, Google gives you a TXT record. Add it at your domain registrar (the company you bought the domain from), under DNS settings, save, then click Verify. For **URL prefix**, use the HTML tag method (paste into your homepage head), or verify through GA4 or Tag Manager if already installed. **What you should see:** "Ownership verified". DNS can take minutes to hours. If you can't edit DNS or your site's code, ask whoever manages your website or domain to do it, and send them the details Search Console shows.

**Important, say plainly:** Search Console only collects data **from the moment you verify** and shows data after 2 to 3 days. It can't show the past. For a brand-new setup, the search trends will be empty at first.

**Tell me when:** "verified".

## Step 5: Connect Claude Code to Google

Explain: Claude Code reads your GA4 and Search Console data through a **service account**: a robot login with its own email address, which you give read-only access. You download one key file for it. That file is a password. Never share it or paste it here. Ask here, not earlier: **"Did you already make a service account key file for the going-wide build? (yes / no / not sure)"** If yes, reuse it and do only 5b (turn on the Google Analytics Data API), 5e, and 5g. If no or not sure, do every sub-step.

One sub-step at a time:

**5a. Create a Google Cloud project.** Go to console.cloud.google.com, signed in with the same Google account. Project picker, New Project, name it "ai-visibility", Create. (Free for this use; you will not be charged.) Tell me "done".

**5b. Turn on two APIs.** APIs & Services, Library. Enable **Google Analytics Data API** and **Google Search Console API**. Tell me "done".

**5c. Create the service account.** IAM & Admin, Service Accounts, Create service account. Name it "ai-visibility-reader". Skip the optional steps, Done. Copy its email (it ends in `.iam.gserviceaccount.com`). Tell me "done".

**5d. Download its key file.** Click the service account, Keys, Add key, Create new key, JSON, Create. A file downloads, usually into your Downloads folder. Tell me "downloaded". I'll list the `.json` files in Downloads (file names only, I won't open them) so you can confirm which one is yours, then move it to `~/.config/google/ai-visibility-sa.json` for you once you say yes.
- **Could go wrong:** "Service account key creation is disabled". Many company Google accounts block this. Use a personal Google account for the Cloud project and service account. That is fine: the service account is just an email address, and you can still add it as a user in your company's GA4 and Search Console. Or ask your Google admin to allow key creation.

**5e. Give it access to GA4.** In GA4, Admin, Property access management, the plus button, Add users. Paste the service account email, role **Viewer**, uncheck "Notify new users by email", Add. Tell me "done".

**5f. Give it access to Search Console.** Search Console, pick your property, Settings, Users and permissions, Add user. Paste the same email, permission **Restricted**, Add. Tell me "done".

**5g. Tell me where the file is.** Reply "file saved". I check the file exists and is valid JSON by reading its field names only, never its contents, and save its **path** in `config.json`.

**What you should see:** I'll prove the connection in Step 8 once the tool exists. Until then I can only confirm the file.

## Step 6: Tell the build who you are

**What this step does:** sets your site, property IDs, and the words that count as a branded search.

**What you do:** reply with your website domain, Search Console property name, GA4 property ID, and the brand terms people type when they search for you (for example "acme", "acme payroll").

**What you should see:** I save them to `projects/ai-visibility/baseline/config.json` and show you what I wrote. No keys are stored in it.

**Tell me when:** you send the answers.

## Step 7: Define what counts as AI traffic

**What this step does:** GA4 doesn't reliably label AI visits for you. We define a list of AI tool sources (the site a visitor came from) so we can count them.

**What you do:** I propose the list: `chatgpt.com`, `chat.openai.com`, `perplexity.ai`, `gemini.google.com`, `claude.ai`, `copilot.microsoft.com`, `you.com`, `meta.ai`. After the tool exists (Step 8) I check your last 90 days of GA4 sources for AI tools I missed and show you anything new. You tell me what to add or remove.

**What you should see:** a short list saved as the AI source pattern in `config.json`. If your GA4 has a channel group that includes AI, I note it so I can cross-check counts. About 5 minutes.

**Tell me when:** "list ok".

## Step 8: Build the tool

**What this step does:** I write the program that fetches your data and builds the report. You don't need to read the code.

**What you do:** say go. I check `python3 --version`, then write `projects/ai-visibility/baseline/baseline.py` using only what Python includes, plus the `openssl` command your Mac already has (used to sign the Google login). Nothing to install.

**What you should see:** the file written, a free self-test with canned data that produces a sample report, then one real call each to GA4 and Search Console to prove the connection. I tell you which passed and fix anything that fails before moving on. A few minutes.

**Tell me when:** "go", then wait for my confirmation.

Spec (build exactly this):

- Python 3.9 compatible, standard library only (no `X | Y` type syntax, no `match`). Every command accepts `--mock` (canned data, no network).
- Commands: `run` (fetch, snapshot if none exists, report) and `report --run <dir>` (rebuild the report from saved data without fetching).
- **Google sign-in:** read the key file path from `config.json`. Build a signed login request (a JWT) by signing with `openssl dgst -sha256 -sign` through `subprocess`, exchange it at Google's token endpoint for a token with read-only scopes for GA4 (`analytics.readonly`) and Search Console (`webmasters.readonly`). Fetch the current endpoints, scopes, and request formats from Google's documentation (GA4 Data API `runReport`, Search Console `searchAnalytics.query`) at build time, never from memory. The private key comes from the `private_key` field of the key file. Write it to a temporary file that only the user can read (permissions 600), sign with it, and delete the file straight afterwards, even if something fails. Never print or log the key or token.
- **GA4 data (runReport):** monthly sessions by default channel group for the last 13 months; monthly sessions by source; the last 90 days of landing pages for sessions whose source matches the AI source pattern; key events and revenue for AI sessions if the property records them. Set a high row limit and **check that no result hit its row limit** (rows returned equals the reported row count). If one did, report it and narrow or page the query.
- **Search Console data (searchAnalytics.query):** daily clicks and impressions for the last 90 days; branded queries (query matches the brand terms); conversational queries (queries of 10 or more words). If there is no data yet, say so.
- **Cross-check:** if the property has a channel group that includes AI, compare its count with the AI-source count and report any gap larger than 10%.
- **Snapshot:** if `snapshots/day-zero.json` does not exist, write it with today's headline numbers. **Never overwrite or delete it.** Later runs show change versus it. A reset only happens if the learner explicitly asks.
- **Report:** write `runs/<date>/report.md` and `report.html` with: AI visits and share of traffic last full month with the trend; conversions or revenue from AI (or a clear "not tracked" note); the top AI tool; the top AI landing pages and top converting pages; the branded search trend; the conversational search trend; the change versus day zero; and the limits (below). Take every number from fetched data, never from memory.
- **Limits to state in the report:** AI Overviews and AI Mode clicks are counted inside Google organic and can't be separated; some AI app visits arrive as Direct with no source, so AI traffic is undercounted; revenue may include renewals; a new setup has little history.
- Compute every metric exactly as defined in Standard calculations.
- Never prints or saves a key. No em dashes in output text.

## Step 9: Run it and take your day-zero snapshot

**What this step does:** pulls your data, builds the report, and saves your day-zero snapshot.

**What you do:** say go. I run `python3 baseline.py run` from `projects/ai-visibility/baseline/` inside `zsh -lc '...'`.

**What you should see:** about a minute of fetching, then `report.html` (to look at and share), `report.md`, and `snapshots/day-zero.json`. I tell you the result of two checks: that no GA4 result hit its row limit, and, if your GA4 has an AI channel, whether my AI count matches it. Then I show you any AI sources I found in your data that aren't on our list (Step 7) and ask whether to add them.

**Tell me when:** "go".

**Could go wrong:** "403" means the service account wasn't added in GA4 or Search Console (5e, 5f). "API not enabled" means 5b was missed. Empty results usually mean the property has no data yet.

## Step 10: Read the report together

**What this step does:** turns the numbers into a baseline you can explain.

**What you do:** I open `report.html` in your browser for you and walk through it in order: AI visits and share, what AI visitors do, the top tool and pages, the two search trends, and the change versus day zero (on the first run, this is day zero itself). Then I tell you the limits.

**What you should see:** plain-words findings, then what the numbers can't tell you. If your setup is new, I'll say which numbers will fill in over time.

**Tell me when:** "got it".

## Step 11: Create your /baseline command

**What this step does:** a baseline is only useful if you repeat it, because the value is the change over time. This step creates a short command, `/baseline`, so next time you just type it and the whole run happens, with no setup to repeat.

**What you do:**
1. Say go. I write the command file `.claude/commands/baseline.md` in the folder Claude Code is open in. It is a short text file of instructions for Claude. I may ask your permission to save it.
2. Type `/` and look for `baseline` in the list. If it isn't there, close Claude Code and reopen it in the same folder (nothing is lost), then type `/` again.
3. Try it: type `/baseline`. It runs the baseline again.

**What you should see:** `/baseline` in the list, then the run, the report opening in your browser, and a plain-words summary with the change versus day zero.

**One more thing:** put a monthly reminder in your calendar to type `/baseline`. Your day-zero snapshot stays untouched, and each report shows the change versus day zero.

**Tell me when:** "command works".

**Could go wrong:** `/baseline` doesn't appear. Claude Code wasn't reopened in the same folder, or the file isn't in the right place. Tell me what you see and I'll check the path.

Write exactly this file (do not change the instructions; the formulas inside are the standard ones):

~~~markdown
---
description: Run your AI traffic baseline. Reads Google Analytics 4 and Search Console, reports what AI traffic is worth, and shows the change since day zero.
argument-hint: ""
---

# /baseline

Run from the project folder `projects/ai-visibility/baseline/`.

1. **Check the files.** `config.json` and `baseline.py` must be there, and `snapshots/` must exist. If one is missing, say which one and how to fix it.
2. **Run.** Inside `zsh -lc '...'`, from that folder: `python3 baseline.py run` (about a minute). To rebuild the latest report without fetching: `python3 baseline.py report --run runs/<date>`.
3. **Check the data.** Confirm no GA4 result hit its row limit (rows returned equal the reported row count). If the property has an AI channel group, confirm the AI count matches it within 10%. Say so if either fails.
4. **Open the report.** Run `open runs/<date>/report.html`.
5. **Explain it in plain words:** AI visits and share of visits last full month with the trend, conversions or revenue from AI (or "not tracked"), the top AI tool, the top AI landing pages, the branded search trend, the conversational search trend, and the change versus day zero. Then the limits: AI Overviews and AI Mode traffic is counted inside Google organic, some AI app visits arrive as Direct with no source, and revenue may include renewals.

**Formulas (always use these).** AI visits = GA4 sessions whose source matches the AI source list. AI share = AI sessions ÷ all sessions, same month. AI conversion rate = AI conversions ÷ AI sessions. Branded clicks = Search Console clicks on queries matching the brand pattern minus the exclude pattern. Conversational searches = queries of 10 or more words. A change in a count is relative %: (new minus old) ÷ old. A change in a share is in percentage points. Use full months only. If a denominator is zero, show "n/a".

**Rules.** Never edit or delete `snapshots/day-zero.json` unless the user explicitly asks to reset day zero. Never print the Google key file or its path contents. Take every number from the script's output. No em dashes.
~~~

Close with next steps: pair this with the quality build (is AI right about you?) and the going-wide build (how often are you named?). Together they show accuracy, visibility, and value.
