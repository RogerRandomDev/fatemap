@tool
extends RefCounted
class_name PhysicalObjectService




static func buildMesh(object:ObjectPhysicalDataResource,instance:MeshInstance3D=null)->Mesh:
	var  mesh=object.mesh
	if instance:instance.mesh=mesh
	return mesh
	
