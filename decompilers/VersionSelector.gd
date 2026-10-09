extends RefCounted
class_name EditorLoaderVersion


static func getLoader(version:int):
	for f in DirAccess.get_files_at("res://decompilers/editing"):
		if f.trim_prefix("editLoader_").trim_suffix(".gd")==str(version):
			return load("res://decompilers/editing/"+f).new()
	return null
	
