import bpy, sys, math
sys.path.insert(0, "/home/user/wayborne/tools/figure_pipeline/blender")
import make_variant as mv
bpy.ops.wm.open_mainfile(filepath="/home/user/wayborne/build/figures/variants/male_medium/male_medium.blend")
mv.ensure_mpfb()
rig = next(o for o in bpy.data.objects if o.type == "ARMATURE")
mesh = next(o for o in bpy.data.objects if o.type == "MESH")
for pb in rig.pose.bones:
    pb.matrix_basis.identity()
names = {g.index: g.name for g in mesh.vertex_groups}
attr = mesh.data.color_attributes.new("side", "FLOAT_COLOR", "POINT")
for v in mesh.data.vertices:
    l = sum(g.weight for g in v.groups if names[g.group].endswith("_l"))
    r = sum(g.weight for g in v.groups if names[g.group].endswith("_r"))
    attr.data[v.index].color = (1,0.1,0.1,1) if l > r and l > 0.3 else ((0.1,0.2,1,1) if r > l and r > 0.3 else (0.8,0.8,0.8,1))
mat = bpy.data.materials.new("m"); mat.use_nodes = True
nt = mat.node_tree; nt.nodes.clear()
o = nt.nodes.new("ShaderNodeOutputMaterial"); e = nt.nodes.new("ShaderNodeEmission"); a = nt.nodes.new("ShaderNodeAttribute")
a.attribute_name = "side"; nt.links.new(a.outputs["Color"], e.inputs["Color"]); nt.links.new(e.outputs[0], o.inputs[0])
mesh.data.materials.clear(); mesh.data.materials.append(mat)
sc = bpy.context.scene
sc.render.engine = "CYCLES"; sc.cycles.samples = 4; sc.render.film_transparent = True
sc.render.resolution_x, sc.render.resolution_y = 300, 400
cd = bpy.data.cameras.new("c"); cd.type = "ORTHO"; cd.ortho_scale = 2.2
cam = bpy.data.objects.new("c", cd); sc.collection.objects.link(cam)
cam.location = (-4.0, 0.0, 0.9); cam.rotation_euler = (math.radians(90), 0, math.radians(-90)); sc.camera = cam
sc.render.filepath = "/tmp/claude-0/-home-user-wayborne/6087156a-0315-56cc-b7aa-69cad162629d/scratchpad/probe/side_from_minusX.png"
bpy.ops.render.render(write_still=True)
