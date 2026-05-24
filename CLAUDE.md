# CarpCode

This repository is a **prototyping and ideas sandbox**. It is never the production home for anything.

## Purpose

Explore, sketch, and validate concepts before they earn their own production repository.
Every subfolder is a self-contained prototype or experiment.

## Conventions

- **One subfolder per prototype.** Name it `<concept>-prototype/` or `<concept>-experiment/`.
- Prototypes use Swift Package Manager (no `.xcodeproj` committed) so they are portable and diff-friendly.
- Production-bound code lives elsewhere. When a prototype graduates, create a new repo and copy the relevant pieces.
- Commit early and often — these are ideas, not polished code.

## Current Prototypes

| Folder | Description |
|--------|-------------|
| `ios-cowork-prototype/` | iOS-native agentic coding assistant (Codex / Claude Code analogue) |
| `watch-ai-core-prototype/` | Shared SPM package consumed by the six watch+AI prototypes below. Not for graduation — gets copied into a child repo when an app graduates. |
| `whispernote-prototype/` | Watch voice → Whisper → LLM-structured notes. |
| `mom-prototype/` | Habit + task manager that flexes around your real calendar. |
| `askband-prototype/` | Push-to-talk LLM Q&A from the wrist. |
| `echolingo-prototype/` | Real-time bidirectional voice translator. |
| `vitaquery-prototype/` | Natural-language HealthKit queries. |
| `wristshell-prototype/` | Voice-controlled VPS ops over Tailscale (allowlisted command templates only). |

## Adding a New Prototype

1. `mkdir <name>-prototype && cd <name>-prototype`
2. `swift package init --type library` (or `--type executable`)
3. Add a `README.md` describing what you're exploring and why.
4. Commit.
