extends RayCast


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var gParent= null
var test

var floorFinderRay = null
# Called when the node enters the scene tree for the first time.
func _ready():
	
	enabled = true
	gParent = get_parent().get_parent()
	test = gParent.get_parent()
	add_exception(gParent.get_parent())
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if floorFinderRay != null:
		var collider = floorFinderRay.get_collider()
		if collider:
			if collider.has_meta("ceil"):
				get_parent().matchingCeil = collider.get_parent()
				floorFinderRay.queue_free()
				floorFinderRay = null
				
			else:
				floorFinderRay.add_exception(collider)
	
	var collider = get_collider()
	if collider:
		#if collider.has_meta("doorCollision"):
			if get_parent().opposingDoor == null:
				if collider.get_children().size()<2:
					return
				
				if collider.get_child(1).get_meta("isTwoSided") == false:
					return
				get_parent().opposingDoor = collider
				#print("%s , %s" % [self.get_name(),collider.get_name()])
				#deleteRaycastNode(collider)
				var localPos = gParent.get_parent().translation
				var otherPos = collider.translation
				

				floorFinderRay = RayCast.new()
				
				floorFinderRay.name = "floorFinderRay"
				floorFinderRay.translation = cast_to.normalized()*0.05
				floorFinderRay.cast_to = Vector3(0,-1000,0)
				floorFinderRay.enabled = true
				add_child(floorFinderRay)
			
	if get_parent().opposingDoor != null and get_parent().matchingCeil != null:
		queue_free()


func deleteRaycastNode(node):
	var index = node.get_name().find("_col") 
	var targetNode = node.get_name().substr(0,index-3)
	targetNode += "interactbox"
	var interactBox = node.get_node(targetNode)
	if interactBox!=null:
		var doorComponent = interactBox.get_node_or_null("DoorComponent")
		if doorComponent:
			doorComponent.remove_child(doorComponent.get_child(0))
