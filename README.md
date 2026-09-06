# NewQuest

An independent Roblox starter for the custom anniversary quest place.

Includes the reusable cutscene runner and steps, a self-contained cinematic bars
helper, a small CutsceneManager, and a camera-only QuestIntro example. There are
no external packages. The scripts are installed in the existing Untitled Experience Studio place
(place ID 86817137440978). This repository manages code and sample camera markers;
the existing terrain, buildings and map assets remain managed in Studio.

## Open and try it

1. Switch to **Untitled Experience** in Roblox Studio.
2. Press **Play**, wait for your character, then click **Play example cutscene**.
3. The camera moves between two shots. Use **Skip** to cancel, or let it finish.
   Movement, prompts, camera and field of view are restored afterward.
4. Stop Play before editing. The preview button appears only in Studio.

For ongoing editing, run `rojo serve` in this repository and connect the Rojo
Studio plugin to **NewQuest** in Untitled Experience. Review the initial sync.
The project maps only starter code and sample markers, preserving other Studio
instances. It is not a backup of the map; save the place in Studio too.

The tool versions are listed in `aftman.toml`. There is no package-install step.
A code-only build check can be run with:

```powershell
New-Item -ItemType Directory -Force build | Out-Null
rojo build default.project.json --output build/NewQuest.rbxlx
```

This build does not contain your Studio map. Keep developing in the existing place.

## Play a scene from quest code

Call from a LocalScript after the player's character is ready:

```lua
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local CutsceneManager = require(ReplicatedStorage.Modules.CutsceneManager)
local QuestIntro = require(ReplicatedStorage.Cutscenes.QuestIntro)

local status, reason = CutsceneManager.Play(
    QuestIntro(workspace.CutsceneMarkers.Intro)
)
if status == 'Failed' then
    warn(reason)
end
```

`Play` yields and returns `Completed`, `Cancelled`, `Failed`, or `Busy`.
Call `CutsceneManager.Cancel('Skipped')` to cancel; do not cancel the playback
coroutine. Death, character replacement and camera replacement also cancel safely.

Author scenes under `src/ReplicatedStorage/Cutscenes`. Each scene has an ordered
`Steps` array. Available steps: Camera, Wait, Move, Call, Dialog, Animation and
Sound. This starter has no dialogue screen; Dialog requires a presentation adapter
passed to `Cutscene.new({ Adapters = { Dialog = ... } })`. Use the low-level runner
for custom setup, or extend the manager when that UI is designed.

Use `context:Wait`, `context:Tween` and `context:Await` in asynchronous custom
steps so cancellation works. Register temporary changes with `context:Set` or
`context:Defer`; cleanup callbacks must not yield. The runner restores temporary
actor moves, sounds, animations, camera and other registered state after a scene.

The example uses the positions of Wide, CloseUp and Focus under
Workspace.CutsceneMarkers.Intro. Orientations are calculated to face Focus.
Edit their initial values in default.project.json when using Rojo.

## Verification

Run `selene src` for lint checks. The existing runner checks are included and
never run automatically. In a Studio Play session, use the **client** Command Bar:

```lua
require(game.ReplicatedStorage.Modules.Cutscene.Tests)()
```

Expected output: `Cutscene tests passed`. This checks ordering, camera cleanup,
overlap rejection, cancellation, failure recovery, callback timeout, tween
cancellation and destruction. Also try the visual example and Skip.

Verified in Untitled Experience on 2026-09-06: runner checks passed, the preview
completed and skipped through its UI, and live client probes confirmed camera,
FOV, prompt, movement-binding and UI cleanup on completion, cancellation and
failure. Selene and the code-only Rojo build passed. Death/respawn, camera
replacement, mobile/gamepad input and custom dialogue/audio adapters were not
exercised in this verification pass.

## Connect the destination later

Untitled Experience currently belongs to universe 10764817039, while BA Staging 1
belongs to universe 3613283495. For the originally planned same-experience travel,
save/publish the finished quest as a place within the intended Berry Avenue
experience, then configure that destination place ID in Berry Avenue. This setup
does not change the entrance destination or publish either place.

This project intentionally starts without quest persistence, inventory, rewards
or Berry Avenue services. The old QuestService's second objective is not loaded
here. Arrival, subsequent objectives and any save/reward contract will be
implemented in this project's own server code as the quest is designed.
Client cutscenes do not grant rewards or authorize quest completion.
