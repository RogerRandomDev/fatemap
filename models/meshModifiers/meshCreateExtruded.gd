extends Node
class_name meshCreateExtruded



static func createExtrudedFromSelected(extrudeLength:float=0.25)->Array[PhysicalObjectModel]:
	var extrudedObjects:Array[PhysicalObjectModel]=[]
	var selectedCleanFaces:Dictionary={}
	for face in MeshEditService.editing.selectedFaces:
		selectedCleanFaces[face._mesh.getCleanFaceForFace(face)]=null
	for face:objectMeshModel.cleanedFace in selectedCleanFaces.keys():
		var newExtruded=PhysicalObjectModel.new()
		newExtruded.objectData=ObjectPhysicalDataResource.new(face._mesh.ownerInstance.get_parent().objectData.inheritedData)
		var extrudedMesh=objectMeshModel.new()
		extrudedMesh.globalTransform=MeshEditService.editing.mesh.globalTransform
		newExtruded.objectData.mesh=extrudedMesh
		var offset=face.normal*extrudeLength
		var face_material=face.faces[0].surfaceMaterial
		#build top+bottom of the extruded mesh
		var _modified_faces_set=face.faces.map(func(f:objectMeshModel.meshFace):
			var f_vertices_a=f.vertices.map(func(v):return v.position)
			var f_vertices_b=f.vertices.map(func(v):return v.position+offset)
			f_vertices_a.reverse()
			var f_uvs=f.vertexUVS
			return [objectMeshModel.meshFace.new(extrudedMesh,f_vertices_a,f_uvs,face_material),objectMeshModel.meshFace.new(extrudedMesh,f_vertices_b,f_uvs,face_material)])
		#use the edges to create the faces connecting the top and bottom
		var faceEdges = face._mesh.getCleanEdgesForFace(face)
		for edge:objectMeshModel.cleanedEdge in faceEdges:
			var a:Vector3 = edge.positions[0]
			var b:Vector3 = edge.positions[1]
			var c:Vector3 = b + offset
			var d:Vector3 = a + offset
			var f_vertices_a:PackedVector3Array=[a,b,c]
			var f_vertices_b:PackedVector3Array=[c,d,a]
			var f_uvs:PackedVector2Array=[];f_uvs.resize(3)
			var side_normal = (b-a).normalized().cross(face.normal).normalized()
			var outward:Vector3 = (edge.getCenter() - face.getCenter()).normalized()
			if side_normal.dot(outward) > 0.0:
				f_vertices_a.reverse()
				f_vertices_b.reverse()
			objectMeshModel.meshFace.new(extrudedMesh,f_vertices_b,f_uvs,face_material)
			objectMeshModel.meshFace.new(extrudedMesh,f_vertices_a,f_uvs,face_material)
		newExtruded.transform=MeshEditService.editing.dataObject.global_transform
		extrudedMesh.rebuild()
		extrudedMesh.initializeFaces()
		for extruded_face in extrudedMesh.faces:
			extruded_face.setSurfaceMaterial(face_material)
		
		
		extrudedObjects.push_back(newExtruded)
	
	
	return extrudedObjects
