extends Control
## Full character customizer — era-aware clothing, 3D preview, backstory.

const HumanoidBuilder = preload("res://scripts/character/HumanoidBuilder.gd")

@onready var name_edit: LineEdit = %NameEdit
@onready var gender_option: OptionButton = %GenderOption
@onready var body_slider: HSlider = %BodySlider
@onready var skin_slider: HSlider = %SkinSlider
@onready var hair_slider: HSlider = %HairSlider
@onready var hair_color_slider: HSlider = %HairColorSlider
@onready var face_slider: HSlider = %FaceSlider
@onready var outfit_option: OptionButton = %OutfitOption
@onready var accessory_option: OptionButton = %AccessoryOption
@onready var preview: ColorRect = %Preview
@onready var preview_label: Label = %PreviewLabel
@onready var era_label: Label = %EraLabel

@onready var height_slider: HSlider = get_node_or_null("%HeightSlider")
@onready var eye_slider: HSlider = get_node_or_null("%EyeSlider")
@onready var facial_slider: HSlider = get_node_or_null("%FacialSlider")
@onready var backstory_option: OptionButton = get_node_or_null("%BackstoryOption")
@onready var preview_root: Node3D = get_node_or_null("%PreviewRoot")
@onready var preview_cam: Camera3D = get_node_or_null("%PreviewCam")


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var era := EraManager.get_era()
	era_label.text = "Era: %s (%d) — clothing & tools adapt" % [era["label"], era["year"]]
	gender_option.clear()
	for g in ["Non-binary / Neutral", "Masculine", "Feminine"]:
		gender_option.add_item(g)
	if backstory_option:
		backstory_option.clear()
		backstory_option.add_item("Local — grew up in Mystery Hollow")
		backstory_option.add_item("Transfer — assigned from the city")
		backstory_option.add_item("Returning — left years ago, came back")
	_setup_preview_world()
	_refill_era_clothing()
	name_edit.text = "Detective %s" % ["Hart", "Cole", "Quinn", "Reed", "Ash"][randi() % 5]
	_update_preview()


func _setup_preview_world() -> void:
	var we := get_node_or_null("Margin/HBox/Right/SubViewportContainer/SubViewport/WorldEnv") as WorldEnvironment
	if we:
		if we.environment == null:
			we.environment = Environment.new()
		we.environment.background_mode = Environment.BG_COLOR
		we.environment.background_color = Color(0.18, 0.2, 0.24)
		we.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		we.environment.ambient_light_color = Color(0.6, 0.62, 0.65)
		we.environment.ambient_light_energy = 0.7



func _refill_era_clothing() -> void:
	var era := EraManager.get_era()
	outfit_option.clear()
	for o in era["outfit_names"]:
		outfit_option.add_item(str(o))
	accessory_option.clear()
	for a in era["accessory_names"]:
		accessory_option.add_item(str(a))


func _on_any_changed(_v: Variant = null) -> void:
	_update_preview()


func _on_randomize() -> void:
	body_slider.value = randi() % 3
	skin_slider.value = randi() % 6
	hair_slider.value = randi() % 4
	hair_color_slider.value = randi() % 6
	face_slider.value = randi() % 5
	if height_slider:
		height_slider.value = randi() % 3
	if eye_slider:
		eye_slider.value = randi() % 5
	if facial_slider:
		facial_slider.value = randi() % 3
	gender_option.select(randi() % 3)
	if outfit_option.item_count > 0:
		outfit_option.select(randi() % outfit_option.item_count)
	if accessory_option.item_count > 0:
		accessory_option.select(randi() % accessory_option.item_count)
	_update_preview()


func _build_character() -> Dictionary:
	var genders := ["neutral", "masculine", "feminine"]
	var stories := ["local", "transfer", "returning"]
	var outfits := [
		Color(0.18, 0.22, 0.32), Color(0.15, 0.15, 0.16), Color(0.35, 0.22, 0.18), Color(0.28, 0.32, 0.28)
	]
	var outfit_i: int = clampi(outfit_option.selected, 0, outfits.size() - 1)
	var backstory := "local"
	if backstory_option:
		backstory = stories[clampi(backstory_option.selected, 0, 2)]
	return {
		"name": name_edit.text.strip_edges() if name_edit.text.strip_edges() != "" else "Detective",
		"gender": genders[gender_option.selected],
		"height": int(height_slider.value) if height_slider else 1,
		"body_type": int(body_slider.value),
		"skin_tone": int(skin_slider.value),
		"hair_style": int(hair_slider.value),
		"hair_color": int(hair_color_slider.value),
		"eye_color": int(eye_slider.value) if eye_slider else 0,
		"face_style": int(face_slider.value),
		"facial_hair": int(facial_slider.value) if facial_slider else 0,
		"outfit": outfit_option.selected,
		"accessory": accessory_option.selected,
		"badge": 1,
		"primary_color": outfits[outfit_i],
		"secondary_color": Color(0.32, 0.28, 0.24),
		"backstory": backstory,
	}


func _update_preview() -> void:
	var data := _build_character()
	preview.color = data["primary_color"].lerp(Color(0.8, 0.7, 0.55), 0.25)
	var story := str(data.get("backstory", "local"))
	preview_label.text = "%s\n%s · %s\n%s\nBackstory: %s" % [
		data["name"],
		gender_option.get_item_text(gender_option.selected),
		outfit_option.get_item_text(maxi(outfit_option.selected, 0)),
		accessory_option.get_item_text(maxi(accessory_option.selected, 0)),
		story,
	]
	if preview_root:
		HumanoidBuilder.build(preview_root, data)


func _on_start() -> void:
	GameState.new_game(EraManager.current_era_id, _build_character())
	get_tree().change_scene_to_file("res://scenes/world/Town.tscn")


func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/main/MainMenu.tscn")
