extends PanelContainer

func _ready():
	# On parcourt toutes les lignes (HBox) et tous les boutons
	for ligne in $VBoxContainer.get_children():
		for bouton in ligne.get_children():
			if bouton is Button:
				# On connecte le clic de chaque bouton à la fonction de saisie
				bouton.pressed.connect(_on_touche_cliquee.bind(bouton.text))

func _on_touche_cliquee(valeur: String):
	# On va chercher ta barre de saisie de mot de passe
	var line_edit = get_node("../wifipsswd/LineEdit")
	
	if valeur == "Backspace":
		line_edit.text = line_edit.text.left(-1)
	elif valeur == "Entrer":
		# On simule l'appui sur le bouton valider de ta popup
		#get_parent()._on_bouton_valider_pressed()
		pass
	elif valeur == "Espace":
		line_edit.text += " "
	else:
		# On ajoute la lettre normalement
		line_edit.text += valeur
	
	# On force le curseur à rester à la fin du texte pour voir ce qu'on écrit
	line_edit.caret_column = line_edit.text.length()
