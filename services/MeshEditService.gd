extends RefCounted
class_name MeshEditService


static var editing:editingMesh
static var editMode:MeshEditMode=MeshEditMode.FACE

static func initializeService()->void:
	signalService.addSignal(&"meshSelectionChanged")
	signalService.addSignal(&"UpdateEditingMesh")

static func setEditing(object:ObjectModel)->void:
	signalService.emitSignal.call_deferred(&"UpdateEditingMesh")
	if object==null:
		editing=null
		return
	var mesh=object.get_node_or_null("MESH_OBJECT")
	if editing and editing.meshObject==mesh:return
	editing=editingMesh.new(object,mesh)
	editing.mesh.preloadCleanFaces()

static func isEditing()->bool:return editing!=null

static func getEditMode()->MeshEditMode:return editMode


enum MeshEditMode{
	FACE=0,
	EDGE=1,
	VERTEX=2
}

class editingMesh extends Resource:
	var dataObject:ObjectModel
	var meshObject:MeshInstance3D
	var mesh:objectMeshModel:
		get:return meshObject.mesh
	
	#surface special info
	#part selections
	var selectedFaces:Array[objectMeshModel.meshFace]=[]
	var selectedEdges:Array[objectMeshModel.meshEdge]=[]
	var selectedVertices:Array[objectMeshModel.meshVertex]=[]
	
	var editing:bool=false
	var mode:MeshEditMode=MeshEditMode.FACE
	
	
	func _init(data:ObjectModel,meshInst:MeshInstance3D):
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
	func clearSelections()->void:
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
	
	func selectVertex(vertex:objectMeshModel.meshVertex,toggleSelected:bool=false)->void:
		if not mesh.vertices.has(vertex):return
		if not selectedVertices.has(vertex):selectedVertices.push_back(vertex)
		elif toggleSelected:deselectVertex(vertex)
	func selectEdge(edge:objectMeshModel.meshEdge,toggleSelected:bool=false)->void:
		if not mesh.edges.has(edge):return
		if not selectedEdges.has(edge):
			selectedEdges.push_back(edge)
			for vertex in edge.vertices:selectVertex(vertex,toggleSelected)
		elif toggleSelected:deselectEdge(edge)
	func selectFace(face:objectMeshModel.meshFace,toggleSelected:bool=false)->void:
		if not mesh.faces.has(face):return
		if not selectedFaces.has(face):
			selectedFaces.push_back(face)
			for edge in face.edges:selectEdge(edge,toggleSelected)
		elif toggleSelected:deselectFace(face)
		
	func select(meshPart,toggleSelected:bool=false)->void:
		if meshPart is objectMeshModel.meshVertex:selectVertex(meshPart,toggleSelected)
		if meshPart is objectMeshModel.meshEdge:selectEdge(meshPart,toggleSelected)
		if meshPart is objectMeshModel.meshFace:selectFace(meshPart,toggleSelected)
		if meshPart is objectMeshModel.cleanedFace:for face in meshPart.faces:selectFace(face,toggleSelected)
	
	
	
	##obtains any face and connected vertex using info from clicking on the object
	func selectByClickInfo(normal:Vector3,hitPosition:Vector3=Vector3.ZERO,keep:bool=false)->void:
		if not keep:clearSelections()
		var localNormal = normal*meshObject.global_transform.basis.get_rotation_quaternion()
		hitPosition-=meshObject.global_position
		var hitFace= mesh.getSelectedFaces(localNormal.snappedf(0.001),hitPosition)
		for face in  hitFace:selectFace(face,keep)
	
	func translateSelection(translateBy:Vector3,local:bool=true)->void:
		if selectedVertices.size()==0:return
		if local:translateBy*=meshObject.global_transform.basis.get_rotation_quaternion()
		var editingPositionIDs=[]
		for vertex in selectedVertices:
			if editingPositionIDs.has(vertex.positionID):continue
			editingPositionIDs.push_back(vertex.positionID)
		for positionID in editingPositionIDs:
			mesh.positionIDs[positionID]=(mesh.positionIDs[positionID]+translateBy)
	
	func setMaterial(material:MaterialService.materialModel,setAllIfNoneActive:bool=false)->void:
		if setAllIfNoneActive and selectedFaces.size()==0:
			for face in mesh.faces:face.setSurfaceMaterial(material)
		
		for face in selectedFaces:
			face.setSurfaceMaterial(material)
	
