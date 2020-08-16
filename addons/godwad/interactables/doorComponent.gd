extends Spatial

var open = false

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
	ONE_SECOND,
	FOUR_SECONDS,
	NINE_SECONDS,
	THIRTY_SECONDS
}

var tag = ""
var trigger
var action
var wait 
var monsters
var keyName = ""
var opposingDoor = null
var matchingCeil = null
var targetDisplacement = Vector3.ZERO
var speed = Vector3(0,-200,0)
var initialPos = Vector3.ZERO
var ceilDiff = null
var gParent = null



func _ready():
	gParent = get_parent().get_parent()
	initialPos = gParent.translation
	#self.connect("body_entered",self,"body_entered")
	


func _physics_process(delta):
	
	if matchingCeil != null and ceilDiff == null:
		ceilDiff = gParent.translation.y - matchingCeil.translation.y

	if open:
		if gParent.has_meta("ceilHeight"):
			var ceilHeight = gParent.get_meta("ceilHeight")
			if gParent.translation.y - initialPos.y >= ceilHeight:
				return
			
			if opposingDoor != null:
				if opposingDoor.has_meta("ceilHeight"):
					if gParent.translation.y - initialPos.y >= min(ceilHeight,opposingDoor.get_meta("ceilHeight")):
						return
			
			
		gParent.translation.y += 0.05
		if opposingDoor!=null:
			opposingDoor.translation.y += 0.05
		
		if matchingCeil != null:
			matchingCeil.translation.y = gParent.translation.y - ceilDiff
		

func body_entered(body):
	if body.get_class() != "StaticBody":
		open(body)
		open = true
		


func open(body):
	if keyName!= "" and body.has_meta("key"):
		if body.get_meta("key") != keyName:
			return


