# Anniversary Quest — asset production checklist

Based on the quest code and connected Anniversary Quest Studio place inspected on
9 September 2026. Scope: classroom → doctor → classroom → police → classroom →
air hostess → classroom finale, within Berry Avenue's universe.

This is a commissioning and approval list, not a claim that everything below is
missing. **Replace** means a confirmed basic placeholder; **Add** means a suggested
asset for an existing gameplay moment; **Review/reuse** means something already
exists and should be checked before commissioning. Unchecked items have not been
signed off for final quality. Extra gameplay ideas are marked **Optional**.

## First production batch

1. Plane service trolley, three meal variants, and tray carrying/serving animations.
2. Six hospital tools and six distinct treatment animations.
3. Finished character appearances, particularly the teacher and speaking students.
4. Police handcuffs, fingerprint scanner, and fingerprint/mugshot poses.
5. Dream transition sound pair and clear sounds for the main interactions.

Check the Berry Avenue asset library before commissioning a new model or recording.
The existing school, hospital, police station, plane cabin, hospital bed, cell door,
mugshot backdrop, and crew seat are already being reused. Rebuilding these is not
part of this list.

## 3D models, clothing, and character appearance

### Plane / air hostess

- [ ] **M01 — Service trolley. Replace.** A finished airline food trolley with
  wheels, handle, meal compartments, and Berry Avenue Airways styling. The current
  service point is a block named `Galley` with a flat `ServiceTray` on top. Match its
  location and fit the cabin aisle. Separate wheels/doors only if they will animate.
  The current game collects meals from a stationary point; pushing a trolley down
  the aisle would also require new gameplay implementation.
- [ ] **M02 — Airline meal set. Replace.** Three distinguishable meals: sandwich,
  salad, and pasta, sharing one tray design. Include appropriate plate/bowl,
  cutlery, napkin, and packaging as desired. Deliver versions suitable for display,
  carrying, and placement in front of passengers; these can reuse the same meshes.
  Current food is generated from simple blocks, balls, and cylinders.
- [ ] **M03 — Passenger lap belt and buckle. Replace.** A reusable fastened belt
  plus an unfastened state for Ben's interaction. The existing belt is one narrow
  block. Make its attachment positions agree with the fastening animation.
- [ ] **M04 — Cabin intercom. Add.** A visible handset/microphone and cradle at the
  galley for the safety announcement. Currently the interaction uses the same
  block as meal collection. A separate handset is only needed if held on screen.
- [ ] **M05 — Passenger tray table. Add/review existing cabin geometry.** Provide a
  proper surface for served meals; they currently appear at a fixed offset in
  front of each passenger. Open/closed states are useful, but an opening interaction
  is optional and would need code.
- [ ] **M06 — Seatbelt sign. Add/review existing cabin fittings.** A readable lit/unlit
  graphic or small fixture for takeoff and cruising. Those changes are currently
  conveyed through text. This may only need a texture and light, not a new model.

### Hospital / doctor

10 September update: M07–M13 now have improved quest props. Medicine and bandage
packaging and the defibrillator paddles were copied from MQ; the scalpel, syringe,
blood bag, and metal tray stands were built with parts. The care board was removed.
Patient, monitor, treatment animation, and sound work remain outside this pass.
The items below retain the original commissioning suggestions for future review.

- [ ] **M07 — Medicine. Replace.** Recognisable medicine container with label and
  cap. Agree whether the action gives a tablet or liquid before making its animation.
- [ ] **M08 — Scalpel. Replace.** A readable stylised handle and blade, sized for
  the character's hand and a brief, non-graphic treatment action.
- [ ] **M09 — Bandage. Replace.** A roll or dressing, plus an applied dressing if
  treatment results should remain visible on the patient.
- [ ] **M10 — Blood bag. Replace.** A recognisable bag and hanger connection.
  Reuse an existing IV stand if available; tubing and the connection point need
  agreeing with the replacement animation.
- [ ] **M11 — Injection. Replace.** A syringe with a readable barrel and plunger.
- [ ] **M12 — Defibrillator. Replace.** Two paddles and, if visible in the shot, a
  matching machine/cables. The current prop is two basic paddle-shaped blocks.
- [ ] **M13 — Medical supply stand/tray. Replace.** One polished reusable design
  for the six pickup stations, with room for the tools and labels. Six unique
  furniture designs are unnecessary.
- [ ] **M14 — Patient presentation. Polish.** Hospital gown, suitable hair/face,
  and any bedding/drape needed for the treatment shots. Retain the existing bed
  and ensure tools can reach their intended contact points.
- [ ] **M15 — Monitor and care-board presentation. Review/reuse.** The quest adds
  simple display surfaces to the existing hospital setup. Improve screen artwork
  and integration first; commission a new housing only if the current one needs it.

### Police

10 September update: M16–M18 have been polished. MQ supplied the phone, car keys,
radio, and booking-desk cuffs. The worn cuffs and chain are fitted parts; wallet,
lockpick, and watch detailing also use parts. The scanner now has a casing, glass,
fingerprint graphic, status lights, and equipment stand. Other police work remains
outside this pass; the original commissioning suggestions follow for reference.

- [ ] **M16 — Handcuffs. Replace.** Proper cuffs with a short connecting chain;
  currently they are blocks attached to the hands with a Beam between them. Match
  the fixed wrist spacing and poses. A decorative chain is sufficient; a physics
  chain is not required for this quest.
- [ ] **M17 — Search evidence set. Replace/polish.** Six separate selectable props:
  phone, wallet, keys, lockpick, radio, and watch. Simple versions already exist.
  Keep each recognisable at the search-camera distance and easy to select/drag.
- [ ] **M18 — Fingerprint scanner. Replace.** Finished casing, scanning glass,
  indicator light, and screen/graphic if wanted. The current device is basic parts.
  Confirm the hand placement with the animator before finalising its dimensions.
- [ ] **M19 — Mugshot equipment. Add if visible in the final shot.** Camera and
  mount/tripod; optionally a booking placard. The photo interaction and flash exist,
  and the current station already supplies the backdrop. Do not recreate the room.

### Cast and outfits

- [ ] **M20 — Classroom cast appearance pass. Polish.** Ms Taylor and six students:
  Maya, Leo, Amira, Ben, Sofia, and Noah. Finalise hair, faces, clothing, and colours;
  preserve recognisable identities for the three speaking students. The inspected
  quest rigs have no Shirt, Pants, or Accessory instances installed.
- [ ] **M21 — Police cast appearance pass. Polish.** Officer Leo's uniform/badge
  and the suspect's final outfit. Keep the six evidence objects visible and avoid
  clothing that clips the handcuff pose.
- [ ] **M22 — Flight passenger appearance pass. Reuse/polish.** Reuse the six
  classmates' designs, with travel outfits only if the dream's art direction calls
  for them. These are currently clones of the classroom cast, not six new identities.
- [ ] **M23 — Player job outfits. Optional.** Doctor, police, and cabin crew outfits
  would help sell each dream. Prefer existing Berry Avenue clothing. Applying and
  restoring outfits is additional implementation, so agree this before commissioning.

## Animations

### Classroom and recurring character moments

- [ ] **A01 — Teacher dialogue gestures. Add.** Relaxed standing/talking loop,
  inviting a student to answer, acknowledging their answer, and dismissal gesture.
  Reuse clips across the three classroom visits.
- [ ] **A02 — Seated student dialogue. Add.** A speaking gesture and listening/
  reaction variations for Maya, Leo, and Amira, while keeping them seated. A small
  shared set with different timing is sufficient; bespoke clips per line are optional.
- [ ] **A03 — Seated idle. Review/reuse.** A sitting animation already exists and
  is shared with flight passengers. Check its fit to both chairs and cabin seats
  before commissioning separate variants.
- [ ] **A04 — Dreaming/waking reaction. Optional.** A brief player or student
  reaction before/after the existing camera transition. This is polish, not a
  requirement for the current scene flow.

### Doctor

- [ ] **A05 — Pick up and carry medical items. Add.** Pickup, held idle, and walking
  with an item. Reuse compatible clips across tools; allow a separate two-hand
  hold for the defibrillator if required.
- [ ] **A06 — Six treatment actions. Replace.** Give medicine, use scalpel, apply
  bandage, replace blood bag, give injection, and use both defibrillator paddles.
  Currently these use a shared scripted shoulder movement, with a bandage variation.
  Agree patient contact points, hand grips, and prop visibility for every action.
- [ ] **A07 — Patient reaction set. Add.** Lying/breathing idle, brief defibrillator
  response, and subtle recovery reaction. Keep the tone consistent with Berry Avenue.

### Police

- [ ] **A08 — Restrained suspect idle/walk. Review/polish.** The generic walk now
  has a fixed pose on both shoulders, elbows, and wrists. A bespoke cuffed idle/walk
  would improve the whole body performance, but is not needed to fix hand movement.
  Include starts/stops if desired and preserve cuff spacing throughout.
- [ ] **A09 — Fingerprint hand placement. Add.** Reach to the scanner, hold for the
  scan, and withdraw. Agree how both cuffed hands move together; do not break the
  restraint pose or silently uncuff the suspect.
- [ ] **A10 — Mugshot pose. Add.** Face the camera and hold still; add a placard hold
  only if M19 includes one. Extra profile photographs are outside the current flow.
- [ ] **A11 — Officer interaction gestures. Optional polish.** Direct the suspect,
  operate the scanner/camera, and acknowledge completion. Use a shared small set.

### Flight

- [ ] **A12 — Intercom announcement. Add.** Pick up/hold/replace the handset and
  speak into it, if the player is shown doing this. Coordinate with M04 and the PA.
- [ ] **A13 — Help Ben fasten his belt. Add.** Player reach/buckle/release and a
  matching seated passenger response. Currently this interaction advances the
  checkpoint without a dedicated fastening animation.
- [ ] **A14 — Crew takeoff seating. Review/polish.** Sit, fasten belt if shown,
  remain seated for takeoff, and stand. Currently reuses the classroom sit.
- [ ] **A15 — Meal service. Add.** Pick up tray, carry idle/walk with the tray level,
  and hand over/place it. The current tray is simply welded to the right hand.
- [ ] **A16 — Passenger reactions. Add.** Settling-in variations, receiving a meal,
  and a brief thank-you/nod. Eating loops are optional. The current introduction
  has scripted head turns and a shared sitting pose.
- [ ] **A17 — Push service trolley. Optional.** Only commission if the trolley
  will actually move through the cabin; it is a stationary pickup point today.

## Sounds, ambience, and music

These are sound-design briefs; use suitable existing library audio where available.
The quest currently explicitly wires a school bell, patient monitor beep, and
takeoff engine sound. The items below describe the intended finished coverage,
not an assertion that the wider Berry Avenue map has no usable sounds.

### Shared / classroom

- [ ] **S01 — Dream transition pair. Add.** A soft build into the dream and a
  distinct return/reveal sound. Reusable across all chapter boundaries; keep the
  important sound tied to the covered transition rather than overlapping dialogue.
- [ ] **S02 — Interaction feedback set. Add.** UI selection/confirm, item pickup,
  valid action, wrong item/action, objective completed, and final quest completion.
  Reuse a coherent small set across stages.
- [ ] **S03 — Classroom ambience. Add/reuse.** Quiet classroom room tone; optional
  restrained student murmur and chair movement. Keep speech/dialogue readable.
- [ ] **S04 — School bell. Review/reuse.** Already implemented for the finale;
  approve its sound and volume before replacing it.
- [ ] **S05 — Music. Optional.** One gentle quest theme, or light variations for
  the classroom, hospital, police, and flight, plus a short completion sting.

### Hospital

- [ ] **S06 — Hospital room tone. Add/reuse.** Quiet ventilation/equipment ambience.
- [ ] **S07 — Patient monitor set. Review/extend.** Existing normal beep, plus a
  warning cue before the final shock and stable/recovery feedback. Avoid duplicating
  the normal beep if the existing asset is suitable.
- [ ] **S08 — Medical interaction set. Add.** Container/tray handling, medicine
  cap, bandage unwrap, IV bag handling, syringe action, and subtle tool contact.
  Several small actions can share foley.
- [ ] **S09 — Defibrillator sequence. Add.** Charge, ready cue, discharge, and
  recovery response aligned with the paddle animation.

### Police

- [ ] **S10 — Police station ambience. Add/reuse.** Restrained room tone and distant
  radio/office activity, without competing with instructions.
- [ ] **S11 — Evidence handling. Add.** Pickup/placement sounds, with distinctive
  keys/metal sounds where useful; not necessarily six unique recordings.
- [ ] **S12 — Fingerprint scanner. Add.** Start, scanning loop, and success beep.
- [ ] **S13 — Mugshot camera. Add.** Shutter/flash sound for the existing flash.
- [ ] **S14 — Handcuffs and cell door. Add/reuse.** Restrained metal handling,
  cell open/close movement, and latch/lock. Check the existing door audio first.
  Cuff rattle should be subtle and tied to body movement, not loose swinging hands.

### Flight

- [ ] **S15 — Cabin sound bed. Add/reuse.** Boarding murmur/ventilation and a cruise
  engine loop, with levels suitable for PA announcements.
- [ ] **S16 — Takeoff audio. Review/extend.** Existing engine sound; approve or
  replace it with acceleration, climb, and a transition into cruise ambience.
- [ ] **S17 — Airline chimes. Add.** PA start/end and seatbelt-sign cues.
- [ ] **S18 — Belt and intercom foley. Add.** Buckle click/release and handset
  pickup/put-down, aligned to the relevant animations.
- [ ] **S19 — Meal service foley. Add.** Tray pickup/place and light packaging/
  cutlery sounds. Trolley wheels/brakes are optional if it will actually move.

## Voice-over and 2D artwork

- [ ] **V01 — Spoken dialogue. Optional.** Record Ms Taylor's opening, prompts,
  and finale; Maya's doctor ambition; Leo's police ambition and officer lines;
  Amira's air hostess ambition. Use the final script, not separate invented lines.
- [ ] **V02 — Airline PA. Recommended if using any voice-over.** Cabin welcome and
  safety announcement, captain's takeoff instruction, and cruise/service cues.
  These are currently text. Finalise wording and timing before booking recording.
- [ ] **G01 — Meal and medical item icons. Add/polish.** Three meal icons and six
  treatment icons, matching the finished models. Police evidence icons only if the
  final UI needs them; the search already uses selectable 3D objects.
- [ ] **G02 — In-world display graphics. Polish.** Care board, monitor states,
  scanner display/fingerprint graphic, meal labels, and airline signage. Reuse the
  established dialogue/UI style rather than commissioning an unrelated UI system.
- [ ] **G03 — Quest completion presentation. Optional polish.** Completion graphic
  and restrained celebration effect. A wearable reward/item is not assumed by the
  current quest scope and would need a separate brief.

## Notes to include in artist / animator briefs

- Match the established Berry Avenue visual style and the actual camera distances.
  Send the existing room, prop placement, and character rig as references.
- Finalise props and hand/contact positions before animating their interactions.
  Particularly coordinate trolley/tray, seatbelt, scanner/cuffs, and medical tools.
- Students, passengers, the patient, and police NPCs currently use R15. **Ms Taylor
  currently uses R6.** Decide whether to keep or convert her before commissioning
  teacher animations. The current suspect uses AnimationConstraint joints.
- Deliver editable source assets plus import-ready models/textures/animation clips.
  Agree pivots, grips, named moving parts, collision needs, and attachment points.
  Give animation clips clear pickup/contact/release markers for implementation.
- Preserve the six evidence props as separate selectable objects. Reuse meal meshes
  for display, held, and served states instead of producing unnecessary duplicates.
- Current timings are reference points, not final creative limits: treatments are
  **2 seconds each**, fingerprint scanning **5 seconds**, mugshot **1.5 seconds**,
  flight intro **14 seconds**, safety PA **24 seconds**, takeoff **24 seconds**, and
  flight completion **8 seconds**. Update gameplay timing to fit approved animations
  and recordings rather than squeezing them into unsuitable timings.
- Deliver clean sound files with loop boundaries where appropriate; keep PA voices,
  chimes, and engine beds separate so their volumes can be mixed independently.
- Asset production and integration are separate tasks. An animated buckle, trolley,
  or monitor graphic will still need wiring into the corresponding quest moment.

## Inspection references

- Original inspection place: Anniversary Quest, `101522826150554`; read-only inspection
  of `ClassroomIntro`, `DoctorQuest`, `PoliceQuest`, `FlightQuest`, and `PlaneInter`.
  The development target moved to `133860577693306` on 10 September 2026.
- Existing asset builders: `tools/BuildClassroom.lua`, `BuildDoctorRoom.lua`,
  `BuildPoliceQuest.lua`, and `BuildFlightQuest.lua`.
- Runtime props: `src/ReplicatedStorage/Modules/FlightMeals.lua` and `PoliceEvidence.lua`.
- Animation/interaction behaviour: `DoctorEffects.client.lua`, `Police.client.lua`,
  `Flight.client.lua`, `FlightService.lua`, and `ClassroomSitting.lua`.
- Dialogue and timing: `src/ReplicatedStorage/Cutscenes/`, `DoctorQuestConfig.lua`,
  `PoliceQuestConfig.lua`, `FlightQuestConfig.lua`, and `AnniversaryQuestConfig.lua`.
