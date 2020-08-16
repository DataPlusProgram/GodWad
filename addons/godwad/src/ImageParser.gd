extends Node
var parent = null

var flatAnimationDictPath = "res://addons/godwad/src/animatedTextureMappings.gd"
var flatAnimationDict = load("res://addons/godwad/src/animatedTextureMappings.gd").new()

#var file = global.file
var pallete = null
func parse(_file,offset,size,dataStore,rChannelIndex = true,saveOutputToFile = false):
	var colormap = parent.directories["GRAPHICS"]["COLORMAP"][3][0].get_data()
	var textureFlag = 0
	var restoreFilePosition = _file.get_position()
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
				
				
				colormap.lock()
				var color = colormap.get_pixel(pixel,0)
				colormap.unlock()
			
				
				#var color = pallete[pixel]#
				if rChannelIndex:
					color = Color(0,0,0,1)
					color.r = pixel/255.0
					
				image.set_pixel(x,i+rowStart,color)
			_file.get_8()#dumy
		
	image.unlock()
	
	var texture = ImageTexture.new()

		
	if saveOutputToFile:
		image.save_png("test.png")
	texture.create_from_image(image)
	
	#texture.flags += texture.FLAG_CONVERT_TO_LINEAR
	
	if parent.texture_filtering:
		texture.flags += texture.FLAGS_DEFAULT
	
	if parent.mipmaps:
		texture.flags += texture.FLAG_MIPMAPS
	
	if parent.anisotrophic:
		texture.flags +=texture.FLAG_ANISOTROPIC_FILTER
	
	_file.seek(restoreFilePosition)
	return texture


func parseFlat(_file,offset,size,dataStore,rChannelIndex = true,saveOutputToFile = false):
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
			
			if rChannelIndex:
					color = Color(0,0,0,1)
					color.r = dat[index]/255.0
			
			image.set_pixel(y,x,color)
			index+=1
	image.unlock()
	

	var texture = ImageTexture.new()
	texture.create_from_image(image)

	return texture
