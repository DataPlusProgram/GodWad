tool
extends Node


var textureCache = {}
var materialCache = {}
var mapNode = null
var parent = null
var scaleFactor
var doorVertices = []
var doorVerticesHeights = {}
var doorLines = []
var shaderUnshadedNoAlpha = load("res://addons/godwad/baseUnshadedNoAlpha.shader")
var shaderUnshadedAlpha = load("res://addons/godwad/baseUnshadedAlpha.shader")
var shaderShadedNoAlpha = load("res://addons/godwad/baseShadedNoAlpha.shader")
var shaderShadedAlpha = load("res://addons/godwad/baseUnshadedAlpha.shader")

var baseShaded
var emptySides = {}
var sides = []
enum LINDEF_FLAG{
	BLOCK_CHARACTERS = 0x01,
	BLOCK_MONSTERS = 0x02,
	TWO_SIDED = 0x4
	UPPER_UNPEGGED= 0x08,
	LOWER_UNPEGGED = 0x10,
	SECRET = 0x20,
	BLOCKS_SOUND = 0x40,
	NEVER_ON_AUTOMA = 0x80,
	ALWAYS_ON_AUTOMAP = 0x100,
	PASS_THRU = 0x200
}


enum WALL{
	UPPER,
	MID,
	LOWER
}

enum TEXTUREDRAW{
	BOTTOMTOP,
	TOPBOTTOM,
	GRID,
}

var material = null
var linedefDict = {}
func instance(par,mapname,map):
	var allMeshNodes = {}
	var markerSides = {}
	scaleFactor = parent.scaleFactor
	mapNode = Spatial.new()
	mapNode.name = mapname
	mapNode.set_meta("map","")
	parent.add_child(mapNode)
	mapNode.owner = parent
	parent.g.timings["map creation time"] = OS.get_ticks_msec()
	

	var lines = parseMap(mapname,"LINEDEFS")
	var verts =  parseMap(mapname,"VERTEXES")
	sides =parseMap(mapname,"SIDEDEFS")
	var sectors = parseMap(mapname,"SECTORS") 
	
	#var segs = parseMap(mapname,"SEGS")
	#var subsectors = parseMap(mapname,"SSECTORS")
	#var nodes = parseMap(mapname,"NODES")
	
	parseMap(mapname,"THINGS")

	parent.floorCreator.instance(mapNode,sectors,lines,sides,verts)
	
	for line in lines:
		var lindefIndex = lines.find(line)
		
		if line[0] > verts.size():
			print("vert out of bounds")
			continue
	
		var startVert = verts[line[0]]
		
		if line[1] > verts.size():
			print("vert out of bounds")
			continue
		
		var endVert = verts[line[1]]
		var flags = line[2]
		var type = line[3]
		var tag = line[4]
		var frontSideIndex = line[5]
		var backSideIndex = line[6]
		var frontSide = null
		var backSide = null
		var doubleSided = (flags & LINDEF_FLAG.TWO_SIDED) != 0
		
		if frontSideIndex < sides.size() : frontSide = sides[frontSideIndex]	
		if backSideIndex < sides.size() : backSide = sides[backSideIndex]
		#if lindefIndex == 5:
		#	breakpoint
		#if isDoor(type):
		#	registerDoor(startVert,endVert)
			
			
		var lowerUnpegged = (flags &  LINDEF_FLAG.LOWER_UNPEGGED) != 0

		if frontSide:
			var meshNode = drawSideDef(sectors,startVert,endVert,frontSide,backSide,lindefIndex,flags,type,frontSideIndex,backSideIndex)
			meshNode["isBackSide"] = false
			meshNode["type"] = type
			meshNode["linedefIndex"] = lindefIndex
			meshNode["sector"] = frontSide[5]
			meshNode["floorZ"] = sectors[frontSide[5]][0] * scaleFactor
			meshNode["light"] = sectors[frontSide[5]][4]
			meshNode["startVert"] = startVert
			meshNode["endVert"] = endVert
			allMeshNodes[frontSideIndex] = meshNode
			allMeshNodes[frontSideIndex] = meshNode
			
			setMeta(meshNode,"low",sectors,frontSide,backSide,startVert,endVert,tag,backSideIndex,doubleSided,lindefIndex,frontSideIndex)
			setMeta(meshNode,"mid",sectors,frontSide,backSide,startVert,endVert,tag,backSideIndex,doubleSided,lindefIndex,frontSideIndex)
			setMeta(meshNode,"high",sectors,frontSide,backSide,startVert,endVert,tag,backSideIndex,doubleSided,lindefIndex,frontSideIndex)
			
			
			if backSide:
				var flag = false
				if meshNode.has("low"): 
					meshNode["low"]["meshNode"].add_to_group("neighbourSector" + String(backSide[5]),true)
					flag = true
				if meshNode.has("mid"):   
					meshNode["mid"]["meshNode"].add_to_group("neighbourSector" + String(backSide[5]),true)
					flag = true
				if meshNode.has("high"):  
					meshNode["high"]["meshNode"].add_to_group("neighbourSector" + String(backSide[5]),true)
					flag = true
					
				if flag == false:
				#	var markerNode = Node.new()
				#	parent.getSector(meshNode["sector"]).add_child(markerNode)
					#markerNode.add_to_group("neighbourSector" + String(backSide[5]),true)
					
					#if !markerSides.has(["neighbourSector" + String(backSide[5])]):
					#	markerSides["neighbourSector" + String(backSide[5])] = []
					markerSides["neighbourSector" + String(backSide[5])] = (meshNode["sector"])
					#breakpoint
			
		if backSide:
			var meshNode = drawSideDef(sectors,endVert,startVert,backSide,frontSide,lindefIndex,flags,type,backSideIndex,frontSideIndex)
			meshNode["isBackSide"] = true
			meshNode["type"] = type
			meshNode["linedefIndex"] = lindefIndex
			meshNode["sector"] = backSide[5]
			meshNode["floorZ"] = sectors[backSide[5]][0] * scaleFactor
			meshNode["light"] = sectors[backSide[5]][4]
			meshNode["startVert"] = startVert
			meshNode["endVert"] = endVert
			allMeshNodes[backSideIndex] = meshNode
			
			setMeta(meshNode,"low",sectors,backSide,frontSide,startVert,endVert,tag,backSideIndex,doubleSided,lindefIndex,backSideIndex)
			setMeta(meshNode,"mid",sectors,backSide,frontSide,startVert,endVert,tag,backSideIndex,doubleSided,lindefIndex,backSideIndex)
			setMeta(meshNode,"high",sectors,backSide,frontSide,startVert,endVert,tag,backSideIndex,doubleSided,lindefIndex,backSideIndex)
			
			if frontSide:
				var flag = false
				if meshNode.has("low"):
					meshNode["low"]["meshNode"].add_to_group("neighbourSector" + String(frontSide[5]),true)
					
					
				if meshNode.has("mid"):
					meshNode["mid"]["meshNode"].add_to_group("neighbourSector" + String(frontSide[5]),true)
				
					
				if meshNode.has("high"):
					meshNode["high"]["meshNode"].add_to_group("neighbourSector" + String(frontSide[5]),true)
					
				if flag == false:
					
					#if !markerSides.has(["neighbourSector" + String(frontSide[5])]):
					#	markerSides["neighbourSector" + String(frontSide[5])] = []
					markerSides["neighbourSector" + String(frontSide[5])] = (meshNode["sector"])
					#var markerNode = Node.new()
					#parent.getSector(meshNode["sector"]).add_child(markerNode)
					#markerNode.add_to_group("neighbourSector" + String(frontSide[5]),true)
	
	setParentMetas(allMeshNodes,emptySides,markerSides)
#	createDoorSideWalls(lines,verts,sides,sectors)
	
	if parent.create_entites == true:
		parent.thingInstancer.parseThings(map)#you have to create things first before scripts because the teleport script will reference the teleport destination thing
	
	if parent.interactables == true:
		for meshDict in allMeshNodes:
			parent.scriptLoader.addFunction(allMeshNodes[meshDict])
	

	parent.g.timings["map creation time"] =  OS.get_ticks_msec() - parent.g.timings["map creation time"]


func setParentMetas(allSideDefs,emptySides,markerSides):
	parent.set_meta("allSideDefs", allSideDefs)
	parent.set_meta("emptySides",emptySides)
	parent.set_meta("markerSides",markerSides)

func unsetParentMetas():
	parent.set_meta("allSideDefs", null)
	parent.set_meta("emptySides",null)
	parent.set_meta("markerSides",null)

func registerDoor(startVert,endVert):
	if !doorVertices.has(startVert):
		doorVertices.append(startVert)
				
	if !doorVertices.has(endVert):
		doorVertices.append(endVert) 
		doorLines.append([startVert,endVert])


func setMeta(meshNode,section,sectors,frontSide,backSide,startVert,endVert,tag,oSide,isTwoSided,lineIndex,sidedefIndex):
	
	
	if !meshNode.has(section):
		return
	
	var sectionMesh = meshNode[section]["meshNode"]
	if sectionMesh.get_parent() == null:
		return
	var ceilingHeightF = sectors[frontSide[5]][1] - sectors[frontSide[5]][0]
	var ceil1 = sectors[frontSide[5]][1]
	var floor1 = sectors[frontSide[5]][0]
	
	
	if  backSide:
		var ceil2 = sectors[backSide[5]][1]
		var floor2 = sectors[backSide[5]][0]
		ceilingHeightF = max( ceil1-floor1, ceil2-floor2)
		sectionMesh.get_parent().set_meta("ceilHeight",ceilingHeightF*parent.scaleFactor)
		#sectionMesh.set_meta("oSide",oSide)
		
	else:
		sectionMesh.get_parent().set_meta("ceilHeight", (ceil1-floor1)*parent.scaleFactor)


		
	#sectionMesh.get_parent().set_meta("doorCollision","")
	sectionMesh.set_meta("sidedefIndex",sidedefIndex)
	sectionMesh.add_to_group("door",true)
	sectionMesh.set_meta("floor",floor1)
	sectionMesh.set_meta("scaleFactor",parent.scaleFactor)
	sectionMesh.set_meta("isTwoSided",isTwoSided)
	sectionMesh.set_meta("line",startVert-endVert)
	sectionMesh.set_meta("lineIndex",lineIndex)
	if sectionMesh.name == "linedef 967 top_col":
		breakpoint
	if frontSide:
		sectionMesh.set_meta("normal",(startVert-endVert).normalized())
	if backSide and !frontSide:
	#elif backSide:
		sectionMesh.set_meta("normal",(startVert-endVert).normalized()*-1)
		
	
	sectionMesh.set_meta("dimensions",meshNode[section]["dimensions"])
	sectionMesh.set_meta("tag",tag)
	sectionMesh.set_meta("oSide",oSide)



func getTexture(name):
	
	if parent.runtimeOnly:  return fetchTexture(name)
	if !parent.runtimeOnly: return fetchTextureDisk(name)

func fetchTexture(name,debug = false):
	if name in textureCache:
		return textureCache[name]
	var directories = parent.directories
	
	
	var tex1 = directories["GRAPHICS"]["TEXTURE1"]
	if tex1[3].empty(): #if we haven't parsed the wall textures
		parent.lumpInstancer.parse(tex1[0],"TEXTURE",tex1)#parse the wall textures

	
	
	var texture1 = directories["GRAPHICS"]["TEXTURE1"][3]
	for i in texture1:
		if i[0] == name:
			var subStr = name.substr(0,name.length()-1)
			if parent.imageParser.flatAnimationDict.list.has(subStr):#if is an animated texture
				textureCache[name] = animatedtextureWall(parent.imageParser.flatAnimationDict.list[subStr],"TEXTURE1")
			else:
				textureCache[name] = loadTexture(i)
				
			return textureCache[name]
	
	if !directories["GRAPHICS"].has("TEXTURE2"):
		return null
		
	var tex2 = directories["GRAPHICS"]["TEXTURE2"]
	if tex2[3].empty():
		parent.lumpInstancer.parse(tex2[0],"TEXTURE",tex2)
		
	var texture2 = directories["GRAPHICS"]["TEXTURE2"][3]
	for i in texture2:
		if i[0] == name:
			if parent.imageParser.flatAnimationDict.list.has(name):#if is an animated texture
				textureCache[name] = animatedtextureWall(parent.imageParser.flatAnimationDict.list[name],"TEXTURE1")
			else:
				textureCache[name] = loadTexture(i)
			
			return textureCache[name]
	
	return null

func fetchTextureDisk(name,debug = false):
	var path = ("res://" + parent.graphicsPath + "/" + name + ".tres")
	
	if doesFileExist(path):
		return load(parent.graphicsPath + "/" + name + ".tres")
		
	var directories = parent.directories
	
	var tex1 = directories["GRAPHICS"]["TEXTURE1"]
	if tex1[3].empty():
		parent.lumpInstancer.parse(tex1[0],"TEXTURE",tex1)
		
	
	
	var texture1 = directories["GRAPHICS"]["TEXTURE1"][3]
	for i in texture1:
		if i[0] == name:
			
			
			loadTexture(i)
			var imageTexture = load(parent.graphicsPath + "/" + name + ".tres")
			return imageTexture
	
	if !directories["GRAPHICS"].has("TEXTURE2"):
		return null
		
	var tex2 = directories["GRAPHICS"]["TEXTURE2"]
	if tex2[3].empty():
		parent.lumpInstancer.parse(tex2[0],"TEXTURE",tex2)
		
	var texture2 = directories["GRAPHICS"]["TEXTURE2"][3]
	for i in texture2:
		if i[0] == name:
			loadTexture(i)
			return load(parent.graphicsPath + "/" + name + ".tres")
	
	return null


func fetchFlat(name,saveToDisk = true):
	
	if !parent.directories["GRAPHICS"].has(name):
		return null
	
		
	var textureFileEntry = parent.directories["GRAPHICS"][name]
	var textureObj = null
		
	if name in textureCache:
		textureObj = textureCache[name]
	else:
		var subStr = name.substr(0,name.length()-1)
		if parent.imageParser.flatAnimationDict.list.has(subStr):#if is an animated texture
			var names = parent.imageParser.flatAnimationDict.list[subStr]
			textureObj = animatedtexture(names)
		

		else:
			textureObj= parent.imageParser.parseFlat(textureFileEntry[0],textureFileEntry[1],textureFileEntry[1],textureFileEntry[1],parent.useShaderMaterials)
			textureCache[name] = textureObj
	
			if parent.texture_filtering == false: textureObj.set_flags(2)
			else: textureObj.set_flags(7)
	
	
	
	return textureObj

func animatedtexture(names):
	var animatedTexture = AnimatedTexture.new()
	#print("number of frames %s" % names.size())
	animatedTexture.frames = names.size()
	var count = 0
	for name in names:
		var textureFileEntry = parent.directories["GRAPHICS"][name]
		var frameTexture = parent.imageParser.parseFlat(textureFileEntry[0],textureFileEntry[1],textureFileEntry[1],textureFileEntry[1],parent.useShaderMaterials)
		
		if parent.texture_filtering == false: frameTexture.set_flags(2)
		else: frameTexture.set_flags(7)
		
		animatedTexture.set_frame_texture(count,frameTexture)
		
		count += 1

	return animatedTexture


func animatedtextureWall(names,gdir):
	var animatedTexture = AnimatedTexture.new()
	var frameTexture = null
	animatedTexture.frames = names.size()
	var count = 0
	var textureDir = parent.directories["GRAPHICS"][gdir][3]
	for name in names:
		#var textureFileEntry = parent.directories["GRAPHICS"][name]
		for i in textureDir:
			if i[0] == name:
				frameTexture = loadTexture(i)
		
		if parent.texture_filtering == false: frameTexture.set_flags(2)
		else: frameTexture.set_flags(7)
		
		animatedTexture.set_frame_texture(count,frameTexture)
		
		count += 1

	return animatedTexture

func fetchFlatDisk(name):
	
	var path = ("res://" + parent.graphicsPath + "/" + name + ".tres")
	if doesFileExist(path):
		return load(parent.graphicsPath + "/" + name + ".tres")
	
	var textureFileEntry = parent.directories["GRAPHICS"][name]
	var textureObj = null
		
	
	textureObj= parent.imageParser.parseFlat(textureFileEntry[0],textureFileEntry[1],textureFileEntry[1],textureFileEntry[1],false,parent.useShaderMaterials)
	if parent.texture_filtering == false: textureObj.set_flags(2)
	else: textureObj.set_flags(7)


	var p = "res://" + parent.graphicsPath + "/" + name
	if parent.generatePNGs:
		textureObj.image.save_png(p + ".png")
	ResourceSaver.save(p + ".tres", textureObj)
	return load(p + ".tres")


func loadTexture(texture,saveToDisk = false,debug = false):

	var image = Image.new()
	var width = texture[2]
	var height  = texture[3]
	image.create(texture[2],texture[3],false,Image.FORMAT_RGBA8)
	var patchArr = parent.directories["GRAPHICS"]["PNAMES"][3]
	image.lock()
	for i in texture[6]:
		var xOffset = i[0]
		var yOffset = i[1]
		var patchName = (patchArr[i[2]])
		
		var patchImageData = parent.directories["GRAPHICS"][patchName.to_upper()]
		var patchImageTexture = parent.imageParser.parse(patchImageData[0],patchImageData[1],patchImageData[2],debug,parent.useShaderMaterials).image

		var source = Rect2(Vector2.ZERO,patchImageTexture.get_size())

		image.blend_rect(patchImageTexture,source,Vector2(xOffset,yOffset))

		patchImageTexture.unlock()
		
	image.unlock()
	var wallTexture = ImageTexture.new()
	
	wallTexture.create_from_image(image)
	
	if parent.texture_filtering == false: wallTexture.set_flags(2)
	else: wallTexture.set_flags(7)
	
	if saveToDisk:
		var path = "res://" + parent.graphicsPath + "/" + texture[0]
		if parent.generatePNGs:
			image.save_png(path + ".png")
		ResourceSaver.save(path + ".tres", wallTexture)
		return load(path + ".tres")
	
	return(wallTexture)




func drawSideDef(sectors,startVert,endVert,side,oSide,lineIndex,flags,type,sideIndex,oSideIndex):
	var sector = sectors[side[5]]
	var sectorIndex = side[5]
	#var sideIndex = sides.find(side)
	var sectorLight = sector[4]
	var fFloor=  sector[0]
	var fCeil =  sector[1]
	var offset = Vector2(side[0],side[1])
	var lowerUnpegged = (flags &  LINDEF_FLAG.LOWER_UNPEGGED) != 0
	var upperUnpegged = (flags &  LINDEF_FLAG.UPPER_UNPEGGED) != 0
	var doubleSided = (flags & LINDEF_FLAG.TWO_SIDED) != 0
	var hasCollision =  true
	var sectorNode = mapNode.get_node_or_null(String(side[5]))
	var sideSections = {}
	
	
	if (flags & LINDEF_FLAG.BLOCK_CHARACTERS) == 0 and oSide != null:
		hasCollision = false
	
	
	if sectorNode == null:
		var childNode = Spatial.new()
		childNode.name = String(side[5])
		sectorNode = childNode
		mapNode.add_child(childNode)
	

	var texture = null
	
	
	var temp = null
	if lowerUnpegged:#if you are lower unpegged and not a mid then the texture starts from your ceiling
		temp = fCeil
	
	
	var floorDraw = TEXTUREDRAW.TOPBOTTOM
	var midDraw = TEXTUREDRAW.TOPBOTTOM
	var ceilDraw = TEXTUREDRAW.BOTTOMTOP
	
	if lowerUnpegged: 
		floorDraw = TEXTUREDRAW.GRID
		midDraw = TEXTUREDRAW.BOTTOMTOP
	
	if upperUnpegged:
		ceilDraw = TEXTUREDRAW.GRID
	
	var midTexture = side[4]
	var lowerTexture = side[3]
	var upperTexture = side[2]
	sideSections["textures"] = {"low":lowerTexture,"mid":midTexture,"high":upperTexture}
	var empty = true
	
	
	if midTexture == '-' and lowerTexture == '-'  and upperTexture == '-' and type !=0 :
		texture = load("res://addons/godwad/assets/noTexture.png")
		var wallNode = createWall(startVert,endVert,fFloor,fCeil+0.1,midDraw,offset,hasCollision,texture,fCeil,String(lineIndex)+" mid",type,sectorLight)#0.1 is to prevent pixel leak
		instanceSection(sectorNode,sideSections,wallNode,"mid")
		return sideSections
		
	
	#!double sided ignores all but the middle section
	if !doubleSided or oSide==null:#any line with nothing behind it is treated as !double sided
		texture = fetchTexture(side[4])
		var wallNode = createWall(startVert,endVert,fFloor,fCeil+0.1,midDraw,offset,hasCollision,texture,fCeil,String(lineIndex)+" mid",type,sectorLight)#0.1 is to prevent pixel leak
		instanceSection(sectorNode,sideSections,wallNode,"mid")
		

		if fFloor==fCeil:
			var textures = {"low":lowerTexture,"mid":midTexture,"high":upperTexture}
			emptySides[lineIndex] = {"startVert":startVert*scaleFactor,"endVert":endVert*scaleFactor,"textures":textures,"floorZ":fFloor,"sector":sectorIndex,"light":sectorLight,"doubleSided":doubleSided}
			if oSide != null:
				emptySides[lineIndex]["neighbourSectorIndex"] = oSide
		
		return sideSections
		
	#once we've made it here we can gaurntee we have an opposite side
	var oFloor= sectors[oSide[5]][0] 
	var oCeil = sectors[oSide[5]][1] 
	
	var lowFloor = min(fFloor,oFloor)
	var highFloor = max(fFloor,oFloor)
	var lowCeil = min(fCeil,oCeil)
	var highCeil = max(fCeil,oCeil)
	
	
	#note that refernces to floor and ceil mean the upper and lower sections of the wall not the actual floor and ceilings of a sector
	
	if fFloor < oFloor:#floor section
		texture = getTexture(side[3])	

		if texture!= null:

			var wallNode = createWall(startVert,endVert,lowFloor,highFloor,floorDraw,offset,true,texture,fCeil,String(lineIndex)+" low",type,sectorLight)
			instanceSection(sectorNode,sideSections,wallNode,"low")	
			empty = false
			
	if fCeil > oCeil:#ceil section
		texture = getTexture(side[2])
		if texture!= null:
			
			var wallNode = createWall(startVert,endVert,lowCeil,highCeil,ceilDraw,offset,true,texture,fCeil,String(lineIndex)+" top",type,sectorLight)
			instanceSection(sectorNode,sideSections,wallNode,"high")
			empty = false
	#now we just need to deal with floating mid sections
	if !lowerUnpegged:
		texture = getTexture(side[4])
		if texture!= null:
			var start = max(lowCeil-texture.get_height()+offset.y,highFloor)
			var wallNode = createWall(startVert,endVert,start,lowCeil+offset.y,midDraw,Vector2(offset.x,0),hasCollision,texture,fCeil,String(lineIndex)+" mid",type,sectorLight)
			instanceSection(sectorNode,sideSections,wallNode,"mid")
			empty = false
			
	if lowerUnpegged:
		texture = getTexture(side[4])
		if texture!= null:
		
			var start =  min(highFloor+offset.y,lowCeil)
			var th = texture.get_height()
			var end = min(start+texture.get_height(),lowCeil)
			var wallNode = createWall(startVert,endVert,start,end,midDraw,Vector2(offset.x,0),hasCollision,texture,fCeil,String(lineIndex)+" mid",type,sectorLight)
			instanceSection(sectorNode,sideSections,wallNode,"mid")
			empty = false
	
	if empty and type != 0:
		texture = load("res://addons/godwad/assets/noTexture.png")
		var wallNode = createWall(startVert,endVert,fFloor,fCeil+0.1,midDraw,offset,hasCollision,texture,fCeil,String(lineIndex)+" mid",type,sectorLight)#0.1 is to prevent pixel leak
		instanceSection(sectorNode,sideSections,wallNode,"mid")
		#return sideSections
		
	
	if empty and (midTexture != '-' or lowerTexture != '-'  or upperTexture != '-'):
		
		var textures = {"empty":true,"low":lowerTexture,"mid":midTexture,"high":upperTexture}
		
		var origin = Vector3(startVert.x,fCeil,startVert.y)
		var normal = (startVert-endVert).normalized()
		
		#var TL = Vector3(startVert.x,fCeil,startVert.y) - origin
		##var BL = Vector3(startVert.x,fFloor,startVert.y) -origin
		#var TR = Vector3(endVert.x,fCeil,endVert.y) - origin
		#var BR = Vector3(endVert.x,fFloor,endVert.y) - origin
	
	#	var line1 = TL - TR
	#	var line2 = TL - BL
	#	var normal = -line1.cross(line2).normalized()
		
		emptySides[sideIndex] = {"startVert":startVert*scaleFactor,"endVert":endVert*scaleFactor,"textures":textures,"floorZ":lowFloor,"sector":sectorIndex,"light":sectorLight,"doubleSided":doubleSided,"normal":normal}
		if doubleSided:
			emptySides[sideIndex]["oSideIndex"] = oSideIndex
			emptySides[sideIndex]["neighbourSector"] = (oSide[5])
		
	
	return sideSections


func instanceSection(sector,sideSections,wallNode,sectionName):
	sector.add_child(wallNode["node"])
	sideSections[sectionName] = wallNode["meta"]


func generateMaterialSpatial(tOffset,texture):

	if materialCache.has(texture):
		if materialCache[texture].has(tOffset):
		 return materialCache[texture][tOffset]
		
		
	var mat = SpatialMaterial.new()
	mat.uv1_scale /= scaleFactor
	

	mat.uv1_offset.x = tOffset.x / texture.get_width() 
	mat.uv1_offset.y = tOffset.y / texture.get_height()
	
	mat.flags_unshaded = parent.unshaded
	
	if texture != null:
		mat.albedo_texture = texture
	
		
	if texture.get_data().detect_alpha():
		mat.flags_transparent =true
		mat.params_depth_draw_mode = SpatialMaterial.DEPTH_DRAW_ALPHA_OPAQUE_PREPASS
			
	if !materialCache.has(texture):
		materialCache[texture] = {}
	
	materialCache[texture][tOffset] = mat

	return mat
	
func generateMaterialShader(tOffset,texture,scroll,sectorLight):
	
	#if texture.has_alpha() == false:
	#	breakpoint
	
	if materialCache.has(texture)and scroll.x == 0 and scroll.y ==0:
		if materialCache[texture].has(sectorLight):
			if materialCache[texture][sectorLight].has(tOffset):
				return materialCache[texture][sectorLight][tOffset]
	
	#if materialCache.has(texture) and tOffset.x == 0 and tOffset.y == 0 and scroll.x == 0 and scroll.y == 0:
	#	 return materialCache[texture]
	
	var shader 

	if parent.unshaded:
		if texture.get_data().detect_alpha():
			shader = shaderUnshadedAlpha
		else:
			shader = shaderUnshadedNoAlpha
	else:
		if texture.get_data().detect_alpha():
			shader = shaderShadedAlpha
		else:
			shader = shaderShadedNoAlpha
		
	var mat = ShaderMaterial.new()
	mat.shader = shader
	

	
	mat.set_shader_param("uv_offset", Vector2(tOffset.x / texture.get_width(),tOffset.y / texture.get_height()))
	mat.set_shader_param("uv_scale",Vector3(1.0,1.0,0)/scaleFactor)
	
	
	#mat.set_shader_param("uv_offset.x",tOffset.x / texture.get_width())
	#mat.set_shader_param("uv_offset.y", tOffset.y / texture.get_height())

	mat.set_shader_param("flags_unshaded" ,parent.unshaded)
	mat.set_shader_param("scrolling",scroll)
	
	if texture != null:
		mat.set_shader_param("texture_albedo" , texture)
		var light = max(31-(sectorLight/8),0)
		var colormap = parent.directories["GRAPHICS"]["COLORMAP"][3][light]

		mat.set_shader_param("color_map",colormap)


	if !materialCache.has(texture) and scroll.x == 0 and scroll.y ==0:
		materialCache[texture] = {}
	
	if scroll.x == 0 and scroll.y ==0:
		if !materialCache[texture].has(sectorLight):
			materialCache[texture][sectorLight] = {}

	if scroll.x == 0 and scroll.y ==0:
		materialCache[texture][sectorLight][tOffset] = mat

	return mat
	


func createWall(start,end,floorZ,ceilZ,drawType,offset,hasCollision = false,texture = null,fCeil = null,nameStr = "",type = 0, sectorLight = 15):
	scaleFactor = parent.scaleFactor
	var retNode = null
	start *= scaleFactor
	end *= scaleFactor
	floorZ *= scaleFactor
	ceilZ *= scaleFactor
	
	#ceilZ +=  0.1*scaleFactor #extra bit of height to prevent slight pixel leakage
	var height = ceilZ-floorZ 
	

	var startUVy = 0
	var endUVy= 0
	var endUVx = 0
	#exture = null

	var origin = Vector3(start.x,ceilZ,start.y)
	#var origin = Vector3(max(start.x,end.x),max(floorZ,ceilZ),max(start.y,end.y)) - Vector3(min(start.x,end.x),min(floorZ,ceilZ),min(start.y,end.y))
	var TL = Vector3(start.x,ceilZ,start.y) - origin
	var BL = Vector3(start.x,floorZ,start.y) -origin
	var TR = Vector3(end.x,ceilZ,end.y) - origin
	var BR = Vector3(end.x,floorZ,end.y) - origin
	
	
	var line1 = TL - TR
	var line2 = TL - BL
	var normal = -line1.cross(line2).normalized()

	var surf = SurfaceTool.new()
	var tmpMesh = Mesh.new()
	
	var mat= null
	var scroll = Vector2(0.0,0.0)
	
	
	if type == 48: 
		scroll.x = -1
	if type == 85: 
		scroll.x = 1
		
	if type == 255:
		scroll = offset

	
	if texture != null:
		if !parent.useShaderMaterials:
			mat = generateMaterialSpatial(offset,texture)
			
		if parent.useShaderMaterials:
			mat = generateMaterialShader(offset,texture,scroll,sectorLight)
			
		endUVx = ((start-end).length()/texture.get_width())
		if drawType == TEXTUREDRAW.TOPBOTTOM:
			endUVy = height
			
			startUVy/=texture.get_height()
			endUVy/=texture.get_height()
	
		elif drawType == TEXTUREDRAW.BOTTOMTOP:
			startUVy = floorZ-ceilZ
			endUVy = 0
			
			startUVy/=texture.get_height()
			endUVy/=texture.get_height()
		
		elif drawType == TEXTUREDRAW.GRID:
			fCeil *= parent.scaleFactor
			startUVy = (fCeil - ceilZ)/texture.get_height()
			endUVy = startUVy+(ceilZ-floorZ)/texture.get_height()

		
		
	surf.begin(Mesh.PRIMITIVE_TRIANGLES)
	if texture != null:
		surf.set_material(mat)
		
	surf.add_normal(normal)
	surf.add_uv(Vector2(0,startUVy))
	surf.add_vertex(TL)
	
	surf.add_normal(normal)
	surf.add_uv((Vector2(endUVx,startUVy)))
	surf.add_vertex(TR)
	
	surf.add_normal(normal)
	surf.add_uv(Vector2(endUVx,endUVy))
	surf.add_vertex(BR)
	
	
	surf.add_normal(normal)
	surf.add_uv(Vector2(0,startUVy))
	surf.add_vertex(TL)
	
	surf.add_normal(normal)
	surf.add_uv(Vector2(endUVx,endUVy))
	surf.add_vertex(BR)
	
	surf.add_normal(normal)
	surf.add_uv(Vector2(0,endUVy))
	surf.add_vertex(BL)
	


	surf.commit(tmpMesh)
	
	var meshNode = MeshInstance.new()
	meshNode.mesh = tmpMesh
	meshNode.name = "linedef " + nameStr
	

	if hasCollision:#we create a static body node as a child of the mesh node but then make it the parent of the mesh node
		meshNode.create_trimesh_collision()
		var staticBodyNode = meshNode.get_child(0)
		staticBodyNode.translation = origin
		meshNode.remove_child(staticBodyNode)
		if texture != null:
			staticBodyNode.add_child(meshNode)
		else:
			meshNode.queue_free()
		retNode = staticBodyNode
		
	else:
		
		meshNode.translation = origin
		retNode = meshNode
		

	var width = (start - end).length()
	var metaDict = {"meshNode":meshNode,"normal":normal,"type":type,"dimensions":Vector2(width,height),"startVert":start,"endVert":end,"light":sectorLight,"floorZ":floorZ}
	return {"node": retNode,"meta":metaDict}


func createCollision(TL,TR,BL,BR):
	var shape = ConcavePolygonShape.new()
	var shapeNode = CollisionShape.new()
	
	

func fetchSprite(sprName):
	var flags = 0
	if parent.directories["GRAPHICS"].has(sprName):
		var spriteDataEntry = parent.directories["GRAPHICS"][sprName]
		if !spriteDataEntry[3] :
			spriteDataEntry[3] = parent.imageParser.parse(spriteDataEntry[0],spriteDataEntry[1],spriteDataEntry[2],spriteDataEntry[3],false)
		
		spriteDataEntry[3].flags = 0
		if parent.texture_filtering:
			spriteDataEntry[3].flags += spriteDataEntry[3].FLAGS_DEFAULT
	
		if parent.mipmaps:
			spriteDataEntry[3].flags += spriteDataEntry[3].FLAG_MIPMAPS
	
		if parent.anisotrophic:
			spriteDataEntry[3].flags +=spriteDataEntry[3].FLAG_ANISOTROPIC_FILTER
		
		spriteDataEntry[3].flags +=spriteDataEntry[3].FLAG_CONVERT_TO_LINEAR
		
		return spriteDataEntry[3]


	
func parse(ldir,lname):
	var dat = parent.directories[ldir][lname]
	parent.lumpInstancer.parse(dat[0],lname,dat[3])
	
func parseMap(ldir,lname):
	var dat = parent.directories["MAPS"][ldir][lname]
	
	parent.lumpInstancer.parse(dat[0],lname,dat)
	return(dat[3])

func doesFileExist(path):
	var file = File.new();
	return file.file_exists(path)

