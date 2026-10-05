extends RefCounted


static var editing:editingMesh
static var editMode:MeshEditMode=MeshEditMode.FACE:
	set(v):
		editMode=v
		FateMap.signalService.emitSignal(&"EditModeChanged",[v])
static var editingType:FateMap.ObjectModel.objectTypes:
	get:return FateMap.ObjectModel.objectTypes.MAX if editor.editingObject==null else editor.editingObject.objectType

static var editor:FateMap.meshEditMode



static func initializeService()->void:pass

static func setEditing(object:FateMap.ObjectModel)->void:
	FateMap.signalService.emitSignal.call_deferred(&"UpdateEditingMesh")
	if object==null:
		editing=null
		return
	
	editor=FateMap.ParameterService.getParam(&"CurrentMeshEditMode").new()
	editor.camera=object.get_viewport().get_camera_3d()
	editor.updateEditingObject(object)
	match object.objectType:
		FateMap.ObjectModel.objectTypes.OBJECT:
			editor=load("res://models/meshEditModes/basicObject.gd").new()
			editor.camera=object.get_viewport().get_camera_3d()
			editor.updateEditingObject(object)
			editing=editingMesh.new(object,null)
			return
		FateMap.ObjectModel.objectTypes.MESH:
			var mesh=object.get_node_or_null("MESH_OBJECT")
			if editing and editing.meshObject==mesh:return
			editing=editingMesh.new(object,mesh)
			editing.mesh.preloadCleanFaces()

static func getEditing():
	return editing

static func isEditing()->bool:return editing!=null

static func getEditMode()->MeshEditMode:return editMode

static func changeEditor(newEditor)->void:
	editor = newEditor.new(editor)

enum MeshEditMode{
	FACE=0,
	EDGE=1,
	VERTEX=2
}

class editingMesh extends Resource:
	var dataObject:FateMap.ObjectModel
	var meshObject:MeshInstance3D
	var mesh:FateMap.objectMeshModel:
		get:return null if meshObject==null else meshObject.mesh
	
	#surface special info
	#part selections
	var selectedFaces:Array[FateMap.objectMeshModel.meshFace]=[]
	var selectedEdges:Array[FateMap.objectMeshModel.meshEdge]=[]
	var selectedVertices:Array[FateMap.objectMeshModel.meshVertex]=[]
	
	var editing:bool=false
	var mode:MeshEditMode=MeshEditMode.FACE
	
	
	func _init(data:FateMap.ObjectModel,meshInst:MeshInstance3D):
		dataObject=data
		meshObject=meshInst
	
	
	##initialize info to begin altering the mesh
	func beginEdit(commitPast:bool=true)->void:
		if editing:
			if commitPast:
				#commit()
				pass
			else:return
		assert(meshObject.mesh!=null,"editingMesh meshObject mesh cannot be null")
		if meshObject.mesh==null:return
		clearSelections()
		editing=true
	
	##clears selected arrays
	func clearSelections(_ignoreChange:bool=true)->void:
		selectedFaces=[]
		selectedEdges=[]
		selectedVertices=[]
		
	
	func deselectVertex(vertex:FateMap.objectMeshModel.meshVertex)->void:
		if not selectedVertices.has(vertex):return
		selectedVertices.erase(vertex)
	func deselectEdge(edge:FateMap.objectMeshModel.meshEdge)->void:
		if not selectedEdges.has(edge):return
		selectedEdges.erase(edge)
		for vertex in edge.vertices:deselectVertex(vertex)
	func deselectFace(face:FateMap.objectMeshModel.meshFace)->void:
		if not selectedFaces.has(face):return
		selectedFaces.erase(face)
		for edge in face.edges:deselectEdge(edge)
	
	func deselect(meshPart)->void:
		if meshPart is FateMap.objectMeshModel.meshVertex:deselectVertex(meshPart)
		if meshPart is FateMap.objectMeshModel.meshEdge:deselectEdge(meshPart)
		if meshPart is FateMap.objectMeshModel.meshFace:deselectFace(meshPart)
		if meshPart is FateMap.objectMeshModel.cleanedFace:for face in meshPart.faces:deselectFace(face)
	
	func selectVertex(vertex:FateMap.objectMeshModel.meshVertex,toggleSelected:bool=false)->void:
		if not mesh.vertices.has(vertex):return
		if not selectedVertices.has(vertex):selectedVertices.push_back(vertex)
		elif toggleSelected:deselectVertex(vertex)
	func selectEdge(edge:FateMap.objectMeshModel.meshEdge,toggleSelected:bool=false)->void:
		if not mesh.edges.has(edge):return
		if not selectedEdges.has(edge):
			selectedEdges.push_back(edge)
			for vertex in edge.vertices:selectVertex(vertex,toggleSelected)
		elif toggleSelected:deselectEdge(edge)
	func selectFace(face:FateMap.objectMeshModel.meshFace,toggleSelected:bool=false)->void:
		if not mesh.faces.has(face):return
		if not selectedFaces.has(face):
			selectedFaces.push_back(face)
			for edge in face.edges:selectEdge(edge,toggleSelected)
		elif toggleSelected:deselectFace(face)
		
	func select(meshPart,toggleSelected:bool=false)->void:
		if meshPart is FateMap.objectMeshModel.meshVertex:selectVertex(meshPart,toggleSelected)
		if meshPart is FateMap.objectMeshModel.meshEdge:selectEdge(meshPart,toggleSelected)
		if meshPart is FateMap.objectMeshModel.meshFace:selectFace(meshPart,toggleSelected)
		if meshPart is FateMap.objectMeshModel.cleanedFace:for face in meshPart.faces:selectFace(face,toggleSelected)
		if meshPart is FateMap.objectMeshModel.cleanedEdge:for edge in meshPart.edges:selectEdge(edge,toggleSelected)
		if meshPart is FateMap.objectMeshModel.cleanedVertex:for vertex in meshPart.vertices:selectVertex(vertex,toggleSelected)
	
	func updateSelectionTracked(ignore:bool=false)->void:
		if meshObject==null:return
		var changes=meshObject.mesh.updateSelection(
			selectedVertices,selectedEdges,selectedFaces
		)
		if ignore:return
		#we changed
		if changes.values().any(func(v):return v.any(func(e):return e.size()>0)):
			loadSelectionUndoRedo(changes)
	func loadSelectionUndoRedo(changes:Dictionary)->void:
		FateMap.UndoRedoService.startAction(&"SelectMeshParts")
		FateMap.UndoRedoService.addDo(func():
			var newEdit=FateMap.MeshEditService.getEditing()
			for i in 3:for selectable in changes[&"added"][i]:newEdit.select(selectable,false)
			for i in 3:for selectable in changes[&"removed"][i]:newEdit.deselect(selectable)
			newEdit.updateSelectionTracked(true)
			FateMap.signalService.emitSignal(&"meshSelectionChanged")
			)
		FateMap.UndoRedoService.addUndo(func():
			var newEdit=FateMap.MeshEditService.getEditing()
			for i in 3:for selectable in changes[&"added"][i]:newEdit.deselect(selectable)
			for i in 3:for selectable in changes[&"removed"][i]:newEdit.select(selectable,false)
			newEdit.updateSelectionTracked(true)
			FateMap.signalService.emitSignal(&"meshSelectionChanged")
		)
		FateMap.UndoRedoService.commitAction()
	
	##obtains any face and connected vertex using info from clicking on the object
	func selectByClickInfo(normal:Vector3,hitPosition:Vector3=Vector3.ZERO,keep:bool=false)->Array[FateMap.objectMeshModel.meshFace]:
		if not keep:clearSelections()
		var localNormal = normal*meshObject.global_transform.basis.get_rotation_quaternion()
		hitPosition-=meshObject.global_position
		var hitFace= mesh.getSelectedFaces(localNormal.snappedf(0.001),hitPosition)
		for face in  hitFace:selectFace(face,keep)
		return hitFace
	
	func translateSelection(translateBy:Vector3,local:bool=true,mergeMove:bool=false)->void:
		if selectedVertices.size()==0 or translateBy.is_zero_approx():return
		if local:translateBy*=meshObject.global_transform.basis.get_rotation_quaternion()
		var editingPositionIDs={}
		for vertex in selectedVertices:editingPositionIDs[vertex.positionID]=mesh.positionIDs[vertex.positionID]
		#FateMap.UndoRedoService.startAction(&"TranslateMeshPoints",UndoRedo.MERGE_ENDS)
		FateMap.UndoRedoService.startAction(&"TranslateMeshPoints",UndoRedo.MERGE_ALL if mergeMove else UndoRedo.MERGE_DISABLE)
		#breaks if i re-center the mesh elsewhere cause it changes where everything is relative
		#if i do MERGE_ALL and just add/subtract the change instead it works fine.
		FateMap.UndoRedoService.addMethods(
			(func():
				for positionID in editingPositionIDs.keys():
					#mesh.positionIDs[positionID]=editingPositionIDs[positionID]+translateBy
					mesh.positionIDs[positionID]+=translateBy
				),
			(func():
				for positionID in editingPositionIDs.keys():
					#mesh.positionIDs[positionID]=editingPositionIDs[positionID]
					mesh.positionIDs[positionID]-=translateBy
				)
		)
		var rebuild = FateMap.MeshEditService.editing.mesh.rebuild
		FateMap.UndoRedoService.addMethods(
			func():
				FateMap.MeshEditService.editing.mesh.rebuild(false)
				FateMap.signalService.emitSignal.call_deferred(&"meshSelectionChanged")
				,
			func():
				FateMap.MeshEditService.editing.mesh.rebuild.call_deferred(false)
				FateMap.signalService.emitSignal.call_deferred(&"meshSelectionChanged")
		)
		
		
		FateMap.UndoRedoService.commitAction(true)
	
	func centerMesh()->void:
		var aabb=AABB(mesh.positionIDs.values()[0],Vector3.ZERO)
		for vertex in mesh.positionIDs.values():
			aabb.position=aabb.position.min(vertex)
			aabb.size=aabb.size.max(vertex)
		aabb.size-=aabb.position
		for vertex in mesh.positionIDs:
			mesh.positionIDs[vertex]-=aabb.get_center()
		meshObject.get_parent().position+=aabb.get_center()*meshObject.global_basis.get_rotation_quaternion().inverse()
		mesh.globalTransform.origin+=aabb.get_center()*meshObject.global_basis.get_rotation_quaternion().inverse()
		meshObject.get_parent().notification(Node3D.NOTIFICATION_TRANSFORM_CHANGED)
	
	func snapSelectedToGrid()->void:
		if selectedVertices.size()==0:return
		var editingPositionIDs={}
		for vertex in selectedVertices:editingPositionIDs[vertex.positionID]=null
		for positionID in editingPositionIDs.keys():
			mesh.positionIDs[positionID]=mesh.positionIDs[positionID].snappedf(
				FateMap.ParameterService.getParam(&"snapDistance")
			)
	
	#not implemented yet, it will slide your edit along the edges to keep angles consistent
	func translateAlongEdges()->void:
		#var alongAxis=FateMap.MeshEditService.editing.mesh.getCleanEdgesTouchingCleanFace(
			#FateMap.MeshEditService.editing.mesh.getCleanFaceForFace(FateMap.MeshEditService.editing.selectedFaces[0])
		#)
		#var positionAlongAxis=[]
		#positionAlongAxis.push_back(
				#alongAxis.find_custom(func(edge):return edge.positionIDs.has(vertex.positionID))
			#)
		#*alongAxis[positionAlongAxis[i]].getQuaternion(positionID)
		pass
	
	func setMaterialOnFaces(material:FateMap.MaterialService.materialModel,faces:Array[FateMap.objectMeshModel.meshFace])->void:
		if faces.size()==0:return
		for face in faces:
			face.setSurfaceMaterial(material)
	
	func setMaterial(material:FateMap.MaterialService.materialModel,setAllIfNoneActive:bool=false)->void:
		if setAllIfNoneActive and selectedFaces.size()==0:
			for face in mesh.faces:face.setSurfaceMaterial(material)
		
		for face in selectedFaces:
			face.setSurfaceMaterial(material)
