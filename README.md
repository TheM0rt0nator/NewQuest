# NewQuest

Single-player anniversary quest destination, designed to run in the same Roblox
universe as Berry Avenue. Connected development target: **Anniversary Quest**, place
101522826150554.

## Try chapter one

Press **Play** in the selected Studio. At the classroom quest step, the player is
seated at the middle-row desk before the opening shot is revealed. Movement and
jumping are disabled during preparation and playback. Ms Taylor asks
Maya what she wants to be, then introduces the doctor chapter. After the doctor
shift, the classroom resumes with Leo's ambition to become a police officer.

Dialogue advances automatically. Click **Continue** to reveal the line, then again
to advance early. **Skip** finishes the introduction checkpoint. The intro starts
automatically on joining only while the active anniversary adventure is at
destination state 1. Later, inactive, or completed quests cannot start it, even
through the seating remote. A retry is available only while that step is current.
Death, failure, or other cancellation releases the seat without advancing progress.

The classroom leads directly into the doctor shift. NPC names and classroom
dialogue are editable in `src/ReplicatedStorage/Cutscenes/ClassroomIntro.lua`.

## Doctor shift

The existing hospital bed near `(541, 20, 465)` is used for the patient. The added
`Workspace.DoctorQuest` model contains the patient, six supply trays, care board,
monitor display, and arrival/camera markers. Its HospitalBed ObjectValue references
the original bed. The hospital itself is preserved.

After a short patient cutscene, collect the item named on the board with its prompt,
then return to the patient and use the treatment prompt. Medicine, shock, scalpel,
bandage, blood bag, and injection each appear once, with Shock kept last. Each
treatment plays an eight-second arm gesture; six treatments plus collecting and
walking are intended to take roughly one to two minutes. The current destination
is highlighted and the held item is visible in the player's hand.

The monitor beeps more slowly after each treatment. At five of six treatments
(the first whole-task checkpoint at or above 75%), it flashes red. After the sixth,
the monitor returns to its normal green display and beep interval. The board shows
that the patient is stable and the doctor shift is complete.

`DoctorQuestConfig.lua` defines the tasks, timings, colours, warning threshold, and
beep asset. The treatment gesture supports both Motor6D and AnimationConstraint
avatars using client-side Transform evaluation after the Animator, following
[Roblox's AnimationConstraint guidance](https://create.roblox.com/docs/reference/engine/classes/AnimationConstraint).
Pickup and treatment use [proximity prompts](https://create.roblox.com/docs/ui/proximity-prompts)
with server checks for the current task, held item, distance, and character state.

## Police booking

Leo's classroom scene leads into a walking entrance at the existing police station.
The player and handcuffed suspect enter together with controls locked. The suspect
then walks between booking, fingerprint, mugshot, and holding-cell checkpoints.
Search uses six 3D props attached to the suspect: phone, wallet, keys, lockpick,
radio, and watch. Click or touch a prop and drag it clear of the body to confiscate
it. Short drags return the prop. Each confiscation saves immediately, so collected
props remain hidden when the search resumes. Scan and photo use buttons. The cell
requires separate open, escort, and close interactions before returning to the
existing classroom finale.

Walking uses `Humanoid:MoveTo()` through editable corridor markers, with one
continuous animation per route. There is no runtime pathfinding or position
snapping. Long walks renew MoveTo before its engine timeout. NPC body collisions
stay disabled during humanoid updates, and falling/ragdoll states are disabled.

The existing dream effect covers both police chapter boundaries before server
placement, then reveals the station or seated classroom shot. The completion
checkpoint waits for this covered handoff rather than teleporting on a server timer.
`QuestUI.lua` builds the booking and objective UI from native frames, text,
padding, and borders, using the pale colours and Arcade font of NPCChat.

`Workspace.PoliceQuest` contains editable `Markers`, `Stations`, `Evidence`, Leo, the suspect,
and a reference to the existing `PoliceStation.Interactables.Doors.Door52` cell.
The mugshot uses the station's existing backdrop. Route doors open only at runtime.
`tools/BuildPoliceQuest.lua` recreates the initial setup only when PoliceQuest does
not already exist; later Studio layout edits take precedence. Save the place in
Studio to retain these map additions.

`PoliceEvidence.lua` installs missing evidence models without replacing existing
Studio props. Each model is massless and welded to its body part, with collisions
disabled. `PoliceSearch.lua` raycasts the visible geometry and moves a local 3D
copy during dragging, keeping the suspect's physics stable. The search camera
includes the chest, wrists, and pockets; the booking UI retains its title and count.

For a temporary Studio-only police test, set the Workspace boolean attribute
`StudioPoliceTest` to true before Play. Fresh mock profiles start at the entrance;
existing checkpoints are preserved. Remove the attribute afterward. It has no
effect outside Studio. Normal play keeps the hospital and Leo classroom sequence.

## Shared quest data

`QuestService` uses Berry Avenue's installed ProfileStore 1.0.3, the same
`PlayerData_LIVE` store, and the same `Player_<UserId>` keys. It loads the full
profile and preserves unrelated fields and quests. ProfileStore manages session
ownership, autosaving, and saving/releasing the profile when the player leaves.

The entrance's outer `Quests.AnniversaryQuest.State` remains the adventure state
(`Id = 2`). This place stores its chapter progress separately inside:

```lua
data.Quests.AnniversaryQuest.Destination = {
	Version = 1,
	State = {
		Id = 1,
		Progress = 0,
		Goal = 1,
		Description = "Listen to your classmates' dreams",
	},
}
```

Stages are defined in `src/ReplicatedStorage/Modules/AnniversaryQuestConfig.lua`:

- `ClassroomIntro` (1): listen to the class; resume at `Arrival` and start the scene.
- `YourFuture` / `DoctorIntro` (2): retains the original saved ID and key; now
  resumes at DoctorQuest.Arrival and introduces the patient.
- `DoctorTasks` (3): resumes in the hospital with the saved task order, completed
  count, and held item. An interrupted treatment must be performed again.
- `DoctorComplete` (4): resumes at the hospital with the patient stable.
- `PoliceClassroom` (5): Leo's existing classroom scene.
- `ClassroomFinale` (6) and `QuestComplete` (7): existing finale and completion IDs.
- `PoliceIntro` (8): station entrance; interrupted entrances restart here.
- `PoliceSearch` (9): saves each confiscated item in `Destination.Police.Confiscated`.
- `PoliceFingerprints` (10) and `PoliceMugshot` (11): resume at their stations.
- `PoliceOpenCell` (12), `PoliceEscortCell` (13), and `PoliceCloseCell` (14): restore
  both the suspect's checkpoint and the appropriate door position.
- `PoliceComplete` (15): returns to classroom finale (6).

The sequence is 1–5 → 8–15 → 6–7. New police IDs are appended so older saved
classroom/finale checkpoints keep their original meaning.

Finishing or deliberately skipping the classroom intro advances Destination.State
to 2. It does not complete the entire anniversary quest or grant a reward.
The doctor's shuffled order and carrying flag are saved in `Destination.Doctor`;
the completed treatment count is `Destination.State.Progress` during state 3.
Returning players load the checkpoint and move to that stage's resume marker.
The same restoration runs on respawn and when the server advances to a new stage.

Server gameplay code can use:

```lua
local QuestService = require(game.ServerScriptService.QuestService)
local QuestConfig = require(game.ReplicatedStorage.Modules.AnniversaryQuestConfig)

local quest = QuestService:GetQuestData(player, "AnniversaryQuest")
local chapter = quest.Destination.State

-- Report progress only after validating the corresponding gameplay event.
QuestService:CompleteObjective(player, "AnniversaryQuest", QuestConfig.States.ClassroomIntro)
```

`GetQuestData` returns a copy. `SetState` advances only to the next configured
destination objective. `CompleteObjective` checks the expected state, so repeated
or late callbacks cannot advance the next stage. `StateChanged` notifies server
stage handlers. Append future objectives to AnniversaryQuestConfig, give each one
a stable ID and resume marker, and implement its gameplay handler. Do not renumber
saved states. Completing a job does not complete the entire anniversary quest;
the existing finale and return handler own final completion.
Clients cannot select arbitrary states. Cutscene reports and item prompts are
validated against the current server session and quest checkpoint.

Studio always uses **ProfileStore.Mock**. Tests never load or change live player
profiles. Mock progress survives profile release/reload within that Play session
and resets when Play stops. Live cross-place handoff still needs verification
after the destination is placed in the final universe and published by you.

## Studio assets and source

The existing school, terrain, buildings, and original SpawnLocation are preserved.
`Workspace.ClassroomIntro` contains the added NPC cast and camera markers. It uses
Persistent streaming mode; the client also requests the classroom area before
showing the scene. The original disabled school seats are untouched. A temporary
server seat seats the player and is removed afterward.

The six student NPCs use R15 rigs. They and the player use the looping sitting pose
`rbxassetid://134259979568724`, configured in `ClassroomSitting.lua`. The player must
use R15 for this animation. Their sitting track is stopped when the seating session
ends; the students keep their pose and Ms Taylor remains standing.

The map and classroom cast are managed in Studio. Save the place there. The
repository is not a backup of the full map. `tools/BuildClassroom.lua` contains the
reproducible initial cast/marker builder; run it only in Edit mode when
ClassroomIntro does not already exist. Later Studio appearance edits take
precedence over that initial builder.

`tools/BuildDoctorRoom.lua` is the equivalent one-time builder for the doctor props.
It refuses to replace an existing DoctorQuest model. Save the place in Studio to
retain the installed props and any subsequent layout edits.

`rojo serve` syncs code and the old example camera markers into the selected place.
Review its initial sync. The project preserves unknown map instances. The older
camera-only QuestIntro example and reusable runner remain available.

The reusable CutsceneManager now includes CutsceneDialogue. Scenes contain an
ordered Steps array; custom asynchronous steps should use context:Wait/Tween/Await.
Register temporary state using context:Set or context:Defer. Cleanup must not yield.

## Formatting and checks

Follow [Roblox's Luau style guide](https://roblox.github.io/lua-style-guide/).
Project code uses tabs, expanded blocks, readable spacing, and a 100-column target.
StyLua settings are in `.stylua.toml`; the vendored ProfileStore source is unchanged.

```powershell
stylua --check src tools
selene src tools
New-Item -ItemType Directory -Force build | Out-Null
rojo build default.project.json --output build/NewQuest.rbxlx
```

The build contains code and example markers, not the Studio map.

Manual checks, during Play when no cutscene is active:

```lua
-- Client Command Bar:
require(game.ReplicatedStorage.Modules.Cutscene.Tests)()

-- Server Command Bar (Studio mock profiles only):
require(game.ServerScriptService.QuestServiceTests)()
```

Verified: full playback, seating before reveal, locked movement/jumping, Skip, state 1-to-2 advancement,
camera/control/dialogue cleanup, death/respawn recovery, runner regressions, invalid progress rejection,
mock profile reload, and preservation of unrelated shared-profile data.
Doctor checks: classroom-to-hospital transition, patient intro, prompt pickup and
treatment, six-task completion, wrong-item/distance/duplicate rejection, warning at
5/6, normal monitor at completion, interruption/respawn with a held item, and mock
profile reload of the shuffled order, carried item, and completed shift.
Live DataStore/teleport handoff and mobile/gamepad layouts remain untested.

Police checks in the connected Studio: Leo classroom-to-police transition, both
entrance walks, automatic station routes, all six mouse drags, scan and photo
buttons, open/escort/close cell prompts, and return to the existing finale.
Death during a partial search restored the checkpoint and confiscated item.
Mock profile tests cover every booking checkpoint, duplicate/unknown items, and
preservation of unrelated profile fields. Station-to-station player travel was
accelerated with test teleports; NPC routes were exercised through gameplay.
Direct-walk regression checks: entrance, every booking station, the corridor to
the cell, and escort inside completed without pathfinding. Runtime monitoring
recorded no collidable NPC parts or tipping during these walks. Both police dream
handoffs were opaque at the chapter change; the finale completed afterward.
Normal classroom-to-doctor startup also passed with the shared transition changes.

3D search checks: all six props were selected and dragged with mouse input, a short
drag kept progress unchanged, and the last confiscation advanced to fingerprints.
A mock profile reload at 2/6 kept both collected props hidden. Respawning during a
drag removed the temporary model, restored the camera and original prop visibility,
and preserved progress. The checkpoint/profile regression suite also passed.

Pointer regression: real OS cursor drags reproduced a top-bar offset that virtual
MCP mouse inputs did not expose. InputObject positions now use ScreenPointToRay;
hover positions subtract the GUI inset to use the same coordinate space. All six
props passed real cursor drags, including a cancelled short drag and completion
through to fingerprints.

Recurring effects follow the active chapter. The doctor monitor connects during
states 2–4, and its pose callback connects only during treatment. Police pose and
collision callbacks connect during states 8–15. These connections disconnect on
chapter exit, death, or character removal and resume once per character. Police
hints/highlights use attribute and UI events instead of a Heartbeat callback.
Readiness events replace police startup polling; search hover remains scoped to
the open search panel. Cutscene, movement, and treatment waits last only for the
operation that owns them.

Lifecycle checks in Studio used temporary connection/tick counters: zero active
chapter callbacks in the initial classroom, one monitor during the doctor chapter,
treatment callbacks only during treatment, and one pose/collision callback during
police booking. Death stopped the relevant callbacks and sound; respawn restored
one connection each. Completing both jobs disconnected every chapter callback on
the classroom return, with unchanged tick counters afterward. Booking hints and
highlights also updated correctly when opening and closing the search panel.

Git commits and pushes are handled manually by the user. This work does not
publish a Roblox place or change Berry Avenue's entrance destination.
