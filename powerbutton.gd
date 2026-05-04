extends Button

func _ready():
	# On connecte le clic du bouton à la fonction
	self.pressed.connect(_on_pressed)

func _on_pressed():
	# Ici on crée un petit menu ou on exécute directement
	# Pour éteindre la Raspberry Pi immédiatement :
	OS.execute("sudo", ["shutdown", "now"])

# Si tu veux juste mettre l'écran en veille (économiser l'énergie)
func veille_ecran():
	OS.execute("xset", ["dpms", "force", "off"])
