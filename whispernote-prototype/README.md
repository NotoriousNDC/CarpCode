# whispernote-prototype

Voice → Whisper → LLM-structured notes, captured from the wrist.

## Why this isn't possible today

watchOS has Apple dictation, but no shipping app captures long-form audio,
transcribes it with Whisper, and runs LLM post-processing
("clean disfluencies", "extract action items", "title this note") directly
from the wrist. Voice memo apps are recorders, not note-takers — the
intelligence lives in another product entirely. WhisperNote collapses the
loop: tap, talk, the structured note lands on your phone seconds later.

## Architecture

```
Watch                     Phone                     Cloud
─────                     ─────                     ─────
record m4a chunks ──► WCSession ──► OpenAI Whisper
                                          │
                                          ▼
                                  cleanup prompt → Claude / GPT
                                          │
                                          ▼
                                    CloudKit private DB
                                          │
Watch list view ◄────── WCSession ◄───────┘
```

When the phone is unreachable but the watch has cellular, the watch uploads
to Whisper directly; LLM cleanup defers until the phone is back. In Strict
privacy mode, transcription falls back to `SFSpeechRecognizer` and LLM
cleanup is skipped.

## Privacy

- Audio files are encrypted at rest (`completeUntilFirstUserAuthentication`).
- In Strict mode, no audio or transcript ever leaves the device.
- In Balanced mode (default), transcripts go through Whisper + LLM; audio
  is deleted from disk once Whisper returns.
- CloudKit private database (per-user) for note storage. Swap for SQLite if
  you want strict local-only.

## Run

`swift build` from this folder builds the core library. The watch + phone
apps need Xcode (no SPM-only build path for watchOS apps).

In Xcode: open `Package.swift`, add an Xcode app project that imports the
three targets as products, sign with your team, run on a paired
device + Apple Watch.

## Status

Skeleton — wiring + key types only. No CloudKit container set up yet,
no UI polish.
