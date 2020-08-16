extends Area

enum MAP_FORMAT{
	DOOM,
	DDOM2
}

onready var map = get_parent().get_parent().get_parent()
func _ready():
	
	self.connect("body_entered",self,"body_entered")



func body_entered(body):

	if body.get_class() != "StaticBody":
		map.queue_free()
		var t = getFormat(map.name)
		var nextMap = map.name
		if t == MAP_FORMAT.DOOM:
			nextMap = incrementDoomMap(map.name)

		if t == MAP_FORMAT.DDOM2:
			nextMap = incrementDoom2Map(map.name)
			
		map.get_parent().createMap(nextMap)
		
			
	
func getFormat(nameStr):
	if nameStr[0] == 'E' and nameStr[2] == 'M':
		return MAP_FORMAT.DOOM
	
	if nameStr.substr(0,3) == "MAP":
		return MAP_FORMAT.DDOM2
	

func incrementDoomMap(nameStr):
	var ret = nameStr
	
	var lastDigit = int(nameStr[3])
	if lastDigit < 9:
		lastDigit+= 1
		nameStr[3] = String(lastDigit)
		return(nameStr)
		
	if lastDigit >= 9:
		var firstDigit = int(nameStr[1])
		if firstDigit < 4:
			firstDigit += 1
			ret = "E" + String(firstDigit) + "M1"
		return ret
		
		
func incrementDoom2Map(nameStr):
	var digitsStr = nameStr[3] + nameStr[4]
	var digits = int(digitsStr)
	digits += 1
	
	if digits < 10:
		digitsStr = "0" + String(digits)
	else:
		digitsStr = String(digits)
	
	return "MAP" + digitsStr
	
	
