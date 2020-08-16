tool
extends EditorPlugin
var editorInterface
var editorSceneTree
var scriptEditor
var dock
var curObj = null
var thread 

func _enter_tree():
	
	add_custom_type("WAD_Map","Spatial",load("res://addons/godwad/src/WAD_Loader.tscn"),preload("res://icon.png"))
	dock = load("res://addons/godwad/scenes/toolbar.tscn").instance()
	dock.get_node("create").connect("pressed", self, "loadWad")
	dock.get_node("createMap").connect("pressed", self, "createMap")
	add_control_to_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU,dock)
	dock.visible = false
	dock.get_node("createMap").visible = false

func handles(object):
	return object is WAD_Map

func make_visible(visible: bool) -> void:
	if dock:
		dock.set_visible(visible)

func _exit_tree():
	remove_custom_type("WAD_Map")
	#remove_control_from_docks(dock)

	remove_control_from_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU,dock)
	dock.free()
	pass


func edit(object):
	curObj = object
	var dropdown = dock.get_node("dropdown")
	var addSignal = true
	
	for sig in object.get_signal_connection_list("wadChange"):
		if sig["target"] == self:
			addSignal = false
	
	if addSignal:
		object.connect("wadChange", self, "wadChange")
	

	if curObj.has_meta("maps") and !curObj.directories["MAPS"].empty():
		populateDropdown(dropdown,curObj.get_meta("maps"))
		dropdown.visible = true
		dock.get_node("createMap").visible = true
	else:
		dropdown.visible = false
		dock.get_node("createMap").visible = false

func setMapNode(target,mapName):
	
	recursiveOwn(target,get_tree().edited_scene_root)

	

func loadWad():
	if curObj:
		if !curObj.loadWAD():
			return
			
		var dict = curObj.directories["MAPS"]
		var dropdown = dock.get_node("dropdown")
		
	
		
		if dict.keys().size()>0:
			curObj.set_meta("maps",dict.keys())
			populateDropdown(dropdown,dict.keys())
			dropdown.visible = true
			dock.get_node("createMap").visible = true
		

func createMap():
	

	var dropdown = dock.get_node("dropdown")
	var mapName = dropdown.get_item_text(dropdown.get_selected_id())
	
	if curObj.get_node_or_null(mapName) == null:
		#thread = Thread.new()#this is very slow for some reason
		#thread.start(curObj, "createMap", mapName,2)
		
		dock.get_node("loadingLabel").visible = true
		dock.get_node("loadingLabel/anim").play("loading")
		
		curObj.createMap(mapName)
		recursiveOwn(curObj,get_tree().edited_scene_root)
		dock.get_node("loadingLabel").visible = false
	else:
		print("A map under that name already exists")

	
func recursiveOwn(node,newOwner):
	for i in node.get_children():
		recursiveOwn(i,newOwner)
	
	node.owner = newOwner

func populateDropdown(dropdown,names):
	dropdown.clear()
	

	for n in names:
		dropdown.add_item(n)

func wadChange(caller):
	caller.set_meta("maps",null)
	var dropdown = dock.get_node("dropdown")
	dropdown.visible = false
	dock.get_node("createMap").visible = false

	pass
