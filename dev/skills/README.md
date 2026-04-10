# mirai Skill for Agents

The mirai skill for async, parallel, and distributed computing in R is part of the [posit-dev/skills](https://github.com/posit-dev/skills) repository, a collection of Claude Skills from Posit for R package development, Shiny, Quarto, and more.

## Installation

### Using `npx skills add` (Any Agent)

Works with Claude Code, Codex, Cursor, Cline, and [other supported agents](https://github.com/vercel-labs/skills).

```bash
# Install just the mirai skill
npx skills add posit-dev/skills --skill mirai

# Browse and install interactively
npx skills add posit-dev/skills --all
```

### Using Claude Code Plugins

#### Add the Posit marketplace (recommended)

Adding the marketplace lets you browse and install any skill, and easily update them later.

```bash
# Add the marketplace
claude plugin marketplace add posit-dev/skills

# Install the r-lib category (includes mirai and all R package dev skills)
claude plugin install r-lib@posit-dev-skills
```

#### Direct install without marketplace

```bash
claude plugin install r-lib@posit-dev-skills
```

## Updating

Skills installed via the Claude Code plugin system can be updated:

```bash
# Update the marketplace index first
claude plugin marketplace update

# Then update individual plugins (use the same plugin@marketplace identifier as install)
claude plugin update r-lib@posit-dev-skills
```

Skills installed via `npx skills add` are copied into your agent's configuration at install time. To update, simply re-run the install command to fetch the latest versions.
