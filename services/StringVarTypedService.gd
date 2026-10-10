extends RefCounted
class_name StringVarTypedService


static func toVar(input:String,mapType:String)->Variant:
	mapType=mapType.to_lower()
	match mapType:
		"text":
			return input
		"boolean":
			var boolean_val=[&"true",&"t",&"1"].has(input.to_lower().strip_edges())
			if not (boolean_val||[&"false",&"f",&"0"].has(input.to_lower().strip_edges())):return null
			return boolean_val
		"color":
			var splitNums = input.split(" ",false)
			if splitNums.size()<3:return null
			if splitNums.size()<4:splitNums.push_back("255")
			return Color8(int(splitNums[0]),int(splitNums[1]),int(splitNums[2]),int(splitNums[3]))
		"file":
			if FileAccess.file_exists(input):
				return load(input)
			return null
		"float":
			return float(input.strip_edges())
		"integer":
			return int(input.strip_edges())
		"vector2":
			var splitNums = input.split(" ",false)
			if splitNums.size()!=2:return null
			return Vector2(float(splitNums[0]),float(splitNums[1]))
		"vector3":
			var splitNums = input.split(" ",false)
			if splitNums.size()!=3:return null
			return Vector3(float(splitNums[0]),float(splitNums[1]),float(splitNums[2]))
		"object":
			var uniqueID:=int(input)
			return instance_from_id(uniqueID)
	return null

static func toStr(input:Variant)->String:
	match typeof(input):
		TYPE_INT:return str(input)
		TYPE_FLOAT:return str(input)
		TYPE_COLOR:return "0 0 0 255" if input==null else "%s %s %s %s"%[input.r8,input.g8,input.b8,input.a8]
		TYPE_BOOL:return "TRUE" if input else "FALSE"
		TYPE_VECTOR2:return "%s %s"%[str(input.x),str(input.y)]
		TYPE_VECTOR3:return "%s %s %s"%[str(input.x),str(input.y),str(input.z)]
		TYPE_STRING:return input
		TYPE_STRING_NAME:return input
		TYPE_OBJECT:return str(input.get_instance_id())
	
	return ""
