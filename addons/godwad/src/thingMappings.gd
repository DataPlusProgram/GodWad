extends Resource
class_name  thingMappings

func debug():
	var count = 0
	for i in things1_89:
		print("%s:%s" % [count,i])
		count += 1

func get_thing(num):
	var thing
	

	if num<= 89:
		if num > things1_89.size():
			print("thing number out of range")
			return null
		
		if things1_89[num] == null:
			print("thing number %s not implemented" % num)
			return null
		
		return things1_89[num]
		
	if num >= 2001 and num <= 2049:
		if num > (2001 + things2001_2049.size()-1):
			print("thing number %s out of range" % num)
			return null
		
		if things2001_2049[num-2001] == null:
			print("thing number %s not implemented" % num)
			return null
		
		return things2001_2049[num-2001]
		

	if num >= 3000:
		if num > (3001 + things3000_3006.size()-1):
			print("thing number %s out of range" % num)
			return null
		
		if things3000_3006[num-3001] == null:
			print("thing number %s not implemented" % num)
			return null
		
		return things3000_3006[num-3001]
		
	return null

export var things1_89 = [
["","",null],
["Player 1 start","PLAYA1",null,0],
["Player 2 start","",null,0],
["Player 3 start","",null,0],
["Player 4 start","",null,0],
["Blue keycard","BKEYA0",null],
["Yellow keycard","YKEYA0",null],
["Spiderdemon","SPIDA1D1",null],
["Backpack","BPAKA0",null],
["Shotgun guy","SPOSA1","res://addons/godwad/interactables/thingScripts/enemy.gd",64],
["Bloody mess","",null],
["Deathmatch start","",null],
["Bloody mess","",null],
["Red keycard","RKEYA0",null],
["Teleport landing","none","res://addons/godwad/thingScripts/teleportLanding.gd",0],
["Dead player","",null],
["Cyberdemon","",null],
["Energy cell pack","",null],
["Dead former humann","",null],
["Dead former sargent","",null],
["Dead imp","",null],
["Dead demon","",null],
["Dead cacodemon","",null],
["Dead lost soul","",null],
["Pool of blood and flesh","",null],
["Impaled human","",null],
["Twitching impared human","",null],
["Skull on a pole","POL4A0",null],
["Five skulls","POL2A0",null],
["Pile of skulls and candles","",null],
["Tall green pillar","",null],
["Short green pillar","",null],
["Tall red pillar","",null],
["Short red pillar","",null],
["Candle","CANDA0",null],
["Candelbra","CBRAA0",null],
["Short green pillar bit beating heart","",null],
["Short red pillar with skull","",null],
["Red skull key","",null],
["Yellow skull key","",null],
["Blue skull key","",null],
["Evil eye",'',null],
["Floating skull","",null],
["Burnt trere","",null],
["Tall blue firestick","",null],
["Tall green firestick","",null],
["Tall red firestick","",null],
["Brown stump","",null],
["Tall techno column","ELECA0",null],
["Hanging victim, twitching","",null],
["Hanging victim, arms out","",null],
["Hanging victim, one-legged","",null],
["Hanging pair of legs","",null],
["Hanging leg","",null],
["Large brown tree","TRE2A0",null],
["Short blue firestick","",null],
["Short green firestick","",null],
["Short red firestick","",null],
["Spectre","",null],
["Hanging victim, arms out","",null],
["Hanging pair of legs","",null],
["Hanging victim, one-legged","",null],
["Hanging leg","",null],
["Hanging victim, twitching","",null],
["Arch-vile","",null],
["Heavy weapon dude","",null],
["Revenant","SKELA0",null],
["Mancubus","",null],
["Arachnotron","",null],
["Hell knight","",null],
["Burning barrel","",null],
["Pain elemental","",null],
["Commander Keen","",null],
["Hanging victim", "guts removed","",null],
["Hanging victim", "guts and brain removed","",null],
["Hanging torso", "looking down","",null],
["Hanging torso", "open skull","",null],
["Hanging torso", "looking up","",null],
["Hanging torso", "brain removed","",null],
["Pool of blood","POB1A0",null],
["Pool of blood 2","POB2A0",null],
["Pool of brains","BRS1A0",null],
["Super shotgun","SGN2A0",null],
["Megasphere","MEGAA0",null],
["Wolfenstein SS","SSWVA1",null],
["Tall techno floor lamp","TLMPA0",null],
["Short techno floor lamp","TLP2A0",null],
["Spawn spot","",null],
["Romero's head","BBRNA0",null],
["Monster spawner","",null],
]

export var things2001_2049 = [
["Shotgun","SHOTA0",null,0],
["Chaingun","MGUNA0",null,0],
["Rocket launcher","LAUNA0",null,0],
["Plasma gun","PLASA0",null,0],
["Chainsaw","CSAWA0",null,0],
["BFG9000","BFUGA0",null,0],
["Clip","CLIPA0",null,0],
["4 shotgun shells","SHELA0",null,0],
["","",null],
["Rocket","ROCKA0",null,0],
["Stimpack","STIMA0",null,0],
["Medkit","MEDIA0",null,0],
["Supercharge","SOULA0",null,0],
["Heatlh bonus","BON1A0","res://addons/godwad/thingScripts/collectable.gd",0],
["Armor bonus","BON2A0","res://addons/godwad/thingScripts/collectable.gd",0],
["","",null],
["","",null],
["Armor","ARM1A0",null],
["Megarmor","ARM2A0",null],
["","",null],
["","",null],
["Invulnerability","PINVA0",null],
["Berserk","PSTRA0",null],
["Partial invisibility","PINSA0",null],
["Radiation shielding suit","SUITA0",null],
["Computer area map","PMAPA0",null],
["","",null],
["Floor lamp","COLU",null],
["","",null],
["","",null],
["","",null],
["","",null],
["","",null],
["","",null],
["Exploding barrel","BAR1A0",null],
["","",null],
["","",null],
["","",null],
["","",null],
["","",null],
["","",null],
["","",null],
["","",null],
["","",null],
["","",null],
["Box of rockets","BROKA0",null,0],
["Energy cell","CELLA0",null,0],
["Box of bullets","AMMOA0",null,0],
["Box of shotgun shells","SBOXA0",null,0],
]

export var things3000_3006 = [
["Imp","TROOA1","res://addons/godwad/interactables/thingScripts/enemy.gd",64],
["Demon","SARGA1",null],
["Baron of Hell","BOSSA1",null],
["Zombieman","POSSA1",null],
["Cacodemon","HEADA1",null],
["Lost soul","SKULA1",null]
]

var impAnim = {
	"s1" : "TROOA1",
	"s2" : "TROOB1",
	"sw" : "TROOA2A8",
	"sw2": "TROOA2B8",
	"w"  : "TROOA3A7",
	"w2" : "TROOA3B7",
	"ne" : "TROO4A6" ,
	"ne2": "TROO4B6" ,
	"n"  : "TROOA5"
	
}
