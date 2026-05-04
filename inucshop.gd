extends Control

# --- CONFIGURATION DES CHEMINS ---
const BDD_PATH = "res://bdd_jeux.json"
const SAVE_DIR = "user://apps/"

# --- RÉFÉRENCES AUX NŒUDS ---
# Assure-toi que ces noms correspondent exactement à ton arbre de scène
@onready var grille = $ScrollContainer/GameGrid
@onready var barre_recherche = $LineEdit 

# --- VARIABLES GLOBALES ---
var liste_complete_jeux = [] # Stockage des données du JSON pour le filtrage

func _ready():
	# 1. Créer le dossier sur la Raspberry Pi s'il n'existe pas
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	
	# 2. Connexion du signal de la barre de recherche
	if barre_recherche:
		barre_recherche.text_changed.connect(self._on_recherche_text_changed)
	grille.add_theme_constant_override("margin_top", 50)
	# 3. Lancer le chargement initial
	charger_la_boutique()

func charger_la_boutique():
	if not FileAccess.file_exists(BDD_PATH):
		push_error("ERREUR : Le fichier bdd_jeux.json est introuvable !")
		return
		
	var file = FileAccess.open(BDD_PATH, FileAccess.READ)
	var content = file.get_as_text()
	var data = JSON.parse_string(content)
	
	if data and data.has("jeux"):
		liste_complete_jeux = data["jeux"]
		# On affiche tous les jeux au démarrage
		afficher_jeux_filtres("")
	else:
		push_error("ERREUR : Format JSON invalide ou clé 'jeux' manquante.")

func afficher_jeux_filtres(filtre: String):
	# On vide la grille proprement avant de la reconstruire
	for n in grille.get_children():
		n.queue_free()

	# On parcourt la liste mémorisée pour appliquer le filtre
	for jeu in liste_complete_jeux:
		# Vérifie si le titre contient le texte recherché (insensible à la casse)
		if filtre == "" or filtre.to_lower() in jeu["titre"].to_lower():
			creer_fiche_jeu(jeu)

func creer_fiche_jeu(infos):
	var v_box = VBoxContainer.new()
	v_box.custom_minimum_size = Vector2(200, 200)
	v_box.add_theme_constant_override("separation", 15)
	
	# 1. L'IMAGE (TextureButton)
	var btn_img = TextureButton.new()
	btn_img.custom_minimum_size = Vector2(200, 200)
	btn_img.ignore_texture_size = true
	btn_img.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	
	if ResourceLoader.exists(infos["icone"]):
		btn_img.texture_normal = load(infos["icone"])
	else:
		btn_img.texture_normal = load("res://icon.svg")
	
	# 2. LE TITRE (Forcé en NOIR)
	var titre = Label.new()
	titre.text = infos["titre"]
	titre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titre.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# Application de la couleur noire
	titre.add_theme_color_override("font_color", Color.BLACK)
	# Optionnel : augmenter un peu la taille pour la lisibilité
	titre.add_theme_font_size_override("font_size", 18)
	
	# 3. LE BOUTON INSTALLER
	var btn_inst = Button.new()
	btn_inst.text = "Installer"
	btn_inst.custom_minimum_size.y = 50
	if est_deja_installe(infos["exec_name"]):
		btn_inst.text = "Jouer"
		btn_inst.add_theme_color_override("font_color", Color.GREEN)
		# On change la fonction connectée pour lancer le jeu au lieu d'installer
		btn_inst.pressed.connect(self._on_play_pressed.bind(infos))
	else:
		btn_inst.text = "Installer"
		btn_inst.pressed.connect(self._on_install_pressed.bind(infos, btn_inst))
	
	# Assemblage
	v_box.add_child(btn_img)
	v_box.add_child(titre)
	v_box.add_child(btn_inst)
	grille.add_child(v_box)

# --- GESTION DES SIGNAUX ---

func _on_recherche_text_changed(nouveau_texte):
	# Met à jour la grille à chaque lettre tapée
	afficher_jeux_filtres(nouveau_texte)

func _on_install_pressed(infos, bouton):
	bouton.text = "Téléchargement..."
	bouton.disabled = true
	
	var http = HTTPRequest.new()
	add_child(http)
	
	var save_path = SAVE_DIR + infos["exec_name"]
	http.set_download_file(save_path)
	
	var err = http.request(infos["download_url"])
	
	if err != OK:
		bouton.text = "Erreur de lien"
		bouton.disabled = false
		return

	http.request_completed.connect(func(result, response_code, headers, body):
		if response_code == 200:
			bouton.text = "Installé"
			var real_path = ProjectSettings.globalize_path(save_path)
			OS.execute("chmod", ["+x", real_path])
			print("Installation réussie : ", real_path)
		else:
			bouton.text = "Échec : " + str(response_code)
			bouton.disabled = false
		http.queue_free())

func _on_bouton_retour_pressed():
	get_tree().change_scene_to_file("res://interfacev2.tscn")

func est_deja_installe(exec_name: String) -> bool:
	var path = SAVE_DIR + exec_name
	return FileAccess.file_exists(path)

func _on_play_pressed(infos):
	var path = ProjectSettings.globalize_path(SAVE_DIR + infos["exec_name"])
	print("Lancement du jeu : ", path)
	
	# Sur Linux/Raspberry, on lance l'exécutable
	OS.execute(path, [])
