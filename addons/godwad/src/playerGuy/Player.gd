extends KinematicBody


export var speed = 20
export var rotSpeed = 200
export(NodePath) var wadMap

onready var weapon = $"Camera/weapon"
onready var weaponAnimation = weapon.get_node("switchAnim")
var gravVelo = Vector3.ZERO
var inputVelo = Vector3.ZERO
var dir = Vector3(0,0,0)
var rotMove = 0
var currentGun = "plasma_gun"
var pGun = ""
var weapons = {
	
	"fists":{
		"idle": "PUNGA0",
		"inventory_number":0
	},
	
	"pistol":{
			"idle":"PISGA0",
			"inventory_number":1,
			"sound_shoot": "DSPISTOL",
			"sound_hit" : "DSPUNCH",
			
		},
	
	"chaingun":{
		"idle": "CHGGA0",
		"inventory_number":3
		
	},
	
	"shotgun":{
		"idle" : "SHTGA0",
		"shoot_anim": ["SHTGB0","SHTGC0","SHTGD0"], 
		"shoot_flash": ["SHTFA0","SHTFB0"],
		"sound_shoot": "DSSHOTGN",
		"inventory_number":2
		
	},
	
	"super_shotgun":{
		"idle": "SHT2A0",
		"shoot_anim": ["SHT2GB0","SHT2GC0","SHT2GD0","SHT2GE0","SHT2GF0","SHT2G0","SHT2H0"],
		"shoot_flash": ["SHTFI0","SHTFJ0"],
		"inventory_number":2
		
	},
	
	"rocket_launcher":{
		"idle": "MISGA0",
		"shoot_anim": ["MISGB0"],
		"shoot_flash": ["MISFA0","MISFB0"],
		"inventory_number":4,
	},
	
	"plasma_gun":{
		"idle": "PLSGA0",
		"shoot_anim": ["PLSFA0","PLSFB0"],
		"recover_anim" : ["PLSGB0"],
		"inventory_number":5,
	},

}
# Called when the node enters the scene tree for the first time.
func _ready():
	set_meta("height",$"CollisionShape".shape.height)
	if get_node_or_null(wadMap)!= null:
		get_node(wadMap).connect("map_loaded",self,"map_loaded")
		var start = get_node(wadMap).get_meta("p1Start")#get_node(wadMap).p1Start
		if start != null:
			translation = start
	 # Replace with function body.


func _handle_input():

	dir = Vector3.ZERO
	rotMove = 0

	if Input.is_action_pressed("ui_up"):
		dir.z -= 1
	
	if Input.is_action_pressed("ui_down"):
		dir.z += 1
			
	if Input.is_action_pressed("ui_left"):
		rotMove += 1
		
	if Input.is_action_pressed("ui_right"):
		rotMove -= 1
		
	if Input.is_action_pressed("shoot"):
		shoot()

	input_weapon_switch("inventory_1",1)
	input_weapon_switch("inventory_2",2)
	input_weapon_switch("inventory_3",3)
	input_weapon_switch("inventory_4",4)
	input_weapon_switch("inventory_5",5)

func input_weapon_switch(inputEvent,inventoryNumber):
	if Input.is_action_pressed(inputEvent):
		for w in weapons.keys():
			if weapons[w]["inventory_number"] == inventoryNumber:
				if w != currentGun:
					currentGun = w
					weaponAnimation.play("weaponSwitchOut")
	
	

func _physics_process(delta):
	_handle_input()
	
	if wadMap:
		if get_node(wadMap).ready and !weaponAnimation.is_playing():
			if pGun != currentGun:
				var weaponSprite = weapons[currentGun]["idle"]
				weapon.texture = get_node(wadMap).levelInstancer.fetchSprite(weaponSprite)
				weaponAnimation.play("weaponSwitchIn")
				pGun = currentGun
	
	#translation += 
#	rotation_degrees.y += rotMove * rotSpeed
	inputVelo = (dir*speed).rotated(Vector3(0,1,0),(rotation.y))
	gravVelo += Vector3(0,-0.5,0)
	var totalVelo = inputVelo + gravVelo
	if (is_on_floor()):
		gravVelo.y = -0.01
		
	move_and_slide(totalVelo,Vector3.UP)
	
func _process(delta):
	rotation_degrees.y += rotMove * rotSpeed * delta

	
func map_loaded(caller,mapName):
	if caller.get_meta("p1Start") == null:
		return
	translation = caller.get_meta("p1Start") #+ Vector3(0,$"CollisionShape".shape.height,0)
	rotation_degrees = caller.get_meta("p1Rot")
	
func shoot():
	var collider = $"Camera/RayCast".get_collider()
	if collider != null:
		if collider.get_parent()!= null:
			var target = collider.get_parent()
			if collider.has_method("takeDamage"):
				collider.takeDamage(20)
