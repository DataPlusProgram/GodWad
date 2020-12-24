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

	
		
	if meshDict["isBackSide"]:
		return null
	
	var type = meshDict["type"]
	if type == 0:
		return null

	var targetSection = null
	var linedefIndex = meshDict["linedefIndex"]
	
	var sector = parent.getSector(meshDict["sector"])
	if sector == null:
		breakpoint
	if meshDict.has("mid"): targetSection = meshDict["mid"]
	elif meshDict.has("low"):  targetSection = meshDict["low"]
	elif meshDict.has("high"): targetSection = meshDict["high"]
	else:
		return null
		
	if targetSection["meshNode"].get_parent() == null:
		print("parentless target: linedef " ,linedefIndex)
		return

	var script = null
	match type:
		1,2,3,4,16,26,27,28,29,31,32,33,34,42,46,50,61,63,75,76,86,90,99,103,105,107,108,109,110,111,112,113,114,115,116,117,118,133,134,135,136,137,175,196:
			script = createScriptTrigger("res://addons/godwad/interactables/door.gd",targetSection,linedefIndex,type,sector)
				
	match type:
		39,97:
			script = createScriptTrigger("res://addons/godwad/interactables/teleportInteraction.gd",targetSection,linedefIndex,type,sector)
		
	match type:
		21,62,88,120:
			script = createScriptTrigger("res://addons/godwad/interactables/lift2.gd",targetSection,linedefIndex,type,sector)	
			
	match type:
		11:
			#var interactionBox = createInteractionHitbox(targetSection,linedefIndex,type,sector)
			#script = load("res://addons/godwad/interactables/levelExit.gd")
			#interactionBox.set_meta("linedeftype",type)
			#interactionBox.set_script(script)
			#targetSection["meshNode"].get_parent().add_child(interactionBox)
			script = createScriptTrigger("res://addons/godwad/interactables/levelExit.gd",targetSection,linedefIndex,type,sector)
			
	match type:
		5,15,18,19,20,23,26,24,30,36,37,38,45,55,56,58,59,60,64,65,66,69,70,71,78,82,83,84,91,92,93,94,96,98,101,102,161,179,180:
			script = createScriptTrigger("res://addons/godwad/interactables/floor.gd",targetSection,linedefIndex,type,sector)
		
	match type:
		7,8,100,127,256,257,258,259:
			script = createScriptTrigger("res://addons/godwad/interactables/stair.gd",targetSection,linedefIndex,type,sector)	
	
	return script

func createInteractionHitbox(meshNode,lindefIndex,type,sector):
	var area = Area.new()
	area.name = "linedef %s interactbox" % lindefIndex
	
	if meshNode == null:
		return
	
	if type == 0:
		return
	
	var colisionShape 
	
	var boxCollisionShapeNode = CollisionShape.new()
	var boxShape = BoxShape.new()
	var dimen = meshNode["dimensions"]

	boxShape.extents.x = 10*parent.scaleFactor #fixed-size depth
	
	if sector.get_meta("ceilingHeight") == null or sector.get_meta("floorHeight") == null:
		boxShape.extents.y = 0
	else:
		boxShape.extents.y = (sector.get_meta("ceilingHeight") - sector.get_meta("floorHeight"))*parent.scaleFactor#this is a quick fix.No texture mids are being ingored and floors will be used instead causing it to be too small
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


func createScriptTrigger(scriptPath,targetSection,linedefIndex,type,sector):
	
	var interactionBox = createInteractionHitbox(targetSection,linedefIndex,type,sector)
	var scriptRes = load(scriptPath)
	interactionBox.set_meta("linedeftype",type)
	interactionBox.set_script(scriptRes)
	
	match type:
		7,8,100,127,256,257,258,259:
			#print(targetSection["meshNode"].get_class())
			#print(targetSection["meshNode"].get_meta("normal"))
			interactionBox.myNormal = targetSection["meshNode"].get_meta("normal")
	

		
	
	if targetSection["meshNode"].get_parent().get_class() == "StaticBody":
		targetSection["meshNode"].get_parent().add_child(interactionBox)
	else:
		targetSection["meshNode"].add_child(interactionBox)
		
	return scriptRes
