# ChainTimer

An Android app (Flutter/Dart) for building **timer chains** — a named,
ordered list of individual timers that run automatically one after another.
Handy for interval workouts, cooking sequences, focus/Pomodoro routines, or
anything with back-to-back timed stages.

## Features

- **Chains of timers** — each chain is a sequence of steps, each with its own
  name and duration.
- **Automatic sequencing** — when one timer ends, the next starts on its own;
  a haptic + sound cue fires at every hand-off and at completion.
- **Live run screen** — a countdown ring for the current step, an "up next"
  hint, overall chain progress, and a step counter.
- **Full playback control** — pause/resume, skip to next, restart the current
  step (or jump back), and restart the whole chain.
- **Reorderable editor** — add, rename, re-time, drag to reorder, and remove
  timers. Chains are reorderable on the home screen too.
- **Local persistence** — chains are saved on-device via `SharedPreferences`
  (JSON), so they survive restarts.
- **Screen stays awake** while a chain is running (`wakelock_plus`).
- **Material 3** UI with light and dark themes.

## Project layout

```
lib/
  main.dart                       App entry point + MaterialApp/theme wiring
  theme.dart                      Material 3 light/dark themes
  models/
    timer_step.dart               A single timer (label + duration) + JSON
    timer_chain.dart              An ordered list of steps + JSON
  services/
    chain_storage.dart            Load/save chains to SharedPreferences
    chain_run_controller.dart     Sequential run engine (tick, pause, skip…)
  providers/
    chains_provider.dart          App state: the saved list of chains
  screens/
    home_screen.dart              List of chains; create/edit/delete/run
    chain_editor_screen.dart      Build/edit a chain and its timers
    run_screen.dart               Run a chain with countdown + controls
  widgets/
    duration_picker_sheet.dart    h:mm:ss duration picker bottom sheet
  utils/
    format.dart                   Duration formatting helpers
    id.dart                       Local id generation
test/
  models_test.dart                Model JSON + duration formatting
  run_controller_test.dart        Sequencing/pause/skip logic (fake clock)
  app_smoke_test.dart             Widget test: empty state → create → list
```

## Running

Requires the [Flutter SDK](https://docs.flutter.dev/get-started/install)
(Dart 3.12+) and the Android toolchain.

```bash
flutter pub get
flutter run           # on a connected device / emulator
flutter test          # run the unit + widget tests
flutter analyze       # static analysis
flutter build apk     # build a release APK
```

## Timekeeping note

The run engine anchors each step's countdown to a target wall-clock time
(via the `clock` package) rather than counting ticks, so the remaining time
stays accurate even if the periodic ticker fires irregularly. Using
`package:clock` also makes the sequencing logic testable under
`fake_async`.
