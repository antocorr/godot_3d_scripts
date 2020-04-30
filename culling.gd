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
# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func hide_if_out(nod, t):
	if !visibility_original.get(nod.get_path()):
		visibility_original[nod.get_path()] = nod.visible
	var dist = nod.translation - t.translation
	if dist.length() > radius and !visibility_enabled.has(nod.get_path()):
		nod.hide()
	else:
		nod.show()
		visibility_enabled.append(nod.get_path())
func _process(delta):
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
	if active and t and counter > interval_btw_checks:
		counter = 0
		if Engine.editor_hint and !run_in_editor:
			return
		visibility_enabled = []
		for tt in t.get_children():
			if positions.get(tt.name):
				if (tt.translation - positions[tt.name]).length() < tres:
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
	
