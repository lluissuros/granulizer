/*
BUGFIXES AND IMPROVEMENTS TODO
Project: granulizer

This file tracks reliability fixes and cleanup items identified in a quick code review.
*/

(
"=== BUGFIXES (HIGH PRIORITY) ===".postln;

// [ ] Fix bus mismatch in events:
//     events route to ~buses[\reverb], but only \reverb0 and \reverb1 are defined.
//     File: granulizer_v2.1.scd
//     Affected lines (approx): 241, 258, 275, 293, 318, 335, 361, 378, 404, 428, 453
//     Action: replace ~buses[\reverb] with an existing valid bus (e.g. \reverb0).

// [ ] Fix initialization order:
//     ~initActiveSounds.() is called before ~initActiveSounds is defined.
//     File: granulizer_v2.1.scd
//     Affected lines (approx): call at 58, definition at 98
//     Action: move call below function definition, or remove early call and keep boot hook.

// [ ] Guard against missing folder key:
//     ~initActiveSounds expects ~sounds[\test].
//     File: granulizer_v2.1.scd
//     Affected line (approx): 101
//     Action: add fallback if \test does not exist (choose first available folder safely).

// [ ] Remove duplicate SynthDef name collision:
//     SynthDef(\reverb) is declared twice; second definition overwrites first.
//     File: granulizer_v2.1.scd
//     Affected lines (approx): 535 and 566
//     Action: keep one reverb version, or rename one definition (e.g. \reverbA / \reverbB).

// [ ] Fix output routing in \streson:
//     SynthDef has out arg but writes hardcoded Out.ar(0, sig).
//     File: granulizer_v2.1.scd
//     Affected line (approx): 586
//     Action: change to Out.ar(out, sig).

// [ ] Review immediate node cleanup:
//     s.freeAll is called right after node/event setup in waitForBoot block.
//     File: granulizer_v2.1.scd
//     Affected line (approx): 644
//     Action: confirm intent; remove or relocate if it kills required nodes.

"=== IMPROVEMENTS (MEDIUM PRIORITY) ===".postln;

// [ ] Normalize path casing for portability:
//     code uses "sounds/" while repo folder is "Sounds/".
//     Files: granulizer_v2.1.scd and variants
//     Action: use consistent folder casing or detect both.

// [ ] Add startup validation logs:
//     verify required folders, buses, and active sounds before playing.
//     Action: fail fast with clear postln errors when setup is incomplete.

// [ ] Consolidate duplicated logic across variants:
//     granulizer_v2.1.scd, perills44 version, and cachichi version diverge.
//     Action: extract common setup/functions and keep venue-specific overrides separate.

// [ ] Improve docs:
//     README is very short.
//     Action: document boot sequence, folder structure, MIDI mappings, and known caveats.

"TODO list loaded.".postln;
)
