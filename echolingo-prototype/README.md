# echolingo-prototype

Real-time bidirectional voice translator from the wrist. Travel + meeting killer.

## Why this isn't possible today

Apple's Translate app on watch is single-utterance and shaky in noise. No
shipping watch app does continuous bidirectional voice-to-voice translation
with LLM-quality output and intelligent turn-taking. The wrist is the right
form factor because it's *visible to both parties* and doesn't require pulling
out a phone in the middle of a conversation.

## Flow

```
mic ─► VoiceActivityDetector (energy-threshold)
        │ chunks at natural pauses
        ▼
     Whisper (language hint per side)
        │
        ▼
     LLM translation prompt (strict: no commentary)
        │
        ▼
     AVSpeech in target language
```

A wrist-flip (CoreMotion) toggles direction A↔B.

## Privacy

- Same as WhisperNote — audio is the most sensitive payload.
- Strict mode falls back to `SFSpeechRecognizer` + Apple Translation API
  (on-device for many pairs in iOS 18+). Quality drops but nothing leaves the device.
- No transcript persistence by default.

## Run

`swift build` for the core. Watch + phone apps need Xcode.

## Status

Skeleton — VAD + translator + view scaffold. No CoreMotion wrist-flip
detector yet; no Apple Translation API fallback wired.
