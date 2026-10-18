extends RefCounted
class_name MeshEditService


static var editing:editingMesh
static var editMode:MeshEditMode=MeshEditMode.FACE:
	set(v):
		editMode=v
		signalService.emitSignal(&"EditModeChanged",[v])
static var editingType:ObjectModel.objectTypes:
	get:return ObjectModel.objectTypes.MAX if editor.editingObjects.size()==0 else editor.editingObjects[0].objectType

static var editor:meshEditMode



static func initializeService()->void:pass

static func setEditing(objects:Array=[])->void:
	signalService.emitSignal.call_deferred(&"UpdateEditingMesh")
	if objects.size()==0:
		editing=null
		return
	var activeDataObjects=[]
	var activeMeshObjects=[]
	for object in objects:
		activeDataObjects.push_back(object)
		activeMeshObjects.push_back(object.get_node_or_null("MESH_OBJECT"))
	var oldEditing=editing
	editor=ParameterService.getParam(&"CurrentMeshEditMode").new()
	editor.camera=objects[0].get_viewport().get_camera_3d()
	editor.updateEditingObjects(activeDataObjects)
	var object = activeDataObjects[0] #use first selected object as base
	match object.objectType:
		ObjectModel.objectTypes.DATA:
			editor=load("res://models/meshEditModes/basicObject.gd").new()
			editor.camera=object.get_viewport().get_camera_3d()
			editor.updateEditingObjects(activeDataObjects)
			editing=editingMesh.new(activeDataObjects,activeMeshObjects)
			return
		ObjectModel.objectTypes.OBJECT:
			editor=load("res://models/meshEditModes/basicObject.gd").new()
			editor.camera=object.get_viewport().get_camera_3d()
			editor.updateEditingObjects(activeDataObjects)
			editing=editingMesh.new(activeDataObjects,activeMeshObjects)
			return
		ObjectModel.objectTypes.MESH:
			editing=editingMesh.new(activeDataObjects,activeMeshObjects)
			for editMesh in editing.meshes:
				if editMesh==null:continue
				editMesh.preloadCleanFaces()
	editing.copyOver(oldEditing)

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
	var dataObjects:Array=[] #objectmodel
	var meshObjects:Array=[] #meshinstance3d
	var meshes:Array[objectMeshModel]=[] #objectmeshmodel
	
	#surface special info
	#part selections
	var selectedCleanFaces:Array[objectMeshModel.cleanedFace]=[]
	var selectedCleanEdges:Array[objectMeshModel.cleanedEdge]=[]
	var selectedCleanVertices:Array[objectMeshModel.cleanedVertex]=[]
	var selectedFaces:Array[objectMeshModel.meshFace]=[]
	var selectedEdges:Array[objectMeshModel.meshEdge]=[]
	var selectedVertices:Array[objectMeshModel.meshVertex]=[]
	
	var editing:bool=false
	var mode:MeshEditMode=MeshEditMode.FACE
	
	
	func _init(data:Array,meshInst:Array):
		dataObjects=data
		meshObjects=meshInst
		meshObjects.resize(dataObjects.size())
		for obj in meshObjects:
			meshes.push_back(null if obj==null else obj.mesh)
	
	func copyOver(old:editingMesh):
		if old==null:return
		selectedCleanFaces=old.selectedCleanFaces.filter(func(f):return meshes.has(f.faces[0]._mesh))
		selectedCleanEdges=old.selectedCleanEdges.filter(func(f):return meshes.has(f.edges[0]._mesh))
		selectedCleanVertices=old.selectedCleanVertices.filter(func(f):return meshes.has(f.vertices[0]._mesh))
		selectedFaces=old.selectedFaces.filter(func(f):return meshes.has(f._mesh))
		selectedEdges=old.selectedEdges.filter(func(f):return meshes.has(f._mesh))
		selectedVertices=old.selectedVertices.filter(func(f):return meshes.has(f._mesh))
	
	
	
	##initialize info to begin altering the mesh
	func beginEdit(commitPast:bool=true)->void:
		if editing:
			if commitPast:
				#commit()
				pass
			else:return
		clearSelections()
		editing=true
	
	##clears selected arrays
	func clearSelections(_ignoreChange:bool=true)->void:
		selectedCleanFaces=[]
		selectedFaces=[]
		selectedEdges=[]
		selectedVertices=[]
		
	
	func deselectVertex(vertex:objectMeshModel.meshVertex)->void:
		if not selectedVertices.has(vertex):return
		selectedVertices.erase(vertex)
	func deselectEdge(edge:objectMeshModel.meshEdge)->void:
		if not selectedEdges.has(edge):return
		selectedEdges.erase(edge)
		for vertex in edge.vertices:deselectVertex(vertex)
	func deselectFace(face:objectMeshModel.meshFace)->void:
		if not selectedFaces.has(face):return
		selectedFaces.erase(face)
		for edge in face.edges:deselectEdge(edge)
	func deselectCleanVertex(cleanVertex:objectMeshModel.cleanedVertex)->void:
		if not selectedCleanVertices.has(cleanVertex):return
		selectedCleanVertices.erase(cleanVertex)
		for vertex in cleanVertex.vertices:deselectVertex(vertex)
	func deselectCleanEdge(cleanEdge:objectMeshModel.cleanedEdge)->void:
		if not selectedCleanEdges.has(cleanEdge):return
		selectedCleanEdges.erase(cleanEdge)
		for edge in cleanEdge.edges:deselectEdge(edge)
	func deselectCleanFace(cleanFace:objectMeshModel.cleanedFace)->void:
		if not selectedCleanFaces.has(cleanFace):return
		selectedCleanFaces.erase(cleanFace)
		for face in cleanFace.faces:deselectFace(face)
	
	func deselect(meshPart)->void:
		if meshPart is objectMeshModel.meshVertex:deselectVertex(meshPart)
		if meshPart is objectMeshModel.meshEdge:deselectEdge(meshPart)
		if meshPart is objectMeshModel.meshFace:deselectFace(meshPart)
		if meshPart is objectMeshModel.cleanedVertex:deselectCleanVertex(meshPart)
		if meshPart is objectMeshModel.cleanedEdge:deselectCleanEdge(meshPart)
		if meshPart is objectMeshModel.cleanedFace:deselectCleanFace(meshPart)
	
	func selectVertex(vertex:objectMeshModel.meshVertex,toggleSelected:bool=false)->void:
		if not meshes.any(func(mesh):return mesh!=null and mesh.vertices.has(vertex)):return
		if not selectedVertices.has(vertex):selectedVertices.push_back(vertex)
		else:if toggleSelected:deselectVertex(vertex)
	func selectEdge(edge:objectMeshModel.meshEdge,toggleSelected:bool=false)->void:
		if not meshes.any(func(mesh):return mesh!=null and mesh.edges.has(edge)):return
		if not selectedEdges.has(edge):
			selectedEdges.push_back(edge)
			for vertex in edge.vertices:selectVertex(vertex,false)
		else:if toggleSelected:deselectEdge(edge)
	func selectFace(face:objectMeshModel.meshFace,toggleSelected:bool=false)->void:
		if not meshes.any(func(mesh):return mesh!=null and mesh.faces.has(face)):return
		if not selectedFaces.has(face):
			selectedFaces.push_back(face)
			for edge in face.edges:selectEdge(edge,false)
		else:if toggleSelected:deselectFace(face)
	func selectCleanVertex(cleanVertex:objectMeshModel.cleanedVertex,toggleSelected:bool=false)->void:
		if not meshes.any(func(mesh):return mesh!=null and mesh.cleanedVertices.has(cleanVertex)):return
		if not selectedCleanVertices.has(cleanVertex):
			selectedCleanVertices.push_back(cleanVertex)
			for vertex in cleanVertex.vertices:selectVertex(vertex,false)
		else:if toggleSelected:deselectCleanVertex(cleanVertex)
	func selectCleanEdge(cleanEdge:objectMeshModel.cleanedEdge,toggleSelected:bool=false)->void:
		if not meshes.any(func(mesh):return mesh!=null and mesh.cleanedEdges.has(cleanEdge)):return
		if not selectedCleanEdges.has(cleanEdge):
			selectedCleanEdges.push_back(cleanEdge)
			for edge in cleanEdge.edges:selectEdge(edge,false)
		else:if toggleSelected:deselectCleanEdge(cleanEdge)
	func selectCleanFace(cleanFace:objectMeshModel.cleanedFace,toggleSelected:bool=false)->void:
		if not meshes.any(func(mesh):return mesh!=null and mesh.cleanedFaces.has(cleanFace)):return
		if not selectedCleanFaces.has(cleanFace):
			selectedCleanFaces.push_back(cleanFace)
			for edge in cleanFace.cleanEdges:selectCleanEdge(edge,false)
			for face in cleanFace.faces:selectFace(face,false)
		else:if toggleSelected:deselectCleanFace(cleanFace)
		
	func select(meshPart,toggleSelected:bool=false)->void:
		if meshPart is objectMeshModel.meshVertex:selectVertex(meshPart,toggleSelected)
		if meshPart is objectMeshModel.meshEdge:selectEdge(meshPart,toggleSelected)
		if meshPart is objectMeshModel.meshFace:selectFace(meshPart,toggleSelected)
		if meshPart is objectMeshModel.cleanedVertex:selectCleanVertex(meshPart)
		if meshPart is objectMeshModel.cleanedEdge:selectCleanEdge(meshPart)
		if meshPart is objectMeshModel.cleanedFace:selectCleanFace(meshPart,toggleSelected)
	
	func isSelected(meshPart)->bool:
		if meshPart is objectMeshModel.meshVertex:return selectedVertices.has(meshPart)
		if meshPart is objectMeshModel.meshEdge:return selectedEdges.has(meshPart)
		if meshPart is objectMeshModel.meshFace:return selectedFaces.has(meshPart)
		if meshPart is objectMeshModel.cleanedFace:return selectedCleanFaces.has(meshPart)
		if meshPart is objectMeshModel.cleanedEdge:return selectedCleanEdges.has(meshPart)
		if meshPart is objectMeshModel.cleanedVertex:return selectedCleanVertices.has(meshPart)
		return false
	
	func updateSelectionTracked(ignore:bool=false)->void:
		if meshObjects.size()==0:return
		var changes:Dictionary={
			&"added":[[],[],[],[],[],[]],
			&"removed":[[],[],[],[],[],[]]
		}
		#get all uupdated selections for each mesh in the selection
		for mesh in meshes:
			if mesh==null:continue
			var meshChanges = mesh.updateSelection(
				selectedVertices.filter(func(v):return v._mesh==mesh),
				selectedEdges.filter(func(v):return v._mesh==mesh),
				selectedFaces.filter(func(v):return v._mesh==mesh),
				selectedCleanVertices.filter(func(v):return v.vertices[0]._mesh==mesh),
				selectedCleanEdges.filter(func(v):return v.edges[0]._mesh==mesh),
				selectedCleanFaces.filter(func(v):return v.faces[0]._mesh==mesh),
				)
			var addSet=meshChanges.get(&"added",[[],[],[],[]])
			var removeSet=meshChanges.get(&"removed",[[],[],[],[]])
			for i in 4:
				changes.get(&"added")[i].append_array(addSet[i])
				changes.get(&"removed")[i].append_array(removeSet[i])
			
			
		if ignore:return
		#we changed
		if changes.values().any(func(v):return v.any(func(e):return e.size()>0 and not (e[0] is objectMeshModel.cleanedVertexObject or e[0] is objectMeshModel.cleanedVertex))):
			loadSelectionUndoRedo(changes)
	func loadSelectionUndoRedo(changes:Dictionary)->void:
		UndoRedoService.startAction(&"SelectMeshParts")
		UndoRedoService.addDo(func():
			var newEdit=MeshEditService.getEditing()
			for i in 6:for selectable in changes[&"added"][i]:newEdit.select(selectable,false)
			for i in 6:for selectable in changes[&"removed"][i]:newEdit.deselect(selectable)
			newEdit.updateSelectionTracked(true)
			signalService.emitSignal(&"meshSelectionChanged")
			)
		UndoRedoService.addUndo(func():
			var newEdit=MeshEditService.getEditing()
			for i in 6:for selectable in changes[&"added"][i]:newEdit.deselect(selectable)
			for i in 6:for selectable in changes[&"removed"][i]:newEdit.select(selectable,false)
			newEdit.updateSelectionTracked(true)
			signalService.emitSignal(&"meshSelectionChanged")
		)
		UndoRedoService.commitAction()
	
	##obtains any face and connected vertex using info from clicking on the object
	func selectByClickInfo(normal:Vector3,hitPosition:Vector3=Vector3.ZERO,keep:bool=false)->Array[objectMeshModel.meshFace]:
		if not keep:clearSelections()
		var hitFace:Array=[]
		for meshObject in meshObjects:
			if meshObject==null:continue
			var localNormal = normal*meshObject.global_transform.basis.get_rotation_quaternion()
			hitPosition-=meshObject.global_position
			hitFace.append_array(meshObject.mesh.getSelectedFaces(localNormal.snappedf(0.001),hitPosition))
			for face in  hitFace:selectFace(face,keep)
		return hitFace
	
	func translateSelection(translateBy:Vector3,local:bool=true,mergeMove:bool=false)->void:
		if selectedVertices.size()==0 or translateBy.is_zero_approx():return
		UndoRedoService.startAction(&"TranslateMeshPoints",UndoRedo.MERGE_ENDS if mergeMove else UndoRedo.MERGE_DISABLE)
		var selectedPositionIDs={}
		var editingMeshPositionIDs={}
		var editingMeshPositionIDsInitial={}
		var meshOwnerInitialOrigins={}
		var meshInternalInitialTransforms={}
		var meshOwnerOrigins={}
		var meshInternalTransforms={}
		for vertex in selectedVertices:
			selectedPositionIDs.get_or_add(vertex._mesh,{})[vertex.positionID]=null
		for mesh in selectedPositionIDs.keys():
			meshOwnerInitialOrigins[mesh]=mesh.ownerInstance.global_position
			meshInternalInitialTransforms[mesh]=mesh.globalTransform
			
			editingMeshPositionIDsInitial[mesh]=mesh.positionIDs.duplicate()
			for positionID in selectedPositionIDs[mesh].keys():
				mesh.positionIDs[positionID]+=translateBy
			var centerOffset=MeshEditService.editing.getMeshCenterOffset(mesh)
			for positionID in mesh.positionIDs:
				mesh.positionIDs[positionID]-=centerOffset
			mesh.ownerInstance.get_parent().position+=centerOffset*mesh.ownerInstance.global_basis
			mesh.globalTransform.origin+=centerOffset*mesh.ownerInstance.global_basis.inverse()
			editingMeshPositionIDs[mesh]=mesh.positionIDs.duplicate()
			meshOwnerOrigins[mesh]=mesh.ownerInstance.global_position
			meshInternalTransforms[mesh]=mesh.globalTransform
		if translateBy.is_zero_approx():return
		UndoRedoService.addMethods((func():
			for mesh in selectedPositionIDs.keys():
				mesh.positionIDs=editingMeshPositionIDs[mesh].duplicate()
				mesh.ownerInstance.get_parent().position=meshOwnerOrigins[mesh]
				mesh.globalTransform.origin=meshInternalTransforms[mesh].origin
				#rebuild and load
				mesh.rebuild(false)
				PhysicalObjectService.updatePickableArea(mesh.ownerInstance.get_parent())
				signalService.emitSignal.call_deferred(&"meshSelectionChanged")
			),(
		func():
			for mesh in selectedPositionIDs.keys():
				mesh.positionIDs=editingMeshPositionIDsInitial[mesh].duplicate()
				mesh.ownerInstance.get_parent().position=meshOwnerInitialOrigins[mesh]
				mesh.globalTransform.origin=meshInternalInitialTransforms[mesh].origin
				#rebuild and load
				mesh.rebuild(false)
				PhysicalObjectService.updatePickableArea(mesh.ownerInstance.get_parent())
				signalService.emitSignal.call_deferred(&"meshSelectionChanged")
		))
		UndoRedoService.commitAction(true)
	
	func applyScale()->void:
		for mesh in meshes:
			if mesh==null:continue
			var dataObject=mesh.ownerInstance.get_parent()
			for id in mesh.positionIDs:
				mesh.positionIDs[id]*=dataObject.scale
			dataObject.scale=Vector3.ONE
	
	func getMeshCenterOffset(mesh:objectMeshModel)->Vector3:
		var aabb=AABB(mesh.positionIDs.values()[0],Vector3.ZERO)
		for vertex in mesh.positionIDs.values():
			aabb.position=aabb.position.min(vertex)
			aabb.size=aabb.size.max(vertex)
		aabb.size-=aabb.position
		return aabb.get_center()
	
	func centerMesh(specified:Array=[])->void:
		if specified.size()==0:
			specified=meshes
		for mesh in specified:
			if mesh==null:continue
			var meshObject=mesh.ownerInstance
			var center=getMeshCenterOffset(mesh)
			for vertex in mesh.positionIDs:
				mesh.positionIDs[vertex]-=center
			meshObject.get_parent().position+=center*meshObject.global_basis
			mesh.globalTransform.origin+=center*meshObject.global_basis.inverse()
			meshObject.get_parent().notification(Node3D.NOTIFICATION_TRANSFORM_CHANGED)
	
	func snapSelectedToGrid()->void:
		if selectedVertices.size()==0:return
		var editingMeshPositionIDs={}
		for vertex in selectedVertices:
			editingMeshPositionIDs.get_or_add(vertex._mesh,{})[vertex.positionID]=null
		for mesh in editingMeshPositionIDs.keys():
			for positionID in editingMeshPositionIDs[mesh].keys():
				mesh.positionIDs[positionID]=mesh.positionIDs[positionID].snappedf(
					ParameterService.getParam(&"snapDistance")
				)
	
	#not implemented yet, it will slide your edit along the edges to keep angles consistent
	func translateAlongEdges()->void:
		#var alongAxis=MeshEditService.editing.mesh.getCleanEdgesTouchingCleanFace(
			#MeshEditService.editing.mesh.getCleanFaceForFace(MeshEditService.editing.selectedFaces[0])
		#)
		#var positionAlongAxis=[]
		#positionAlongAxis.push_back(
				#alongAxis.find_custom(func(edge):return edge.positionIDs.has(vertex.positionID))
			#)
		#*alongAxis[positionAlongAxis[i]].getQuaternion(positionID)
		pass
	
	func setMaterialOnFaces(material:MaterialService.materialModel,faces:Array[objectMeshModel.meshFace])->void:
		if faces.size()==0:return
		for face in faces:
			face.setSurfaceMaterial(material)
	
	func setMaterial(material:MaterialService.materialModel,setAllIfNoneActive:bool=false)->void:
		if setAllIfNoneActive and selectedFaces.size()==0:
			for mesh in meshes:
				for face in mesh.faces:face.setSurfaceMaterial(material)
		
		for face in selectedFaces:
			face.setSurfaceMaterial(material)
