extends Node



func loadProjectResources()->void:
	var newSource=ProjectSettings.get_setting("fatemap/project_directory","res:/")+"/FateMap/Imported/"
	if MaterialService.materialSource!=newSource:
		MaterialService.materialList.clear()
		MaterialService.materialSource=newSource
		MaterialService.loadAllFMT(MaterialService.materialSource+"Materials")
	
	var modelSource="%s/FateMap/Imported/Models/"%ProjectSettings.get_setting("fatemap/project_directory","res://")
	if ModelService.modelSource!=modelSource:
		ModelService.models.clear()
		ModelService.modelSource=modelSource
		ModelService.loadModelFiles()
