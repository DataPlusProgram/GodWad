tool
extends Node
#onready var file = global.file

func parse(_file,lumpName,lumpData):
	if lumpData.empty():
		return
	
	if lumpName == "LINEDEFS":
		lumpData[3] = readLineDef(_file,lumpData[1],lumpData[2])
		
	if lumpName == "SIDEDEFS":
		lumpData[3] = readSideDef(_file,lumpData[1],lumpData[2])
	
	if lumpName == "VERTEXES":
		lumpData[3] = readVertices(_file,lumpData[1],lumpData[2])
	
	if lumpName == "SECTORS":
		lumpData[3] = readSector(_file,lumpData[1],lumpData[2])
	
	if lumpName == "SEGS":
		lumpData[3] = readSegs(_file,lumpData[1],lumpData[2])
	
	if lumpName == "SSECTORS":
		lumpData[3] = readSubSectors(_file,lumpData[1],lumpData[2])
	
	if lumpName == "PLAYPAL":
		lumpData[3] = readPLAYPAL(_file,lumpData[1],lumpData[2])
	
	if lumpName.substr(0,7) == "TEXTURE":
		lumpData[3] = readTexture(_file,lumpData[1],lumpData[2])
	
	if lumpName == "PNAMES":
		lumpData[3] =readPname(_file,lumpData[1],lumpData[2])
	
	if lumpName == "NODES":
		lumpData[3] =readNode(_file,lumpData[1],lumpData[2])
		
	if lumpName == "BLOCKMAP":
		pass
		#lumpData[3] = readBlockmap(_file,lumpData[1],lumpData[2])
		

func readLineDef(_file,offset,size):
	_file.seek(offset)
	var ret = []
	#var bif
	while(_file.get_position()-offset < size):
		var startVert = _file.get_16()
		var endVert = _file.get_16()
		var flags = _file.get_16()
		var specialType = _file.get_16()
		var sectorTag = _file.get_16()
		var frontSidedef = _file.get_16()
		var backSidedef = _file.get_16()
		ret.append([startVert,endVert,flags,specialType,sectorTag,frontSidedef,backSidedef])
		
	return ret
	
func readSideDef(_file,offset,size):
	_file.seek(offset)
	var ret = []
	while(_file.get_position()-offset < size):
		var xOffset = _file.get_16u()
		var yOffset = _file.get_16u()
		var upperName = _file.get_String(8)
		var lowerName = _file.get_String(8)
		var middleName = _file.get_String(8)
		var facingSector = _file.get_16()
		ret.append([xOffset,yOffset,upperName,lowerName,middleName,facingSector,[],[]])
	

	return ret

func readSector(_file,offset,size):
	_file.seek(offset)
	var ret = []
	while(_file.get_position()-offset < size):
		var floorHeight = _file.get_16u()

		var ceilingHeight = _file.get_16u()
		var floorTexture = _file.get_String(8)
		var ceilingTexture = _file.get_String(8)
		var lightLevel = _file.get_16()
		var type = _file.get_16()
		var tagNum = _file.get_16()
		ret.append([floorHeight,ceilingHeight,floorTexture,ceilingTexture,lightLevel,type,tagNum,[]])
	return ret

func readSubSectors(_file,offset,size):
	_file.seek(offset)
	var ret = []
	while(_file.get_position()-offset < size):
		var segCount = _file.get_16()
		var firstSegNumber = _file.get_16()
		var temp = []
		for i in segCount:
			temp.append(firstSegNumber+i)
		ret.append(temp)

	return(ret)

func readVertices(_file,offset,size):
	_file.seek(offset)
	var ret = []
	while(_file.get_position()-offset < size):
		var posX = _file.get_16u()
		var posY = -_file.get_16u()
		ret.append(Vector2(posX,posY))
		
	return(ret)

func readSegs(_file,offset,size):
	_file.seek(offset)
	var ret = []
	while(_file.get_position()-offset < size):
		var startVertex = _file.get_16()
		var endVertex = _file.get_16()
		var angle = _file.get_16()
		var lineDef = _file.get_16()
		var direction = _file.get_16()
		var offsetDistance = _file.get_16()
		ret.append([startVertex,endVertex,angle,lineDef,direction,offset])

	return ret

func readPLAYPAL(_file,offset,size):
	_file.seek(offset)
	var ret = []
	for i in range(0,size/768):
		var pallete = []
		for i in 256:
			pallete.append(Color8(_file.get_8(),_file.get_8(),_file.get_8()))
		ret.append(pallete)
	return ret



func readTexture(_file,offset,size):
	_file.seek(offset)
	var ret = []
	var textureOffsets = []
	var textureEtries = []
	var numTextures = _file.get_32()
	for i in numTextures:
		textureOffsets.append(_file.get_32())
	
	for i in textureOffsets:
		_file.seek(offset+i)
		
		var texName = _file.get_String(8)
		var masked = _file.get_32()
		var width = _file.get_16()
		var height = _file.get_16()
		var obsoleteData = _file.get_32()
		var patchCount = _file.get_16()
		var patches = []
		
		for i in patchCount:
			var originX = _file.get_16u()
			var originY = _file.get_16u()
			var pnameIndex = _file.get_16()
			var stepDir = _file.get_16()
			var colorMap = _file.get_16()
			patches.append([originX,originY,pnameIndex,stepDir,colorMap])
				
		textureEtries.append([texName,masked,width,height,obsoleteData,patchCount,patches])
	return textureEtries

func readPname(_file,offset,size):
	_file.seek(offset)
	var ret = []
	var numberOfPname = _file.get_32()

	for i in numberOfPname:
		var name = _file.get_String(8)
		ret.append(name)

	
	return ret

func readNode(_file,offset,size):
	_file.seek(offset)
	var ret = []
	while(_file.get_position()-offset < size):
		var x = _file.get_16u()
		var y = -_file.get_16u()
		var startPos = Vector2(x,y)
		var dX = _file.get_16u()
		var dY = -_file.get_16u()
		var delta = Vector2(dX,dY)
		
		var BB1maxY = _file.get_16u()
		var BB1minY = -_file.get_16u()
		var BB1maxX = _file.get_16u()
		var BB1minX = _file.get_16u()
		var BB1 = Rect2(Vector2(BB1minX,BB1maxX),Vector2(BB1maxX,BB1maxY))
		var BB2maxY = _file.get_16u()
		var BB2minY = -_file.get_16u()
		var BB2maxX = _file.get_16u()
		var BB2minX = _file.get_16u()
		var BB2 = Rect2(Vector2(BB2minX,BB2maxX),Vector2(BB2maxX,BB2maxY))
		var rChild = _file.get_16()
		#rChild & 0b1000000000000000
		var lChild = _file.get_16()
		ret.append([startPos,delta,BB1,BB2,rChild,lChild])
		
	return ret
	
func readBlockmap(_file,offset,size):
	_file.seek(offset)
	var ret = []
	#while(_file.get_position()-offset < size):
	var gridmapX = _file.get_16u()
	var gridmapY = _file.get_16u()
	var nCols = _file.get_16()
	var nRows = _file.get_16()
	var blockOffsets = []
	var numberOfBlocks = nRows * nCols
	for i in numberOfBlocks-1:
		blockOffsets.append(_file.get_16())
	

