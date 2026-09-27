# Balloon Rush - Vertical Slice v0.2

Professional Godot 4.2+ prototype for the first playable slice of Balloon Rush.

## What is implemented

- Portrait mobile project: 1080 x 1920 design resolution.
- Milo rises automatically while the balloon has air.
- One-hand left/right touch control plus A/D and arrow keys on desktop.
- Air drains over time and small bubbles restore part of it.
- At 0 air, Milo loses the balloon and enters a 3.5 second rescue fall.
- A rescue balloon is generated below Milo during a fall.
- Milo keeps horizontal control while falling and must avoid hazards.
- Coins are collected during the run and saved after the run finishes.
- Procedural chunk generation with a guaranteed safe lane per obstacle row.
- Static platforms, spikes, and patrolling drones.
- Current altitude, run coins, air, low-air warning, and fall countdown HUD.
- One rewarded-ad revive per run.
- Debug builds simulate a completed rewarded ad safely.
- Revive restores 100 percent air and grants 2 seconds of invulnerability.
- Second death ends the run.
- One personal record: maximum height reached.
- Persistent record and wallet coins.
- Reference art is stored under docs/reference but is not wired into gameplay yet.

## Open the project

1. Extract the folder.
2. Open Godot Project Manager.
3. Import `project.godot`.
4. Run the project with F6/F5.

Desktop controls:
- A or Left Arrow: move left.
- D or Right Arrow: move right.

Mobile controls:
- Touch the left half of the screen to move left.
- Touch the right half of the screen to move right.

## Important architecture rule

Gameplay, persistence, ads, UI, world generation, and player states remain separated. Final 2D art can replace the placeholder polygons without rewriting gameplay logic.

## AdMob status

The project does not call live ads. `AdManager` is an integration boundary. Debug builds simulate the reward callback. When a production AdMob plugin is selected, only `AdManager` should need provider-specific code.

## Next production milestone

1. Test the movement and 3.5 second fall on a real phone.
2. Tune air drain, rise speed, fall speed, and rescue balloon distance.
3. Replace Milo placeholder art with the approved 2D cartoon assets.
4. Add final Zone 1 background layers and VFX.
5. Add audio and haptics.
6. Add shop/upgrades after the core loop feels good.
