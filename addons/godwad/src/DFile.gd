extends Node
var timings = {}

class DFile:
	var data
	var pos = 0
	
	func loadF(path):
		var file = File.new()
		if file.open(path,File.READ) != 0:
			print("Error opening file")
			return false
		data = file.get_buffer(file.get_len())
		
		file.close()
		return true
		
	
	func seek(offset):
		pos = offset
	
	func get_position():
		return pos
	
	func get_8():
		var ret = data[pos]
		pos+=1
		return ret
	
	func get_16():
		var ret = data.subarray(pos,pos+1)
		pos+=2
		return (ret[1] << 8) + ret[0]
	
	func get_32():
		var ret = data.subarray(pos,pos+3)
		pos+=4
		return (ret[3] << 24) + (ret[2] << 16) + (ret[1] << 8 ) + ret[0]
	
	func get_16u():
		var ret = data.subarray(pos,pos+1)
		ret =  (ret[1] << 8) + ret[0]
		if (ret & 0x8000):
			ret -= 0x8000
			ret = (-32767 + ret) -1
		
		pos+=2
		return ret
		
	func get_buffer(size):
		var ret = data.subarray(pos,pos+size)
		pos+=size
		return ret
	
	func get_String(length):
		var ret = data.subarray(pos,pos+(length-1)).get_string_from_ascii()
		pos+=length
		return ret.to_upper()

	func get_len():
		return data.size()
		
