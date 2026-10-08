# Riftborn movement reuse notes

Source reviewed: `Riftborn chat.rbxlx`.

## Key finding
The old game's movement presentation is not primarily a set of uploaded locomotion animations. A large part of the look is procedural and driven by a `MovementPoses` module layered after the normal Roblox Animator each frame.

The procedural pose system includes:
- Naruto-style sprint arm/torso pose
- windmill/double-jump arm motion
- superhero landing pose
- long-jump charge crouch
- wall-run hand/body pose
- ledge-climb pose
- vault pose
- front flip/root rotation
- root lean/drop blending

The movement controller also reuses the character's normal `Animate/run` Animation for the wall-run leg cycle, falling back to Roblox animation `913376220` if no run Animation is found.

## Rebuild direction
1. Preserve the movement-pack physics we already like.
2. Reuse the Riftborn procedural pose layer for arms/torso/root presentation where appropriate.
3. Use owned locomotion animations for the lower-body run/jump/fall/land layer.
4. Keep these presentation layers separate so we can tune them without changing physics.
