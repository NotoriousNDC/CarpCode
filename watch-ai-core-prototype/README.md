# watch-ai-core-prototype

Shared Swift Package consumed by the watch + AI prototypes in this repo:

- `whispernote-prototype/`
- `mom-prototype/`
- `askband-prototype/`
- `echolingo-prototype/`
- `vitaquery-prototype/`
- `wristshell-prototype/`

This package is **not** intended to graduate to its own production repo. When
one of the apps above is ready to graduate, copy `Sources/Core/` (and any
`CoreUI/` bits used) into the new repo and drop the relative SPM dependency.

## Why a shared package during prototyping?

The six prototypes share enough surface — Keychain, multi-provider LLM client,
Whisper client, `WCSession` bridge, privacy config — that maintaining six
copies during exploratory work would be wasteful. A single shared package
keeps iteration cheap. The cost of extracting a slice later (~ 2 minutes of
copying) is far smaller than the cost of duplicating now.

## What's here

```
Sources/
├── Core/
│   ├── Privacy/         PrivacyConfig + log/string redaction
│   ├── Security/        KeychainStore + BiometricGate (LAContext)
│   ├── Providers/       ModelProvider protocol + Anthropic/OpenAI clients
│   ├── Transcription/   Whisper client + on-device speech fallback + AudioRecorder
│   ├── Bridge/          WCSession wrapper + offline command queue
│   ├── Net/             URLSession wrapper, SSE parser, Tailscale-aware endpoints
│   ├── Models/          Message, ContentPart, ToolDefinition (mirrors ios-cowork)
│   └── Utilities/       JSON helpers, AsyncStream extensions
└── CoreUI/              RecordingOrb, PrivacyBadge, Theme
```

## Privacy posture

`PrivacyConfig` defines three modes (Strict / Balanced / Convenience). Every
feature in every app gates cloud calls and data minimization through this
config. Default is **Balanced**. Apps with elevated risk (e.g. WristShell)
default to **Strict** instead.

## Tests

`Tests/CoreTests/` is pure-Swift — runs under `swift test` on Linux without
any Apple platform dependencies.
