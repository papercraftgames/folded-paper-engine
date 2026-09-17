# Character blending and three-stage jump animations

## Install and assign animations

Extract the Godot ZIP into the project root so it replaces
`addons/folded_paper_engine`. Restart the running game after updating the addon.
Use the matching patched Blender addon and assign distinct clips under Character:

| Blender field | Playback |
| --- | --- |
| Jump Animation | Initial takeoff, played once |
| Air Control Animation | Loops after takeoff until physical ground contact |
| Land Animation | Plays once on landing, then returns to Idle/Walk/Run |

Export the scene again with Custom Properties enabled. The metadata keys are
`JumpAnimation`, `AirControlAnimation`, and `LandAnimation`. New clip assignments
must be present in the exported scene; installing the plugin does not create or
split animation assets.

Jump and Land use one-shot playback, and Air Control loops regardless of the
imported Loop setting. Walking off a ledge skips takeoff. Landing during a short
jump interrupts takeoff; jumping again interrupts Land. On contact, Land and the
currently requested Walk, Run, or Idle animation play simultaneously at 80%/20%
weights by default. Land then fades to 0% while locomotion reaches 100%, without
passing through an unwanted Idle state. A short entry blend preserves the exact
Air Control pose, and the locomotion playback phase is preserved when the mixer exits.

Blank or unresolved Air Control holds the completed Jump pose. Blank or unresolved
Land returns directly to locomotion. With neither new clip available, existing
single-Jump setups retain their previous behavior. Choose a short takeoff clip so
it can finish before a normal jump lands.

## Original problem

FPE currently switches character animations by stopping the previous clip and
starting a different AnimationPlayer. Idle, Walk, Run and Jump therefore snap
between poses. The jump state also uses the movement raycasts: the stock capsule
extends 0.46 units below its center, while its probes extend 0.56 units. These
probes can select a grounded animation before the capsule actually lands.

## Implemented behavior

- Combine only each character's configured clips into one AnimationPlayer after
  their track paths are repaired. Keep the animation-name map and independent
  scene animation players. Staged jump playback sets its required loop modes.
- Crossfade character state changes using Godot's native `play` blend argument,
  without stopping the outgoing clip. `CharacterControls.animation_blend_time`
  defaults to **0.15 seconds**; set it to **0** to disable blending.
- The transient landing mixer starts at `landing_initial_weight` (default **0.8**),
  leaving 20% for the requested Walk, Run, or Idle clip. Land fades to zero over
  `landing_weight_fade_time` (default **0.2 seconds**) while both clips advance.
- `landing_entry_blend_time` (default **0.08 seconds**) smooths Air Control into
  the 80/20 composite; mixer handoff seeks locomotion to its existing phase.
- Blend skeleton rotations around the currently visible pose. Godot's default
  rest-relative rotation blending can spin a bone through a full turn when both
  clips are near 180 degrees from its rest pose. `CharacterAnimationPlayer`
  temporarily changes the rotation reference during mixing and restores it after
  the mixer applies the result, without changing animation keys or bone rests.
- End the airborne stage from a supporting physics contact or the same downward
  ground probes used by movement, so controls and animation agree about landing.
  Check normals against the character's up direction so walls do not count as
  floors, and ignore stale launch probes while rising. Rotated rigs remain supported.
- Select Jump immediately when the stock controller applies a takeoff impulse.
  On completion, blend into Air Control; on landing, blend into Land. Pause/resume
  preserves one-shot stages. Ignore departing contact reports immediately after
  takeoff so they cannot briefly trigger Land.
- Make pause/resume, stop-by-name and frame-event dispatch distinguish the active
  clip when several animation names now reference one player. Only the latest
  state requested while paused resumes.

The patch does not retime authored keys inside a clip.

## Files

- `Engine/Features/Animation/AnimationUtils.gd`: character clip grouping and
  shared-player-aware playback controls.
- `Engine/Features/Animation/CharacterAnimationPlayer.gd`: continuous skeletal
  rotation blending across the +/-180-degree boundary.
- `Engine/Features/Object/Character/CharacterControls.gd`: blend duration,
  staged transitions and contact-based animation state.
- `CharacterConfig.gd` and `CharacterAnimationConfig.gd` in the same directory:
  read and store the new Blender fields.
- `Engine/Features/Animation/FrameEventRunner.gd`: dispatch events only for the
  selected clip, resetting inactive clips' event cursors.
- `tests/character_animation_test.gd`: headless regression test.

## Validation

Run from a Godot project containing the addon:

```text
godot --headless --path . --script res://addons/folded_paper_engine/tests/character_animation_test.gd
```

Verified with Godot 4.7.2 and Jolt Physics: intermediate blend poses, landing
blends after a one-shot finishes, independent player mappings, inactive-clip
commands, global pause/resume, transitions requested while paused, frame-event
isolation, premature ground-probe hits, complete jumps, and rotated-rig landing.
Stage tests cover Jump -> Air Control -> Land -> locomotion, a real physics jump,
short jumps, walking off ledges, interrupting Land with another jump, missing
clips, loop-mode enforcement, and paused takeoff/landing clips.
Rotation regressions cover both directions across +/-180 degrees, interrupted
blends, stop/pause/resume, unchanged bone rests, and skeleton motion scale.
The rotation test fails without the fix. All 48 transitions between the actual
Gami Idle/Walk/Run/Jump clips at four source phases passed; the largest accumulated
torso rotation over a transition was 19.13 degrees, with no full-turn spins.
A separate copy of the Gami scene also passed runtime checks for shared character
clips and a complete jump/airborne/landing sequence. Visual feel still needs an
interactive playtest; this validation checks poses and runtime states.

## Research

Checked September 17, 2026. Installed plugin version: 1.0.11. The public upstream
scripts still use the same separate-player and stop/start approach at review time.

- [FPE character/player documentation](https://foldedpaperengine.com/docs/fpe-characters-players-and-cameras.html)
- [FPE AnimationUtils API](https://foldedpaperengine.com/godot-api-docs/AnimationUtils.html)
- [Upstream CharacterControls](https://github.com/papercraftgames/folded-paper-engine/blob/main/src/Game/addons/folded_paper_engine/Engine/Features/Object/Character/CharacterControls.gd)
- [Upstream AnimationUtils](https://github.com/papercraftgames/folded-paper-engine/blob/main/src/Game/addons/folded_paper_engine/Engine/Features/Animation/AnimationUtils.gd)
- [Godot AnimationPlayer blending](https://docs.godotengine.org/en/stable/classes/class_animationplayer.html#class-animationplayer-method-play)
- [Godot's rest-relative rotation blending](https://docs.godotengine.org/en/stable/tutorials/animation/animation_tree.html#for-better-blending)

This is a local patch and proposal; it has not been submitted upstream.
