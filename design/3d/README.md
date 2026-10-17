# Clearing crystal pipeline

The three primary screens use reference-matched still artwork from the built-in
ImageGen tool. That artwork gives the translucent material, reflections and floor
caustics seen in the design target without spending mobile GPU time on inaccurate
real-time glass. The final prompts and asset mappings are in
`hero-image-prompts.md`.

The editable native 3D study is separate:

- `QuietStone.blend` and `generate_quiet_stone.py` define the faceted shell and
  amber inclusions. Regenerate with
  `/Applications/Blender.app/Contents/MacOS/Blender --background --factory-startup --python design/3d/generate_quiet_stone.py`.
- The script exports `Clearing/Assets/QuietStone.usdz`. RealityKit loads it in
  `Clearing/Design/CrystalRockView.swift` and applies
  `Clearing/Design/CrystalSurface.metal` to both named meshes.
- Progress → “View the living crystal” shows that live shader and slow rotation.
- `render_quiet_stone_hero.py`, `QuietStoneHero.blend`, and `QuietStoneHero.png`
  are an editable Blender lighting/material comparison, not the shipping hero.

RealityKit's iOS 17 custom material approximates layered glass; it does not
refract the screen image or ray-trace the target's caustics. The still/live split
keeps the high-fidelity first glance and the native 3D exploration honest.
