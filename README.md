# Digital Pet — Activity 07

## Team 1: Care Systems

Simple Flutter app using StatefulWidget, setState, Timer, and a
TextEditingController. Team 2 personality and visual design are left for the
teammate.

- Confirm a pet name; reset preserves the name.
- Feed reduces hunger by 10. Resulting hunger below 30 costs 20 happiness;
  otherwise feeding adds 10 happiness.
- Play adds 10 happiness and 5 hunger. All meters stay between 0 and 100.
- Hunger increases by 5 every 30 seconds. A tick already at 100 hunger costs
  20 happiness; the tick that first reaches 100 does not.
- Win by keeping happiness strictly above 80 for three continuous minutes.
- Lose at 100 hunger and happiness at or below 10.
- Pause stops care and both timers. Resume begins fresh timer intervals,
  including a new three-minute win attempt.
- Reset restores both meters to 50 and restarts play from any status.

## Run and check

```sh
flutter pub get
flutter run
flutter analyze
flutter test
```

Widget tests advance simulated time with the production durations unchanged.
They cover naming, meter bounds, feeding thresholds, hunger ticks, win/loss,
pause/resume, reset, and disposal with active timers.

## Review

The initial main commit contains the existing Flutter starter. Team 1 changes
are on `team-1/care-systems` for teammate review before merging.
