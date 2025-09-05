extends RefCounted
class_name MeshEditService


static var editing:editingMesh


static func setEditing(object:ObjectModel)->void:
	var mesh=object.get_node_or_null("MESH_OBJECT")
	editing=editingMesh.new(object,mesh)



enum MeshEditMode{
	FACE=0,
	VERTEX=1
}

class editingMesh extends Resource:
	var dataObject:ObjectModel
	var meshObject:MeshInstance3D
	var mesh:objectMeshModel:
		get:return meshObject.mesh
	
	#surface special info
	#part selections
	var selectedFaces:Array[objectMeshModel.meshFace]=[]
	var selectedVertices:PackedInt32Array=[]
	
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
		selectedVertices=[]
	
	
	##TODO: make use of event_position to further filter to only faces intersecting the mouse
	##obtains any face and connected vertex with a given normal
	func select(normal:Vector3,hitPosition:Vector3=Vector3.ZERO,keep:bool=false)->void:
		if not keep:clearSelections()
		var localNormal = normal*meshObject.global_transform.basis.get_rotation_quaternion()
		selectedFaces.append_array(mesh.getSelectedFaces(localNormal,hitPosition))
	
	func translateSelection(translateBy:Vector3,local:bool=true)->void:
		if selectedFaces.size()==0:return
		if local:translateBy*=Quaternion(selectedFaces[0].getFaceNormal(),Vector3.UP)
		var weldedChanges:PackedVector3Array=[]
		for face in selectedFaces:
			weldedChanges.append_array(face.translateBy(translateBy))
		#make it an array of only unique positions
		var removedChanges:int=0
		for index in len(weldedChanges):
			if weldedChanges.find(weldedChanges[index-removedChanges])!=index-removedChanges:
				weldedChanges.remove_at(index-removedChanges)
				removedChanges+=1
		for face in mesh.faces.filter(func(f):return not selectedFaces.has(f)):
			for weldedChange in weldedChanges:
				face.weldedTranslate(weldedChange,weldedChange+translateBy)
	
	func setMaterial(material:MaterialService.materialModel)->void:
		for face in selectedFaces:
			face.setSurfaceMaterial(material)
	
