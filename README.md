## Work in progress for granular experimentation

I am trying to leave a clean enough code, but please reach out to me if you find any trouble using it.

## SuperCollider setup

Recommended setup for running these sketches:

- SuperCollider `3.14.0`
- `sc3-plugins`
  - required here because the code uses `Streson`
- Quark `Tendency`
  - required here because `granulizer_v2.scd` and `granulizer_v2.1.scd` use `Tendency`

Extra quarks currently installed and loaded in my local setup:

- `Vowel`
- `SuperDirt`
- `Dirt-Samples`

Most of the rest of the code relies on standard SuperCollider classes (`TaskProxy`, `SkipJack`, `Pbindef`, `Pdefn`, `ProxySpace`, `QtGUI`, `PanAz`, etc.).

You may also need to adapt local audio device names and a few hardcoded paths depending on your machine.
