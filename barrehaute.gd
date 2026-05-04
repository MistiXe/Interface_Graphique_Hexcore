extends HBoxContainer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	get_wifi_status()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
		var datetime = Time.get_datetime_dict_from_system()
	
	# Format Heure : 14:30
		$heure.text = "%02d:%02d" % [datetime.hour, datetime.minute]
	
	# Format Date : 26/02/2026
		$date.text = "%02d/%02d/%04d" % [datetime.day, datetime.month, datetime.year]


func get_wifi_status():
	var output = []
	OS.execute("hostname", ["-I"], output) 
	if output[0].length() > 0:
		$wifi.modulate = Color.WHITE # Connecté
	else:
		$wifi.modulate = Color.RED # Déconnecté
