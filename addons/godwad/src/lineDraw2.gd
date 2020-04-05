extends Control

export(Color) var color = Color(0,0,0)
export var drawScale = 1.0
var vector = Vector2.ZERO
var drawList = []
var pointList = []
var lineList = []
var polyList = []
var triangleList = []
var triangleColorList = []
var length = 100
func _physics_process(delta):
	update()

func _raedy():
	randomize()

func add_draw(start,end,color = Color.black):
	drawList.append([start,end,color])

func _draw():
	for i in drawList:
		draw_line(i[0]*drawScale,i[1]*drawScale,i[2])
		
	for i in pointList:
		draw_circle(i[0]*drawScale,3,i[1])
		
	for poly in polyList:
		var temp = []
		for v in poly[0]:
			temp.append(v*drawScale)
		draw_polygon(temp,poly[1])
		
	for i in triangleList.size():
		draw_primitive(triangleList[i],triangleColorList[i],[])
	
	for i in lineList:
		draw_line(i[0]*drawScale,i[1]*drawScale,i[2])
		
func erase():
	drawList.clear()
	pointList.clear()

func add_point(pos,color = Color.black):
	pointList.append([pos,color])

func add_line(a,b,color =null):
	if color == null:
		color = Color.from_hsv(randf(),1,1)
	
	lineList.append([a,b,color])
	

func add_poly(arr,color = null):
	randomize()
	if color == null:
		color = Color.from_hsv(randf(),1,1)
	
	var colorList = []
	for i in arr:
		colorList.append(color)
	
	polyList.append([arr,colorList])
	
func add_triangle(arr,color = null):
	var colorArr = []
	colorArr.resize(arr.size())
	
	if color == null:
		color = Color.from_hsv(randf(),1,1)
	triangleList.append(arr)
	triangleColorList.append([color,color,color])
	
