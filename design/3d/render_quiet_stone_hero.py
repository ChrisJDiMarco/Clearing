"""Render premium still art from the same Blender geometry as QuietStone.usdz.

Draft: QUIET_STONE_DRAFT=1 Blender --background --python design/3d/render_quiet_stone_hero.py
Final: Blender --background --python design/3d/render_quiet_stone_hero.py

This script never touches the live USDZ. It produces a self-contained still
for the static onboarding/Today hero where photographic light is preferable
to the simplified real-time RealityKit scene.
"""

from pathlib import Path
import math
import os

import bpy
from mathutils import Vector


ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "design" / "3d" / "QuietStone.blend"
DESIGN_DIR = ROOT / "design" / "3d"
DRAFT = os.environ.get("QUIET_STONE_DRAFT") == "1"

bpy.ops.wm.open_mainfile(filepath=str(SOURCE))
scene = bpy.context.scene

shell = bpy.data.objects["QuietStoneShell"]
core = bpy.data.objects["AmberCore"]
for obj in tuple(bpy.data.objects):
    if obj not in (shell, core):
        bpy.data.objects.remove(obj, do_unlink=True)

# Make the warm center asymmetric and integrated with the lower-left crystal,
# avoiding the read of a separate, centrally floating orange pebble.
core.scale = (0.69, 0.63, 0.37)
core.location = (-0.043, 0.014, -0.077)
core.rotation_euler = (math.radians(-7), math.radians(16), math.radians(-14))

def rgb(hex_value):
    hex_value = hex_value.removeprefix("#")
    return tuple(int(hex_value[i:i + 2], 16) / 255 for i in (0, 2, 4))

def node_material(name):
    material = bpy.data.materials.new(name)
    material.use_nodes = True
    material.node_tree.nodes.clear()
    return material, material.node_tree.nodes, material.node_tree.links

def output(nodes):
    return nodes.new("ShaderNodeOutputMaterial")

# Crystal-clear shell with a *spatially graded* honey-to-ice tint. Metallic
# shading was intentionally avoided; real glass gains interest from reflected
# softboxes, thickness, refraction, and internal light paths.
shell_mat, nodes, links = node_material("Beauty_ChampagneToIceGlass")
glass = nodes.new("ShaderNodeBsdfGlass")
glass.inputs["Roughness"].default_value = 0.018
glass.inputs["IOR"].default_value = 1.49
tex = nodes.new("ShaderNodeTexCoord")
split = nodes.new("ShaderNodeSeparateXYZ")
links.new(tex.outputs["Generated"], split.inputs["Vector"])
left = nodes.new("ShaderNodeMath")
left.operation = "SUBTRACT"
left.inputs[0].default_value = 1
links.new(split.outputs["X"], left.inputs[1])
low = nodes.new("ShaderNodeMath")
low.operation = "SUBTRACT"
low.inputs[0].default_value = 1
links.new(split.outputs["Z"], low.inputs[1])
warmth = nodes.new("ShaderNodeMath")
warmth.operation = "MULTIPLY"
links.new(left.outputs[0], warmth.inputs[0])
links.new(low.outputs[0], warmth.inputs[1])
gradient = nodes.new("ShaderNodeValToRGB")
gradient.color_ramp.elements.remove(gradient.color_ramp.elements[1])
for index, (position, color) in enumerate((
    (0.0, (0.72, 0.83, 0.87, 1.0)),
    (0.22, (0.85, 0.90, 0.91, 1.0)),
    (0.55, (0.91, 0.83, 0.66, 1.0)),
    (1.0, (0.73, 0.47, 0.21, 1.0)),
)):
    element = gradient.color_ramp.elements[0] if index == 0 else gradient.color_ramp.elements.new(position)
    element.position = position
    element.color = color
links.new(warmth.outputs[0], gradient.inputs["Fac"])
links.new(gradient.outputs["Color"], glass.inputs["Color"])
clear = nodes.new("ShaderNodeBsdfTransparent")
clear.inputs["Color"].default_value = (1, 1, 1, 1)
shell_mix = nodes.new("ShaderNodeMixShader")
shell_mix.inputs[0].default_value = 0.14
links.new(glass.outputs["BSDF"], shell_mix.inputs[1])
links.new(clear.outputs["BSDF"], shell_mix.inputs[2])
out = output(nodes)
links.new(shell_mix.outputs["Shader"], out.inputs["Surface"])
shell.data.materials.clear()
shell.data.materials.append(shell_mat)

# Amber inclusion: irregular facets rather than opaque gemstone color. Volume
# absorption supplies the rich interior while leaving lit edges see-through.
core_mat, nodes, links = node_material("Beauty_AmberInclusions")
inner_glass = nodes.new("ShaderNodeBsdfPrincipled")
inner_glass.inputs["Base Color"].default_value = (0.34, 0.13, 0.025, 1)
inner_glass.inputs["Roughness"].default_value = 0.12
inner_glass.inputs["Transmission Weight"].default_value = 0.05
inner_glass.inputs["IOR"].default_value = 1.46
absorption = nodes.new("ShaderNodeVolumeAbsorption")
absorption.inputs["Color"].default_value = (0.90, 0.57, 0.24, 1)
absorption.inputs["Density"].default_value = 2.4
out = output(nodes)
links.new(inner_glass.outputs["BSDF"], out.inputs["Surface"])
links.new(absorption.outputs["Volume"], out.inputs["Volume"])
core.data.materials.clear()
core.data.materials.append(core_mat)

# Cream floor. Outside the illuminated contact zone it eases into a stable
# flat color, helping the rectangular still merge with Clearing's ivory UI.
floor_mat, nodes, links = node_material("Beauty_CreamFloor")
diffuse = nodes.new("ShaderNodeBsdfPrincipled")
diffuse.inputs["Base Color"].default_value = (*rgb("#EDE9E1"), 1)
diffuse.inputs["Roughness"].default_value = 0.74
far = nodes.new("ShaderNodeEmission")
far.inputs["Color"].default_value = (*rgb("#F7F5F0"), 1)
far.inputs["Strength"].default_value = 10.0
geo = nodes.new("ShaderNodeNewGeometry")
radial = nodes.new("ShaderNodeVectorMath")
radial.operation = "LENGTH"
links.new(geo.outputs["Position"], radial.inputs[0])
fade = nodes.new("ShaderNodeMapRange")
fade.inputs["From Min"].default_value = 0.16
fade.inputs["From Max"].default_value = 0.29
links.new(radial.outputs["Value"], fade.inputs["Value"])
mix = nodes.new("ShaderNodeMixShader")
links.new(fade.outputs["Result"], mix.inputs[0])
links.new(diffuse.outputs["BSDF"], mix.inputs[1])
links.new(far.outputs["Emission"], mix.inputs[2])

# A quiet fan of broken light at the contact point suggests refracted amber
# caustics without introducing a hard-edged graphic or compositing a decal.
xy = nodes.new("ShaderNodeSeparateXYZ")
links.new(geo.outputs["Position"], xy.inputs["Vector"])
flat_position = nodes.new("ShaderNodeCombineXYZ")
links.new(xy.outputs["X"], flat_position.inputs["X"])
links.new(xy.outputs["Y"], flat_position.inputs["Y"])
floor_radius = nodes.new("ShaderNodeVectorMath")
floor_radius.operation = "LENGTH"
links.new(flat_position.outputs["Vector"], floor_radius.inputs[0])
angle = nodes.new("ShaderNodeMath")
angle.operation = "ARCTAN2"
links.new(xy.outputs["Y"], angle.inputs[0])
links.new(xy.outputs["X"], angle.inputs[1])
angle_scale = nodes.new("ShaderNodeMath")
angle_scale.operation = "MULTIPLY"
angle_scale.inputs[1].default_value = 21
links.new(angle.outputs[0], angle_scale.inputs[0])
radial_wave = nodes.new("ShaderNodeMath")
radial_wave.operation = "MULTIPLY"
radial_wave.inputs[1].default_value = 27
links.new(floor_radius.outputs["Value"], radial_wave.inputs[0])
wave_sine = nodes.new("ShaderNodeMath")
wave_sine.operation = "SINE"
links.new(radial_wave.outputs[0], wave_sine.inputs[0])
wave_scale = nodes.new("ShaderNodeMath")
wave_scale.operation = "MULTIPLY"
wave_scale.inputs[1].default_value = 0.8
links.new(wave_sine.outputs[0], wave_scale.inputs[0])
twisted_angle = nodes.new("ShaderNodeMath")
twisted_angle.operation = "ADD"
links.new(angle_scale.outputs[0], twisted_angle.inputs[0])
links.new(wave_scale.outputs[0], twisted_angle.inputs[1])
ray_sine = nodes.new("ShaderNodeMath")
ray_sine.operation = "SINE"
links.new(twisted_angle.outputs[0], ray_sine.inputs[0])
ray_positive = nodes.new("ShaderNodeMath")
ray_positive.operation = "MAXIMUM"
ray_positive.inputs[1].default_value = 0
links.new(ray_sine.outputs[0], ray_positive.inputs[0])
ray_sharp = nodes.new("ShaderNodeMath")
ray_sharp.operation = "POWER"
ray_sharp.inputs[1].default_value = 17
links.new(ray_positive.outputs[0], ray_sharp.inputs[0])
caustic_radius = nodes.new("ShaderNodeMapRange")
caustic_radius.inputs["From Min"].default_value = 0.09
caustic_radius.inputs["From Max"].default_value = 0.32
links.new(floor_radius.outputs["Value"], caustic_radius.inputs["Value"])
ring = nodes.new("ShaderNodeValToRGB")
ring.color_ramp.elements[0].position = 0.0
ring.color_ramp.elements[0].color = (0, 0, 0, 1)
ring.color_ramp.elements[1].position = 1.0
ring.color_ramp.elements[1].color = (0, 0, 0, 1)
for position, weight in ((0.22, 0.54), (0.47, 1.0), (0.73, 0.26)):
    item = ring.color_ramp.elements.new(position)
    item.color = (weight, weight, weight, 1)
links.new(caustic_radius.outputs["Result"], ring.inputs["Fac"])
ring_multiply = nodes.new("ShaderNodeMath")
ring_multiply.operation = "MULTIPLY"
links.new(ray_sharp.outputs[0], ring_multiply.inputs[0])
links.new(ring.outputs["Color"], ring_multiply.inputs[1])
x_bias = nodes.new("ShaderNodeMapRange")
x_bias.inputs["From Min"].default_value = -0.28
x_bias.inputs["From Max"].default_value = 0.28
x_bias.inputs["To Min"].default_value = 0.28
x_bias.inputs["To Max"].default_value = 1
links.new(xy.outputs["X"], x_bias.inputs["Value"])
bias_multiply = nodes.new("ShaderNodeMath")
bias_multiply.operation = "MULTIPLY"
links.new(ring_multiply.outputs[0], bias_multiply.inputs[0])
links.new(x_bias.outputs["Result"], bias_multiply.inputs[1])
caustic_amount = nodes.new("ShaderNodeMath")
caustic_amount.operation = "MULTIPLY"
caustic_amount.inputs[1].default_value = 0.44
links.new(bias_multiply.outputs[0], caustic_amount.inputs[0])
caustic_emission = nodes.new("ShaderNodeEmission")
caustic_emission.inputs["Color"].default_value = (1.0, 0.78, 0.47, 1)
caustic_emission.inputs["Strength"].default_value = 15
caustic_mix = nodes.new("ShaderNodeMixShader")
links.new(caustic_amount.outputs[0], caustic_mix.inputs[0])
links.new(mix.outputs["Shader"], caustic_mix.inputs[1])
links.new(caustic_emission.outputs["Emission"], caustic_mix.inputs[2])
out = output(nodes)
links.new(caustic_mix.outputs["Shader"], out.inputs["Surface"])

bpy.context.view_layer.update()
bottom = min((shell.matrix_world @ Vector(corner)).z for corner in shell.bound_box)
bpy.ops.mesh.primitive_plane_add(size=200, location=(0, 0, bottom - 0.001))
floor = bpy.context.object
floor.name = "Beauty_CreamFloor"
floor.data.materials.append(floor_mat)

# Invisible-to-camera studio flags give the clear faces something dark to
# reflect/refract. This is the classic product-photography contrast trick: the
# backdrop stays cream while selected facets gain believable internal depth.
def dark_flag(name, position, target, width, height, tone):
    material, nodes, links = node_material(name + "Material")
    shader = nodes.new("ShaderNodeBsdfDiffuse")
    shader.inputs["Color"].default_value = (*tone, 1)
    links.new(shader.outputs["BSDF"], output(nodes).inputs["Surface"])
    bpy.ops.mesh.primitive_plane_add(size=1, location=position)
    obj = bpy.context.object
    obj.name = name
    obj.scale = (width, height, 1)
    obj.rotation_euler = (Vector(target) - obj.location).to_track_quat("Z", "Y").to_euler()
    obj.data.materials.append(material)
    obj.visible_camera = False
    obj.visible_shadow = False
    obj.visible_diffuse = False
    return obj

dark_flag("Cool internal negative card", (0.0, 0.23, 0.025), (0, 0, 0.02), 0.19, 0.27, (0.25, 0.31, 0.34))

def area_light(name, position, target, power, color, width, height=None):
    data = bpy.data.lights.new(name, "AREA")
    data.energy = power
    data.color = color
    data.shape = "RECTANGLE" if height is not None else "DISK"
    data.size = width
    if height is not None:
        data.size_y = height
    obj = bpy.data.objects.new(name, data)
    bpy.context.collection.objects.link(obj)
    obj.location = position
    obj.rotation_euler = (Vector(target) - obj.location).to_track_quat("-Z", "Y").to_euler()
    return obj

area_light("Warm softbox upper left", (-0.36, -0.26, 0.48), (0, 0, 0), 3.5, (1.0, 0.87, 0.72), 0.33, 0.45)
area_light("Cool vertical strip right", (0.40, -0.02, 0.34), (0, 0, 0), 4.0, (0.84, 0.94, 1.0), 0.14, 0.48)
area_light("White sharp edge", (0.08, 0.29, 0.39), (0, 0, 0), 5.5, (1.0, 0.98, 0.94), 0.18, 0.35)
area_light("Broad frontal fill", (0.05, -0.42, 0.27), (0, 0, 0), 0.5, (1.0, 0.97, 0.88), 0.58, 0.47)
caustic = area_light("Amber contact caustic", (-0.17, 0.15, 0.49), (0.0, 0, bottom), 1.8, (1.0, 0.83, 0.57), 0.045)
caustic.data.cycles.is_caustics_light = True

camera_data = bpy.data.cameras.new("BeautyCamera")
camera = bpy.data.objects.new("BeautyCamera", camera_data)
bpy.context.collection.objects.link(camera)
camera.location = (0.26, -0.70, 0.16)
target = Vector((0, 0, -0.005))
camera.rotation_euler = (target - camera.location).to_track_quat("-Z", "Y").to_euler()
camera_data.type = "ORTHO"
camera_data.ortho_scale = 0.52
scene.camera = camera

world = bpy.data.worlds.new("Beauty Studio World")
scene.world = world
world.use_nodes = True
world.node_tree.nodes.clear()
world_out = world.node_tree.nodes.new("ShaderNodeOutputWorld")
world_ambient = world.node_tree.nodes.new("ShaderNodeBackground")
world_ambient.inputs["Color"].default_value = (0.88, 0.92, 0.95, 1)
world_ambient.inputs["Strength"].default_value = 0.22
world_camera = world.node_tree.nodes.new("ShaderNodeBackground")
world_camera.inputs["Color"].default_value = (*rgb("#F7F5F0"), 1)
world_camera.inputs["Strength"].default_value = 10.0
camera_ray = world.node_tree.nodes.new("ShaderNodeLightPath")
world_mix = world.node_tree.nodes.new("ShaderNodeMixShader")
world.node_tree.links.new(camera_ray.outputs["Is Camera Ray"], world_mix.inputs[0])
world.node_tree.links.new(world_ambient.outputs["Background"], world_mix.inputs[1])
world.node_tree.links.new(world_camera.outputs["Background"], world_mix.inputs[2])
world.node_tree.links.new(world_mix.outputs["Shader"], world_out.inputs["Surface"])

scene.render.engine = "CYCLES"
scene.cycles.samples = 32 if DRAFT else 96
scene.cycles.use_denoising = True
scene.cycles.max_bounces = 16
scene.cycles.diffuse_bounces = 6
scene.cycles.glossy_bounces = 12
scene.cycles.transmission_bounces = 16
scene.cycles.transparent_max_bounces = 12
scene.cycles.caustics_refractive = True
scene.cycles.caustics_reflective = True
shell.cycles.is_caustics_caster = True
core.cycles.is_caustics_caster = True
floor.cycles.is_caustics_receiver = True

prefs = bpy.context.preferences.addons["cycles"].preferences
prefs.compute_device_type = "METAL"
prefs.get_devices()
for device in prefs.devices:
    device.use = device.type == "METAL"
scene.cycles.device = "GPU"

scene.render.resolution_x = 650 if DRAFT else 1500
scene.render.resolution_y = 650 if DRAFT else 1500
scene.render.resolution_percentage = 100
scene.render.image_settings.file_format = "PNG"
scene.render.image_settings.color_mode = "RGBA"
scene.view_settings.view_transform = "AgX"
scene.view_settings.look = "AgX - Medium High Contrast"
scene.view_settings.exposure = -1.2
scene.render.filepath = str(DESIGN_DIR / "QuietStoneHero-draft.png" if DRAFT else DESIGN_DIR / "QuietStoneHero.png")
if os.environ.get("QUIET_STONE_DEBUG_CORE") == "1":
    shell.hide_render = True
if os.environ.get("QUIET_STONE_DEBUG_SHELL") == "1":
    core.hide_render = True

if not DRAFT:
    bpy.context.preferences.filepaths.save_version = 0
    bpy.ops.wm.save_as_mainfile(filepath=str(DESIGN_DIR / "QuietStoneHero.blend"))
bpy.ops.render.render(write_still=True)
print("QUIET_STONE_HERO", scene.render.filepath)
