# QA Checklist - Wavedash Achievements (Iteration 1)

## Scope
- Active achievement in this iteration: `bienvenida_ruka`.
- Backlog achievements remain documented but inactive.

## Functional checks
- [ ] Start game from menu (`New Game`) and verify the event `run_started` is emitted.
- [ ] Confirm `bienvenida_ruka` unlocks only once on first run start.
- [ ] Restart game and start another run; verify it does not unlock again.
- [ ] Open Achievements screen and verify summary shows `1/1` after unlock.
- [ ] Verify backlog list is visible and marked as TODO entries.

## Wavedash sync checks
- [ ] With Wavedash SDK available in autoload, verify unlock is queued and sent through `set_achievement`.
- [ ] Verify `store_stats` is called when available.
- [ ] With SDK unavailable, verify no crash and queue remains pending.

## Regression checks (gameplay safety)
- [ ] Main menu still navigates New Game, Options, Credits, Exit.
- [ ] Retry from Game Over still returns to level scene.
- [ ] No combat/movement/damage/generation behavior changed.

## Notes
- This checklist is intentionally manual to keep integration low risk in jam cadence.
