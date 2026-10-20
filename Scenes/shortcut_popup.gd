extends PopupPanel

const shortcuts={
	"General":{
		"Delete":"Remove selected",
		"Shift":"Select Multiple",
		"Ctrl+z":"Undo",
		"Ctrl+Shift+z":"Redo",
		"(Click)RightMouse":"Open Menu"
	},
	"Camera":{
		"(drag)RightMouse":"Rotate Camera",
		"RightMouse+Scroll":"Adjust move speed",
		"RightMouse+(W|A|S|D)":"Move Camera"
	},
	"Objects":{
		"Left":"Move Selection Left",
		"Right":"Move Selection Right",
		"Up":"Move Selection Forward",
		"Down":"Move Selection Backward",
		"PageUp":"Move Selection Up",
		"PageDown":"Move Selection Down",
		"Models":{
		"(drag)LeftMouse":"Move object",
		},
		"Meshes":{
			"Ctrl+(drag)LeftMouse":"create mesh",
			"Scroll":"adjust vertical"
		}
	}
}

func _ready()->void:
	var root = $Tree.create_item()
	for s in shortcuts.keys():
		createItems(s,shortcuts[s],root)

func createItems(n:String,content,item:TreeItem)->void:
	if content is String:
		var sub:TreeItem=item.create_child()
		sub.set_text(0,n)
		sub.set_text(1,content)
	else:
		var sub:TreeItem=item.create_child()
		sub.set_text(0,n)
		for s in content.keys():
			createItems(s,content[s],sub)
	
