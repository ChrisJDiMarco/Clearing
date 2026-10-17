"""Generate Clearing's original, mobile-ready Quiet Stone asset.

Run with:
    /Applications/Blender.app/Contents/MacOS/Blender --background \
      --factory-startup --python design/3d/generate_quiet_stone.py

The USDZ contains only the rock mesh. The .blend file and preview are design
sources and are intentionally kept outside the iOS app bundle.
"""

from pathlib import Path
import math
import random

import bpy
import bmesh
from mathutils import Vector


ROOT = Path(__file__).resolve().parents[2]
SOURCE_DIR = ROOT / "design" / "3d"
ASSET_DIR = ROOT / "Clearing" / "Assets"
SOURCE_DIR.mkdir(parents=True, exist_ok=True)
ASSET_DIR.mkdir(parents=True, exist_ok=True)

bpy.ops.object.select_all(action="SELECT")
bpy.ops.object.delete(use_global=False)

# An icosphere is a closed, even triangulation. Perturbing its vertices by
# several broad waves gives the facets an organic mineral silhouette without
# requiring a texture, high polygon count, or tessellation at runtime.
bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=3, radius=1)
stone = bpy.context.object
stone.name = "QuietStoneShell"
stone.data.name = "QuietStone_FacetedMesh"
rng = random.Random(27419)

for vertex in stone.data.vertices:
    unit = vertex.co.normalized()
    x, y, z = unit
    angle = math.atan2(y, x)
    broad = (
        0.084 * math.sin(3.6 * angle + 1.1 * z)
        + 0.051 * math.cos(6.4 * x - 3.1 * y + 1.2 * z)
        + 0.032 * math.sin(7.7 * z + 2.2 * y)
    )
    fine = rng.uniform(-0.026, 0.026)
    radius = 1.0 + broad + fine
    crown = max(0.0, z)
    taper = 1.0 - 0.29 * crown**1.6
    left_crown = -0.044 * crown**2
    lower_chamfer = max(0.0, -z - 0.42)
    vertex.co = Vector((
        x * radius * 0.132 * taper + left_crown + 0.018 * max(-z, 0.0),
        y * radius * 0.110 * taper + 0.012 * crown,
        z * radius * 0.182 - 0.009 * lower_chamfer,
    ))
    # Slightly compress the underside so it reads as a substantial object
    # resting in a scene, not an ornamental gem floating on a point.
    if vertex.co.z < -0.078:
        vertex.co.z = -0.078 + (vertex.co.z + 0.078) * 0.58

for polygon in stone.data.polygons:
    polygon.use_smooth = False

# Apply a fixed tilt to the mesh itself. The transform remains identity, so
# RealityKit can spin the stone about its exact center without an offset.
stone.rotation_euler = (math.radians(5), math.radians(-5), math.radians(-5))
bpy.context.view_layer.objects.active = stone
bpy.ops.object.transform_apply(location=False, rotation=True, scale=False)

material = bpy.data.materials.new("WarmTranslucentQuartz")
material.use_nodes = True
bsdf = material.node_tree.nodes.get("Principled BSDF")
bsdf.inputs["Base Color"].default_value = (0.83, 0.89, 0.89, 1)
bsdf.inputs["Metallic"].default_value = 0.0
bsdf.inputs["Roughness"].default_value = 0.16
bsdf.inputs["IOR"].default_value = 1.47
bsdf.inputs["Transmission Weight"].default_value = 0.88
bsdf.inputs["Coat Weight"].default_value = 0.12
bsdf.inputs["Coat Roughness"].default_value = 0.09
absorption = material.node_tree.nodes.new("ShaderNodeVolumeAbsorption")
absorption.inputs["Color"].default_value = (0.93, 0.87, 0.78, 1)
absorption.inputs["Density"].default_value = 1.6
material.node_tree.links.new(
    absorption.outputs["Volume"],
    material.node_tree.nodes["Material Output"].inputs["Volume"],
)
stone.data.materials.append(material)

# A separate warm inclusion lets RealityKit apply a different shader to the
# interior. It is deliberately asymmetric, like a mineral vein rather than a
# second concentric UI orb.
core_mesh = stone.data.copy()
core_mesh.name = "AmberCore_FacetedMesh"
core_mesh.materials.clear()
core = bpy.data.objects.new("AmberCore", core_mesh)
bpy.context.collection.objects.link(core)
core.scale = (0.76, 0.75, 0.63)
core.rotation_euler = (math.radians(-12), math.radians(16), math.radians(-11))
core.location = (-0.021, 0.011, -0.028)

# Fine angled inclusions are loose pieces in the *same* AmberCore mesh. Native
# code can keep addressing one named ModelEntity while the internal silhouette
# reads as layered mineral fractures instead of a centered round nugget.
bm = bmesh.new()
bm.from_mesh(core_mesh)
for center_x, center_y, center_z, width, height in (
    (-0.040, -0.028, 0.076, 0.016, 0.082),
    (0.018, 0.012, 0.063, 0.011, 0.066),
    (-0.003, -0.036, -0.005, 0.012, 0.058),
):
    v = [
        bm.verts.new((center_x - width, center_y, center_z - height * 0.46)),
        bm.verts.new((center_x + width, center_y - width * 0.4, center_z - height * 0.42)),
        bm.verts.new((center_x + width * 0.25, center_y + width, center_z - height * 0.37)),
        bm.verts.new((center_x - width * 0.17, center_y + width * 0.22, center_z + height * 0.54)),
    ]
    for indices in ((0, 2, 1), (0, 1, 3), (1, 2, 3), (2, 0, 3)):
        bm.faces.new(tuple(v[index] for index in indices))
bm.to_mesh(core_mesh)
bm.free()

core_material = bpy.data.materials.new("AmberCorePreview")
core_material.use_nodes = True
core_bsdf = core_material.node_tree.nodes.get("Principled BSDF")
core_bsdf.inputs["Base Color"].default_value = (0.63, 0.25, 0.07, 1)
core_bsdf.inputs["Roughness"].default_value = 0.31
core_bsdf.inputs["Transmission Weight"].default_value = 0.41
core_bsdf.inputs["IOR"].default_value = 1.45
core_bsdf.inputs["Emission Color"].default_value = (0.62, 0.24, 0.04, 1)
core_bsdf.inputs["Emission Strength"].default_value = 0.12
core_mesh.materials.append(core_material)

# The editable source includes the presentation rig, but only the mesh is
# selected for USDZ export.
ground_material = bpy.data.materials.new("WarmIvoryBackdrop")
ground_material.diffuse_color = (0.55, 0.52, 0.47, 1)
ground_material.use_nodes = True
ground_bsdf = ground_material.node_tree.nodes.get("Principled BSDF")
ground_bsdf.inputs["Base Color"].default_value = (0.55, 0.52, 0.47, 1)
ground_bsdf.inputs["Roughness"].default_value = 0.82

bpy.ops.mesh.primitive_plane_add(size=200, location=(0, 0, -0.139))
ground = bpy.context.object
ground.name = "PreviewGround_NotExported"
ground.data.materials.append(ground_material)

def area_light(name, location, energy, color, size, target=(0, 0, 0)):
    data = bpy.data.lights.new(name, "AREA")
    data.energy = energy
    data.color = color
    data.shape = "DISK"
    data.size = size
    obj = bpy.data.objects.new(name, data)
    bpy.context.collection.objects.link(obj)
    direction = Vector(target) - obj.location
    obj.location = location
    direction = Vector(target) - obj.location
    obj.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()
    return obj

area_light("Softbox_WarmKey", (0.05, -0.45, 0.52), 25, (1.0, 0.76, 0.49), 0.45)
area_light("Softbox_CoolRim", (-0.34, 0.30, 0.36), 34, (0.65, 0.91, 1.0), 0.35)
area_light("Softbox_Fill", (0.43, 0.22, 0.28), 14, (1.0, 0.94, 0.82), 0.50)

camera_data = bpy.data.cameras.new("PreviewCamera")
camera = bpy.data.objects.new("PreviewCamera", camera_data)
bpy.context.collection.objects.link(camera)
camera.location = (0.36, -0.50, 0.27)
target = Vector((0, 0, -0.001))
camera.rotation_euler = (target - camera.location).to_track_quat("-Z", "Y").to_euler()
camera_data.type = "ORTHO"
camera_data.ortho_scale = 0.55
bpy.context.scene.camera = camera

world = bpy.context.scene.world
world.color = (0.52, 0.48, 0.41)
world.use_nodes = True
world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.80, 0.76, 0.68, 1)
world.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.22

scene = bpy.context.scene
scene.render.engine = "CYCLES"
scene.cycles.samples = 64
scene.render.resolution_x = 1200
scene.render.resolution_y = 1200
scene.render.resolution_percentage = 100
scene.view_settings.view_transform = "AgX"
scene.view_settings.look = "AgX - Medium High Contrast"
scene.view_settings.exposure = -0.45
scene.render.image_settings.file_format = "PNG"
scene.render.filepath = str(SOURCE_DIR / "QuietStone-preview.png")

bpy.context.preferences.filepaths.save_version = 0
bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE_DIR / "QuietStone.blend"))

bpy.ops.object.select_all(action="DESELECT")
stone.select_set(True)
core.select_set(True)
bpy.context.view_layer.objects.active = stone
bpy.ops.wm.usd_export(
    filepath=str(ASSET_DIR / "QuietStone.usdz"),
    selected_objects_only=True,
    export_materials=True,
    export_lights=False,
    export_cameras=False,
    export_animation=False,
    export_uvmaps=False,
    export_normals=True,
    convert_orientation=True,
)

# Render from the source scene as a design QA artifact.
bpy.ops.render.render(write_still=True)

print("QUIET_STONE_VERTICES", len(stone.data.vertices))
print("QUIET_STONE_TRIANGLES", len(stone.data.polygons))
print("QUIET_STONE_MESHES", stone.name, core.name)
print("QUIET_STONE_BOUNDS_METERS", tuple(round(v, 4) for v in stone.dimensions))
print("QUIET_STONE_USDZ", ASSET_DIR / "QuietStone.usdz")
