extends Node

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


func create(type):
	var script
	match type:
		1,2,3,4,16,26,27,28,29,31,32,33,34,42,46,50,61,63,75,76,86,90,99,103,105,107,108,109,110,111,112,113,114,115,116,117,118,133,134,135,136,137,175,196:
			script = load("res://addons/godwad/interactables/doorInteraction.gd")
	return script

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
