extends Node
## Global signal bus — keep systems decoupled.

# Life sim
signal needs_changed(hunger: float, energy: float, mood: float)
signal relationship_changed(npc_id: String, value: int)

# World
signal time_changed(hour: float, day: int)
signal day_night_changed(is_night: bool)
signal era_changed(era_id: String)

# Detective
signal evidence_collected(evidence_id: String)
signal case_updated(case_id: String)
signal dialogue_started(npc_id: String)
signal dialogue_ended(npc_id: String)
signal accusation_result(success: bool, ending_id: String)

# Player
signal interaction_available(label: String)
signal interaction_cleared()
signal notification(text: String, duration: float)

# Save
signal game_saved()
signal game_loaded()
