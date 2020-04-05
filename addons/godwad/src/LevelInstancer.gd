tool
extends Node


var textureCache = {}
var materialCache = {}
var mapNode = null
var parent = null
var scaleFactor

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

enum LINDEF_TYPE{
	DR_DOOR = 1,
	W1_DOOR_STAY_OPEN,
	W1_DOOR_CLOSE,
	W1_DOOR
	
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

func instance(par,mapname,map):
	scaleFactor = parent.scaleFactor
	mapNode = Spatial.new()
	mapNode.name = mapname
	parent.add_child(mapNode)
	mapNode.owner = parent
	parent.g.timings["map creation time"] = OS.get_ticks_msec()
	

	var lines = parseMap(mapname,"LINEDEFS")
	var verts =  parseMap(mapname,"VERTEXES")
	var sides =parseMap(mapname,"SIDEDEFS")
	var sectors = parseMap(mapname,"SECTORS") 
	#var segs = parseMap(mapname,"SEGS")
	#var subsectors = parseMap(mapname,"SSECTORS")
	#var nodes = parseMap(mapname,"NODES")
	
	parseMap(mapname,"THINGS")
	parseThings(map)

	

	parent.floorCreator.instance(mapNode,sectors,lines,sides,verts)
	
	for line in lines:
		var lindefIndex = lines.find(line)
		var startVert = verts[line[0]]
		var endVert = verts[line[1]]
		var flags = line[2]
		var type = line[3]
		var frontSideIndex = line[5]
		var backSideIndex = line[6]
		var frontSide = null
		var backSide = null

		if frontSideIndex != 65535 : frontSide = sides[frontSideIndex]	
		if backSideIndex != 65535 : backSide = sides[backSideIndex]
		
		var lowerUnpegged = (flags &  LINDEF_FLAG.LOWER_UNPEGGED) != 0
		if frontSide:
			var meshNode = drawSideDef(sectors,startVert,endVert,frontSide,backSide,lindefIndex,flags)
			#createInteractionHitbox(meshNode,lindefIndex,type)
			
		if backSide:
			var meshNode = drawSideDef(sectors,endVert,startVert,backSide,frontSide,lindefIndex,flags)

	
	
	parent.g.timings["map creation time"] =  OS.get_ticks_msec() - parent.g.timings["map creation time"]




func createInteractionHitbox(meshNode,lindefIndex,type):
	var area = Area.new()
	area.name = "lindef %s interactbox" % lindefIndex
	
	if meshNode == null:
		return
	
	if type == 0:
		return
	
	for i in meshNode.keys():
		var colisionShape = meshNode[i]["meshNode"].get_child(0).get_child(0).duplicate()
		var boxCollisionShapeNode = CollisionShape.new()
		var boxShape = BoxShape.new()
		var dimen = meshNode[i]["dimensions"]
	
		boxShape.extents.x = 10*parent.scaleFactor
		boxShape.extents.y = dimen.y/2
		boxShape.extents.z = dimen.x/2

		var line = meshNode[i]["startVert"]-meshNode[i]["endVert"]
		var angle = (line.angle_to(Vector2.UP))
		
		boxCollisionShapeNode.translation.x=  meshNode[i]["startVert"].x - (line/2).x 
		boxCollisionShapeNode.translation.z=  meshNode[i]["startVert"].y - (line/2).y
		boxCollisionShapeNode.translation.y = meshNode[i]["floorZ"] + dimen.y/2
		
		boxCollisionShapeNode.rotation =Vector3(0,angle,0)
		var doorScript = parent.scriptLoader.create(type)#load("res://doorInteraction.gd")

		
		
		boxCollisionShapeNode.shape = boxShape#
		area.add_child(boxCollisionShapeNode)
		area.set_script(doorScript)
		meshNode[i]["meshNode"].add_child(area)
		colisionShape.translation -= 500*parent.scaleFactor*meshNode[i]["normal"]
		
	#area.add_child(mesh.get_child(0).duplicate())
	#area.add_child(mesh.get_child(0).duplicate())




func getTexture(name):
	if parent.runtimeOnly:  return fetchTexture(name)
	if !parent.runtimeOnly: return fetchTextureDisk(name)

func fetchTexture(name,debug = false):
	if name in textureCache:
		return textureCache[name]
	var directories = parent.directories
	
	var tex1 = directories["GRAPHICS"]["TEXTURE1"]
	if tex1[3].empty():
		parent.lumpInstancer.parse(tex1[0],"TEXTURE",tex1)

	
	
	var texture1 = directories["GRAPHICS"]["TEXTURE1"][3]
	for i in texture1:
		if i[0] == name:
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
			textureCache[name] = loadTexture(i,false)
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
		textureObj= parent.imageParser.parseFlat(textureFileEntry[0],textureFileEntry[1],textureFileEntry[1],textureFileEntry[1])
		textureCache[name] = textureObj
	
	if parent.texture_filtering == false: textureObj.set_flags(2)
	else: textureObj.set_flags(7)
	
	
	
	return textureObj
	
func fetchFlatDisk(name):
	
	var path = ("res://" + parent.graphicsPath + "/" + name + ".tres")
	if doesFileExist(path):
		return load(parent.graphicsPath + "/" + name + ".tres")
	
	var textureFileEntry = parent.directories["GRAPHICS"][name]
	var textureObj = null
		
	
	textureObj= parent.imageParser.parseFlat(textureFileEntry[0],textureFileEntry[1],textureFileEntry[1],textureFileEntry[1])
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
		var patchImageTexture = parent.imageParser.parse(patchImageData[0],patchImageData[1],patchImageData[2],debug).image

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




func drawSideDef(sectors,startVert,endVert,side,oSide,sideIndex,flags,backSide = false):
	var sector = sectors[side[5]]
	var fFloor=  sector[0]
	var fCeil =  sector[1]
	var offset = Vector2(side[0],side[1])
	var lowerUnpegged = (flags &  LINDEF_FLAG.LOWER_UNPEGGED) != 0
	var upperUnpegged = (flags &  LINDEF_FLAG.UPPER_UNPEGGED) != 0
	var doubleSided = (flags & LINDEF_FLAG.TWO_SIDED) != 0
	var hasCollision =  (flags & LINDEF_FLAG.BLOCK_CHARACTERS) != 0
	var sectorNode = mapNode.get_node_or_null(String(side[5]))
	var mesh = {}
	
	if sectorNode == null:
		var childNode = Spatial.new()
		childNode.name = String(side[5])
		sectorNode = childNode
		mapNode.add_child(childNode)
	

	var texture = null
	
	if backSide:
		var temp = startVert
		startVert = endVert
		endVert = temp
	
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
	
	
	#!double sided ignores all but the middle section
	if !doubleSided or oSide==null:#wany line with nothing behind it is treated as !double sided
		if parent.runtimeOnly:  texture = fetchTexture(side[4])
		if !parent.runtimeOnly: texture = fetchTextureDisk(side[4])
		mesh["mid"] = createWall(startVert,endVert,fFloor,fCeil,midDraw,offset,sectorNode,sideIndex,hasCollision,texture,fCeil)
		
		return
		
	#once we've made it here we can gaurntee we have an opposite side
	var oFloor= sectors[oSide[5]][0] 
	var oCeil = sectors[oSide[5]][1] 
	
	var lowFloor = min(fFloor,oFloor)
	var highFloor = max(fFloor,oFloor)
	var lowCeil = min(fCeil,oCeil)
	var highCeil = max(fCeil,oCeil)
	
	
	#note that refernces to floor and ceil mean the upper and lower sections of the wall not the actual floor and ceilings of a sector
	
	if lowFloor != highFloor:#floor section
		texture = getTexture(side[3])
	
		if texture!= null:
			mesh["floor"] = createWall(startVert,endVert,lowFloor,highFloor,floorDraw,offset,sectorNode,sideIndex,true,texture,fCeil)
	
	if fCeil > oCeil:#ceil section
		texture = getTexture(side[2])
		if texture!= null:
			mesh["ceil"] = createWall(startVert,endVert,lowCeil,highCeil,ceilDraw,offset,sectorNode,sideIndex,true,texture,fCeil)
	
	#now we just need to deal with floating mid sections
	if !lowerUnpegged:
		texture = getTexture(side[4])
		if texture!= null:
			var start = max(lowCeil-texture.get_height()+offset.y,highFloor)
			mesh["mid"] = createWall(startVert,endVert,start,lowCeil+offset.y,midDraw,Vector2.ZERO,sectorNode,sideIndex,hasCollision,texture,fCeil)
	
	if lowerUnpegged:
		texture = getTexture(side[4])
		if texture!= null:
			var end = min(highFloor+texture.get_height(),lowCeil)
			mesh["mid"] = createWall(startVert,endVert,highFloor,end,midDraw,Vector2.ZERO,sectorNode,sideIndex,hasCollision,texture,fCeil)
			
	
	return mesh




func generateMaterial(tOffset,texture):

		
	if materialCache.has(texture) and tOffset.x == 0 and tOffset.y == 0:
		 return materialCache[texture]
		
	var mat = SpatialMaterial.new()
	mat.uv1_scale /= scaleFactor
	
	mat.uv1_offset.x = tOffset.x / texture.get_width()
	mat.uv1_offset.y = tOffset.y / texture.get_height()
	
	mat.flags_unshaded = parent.unshaded
	#mat.params_cull_mode = 0
	if texture != null:
		mat.albedo_texture = texture
	
		
	if texture.get_data().detect_alpha():
		mat.flags_transparent =true
		mat.params_depth_draw_mode = SpatialMaterial.DEPTH_DRAW_ALPHA_OPAQUE_PREPASS
			
	if tOffset.x == 0 and tOffset.y == 0:
		materialCache[texture] = mat

	return mat


func createWall(start,end,floorZ,ceilZ,type,offset,sectorNode= -1,sideIndex=-1,hasCollision = false,texture = null,fCeil = null):

	if texture == null:
		breakpoint

	start *= scaleFactor
	end *= scaleFactor
	floorZ *= scaleFactor
	ceilZ *= scaleFactor
	
	var height = ceilZ-floorZ
	

	var startUVy = 0
	var endUVy= 0
	var endUVx = 0
	#exture = null

	
	var TL = Vector3(start.x,ceilZ,start.y)
	var BL = Vector3(start.x,floorZ,start.y)
	var TR = Vector3(end.x,ceilZ,end.y)
	var BR = Vector3(end.x,floorZ,end.y)
	var line1 = TL - TR
	var line2 = TL - BL
	var normal = line1.cross(line2).normalized()

	var surf = SurfaceTool.new()
	var tmpMesh = Mesh.new()
	
	var mat= null
	
	if texture != null:
		mat = generateMaterial(offset,texture)
		endUVx = ((start-end).length()/texture.get_width())
		if type == TEXTUREDRAW.TOPBOTTOM:
			endUVy = height
			
			startUVy/=texture.get_height()
			endUVy/=texture.get_height()
	
		elif type == TEXTUREDRAW.BOTTOMTOP:
			startUVy = floorZ-ceilZ
			endUVy = 0
			
			startUVy/=texture.get_height()
			endUVy/=texture.get_height()
		
		elif type == TEXTUREDRAW.GRID:
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
	meshNode.name = "linedef " + String(sideIndex)
	
	#if texture == null:
	#	meshNode.visible = false
	
	if hasCollision:
		meshNode.create_trimesh_collision()
	
	sectorNode.add_child(meshNode)

	var width = (start - end).length()
	return {"meshNode":meshNode,"sectorNode":sectorNode,"normal":normal,"dimensions":Vector2(width,height),"startVert":start,"endVert":end,"floorZ":floorZ}


func createCollision(TL,TR,BL,BR):
	var shape = ConcavePolygonShape.new()
	var shapeNode = CollisionShape.new()
	
	

func parseThings(map):
	var test = map["THINGS"]
	var file = map["THINGS"][0]
	var offset = map["THINGS"][1]
	var size = map["THINGS"][2]
	file.seek(offset)
	
	
	while(file.get_position()-offset < size):
		var position = Vector3(file.get_16u(),0,-file.get_16u())
		var rotation = file.get_16()
		var doomEdType = file.get_16()
		var flags = file.get_16()
	
		var rot = 0
		if rotation == 0: rot = 0
		if rotation == 1: rot = 45
		if rotation == 2: rot = 90
		if rotation == 3: rot = 135
		if rotation == 4: rot = 180
		if rotation == 5: rot = 225
		if rotation == 6: rot = 270
		if rotation == 7: rot = 315
		
		#if doomEdType == 1:
		#	$"../../Player".translation = position*scaleFactor
		#	$"../../Player".rotation_degrees.y = rotation-90



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
