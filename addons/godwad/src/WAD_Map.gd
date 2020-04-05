tool
extends Spatial
class_name WAD_Map

signal map_loaded(caller,mapName)
signal wadChange(caller)

export var scaleFactor = 0.05 setget scaleChange
var treeView = false 
export var unshaded = true setget unshadedChange
export var texture_filtering = false
export(Array,String,FILE) var WADs = [""] setget wadChange

#export var runtimeOnly = false
var runtimeOnly = true
#export var generatePNGs = false

var levelInstancer = load("res://addons/godwad/src/LevelInstancer.gd").new()
var lumpInstancer = load("res://addons/godwad/src/lumpInstancer.gd").new()
var floorCreator = load("res://addons/godwad/src/floorCreator.gd").new()
var imageParser = load("res://addons/godwad/src/ImageParser.gd").new()
var g = load("res://addons/godwad/src/DFile.gd").new()
var scriptLoader = load("res://addons/godwad/src/scriptCreator.gd").new()

var directories = {"MAPS":{},"GRAPHICS":{},"SOUND":{"MUSIC":{},"SPEAKER":{},"SOUND CARD":{}}}
var musicDir = directories["SOUND"]["MUSIC"]
var soundCardDir = directories["SOUND"]["SOUND CARD"]
var speakerDir = directories["SOUND"]["SPEAKER"]
var baseDirName = "WAD_resources"
var graphicsPath = baseDirName + "/" + "graphics"  



func _ready():
	levelInstancer.parent = self
	imageParser.parent = self
	floorCreator.parent = self
	
	#loadWAD()
	#createMap("MAP30")

func loadWAD():
	if !runtimeOnly:
		if !createDirectory(baseDirName): return
		if !createDirectory(graphicsPath): return
	for wad in WADs:
		if wad != "":
			readWAD(wad)

	if !parseEssential():
		directories["MAPS"].clear()
		return false
		
	return true
	

func createMap(mapName):
	levelInstancer.parent = self
	imageParser.parent = self
	floorCreator.parent = self
	
	levelInstancer.instance(self,mapName,directories["MAPS"][mapName])

	emit_signal("map_loaded",self,mapName)
	if treeView:
		var treeNode = Tree.new()
		var script = load("res://addons/godwad/src/Tree.gd")
		treeNode.set_script(script)
		dictTraverseParse(directories,null)
		treeNode.set_dict(directories)
		
		
		add_child(treeNode)
func readMap(file_,lsize,directory):
	var list = ["THINGS","LINEDEFS","SIDEDEFS","VERTEXES","SEGS","SSECTORS","NODES","SECTORS","REJECT","BLOCKMAP"]


	while(true):
		var end = true
		var ppos = file_.get_position()
		if ppos == file_.get_len():
			return
		var buf = [file_.get_32(), file_.get_32(),file_.get_String(8)]
		
		for i in list:
			if buf[2] == i:
				end = false
		
		if end == true:
			file_.seek(ppos)
			break
		
		var offset = buf[0]
		var size = buf[1]#file_.get_32()
		var name = buf[2]#file_.get_String(8)
		directory[name] = [file_,offset,size,[]]
		end = true
		
		

		

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

	var currentFolder = ""
	#directories[currentFolder] = {}
	var lumpNum = 0
	file.seek(directoryOffset)
	
	while lumpNum < numLumps:
		var offset = file.get_32()
		var size = file.get_32()
		var name = file.get_String(8)

		
		if (name[0] == "E" and name[2] == "M") or name.substr(0,3) == "MAP":
			currentFolder = name
			directories["MAPS"][currentFolder] = {}
			
			readMap(file,size,directories["MAPS"][currentFolder])
			lumpNum += 10

		elif (name.substr(0,2) == "DS"):
			soundCardDir[name] = [file,size,name,[]]
		
		elif (name.substr(0,2) == "DP"):
			speakerDir[name] = [file,size,name,[]]

		elif (name.substr(0,2) == "D_"):
			musicDir[name] = [file,size,name,[]]
		
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
		
	#if !parse("GRAPHICS","COLORMAP"):
	#	print("Couldn't find colormap within WAD file. Aborting")
	#	return false
		
	if !parse("GRAPHICS","PNAMES"):
		print("Couldn't find PNAMES within WAD file. Aborting")
		return false

	return true
	
func parse(ldir,lname):
	if directories[ldir].has(lname):
		var dat = directories[ldir][lname]
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
