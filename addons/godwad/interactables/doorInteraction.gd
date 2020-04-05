extends Area


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
var trigger
var action
var speed
var wait 
var monsters
var keyName = ""

func _ready():
	self.connect("body_entered",self,"body_entered")


func _process(delta):
	pass


func body_entered(body):
	if body.get_class() != "StaticBody":
		open(body)
		


func open(body):
	if keyName!= "" and body.has_meta("key"):
		if body.get_meta("key") != keyName:
			return

	#print(body.name)
	#get_parent().queue_free()


