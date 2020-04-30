tool
extends Spatial

export var create_collider = false
export var unwrap_uv2 = false
export var active = false
export var path = "prefabs"
export var from_unity = false
export var add_root_spatial = false
export var make_atlas_scene = true
export var swap_with_existing_prefab = false
export (String, DIR) var prefab_dir
export var enable_baking_for_mesh = false
export var add_visibility_enabler = false
export var remove_visibility_enabler = false


var file = ""
var scenedir = ""
func get_scene_file_dir():
	var fname = get_tree().edited_scene_root.filename
	var relpath = fname.replace("res://", "")
	var path = []
	for st in relpath.split("/"):
		if ".tscn" in st :
			file = st
		else:
			scenedir += st + "/"
			
			

func _ready():
	pass # Replace with function body.

func _process(delta):
	if add_visibility_enabler:
		for n in get_children():
			if n is MeshInstance and !n.has_node("VE_" + n.name):
				var ve = VisibilityEnabler.new()
				ve.name = "VE_" + n.name
				print(n.get_aabb())
				n.add_child(ve)
				ve.set_owner(get_tree().edited_scene_root)
				#ve.translation = n.translation
				ve.aabb = n.get_aabb()
		add_visibility_enabler = false
	if remove_visibility_enabler:
		for n in get_children():
			if n is MeshInstance and n.has_node("VE_" + n.name):
				print("!")
				n.get_node("VE_" + n.name).free()
		remove_visibility_enabler = false
	if enable_baking_for_mesh:
		for n in get_children():
			if n is MeshInstance:
				n.use_in_baked_light = true	
		enable_baking_for_mesh = false
	if create_collider:
		for n in get_children():
			if n is MeshInstance:
				n.create_trimesh_collision()	
		create_collider = false
	if active:
		get_scene_file_dir()
		var dir = Directory.new()
		dir.open("res://" + scenedir)
		if not "/" in path:
			path += "/"
		dir.make_dir(path)
		var completepath = "res://" + scenedir + path
		var atlas_scene = null		
		for c in get_children():
			if c is MeshInstance:
				var scene = PackedScene.new()
				
				var clone = c.duplicate()
				clone.translation = Vector3(0, 0, 0)
				var n = null	
				var object_name = c.name
				if from_unity:
					clone.scale = Vector3(1, 1, 1)
					clone.rotation_degrees = Vector3(0, 0, 0)
					if "(" in c.name:
						object_name = c.name.split(" (")[0]
						clone.name = object_name
				if add_root_spatial:
					n = Spatial.new()
					n.name = c.name	
					n.add_child(clone)
					__set_owner(clone, n)
				else:
					n = clone
					for child in n.get_children():
						__set_owner(child, n)				
				#clone.set_owner(n)				
				
				var result = scene.pack(n)
				if result == OK:
					ResourceSaver.save(completepath + object_name + ".tscn", scene)
		if make_atlas_scene:			
			var sroot = Spatial.new()
			sroot.name = name
			var count = 0
			for c in get_children():
				if c is MeshInstance:
					count += 1
					var fname =  c.name + ".tscn"
					if from_unity:
						fname = c.name.split(" (")[0] + ".tscn"
					var linked = load(completepath + fname)
					linked = linked.instance()
					linked.translation = c.translation
					if from_unity:
						linked.rotation_degrees = c.rotation_degrees
						linked.scale = c.scale
						linked.name = c.name
					sroot.add_child(linked)
					linked.set_owner(sroot)
			if count > 0:
				atlas_scene = PackedScene.new()
				var result = atlas_scene.pack(sroot)
				if result == OK:
					var fname = "_Atlas_" +name + ".tscn"
					ResourceSaver.save(completepath + fname, atlas_scene)
					
		active = false
func __set_owner(p, ow):
	p.set_owner(ow)
	if p.get_child_count() > 0:
		for c in p.get_children():
			__set_owner(c, ow)
