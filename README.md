# claude-setup

Version-controlled working conventions for AI-assisted development — the rules, skills, and
scaffolding that make every project under `~/dev` follow the same flow.

Built around the [AI-native SDLC playbook](https://claude.com/blog/the-ai-native-sdlc-playbook):
every feature moves **intent → spec → plan → code**, each artifact accepted before the next.

## What's here

| Path | Installs to | What it does |
|---|---|---|
| `dev/CLAUDE.md` | `~/dev/CLAUDE.md` | The standing rules. Read automatically in every session under `~/dev` — this is the layer that doesn't depend on recall. |
| `claude/skills/new-project/` | `~/.claude/skills/` | Scaffold a project: slug → vault folder → intent interview → critique → repo promotion. |
| `claude/skills/sdlc/` | `~/.claude/skills/` | Which artifact is next, and the gates between them. |
| `claude/skills/project-audit/` | `~/.claude/skills/` | Find and fix drift across all projects. |
| `project-template/` | `~/dev/projects/_project-template` | The scaffolding itself, plus `new-project.sh` and `project-audit.sh`. |

## Install

```bash
git clone git@github.com:werner-jakobsmeier/claude-setup.git ~/dev/claude-setup
~/dev/claude-setup/install.sh
```

Everything is **symlinked**, not copied — edit the installed file and the change is already in the
repo. No syncing back, no forgetting which copy is real.

## Commands

```bash
new-project.sh init <slug> "<Title>"     # vault design folder
new-project.sh repo <slug> "<Title>"     # repo docs skeleton, migrates the chain, git init
new-project.sh sync <slug> [--apply]     # re-stamp after the template changes (dry run by default)
project-audit.sh [slug]                  # conformance checks across all projects
```

## The idea

Conventions decay when they live only in someone's head, or in a tool's soft memory. These live in
files that load unconditionally, are enforced by scripts that check the same things every time, and
are versioned so a change to the convention is a change to the template — applied everywhere with
`sync`, not re-typed per project.

## Not tracked

`~/.claude/settings.json` is deliberately excluded — it holds machine-specific settings and may
gain environment values that shouldn't be published.
