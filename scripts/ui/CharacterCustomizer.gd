extends Control
## Full character customization before entering the world.

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


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var era := EraManager.get_era()
	era_label.text = "Era: %s (%d)" % [era["label"], era["year"]]
	gender_option.clear()
	for g in ["Neutral", "Masculine", "Feminine"]:
		gender_option.add_item(g)
	_refill_era_clothing()
	name_edit.text = "Detective %s" % ["Hart", "Cole", "Quinn", "Reed"][randi() % 4]
	_update_preview()


func _refill_era_clothing() -> void:
	var era := EraManager.get_era()
	outfit_option.clear()
	for o in era["outfit_names"]:
		outfit_option.add_item(o)
	accessory_option.clear()
	for a in era["accessory_names"]:
		accessory_option.add_item(a)


func _on_any_changed(_v: Variant = null) -> void:
	_update_preview()


func _update_preview() -> void:
	var tones := [
		Color(0.95, 0.85, 0.75), Color(0.90, 0.75, 0.60), Color(0.80, 0.62, 0.48),
		Color(0.65, 0.45, 0.32), Color(0.45, 0.30, 0.22), Color(0.30, 0.20, 0.15),
	]
	var skin: Color = tones[clampi(int(skin_slider.value), 0, 5)]
	var outfits := [
		Color(0.2, 0.25, 0.4), Color(0.15, 0.15, 0.15), Color(0.45, 0.25, 0.2), Color(0.3, 0.4, 0.35)
	]
	var outfit_col: Color = outfits[clampi(outfit_option.selected, 0, outfits.size() - 1)]
	preview.color = outfit_col.lerp(skin, 0.35)
	preview_label.text = "%s\n%s · %s\n%s" % [
		name_edit.text,
		gender_option.get_item_text(gender_option.selected),
		outfit_option.get_item_text(maxi(outfit_option.selected, 0)),
		accessory_option.get_item_text(maxi(accessory_option.selected, 0)),
	]


func _build_character() -> Dictionary:
	var genders := ["neutral", "masculine", "feminine"]
	return {
		"name": name_edit.text.strip_edges() if name_edit.text.strip_edges() != "" else "Detective",
		"gender": genders[gender_option.selected],
		"body_type": int(body_slider.value),
		"skin_tone": int(skin_slider.value),
		"hair_style": int(hair_slider.value),
		"hair_color": int(hair_color_slider.value),
		"face_style": int(face_slider.value),
		"outfit": outfit_option.selected,
		"accessory": accessory_option.selected,
		"primary_color": preview.color.darkened(0.2),
		"secondary_color": Color(0.75, 0.7, 0.55),
	}


func _on_start() -> void:
	GameState.new_game(EraManager.current_era_id, _build_character())
	get_tree().change_scene_to_file("res://scenes/world/Town.tscn")


func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/main/MainMenu.tscn")
