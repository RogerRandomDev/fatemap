extends RefCounted
class_name externalLoader

const extensionsForType:Dictionary={
	"PackedScene":["glb","gltf","fbx"],
	"Image":["png","jpg","jpeg","svg"],
	"Material":["material"]
}

static var alreadyLoaded:Dictionary={}


static func getExternalFileType(filePath:String):
	var fileName=filePath.rsplit("/")[-1]
	var fileType=fileName.split(".",true,1)[-1]
	fileName=fileName.trim_suffix(fileType)
	for extensionType in extensionsForType:
		if not extensionsForType[extensionType].has(fileType):continue
		return extensionType

static func loadExternalFile(filePath:String,overrideType:String="")->Variant:
	var fileName=filePath.rsplit("/")[-1]
	var fileType=fileName.split(".",true,1)[-1]
	fileName=fileName.trim_suffix(fileType)
	
	var fileLoadType=getExternalFileType(filePath)
	if not overrideType.is_empty():fileLoadType=overrideType
	if alreadyLoaded.has(filePath):
		return alreadyLoaded[filePath]
	match fileLoadType:
		"PackedScene":
			var packed:PackedScene=PackedScene.new()
			var sceneToPack:Node=null
			#gltf/fbx file loading
			if ["gltf","glb","fbx"].has(fileType):
				var document:GLTFDocument=(
					GLTFDocument.new() if 
					["gltf","glb"].has(fileType) else 
					FBXDocument.new())
				var state:GLTFState=(
					GLTFState.new() if 
					["gltf","glb"].has(fileType) else
					FBXState.new())
				document.append_from_file(filePath,state)
				sceneToPack=document.generate_scene(state)
			packed.pack(sceneToPack)
			alreadyLoaded[filePath]=packed
			return packed
		"Image":
			var img=Image.load_from_file(filePath)
			img.compress(Image.COMPRESS_S3TC)
			var imageTexture=ImageTexture.create_from_image(img)
			alreadyLoaded[filePath]=imageTexture
			return imageTexture
		"Material":
			var externalMaterial:Material=ResourceLoader.load(filePath,"Material")
			alreadyLoaded[filePath]=externalMaterial
			return externalMaterial
		
	return null
