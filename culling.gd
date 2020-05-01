tool
extends Spatial
export var active = false
export var run_in_editor = false
export (NodePath) var tracked_p
var visibility_original = {}
var visibility_enabled = []
var positions = {}
export var starting_path = "Level"
export var depth = 1
export var radius = 60
export var interval_btw_checks = 15
export var tres = 7
var counter = 0
export var debug = ""
export var reset_visibility = false
export var create_culling_grid = false
export var remove_culling_grid = false
export var grid_size = 20
export var delete_grid_parents = false
var cgrid = {}


func __set_owner(p, ow):
	p.set_owner(ow)
	if p.get_child_count() > 0:
		for c in p.get_children():
			__set_owner(c, ow)
func do_create_culling_grid(par = null):
	if !par:
		par = self
	for c in par.get_children():
		var t = c.translation
		var gx = round(t.x / grid_size) * grid_size
		var gy = round(t.y / grid_size) * grid_size
		var gz = round(t.z / grid_size) * grid_size
		if str(gx) == "-0":
			gx= 0
		if str(gy) == "-0":
			gy = 0
		if str(gz) == "-0":
			gz = 0
		var gname = str(gx).replace("-", "m") + "_" + str(gy).replace("-", "m") + "_" + str(gz).replace("-", "m")
		var g = null
		if !par.has_node(gname):
			g = Spatial.new()
			g.name = gname
			g.translation =  Vector3(gx, gy, gz)
			par.add_child(g)
			g.set_owner(get_parent())			
		else:
			g = par.get_node(gname)
		c.get_parent().remove_child(c)
		g.add_child(c)
		__set_owner(c, get_parent())
		c.translation = t - g.translation
		
func do_remove_grid():
	for c in get_children():
		do_reparent_grid_el(c)
		if delete_grid_parents:
			c.free()
func do_reparent_grid_el(par):
	for c in par.get_children():
		c.get_parent().remove_child(c)
		add_child(c)
		__set_owner(c, get_parent())
		c.translation += par.translation
func _ready():
	if create_culling_grid:
		create_culling_grid = false
		var par = null
		if starting_path == "":
			par = self
		else:
			par = get_node(starting_path)
		if depth:
			for n in par.get_children():
				do_create_culling_grid(n)
		else:
			do_create_culling_grid()

func hide_if_out(nod, t):
	if !visibility_original.get(nod.get_path()):
		visibility_original[nod.get_path()] = nod.visible
	var dist = nod.translation - t.translation
	if dist.length() > radius and !visibility_enabled.has(nod.get_path()):
		nod.hide()
	else:
		nod.show()
		visibility_enabled.append(nod.get_path())
func _process(_delta):
	counter += 1
	var t = null
	if tracked_p:
		t = get_node(tracked_p)
	if reset_visibility:
		reset_visibility = false
		var par = null
		if starting_path == "":
			par = self
		for n in par.get_children():
			if depth:
				for nn in n.get_children():
					nn.show()
			else:
				n.show()
	if remove_culling_grid and run_in_editor and Engine.editor_hint:
		remove_culling_grid = false
		do_remove_grid()
	if create_culling_grid and run_in_editor and Engine.editor_hint:
		create_culling_grid = false
		var par = null
		if starting_path == "":
			par = self
		else:
			par = get_node(starting_path)
		if depth:
			for n in par.get_children():
				do_create_culling_grid(n)
		else:
			do_create_culling_grid()
	if active and t and counter > interval_btw_checks:
		counter = 0
		if Engine.editor_hint and !run_in_editor:
			return
		visibility_enabled = []
		for tt in t.get_children():
			if positions.get(tt.name):
				if (tt.translation - positions[tt.name]).length() < tres and !Engine.editor_hint:
					continue
			positions[tt.name] = tt.translation
			var par = null
			if starting_path == "":
				par = self
			else:
				par = get_node(starting_path)
			for n in par.get_children():
				if depth:
					for nn in n.get_children():
						hide_if_out(nn, tt)
				else:
					hide_if_out(n, tt)
		#print(visibility_enabled.size())
	
