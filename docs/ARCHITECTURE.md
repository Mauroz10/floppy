# Architecture

## Runtime flow

`Main` wires the scene-level systems together.

- `PlayerController`: player-facing API and physical body.
- `PlayerStateMachine`: owns Inflated, Falling, and Dead states.
- `AirComponent`: air resource only; it does not know about UI or ads.
- `WorldGenerator`: deterministic chunk generation and rescue balloon placement.
- `GameManager`: run state, peak height, run coins, one-revive rule.
- `SaveManager`: persistent wallet coins and personal record.
- `AdManager`: provider boundary for rewarded ads.
- `BalloonHUD`: presentation and user actions only.

## Death and revive

1. Hazard or fall timer calls `PlayerController.kill()`.
2. Player enters Dead and emits `died`.
3. Main asks `GameManager` to process the death.
4. First death enters `AWAITING_REVIVE`.
5. HUD can request a rewarded ad through `GameManager`.
6. `AdManager` emits the reward only after completion.
7. `GameManager` marks revive used and emits `revive_granted`.
8. Main revives Milo in a generator-provided safe lane.
9. Any later death finishes the run.

No ad callback directly edits the player.

## Procedural fairness

The generator uses five horizontal lanes. Every row reserves one lane as the safe corridor. The safe lane moves at most one lane between rows, reducing impossible jumps. Hazards are only placed outside the reserved lane.

The current implementation is intentionally conservative. Later worlds can use profile Resources to define hazards and difficulty without duplicating generator logic.
