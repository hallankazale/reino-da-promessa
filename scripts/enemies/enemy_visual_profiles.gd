extends RefCounted
class_name EnemyVisualProfiles

## Central registry for imported enemy presentation quirks.
## Gameplay code never needs to know asset-specific forward axes or foot offsets.
## IMPORTANT: yaw here is the correction of the imported mesh, not gameplay facing.

const DEFAULT_PROFILE := {
	"override_yaw": false,
	"yaw_degrees": 0.0,
	"ground_to_collider": true,
	"feet_offset": 0.0,
}

const PROFILES := {
	"wasteland_specter": {
		# Quaternius specter already uses the gameplay -Z forward convention.
		# The previous 180-degree correction inverted it and was the reason the
		# on-screen creature kept looking away even though the adapter test passed.
		"override_yaw": true,
		"yaw_degrees": 0.0,
		"ground_to_collider": true,
		"feet_offset": -0.04,
	},
	"spring_shade": {
		"override_yaw": true,
		"yaw_degrees": 0.0,
		"ground_to_collider": true,
		"feet_offset": -0.04,
	},
	"skeleton_raider": {
		# Logical id kept for loot/quest compatibility; visual is KayKit Rogue_Hooded.
		# KayKit characters face +Z in their source asset, so they need 180 degrees
		# to match the game's -Z-forward convention. A small sole offset removes the
		# visible hover caused by the imported rig/bounds.
		"override_yaw": true,
		"yaw_degrees": 180.0,
		"ground_to_collider": true,
		"feet_offset": -0.14,
	},
	"ruins_demon": {
		"override_yaw": true,
		"yaw_degrees": 0.0,
		"ground_to_collider": true,
		"feet_offset": -0.03,
	},
}

static func get_profile(enemy_kind: String) -> Dictionary:
	var profile := DEFAULT_PROFILE.duplicate(true)
	if PROFILES.has(enemy_kind):
		for key in PROFILES[enemy_kind].keys():
			profile[key] = PROFILES[enemy_kind][key]
	return profile
