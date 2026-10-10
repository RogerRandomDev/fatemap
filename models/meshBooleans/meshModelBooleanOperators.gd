
extends RefCounted
class_name MeshBoolean

enum Operation {
	UNION,
	DIFFERENCE,
	INTERSECTION
}

const EPSILON: float = 0.01


# ===========================================================================
# Internal geometry types
# ===========================================================================

class Vertex:
	var position: Vector3
	var uv: Vector2

	func _init(p_position: Vector3, p_uv: Vector2 = Vector2.ZERO) -> void:
		position = p_position
		uv = p_uv

	func interpolate(other: Vertex, t: float) -> Vertex:
		return Vertex.new(
			position.lerp(other.position, t),
			uv.lerp(other.uv, t)
		)


class Polygon:
	var vertices: Array = []
	var material
	var normal: Vector3 = Vector3.ZERO
	var w: float = 0.0

	func _init(p_vertices: Array, p_material = null) -> void:
		vertices = p_vertices.duplicate()
		material = p_material
		_calculate_BooleanPlane()

	func _calculate_BooleanPlane() -> void:
		normal = Vector3.ZERO
		w = 0.0

		if vertices.size() < 3:
			return

		var origin: Vector3 = vertices[0].position

		for i in range(1, vertices.size() - 1):
			var a: Vector3 = vertices[i].position - origin
			var b: Vector3 = vertices[i + 1].position - origin
			var cross: Vector3 = a.cross(b)

			if cross.length_squared() > 0.0000000001:
				normal = cross.normalized()
				w = normal.dot(origin)
				return

	func is_valid() -> bool:
		return (
			vertices.size() >= 3
			and normal.length_squared() > 0.5
		)

	func flip() -> void:
		vertices.reverse()
		normal = -normal
		w = -w


class BooleanPlane:
	const COPLANAR := 0
	const FRONT := 1
	const BACK := 2
	const SPANNING := 3

	var normal: Vector3
	var w: float

	func _init(p_normal: Vector3, p_w: float) -> void:
		normal = p_normal
		w = p_w

	func flip() -> void:
		normal = -normal
		w = -w

	func split_polygon(
		polygon: Polygon,
		coplanar_front: Array,
		coplanar_back: Array,
		front: Array,
		back: Array
	) -> void:
		var polygon_type := COPLANAR
		var vertex_types: Array[int] = []

		for vertex in polygon.vertices:
			var distance: float = normal.dot(vertex.position) - w
			var vertex_type := COPLANAR

			if distance < -MeshBoolean.EPSILON:
				vertex_type = BACK
			elif distance > MeshBoolean.EPSILON:
				vertex_type = FRONT

			polygon_type |= vertex_type
			vertex_types.append(vertex_type)

		match polygon_type:
			COPLANAR:
				if normal.dot(polygon.normal) >= 0.0:
					coplanar_front.append(polygon)
				else:
					coplanar_back.append(polygon)

			FRONT:
				front.append(polygon)

			BACK:
				back.append(polygon)

			SPANNING:
				var front_vertices: Array = []
				var back_vertices: Array = []
				var count: int = polygon.vertices.size()

				for i in range(count):
					var j: int = (i + 1) % count

					var vi: Vertex = polygon.vertices[i]
					var vj: Vertex = polygon.vertices[j]

					var ti: int = vertex_types[i]
					var tj: int = vertex_types[j]

					if ti != BACK:
						front_vertices.append(vi)

					if ti != FRONT:
						back_vertices.append(vi)

					if (ti | tj) == SPANNING:
						var direction: Vector3 = vj.position - vi.position
						var denominator: float = normal.dot(direction)

						if absf(denominator) <= MeshBoolean.EPSILON:
							continue

						var t: float = (
							w - normal.dot(vi.position)
						) / denominator

						var split_vertex: Vertex = vi.interpolate(
							vj,
							clampf(t, 0.0, 1.0)
						)

						front_vertices.append(split_vertex)
						back_vertices.append(
							Vertex.new(
								split_vertex.position,
								split_vertex.uv
							)
						)

				var front_polygon := Polygon.new(
					front_vertices,
					polygon.material
				)

				var back_polygon := Polygon.new(
					back_vertices,
					polygon.material
				)

				if front_polygon.is_valid():
					front.append(front_polygon)

				if back_polygon.is_valid():
					back.append(back_polygon)


class BSPNode:
	var plane: BooleanPlane = null
	var polygons: Array = []
	var front: BSPNode = null
	var back: BSPNode = null

	func _init(p_polygons: Array = []) -> void:
		if not p_polygons.is_empty():
			build(p_polygons)

	func build(input_polygons: Array) -> void:
		if input_polygons.is_empty():
			return

		if plane == null:
			var first: Polygon = input_polygons[0]
			plane = BooleanPlane.new(first.normal, first.w)

		var front_polygons: Array = []
		var back_polygons: Array = []

		for polygon in input_polygons:
			plane.split_polygon(
				polygon,
				polygons,
				polygons,
				front_polygons,
				back_polygons
			)

		if not front_polygons.is_empty():
			if front == null:
				front = BSPNode.new()
			front.build(front_polygons)

		if not back_polygons.is_empty():
			if back == null:
				back = BSPNode.new()
			back.build(back_polygons)

	func all_polygons() -> Array:
		var result: Array = polygons.duplicate()

		if front != null:
			result.append_array(front.all_polygons())

		if back != null:
			result.append_array(back.all_polygons())

		return result

	func invert() -> void:
		for polygon in polygons:
			polygon.flip()

		if plane != null:
			plane.flip()

		if front != null:
			front.invert()

		if back != null:
			back.invert()

		var temp: BSPNode = front
		front = back
		back = temp

	func clip_polygons(input_polygons: Array) -> Array:
		if plane == null:
			return input_polygons.duplicate()

		var front_polygons: Array = []
		var back_polygons: Array = []

		for polygon in input_polygons:
			plane.split_polygon(
				polygon,
				front_polygons,
				back_polygons,
				front_polygons,
				back_polygons
			)

		if front != null:
			front_polygons = front.clip_polygons(front_polygons)

		if back != null:
			back_polygons = back.clip_polygons(back_polygons)
		else:
			back_polygons.clear()

		front_polygons.append_array(back_polygons)
		return front_polygons

	func clip_to(other: BSPNode) -> void:
		polygons = other.clip_polygons(polygons)

		if front != null:
			front.clip_to(other)

		if back != null:
			back.clip_to(other)


# ===========================================================================
# Public API
# ===========================================================================

## Returns one objectMeshModel per connected component.
## All output vertices use model A's local coordinate space.
static func execute(
	obj_a: ObjectModel,
	obj_b: ObjectModel,
	operation: Operation = Operation.DIFFERENCE
) -> Array:
	var empty_results: Array[objectMeshModel] = []
	
	if obj_a == null or obj_b == null:
		push_error("MeshBoolean: Both objects are required.")
		return empty_results

	if obj_a.objectDisplay == null or obj_b.objectDisplay == null:
		push_error("MeshBoolean: Both objects need an objectDisplay.")
		return empty_results

	var model_a: objectMeshModel = obj_a.objectDisplay.mesh
	var model_b: objectMeshModel = obj_b.objectDisplay.mesh

	if model_a == null or model_b == null:
		push_error("MeshBoolean: Both meshes are required.")
		return empty_results

	if (
		operation != Operation.UNION
		and operation != Operation.DIFFERENCE
		and operation != Operation.INTERSECTION
	):
		push_error("MeshBoolean: Unknown operation.")
		return empty_results

	var transform_a: Transform3D = _get_model_transform(model_a)
	var transform_b: Transform3D = _get_model_transform(model_b)

	if is_zero_approx(transform_a.basis.determinant()):
		push_error("MeshBoolean: Model A has a non-invertible transform.")
		return empty_results

	if is_zero_approx(transform_b.basis.determinant()):
		push_error("MeshBoolean: Model B has a non-invertible transform.")
		return empty_results

	var b_to_a: Transform3D = (
		transform_a.affine_inverse() * transform_b
	)

	var polygons_a: Array = _model_to_polygons(
		model_a,
		Transform3D.IDENTITY
	)

	var polygons_b: Array = _model_to_polygons(
		model_b,
		b_to_a
	)

	if polygons_a.is_empty():
		if operation == Operation.UNION:
			return _polygons_to_models(polygons_b, transform_a)
		return empty_results

	if polygons_b.is_empty():
		if operation != Operation.INTERSECTION:
			return _polygons_to_models(polygons_a, transform_a)
		return empty_results

	var a := BSPNode.new(polygons_a)
	var b := BSPNode.new(polygons_b)

	match operation:
		Operation.UNION:
			a.clip_to(b)
			b.clip_to(a)
			b.invert()
			b.clip_to(a)
			b.invert()
			a.build(b.all_polygons())

		Operation.DIFFERENCE:
			a.invert()
			a.clip_to(b)
			b.clip_to(a)
			b.invert()
			b.clip_to(a)
			b.invert()
			a.build(b.all_polygons())
			#a.invert()

		Operation.INTERSECTION:
			a.invert()
			b.clip_to(a)
			b.invert()
			a.clip_to(b)
			b.clip_to(a)
			a.build(b.all_polygons())
			a.invert()

	return _decompose_component_to_models(_polygons_to_models(a.all_polygons(), transform_a))


# ===========================================================================
# Input conversion
# ===========================================================================

static func _get_model_transform(
	model: objectMeshModel
) -> Transform3D:
	if "ownerInstance" in model:
		var owner = model.get("ownerInstance")

		if is_instance_valid(owner) and owner is Node3D:
			return owner.global_transform

	if "globalTransform" in model:
		return model.get("globalTransform")

	return Transform3D.IDENTITY


static func _model_to_polygons(
	model: objectMeshModel,
	vertex_transform: Transform3D
) -> Array:
	var result: Array = []

	for face in model.faces:
		if face.vertices.size() < 3:
			continue

		var vertices: Array = []

		for vertex in face.vertices:
			vertices.append(
				Vertex.new(
					vertex_transform * vertex.position,
					vertex.uv
				)
			)

		var polygon := Polygon.new(
			vertices,
			face.surfaceMaterial
		)

		if not polygon.is_valid():
			continue

		if vertex_transform.basis.determinant() < 0.0:
			polygon.flip()

		result.append(polygon)

	return result


# ===========================================================================
# Output conversion and component separation
# ===========================================================================


static func _polygons_to_models(
	polygons: Array,
	result_transform: Transform3D
) -> Array:
	var results: Array = []
	var triangles: Array = []

	var tolerance: float = _get_weld_tolerance(polygons)
	var buckets: Dictionary = {}
	var welded_positions: Array[Vector3] = []

	# Triangulate the BSP polygons and weld coincident vertices.
	for polygon in polygons:
		if polygon.vertices.size() < 3:
			continue

		var first: Vertex = polygon.vertices[0]

		for i in range(1, polygon.vertices.size() - 1):
			var v1: Vertex = polygon.vertices[i]
			var v2: Vertex = polygon.vertices[i + 1]

			var points: Array[Vector3] = [
				first.position,
				v1.position,
				v2.position
			]

			var uvs: Array[Vector2] = [
				first.uv,
				v1.uv,
				v2.uv
			]

			var ids: Array[int] = []

			for point in points:
				ids.append(
					_get_vertex_id(
						point,
						tolerance,
						buckets,
						welded_positions
					)
				)

			if (
				ids[0] == ids[1]
				or ids[1] == ids[2]
				or ids[2] == ids[0]
			):
				continue

			var a: Vector3 = welded_positions[ids[0]]
			var b: Vector3 = welded_positions[ids[1]]
			var c: Vector3 = welded_positions[ids[2]]

			if (b - a).cross(c - a).length_squared() <= tolerance ** 4:
				continue

			triangles.append({
				"p":[first.position,v1.position,v2.position],
				"ids": ids,
				"uv": uvs,
				"material": polygon.material
			})

	# Repair T-junctions before constructing connectivity.
	triangles = _repair_t_junctions(
		triangles,
		welded_positions,
		tolerance
	)

	if triangles.is_empty():
		return results

	# Map each undirected edge to its incident triangles.
	var edge_triangles: Dictionary = {}

	for triangle_index in range(triangles.size()):
		var ids: Array = triangles[triangle_index]["ids"]

		for edge_index in range(3):
			var id_a: int = ids[edge_index]
			var id_b: int = ids[(edge_index + 1) % 3]

			var edge := Vector2i(
				mini(id_a, id_b),
				maxi(id_a, id_b)
			)

			if not edge_triangles.has(edge):
				edge_triangles[edge] = []

			edge_triangles[edge].append(triangle_index)

	# Build the adjacency graph.
	var adjacency: Array = []

	for i in range(triangles.size()):
		adjacency.append([])

	for edge in edge_triangles:
		var incident: Array = edge_triangles[edge]

		if incident.size() < 2:
			continue

		for i in range(incident.size()):
			for j in range(i + 1, incident.size()):
				var ta: int = incident[i]
				var tb: int = incident[j]

				adjacency[ta].append(tb)
				adjacency[tb].append(ta)

	# Find each connected component.
	var visited := PackedByteArray()
	visited.resize(triangles.size())
	visited.fill(0)

	for start in range(triangles.size()):
		if visited[start] != 0:
			continue

		var component: Array[int] = []
		var queue: Array[int] = [start]
		var queue_index: int = 0

		visited[start] = 1

		while queue_index < queue.size():
			var current: int = queue[queue_index]
			queue_index += 1
			component.append(current)

			for neighbor in adjacency[current]:
				if visited[neighbor] != 0:
					continue

				visited[neighbor] = 1
				queue.append(neighbor)

		results.append_array(triangles)

	return results



# ===========================================================================
# Vertex welding
# ===========================================================================

static func _get_weld_tolerance(polygons: Array) -> float:
	var bounds := AABB()
	var has_bounds := false

	for polygon in polygons:
		for vertex in polygon.vertices:
			if not has_bounds:
				bounds = AABB(vertex.position, Vector3.ZERO)
				has_bounds = true
			else:
				bounds = bounds.expand(vertex.position)

	if not has_bounds:
		return EPSILON * 2.0

	var scale: float = maxf(
		bounds.size.x,
		maxf(bounds.size.y, bounds.size.z)
	)

	return maxf(EPSILON * 2.0, scale * 0.000001)


static func _get_vertex_id(
	position: Vector3,
	tolerance: float,
	buckets: Dictionary,
	welded_positions: Array[Vector3]
) -> int:
	var cell := Vector3i(
		floori(position.x / tolerance),
		floori(position.y / tolerance),
		floori(position.z / tolerance)
	)

	var tolerance_squared: float = tolerance * tolerance

	# Search adjacent cells to avoid missing close vertices on cell borders.
	for x in range(-1, 2):
		for y in range(-1, 2):
			for z in range(-1, 2):
				var neighbor_cell := cell + Vector3i(x, y, z)

				if not buckets.has(neighbor_cell):
					continue

				for vertex_id in buckets[neighbor_cell]:
					if (
						welded_positions[vertex_id]
						.distance_squared_to(position)
						<= tolerance_squared
					):
						return vertex_id

	var new_id: int = welded_positions.size()
	welded_positions.append(position)

	if not buckets.has(cell):
		buckets[cell] = []

	buckets[cell].append(new_id)

	return new_id

static func _repair_t_junctions(
	triangles: Array,
	welded_positions: Array[Vector3],
	tolerance: float
) -> Array:
	var repaired: Array = []
	var original_vertex_count: int = welded_positions.size()
	var tolerance_squared: float = tolerance * tolerance

	for triangle_data in triangles:
		var ids: Array = triangle_data["ids"]
		var uvs: Array = triangle_data["uv"]

		var boundary: Array = []

		# Gather every existing vertex lying on each triangle edge.
		for edge_index in range(3):
			var next_index: int = (edge_index + 1) % 3

			var start_id: int = ids[edge_index]
			var end_id: int = ids[next_index]

			var start: Vector3 = welded_positions[start_id]
			var finish: Vector3 = welded_positions[end_id]
			var edge: Vector3 = finish - start
			var edge_length_squared: float = edge.length_squared()

			if edge_length_squared <= tolerance_squared:
				continue

			boundary.append({
				"id": start_id,
				"uv": uvs[edge_index]
			})

			var points_on_edge: Array = []

			var edge_min := Vector3(
				minf(start.x, finish.x) - tolerance,
				minf(start.y, finish.y) - tolerance,
				minf(start.z, finish.z) - tolerance
			)

			var edge_max := Vector3(
				maxf(start.x, finish.x) + tolerance,
				maxf(start.y, finish.y) + tolerance,
				maxf(start.z, finish.z) + tolerance
			)

			for candidate_id in range(original_vertex_count):
				if candidate_id == start_id or candidate_id == end_id:
					continue

				var point: Vector3 = welded_positions[candidate_id]

				# Quickly reject points outside the edge's bounding box.
				if (
					point.x < edge_min.x or point.x > edge_max.x
					or point.y < edge_min.y or point.y > edge_max.y
					or point.z < edge_min.z or point.z > edge_max.z
				):
					continue

				var t: float = (point - start).dot(edge) / edge_length_squared

				# Only consider points strictly inside the edge.
				var parameter_tolerance: float = tolerance / sqrt(edge_length_squared)

				if t <= parameter_tolerance or t >= 1.0 - parameter_tolerance:
					continue

				var projected: Vector3 = start + edge * t

				if projected.distance_squared_to(point) > tolerance_squared:
					continue

				points_on_edge.append({
					"id": candidate_id,
					"t": t,
					"uv": (uvs[edge_index] as Vector2).lerp(
						uvs[next_index],
						t
					)
				})

			points_on_edge.sort_custom(
				func(a: Dictionary, b: Dictionary) -> bool:
					return a["t"] < b["t"]
			)

			for point_data in points_on_edge:
				boundary.append({
					"id": point_data["id"],
					"uv": point_data["uv"]
				})

		# Remove consecutive duplicate vertex IDs from the boundary.
		var clean_boundary: Array = []

		for entry in boundary:
			if clean_boundary.is_empty():
				clean_boundary.append(entry)
			elif clean_boundary[-1]["id"] != entry["id"]:
				clean_boundary.append(entry)

		if clean_boundary.size() > 1:
			if clean_boundary[0]["id"] == clean_boundary[-1]["id"]:
				clean_boundary.pop_back()

		if clean_boundary.size() < 3:
			continue

		# Create an interior vertex and fan-triangulate the repaired boundary.
		var p0: Vector3 = welded_positions[ids[0]]
		var p1: Vector3 = welded_positions[ids[1]]
		var p2: Vector3 = welded_positions[ids[2]]

		var center: Vector3 = (p0 + p1 + p2) / 3.0
		var center_uv: Vector2 = (
			(uvs[0] as Vector2)
			+ (uvs[1] as Vector2)
			+ (uvs[2] as Vector2)
		) / 3.0

		var center_id: int = welded_positions.size()
		welded_positions.append(center)

		for i in range(clean_boundary.size()):
			var j: int = (i + 1) % clean_boundary.size()

			var a: Dictionary = clean_boundary[i]
			var b: Dictionary = clean_boundary[j]

			var id_a: int = a["id"]
			var id_b: int = b["id"]

			if id_a == id_b:
				continue

			var pa: Vector3 = welded_positions[id_a]
			var pb: Vector3 = welded_positions[id_b]

			if (pa - center).cross(pb - center).length_squared() <= tolerance_squared * tolerance_squared:
				continue

			repaired.append({
				"ids": [center_id, id_a, id_b],
				"p":[center,pa,pb],
				"uv": [center_uv, a["uv"], b["uv"]],
				"material": triangle_data["material"]
			})

	return repaired
const DECOMPOSITION_EPSILON: float = 0.0005


# Each triangle is:
# {
#     "p": [Vector3, Vector3, Vector3],
#     "uv": [Vector2, Vector2, Vector2],
#     "material": Material
# }


static func _decompose_component(component: Array) -> Array:
	var result: Array = []
	_decompose_recursive(component, result, 0)
	return result


const MAX_DECOMPOSITION_DEPTH: int = 12
const MAX_VERTICES_PER_CONVEX_PART: int = 999

const MIN_TRIANGLES_PER_PART: int = 8
const MIN_PART_VOLUME_RATIO: float = 0.04
const MIN_CONVEXITY_IMPROVEMENT: float = 0.25
const CUT_CANDIDATES_PER_AXIS: int = 5


static func _decompose_recursive(
		triangles: Array,
		result: Array,
		depth: int
) -> void:
	if triangles.is_empty():
		return

	var vertices := _collect_unique_vertices(triangles)

	# Never split an already convex piece solely because it is large.
	if _is_convex_triangle_mesh(triangles, vertices):
		result.append(triangles)
		return

	if depth >= MAX_DECOMPOSITION_DEPTH:
		result.append(triangles)
		return

	if triangles.size() < MIN_TRIANGLES_PER_PART * 2:
		result.append(triangles)
		return

	var bounds := _get_triangle_bounds(triangles)
	var best_cut := _find_best_cut(triangles, bounds)

	if best_cut.is_empty():
		result.append(triangles)
		return

	var front: Array = best_cut["front"]
	var back: Array = best_cut["back"]

	_decompose_recursive(front, result, depth + 1)
	_decompose_recursive(back, result, depth + 1)


static func _find_best_cut(triangles: Array, bounds: AABB) -> Dictionary:
	var size := bounds.size
	var axes: Array[int] = [0, 1, 2]

	# Try the largest axis first.
	axes.sort_custom(func(a: int, b: int) -> bool:
		return _axis_value(size, a) > _axis_value(size, b)
	)

	var total_volume := maxf(
		size.x * size.y * size.z,
		0.000001
	)

	var best_score := INF
	var best_result: Dictionary = {}

	for axis in axes:
		var minimum := _axis_value(bounds.position, axis)
		var maximum := _axis_value(bounds.end, axis)
		var extent := maximum - minimum

		if extent <= DECOMPOSITION_EPSILON * 4.0:
			continue

		# Avoid cuts near either extreme of the object.
		for candidate_index in range(CUT_CANDIDATES_PER_AXIS):
			var fraction := float(candidate_index + 1) / float(
				CUT_CANDIDATES_PER_AXIS + 1
			)
			var position := lerpf(minimum, maximum, fraction)

			var front: Array = []
			var back: Array = []

			_split_triangles_with_caps(
				triangles,
				axis,
				position,
				front,
				back
			)

			if front.is_empty() or back.is_empty():
				continue

			if front.size() < MIN_TRIANGLES_PER_PART:
				continue
			if back.size() < MIN_TRIANGLES_PER_PART:
				continue

			var front_bounds := _get_triangle_bounds(front)
			var back_bounds := _get_triangle_bounds(back)

			var front_volume := _bounds_volume(front_bounds)
			var back_volume := _bounds_volume(back_bounds)

			if front_volume / total_volume < MIN_PART_VOLUME_RATIO:
				continue
			if back_volume / total_volume < MIN_PART_VOLUME_RATIO:
				continue

			var front_vertices := _collect_unique_vertices(front)
			var back_vertices := _collect_unique_vertices(back)

			var front_convexity := _convexity_error(front, front_vertices)
			var back_convexity := _convexity_error(back, back_vertices)

			var parent_convexity := _convexity_error(
				triangles,
				_collect_unique_vertices(triangles)
			)

			var child_error := (
				front_convexity * front.size()
				+ back_convexity * back.size()
			) / float(front.size() + back.size())

			var improvement := parent_convexity - child_error

			if improvement < MIN_CONVEXITY_IMPROVEMENT:
				continue

			# Penalize unbalanced pieces and cuts that create
			# excessive surface area.
			var balance_penalty := absf(
				float(front.size() - back.size())
				/ float(front.size() + back.size())
			)

			var score := (
				child_error
				+ balance_penalty * parent_convexity * 0.25
			)

			if score < best_score:
				best_score = score
				best_result = {
					"front": front,
					"back": back
				}

	return best_result


static func _bounds_volume(bounds: AABB) -> float:
	return (
		absf(bounds.size.x)
		* absf(bounds.size.y)
		* absf(bounds.size.z)
	)


static func _convexity_error(
		triangles: Array,
		vertices: Array[Vector3]
) -> float:
	if triangles.is_empty() or vertices.is_empty():
		return INF

	var center := Vector3.ZERO
	for p in vertices:
		center += p
	center /= float(vertices.size())

	var total_error := 0.0
	var face_count := 0

	for triangle in triangles:
		var points: Array = triangle["p"]
		var a: Vector3 = points[0]
		var b: Vector3 = points[1]
		var c: Vector3 = points[2]

		var normal := (b - a).cross(c - a)
		if normal.length_squared() < 0.00000001:
			continue

		normal = normal.normalized()

		# Orient the plane outward relative to the piece center.
		if normal.dot(center - a) > 0.0:
			normal = -normal

		var worst_protrusion := 0.0
		for p in vertices:
			worst_protrusion = maxf(
				worst_protrusion,
				normal.dot(p - a)
			)

		total_error += maxf(0.0, worst_protrusion)
		face_count += 1

	if face_count == 0:
		return INF

	return total_error / float(face_count)


static func _axis_value(v: Vector3, axis: int) -> float:
	match axis:
		0:
			return v.x
		1:
			return v.y
		_:
			return v.z


static func _set_axis_value(v: Vector3, axis: int, value: float) -> Vector3:
	match axis:
		0:
			v.x = value
		1:
			v.y = value
		_:
			v.z = value
	return v


static func _get_triangle_bounds(triangles: Array) -> AABB:
	var bounds := AABB()
	var initialized := false

	for triangle in triangles:
		for p in triangle["p"]:
			if not initialized:
				bounds = AABB(p, Vector3.ZERO)
				initialized = true
			else:
				bounds = bounds.expand(p)

	return bounds


static func _collect_unique_vertices(triangles: Array) -> Array[Vector3]:
	var result: Array[Vector3] = []
	var tolerance_squared := DECOMPOSITION_EPSILON * DECOMPOSITION_EPSILON

	for triangle in triangles:
		for p in triangle["p"]:
			var found := false

			for existing in result:
				if existing.distance_squared_to(p) <= tolerance_squared:
					found = true
					break

			if not found:
				result.append(p)

	return result


static func _is_convex_triangle_mesh(
		triangles: Array,
		vertices: Array[Vector3]
) -> bool:
	if triangles.size() < 4 or vertices.size() < 4:
		return false

	var center := Vector3.ZERO
	for p in vertices:
		center += p
	center /= float(vertices.size())

	for triangle in triangles:
		var points: Array = triangle["p"]
		var a: Vector3 = points[0]
		var b: Vector3 = points[1]
		var c: Vector3 = points[2]

		var normal := (b - a).cross(c - a)
		if normal.length_squared() < 0.00000001:
			continue

		normal = normal.normalized()

		# Orient the face normal away from the mesh center.
		if normal.dot(center - a) > 0.0:
			normal = -normal

		# A convex mesh must have every vertex on or behind
		# every outward-facing face plane.
		for p in vertices:
			if normal.dot(p - a) > DECOMPOSITION_EPSILON:
				return false

	return true


static func _split_by_triangle_count(triangles: Array) -> Array:
	var first: Array = []
	var second: Array = []
	var midpoint := int(triangles.size() / 2)

	for i in range(triangles.size()):
		if i < midpoint:
			first.append(triangles[i])
		else:
			second.append(triangles[i])

	return [first, second]


static func _split_triangles_with_caps(
		triangles: Array,
		axis: int,
		split_position: float,
		front: Array,
		back: Array
) -> void:
	var cut_segments: Array = []
	var epsilon := DECOMPOSITION_EPSILON

	for triangle in triangles:
		var points: Array = triangle["p"]
		var uvs: Array = triangle["uv"]
		var material = triangle["material"]

		var min_value := INF
		var max_value := -INF

		for p: Vector3 in points:
			var value := _axis_value(p, axis)
			min_value = minf(min_value, value)
			max_value = maxf(max_value, value)

		if min_value >= split_position - epsilon:
			front.append(triangle)
			continue

		if max_value <= split_position + epsilon:
			back.append(triangle)
			continue

		var front_polygon := _clip_triangle_to_axis_plane(
			points, uvs, axis, split_position, true
		)
		var back_polygon := _clip_triangle_to_axis_plane(
			points, uvs, axis, split_position, false
		)

		_append_polygon_triangulation(front_polygon, material, front)
		_append_polygon_triangulation(back_polygon, material, back)

		var intersections: Array[Vector3] = []

		for i in range(3):
			var j := (i + 1) % 3
			var a: Vector3 = points[i]
			var b: Vector3 = points[j]
			var da := _axis_value(a, axis) - split_position
			var db := _axis_value(b, axis) - split_position

			if (da < -epsilon and db > epsilon) or (
				da > epsilon and db < -epsilon
			):
				var t := da / (da - db)
				var intersection := a.lerp(b, t)
				intersection = _set_axis_value(
					intersection, axis, split_position
				)
				_add_unique_position(intersections, intersection)

		if intersections.size() == 2:
			cut_segments.append([
				intersections[0],
				intersections[1]
			])

	# Close the cut surface on both resulting pieces.
	var loops := _segments_to_loops(cut_segments)

	for loop in loops:
		if loop.size() < 3:
			continue

		# The positive-side piece needs a cap facing toward
		# the negative side; the negative-side piece needs
		# the opposite-facing cap.
		_triangulate_cap(loop, axis, false, front)
		_triangulate_cap(loop, axis, true, back)


static func _clip_triangle_to_axis_plane(
		points: Array,
		uvs: Array,
		axis: int,
		split_position: float,
		keep_front: bool
) -> Array:
	var output: Array = []
	var epsilon := DECOMPOSITION_EPSILON

	for i in range(points.size()):
		var j := (i + 1) % points.size()

		var a: Vector3 = points[i]
		var b: Vector3 = points[j]
		var uv_a: Vector2 = uvs[i]
		var uv_b: Vector2 = uvs[j]

		var da := _axis_value(a, axis) - split_position
		var db := _axis_value(b, axis) - split_position

		var inside_a := da >= -epsilon if keep_front else da <= epsilon
		var inside_b := db >= -epsilon if keep_front else db <= epsilon

		if inside_a:
			output.append({"p": a, "uv": uv_a})

		if inside_a != inside_b:
			var denominator := da - db
			if absf(denominator) > 0.0000001:
				var t := da / denominator
				var p := a.lerp(b, t)
				p = _set_axis_value(p, axis, split_position)
				var uv := uv_a.lerp(uv_b, t)
				output.append({"p": p, "uv": uv})

	return output


static func _append_polygon_triangulation(
		polygon: Array,
		material,
		output: Array
) -> void:
	if polygon.size() < 3:
		return

	for i in range(1, polygon.size() - 1):
		var p0: Dictionary = polygon[0]
		var p1: Dictionary = polygon[i]
		var p2: Dictionary = polygon[i + 1]

		output.append({
			"p": [p0["p"], p1["p"], p2["p"]],
			"uv": [p0["uv"], p1["uv"], p2["uv"]],
			"material": material
		})


static func _add_unique_position(points: Array, p: Vector3) -> void:
	for existing: Vector3 in points:
		if existing.distance_squared_to(p) <= (
			DECOMPOSITION_EPSILON * DECOMPOSITION_EPSILON
		):
			return
	points.append(p)


static func _segments_to_loops(segments: Array) -> Array:
	var remaining: Array = segments.duplicate(true)
	var loops: Array = []
	var tolerance_squared := (
		DECOMPOSITION_EPSILON * DECOMPOSITION_EPSILON * 16.0
	)

	while not remaining.is_empty():
		var segment: Array = remaining.pop_back()
		var loop: Array[Vector3] = [segment[0], segment[1]]
		var closed := false

		for _iteration in range(remaining.size() + 2):
			var tail: Vector3 = loop.back()
			var match_index := -1
			var match_point := Vector3.ZERO

			for i in range(remaining.size()):
				var candidate: Array = remaining[i]

				if tail.distance_squared_to(candidate[0]) <= tolerance_squared:
					match_index = i
					match_point = candidate[1]
					break

				if tail.distance_squared_to(candidate[1]) <= tolerance_squared:
					match_index = i
					match_point = candidate[0]
					break

			if match_index < 0:
				break

			remaining.remove_at(match_index)

			if match_point.distance_squared_to(loop[0]) <= tolerance_squared:
				closed = true
				break

			loop.append(match_point)

		if closed and loop.size() >= 3:
			loops.append(loop)

	return loops


static func _triangulate_cap(
		loop: Array,
		axis: int,
		outward_positive: bool,
		output: Array
) -> void:
	var polygon: Array[Vector3] = []
	for p: Vector3 in loop:
		polygon.append(p)

	# Remove consecutive duplicate vertices.
	for i in range(polygon.size() - 1, 0, -1):
		if polygon[i].distance_squared_to(polygon[i - 1]) <= (
			DECOMPOSITION_EPSILON * DECOMPOSITION_EPSILON
		):
			polygon.remove_at(i)

	if polygon.size() < 3:
		return

	var normal := Vector3.RIGHT if axis == 0 else (
		Vector3.UP if axis == 1 else Vector3.BACK
	)
	if not outward_positive:
		normal = -normal

	var material = null
	var remaining: Array[int] = []
	for i in range(polygon.size()):
		remaining.append(i)

	var projected: Array[Vector2] = []
	for p in polygon:
		match axis:
			0:
				projected.append(Vector2(p.y, p.z))
			1:
				projected.append(Vector2(p.x, p.z))
			_:
				projected.append(Vector2(p.x, p.y))

	var signed_area := 0.0
	for i in range(projected.size()):
		var j := (i + 1) % projected.size()
		signed_area += (
			projected[i].x * projected[j].y
			- projected[j].x * projected[i].y
		)

	if absf(signed_area) < 0.0000001:
		return

	var ccw := signed_area > 0.0
	var guard := 0

	while remaining.size() > 2 and guard < polygon.size() * polygon.size():
		guard += 1
		var ear_found := false

		for i in range(remaining.size()):
			var ia: int = remaining[(i - 1 + remaining.size()) % remaining.size()]
			var ib: int = remaining[i]
			var ic: int = remaining[(i + 1) % remaining.size()]

			var a := projected[ia]
			var b := projected[ib]
			var c := projected[ic]

			var cross := (
				(b.x - a.x) * (c.y - b.y)
				- (b.y - a.y) * (c.x - b.x)
			)

			if (ccw and cross <= 0.0000001) or (
				not ccw and cross >= -0.0000001
			):
				continue

			var contains_point := false
			for candidate_index in remaining:
				if candidate_index == ia or candidate_index == ib or candidate_index == ic:
					continue

				if _point_in_triangle_2d(
					projected[candidate_index], a, b, c
				):
					contains_point = true
					break

			if contains_point:
				continue

			_append_cap_triangle(
				polygon[ia], polygon[ib], polygon[ic],
				normal, output, material
			)
			remaining.remove_at(i)
			ear_found = true
			break

		if not ear_found:
			# Degenerate or self-intersecting loop.
			return

	if remaining.size() == 3:
		_append_cap_triangle(
			polygon[remaining[0]],
			polygon[remaining[1]],
			polygon[remaining[2]],
			normal, output, material
		)


static func _append_cap_triangle(
		a: Vector3,
		b: Vector3,
		c: Vector3,
		desired_normal: Vector3,
		output: Array,
		material
) -> void:
	if (b - a).cross(c - a).dot(desired_normal) < 0.0:
		var swap := b
		b = c
		c = swap

	output.append({
		"p": [a, b, c],
		"uv": [Vector2.ZERO, Vector2.ZERO, Vector2.ZERO],
		"material": material
	})


static func _point_in_triangle_2d(
		p: Vector2,
		a: Vector2,
		b: Vector2,
		c: Vector2
) -> bool:
	var d1 := _cross_2d(p, a, b)
	var d2 := _cross_2d(p, b, c)
	var d3 := _cross_2d(p, c, a)

	var has_negative := d1 < -0.000001 or d2 < -0.000001 or d3 < -0.000001
	var has_positive := d1 > 0.000001 or d2 > 0.000001 or d3 > 0.000001

	return not (has_negative and has_positive)


static func _cross_2d(p: Vector2, a: Vector2, b: Vector2) -> float:
	return (
		(p.x - a.x) * (b.y - a.y)
		- (p.y - a.y) * (b.x - a.x)
	)


static func _append_hull_face(
	model: objectMeshModel,
	p0: Vector3,
	p1: Vector3,
	p2: Vector3,
	source_centers: Array[Vector3],
	source_materials: Array
) -> void:
	var cross: Vector3 = (p1 - p0).cross(p2 - p0)

	if cross.length_squared() <= 0.0000000001:
		return

	# New hull faces do not have original UVs. Use planar XZ mapping.
	var uvs := PackedVector2Array([
		Vector2(p0.x, p0.z),
		Vector2(p1.x, p1.z),
		Vector2(p2.x, p2.z)
	])

	# Assign the material from the nearest original triangle centroid.
	var center: Vector3 = (p0 + p1 + p2) / 3.0
	var nearest_index: int = -1
	var nearest_distance: float = INF

	for i in range(source_centers.size()):
		var distance: float = center.distance_squared_to(
			source_centers[i]
		)

		if distance < nearest_distance:
			nearest_distance = distance
			nearest_index = i

	var material = null

	if nearest_index >= 0:
		material = source_materials[nearest_index]

	var points := PackedVector3Array([p0, p1, p2])

	var face = objectMeshModel.meshFace.new(
		model,
		points,
		uvs,
		material
	)

	model.faces.append(face)


static func _make_model_from_component(
	component: Array[int],
	triangles: Array,
	welded_positions: Array[Vector3],
	result_transform: Transform3D
) -> objectMeshModel:
	var model := objectMeshModel.new()
	model.globalTransform = result_transform

	for triangle_index in component:
		var triangle_data: Dictionary = triangles[triangle_index]
		var ids: Array = triangle_data["ids"]
		var uvs: Array = triangle_data["uv"]

		var points := PackedVector3Array([
			welded_positions[ids[0]],
			welded_positions[ids[1]],
			welded_positions[ids[2]]
		])

		var triangle_uvs := PackedVector2Array([
			uvs[0],
			uvs[1],
			uvs[2]
		])

		var face = objectMeshModel.meshFace.new(
			model,
			points,
			triangle_uvs,
			triangle_data["material"]
		)

		model.faces.append(face)

	if model.faces.is_empty():
		return null

	model.rebuild()
	return model


static func _triangulate_convex_hull(
	points: PackedVector3Array
) -> Array:
	var triangles: Array = []

	if points.size() < 4:
		return triangles

	var bounds := AABB(points[0], Vector3.ZERO)
	for point in points:
		bounds = bounds.expand(point)

	var scale: float = maxf(
		bounds.size.x,
		maxf(bounds.size.y, bounds.size.z)
	)
	var tolerance: float = maxf(0.00001, scale * 0.000001)
	var normal_tolerance: float = 0.0001

	# Each entry represents one unique supporting plane.
	var planes: Array[Dictionary] = []

	for i in range(points.size() - 2):
		for j in range(i + 1, points.size() - 1):
			for k in range(j + 1, points.size()):
				var a: Vector3 = points[i]
				var b: Vector3 = points[j]
				var c: Vector3 = points[k]

				var normal: Vector3 = (b - a).cross(c - a)

				if normal.length_squared() <= tolerance * tolerance:
					continue

				normal = normal.normalized()

				var has_positive := false
				var has_negative := false

				for point in points:
					var distance: float = normal.dot(point - a)

					if distance > tolerance:
						has_positive = true
					elif distance < -tolerance:
						has_negative = true

					if has_positive and has_negative:
						break

				# A supporting plane has all hull points on one side.
				if has_positive and has_negative:
					continue

				# Orient the plane outward, so the hull lies behind it.
				if has_positive:
					normal = -normal

				var plane_w: float = normal.dot(a)
				var duplicate := false

				for existing in planes:
					if (
						normal.dot(existing["normal"])
							>= 1.0 - normal_tolerance
						and absf(plane_w - existing["w"]) <= tolerance
					):
						duplicate = true
						break

				if duplicate:
					continue

				# Gather all points belonging to this planar face.
				var face_indices: Array[int] = []

				for point_index in range(points.size()):
					if absf(
						normal.dot(points[point_index]) - plane_w
					) <= tolerance:
						face_indices.append(point_index)

				if face_indices.size() < 3:
					continue

				planes.append({
					"normal": normal,
					"w": plane_w,
					"indices": face_indices
				})

	# Sort each planar face around its centroid, then triangulate it.
	for face in planes:
		var normal: Vector3 = face["normal"]
		var face_indices: Array[int] = face["indices"]

		var center := Vector3.ZERO
		for index in face_indices:
			center += points[index]
		center /= float(face_indices.size())

		var axis_u: Vector3 = (
			points[face_indices[0]] - center
		).normalized()

		if axis_u.length_squared() < 0.5:
			continue

		var axis_v: Vector3 = normal.cross(axis_u).normalized()

		face_indices.sort_custom(
			func(a_index: int, b_index: int) -> bool:
				var a_delta: Vector3 = points[a_index] - center
				var b_delta: Vector3 = points[b_index] - center

				var angle_a: float = atan2(
					a_delta.dot(axis_v),
					a_delta.dot(axis_u)
				)
				var angle_b: float = atan2(
					b_delta.dot(axis_v),
					b_delta.dot(axis_u)
				)

				return angle_a < angle_b
		)

		var first: Vector3 = points[face_indices[0]]

		for i in range(1, face_indices.size() - 1):
			var second: Vector3 = points[face_indices[i]]
			var third: Vector3 = points[face_indices[i + 1]]

			# Ensure winding agrees with the outward face normal.
			if (second - first).cross(third - first).dot(normal) < 0.0:
				var temp: Vector3 = second
				second = third
				third = temp

			triangles.append([first, second, third])

	return triangles


static func _decomposed_triangles_to_model(triangles: Array) -> objectMeshModel:
	var model := objectMeshModel.new()

	for triangle in triangles:
		var points: Array = triangle["p"]
		var uvs: Array = triangle["uv"]
		var material = triangle["material"]

		var face = objectMeshModel.meshFace.new(
			model,
			PackedVector3Array(points),
			PackedVector2Array(uvs),
			material
		)

		model.faces.append(face)

	model.rebuild()
	return model

static func _decompose_component_to_models(
		component: Array
) -> Array[objectMeshModel]:
	var triangle_sets: Array = []
	var models: Array[objectMeshModel] = []

	_decompose_recursive(component, triangle_sets, 0)

	for triangles in triangle_sets:
		var model := _decomposed_triangles_to_model(triangles)
		models.append(model)

	return models
