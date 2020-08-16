tool
extends Tree
var imagePreview = null
var lookupDict = {}
var root = null
func _ready():
	#hide_root = false
	self.connect("cell_selected",self,"cell_selected")
	anchor_right = 0.25
	anchor_bottom = 1
	hide_root = true

func _physics_process(delta):
	if Input.is_action_just_pressed("ui_accept"):
		var sel = get_selected()
		if sel != null:
			var dat = get_selected().get_metadata(0)
			var texture =get_parent().imageParser.parse(dat[0],dat[1],dat[2],dat[3])
			
			if imagePreview == null:
				imagePreview = Sprite.new()
				get_parent().add_child(imagePreview)
				
			imagePreview.position.x = get_viewport().size.x/2
			imagePreview.position.y = get_viewport().size.y/2
			imagePreview.texture = texture
			
			#anchor_right = 0
			#anchor_bottom = 0
			#visible = false

			
		

func set_dict(dict):
	var root = create_item()
	root.set_text(0,"root")
	recurseAdd(dict,root)

func recurseAdd(node,parent =null):
	var keys = node.keys()
	var title = ""
	if node != null:
		title = node
		
	for i in node.keys():
		var me = add(i,parent)
		if typeof(node[i]) != TYPE_ARRAY:
			recurseAdd(node[i],me)
		else:
			me.set_metadata(0,node[i])

func add(name,parent= root,meta = null):
	if typeof(parent) != TYPE_OBJECT:
		parent = root
	var ret = create_item(parent)
	ret.set_text(0,name)
	ret.collapsed = true
	if meta != null:
		ret.set_metadata(0,meta)
	
	return ret


func cell_selected():
	var meta = get_selected().get_metadata(0)
	print(meta)
	

