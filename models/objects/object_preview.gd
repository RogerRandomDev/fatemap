extends SubViewportContainer

var obj

func loadPreview(object:Node3D)->void:
	$SubViewport.add_child(object)
	obj=object
	updateAABB.call_deferred()

func updateAABB()->void:
	var aabb=get_global_aabb(obj)
	var center=aabb.get_center()
	var aabb_size = aabb.size
	var max_dim = max(aabb_size.x,max(aabb_size.y,aabb_size.z))
	var fov = $SubViewport/Camera3D.fov
	var distance = (max_dim * 0.5 * 1.5) / tan(deg_to_rad(fov * 0.5))
	var dir = $SubViewport/Camera3D.global_transform.basis.z.normalized()
	$SubViewport/Camera3D.position=center + dir * distance

func get_global_aabb(node: Node3D) -> AABB:
	var total_aabb := AABB()
	var has_initial_bounds := false
	
	# Internal helper function to recurse through the tree
	var calculate_bounds = func(current: Node, count_mesh: Callable) -> void:
		pass # Declared above to support recursive lambdas if needed, but a secondary function is cleaner
		
	total_aabb = _build_global_aabb_recursive(node, total_aabb, has_initial_bounds)
	return total_aabb

func _build_global_aabb_recursive(current_node: Node, total_aabb: AABB, initialized: bool) -> AABB:
	var is_initialized = initialized
	
	# Only visual instances have a direct AABB bounds
	if current_node is VisualInstance3D:
		# Get local AABB and transform it to global space
		var local_aabb: AABB = current_node.get_aabb()
		var global_aabb: AABB = current_node.global_transform * local_aabb
		if not is_initialized:
			total_aabb.position = global_aabb.position
			total_aabb.size = global_aabb.size
			is_initialized = true
		else:
			total_aabb = total_aabb.merge(global_aabb)
	# Traverse children recursively
	for child in current_node.get_children():
		if child is Node3D and not child.is_queued_for_deletion():
			total_aabb = _build_global_aabb_recursive(child, total_aabb, is_initialized)
	return total_aabb

## Calculates the combined AABB relative to the parent node's own local space.
func get_local_aabb(root_node: Node3D) -> AABB:
	# Calculate the global box first, then transform it by the root node's inverse global transform
	var global_box = get_global_aabb(root_node)
	return root_node.global_transform.affine_inverse() * global_box
