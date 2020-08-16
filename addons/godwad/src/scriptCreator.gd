extends Node
var parent = null

enum TRIGGERS{
	WALK_OVER_ONCE,
	WALK_OVER_REPEATABLE,
	SWITCH_ONCE,
	SWITCH_REPEATABLE,
	GUNFIRE_ONCE,
	GUNFIRE_REPEATABLE,
	DOOR_ONCE,
	DOOR_REPEATABLE
}

enum ACTIONS{
	OPEN_WAIT_CLOSE,
	OPEN,
	CLOSE_WAIT_OPEN,
	CLOSE
}

enum SPEED{
	SLOW,
	NORMAL,
	TURBO
}

enum WAIT{
	NONE,
	ONE_SECOND,
	FOUR_SECONDS,
	NINE_SECONDS,
	THIRTY_SECONDS
}

var doorProfile = []

# Called when the node enters the scene tree for the first time.
func _ready():
	doorProfile.resize(137)
	doorProfile[1] = [TRIGGERS.DOOR_REPEATABLE,false,SPEED.SLOW,WAIT.FOUR_SECONDS,true,ACTIONS.OPEN_WAIT_CLOSE]
	doorProfile[2] = [TRIGGERS.WALK_OVER_ONCE,false,SPEED.SLOW,WAIT.NONE,false,ACTIONS.OPEN]
	doorProfile[3] = [TRIGGERS.WALK_OVER_ONCE,false,SPEED.SLOW,WAIT.NONE,false,ACTIONS.CLOSE]
	doorProfile[4] = [TRIGGERS.WALK_OVER_ONCE,false,SPEED.SLOW,WAIT.FOUR_SECONDS,true,ACTIONS.CLOSE]
	
	pass # Replace with function body.


func addFunction(meshDict):
	#var type = meshDict["type"]
	
	if meshDict["isBackSide"]:
		return null
	

	var type = meshDict["type"]
	

	var targetSection = null
	var linedefIndex = meshDict["linedefIndex"]
	
	if meshDict.has("mid"): targetSection = meshDict["mid"]
	elif meshDict.has("floor"):  targetSection = meshDict["floor"]
	elif meshDict.has("ceil"): targetSection = meshDict["ceil"]
	else:
		return null
	#	type = meshDict[mid]
	#	breakpoint
	#for section in type.keys():
	
	
	
	var script = null
	match type:
		1,2,3,4,16,26,27,28,29,31,32,33,34,42,46,50,61,63,75,76,86,90,99,103,105,107,108,109,110,111,112,113,114,115,116,117,118,133,134,135,136,137,175,196:
			var interactionBox = createInteractionHitbox(targetSection,linedefIndex,type)
			script = load("res://addons/godwad/interactables/doorInteraction.gd")
			interactionBox.set_script(script)
			targetSection["meshNode"].get_parent().add_child(interactionBox)
			
		
	match type:
		39,97:
			var interactionBox = createInteractionHitbox(targetSection,linedefIndex,type)
			script = load("res://addons/godwad/interactables/teleportInteraction.gd")
			interactionBox.set_script(script)
			if targetSection["meshNode"].get_parent().get_class() == "StaticBody":
				targetSection["meshNode"].get_parent().add_child(interactionBox)
			else:
				targetSection["meshNode"].add_child(interactionBox)
		
	match type:
		62,88,120:
			var interactionBox = createInteractionHitbox(targetSection,linedefIndex,type)
			script = load("res://addons/godwad/interactables/lift.gd")
			interactionBox.set_script(script)
			if targetSection["meshNode"].get_parent().get_class() == "StaticBody":
				targetSection["meshNode"].get_parent().add_child(interactionBox)
			else:
				targetSection["meshNode"].add_child(interactionBox)
			
	
	match type:
		11:
			var interactionBox = createInteractionHitbox(targetSection,linedefIndex,type)
			script = load("res://addons/godwad/interactables/levelExit.gd")
			interactionBox.set_script(script)
			targetSection["meshNode"].get_parent().add_child(interactionBox)
			
	match type:
		36:
			var interactionBox = createInteractionHitbox(targetSection,linedefIndex,type)
			script = load("res://addons/godwad/interactables/floor.gd")
			interactionBox.set_script(script)
			if targetSection["meshNode"].get_parent().get_class() == "StaticBody":
				targetSection["meshNode"].get_parent().add_child(interactionBox)
			else:
				targetSection["meshNode"].add_child(interactionBox)
			

	return script

func createInteractionHitbox(meshNode,lindefIndex,type):
	
	var area = Area.new()
	area.name = "linedef %s interactbox" % lindefIndex
	
	if meshNode == null:
		return
	
	if type == 0:
		return
	
	var colisionShape #= 
	
	#if get_parent().get_class() == "StaticBody":
	#	colisionShape = meshNode["meshNode"].get_parent().get_child(0)
		
	#else:
	#	colisionShape =
	
	
	var boxCollisionShapeNode = CollisionShape.new()
	var boxShape = BoxShape.new()
	var dimen = meshNode["dimensions"]
		
	boxShape.extents.x = 10*parent.scaleFactor
	boxShape.extents.y = dimen.y/2
	boxShape.extents.z = dimen.x/2

	var line = meshNode["startVert"]-meshNode["endVert"]
	var angle = (line.angle_to(Vector2.UP))

	boxCollisionShapeNode.translation.x=  - (line/2).x 
	boxCollisionShapeNode.translation.z=  - (line/2).y
	boxCollisionShapeNode.translation.y = -  dimen.y/2
		
	boxCollisionShapeNode.rotation =Vector3(0,angle,0)

		

	boxCollisionShapeNode.shape = boxShape
	area.add_child(boxCollisionShapeNode)
	
	return area
