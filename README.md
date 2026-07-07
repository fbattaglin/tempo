# 🎵 Tempo

**A native macOS metronome that doesn't bother your CPU or your ears.**

No Electron, no web framework hiding under the hood, no 200MB just to play
a click. Just SwiftUI + `AVAudioEngine`, a pendulum that swings *exactly*
in time with the audio (because both are driven by the same clock), and
an interface that fits in the palm of your hand — literally, it's a tiny
window.

---

## ✨ What it does

- 🎯 **30–240 BPM**, via slider, numeric field, ↑/↓ on the keyboard, or by
  dragging the pendulum weight (just like a real mechanical metronome:
  weight near the pivot = fast, farther out = slow).
- 🕰️ **Pendulum genuinely synced to the audio** — not two separate timers
  hoping to stay aligned. Both read the same sample-time clock, so they
  never drift apart, even after playing for hours.
- 👆 **Tap tempo** — tap along (button or `T` key) and it works out the BPM.
- 🎼 **Time signatures** from 2/4 to 12/8, with an accent on the downbeat.
- ⚙️ **Configurable default BPM** (⌘,) — landed somewhere and want to get
  back? One click or `⌘0`. You decide what that number is, not me.
- 📊 **Menu bar mode** — runs without even opening the main window.
- 🌗 Dark mode, light mode, native keyboard shortcuts — everything a real
  macOS app should do.

## 🧠 Why the timing never drifts

The classic software-metronome trap: firing each click from a `Timer`.
Timers jitter, delay accumulates, and after a few minutes the "click" no
longer lines up with the "tick." Not here — the audio engine **schedules
clicks with sample-accurate precision** straight on `AVAudioEngine`, using
a floating-point accumulator that never lets rounding snowball. There's
even an automated test guarding this (see
`TempoTests/BeatClockTests.swift`).

## 🚀 Running the project

You'll need Xcode 15+ and [XcodeGen](https://github.com/yonaskolb/XcodeGen)
(`brew install xcodegen`) — the `.xcodeproj` isn't committed, it's
generated from `project.yml`.

### Easiest path: install it directly

```sh
./install.sh
```

Builds everything (universal, arm64 + x86_64), signs it, and installs
straight into `/Applications`, replacing whatever was there. Opens the app
on its own at the end. No dmg, no dragging icons.

To confirm you're on the latest build: **Tempo menu → About Tempo**. Each
build is stamped with a number like `20260705.211212` (date + time) —
does it match what the script printed? You're on the right version.

### Just to open in Xcode and hack on the code

```sh
xcodegen generate
open Tempo.xcodeproj
```
⌘R and you're set.

### Tests

```sh
xcodebuild -project Tempo.xcodeproj -scheme Tempo -configuration Debug -destination 'platform=macOS' test
```

### Building a real `.dmg` (for distribution)

```sh
Packaging/build_dmg.sh
```

The app is **ad-hoc signed** (no paid Apple Developer account). If someone
installs it from a downloaded `.dmg`, Gatekeeper will complain about an
"unidentified developer" the first time it's opened — right-click the icon
→ **Open** → confirm. Only happens once.

## 🗺️ Architecture, behind the curtain

| File | What it does |
|---|---|
| `Tempo/Audio/MetronomeEngine.swift` | The heart: schedules sample-accurate clicks on `AVAudioEngine`, never stops the engine between pauses (only the player), so resuming is instant. |
| `Tempo/Audio/BeatClock.swift` | The single source of truth for "what time is it" — translates audio sample-time to host-time, so the UI can read it without touching the audio thread. |
| `Tempo/Views/PendulumView.swift` | The pendulum. Interpolates between the last two beats published by `BeatClock` — zero timing logic of its own. |
| `Tempo/ViewModel/MetronomeViewModel.swift` | Observable state: BPM, time signature, play/pause, tap tempo, all persisted. |
| `Tempo/Views/SettingsView.swift` | The preferences screen (⌘,) where you set your default BPM. |

## ⌨️ Shortcuts

| Shortcut | Action |
|---|---|
| `Space` | Play / Pause |
| `↑` / `↓` | BPM ±1 |
| `⇧↑` / `⇧↓` | BPM ±5 |
| `⌘0` | Reset to default BPM |
| `⌘,` | Preferences |
| `T` (or the TAP button) | Tap tempo |

---

*Built to be light, fast, and stay out of your way — the metronome is the
accompanist, not the star.*
