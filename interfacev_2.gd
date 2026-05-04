extends Control

var reseau_actuel_selectionne = ""
var reseau_actuel = ""
var joueurs_connectes = [false, false, false]
var systeme_verrouille = true
var manettes_autorisees = []
var clavier_ouvert = false
var index_focus_wifi = 0  # index du bouton wifi actuellement sélectionné

# --------------------------------------------------
# READY
# --------------------------------------------------
func _ready() -> void:
	rafraichir_menu_jeux()
	$overlay.visible = true
	$overlay/popupmanette.visible = true
	bloquer_menu_principal()

# --------------------------------------------------
# PROCESS
# --------------------------------------------------
func _process(delta: float) -> void:
	if clavier_ouvert:
		return

	# Focus popup manette
	if $overlay/popupmanette.visible and not $overlay/popupmanette.has_focus():
		$overlay/popupmanette.grab_focus()

	# Synchronisation manettes pour popup manette
	if $overlay/popupmanette.visible:
		for i in range(3):
			if not joueurs_connectes[i]:
				if Input.is_joy_button_pressed(i, JOY_BUTTON_LEFT_SHOULDER) and \
				   Input.is_joy_button_pressed(i, JOY_BUTTON_RIGHT_SHOULDER):
					_synchroniser_manette(i)

		for id in manettes_autorisees:
			if Input.is_joy_button_pressed(id, JOY_BUTTON_X):
				debloquer_menu_principal()
				$overlay.visible = false
				$overlay/popupmanette.visible = false
				systeme_verrouille = false
				$CenterContainer/ScrollContainer/barredejeu.get_child(0).grab_focus()

# --------------------------------------------------
# MENU JEUX
# --------------------------------------------------
func rafraichir_menu_jeux():
	var dossier = DirAccess.open("user://apps/")
	var cpt = 0
	if dossier:
		dossier.list_dir_begin()
		var nom_fichier = dossier.get_next()
		while nom_fichier != "":
			if not dossier.current_is_dir() and nom_fichier.ends_with(".exe"):
				cpt += 1
				creer_bouton_jeu_dans_menu(nom_fichier)
			nom_fichier = dossier.get_next()
	$%compteur_jeu.text = "Jeux disponibles : " + str(cpt)

func creer_bouton_jeu_dans_menu(nom_exe):
	var nouveau_bouton = Button.new()
	nouveau_bouton.custom_minimum_size = Vector2(120, 50)
	nouveau_bouton.icon = load("res://assets/hecker_logo.jpg")
	nouveau_bouton.expand_icon = true
	nouveau_bouton.text = ""
	nouveau_bouton.pressed.connect(func():
		var chemin_final = ProjectSettings.globalize_path("user://apps/" + nom_exe)
		print("Lancement de : ", chemin_final)

		# 1. On cache l'interface ou on bloque les inputs
		process_mode = Node.PROCESS_MODE_DISABLED 

		# 2. On lance le jeu de manière bloquante (ou via un script externe)
		OS.execute(chemin_final, [])

		# 3. Une fois le jeu fermé, le script reprend ici
		process_mode = Node.PROCESS_MODE_INHERIT
		nouveau_bouton.grab_focus() # On redonne le focus au bouton
	)
	$CenterContainer/ScrollContainer/barredejeu.add_child(nouveau_bouton)
	$CenterContainer/ScrollContainer/barredejeu.move_child(nouveau_bouton, 0)

# --------------------------------------------------
# WIFI
# --------------------------------------------------
func lister_wifi_disponibles():
	var liste = $overlay/popupreseau/ScrollContainer/listewifi
	for enfant in liste.get_children():
		enfant.queue_free()

	var output = []
	OS.execute("netsh", ["wlan", "show", "networks"], output)
	if output.size() > 0:
		var lignes = output[0].split("\n")
		for ligne in lignes:
			if "SSID" in ligne:
				var nom_wifi = ligne.split(":")[1].strip_edges()
				if nom_wifi != "":
					_creer_bouton_wifi(nom_wifi)
	await get_tree().process_frame

	# relier le dernier wifi au bouton déconnecter
	if liste.get_child_count() > 0:
		var dernier = liste.get_child(liste.get_child_count() - 1)
		var deco = $"overlay/popupreseau/HBoxContainer/Déconnexion"
		
		# 1. Quand on appuie sur BAS depuis le dernier Wi-Fi -> Va vers Déconnecter
		dernier.focus_neighbor_bottom = deco.get_path()
		
		# 2. Quand on appuie sur HAUT depuis Déconnecter -> Remonte vers le dernier Wi-Fi
		deco.focus_neighbor_top = dernier.get_path()

func _creer_bouton_wifi(nom):
	var btn = Button.new()
	btn.text = nom
	btn.alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_LEFT
	$overlay/popupreseau/ScrollContainer/listewifi.add_child(btn)
	btn.pressed.connect(func():
		var reseau_actuel = $overlay/popupreseau/statut.text.replace("Connecté à : ", "")
		if nom != reseau_actuel:
			reseau_actuel_selectionne = nom
			_demander_connexion(nom)
	)

func verifier_statut_wifi():
	var output = []
	OS.execute("netsh", ["wlan", "show", "interfaces"], output)
	for ligne in output[0].split("\n"):
		if "SSID" in ligne:
			var nom = ligne.split(":")[1].strip_edges()
			$overlay/popupreseau/statut.text = "Connecté à : " + nom
			return
	$overlay/popupreseau/statut.text = "Non connecté"

# --------------------------------------------------
# CLAVIER WIFI
# --------------------------------------------------
func _demander_connexion(nom_du_reseau: String):
	reseau_actuel_selectionne = nom_du_reseau
	clavier_ouvert = true
	$overlay/wifipsswd.visible = true
	$overlay/clavier.show()
	bloquer_menu_principal()
	await get_tree().process_frame
	# Focus automatique sur le premier bouton du clavier
	if $overlay/clavier.get_child_count() > 0:
		var premier_bouton = $overlay/clavier.get_node("VBoxContainer/HBoxContainer/Button")
		if premier_bouton:
			premier_bouton.grab_focus()

func _fermer_clavier_et_mur():
	clavier_ouvert = false
	$overlay/wifipsswd.visible = false
	$overlay/clavier.hide()
	$CenterContainer.process_mode = Node.PROCESS_MODE_INHERIT
	if $CenterContainer/ScrollContainer/barredejeu.get_child_count() > 0:
		$CenterContainer/ScrollContainer/barredejeu.get_child(0).grab_focus()

func ajouter_lettre(lettre):
	var champ = $overlay/wifipsswd/LineEdit
	champ.text += lettre
	$overlay/wifipsswd/LineEdit.grab_focus()  # focus toujours sur le champ

func supprimer_lettre():
	var champ = $overlay/wifipsswd/LineEdit
	var txt = champ.text
	if txt.length() > 0:
		champ.text = txt.substr(0, txt.length() - 1)
	$overlay/wifipsswd/LineEdit.grab_focus()

# --------------------------------------------------
# GESTION MANETTE RESEAU
# --------------------------------------------------
func _unhandled_input(event):
	if $overlay/popupreseau.visible:
		var liste = $overlay/popupreseau/ScrollContainer/listewifi
		var nb_btn = liste.get_child_count()
		if nb_btn == 0:
			print("Il y en a 0")
			return
		
		
		if event is InputEventJoypadButton and event.pressed:
			print("test")
			if event.button_index == JOY_BUTTON_B:
				$overlay/popupreseau.visible = false
				$overlay.visible = false
				debloquer_menu_principal()

# --------------------------------------------------
# VALIDATION WIFI
# --------------------------------------------------
func _on_bouton_valider_pressed():
	var password = $overlay/wifipsswd/LineEdit.text
	var ssid = reseau_actuel_selectionne
	var args = ["wlan", "connect", "name=" + ssid]
	OS.execute("netsh", args)
	_fermer_clavier_et_mur()
	verifier_statut_wifi()

# --------------------------------------------------
# BOUTONS POPUP
# --------------------------------------------------
func _on_bouton_reseau_pressed():
	$overlay.visible = true
	$overlay/popupreseau.visible = true
	verifier_statut_wifi()
	lister_wifi_disponibles()
	bloquer_menu_principal()
	await get_tree().process_frame
	$overlay/popupreseau/ScrollContainer/listewifi.get_child(0).grab_focus()



		
	





	

func _on_bouton_deconnexion_pressed():
	OS.execute("netsh", ["wlan", "disconnect"])
	verifier_statut_wifi()

func _on_bouton_fermer_pressed() -> void:
	$overlay/popupreseau.visible = false
	$overlay.visible = false
	debloquer_menu_principal()

# --------------------------------------------------
# MANETTES
# --------------------------------------------------
func _on_bouton_manette_pressed() -> void:
	bloquer_menu_principal()
	$overlay.visible = true
	$overlay/popupmanette.visible = true

func _synchroniser_manette(index):
	if not index in manettes_autorisees:
		manettes_autorisees.append(index)
		joueurs_connectes[index] = true
		var slot = $overlay/popupmanette/conteneurslots.get_child(index)
		slot.modulate = Color(1, 1, 1, 1)
		if manettes_autorisees.size() == 1:
			systeme_verrouille = false
			for bouton in $CenterContainer/ScrollContainer/barredejeu.get_children():
				bouton.focus_mode = Control.FOCUS_ALL

# --------------------------------------------------
# FOCUS MENU PRINCIPAL
# --------------------------------------------------
func bloquer_menu_principal():
	for bouton in $CenterContainer/ScrollContainer/barredejeu.get_children():
		bouton.focus_mode = Control.FOCUS_NONE

func debloquer_menu_principal():
	for bouton in $CenterContainer/ScrollContainer/barredejeu.get_children():
		bouton.focus_mode = Control.FOCUS_ALL


func _on_wpa_cli_pressed() -> void:
	print("Lancement de la synchronisation WPS (PBC)...")
	# On demande à Linux de chercher un bouton WPS pressé sur le routeur
	var output = []
	OS.execute("wpa_cli", ["wps_pbc"], output)
	
	# Optionnel : Afficher un message à l'utilisateur
	$overlay/popupreseau/statut.text = "Appuyez sur le bouton de votre routeur..."
	
	# Lancer un timer pour vérifier si la connexion a réussi après 15-30 secondes
	await get_tree().create_timer(20).timeout
	verifier_statut_wifi()




func _on_inushop_pressed() -> void:
	get_tree().change_scene_to_file("res://inucshop.tscn")
