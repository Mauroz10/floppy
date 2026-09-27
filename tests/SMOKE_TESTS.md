# Balloon Rush v0.2 smoke tests

Run these in order after importing the project in Godot.

## Boot
- Project opens without parser errors.
- Main scene starts in portrait orientation.
- Milo begins rising automatically.

## Input
- A/Left moves Milo left.
- D/Right moves Milo right.
- Touching either half of a phone screen moves in that direction.
- Milo cannot leave the horizontal play area.

## Air
- Air starts at 100 percent.
- Air decreases while inflated.
- Small bubbles restore air only while Milo still has a balloon.
- Low-air warning appears near the configured threshold.

## Fall rescue
- At 0 percent air, the balloon disappears.
- Milo starts falling and still has lateral control.
- A rescue balloon appears below.
- The rescue timer starts at about 3.5 seconds.
- Touching the rescue balloon returns Milo to inflated ascent.
- Missing the rescue window kills Milo.

## Hazards
- Static hazard blocks kill Milo.
- Spikes kill Milo.
- Drones patrol horizontally and kill Milo on contact.
- The safe route is never directly occupied by a generated hazard.

## Revive
- First death shows the revive choice.
- In a debug build, the video button simulates reward completion.
- Milo revives with full air.
- Milo ignores hazards for about 2 seconds after revive.
- A second death ends the run without another revive.

## Run results
- Game Over shows the maximum height reached.
- Game Over shows run coins.
- Only one personal record is stored.
- Run coins are added to the saved wallet once.
- Retry starts a fresh run while preserving the record and saved wallet.
