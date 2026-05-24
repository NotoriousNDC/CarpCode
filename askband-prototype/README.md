# askband-prototype

Push-to-talk LLM Q&A from the wrist.

## Why this isn't possible today

Siri on the watch is locked to Apple's models and refuses lots of factual
queries. Third-party "ChatGPT on watch" apps exist but are clunky text-input
UIs. A real push-to-talk LLM with provider choice (Claude 4.7 / GPT) and a
complication entry point is genuinely missing.

## Flow

```
complication tap / crown long-press
   │
   ▼
RecordingOrb ── Whisper ── LLM (streaming) ── AVSpeech
                            │
                            ▼
                       text on screen
```

Conversation history (last ~5 minutes) is held in memory only and supports
follow-up questions; clears after the timeout or on app dismissal.

## Privacy

- No persistence by default. History never touches disk.
- Strict mode disables AVSpeech for anything that quotes user content back
  verbatim (so a passerby can't hear your last query read aloud).
- Audio is deleted right after Whisper returns; we never keep it.

## Run

`swift build` for the core. Watch + phone apps need Xcode.

## Status

Skeleton — state machine, view scaffold, no complication entry yet.
