extends RefCounted
class_name MaterialService

static var materialList:Array[materialModel]=[]
static var basicMaterial:Material=null
static var basicMaterialParams:Dictionary={}

static func setDefaultMaterialBase(material:Material,params:Dictionary={})->void:
	basicMaterial=material
	basicMaterialParams=params

static func addMaterial(materialName:StringName,material:Material=null,texture:Texture=null,params:Dictionary={},tags:PackedStringArray=[])->bool:
	var ignoreBaseParams:bool=false
	if material==null:material=basicMaterial
	else:ignoreBaseParams=true
	
	var newMaterial=materialModel.new(materialName,params,ignoreBaseParams)
	if materialList.any(func(mat):return mat.checkConflict(newMaterial)):
		return false
	newMaterial.setMaterial(material)
	newMaterial.setTexture(texture)
	newMaterial.setTags(tags)
	newMaterial.updateMaterial()
	materialList.push_back(newMaterial)
	
	return true

static func getMaterialList()->Array[materialModel]:return materialList

static func getMaterial(materialName:StringName)->materialModel:
	var index = materialList.find_custom(func(mat):return mat.materialName==materialName)
	
	if index==-1:return null
	return materialList[index]




class materialModel extends Resource:
	var materialName:StringName
	var materialMat:Material
	var materialTexture:Texture
	var materialParameters:Dictionary={}
	var materialTags:PackedStringArray=[]
	
	
	func _init(name:StringName=&"",params:Dictionary={},ignoreDefaultParams:bool=false):
		materialName=name
		if not ignoreDefaultParams:materialParameters=MaterialService.basicMaterialParams.duplicate(false)
		for parameter in params:
			materialParameters[parameter]=params[parameter]
		updateMaterial()
	
	func setTexture(texture:Texture)->void:
		materialTexture=texture
		updateMaterial()
	
	##sets the material and specifies to make it unique or shared
	func setMaterial(mat:Material,unique:bool=true)->void:
		if unique:
			materialMat=mat.duplicate(true)
		else:
			materialMat=mat
		updateMaterial()
	
	##Sets the parameters for the material using the provided dictionary
	func setParameters(parameterList:Dictionary={},ignoreDefaultParams:bool=false)->void:
		if not ignoreDefaultParams:materialParameters=MaterialService.basicMaterialParams.duplicate(false)
		for parameter in parameterList:
			materialParameters[parameter]=parameterList[parameter]
		updateMaterial()
	
	##applies tags to the material
	func setTags(tags:PackedStringArray)->void:
		materialTags=tags
	
	##returns an assembled copy of the material that can be shared or unique
	func getInstance(unique:bool=true)->Material:
		var materialInstance:Material
		if unique:materialInstance=materialMat.duplicate()
		else:materialInstance=materialMat
		
		return materialInstance
	
	##updates the material to keep up to date with current stored values
	func updateMaterial()->void:
		if materialMat is StandardMaterial3D:
			materialMat.albedo_texture=materialTexture
			var possibleParameters:Array=materialMat.get_property_list().map(func(param):return param.name)
			for param in materialParameters:
				if not possibleParameters.has(param):continue
				materialMat.set(param,materialParameters[param])
		if materialMat is ShaderMaterial:
			var shaderParameterList=(
				materialMat.get_property_list().filter(
					func(param):return param.name.begins_with("shader_parameter/")
				).map(func(param):return param.name.trim_prefix("shader_parameter/"))
			)
			if shaderParameterList.has("albedoTexture"):
				materialMat.set_shader_parameter(&"albedoTexture",materialTexture)
			for param in materialParameters:
				if not shaderParameterList.has(param):continue
				materialMat.set_shader_parameter(param,materialParameters[param])
	
	##check that the check material isn't conflicting with anything in this material
	func checkConflict(check:materialModel):
		return (
			check.materialName==materialName
		)
