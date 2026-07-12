# Liminal — Naive External Playtest Packet

## Build under test

- Source checkpoint: `313ce3bac336e9a669719b57eb892802b44c8c2b`
- Unsigned device Release executable SHA-256: `fc4b7252a2c262c0c90f8f74820e35a0afb4f10eac9de63408a019a41c359ef8`
- Resource-path manifest SHA-256: `419d0a479bcaa9eff2fd8ef7f1e43a5e324f34042a1d20c2051c9888c2543124`
- Decision posture: engineering candidate only; external sessions cannot begin until this source checkpoint is installed through a signed device build or TestFlight

Do not substitute another build without recording its commit and hashes. A mixed-build cohort is invalid evidence.

## Cohort

Recruit eight adults who have not read the design notes, watched another session, or received a mechanic explanation. Assign anonymous IDs `P01` through `P08`; do not store names, contact details, or health information in this repository.

Before each session:

1. Use the same fresh install and settings state.
2. Confirm audio is audible and the device is comfortable to hold.
3. Say only: **“Play until you reach an ending or choose to stop; I will help only with technical failures.”**
4. Start the observation clock when Space 1 becomes interactive.

Do not explain movement controls, the speed/environment relationship, or the exit condition. Record any coaching. Stop immediately on request or at the first sign of discomfort.

## During the session

Record observed behavior in `session-observations.csv`. The opening-space evidence chain is:

1. begins moving without mechanic coaching;
2. notices that movement speed changes light or sound;
3. deliberately varies speed to test that relationship;
4. completes Space 1 without coaching;
5. reports any accessibility, motion-comfort, audio, performance, or technical blocker.

After play, ask: **“In your own words, how does this game work?”** Then ask which moment they remember most. Do not correct the answer.

## Retention check

Contact the same player 48–72 hours later. Without showing footage or reminding them of mechanics, ask:

- “How did Liminal work?”
- “What specific moment do you remember?”

Record the answers in `retention-observations.csv`.

## Decision rule

Expansion requires all of the following from one consistent build:

- at least 6/8 identify the movement/environment relationship within five minutes;
- at least 5/8 deliberately vary speed to test it;
- at least 4/8 complete Space 1 without coaching;
- no repeated accessibility or motion-sickness blocker;
- after 48–72 hours, at least 5/8 accurately explain the relationship;
- after 48–72 hours, at least 4/8 recall a specific authored moment.

Complete `decision.md` from recorded evidence. Failure permits one focused revision and a fresh cohort. Repeated failure means bounded redesign or parking.
