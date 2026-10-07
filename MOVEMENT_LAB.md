# Movement Lab

This branch is the safe reconstruction workspace for the uploaded movement pack.

## Rules

- Preserve the original movement physics before tuning anything.
- Treat the extracted controller files under `src/reference` as read-only reference copies.
- Replace unavailable animation/audio assets with assets this project is authorized to use.
- Match the reference video's timing, state transitions, body lean, camera response, and overall feel first; customize only after the baseline is stable.

## Current movement stack

The original controller loads its animations from `CharacterHandler/Animations` through the Humanoid `Animator`. The movement physics already cover running, jumping, landing/rolling, sliding, wall-running, wall-jumping, double-jumping/boosting, camera updates, speed modifiers, and state gating.

## First milestone

1. Restore locomotion presentation with replacement animations.
2. Verify Idle -> Run -> Jump/Fall -> Land.
3. Verify Slide and Roll.
4. Verify Left/Right wall-run and wall-jump transitions.
5. Re-enable movement sounds/VFX with authorized assets.
6. Only then begin feel/tuning changes.
