# Quest sound sourcing checklist

Based on the finished quest props and current code, checked 10 September 2026.
Tick an item once you have chosen its audio. Record its Roblox asset ID alongside
the entry. These are sourcing briefs, not sounds already implemented unless stated.

## Shared effects

- [x] **01 — Enter dream — IMPLEMENTED:** `89768647782835`.
  Reuse when leaving the classroom for each career dream.
- [x] **02 — Return from dream — IMPLEMENTED:** `101519970536731`.
  Plays when returning to the classroom.
- [x] **03 — UI click — IMPLEMENTED:** MQ's `8730872559`, volume 0.5 and playback
  speed 0.8–1.2, matching its ScreenController. Preloaded for quest buttons and
  dialogue Continue controls, with duplicate bindings prevented.
- [ ] **04 — Invalid action:** soft negative tick/buzz for rejected actions or
  incorrect meal delivery; brief and not harsh.
- [ ] **05 — Objective complete:** small positive chime for a completed task.
- [ ] **06 — Quest complete:** warmer, more celebratory sting for the final reward,
  approximately 2–4 seconds; distinct from the normal objective chime.

## Classroom

- [ ] **07 — Classroom ambience:** seamless 30–60 second room-tone loop, with
  very quiet indistinct student murmur if desired. No clearly spoken words.
- [ ] **08 — Chair movement / sitting:** short chair scrape and clothing movement;
  one or two variants for classroom seating.
- [ ] **09 — School bell — REVIEW EXISTING:** currently assigned and played in
  the finale: `138704534210583`. Only source a replacement if needed.

## Hospital

- [ ] **10 — Hospital ambience:** seamless 30–60 second loop of subdued ventilation
  and distant equipment. Avoid baked-in monitor beeps so those remain controllable.
- [ ] **11 — Patient monitor beep — REVIEW EXISTING:** `172905765`. A single clean
  beep, not a recording of a whole heartbeat sequence; code controls its interval.
- [ ] **12 — Monitor warning:** short electronic warning before the final shock.
  Distinct from the normal beep; no continuous flatline is needed.
- [ ] **13 — Medical tool pickup / tray contact:** light metal instrument lift
  and placement sounds. Two variants can cover the scalpel and other tray handling.
- [ ] **14 — Medicine packaging:** small tablet-box/blister rustle. The finished
  prop is medicine packaging, so a bottle-cap sound is unnecessary.
- [ ] **15 — Bandage packaging / dressing:** paper wrapper tear and soft fabric
  handling, approximately 1–2 seconds.
- [ ] **16 — Blood bag handling:** soft plastic bag and connector handling,
  approximately 1 second.
- [ ] **17 — Syringe handling:** subtle plastic click/plunger movement; keep it
  understated rather than an exaggerated injection sound.
- [ ] **18 — Defibrillator charge:** short rising electronic charge, ideally
  about 1 second so it can fit the current brief treatment sequence.
- [ ] **19 — Defibrillator ready:** single short ready beep.
- [ ] **20 — Defibrillator discharge:** brief electrical snap/thump. Keep separate
  from the charge so it can be timed to the treatment.

Return to the existing normal monitor beep after recovery; a separate recovery
recording is unnecessary. Objective completion can use sound 05.

## Police

- [ ] **21 — Police station ambience:** seamless 30–60 second quiet office loop;
  optional distant indistinct radio chatter, with no prominent speech or sirens.
- [ ] **22 — Handcuff chain movement:** restrained metal-link clink, with two or
  three short variants. For walking/body movement; no cuff-closing sound is needed
  because the suspect arrives already cuffed.
- [ ] **23 — Hard evidence handling:** small plastic/metal pickup and placement
  ticks for the phone, radio, watch, and lockpick. A shared pair is sufficient.
- [ ] **24 — Wallet handling:** short soft leather rustle.
- [ ] **25 — Keys:** short keyring jingle for pickup/confiscation.
- [ ] **26 — Fingerprint scanner start:** short activation chirp.
- [ ] **27 — Fingerprint scanning:** quiet seamless electronic hum/pulse loop,
  approximately 1–2 seconds per loop, to cover the five-second scan.
- [ ] **28 — Fingerprint scan complete:** clean electronic confirmation beep,
  distinct from the start cue. This can replace sound 05 for this interaction.
- [x] **29 — Mugshot camera — IMPLEMENTED:** `8974344071`, reused from MQ's
  camera tool and police cameras at volume 0.35. Preloaded and played with the flash.
- [ ] **30 — Cell door opening — REVIEW EXISTING:** `7203901209`, found on
  `PoliceQuest.CellDoor.Value.Node.Open`. Present in the model; the quest door
  tween does not explicitly play it yet.
- [ ] **31 — Cell door closing / latch — REVIEW EXISTING:** `7203816681`, found on
  `PoliceQuest.CellDoor.Value.Node.Close`. Present in the model; needs wiring.
  Listen first before sourcing any additional lock/latch sound.

## Plane

- [ ] **32 — Cabin ambience:** seamless 30–60 second quiet ventilation and faint
  passenger-murmur loop. Leave space for the announcement dialogue.
- [ ] **33 — PA chime:** short airline announcement chime; one asset can be reused
  at the start/end of the announcement, without handset handling sounds.
- [ ] **34 — Seatbelt buckle:** clear, short metal/plastic fastening click for Ben.
  A release sound is unnecessary unless unfastening is later shown.
- [x] **35 — Takeoff engine — IMPLEMENTED:** MQ's `16880017184`, preloaded for
  the 24-second takeoff scene and faded into cruise at the cruising-altitude cue.
- [x] **36 — Cruise engine — IMPLEMENTED:** MQ's `16882075643`, looping quietly
  through meal service and fading out for the classroom return.
- [ ] **37 — Meal tray pickup / handover:** light tray and plate contact; two
  short variants reused for all three meals. No separate eating sounds needed.

## Sourcing notes

- Start with entries marked REVIEW EXISTING before buying or uploading replacements.
- For short effects, choose clean clips with little leading silence and short tails.
  Keep charge, discharge, and confirmation cues as separate files for timing.
- Ambience must loop cleanly. Avoid recordings containing prominent announcements,
  alarms, footsteps, or other events that would repeat noticeably.
- For each selected sound, record its asset ID, source/licence, and whether it loops.
  Prefer WAV masters when downloading files for upload.
- Music and spoken dialogue are separate decisions, not part of this effects list.
  Classroom music is now `1837383248` (Lighthearted), looping at volume 0.12 during
  all four classroom cutscenes, with fades on entry, exit, and dream transitions.
  No sounds are required for the removed care board, intercom handset, passenger
  tray tables, or stationary trolley wheels/brakes.
