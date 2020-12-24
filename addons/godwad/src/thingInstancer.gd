extends Node

enum THINGFLAG{
	SKILL_EASY = 0x01,
	SKILL_MEDIUM = 0x02,
	SKILL_HARD = 0x04,
	IS_DEAF = 0x08,
	NOT_IN_SINGLEPLAER = 0x10,
	BOOM_NOT_IN_DM = 0x20,
	BOOM_NOT_IN_COOP = 0x40,
	MBF_FRIENDLY_MONSTER = 0x80
	
}

var parent = null
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func parseThings(map):
	
	var tm = parent.thingMappings
	var test = map["THINGS"]
	var file = map["THINGS"][0]
	var offset = map["THINGS"][1]
	var size = map["THINGS"][2]
	var thingParent = Spatial.new()
	thingParent.name = "things"
	parent.add_child(thingParent)
	file.seek(offset)
	#var things = tm.things
	

	var thingSize = (size)
	
	while(file.get_position()-offset < size):
		
		var position = Vector3(file.get_16u(),0,-file.get_16u())
		var rotation = file.get_16()
		var doomEdType = file.get_16() 
		var flags = file.get_16()
		
		var spawnObject = false
		
		
		if flags & THINGFLAG.NOT_IN_SINGLEPLAER != 0:
			if parent.enable_multiplayer_things == false:
				continue
		
		if flags & THINGFLAG.SKILL_EASY !=0:
			if parent.thingSpawn == parent.THINGSPAWN.easy:
				spawnObject = true
		
		if flags & THINGFLAG.SKILL_MEDIUM != 0:
			if  parent.thingSpawn == parent.THINGSPAWN.medium:
				spawnObject = true
		
		if flags & THINGFLAG.SKILL_HARD !=0:
			if parent.thingSpawn == parent.THINGSPAWN.hard:
				spawnObject = true
				
		if spawnObject == false:
			continue
		
		var thing = tm.get_thing(doomEdType)
		if thing == null:
			continue
			
		var spriteName = thing[1]
		if spriteName == "":
			continue
		
		
		var spr = null
		if spriteName != "none":
			spr = parent.levelInstancer.fetchSprite(spriteName)
			if spr == null:
				continue
		
			
		var rot = 0
		if rotation == 0: rot = 0
		if rotation == 1: rot = 45
		if rotation == 2: rot = 90
		if rotation == 3: rot = 135
		if rotation == 4: rot = 180
		if rotation == 5: rot = 225
		if rotation == 6: rot = 270
		if rotation == 7: rot = 315
		
		var collisionHeight = 32
		
		if thing.size() > 3:
			collisionHeight = thing[3]
			
		var thingParts = createEnt(spr, position*parent.scaleFactor,rot,collisionHeight)
		var collisionNode = thingParts[1]
		var thingSprite = thingParts[0]
		
		if doomEdType == 1:
			parent.set_meta("p1Start",thingSprite.translation)
			parent.set_meta("thingSprite",Vector3(0,rotation-90,0))
			#parent.p1Start = thingSprite.translation
			parent.set_meta("p1Rot", Vector3(0,rotation-90,0))
			thingSprite.queue_free()
			continue
		
		if thing[2] != null:
			var script = load(thing[2])
			collisionNode.set_script(script)
			
			
			#var colision = node.get_child(0)
			#if colision != null:
			#	var script = load(thing[2])
			#	colision.set_script(script)
			
		parent.get_node("things").add_child(thingSprite)
	
		

func createEnt(sprite,pos,rotation,collisionHeight):
	var spriteNode = Sprite3D.new()
	spriteNode.billboard = SpatialMaterial.BILLBOARD_FIXED_Y
	spriteNode.axis = 2
	spriteNode.pixel_size = parent.scaleFactor
	if parent.unshaded == false:
		spriteNode.shaded = true
	
	if sprite != null:
		spriteNode.texture = sprite
	
	spriteNode.translation = pos
	spriteNode.alpha_cut = spriteNode.ALPHA_CUT_OPAQUE_PREPASS
	
	
	var info =  getFloorHeightAtPoint(pos)
	var sectorToTagDict = parent.get_meta("sectorToTagDict")
	if sectorToTagDict.has(String(info["sector"])):#most sectors don't have tags
		var sectorTag = sectorToTagDict[String(info["sector"])]
		var group = "thing_in_tag_sector_" + sectorTag
	
		spriteNode.add_to_group(group)
		spriteNode.set_meta("sector",info["sector"])
		
	var collisionNode = createCylinderCollisionChild(spriteNode,collisionHeight)
	
	if sprite != null:
		spriteNode.translation.y = info["height"] + (sprite.get_height()/2 * parent.scaleFactor)
	else:
		spriteNode.translation.y = info["height"]
	
	
	
	return [spriteNode,collisionNode]
	
	
func getFloorHeightAtPoint(point):
	var rc = RayCast.new()
	rc.enabled = true
	rc.translation.x = point.x
	rc.translation.z = point.z
	rc.translation.y = 5000
	rc.cast_to.y = -rc.translation.y*2
	rc.set_collision_mask_bit(0,0)
	rc.set_collision_mask_bit(1,1)#only floors on this bit
	parent.add_child(rc)
	rc.force_raycast_update()
	
	var colY = rc.get_collision_point().y
	
	if rc.get_collider() == null:
		return {"height":0,"sector":0}
		
	var gp = rc.get_collider().get_parent().get_parent()
	#print(gp.name)
	
	rc.queue_free()
	return {"height":colY,"sector":gp.name}
	
func createCylinderCollisionChild(node,height):
	var bodyNode = StaticBody.new()
	var shapeNode = CollisionShape.new()
	var shape = CylinderShape.new()
	shape.radius = 16 * parent.scaleFactor
	shape.height = max(height,0.001) * parent.scaleFactor
	
	shapeNode.shape = shape
	if height <=0:
		bodyNode.collision_layer = 0
		bodyNode.collision_mask =0 
		
	bodyNode.add_child(shapeNode)
	node.add_child(bodyNode)
	return bodyNode
