extends TextureButton


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_texture_butto_focus_entered() -> void:
	# Change le texte de ton label au-dessus de la barre
	%DescriptionAction.text = "Paramètres"

func _on_texture_butto_focus_exited() -> void:
	# Vide le texte quand tu quittes le bouton
	%DescriptionAction.text = ""
