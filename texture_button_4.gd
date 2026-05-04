extends TextureButton

func _ready():
	# On connecte le clic du bouton à la fonction
	self.pressed.connect(_on_pressed)
	

func _on_pressed():
	# Ici on crée un petit menu ou on exécute directement
	# Pour éteindre la Raspberry Pi immédiatement :
	OS.execute("sudo", ["shutdown", "now"])

func veille_ecran():
	OS.execute("xset", ["dpms", "force", "off"])
	
func _on_texture_butto_focus_entered() -> void:
	# Change le texte de ton label au-dessus de la barre
	%DescriptionAction.text = "Eteindre"

func _on_texture_butto_focus_exited() -> void:
	# Vide le texte quand tu quittes le bouton
	%DescriptionAction.text = ""
