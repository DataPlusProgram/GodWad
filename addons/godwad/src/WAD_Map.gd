tool
extends Spatial
class_name WAD_Map

signal map_loaded(caller,mapName)
signal wadChange(caller)


enum THINGSPAWN {none,easy,medium,hard}
export(THINGSPAWN) var thingSpawn = THINGSPAWN.medium
export var interactables : bool  = true
export var scaleFactor = 0.05 setget scaleChange
var treeView = false
export var unshaded = true setget unshadedChange
export var texture_filtering = false
export var mipmaps = false
export var anisotrophic = false
var create_entites = false
export(Array,String,FILE) var WADs = [""] setget wadChange

export var enable_multiplayer_things = false
export var useShaderMaterials = true
export var drawTriggers = false
#export var runtimeOnly = false
var runtimeOnly = true
var ready = false
var wadLoaded = false
#var allSideDefs = {}

#export var generatePNGs = false

var hexenFormat = false
var levelInstancer# = load("res://addons/godwad/src/LevelInstancer.gd").new()
var lumpInstancer# = load("res://addons/godwad/src/lumpInstancer.gd").new()
var floorCreator# = load("res://addons/godwad/src/floorCreator.gd").new()
var imageParser## = load("res://addons/godwad/src/ImageParser.gd").new()
var g# = load("res://addons/godwad/srcdrwa/DFile.gd").new()
var thingInstancer# = load("res://addons/godwad/src/thingInstancer.gd").new()
var scriptLoader# = load("res://addons/godwad/src/scriptCreator.gd").new()
var thingMappings #= load("res://addons/godwad/src/thingMappings.gd").new()

var directories = {"MAPS":{},"GRAPHICS":{},"SOUND":{"MUSIC":{},"SPEAKER":{},"SOUND CARD":{}}}
var musicDir = directories["SOUND"]["MUSIC"]
var soundCardDir = directories["SOUND"]["SOUND CARD"]
var speakerDir = directories["SOUND"]["SPEAKER"]
var baseDirName = "WAD_resources"
var graphicsPath = baseDirName + "/" + "graphics"  

#var p1Start = null
#var p1Rot = Vector3.ZERO
func _ready():
	
	levelInstancer = load("res://addons/godwad/src/LevelInstancer.gd").new()
	lumpInstancer = load("res://addons/godwad/src/lumpInstancer.gd").new()
	floorCreator = load("res://addons/godwad/src/floorCreator.gd").new()
	imageParser = load("res://addons/godwad/src/ImageParser.gd").new()
	g = load("res://addons/godwad/src/DFile.gd").new()
	thingInstancer = load("res://addons/godwad/src/thingInstancer.gd").new()
	scriptLoader = load("res://addons/godwad/src/scriptCreator.gd").new()
	thingMappings = load("res://addons/godwad/src/thingMappings.gd").new()
	
	if thingSpawn!= THINGSPAWN.none:
		create_entites = true
		
	
	levelInstancer.parent = self
	imageParser.parent = self
	floorCreator.parent = self
	lumpInstancer.parent = self
	scriptLoader.parent = self
	thingInstancer.parent = self
	
	loadWAD()
	
	#if !Engine.is_editor_hint():	
	#	if WADs[0].find("DOOM.WAD") != -1:
	#		createMap("E1M2")
	#	else:
	#		createMap("MAP02")
		
		
	ready = true
	

func loadWAD():
	
	if WADs.size() == 0:
		print("There are no WAD files selected")
		return false
	
	if WADs.size() == 1 and WADs[0] == "":#we won't catch cases where there is an array size greather than one with all null paths but this should be extensive enough
		print("There are no WAD files selected")
		return false
	
	ready = false
	if thingSpawn!= THINGSPAWN.none:
		create_entites = true
	
	if !runtimeOnly:
		if !createDirectory(baseDirName): return
		if !createDirectory(graphicsPath): return
	for wad in WADs:
		if wad != "":
			readWAD(wad)

	if !parseEssential():
		directories["MAPS"].clear()
		return false
	
	wadLoaded = true
	return true
	

func createMap(mapName):
	levelInstancer.parent = self
	imageParser.parent = self
	floorCreator.parent = self
	levelInstancer.instance(self,mapName,directories["MAPS"][mapName])
	scriptLoader.parent = self
	
	var theDoors = get_tree().get_nodes_in_group("door")

	if treeView:
		var treeNode = Tree.new()
		var script = load("res://addons/godwad/src/Tree.gd")
		treeNode.set_script(script)
		dictTraverseParse(directories,null)
		treeNode.set_dict(directories)
		
		add_child(treeNode)
	emit_signal("map_loaded",self,mapName)
	ready = true
		
func readMap(file_,lsize,directory):
	var list = ["THINGS","LINEDEFS","SIDEDEFS","VERTEXES","SEGS","SSECTORS","NODES","SECTORS","REJECT","BLOCKMAP","BEHAVIOR","SCRIPTS"]

	var numberOfLumpsInMap = 0
	while(true):
		var end = true
		var ppos = file_.get_position()
		if ppos == file_.get_len():
			return numberOfLumpsInMap
		var buf = [file_.get_32(), file_.get_32(),file_.get_String(8)]
		
		for i in list:
			if buf[2] == i:
				if i == "BEHAVIOR":
					hexenFormat = true
					
				numberOfLumpsInMap += 1
				end = false
		
		if end == true:
			file_.seek(ppos)
			break
		
		var offset = buf[0]
		var size = buf[1]#file_.get_32()
		var name = buf[2]#file_.get_String(8)
		directory[name] = [file_,offset,size,[]]
		end = true
		
		

	return numberOfLumpsInMap

func readWAD(filepath):
	#var file_ = File.new()
	g.timings["IWAD directoy population time"] = OS.get_ticks_msec()
	var file = g.DFile.new()
	
	if file.loadF(filepath) == false:
		print("File could not be opened")
		return false
	

	var magic = file.get_String(4)
	var numLumps = file.get_32()
	var directoryOffset = file.get_32()


	var lumpNum = 0
	file.seek(directoryOffset)
	
	while lumpNum < numLumps:
		var offset = file.get_32()
		var size = file.get_32()
		var name = file.get_String(8)
		
		
		if (name[0] == "E" and name[2] == "M") or name.substr(0,3) == "MAP":
			if name != "MAPINFO":
				directories["MAPS"][name] = {}
			
				var numMapLumps = readMap(file,size,directories["MAPS"][name])
				lumpNum += numMapLumps

		elif (name.substr(0,2) == "DS"):
			soundCardDir[name] = [file,offset,size,[]]
		
		elif (name.substr(0,2) == "DP"):
			speakerDir[name] = [file,offset,size,[]]

		elif (name.substr(0,2) == "D_"):
			musicDir[name] = [file,offset,size,[]]
		
		elif (name.substr(0,4) == "DEMO"):
			directories["GRAPHICS"][name] = [file,offset,size,[]]
			
		elif(name == "GENMIDI"):
			directories["SOUND"][name] = [file,offset,size,[]]
			
		elif(name == "DMXGUS"):
			directories["SOUND"][name] = [file,offset,size,[]]
		else:
			directories["GRAPHICS"][name] = [file,offset,size,[]]
	
		lumpNum+=1
	g.timings["IWAD directoy population time"] = OS.get_ticks_msec() - g.timings["IWAD directoy population time"] 
	return true

func dictTraverseParse(node,parent):
	if typeof(node) == TYPE_DICTIONARY:
		for i in node.values():
			dictTraverseParse(i,node)
	else:
		var myKey = "r"
		for key in parent.keys():
			if typeof(parent[key]) == TYPE_ARRAY:
				if(parent[key] == node):
					lumpInstancer.parse(node[0],key,node)
		

func parseEssential():
	if !parse("GRAPHICS","PLAYPAL"):
		print("Couldn't find pallette within WAD file. Aborting")
		return false
		
	if !parse("GRAPHICS","COLORMAP"):
		print("Couldn't find colormap within WAD file. Aborting")
		return false
		
	if !parse("GRAPHICS","PNAMES"):
		print("Couldn't find PNAMES within WAD file. Aborting")
		return false

	return true
	
func parse(ldir,lname):
	if directories[ldir].has(lname):
		var dat = directories[ldir][lname]
		lumpInstancer.parent = self
		lumpInstancer.parse(dat[0],lname,dat)
		return true
	return false

func createDirectory(name):
	var dir = Directory.new()

	if not dir.dir_exists(name):
		var error = dir.make_dir(name)
		if error:
			print("Error creating directory")
			return false
	else:
		print("Directory already exists!")
	
	return true
	

func wadChange(value):
	WADs = value
	directories["MAPS"].clear()
	emit_signal("wadChange",self)
	

func unshadedChange(value):
	unshaded = value
	emit_signal("wadChange",self)

func scaleChange(value):
	scaleFactor = value
	emit_signal("wadChange",self)

func _get_configuration_warning():
	if WADs.size() == 0:
		return "No WAD files selected"
		
	if WADs.size() == 1 and WADs[0] == "":
		return "No WAD files selected"
		
	return ""


func decideType(file):
	var startPos = file.get_position()
	file.seek(0)
	

	while !file.eof_reached():
		var fileAsString = file.get_String(16)
		#print(fileAsString)
	#	file.String()
	file.seek(startPos)
	pass



func getAllLinesOfTag(tag):
	var tagStr = String(tag)
	if tag == 0:
		return [null]
	
	var targetSectors = null
	
	targetSectors = get_tree().get_nodes_in_group("sector_tag_" + String(tag))#we get the sectors that have the tag
	
	var sides=[]
	if targetSectors.empty():#no sectors have the tag so abandon
		return null
		
	var allSides = []
	for sector in targetSectors:
		var sectorSides = getAllSectorSides(sector)
		if sectorSides != null:
			allSides += sectorSides
			
	if allSides.empty():
		return null
	#this is the filter part of the function which will need to be broken off into its own function at some stage
	return allSides

func getAllSectorSides(sector):#get all sides relevent to sector
	var localSides =  getLocalSides(sector)
	var neighbourSides = getNeighbourSides(sector)
	return localSides + neighbourSides

func getLocalSides(sector):#all sides facing towards sector
	var sides = []
	for child in sector.get_children():
		if child.get_class() == "StaticBody":
			var lineMeshOrNull = getLineMesh(child)
			if lineMeshOrNull != null:
				if lineMeshOrNull.name:
					sides.append(lineMeshOrNull)
	return sides

func getNeighbourSides(sector,countEmpty = false):#all sides facing away from sector

	var sectorStr = sector.name
	var empties = []
	
	var emptySides = getAllEmptySidesOfSector(sectorStr)#we will get empty sides of our sector
	var allSides = get_meta("allSideDefs")
	if countEmpty:
		for i in emptySides:#we will check all our empty sides to see if they have an osides
			if allSides.has(i):#
				var dict = allSides[i]
				#print(dict)
				var node = get_node(dict["mid"]["meshNodePath"])
				empties.append(node) 


	var neighbourSidedefs = get_tree().get_nodes_in_group("neighbourSector" + sector.get_name())
	for i in empties:
		if !neighbourSidedefs.has(i):
			neighbourSidedefs.append(i)
	
	
	
	return neighbourSidedefs 
	

	
func getLineMesh(line):#for a given line StaticBody get its linedef MeshInstance Node
	for i in line.get_children():
		if i.has_meta("floor"):
			return i
	return null
	
func getSector(num):
	var children = get_children()
	for i in children:
		if i.has_meta("map"):
			#print(i.name)
			for c in i.get_children():
				if c.name == String(num):
					return c
	
	return null
	
func getSectorFloorAndCeil(sector):
	var ret = {}
	for c in sector.get_children():
		if c.has_meta("floor"):
			if c.name.find("linedef") == -1:#a hack because I doubled up on the floor metatag
				ret["floor"] = c

		if c.has_meta("ceil"):
			ret["ceil"] = c
	return ret

func stripScripts(node):
	for i in node.get_children():
		stripScripts(i)
		
	if node.get_script()!=null:
		node.queue_free()

func getNeighbourSectors(sector,includeEmptyLines = false):
	var neighbourLines = getNeighbourSides(sector,includeEmptyLines)
	var ret = []
	var sectorStr = sector.name
	for i in neighbourLines:

		var sec = i.get_parent().get_parent()
		if i.get_parent().get_class() != "StaticBody":
			sec = i.get_parent()
		if !ret.has(sec) and sec != null:
			ret.append(sec)
			
	var markerSides = get_meta("markerSides")
	if markerSides.has("neighbourSector" + sectorStr):
		var sec = getSector(markerSides["neighbourSector" + sectorStr])
		if !ret.has(sec) and sec != null:
			ret.append(sec)
		
	return ret

func getLowestNeighbourFloor(sector):
	var neighbours = getNeighbourSectors(sector)
	var lowestFloorHeight = sector.get_meta("floorHeight")
	
	for i in neighbours:
		
		
		var height = i.get_meta("floorHeight")
		if height == null:
			return 0
		if height < lowestFloorHeight:
			lowestFloorHeight = height
	
	return lowestFloorHeight

func getHighestNeighbourFloor(sector,includeSelf = true):
	var neighbours = getNeighbourSectors(sector)
	var highestFloorHeight = -INF
	if includeSelf:
		highestFloorHeight = sector.get_meta("floorHeight")
	
	for i in neighbours:
		
		var height = i.get_meta("floorHeight")
		if height == null:
			continue
		if height > highestFloorHeight:
			highestFloorHeight = height
	
	return highestFloorHeight

func getClosestNeighbourFloor(sector):
	var neighbours = getNeighbourSectors(sector)
	var myHeight = sector.get_meta("floorHeight")
	var closestHeight = myHeight
	
	for i in neighbours:
		
		var height = abs(i.get_meta("floorHeight")-myHeight)
		
		if height < closestHeight:
			closestHeight = height
	
	return closestHeight

func raiseNextNeighbourFloor(sector):
	
	var neighbours = getNeighbourSectors(sector,true)

	var myHeight = sector.get_meta("floorHeight")
	var closestHeight = INF
	
	for i in neighbours:
		
		var height = i.get_meta("floorHeight")
		if height == null:
			continue
		if height > myHeight and height < closestHeight:
			closestHeight = height
	
	if closestHeight == INF:
		return myHeight

	return closestHeight

func getLowestNeighbourCeil(sector,includeSelf = true):
	var neighbours = getNeighbourSectors(sector,true)
	var lowestCeilHeight = sector.get_meta("ceilingHeight")
	if includeSelf == false:
		lowestCeilHeight = INF
	
	for i in neighbours:
		if i.get_meta("ceilingHeight") == null:
			continue
		var height = i.get_meta("ceilingHeight")
		
		if height < lowestCeilHeight:
			lowestCeilHeight = height
	
	return lowestCeilHeight

func getChildMesh(col):
	if col.get_parent().get_class() == "Spatial":
		if col.has_meta("dimensions"):
			return col
			
	for i in col.get_children():
		if i.has_meta("dimensions"):
			return i
	
	return null
		

#func getAllEmptySidesOfSector(sectorInt):
#	var emptySides = get_meta("emptySides")
#	var ret = []
#	for i in emptySides:
#		var test =  emptySides[i]["sector"]
##		if emptySides[i]["sector"] == sectorInt:
#			ret.append(emptySides[i])
	
#	return ret

func getAllEmptySidesOfSector(sector):
	var ret = []
	var emptySides = get_meta("emptySides")
	var allSides = get_meta("allSideDefs")
#	
	for i in emptySides.values():
		if i["sector"] == int(sector):
			if !ret.has(i):
				ret.append(i)
	return ret
		

func deleteMap(map):
	#remove_child(map)
	map.queue_free()
	if find_node("things"):
		find_node("things").queue_free()
	levelInstancer.unsetParentMetas()
	

func getSectorsFromTag(side,tag):
	var sectorIndexs = []
	
	if tag!= 0:
		if get_meta("tagToSectorsDict").has(tag):
			sectorIndexs = get_meta("tagToSectorsDict")[tag] 
		else:
			print("sector not found for tag:",tag)
			var sides = get_meta("allSideDefs")
			var oSide = getChildMesh(side).get_meta("oSide")
			if oSide > sides.size():
				return []
			var targetSide = sides[oSide]
		
			sectorIndexs = [targetSide["sector"]]
	else:
		var sides = get_meta("allSideDefs")
		var oSide = getChildMesh(side).get_meta("oSide")
		var targetSide = sides[oSide]
		
		sectorIndexs = [targetSide["sector"]]
	
	return sectorIndexs


func rewall(side,sectionName,lineMesh,end,sector,reverse = false,offset= 0):
	var sideSector = getSector(side["sector"])
	var f =  side[sectionName]
	var textureName = side["textures"][sectionName]
	var texture = levelInstancer.getTexture(textureName)

	var start = side["floorZ"]
	var lVert = f["startVert"]/scaleFactor
	var rVert = f["endVert"]/scaleFactor

	if reverse:
		lVert = rVert
		rVert = f["startVert"]/scaleFactor

	var light = side["light"]
	var material = lineMesh.mesh.surface_get_material(0)
	var wall = levelInstancer.createWall(lVert,rVert,(end+offset)/scaleFactor,start/scaleFactor,0,Vector2.ZERO,true,texture,null,"",0,light)#texture,fCeil,"mid",type,sectorLight)
	sector.add_child(wall["node"])
