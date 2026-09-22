# Secret quest: classic destination

The destination is **Secret**, place **78518778092310**. This handles the adventure
after teleporting through the tree. The Berry Avenue three-item entrance remains
separate. The anniversary source and project are preserved; nothing is published.

## Four puzzles

1. **Beachside Boutique:** equip the real [The Classic VIP T-shirt](https://www.roblox.com/catalog/17578965036/The-Classic-VIP)
   on the Roblox avatar, then touch the door. Catalog ID: **17578965036**;
   graphic ID: **17578964955**. The server checks the applied avatar description
   and its actual ShirtGraphic. There is no pickup, automatic outfit change or
   ownership-only shortcut. The free listing was verified on September 21, 2026.
   It changes from 55% to 75% transparent and becomes passable for two seconds,
   then closes. There is no door prompt. Later visits still require the equipped
   shirt. The first valid touch unlocks Sunset Clothing once. Noobs wear Headstack,
   The Classic ROBLOX Fedora, and The Classic's Agonizingly Happy Bucket prize.
   Both door faces show a red prohibition symbol (**🚫**), built from a circle
   and diagonal bar so it does not depend on emoji font support. Five additional
   noobs are scattered along the beachfront, crossings and shops; all are static
   anchored models. The three original boutique noobs remain.
   The event noob's [Agonizingly Happy Bucket](https://www.roblox.com/catalog/17521787511/Agonizingly-Happy-Bucket)
   is the reward earned for 10 Classic Tokens in The Classic
   ([event reward history](https://roblox.fandom.com/wiki/Catalog:Agonizingly_Happy_Bucket)).
   Its mesh and texture were checked against the actual catalog asset.
2. **Sunset Clothing:** rotate the four existing window mannequins to face the sea.
   Their original bodies and plinths are preserved. Added classic heads/faces make
   forward visible; sun motifs on the front of the plinths provide a visual hint.
3. **Nail Salon:** find five clue bottles spread across the salon's existing
   furniture. Read them left to right while facing into the shop from its entrance:
   **cyan, carnation pink, orange, medium green, dark indigo**. Enter the code using the original
   shelf bottles; duplicates of a colour are interchangeable. Five small lights
   show the five most recent inputs from left to right. Each new click shifts out
   the oldest input once the display is full. Entering the correct five colours
   consecutively succeeds at any point, even after mistakes or a partial attempt;
   there is no reset or fixed batch boundary. Partial correct codes do not give
   success feedback. Input history is saved. All fifteen bottles support
   clicks on bodies/caps and prompts. The scattered copies are visual clues only,
   with no prompts or click detectors. The sample hand has been removed.
   Four old decorative desk bottles are hidden to avoid a conflicting colour
   sequence; their original visibility and collision properties are retained.
   Bottle shapes and colours are unchanged. Each colour has a matching symbol
   on its shelf bottles, scattered clue bottle and entered-code display:
   cyan = star, pink = heart, orange = triangle, green = circle, indigo = cross,
   white = square. Prompts also name the symbol. The pixel symbols have fully
   transparent backgrounds so the polish colour remains visible. They use native
   UI frames and need no image assets or font glyphs.
4. **Juices & Smoothies:** recreate the sample drink with strawberry, banana and
   milk, in any order. Blueberry, orange, kiwi, pineapple and chocolate are decoys.
   Eight ingredients occupy two rows of trays. All 56 three-ingredient combinations
   are accepted as attempts, with exactly one successful combination.
   The sample's colour, garnish and cream provide the recipe clues. Eight
   differently coloured samples sit on the separate west-side counter around
   **(-675, 320, 157)**, away from the blender
   and ingredients. The correct pink strawberry sample sits **0.6 studs forward**
   of the other drinks. All have matching cups, cream and garnish.
   The four-puzzle completion opens the spawn portal.

The generated instruction boards and all five extra puzzle areas have been
removed, including the hotel gallery. Existing map signs are preserved.

## MQ entrance

The tree and four entrance anchors now have neutral instance names. Private
ObjectValues in **ServerStorage.SecretQuestBindings** identify the originals for
server code and editing. The hardening update preserves their current placement;
at installation the trunk was at **(-312.619, 81.521, 2582.383)**. The tree prompt
still appears within eight studs. All tree parts remain anchored. The tree and
item anchors use Atomic streaming instead of forcing the tree to every client.

**tools/RelocateMQSecretTree.lua** is an optional Edit-mode tool that moves the tree
back behind the campsite grove, at trunk base **(-1205, 57.96, 2105)**. It was not
run during the hardening update. Its original pivots and location notes now live
on the private references, rather than replicated map attributes.

## Physical smoothie interaction

Pick up one ingredient at a time. It disappears from its tray and welds to the
avatar's right hand (R15 or R6). At the blender, use the jug prompt to add it.
Fruit moves from the hand, rises over the jug, drops in and remains visible;
milk tilts and pours a visible stream. Once enough ingredients are present,
the green blend control closes the lid and spins the ingredients and blade while
the liquid appears. A wrong mixture stays visible until emptied. The red reset
control uses **R** / gamepad **Y** and restores the ingredients.

Held ingredients, committed jug contents and puzzle progress are saved.
Animations lock out duplicate interactions. Death, character removal, stopping
the service and leaving cancel effects and release temporary instances. An
interrupted drop never commits or consumes its ingredient; it returns to the
player's hand on respawn. There is no idle animation/frame loop.

## UI

The classic destination has no quest card, instructions, progress counter,
objective markers or direction beam. Only the active shop's existing signs glow,
using lit text, a neon border and warm sign lights. Earlier and later shops use
their original sign lighting. These update on stage changes without frame loops.
Finishing the fourth puzzle opens the return portal without a completion card.
Entering the portal confirms the saved completion, then awards/checks badge
**4162590358506538** before starting the anniversary quest's seven-second animation
with the same artwork, fireworks, fanfare and card motion. Its heading reads
**SECRET QUEST**, with **Your secret badge is claimed!** and **Returning to Berry
Avenue...**. The client acknowledges when playback finishes, and the server then
teleports. Early/stale acknowledgements are ignored; a bounded fallback prevents
a missing acknowledgement from stranding the player. Duplicate portal touches
cannot restart the process. Badge failures show a retry message without celebrating.
Teleport retries after the animation do not replay it in the same session.
Loading a completed save does not play the animation until portal entry.
Respawn, script destruction and session shutdown clean up active playback.
Return-portal saving, badge, teleport and error messages also use the anniversary
feedback styling. The MQ entrance's existing quest UI remains separate.

## Editing and installation

Use **secret.project.json**, not default.project.json.
The main files are:

- secret/server/Config.lua: private answers, route, coordinates, badge/return IDs.
- secret/shared/Config.lua: only the current place ID for the client entry point.
- secret/shared/AnniversaryQuestConfig.lua: only completion presentation settings.
- secret/server/PrivateState.lua: private references and original map properties.
- secret/server/World.lua: scene setup, original mannequin references and locks.
- secret/server/Props.lua: fruit, carton and blender geometry.
- secret/server/PolishSymbols.lua: colour-blind labels for bottles and code display.
- secret/server/Clues.lua: original shop signs, noob hats and the VIP-door visual.
- secret/server/VipShirt.lua: server-side equipped catalog T-shirt check.
- secret/server/Smoothie.lua: hand attachments, animation and visible jug state.
- secret/server/Progress.lua: puzzle rules and save migration.
- secret/server/Service.lua: server validation, persistence and completion.
- src/ReplicatedStorage/Modules/QuestCelebration.lua: shared completion animation;
  optional copy overrides leave the anniversary quest's default text unchanged.

Run tools/BuildSecretInstaller.ps1, then execute build/InstallSecretQuest.lua in
Secret's **Edit** datamodel. It verifies the place ID, creates a private rollback
copy, installs only quest source, and enables the two Secret entry scripts. It
preserves the existing legacy script/screen settings; anniversary isolation was
already applied in this place. It does not publish or save the place. Do not use
this update installer as an automatic anniversary-isolation tool in a new place.

Generated props are built under **ServerStorage.SecretQuestAssets** in Edit mode.
At runtime, the server places each stage's props into Workspace only when that
stage is unlocked. The portal stays private until all puzzles are solved. The
original window rigs and shelf polishes stay in Workspace. Server tables hold
their bindings and mannequin target orientations; original map properties are
retained under **ServerStorage.SecretQuestOriginals**. Prompts/click detectors are
attached only for the current stage. Five non-interactive bottle copies supply
the scattered colour clues. Generated instance names no longer number the clues,
identify the correct smoothie or expose step/action attributes.
Avoid deleting the original rigs. Update source placements before regenerating
manually moved props.

MQ has its own source snapshot under **mq/**. Run **tools/BuildMQPrivacy.ps1 -Stage**
and execute **build/StageMQPrivacy.lua** to validate cloned entrance objects and
private modules without changing the active map. **tools/BuildMQPrivacy.ps1**
generates the targeted installer; it backs up the affected modules and entrance
objects and preserves unrelated quest-service child modules. Its server config
owns the item/destination mapping. The shared config retains only quest display
copy. Legacy collected-item names migrate to opaque IDs without losing progress.

## Datamining limits

This removes direct answer lists from client modules and revealing instance
metadata. It also prevents unreached generated puzzles from being sent to the
client in advance. It does not make visible objects secret: a modified client
can inspect the geometry, colours, asset IDs and active prompts it receives.
Atomic streaming is a loading policy, not an authorization boundary. The server
still checks quest stage, interaction identity, distance, equipped shirt,
completion, saving and badge state; client appearance changes cannot grant those.

## Data and release

The current test destination **78518778092310** always starts a fresh quest on
each join, including published test servers. It uses **ProfileStore.Mock** and
replaces the loaded mock progress with a new quest, so both incomplete and
completed test runs reset. Existing persistent saves are not read or overwritten.
Respawning within the same session keeps the current attempt.

**Config.TestPlaceId** identifies this test destination independently of
**Config.PlaceId**, which controls where the quest scripts run. When the production
place is created, update **PlaceId** in both server and minimal shared configs to
its ID and leave the server's **TestPlaceId** unchanged.
Production servers then resume and save progress normally. No production place ID
is needed to enable the test reset now.

Progress uses **SecretQuest_Classic_v1**, key Player_<UserId>, independently of
Berry Avenue and anniversary profiles. Save schema version 3 migrates the earlier
nine-stage setup: unfinished early stages are retained; old stages 3/4 restart
at the nail puzzle; saves that had already finished all four retained puzzles
remain complete. Old recipe/rotation input is cleared because those rules changed.
Version 2 saves retain their stage and smoothie state. The old collected-shirt
flag is discarded, and unfinished nail attempts start with the new five-colour code.

Studio always uses **ProfileStore.Mock**, confirmed by the player's SecretSaveMode
attribute. The library's generic API-availability log does not mean live data is
being used. Completion saves mock data and simulates badge/teleport.
**SecretResetOnJoin** records whether the test-place reset policy is active.

CompletionBadgeId is configured to the test badge **4162590358506538**. Players
claim it by entering the return portal after completing all four puzzles.
Before release, set maximum players to 1 and use a reserved server for the entrance teleport.
The return destination remains **8481844229**. Live completion confirms the save,
awards/checks the badge, plays the completion animation, then teleports. Missing badge configuration or service
failure leaves the saved completion retryable. Live awards and teleports require
a published Roblox session to verify.

## Validation

Studio mock checks cover the four-stage chain, original mannequin faces and
orientation, nail unlocking the smoothie shop, hand attachment, visible jug
contents, wrong blends/reset, save/resume while holding fruit, death during a
drop, milk pouring, the finished pink blend and the portal. Rojo and StyLua checks pass.
Direct mouse clicking of the nail bottle was verified, along with source-tray
visibility, 57 distinct client-observed fruit positions during a drop, and the
finished mixture showing through the jug panels.

The VIP revision was checked with physical character movement: no-shirt rejection,
55% to 75% transparency, passage, timed closing, repeat entry without double
progress, rejection when the owned shirt is unequipped, and death cleanup.
Actual mouse clicks on the original shelf bottle caps confirmed that the wrong
colour stays locked in the earlier revision. All fifteen original bottles remain
in place; the replacement display has been removed. The current revision uses
the five-colour sequence instead of a single pink click.

The September 21 revision passed a full Studio mock run with the actual catalog
T-shirt applied to the test avatar. Checks covered no-shirt blocking, rejection
of a graphic without its catalog description, physical passage, timed closing,
unequipping, each shop's active sign, five wrong nail inputs, partial-code save
and restart, and real mouse clicks for the remaining four correct colours.
The smoothie and portal completed, all shop lights switched off, and only portal
status feedback appeared. The classic HUD and objective beams were absent.
MQ checks confirmed the tree moved 2,742 studs, remained anchored, and retained
its tagged activation trigger with an eight-stud interaction limit.

The follow-up clue revision passed focused Edit-mode checks: all five scattered
bottles are upright, sit on existing surfaces without furniture intersections,
and project left to right from the entrance in the same order as the accepted
code. None is interactive, and all fifteen original shelf inputs remain registered.
The four hidden decorative bottles restore correctly when rebuilding the scene.
All four smoothie samples rest on the counter, with only the pink drink offset
0.6 studs toward the shop interior. Both VIP SurfaceGuis contain only a VIP label.
Visual checks covered the salon, smoothie lineup, door and event-prize noob.

The shared celebration passed a Studio mock test using the final smoothie blend.
It triggered once, displayed the Secret copy and fireworks, lasted about seven
seconds, and cleaned up its GUI, sounds and control binding. The portal rejected
use during playback and completed afterward. Reloading the completed mock save
did not replay the animation. Default anniversary copy and repeated cancellation
were also checked. Stopping the actual running service during playback cancelled
the animation immediately and released controls. Both Rojo projects and StyLua checks pass.

The nail retry fix passed **tools/TestSecretNailPuzzle.lua** (17 regression cases),
covering wrong-input prefixes, restarts within partial attempts, interrupted
sequences, and save/reload continuity. A Studio mock test through the running quest
service loaded an old incorrect input, clicked three more wrong colours, then
entered the correct sequence. The lights rolled to the latest five inputs, and
the final click advanced to stage 4 and opened the smoothie shop.

Five Studio mock-storage checks covered resetting incomplete and completed test
saves, retaining production-policy partial progress and a held ingredient,
retaining that progress across another session, and retaining completed progress.
The production-policy checks used a nonmatching test ID in memory; they did not
access persistent player data or change the configured test ID in the place.

The September 22 feedback revision passed **tools/TestSecretFeedback.lua** through
the running Studio service: all four puzzles, wrong nail inputs followed by the
correct sequence, hand attachment/drop/reset for all four new ingredients, all
56 smoothie combinations, and portal-only completion. The client confirmed the
simulated badge status preceded the visible animation; the GUI and control binding
were removed afterward. Early and stale client acknowledgements were rejected.
**tools/TestSecretPortal.lua** passed six isolated cases using the production portal
functions with fake badge/teleport services: badge failure/retry, already-owned
badge, duplicate entry, teleport failure/retry, incomplete quest, departed player,
and the missing-acknowledgement fallback (related assertions share cases).
The 17 nail regression cases still pass. Visual checks covered unchanged bottles
with symbols, the 🚫 door, expanded smoothie display and tree concealment.

The privacy refactor passed private-copy validation for all five Secret stages:
future props/portal remain private, only current prompts are attached, generated
metadata is absent, and hiding the scene removes all its interactions. MQ passed
private-copy migration, invalid/duplicate collection and binding checks, followed
by a running Studio mock test through the real tree and all three pickup prompts,
carried models, anonymous saved-state responses and the reserved-teleport preview.
Its client confirmed the shared item list and destination are absent. The privacy
revision also passed all 17 nail retry cases and six portal failure/retry cases
against the staged source. The refactor is now installed in both Studio places.
Secret's rollback copy is **ServerStorage.SecretQuestPrivacyBackup_1790104056**;
MQ's is **ServerStorage.MQPrivacyBackup_1790101865**. Neither place was published.

The installed Secret refactor passed the full four-puzzle run using
**ProfileStore.Mock**, including all 56 smoothie combinations, carrying and
depositing fruit, nail retries and portal-only completion. Initial client checks
confirmed that private modules/assets, answer tokens, stage/action bindings and
player progress attributes were absent. Completion cleaned up the celebration
GUI. Repeated Stop/Start calls passed, the test place reset to stage 1, later
props and the portal returned to private storage, and all static world parts
remained anchored. Badge awards and teleports were simulated in Studio.
