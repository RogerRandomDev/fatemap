
extends RefCounted
class_name MeshBoolean

enum Operation {
	UNION,
	DIFFERENCE,
	INTERSECTION
}

const EPSILON: float = 0.00001


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
) -> Array[objectMeshModel]:
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

	return _polygons_to_models(a.all_polygons(), transform_a)


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
) -> Array[objectMeshModel]:
	var results: Array[objectMeshModel] = []
	var triangles: Array = []

	var tolerance: float = _get_weld_tolerance(polygons)
	var buckets: Dictionary = {}
	var welded_positions: Array[Vector3] = []

	# Triangulate polygons and weld their vertex positions.
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

			# Welding may collapse a degenerate triangle.
			if ids[0] == ids[1] or ids[1] == ids[2] or ids[2] == ids[0]:
				continue

			var a: Vector3 = welded_positions[ids[0]]
			var b: Vector3 = welded_positions[ids[1]]
			var c: Vector3 = welded_positions[ids[2]]

			if (b - a).cross(c - a).length_squared() <= tolerance ** 4:
				continue

			triangles.append({
				"ids": ids,
				"uvs": uvs,
				"material": polygon.material
			})
	
	triangles = _repair_t_junctions(
		triangles,
		welded_positions,
		tolerance
	)
	
	if triangles.is_empty():
		return results

	# Build edge -> triangle incidence.
	# Only edges with exactly two incident triangles connect components.
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

	# Create triangle adjacency graph.
	var adjacency: Array = []

	for i in range(triangles.size()):
		adjacency.append([])

	for edge in edge_triangles:
		var incident: Array = edge_triangles[edge]

		if incident.size() < 2:
			continue

		# Connect all triangles incident to this edge.
		# Do not split valid components merely because BSP generated
		# more than two faces sharing the same welded edge.
		for i in range(incident.size()):
			for j in range(i + 1, incident.size()):
				var triangle_a: int = incident[i]
				var triangle_b: int = incident[j]

				adjacency[triangle_a].append(triangle_b)
				adjacency[triangle_b].append(triangle_a)

	# Find connected components using breadth-first search.
	var visited := PackedByteArray()
	visited.resize(triangles.size())
	visited.fill(0)

	for start in range(triangles.size()):
		if visited[start] != 0:
			continue

		var component: Array[int] = []
		var queue: Array[int] = [start]
		var queue_index := 0

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

		var result := objectMeshModel.new()
		result.globalTransform = result_transform

		for triangle_index in component:
			var triangle_data: Dictionary = triangles[triangle_index]
			var ids: Array = triangle_data["ids"]
			var uvs: Array = triangle_data["uvs"]

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
				result,
				points,
				triangle_uvs,
				triangle_data["material"]
			)

			result.faces.append(face)

		result.rebuild()
		results.append(result)

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
		var uvs: Array = triangle_data["uvs"]

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
				"uvs": [center_uv, a["uv"], b["uv"]],
				"material": triangle_data["material"]
			})

	return repaired
