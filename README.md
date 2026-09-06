# NewQuest

Single-player anniversary quest destination, designed to run in the same Roblox
universe as Berry Avenue. Development target: **Untitled Experience**, place
86817137440978.

## Try chapter one

Press **Play** in the selected Studio. At the classroom quest step, the player is
seated at the middle-row desk before the opening shot is revealed. Movement and
jumping are disabled during preparation and playback. Ms Taylor asks
Maya, Leo, and Amira what they want to be: a doctor, pilot, and artist. Camera shots
and dialogue lead to the teacher asking the player the same question.

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
bandage, blood bag, and injection each appear once in a shuffled order. Each
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
saved states. Stages after the doctor shift are not defined yet. Completing this
job does not complete the entire anniversary quest or award its final reward.
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

Git commits and pushes are handled manually by the user. This work does not
publish a Roblox place or change Berry Avenue's entrance destination.
