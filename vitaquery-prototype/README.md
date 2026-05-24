# vitaquery-prototype

Natural-language HealthKit queries from the wrist.

## Why this isn't possible today

HealthKit is rich, but the Health app is read-only and gives you charts.
There is no way to ask *"is my HRV trend concerning?"* or *"am I overtraining
this week?"* and get a real LLM that correlates sleep, HRV, training load,
and resting HR. This unlocks the qualitative health questions Apple won't
touch without a medical certification.

## Architecture

```
voice query (watch) ─► phone
                        │
                        ▼
                HealthSummarizer (HKStatisticsCollectionQuery)
                        │
                        ▼
                small JSON struct: means, stddevs, week-over-week deltas
                        │
                        ▼
                LLM with strict system prompt (see VitaPromptTemplate.swift)
                        │
                        ▼
                response (with mandatory "talk to a doctor" language for
                anything that sounds clinical)
```

**Raw HealthKit samples NEVER leave the device.** Even Convenience mode
keeps `PrivacyConfig.allowsRawHealthSamples == false`. Only aggregated
statistics are sent to the LLM.

## Privacy

- HealthKit `requestAuthorization` requested explicitly on first use.
- Only summary stats (mean, stddev, week-over-week delta, percentile vs.
  rolling 30-day window) leave the device.
- Strict mode disables the LLM entirely — falls back to a rule-based
  "your HRV is in the 25th percentile of your last 30 days" template.

## Guardrails (medical disclaimer)

The system prompt explicitly forbids diagnostic claims and requires
"talk to a clinician" language for anything that smells clinical. Apple's
HealthKit reviewers will look for this.

## Run

`swift build` for the core. Watch + phone apps need Xcode.

## Status

Skeleton — summarizer + prompt template + view scaffold. HealthKit calls
are stubbed behind a `HealthDataSource` protocol so the prompt logic is
unit-testable.
