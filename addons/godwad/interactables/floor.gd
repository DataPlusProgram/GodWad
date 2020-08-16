extends Area

var ray
var mFloor
var backWall = null
var backWallOffset = Vector3(0,0,0)
var foundBackWall = false
var initialPos = Vector3.ZERO
var normal
#var backWallPost = Vector3.ZERO
var active = false
var myFloor = null
var scaleFactor = 1
var targetLines = null
var liftComponents = []
var map
var tag  = ""

func _ready():
	if(get_parent().get_class() == "StaticBody"):
		tag = get_parent().get_child(1).get_meta("tag")
	else:
		tag = get_parent().get_meta("tag")
	
	map = get_parent().get_parent().get_parent().get_parent()

	
	if tag != 0:
		targetLines =map.getAllLinesOfTag(tag)
	else:
		targetLines = [get_parent().get_child(1)]
	
	
	
	self.connect("body_entered",self,"body_entered")

	if targetLines == null:
		return 
	#for i in targetFloor:#we go through every line that is associated with the sector we target.
	#	if i.get_meta("isTwoSided") != true:
	#		continue
			
		
	#	if i.name.find("top") != -1:
	#		continue
			
		
	#	if i!= null:
	#		var liftComp = i.get_node_or_null("LiftComponent")
	#		if liftComp:
	#			if liftComponents.has(liftComp):
	#				continue
	#			else:
	#				liftComponents.append(liftComp)
			

	#		var targetMesh = i#.get_parent().get_child(1)
	##		var line = targetMesh.get_meta("line")
	#		var normal =  targetMesh.get_meta("normal")
	#		var scaleFactor =targetMesh.get_meta("scaleFactor")
	#		var diemnsion = targetMesh.get_meta("dimensions")
			

			#var liftComponent =Spatial.new()
			#liftComponent.set_script(load("res://addons/godwad/interactables/liftComponent.gd"))
			#liftComponent.name = "LiftComponent"
			
			#liftComponent.map = map

			
			#i.add_child(liftComponent)

			#liftComponents.append(liftComponent)
	

func body_entered(body):
	if body.get_class() != "StaticBody":
		for i in liftComponents:
			if i != null:
				i.active = true
				print("hit lift")
