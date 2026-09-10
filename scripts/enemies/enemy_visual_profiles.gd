extends RefCounted
class_name EnemyVisualProfiles

## Central registry for imported enemy presentation quirks.
## Gameplay code never needs to know asset-specific forward axes or foot offsets.

const DEFAULT_PROFILE := {
	"override_yaw": false,
	"yaw_degrees": 0.0,
	"ground_to_collider": true,
	"feet_offset": 0.0,
}

const PROFILES := {
	"wasteland_specter": {
		"override_yaw": true,
		"yaw_degrees": 180.0,
		"ground_to_collider": true,
		"feet_offset": 0.0,
	},
	"spring_shade": {
		"override_yaw": true,
		"yaw_degrees": 180.0,
		"ground_to_collider": true,
		"feet_offset": 0.0,
	},
	"skeleton_raider": {
		# Logical id kept for loot/quest compatibility; visual is KayKit Rogue_Hooded.
		"override_yaw": true,
		"yaw_degrees": 180.0,
		"ground_to_collider": true,
		"feet_offset": 0.0,
	},
	"ruins_demon": {
		"override_yaw": true,
		"yaw_degrees": 0.0,
		"ground_to_collider": true,
		"feet_offset": 0.0,
	},
}

static func get_profile(enemy_kind: String) -> Dictionary:
	var profile := DEFAULT_PROFILE.duplicate(true)
	if PROFILES.has(enemy_kind):
		for key in PROFILES[enemy_kind].keys():
			profile[key] = PROFILES[enemy_kind][key]
	return profile
