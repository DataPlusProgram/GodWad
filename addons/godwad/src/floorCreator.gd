extends Node
var deubugCount = 0
var vertsl= []
var materialCache = {}
var parent = null

var shaderUnshadedNoAlpha = load("res://addons/godwad/baseUnshadedNoAlpha.shader")
var shaderUnshadedAlpha = load("res://addons/godwad/baseUnshadedAlpha.shader")
var shaderShaded = load("res://addons/godwad/baseShadedNoAlpha.shader")
var shaderShadedAlpha = load("res://addons/godwad/baseUnshadedAlpha.shader")

func instance(mapnode,sectors,lines,sides,verts):
	var sectorToTagDict = {}
	var tagToSectorsDict = {}
	parent.g.timings["floor creation time"] =  OS.get_ticks_msec() 
	vertsl = verts
	var secToLines = crateSectorToLineArray(sectors,lines,sides)
	var guessPoly = null
	var clipped
	for sectorIndex in sectors.size():
		var currentSector = sectors[sectorIndex]
		var sec = secToLines[sectorIndex]
		var tag = currentSector[6]
		if sec == null:
			continue
		if sec.size() < 3:
			print("found sector with less than 3 vertices. skiping")
			continue
		
		var loops = createSectorClosedLoop(sec)
		var secNode = Spatial.new()
		secNode.name = String(sectorIndex)
		secNode.set_meta("floorHeight",currentSector[0])
		secNode.set_meta("ceilingHeight",currentSector[1])
		secNode.add_to_group("sector_tag_" + String(tag))
		if tag!= 0:
			sectorToTagDict[String(sectorIndex)] = String(tag)
			if !tagToSectorsDict.has(tag):
				tagToSectorsDict[tag] = []
				
			tagToSectorsDict[tag].append(String(sectorIndex))
				
		mapnode.add_child(secNode)
		parent.set_meta("sectorToTagDict",sectorToTagDict)
		parent.set_meta("tagToSectorsDict",tagToSectorsDict)
		
		if typeof(loops[0]) == TYPE_STRING:#unclosed sectors don't really work but we do what we can
			guessPoly = guessConvexHull(loops[2])
			loops=loops[1]

		var workingSet = []#getLopAsVerts(loops[0],verts)
		var externals = []
		workingSet = null

		if guessPoly != null:
			#renderLoop(currentSector,secNode,guessPoly,Vector3(0,-0.01,0))
			renderLoop(currentSector,secNode,guessPoly,Vector3(0,-0.01,0))
			guessPoly=null

		if loops == null:#a polygon had failed to be generated
			continue
		for i in loops.size():
			loops[i] = getLoopAsVerts(loops[i],verts)
		
		var tree = createTree(loops)
		for i in tree:
			if i[1] == null:
				workingSet = i[0]
				var children = getNodeChildren(i,tree,currentSector)
				children.sort_custom(self,"shapeXaxisCompare")
				

				for j in children:
					if j.size()<3:
						print("found a sub area with less than 3 vertices")
						continue

					workingSet = createCanal(workingSet,j,String(sectorIndex))
					
					
				workingSet = easeOverlapping(workingSet)
				removeUnnecessaryVerts(workingSet)
				#createDbgPoly(workingSet,sectorIndex)
				renderLoop(currentSector,secNode,workingSet)
				
	#for i in get_children():
	#	if i is Polygon2D:
	#		var packed_scene = PackedScene.new()
	#		packed_scene.pack(i)
		#	ResourceSaver.save("res://debug_output/%s.tscn" % i.name, packed_scene)
				

	parent.g.timings["floor creation time"] =  OS.get_ticks_msec() - parent.g.timings["floor creation time"]

func getNodeChildren(node,treeArr,sector):
	var arr = []
	var index = treeArr.find(node)
	for i in treeArr:
		if i[1] == index:
			arr.append(i[0])
			#renderLoop(sector,i[0],null)
	return arr

func getMaxX(shape):
	var shapeMaxX = Vector2(-INF,0)
	for vert in shape:
		if vert.x > shapeMaxX.x:
			shapeMaxX = vert
			
	if shapeMaxX.x != -INF:
		return shapeMaxX
	else:
		return


func createCanal(shape1,shape2,dbgName = null):

	var shape2MaxX = Vector2(-INF,0)
	var shape2MaxIndex = -1
	var shapae1closestIndex = -1
	var shape1closestVert
	var shape1nextIndex
	var fiddleVector = Vector2(0,-0.001)
	var isVertex = false
	
	shape2MaxX = getMaxX(shape2)
	shape2MaxIndex = shape2.find(shape2MaxX)
	
	var shape1close = getClosetXpoint(shape2MaxX,shape1)
	if shape1close == null:
		print("failed to created canal")
		return shape1
	shape1closestVert = shape1close[0]
	shapae1closestIndex = shape1close[1]
	shape1nextIndex = shape1close[2]
	
	
	if shape1closestVert == shape1[shapae1closestIndex] or shape1closestVert == shape1[shape1nextIndex]:
		isVertex = true
	
	var s1Sfter 


	var s1Before = shape1.slice(0,shapae1closestIndex)
	if shapae1closestIndex != shape1.size()-1:
		s1Sfter = shape1.slice(shapae1closestIndex+1,shape1.size())
	else:
		s1Sfter = []
		
	
	var half1 = []
	var half2 = []
	#var s2newOrder = []
	
	if shape2MaxIndex != 0:
		half1 = shape2.slice(0,shape2MaxIndex-1)#everything up untill the split point
	else:
		half1 = []#giving slice a negative number will just loop it back over to the end of the array
	half2 = shape2.slice(shape2MaxIndex,shape2.size()-1)#everyting after the split point(including the split point itself)
	

	var increasingY = 1
	if (shape1[shapae1closestIndex].y -shape1[shape1nextIndex].y) > 0:
		increasingY =-1


	var newS2EndPoint = scaleLine([ (half2 + half1).back(),shape2MaxX],1)
	
	var newS1EndPoint = scaleLine([shape2MaxX+ fiddleVector,shape1closestVert],1.001) - Vector2(0,0.01)
	if increasingY == 1:
		 newS1EndPoint = scaleLine([shape2MaxX+ fiddleVector,shape1closestVert],1.001) + Vector2(0,0.01)
	if isVertex:#if we are a vertice we need to look one point foward than we usually do
		
		var nextPointAfterEnd = (shape1nextIndex+1)%shape1.size()
		
		var line = [shape1closestVert,shape1[nextPointAfterEnd]]
		newS1EndPoint = scaleLine(line,0.001)
	
	

	var s2combine = half2 + half1 + [newS2EndPoint]

	var s2lastLine = [s2combine[s2combine.size()-1],shape2MaxX]
	#var transitionLine = [s2newOrder.back(), shape1closestVert]
	var combinedPoly
	
	combinedPoly = s1Before + [shape1closestVert] + s2combine + [newS1EndPoint]  + s1Sfter 
	
	
	removeDuplicateVerts(combinedPoly)
	removeUnnecessaryVerts(combinedPoly)
#	createDbgPoly(combinedPoly,dbgName)
	

	return combinedPoly



func getLoopAsVerts(loop,verts):
	var vertArray = []
	for i in loop:
		
		if i[1] > verts.size():
			print("vert out of index")
			continue
		
		var vert = verts[i[1]]
		vertArray.append(vert)
	return vertArray


func renderLoop(currentSector,sectorNode,verts,offset = Vector3(0,0,0)):
	

	var vertArray= triangulate(verts)
	if vertArray == []:
		vertArray = Geometry.convex_hull_2d(verts)
		vertArray = triangulate(vertArray)
	
	if vertArray == []:
		return
	
	var floorHeight = currentSector[0]
	var ceilHeight = currentSector[1]
	var floorTexture =null
	if parent.runtimeOnly:floorTexture =  parent.levelInstancer.fetchFlat(currentSector[2])
	if !parent.runtimeOnly:floorTexture =   parent.levelInstancer.fetchFlatDisk(currentSector[2])
	
	var ceilTexture 
	if parent.runtimeOnly:ceilTexture =  parent.levelInstancer.fetchFlat(currentSector[3])
	if !parent.runtimeOnly:ceilTexture = parent.levelInstancer.fetchFlatDisk(currentSector[3])
	#if currentSector[2] == "F_SKY1":
	#	floorTexture = null
		
#		if currentSector[2] == "F_SKY1":
	#	floorTexture = null


	var dim = Vector3(-INF,0,-INF)
	var mini = Vector3(INF,0,INF)
	var finalArr =[]#= [vertArray]
	var origin = offset#Vector3(vertArray[0].x,0,vertArray[0].y) + offset
	#$"../draw".add_poly(vertArray)

	for i in vertArray.size()/3:
		var t1 = Vector3(vertArray[i*3].x,0,vertArray[i*3].y)  - origin
		var t2 = Vector3(vertArray[i*3+1].x,0,vertArray[i*3+1].y) - origin
		var t3 = Vector3(vertArray[i*3+2].x,0,vertArray[i*3+2].y) - origin
		
		if t1.x > dim.x: dim.x = t1.x
		if t2.x > dim.x: dim.x = t2.x
		if t2.x > dim.x: dim.x = t3.x
		if t1.z > dim.z: dim.z = t1.z
		if t2.z > dim.z: dim.z = t2.z
		if t2.z > dim.z: dim.z = t3.z
		
		if t1.x < mini.x: mini.x = t1.x
		if t2.x < mini.x: mini.x = t2.x
		if t2.x < mini.x: mini.x = t3.x
		if t1.z < mini.z: mini.z = t1.z
		if t2.z < mini.z: mini.z = t2.z
		if t2.z < mini.z: mini.z = t3.z
		
		
		finalArr.append(t1)
		finalArr.append(t2)
		finalArr.append(t3)
	
	var light = currentSector[4]
	
	if floorTexture!= null:
		var floorMesh = createFloorMesh(finalArr,floorHeight,1,dim,mini,currentSector[2],floorTexture,light)
		floorMesh.create_trimesh_collision()
		floorMesh.name = currentSector[2]
		floorMesh.translation = (origin + Vector3(0,floorHeight,0))*parent.scaleFactor 
		floorMesh.get_node("_col").set_meta("floor","true")
		floorMesh.set_meta("floor","true")
		floorMesh.add_to_group(sectorNode.name)
		sectorNode.add_child(floorMesh)
		floorMesh.get_child(0).set_collision_layer_bit(1,1)
	
	
	if ceilTexture!=null:
		var ceilMesh = createFloorMesh(finalArr,ceilHeight,-1,dim,mini,currentSector[3],ceilTexture,light)
		ceilMesh.create_trimesh_collision()
		ceilMesh.get_node("_col").set_meta("ceil","true")
		ceilMesh.set_meta("ceil","true")
		ceilMesh.name = currentSector[3]
		#ceilMesh.translation = origin * parent.scaleFactor 
		ceilMesh.translation = (origin + Vector3(0,ceilHeight,0))*parent.scaleFactor 
		sectorNode.add_child(ceilMesh)
		
	
	#$"../AreaCreator".create(verts,ceilHeight,floorHeight)
	
	pass
	
	
	
func createFloorMesh(arr,height,dir,dim,mini,textureName,texture = null,sectorLight = 0):
	var surf = SurfaceTool.new()
	var tmpMesh = Mesh.new()
	var scaleFactor = parent.scaleFactor 
	
	var mat = null
	var textureKey = textureName
	
	if !parent.useShaderMaterials:
		mat = parent.levelInstancer.generateMaterialSpatial(Vector2.ZERO,texture)
	else:
		mat = parent.levelInstancer.generateMaterialShader(Vector2.ZERO,texture,Vector2.ZERO,sectorLight)

	surf.begin(Mesh.PRIMITIVE_TRIANGLES)
	surf.set_material(mat)
 

	if dir == -1:
		arr.invert()
	var count = 0
	for v in arr:
		
		surf.add_normal(Vector3(0,dir,0))
		if texture.get_width() != 0 and texture.get_height()!=0:

			var uvX = (v.x*scaleFactor)/texture.get_width()
			var uvY = (v.z*scaleFactor)/texture.get_height()
			
			surf.add_uv(Vector2(uvX,uvY))
		surf.add_vertex(v*scaleFactor)

	
	surf.commit(tmpMesh)
	var meshNode = MeshInstance.new()
	meshNode.mesh = tmpMesh
	
	
	
	return meshNode

	
func triangulate(arr):
	var triangualted = Geometry.triangulate_polygon(arr)
	#var triangualted = Geometry.triangulate_delaunay_2d(arr)
	var vertArrTri = []
	for i in triangualted:
		vertArrTri.append(arr[i])

	return vertArrTri



func createSectorClosedLoop(sec):
	var soup = sec.duplicate(true)
	var loops = []
	var curloop = []
	var badVerts = []
	var first = [INF,INF]
	for line in sec:
		if line[0] < first[0]:
			first = line
			

	commitToLoop(first,curloop,soup)
	var i = -1
	var fetch = true
	while(true):
	
		if curloop.back()[1] == curloop.front()[0]:# and loop.size() > 1:#we closed a loop
			loops.append(curloop)
			curloop = []
			i = -1
			fetch = commitToLoop(soup[i],curloop,soup)
					
		
		elif curloop.back()[1] == soup[i][0] :#connection found
			fetch = commitToLoop(soup[i],curloop,soup)
			i=-1
			

		elif i+1==soup.size():#we have reached the end without closing the loop
			badVerts = badVerts + curloop
			curloop = []
			fetch = commitToLoop(soup[0],curloop,soup)

			i = -1
			#commitToLoop(soup[0],curloop,soup)
		
		if fetch == false:#we ran out of lines to process
			if curloop.back()[1] == curloop.front()[0]:
				loops.append(curloop)
				curloop = []
			
			if !curloop.empty():
				badVerts = badVerts + curloop
			
			if badVerts.size()>0:
				return(["fail",loops,badVerts])
				
			if badVerts.size()==0:
				if loops.empty():
					breakpoint
				return(loops)
		
		i+=1
		
func createSectorClosedLoop2(sec):
	var soup = sec.duplicate(true)
	var loops = []
	var curloop = []
	var badVerts = []
	var first = [INF,INF]
	var fetch = true
	for line in sec:
		if line[0] < first[0]:#get the smallest vertex indice
			first = line
			

	commitToLoop(first,curloop,soup)
	var i = 0
	while(true):
		var check = soup[i]
		if curloop.back()[1] == check[0]:
			fetch = commitToLoop(soup[i],curloop,soup)
			i=0
		
		if curloop.front()[0] == soup.back()[1] and curloop.size() > 2:
			loops.append(curloop)
			curloop = []
			i = 0
			fetch = commitToLoop(soup[i],curloop,soup)
		
		if i+1 == soup.size():
			badVerts = badVerts + curloop
			curloop = []
			fetch = commitToLoop(soup[0],curloop,soup)
			i=0
		
		if fetch == false:#soup.size() == 0
			if badVerts.size()>0:
				return(["fail",loops,badVerts])
				
			else:
				if loops.empty():
					breakpoint
				return(loops)
			
		
		i+=1
	

	
func commitToLoop(value,curLoop,soup):
	curLoop.append(value)
	soup.erase(value)
	if soup.size()>0:
		return true
	else:
		return false


func crateSectorToLineArray(sectors,lines,sides):
	var linNum = 0
	var sectorLines = []
	sectorLines.resize(sectors.size())
	for line in lines:
		#print(linNum)
		var frontSideIndex = line[5]
		var backSideIndex = line[6]
		
		if frontSideIndex != 65535 : 
			if frontSideIndex > sides.size():
				print("index ",frontSideIndex ," out of range")
				continue
			var frontSide = sides[frontSideIndex]
			var sectorId = frontSide[5]
		
			if typeof(sectorLines[sectorId]) != TYPE_ARRAY: sectorLines[sectorId] = []
			sectorLines[frontSide[5]].append(line.slice(0,1))

	
		if backSideIndex != 65535 : 
			
			if backSideIndex > sides.size():
				print("index ",backSideIndex ," out of range")
				continue
			
			var backSide = sides[backSideIndex]
			var sectorId = backSide[5]
			if typeof(sectorLines[sectorId]) != TYPE_ARRAY: sectorLines[sectorId] = []
			var sliced = line.slice(0,1)
			sectorLines[backSide[5]].append([sliced[1],sliced[0]])
			
		linNum += 1
	return sectorLines

func createTree(loops):
	var arr = loops.duplicate(true)
	
	var tree = []
	for i in arr:
		tree.append([i,null,[]])

	for i in tree.size()-1:
		for j in range(i+1,arr.size()):
			var p1 = tree[i][0]
			var p2 = tree[j][0]
			var isP1withinP2 = (Geometry.clip_polygons_2d(p1,p2)) == []
			var isP2withinP1 = (Geometry.clip_polygons_2d(p2,p1)) == []
			
			if isP1withinP2:
				tree[i][1] = j
			
			if isP2withinP1:
				tree[j][1] = i
	
	return tree 

func getClosetXpoint(point,poly):
	var maxX = getMaxX(poly)
	var closestDist = INF
	var ret = null
	for i in poly.size():
		var line1 = [poly[i],poly[(i+1)%poly.size()]] 
		var line2 = [point,Vector2(maxX.x+10,point.y)]
		var closestPoint = Geometry.segment_intersects_segment_2d(line1[0],line1[1],line2[0],line2[1])
		if closestPoint != null:
			if point.distance_squared_to(closestPoint) < closestDist:
				closestDist =  point.distance_squared_to(closestPoint)
				
				ret = [closestPoint,i,(i+1)%poly.size()]
				
	if ret != null:
		return [Vector2(round(ret[0].x),round(ret[0].y)),ret[1],ret[2]]
	return ret

func scaleLine(line,factor):
	var slope = line[1] - line[0]
	return line[0] + (slope*factor)


func shapeXaxisCompare(a,b):
	if getMaxX(a) > getMaxX(b):
		return true
	else:
		return false

func guessConvexHull(arr):
	var tmp = []
	
	for i in arr:
		if i[0]> vertsl.size():
			print("vert index ", i ,  "out of range")
			continue
			
		if tmp.find(vertsl[i[0]]) == -1:
			tmp.append(vertsl[i[0]])
		
		if i[1]> vertsl.size():
			print("vert index ", i ,  "out of range")
			continue	
		
		if tmp.find(vertsl[i[1]])  == -1:
			tmp.append(vertsl[i[1]]) 
		
	var hull = Geometry.convex_hull_2d(tmp)
	

	return hull
	
func removeDuplicateVerts(arr):
	var end = arr.size()
	var i = 0
	while(i<end):
		if arr.size()<4:
			return
		var a = stepifyVector(arr[i],0.1)
		var b = stepifyVector(arr[(i+1)%arr.size()],0.1)

		if a == b:
			arr.remove((i+1)%arr.size())
			i-=1
			end = arr.size()
		i+=1

func removeUnnecessaryVerts(arr):
	
	var end = arr.size()
	var i = 0
	while(i<end):
		if arr.size()<4:
			return
		var a = stepifyVector(arr[i],0.1)
		var b = stepifyVector(arr[(i+1)%arr.size()],0.1)
		var c = stepifyVector(arr[(i+2)%arr.size()],0.1)
		var slopeA 
		var slopeB
		var aDeltaX = (b.x-a.x)
		var bDeltaY = (c.x-b.x)
		
		if aDeltaX == 0: 
			slopeA = INF
		else:
			slopeA = (b.y-a.y)/(b.x-a.x)
		
		if bDeltaY == 0: 
			slopeB = INF
		else:
			slopeB = (c.y-b.y)/(c.x-b.x)
		
		if slopeA == slopeB:
			#print(slopeA,slopeB)
			arr.remove((i+1)%arr.size())
			i-=1
			end = arr.size()

		i+=1

func stepifyVector(v,step):
	v = Vector2(stepify(v.x,step),stepify(v.y,step))
	return v
	
func stepifyVector3(v,step):
	v = Vector3(stepify(v.x,step),stepify(v.y,step),stepify(v.z,step))
	return v

func createDbgPoly(arr,dbgName):
	var debugImage = Polygon2D.new()
	debugImage.polygon = arr
	debugImage.scale *= 0.1

	if dbgName!= null:
		debugImage.name = "Sector %s " % dbgName

	#debugImage.set_owner(self)
	#add_child(debugImage)
	
func easeOverlapping(arr):
	var size = arr.size()
	
	for i in arr:
		if arr.count(i) >1:
			var a = arr.find(i)
			var b = arr.find_last(i)
			
			var aLine = [(a-1)%size,a,(a+1)%size]
			var bLine = [(b-1)%size,b,(b+1)%size]
			if a == 0: aLine[0] += size
			if b == 0: bLine[0] += size
			
			var aBefore = min(aLine[0],aLine[2])
			var aAfter = max(aLine[0],aLine[2])
			var bBefore = min(bLine[0],bLine[2])
			var bAfter = max(bLine[0],bLine[2])
			
			
			var aLineV = [arr[aBefore],arr[aLine[1]],arr[aAfter]]
			var bLineV = [arr[bBefore],arr[bLine[1]],arr[bAfter]]
			#var bLineV = [arr[bLine[0]],arr[bLine[1]],arr[bLine[2]]]
			
			#print(arr[aLine[1]])
			arr[aLine[1]] = scaleLine([aLineV[0],aLineV[1]],0.9999)
			arr[bLine[1]] = scaleLine([bLineV[0],bLineV[1]],0.9999)
			#print(arr[aLine[1]])

	return arr

