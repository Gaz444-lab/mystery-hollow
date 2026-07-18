extends Node
## Era selection drives fashion, tech, vehicles, tools, and world flavour.

const ERAS := {
	"1900s": {
		"label": "1900s",
		"year": 1905,
		"tagline": "Gas lamps, horse carts, and whispered secrets.",
		"tech_level": 1,
		"vehicle": "Horse & Carriage",
		"tools": ["Notebook", "Magnifying glass", "Pocket watch"],
		"palette": {
			"sky_day": Color(0.55, 0.65, 0.78),
			"sky_night": Color(0.05, 0.06, 0.12),
			"building_a": Color(0.45, 0.38, 0.30),
			"building_b": Color(0.52, 0.42, 0.32),
			"road": Color(0.28, 0.26, 0.22),
			"grass": Color(0.22, 0.35, 0.18),
			"accent": Color(0.55, 0.42, 0.22),
		},
		"outfit_names": ["Wool coat", "Waistcoat", "Long dress", "Work apron"],
		"accessory_names": ["Bowler hat", "Bonnet", "Pocket watch chain", "Spectacles"],
	},
	"1980s": {
		"label": "1980s",
		"year": 1986,
		"tagline": "Neon nights, cassette tapes, cold cases on film.",
		"tech_level": 3,
		"vehicle": "Sedan",
		"tools": ["Polaroid", "Walkie-talkie", "Cassette recorder"],
		"palette": {
			"sky_day": Color(0.45, 0.62, 0.85),
			"sky_night": Color(0.08, 0.05, 0.15),
			"building_a": Color(0.55, 0.45, 0.40),
			"building_b": Color(0.35, 0.40, 0.48),
			"road": Color(0.22, 0.22, 0.24),
			"grass": Color(0.20, 0.38, 0.18),
			"accent": Color(0.85, 0.25, 0.55),
		},
		"outfit_names": ["Leather jacket", "Power suit", "Denim set", "Track jacket"],
		"accessory_names": ["Sunglasses", "Walkman", "Mullet-ready bandana", "Gold chain"],
	},
	"1990s": {
		"label": "1990s",
		"year": 1997,
		"tagline": "Grunge coats, payphones, and grainy VHS clues.",
		"tech_level": 4,
		"vehicle": "Pickup truck",
		"tools": ["Pager", "Disposable camera", "Flip phone (late)"],
		"palette": {
			"sky_day": Color(0.50, 0.68, 0.88),
			"sky_night": Color(0.06, 0.07, 0.14),
			"building_a": Color(0.48, 0.48, 0.46),
			"building_b": Color(0.40, 0.42, 0.50),
			"road": Color(0.20, 0.20, 0.22),
			"grass": Color(0.22, 0.40, 0.20),
			"accent": Color(0.30, 0.55, 0.75),
		},
		"outfit_names": ["Flannel shirt", "Trench coat", "Hoodie & jeans", "Blazer"],
		"accessory_names": ["Beanie", "Pager clip", "Round glasses", "Backpack"],
	},
	"2000s": {
		"label": "2000s",
		"year": 2005,
		"tagline": "Flip phones, coffee chains, early digital forensics.",
		"tech_level": 5,
		"vehicle": "SUV",
		"tools": ["Digital camera", "Laptop", "Early smartphone"],
		"palette": {
			"sky_day": Color(0.48, 0.70, 0.90),
			"sky_night": Color(0.05, 0.06, 0.12),
			"building_a": Color(0.55, 0.55, 0.52),
			"building_b": Color(0.42, 0.45, 0.50),
			"road": Color(0.18, 0.18, 0.20),
			"grass": Color(0.24, 0.42, 0.22),
			"accent": Color(0.20, 0.45, 0.70),
		},
		"outfit_names": ["Cargo jacket", "Business casual", "Y2K jacket", "Peacoat"],
		"accessory_names": ["Bluetooth earpiece", "Ball cap", "ID lanyard", "Thin glasses"],
	},
	"present": {
		"label": "Present Day",
		"year": 2026,
		"tagline": "Body cams, smartphones, and secrets that still hide offline.",
		"tech_level": 6,
		"vehicle": "Electric crossover",
		"tools": ["Smartphone", "Body cam", "Forensic kit"],
		"palette": {
			"sky_day": Color(0.52, 0.72, 0.92),
			"sky_night": Color(0.04, 0.05, 0.10),
			"building_a": Color(0.58, 0.56, 0.54),
			"building_b": Color(0.38, 0.42, 0.48),
			"road": Color(0.16, 0.16, 0.18),
			"grass": Color(0.26, 0.44, 0.24),
			"accent": Color(0.25, 0.55, 0.50),
		},
		"outfit_names": ["Field jacket", "Smart casual", "Tactical softshell", "Wool overcoat"],
		"accessory_names": ["Smartwatch", "Ballistic glasses", "Beanie", "Scarf"],
	},
}

var current_era_id: String = "present"


func set_era(era_id: String) -> void:
	if not ERAS.has(era_id):
		era_id = "present"
	current_era_id = era_id
	EventBus.era_changed.emit(current_era_id)


func get_era() -> Dictionary:
	return ERAS[current_era_id]


func get_palette() -> Dictionary:
	return get_era()["palette"]


func get_era_ids() -> Array:
	return ERAS.keys()


func tech_allows(feature: String) -> bool:
	## Gate era-specific detective tools.
	var level: int = int(get_era().get("tech_level", 1))
	match feature:
		"digital_forensics":
			return level >= 5
		"phone_records":
			return level >= 4
		"camera":
			return level >= 3
		"radio":
			return level >= 3
		_:
			return true
