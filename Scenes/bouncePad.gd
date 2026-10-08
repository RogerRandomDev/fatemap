extends Area3D
class_name BouncePad

func _ready() -> void:
	body_entered.connect(
		func(body:Node3D):
			if body is CharacterBody3D:
				body.velocity.y=4
	)
