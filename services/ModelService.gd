extends Node

var models:Dictionary={}

var modelSource:String=""

func loadModelFiles(loadAt:String="")->void:
	for dir in DirAccess.get_directories_at(modelSource+loadAt):
		loadModelFiles(loadAt+"/"+dir)
	for f in DirAccess.get_files_at(modelSource+loadAt):
		loadModel(f)
	


func loadModel(modelPath:String)->void:
	var doc = GLTFDocument.new()
	var fileType=externalLoader.getExternalFileType(modelPath)
	if fileType!="PackedScene":return
	externalLoader.loadExternalFile(modelSource+modelPath)
	#on load fail load GLB directly
	var state = GLTFState.new()
	var error = doc.append_from_file(modelSource+modelPath,state)
	if error == OK:
		var packed=PackedScene.new()
		packed.pack(doc.generate_scene(state))
		packed.resource_path="res://FateMap/Imported/Models/%s"%modelPath
		models["res://FateMap/Imported/Models/%s"%modelPath]=packed
