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
var allSideDefs = {}
var sectorToTagDict = {}
#export var generatePNGs = false

var hexenFormat = false
var levelInstancer = load("res://addons/godwad/src/LevelInstancer.gd").new()
var lumpInstancer = load("res://addons/godwad/src/lumpInstancer.gd").new()
var floorCreator = load("res://addons/godwad/src/floorCreator.gd").new()
var imageParser = load("res://addons/godwad/src/ImageParser.gd").new()
var g = load("res://addons/godwad/src/DFile.gd").new()
var thingInstancer = load("res://addons/godwad/src/thingInstancer.gd").new()
var scriptLoader = load("res://addons/godwad/src/scriptCreator.gd").new()
var thingMappings = load("res://addons/godwad/src/thingMappings.gd").new()

var directories = {"MAPS":{},"GRAPHICS":{},"SOUND":{"MUSIC":{},"SPEAKER":{},"SOUND CARD":{}}}
var musicDir = directories["SOUND"]["MUSIC"]
var soundCardDir = directories["SOUND"]["SOUND CARD"]
var speakerDir = directories["SOUND"]["SPEAKER"]
var baseDirName = "WAD_resources"
var graphicsPath = baseDirName + "/" + "graphics"  

var p1Start = null
var p1Rot = Vector3.ZERO
func _ready():
	
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
	#		createMap("E1M1")
	#	else:
	#		createMap("MAP01")
		
		
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
	
	#decideType(file)
	
	var magic = file.get_String(4)
	print(magic)
	var numLumps = file.get_32()
	var directoryOffset = file.get_32()

	#var currentFolder = ""
	#directories[currentFolder] = {}
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
		var sectorSides = getSectorSides(sector)
		if sectorSides != null:
			allSides += sectorSides
			
	if allSides.empty():
		return null
	#this is the filter part of the function which will need to be broken off into its own function at some stage
	return allSides

func getSectorSides(sector):#get all sides relevent to sector
	var sides = []
	
	for child in sector.get_children():#get sides that are facing the sector
		if child.get_class() == "StaticBody":
			var lineMeshOrNull = getLineMesh(child)
			if lineMeshOrNull != null:
				sides.append(lineMeshOrNull)
				
				
	var nieghbourSidedefs = get_tree().get_nodes_in_group("neighbourSector" + sector.get_name())#get sides that face away from sector but share a line with it
	

	return sides + nieghbourSidedefs
	
func getLineMesh(line):#for a given line StaticBody get its linedef MeshInstance Node
	for i in line.get_children():
		if i.has_meta("floor"):
			return i
	return null
	
func getSector(num):
	for i in get_children():
		if i.has_meta("map"):
			for c in i.get_children():
				if c.name == String(num):
					return c
	
	return null
	

func stripScripts(node):
	for i in node.get_children():
		stripScripts(i)
		
	if node.get_script()!=null:
		node.queue_free()
