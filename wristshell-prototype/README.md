# wristshell-prototype

Voice-controlled VPS operations from the wrist. Tailscale-private by default.

## Why this isn't possible today

Termius doesn't do voice and has no watch app worth using. SSH from a watch
is a security nightmare if you do it naive. The interesting design question
is: how do you build *useful* remote ops from a wrist without giving the
wrist arbitrary shell access?

Answer: don't ship SSH at all. Ship an allowlist of operations, exposed via
a tiny VPS-side service, addressable only from inside your tailnet by default.

## Threat model

- **Watch is the weakest link.** Stolen wrist + biometric bypass should not
  equal "rm -rf my server." Hence: no free-form shell on watch.
- **Network is hostile by default.** Both phone and VPS are nodes on the
  user's Tailscale tailnet. The VPS service binds only to its tailnet IP.
  Public ports stay closed.
- **LLM is untrusted.** The model proposes a *templated* command; the VPS
  service validates the template + arguments against its allowlist. The
  model cannot emit raw shell.

## Topology

```
DEFAULT (private):
  Watch ─ WCSession ─► Phone ─ Tailscale ─► VPS Agent (Tailscale IP only)
                                                │
                                       runs templated commands
                                       under a restricted shell

OPT-IN STANDALONE (cellular watch, phone absent):
  Watch ─ HTTPS + mTLS ─► VPS Agent (public endpoint, separate from Tailscale one)
                                                │
                                       same allowlist, same validation
                                       bearer token rotated every 15 min
                                       biometric required to enable
```

## Voice flow

```
speak ─► Whisper ─► LLM with allowlisted-template prompt
                          │
                          ▼
                  JSON: { "template": "restart_service",
                          "args": { "name": "nginx" } }
                          │
                          ▼
                  CommandPlanner validates against AllowlistRegistry
                          │
                          ▼
                  Phone POST → VPS Agent → run + return stdout/stderr
```

## Privacy defaults

Default `PrivacyConfig` is **Strict**, not Balanced:

- Voice transcription is required to go through the phone (never direct watch→cloud).
- Command outputs never written to disk on the watch.
- Command templates ship with the app — never LLM-generated arbitrary shell.

## Folder layout

```
wristshell-prototype/
├── Package.swift                (watch + phone client)
├── README.md
├── Sources/
│   ├── WristShellCore/          shared types: CommandTemplate, Allowlist, Planner
│   ├── WristShellWatch/         tiny watch UI
│   └── WristShellPhone/         settings + connection management
├── VPSAgent/                    separate SPM exec for the Linux daemon
│   ├── Package.swift
│   └── Sources/VPSAgent/        receives requests, validates, executes
└── Tests/
    └── WristShellCoreTests/
```

## Run

`swift build` in the top folder builds the iOS/watch client core.
`swift build` in `VPSAgent/` builds the Linux daemon.

## Status

Skeleton. Command planner + allowlist + agent shell are stubbed at a level
where you can read the threat model and the data flow but no live socket
is opened anywhere.
