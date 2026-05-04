extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$AnimationPlayer.play("flambo")
	$AudioStreamPlayer2D.play()
	$AnimationPlayer.animation_finished.connect(_on_intro_terminee)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func _on_intro_terminee(_anim_name):
	# On bascule vers ton interface principale
	get_tree().change_scene_to_file("res://interfacev2.tscn")
