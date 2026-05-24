# mom-prototype

A habit-builder + task manager that flexes around your real calendar.
Take your life back from socials.

## Why this isn't possible today

Apple Reminders does time and location triggers, but it cannot reason. There
is no shipping watch app that says *"you have a 6-7pm window today and you
haven't done your workout cue this week — surface it now"*, or *"move the
'review contract' reminder to after your 3pm meeting because you said you
were in back-to-backs"*. Atomic-habits cueing requires understanding both
the rhythm of the habit and the texture of the day. That's an LLM job.

## Two surfaces, one engine

- **Habits** — recurring, glyph-tagged. Pick a target frequency, the engine
  picks the times. Glyphs include: water drop (hydration), sun (break),
  dog (walk), guitar (practice), dumbbell (workout), book (reading instead
  of scrolling).
- **Tasks** — one-off natural-language items ("remind me to call dad when
  I leave the office"). LLM parses these into a `TriggerRule` once.

Both feed the same `CalendarFlexEngine`, which produces `ScheduledCue`s.

## Calendar-flex engine

Runs on the phone every ~15 min via `BGAppRefreshTask`:

```
EventKit (today's calendar)
HealthKit (last gym visit, sleep window)
   │
   ▼
CuePromptBuilder ──► LLM (strict JSON schema) ──► [ScheduledCue]
   │
   ▼
UNNotificationRequests + watch push via WatchPhoneBridge
```

Watch UX is a haptic + glyph + 1-line text. Tap = done; long-press = snooze
with a reason ("in a meeting") that flows back into the engine.

## Privacy

- **Balanced (default)**: event *durations* and *categories* (Work/Personal)
  go to the LLM. Titles and attendees never leave the device.
- **Convenience**: event titles included for better reasoning.
- **Strict**: LLM disabled. Engine falls back to deterministic heuristics
  ("water every 90 minutes during awake hours, skip if in a calendar event").
  Clear "AI scheduling off" badge in UI.
- Snooze reasons are short free-text. In Balanced they're sent verbatim
  (with PII-style patterns redacted); in Strict they stay on device.

## Run

`swift build` builds the core library. Watch + phone apps need Xcode.

## Status

Skeleton — models, engine, prompt builder, watch + phone view shells.
No `BGAppRefreshTask` wiring yet; no EventKit / HealthKit live calls
(stubbed via protocols so the engine is unit-testable).

## Naming

"Mom" is the working name. Could be:
- Mom (current)
- Cue
- Bend (as in: bends to your day)
- Otis (atomic-habits friendly tone)

Folder renames are trivial; the package name only needs to change in
`Package.swift`.
