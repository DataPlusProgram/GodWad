extends Node
var parent = null

#var file = global.file
var pallete = null
func parse(_file,offset,size,dataStore,saveOutputToFile = false):
	if pallete == null:
		pallete = parent.directories["GRAPHICS"]["PLAYPAL"][3][0]
		
	_file.seek(offset)
	
	var width = _file.get_16()
	var height = _file.get_16()

	var left_offset = _file.get_16()
	var top_offset = _file.get_16()
	var columnOffsets = []
	for i in width:
		columnOffsets.append(_file.get_32())

	var image = Image.new()
	image.create(width,height,false,Image.FORMAT_RGBA8)
	image.lock()

	for x in range(0,width):
		#var dataIndex = 0
		_file.seek(offset + columnOffsets[x])
		var rowStart = 0
		while rowStart != 255:
			rowStart = _file.get_8()
			if rowStart == 255:
				break
			var pixCount = _file.get_8()
			var dummy = _file.get_8()
			for i in pixCount:
				var pixel = _file.get_8()
				var color = pallete[pixel]#
				image.set_pixel(x,i+rowStart,color)
			_file.get_8()#dumy
		
	image.unlock()
	
	var texture = ImageTexture.new()
	
	if saveOutputToFile:
		image.save_png("test.png")
	texture.create_from_image(image)
	return texture


func parseFlat(_file,offset,size,dataStore,saveOutputToFile = false):
	if pallete == null:
		pallete = parent.directories["GRAPHICS"]["PLAYPAL"][3][0]
	
	_file.seek(offset)
	var dat = _file.get_buffer(4096)
	var datConverted = [] 
	
	var image = Image.new()
	image.create(64,64,false,Image.FORMAT_RGBA8)
	image.lock()
	var index = 0
	for x in 64:
		for y in 64:
			var color = pallete[dat[index]]
			image.set_pixel(y,x,color)
			image
			index+=1
	image.unlock()
	
	#if saveOutputToFile:
		
	var texture = ImageTexture.new()
	texture.create_from_image(image)

	return texture
