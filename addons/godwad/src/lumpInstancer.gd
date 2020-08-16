tool
extends Node
var parent = null
#onready var file = global.file
var testFlag = false
func parse(_file,lumpName,lumpData):
	if lumpData.empty():
		return
	
	if lumpName == "LINEDEFS":
		if parent.hexenFormat == false:
			lumpData[3] = readLineDef(_file,lumpData[1],lumpData[2])
		else:
			lumpData[3] = readLineDefHexen(_file,lumpData[1],lumpData[2])
		
	elif lumpName == "SIDEDEFS":
		lumpData[3] = readSideDef(_file,lumpData[1],lumpData[2])
	
	elif lumpName == "VERTEXES":
		lumpData[3] = readVertices(_file,lumpData[1],lumpData[2])
	
	elif lumpName == "SECTORS":
		lumpData[3] = readSector(_file,lumpData[1],lumpData[2])
	
	elif lumpName == "SEGS":
		lumpData[3] = readSegs(_file,lumpData[1],lumpData[2])
	
	elif lumpName == "SSECTORS":
		lumpData[3] = readSubSectors(_file,lumpData[1],lumpData[2])
	
	elif lumpName == "PLAYPAL":
		lumpData[3] = readPLAYPAL(_file,lumpData[1],lumpData[2])
		
	elif lumpName == "COLORMAP":
		lumpData[3] = readCOLORMAP(_file,lumpData[1],lumpData[2])
	
	elif lumpName.substr(0,7) == "TEXTURE":
		lumpData[3] = readTexture(_file,lumpData[1],lumpData[2])
	
	elif lumpName == "PNAMES":
		lumpData[3] =readPname(_file,lumpData[1],lumpData[2])
	
	elif lumpName == "NODES":
		lumpData[3] =readNode(_file,lumpData[1],lumpData[2])
		
	elif lumpName == "BLOCKMAP":
		pass
	
	elif lumpName.substr(0,2) == "DS":
		lumpData[3] = readDS(_file,lumpData[1],lumpData[2])	
		#if lumpName == "DSPISTOL":
			#lumpData[3].play()
	#		breakpoint
	
	elif lumpName.substr(0,2) == "D_":
		lumpData[3] = readDS(_file,lumpData[1],lumpData[2])
		lumpData[3] = readMIDIknockoff(_file,lumpData[1],lumpData[2])
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


func readLineDefHexen(_file,offset,size):
	_file.seek(offset)
	var ret = []
	#var bif
	while(_file.get_position()-offset < size):
		var startVert = _file.get_16()
		var endVert = _file.get_16()
		var flags = _file.get_16()
		var specialType = _file.get_8()
		var arg1 = _file.get_8()
		var arg2 = _file.get_8()
		var arg3 = _file.get_8()
		var arg4 = _file.get_8()
		var arg5 = _file.get_8()
		var frontSidedef = _file.get_16()
		var backSidedef = _file.get_16()
		ret.append([startVert,endVert,flags,specialType,null,frontSidedef,backSidedef])
		
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
		for j in 256:
			pallete.append(Color8(_file.get_8(),_file.get_8(),_file.get_8()))
		ret.append(pallete)
	return ret


func readCOLORMAP2(_file,offset,size):
	_file.seek(offset)
	var ret = []
	for i in 34:
		var colorMap = []
		for j in 255:
			colorMap.append(_file.get_8())
		ret.append(colorMap)
	return ret


func readCOLORMAP(_file,offset,size):
	_file.seek(offset)
	var pallete = parent.directories["GRAPHICS"]["PLAYPAL"][3][0]

	
	var ret = []
	
	for i in 34:
		
		var image = Image.new()
		image.create(256,1,false,Image.FORMAT_RGBA8)
		image.lock()
		
		var colorMap = []
		for j in 256:
			var index =_file.get_8()
			image.set_pixel(j,0,pallete[index])
			
		
		image.unlock()
	
		var texture = ImageTexture.new()
		texture.create_from_image(image)
		#image.save_png("test" + String(i) + ".png")
		#texture.flags += texture.FLAG_CONVERT_TO_LINEAR
		ret.append(texture)
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
		
		for j in patchCount:
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
	

func readDS(_file,offset,size):
	_file.seek(offset)
	var sampleArr = []
	
	var magic = _file.get_16()
	var sampleRate = _file.get_16()
	var numberOfSamples = _file.get_16()
	var unk = _file.get_16()
	
	var audioPlayer = AudioStreamPlayer.new()
	audioPlayer.volume_db = -20.0
	
	var audio = AudioStreamSample.new()
	audio.format = AudioStreamSample.FORMAT_8_BITS
	audio.mix_rate = sampleRate

	var data = []
	
	for i in range(0,numberOfSamples - 4):#4 bytes of padding at end of sample:
		data.append(_file.get_8()-128)
		
	#print(sampleRate)
		
	audio.data = data
	audioPlayer.stream  = audio
	#parent.add_child(audioPlayer)
	#if testFlag == false and sampleRate == 22050:
	#	audioPlayer.play()
	#	testFlag = true
	#print("%s %s %s" % [magic,sampleRate,numberOfSamples])
	return audioPlayer

func readMIDIknockoff(_file,offset,size):
	_file.seek(offset)
	
	var magic = _file.get_String(4)
	var totalSize = _file.get_16()
	var startOffset = _file.get_16()
	var numPrimanyChannels = _file.get_16()
	var numSecondaryChannels = _file.get_16()
	var numInstrumentPatches = _file.get_16()
	var zero = _file.get_16()
	var instrumentPatchNumbers  = _file.get_16()
	
	_file.seek(startOffset)
	var data = _file.get_8()
	var type = (data >> 4) |  0b00000111
	#print("%s %s" % [data >> 4,type])
	#print(numPrimanyChannels)
	return
