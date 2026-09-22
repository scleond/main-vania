extends RefCounted
## Central gameplay tuning for the Ember combat slice (issue #20).
##
## This is the authoritative source for swipe timing, reach, damage, burn,
## knockback, and enemy warning/recovery behavior. player.gd and main.gd read
## these values; visual.gd (presentation) must never change them. Animation
## frame counts and playback speeds do not trigger or determine damage windows.
const PLAYER_MOVE_SPEED := 115.0
const PLAYER_GROUND_ACCELERATION := 900.0
const PLAYER_GROUND_STOPPING := 1250.0
const PLAYER_AIR_ACCELERATION := 510.0
const PLAYER_AIR_STOPPING := 230.0
const PLAYER_DASH_SPEED := 340.0
const DASH_DURATION := 0.16
const DASH_COOLDOWN := 0.58
const MIXED_DASH_COOLDOWN := 0.4
const JUMP_SPEED := 320.0
const GRAVITY := 850.0
const COYOTE_DURATION := 0.1
const JUMP_BUFFER_DURATION := 0.1
const ROOM_LEFT_BOUND := 15.0
const ROOM_RIGHT_BOUND := 7450.0
const PLAYER_MAX_HP := 6.0
const INVULNERABLE_DURATION := 0.95
const HIT_LAUNCH_Y := -135.0
# Swipe: full motion length, cooldown, and the authoritative active window
# expressed in remaining attack time (attack_left). Visual frames are cosmetic.
const SWIPE_DURATION := 0.30
const SWIPE_COOLDOWN := 0.36
const SWIPE_ACTIVE_LATE := 0.23
const SWIPE_ACTIVE_EARLY := 0.08
const SWIPE_BASE_REACH := 42.0
const SWIPE_ARC_RANK1_REACH := 66.0
const SWIPE_ARC_REACH_PER_RANK := 6.0
const SWIPE_DAMAGE := 1.0
const SWIPE_KNOCKBACK := 10.0
const SWIPE_HITBOX_PAD := 14.0
const SWIPE_BACK_ALLOW := -10.0
const SWIPE_HIT_HEIGHT := 43.0
# Searing Claws burn: applied duration grows per rank; ticks are fixed timing.
const BURN_BASE_DURATION := 1.7
const BURN_DURATION_PER_RANK := 0.5
const BURN_TICK_INTERVAL := 0.7
const BURN_TICK_DAMAGE := 1.0
# Ember easy (lunge) and medium (charge) enemies. Temp art is sufficient;
# these timings are what make warnings readable and recoveries punishable.
const EASY_HP := 3.0
const EASY_APPROACH_SPEED := 40.0
const EASY_TRIGGER_RANGE := 72.0
const EASY_WARN_DURATION := 0.72
const EASY_LUNGE_SPEED := 140.0
const EASY_LUNGE_DURATION := 0.22
const EASY_RECOVER_DURATION := 0.95
const EASY_DAMAGE := 1.0
const EASY_NUMEN := 1
const MEDIUM_HP := 6.0
const MEDIUM_APPROACH_SPEED := 30.0
const MEDIUM_TRIGGER_RANGE := 72.0
const MEDIUM_WARN_DURATION := 0.95
const MEDIUM_LUNGE_SPEED := 200.0
const MEDIUM_LUNGE_DURATION := 0.32
const MEDIUM_RECOVER_DURATION := 1.35
const MEDIUM_DAMAGE := 2.0
const MEDIUM_NUMEN := 2
const ENEMY_LEASH_RANGE := 240.0
const ENEMY_CONTACT_RANGE := 25.0
const ENEMY_MIN_X := 145.0
const ENEMY_MAX_X := 615.0
const ENEMY_HIT_FLASH := 0.12
# Session pacing around the single-room Ember encounter.
const CHECKPOINT_RETRY_DISTANCE := 45.0
const CHOICE_DELAY := 0.65
const WAVE_WAIT_AFTER_KILL := 1.2
const WAVE_WAIT_AFTER_CHOICE := 0.8
const WAVE_WAIT_INITIAL := 0.6
const PARTICLE_LIFETIME := 0.65
# --- Ember section (issue #24) ---
const SECTION_EMBER := 'ember'
const MAX_ACTIVE_THREATS_PER_ROOM := 3
# Checkpoints: entry heal and pre-miniboss heal.
const CHECKPOINT_EMBER_ENTRY := 'ember_entry'
const CHECKPOINT_EMBER_PREBOSS := 'ember_preboss'
const CHECKPOINT_RETRY_RANGE := 55.0
# Miniboss stats (provisional tuning).
# Target a readable 30-60s fight at baseline stats; warning and recovery
# durations remain authoritative regardless of the creature art or frame count.
const MINIBOSS_HP := 16.0
const MINIBOSS_APPROACH_SPEED := 35.0
const MINIBOSS_TRIGGER_RANGE := 120.0
const MINIBOSS_WARN_DURATION := 1.05
const MINIBOSS_SLAM_SPEED := 260.0
const MINIBOSS_SLAM_DURATION := 0.35
const MINIBOSS_SLAM_RECOVER := 1.55
const MINIBOSS_SLAM_DAMAGE := 2.0
const MINIBOSS_FIRE_WAVE_SPEED := 110.0
const MINIBOSS_FIRE_WAVE_DURATION := 1.8
const MINIBOSS_FIRE_WAVE_INTERVAL := 3.5
const MINIBOSS_FIRE_WAVE_DAMAGE := 1.0
const MINIBOSS_FIRE_WAVE_HEIGHT := 30.0
const MINIBOSS_IDLE_TELL := 0.6
const MINIBOSS_IDLE_DURATION := 1.2
const MINIBOSS_NUMEN := 5
# Shrine awakening after miniboss defeat.
const SHRINE_EMBER := 'ember_shrine'
const SHRINE_AWAKEN_DURATION := 1.5
# Section objective ID for later world assembly.
const SECTION_OBJECTIVE_EMBER := 'objective_ember'
# Influence-site connection points (stable IDs, not positions).
const INFLUENCE_SLOTS := ['slot_a', 'slot_b']

# Storm section: charged straight shots and medium relocation before aimed shots.
const SECTION_STORM := 'storm'
const STORM_SHOT_TRIGGER_RANGE := 230.0
const STORM_EASY_CHARGE := 0.85
const STORM_MEDIUM_RELOCATE_TIME := 0.42
const STORM_MEDIUM_AIM_TIME := 0.8
const STORM_EASY_RECOVER := 1.0
const STORM_MEDIUM_RECOVER := 1.3
const STORM_RELOCATE_DISTANCE := 75.0
const STORM_RELOCATE_SPEED := 180.0
const STORM_SHOT_SPEED := 210.0
const STORM_SHOT_LIFETIME := 2.0
const STORM_SHOT_DAMAGE := 1.0
const STORM_SHOT_RADIUS := 13.0
const STORM_SHOT_HEIGHT := 275.0
const STORM_ENEMY_MIN_X := 2430.0
const STORM_ENEMY_MAX_X := 3510.0
const CHECKPOINT_STORM_ENTRY := 'storm_entry'
const CHECKPOINT_STORM_PREBOSS := 'storm_preboss'
const SHRINE_STORM := 'storm_shrine'
const SECTION_OBJECTIVE_STORM := 'objective_storm'
const STORM_BOSS_HP := 16.0
const STORM_BOSS_IDLE := 0.65
const STORM_BOSS_WARN := 1.25
const STORM_BOSS_ACTIVE := 0.38
const STORM_BOSS_RECOVER := 1.4
const STORM_BOSS_DAMAGE := 2.0
const STORM_BOSS_NUMEN := 5
const STORM_BOSS_LEFT := 3350.0
const STORM_BOSS_LANE_WIDTH := 65.0
const STORM_BOSS_LANE_COUNT := 3
const STORM_BOSS_GROUND_Y := 300.0
const STORM_BOSS_HIT_HEIGHT := 34.0
const STORM_SHRINE_RANGE := 60.0
# Secondary damage never invokes swipe hit effects.
const CHAIN_BASE_REACH := 85.0
const CHAIN_REACH_PER_RANK := 12.0
const CHAIN_BASE_DAMAGE := 1.0
const CHAIN_DAMAGE_PER_RANK := 0.5
const THUNDERBEAT_EVERY_SWIPES := 3
const THUNDERBEAT_BASE_REACH := 75.0
const THUNDERBEAT_REACH_PER_RANK := 12.0
const THUNDERBEAT_BASE_DAMAGE := 1.0
const THUNDERBEAT_DAMAGE_PER_RANK := 0.5
const SECONDARY_CUE_DURATION := 0.22

# Thorn ranged foes and earned secondary effects. All timers and hit spacing
# are gameplay values, independent of presentation frames.
const SECTION_THORN := 'thorn'
const THORN_ENEMY_MIN_X := 3580.0
const THORN_ENEMY_MAX_X := 4710.0
const THORN_TRIGGER_RANGE := 225.0
const THORN_EASY_WARN := 0.8
const THORN_MEDIUM_WARN := 1.05
const THORN_EASY_RECOVER := 1.0
const THORN_MEDIUM_RECOVER := 1.4
const THORN_SHOT_SPEED := 175.0
const THORN_SHOT_LIFETIME := 2.2
const THORN_SHOT_DAMAGE := 1.0
const THORN_SHOT_RADIUS := 11.0
const THORN_SHOT_HEIGHT := 276.0
const THORN_FAN_COUNT := 3
const THORN_FAN_ANGLE := 0.19
const CHECKPOINT_THORN_ENTRY := 'thorn_entry'
const CHECKPOINT_THORN_PREBOSS := 'thorn_preboss'
const SHRINE_THORN := 'thorn_shrine'
const SECTION_OBJECTIVE_THORN := 'objective_thorn'
# Temporary thickets rise from marked lanes; one opening stays clear.
# Baseline swipe alone can finish this provisional 30-60-second encounter.
const THORN_BOSS_HP := 12.0
const THORN_BOSS_IDLE := 0.5
const THORN_BOSS_WARN := 1.1
const THORN_BOSS_ACTIVE := 0.7
const THORN_BOSS_RECOVER := 1.5
const THORN_BOSS_DAMAGE := 1.0
const THORN_BOSS_NUMEN := 5
const THORN_BOSS_LEFT := 4620.0
const THORN_BOSS_LANE_WIDTH := 40.0
const THORN_BOSS_LANE_COUNT := 3
const THORN_BOSS_GROUND_Y := 300.0
const THORN_BOSS_HIT_HEIGHT := 48.0
const THORN_SHRINE_RANGE := 60.0
const BARB_SPEED := 290.0
const BARB_LIFETIME := 0.9
const BARB_RADIUS := 13.0
const BARB_BASE_DAMAGE := 1.0
const BARB_DAMAGE_PER_RANK := 0.5
const BARB_SPAWN_OFFSET := 24.0
const BARB_HEIGHT := 279.0
const BRAMBLE_LIFETIME := 1.1
const BRAMBLE_RADIUS := 33.0
const BRAMBLE_BASE_DAMAGE := 1.0
const BRAMBLE_DAMAGE_PER_RANK := 0.5
const BRAMBLE_SPACING := 34.0
const BRAMBLE_HEIGHT := 295.0

# Stone: the easy foe approaches and swipes; the medium faces its target with
# a frontal guard until its own swipe finishes. Recovery is a fixed opening.
const SECTION_STONE := 'stone'
const STONE_ENEMY_MIN_X := 4790.0
const STONE_ENEMY_MAX_X := 5890.0
const STONE_EASY_HP := 3.0
const STONE_MEDIUM_HP := 6.0
const STONE_EASY_APPROACH_SPEED := 43.0
const STONE_MEDIUM_APPROACH_SPEED := 29.0
const STONE_EASY_TRIGGER_RANGE := 65.0
const STONE_MEDIUM_TRIGGER_RANGE := 75.0
const STONE_EASY_WARN := 0.62
const STONE_MEDIUM_WARN := 0.9
const STONE_EASY_SWIPE_DURATION := 0.26
const STONE_MEDIUM_SWIPE_DURATION := 0.33
const STONE_EASY_RECOVER := 0.78
const STONE_MEDIUM_RECOVER := 1.25
const STONE_EASY_SWIPE_REACH := 43.0
const STONE_MEDIUM_SWIPE_REACH := 52.0
const STONE_EASY_DAMAGE := 1.0
const STONE_MEDIUM_DAMAGE := 2.0
const STONE_GUARD_FRONT_MARGIN := 0.0
# Stone Shrine encounter: a heavy charge pins the Miniboss to the arena wall.
# Its trailing side alone is vulnerable while stuck. All timing and collision
# values are independent of the temporary creature drawing.
const CHECKPOINT_STONE_ENTRY := 'stone_entry'
const CHECKPOINT_STONE_PREBOSS := 'stone_preboss'
const SHRINE_STONE := 'stone_shrine'
const SECTION_OBJECTIVE_STONE := 'objective_stone'
const STONE_BOSS_HP := 16.0
const STONE_BOSS_IDLE := 0.55
const STONE_BOSS_WARN := 1.15
const STONE_BOSS_CHARGE_SPEED := 300.0
const STONE_BOSS_CHARGE_DURATION := 0.65
const STONE_BOSS_STUCK := 1.7
const STONE_BOSS_RECOVER := 0.5
const STONE_BOSS_DAMAGE := 2.0
const STONE_BOSS_NUMEN := 5
const STONE_BOSS_LEFT := 5800.0
const STONE_BOSS_RIGHT := 5940.0
const STONE_BOSS_GROUND_Y := 300.0
const STONE_BOSS_HIT_HEIGHT := 32.0
const STONE_BOSS_CONTACT_RANGE := 25.0
const STONE_BOSS_WEAK_SIDE_MARGIN := 8.0
const STONE_SHRINE_RANGE := 60.0
# Each rank improves both paths, with hard caps below immunity and burst spam.
const STONEHIDE_BASE_REDUCTION := 0.12
const STONEHIDE_REDUCTION_PER_RANK := 0.06
const STONEHIDE_MAX_REDUCTION := 0.54
const REPRISAL_BASE_DAMAGE := 0.75
const REPRISAL_DAMAGE_PER_RANK := 0.25
const REPRISAL_BASE_RADIUS := 47.0
const REPRISAL_RADIUS_PER_RANK := 7.0
const REPRISAL_MAX_RADIUS := 96.0
const REPRISAL_COOLDOWN := 1.15

# Wind movement and enemy combat values are independent of visual playback.
const SLIPSTREAM_REDUCTION_PER_RANK := 0.075
const SLIPSTREAM_MIN_COOLDOWN := 0.18
const AIRBORNE_JUMP_SPEED := 290.0
const AIRBORNE_AIR_ACCELERATION_BASE := 650.0
const AIRBORNE_AIR_ACCELERATION_PER_RANK := 95.0
const AIRBORNE_AIR_STOPPING_BASE := 360.0
const AIRBORNE_AIR_STOPPING_PER_RANK := 65.0
const AIRBORNE_CONTROL_CAP := 1350.0
const SECTION_WIND := 'wind'
const WIND_ENEMY_MIN_X := 6000.0
const WIND_ENEMY_MAX_X := 7160.0
const WIND_EASY_HOVER_HEIGHT := 282.0
const WIND_MEDIUM_CIRCLE_HEIGHT := 252.0
const WIND_ATTACK_HEIGHT := 283.0
const WIND_EASY_APPROACH_SPEED := 65.0
const WIND_MEDIUM_APPROACH_SPEED := 75.0
const WIND_TRIGGER_RANGE := 155.0
const WIND_EASY_WARN := 0.68
const WIND_MEDIUM_WARN := 0.9
const WIND_EASY_SWOOP_SPEED := 175.0
const WIND_MEDIUM_DIVE_SPEED := 235.0
const WIND_EASY_SWOOP_DURATION := 0.32
const WIND_MEDIUM_DIVE_DURATION := 0.43
const WIND_EASY_RECOVER := 0.95
const WIND_MEDIUM_RECOVER := 1.25
const WIND_CONTACT_RANGE := 24.0
const WIND_EASY_DAMAGE := 1.0
const WIND_MEDIUM_DAMAGE := 2.0
const WIND_RETURN_SPEED := 110.0
const WIND_CIRCLE_RADIUS := 82.0
const WIND_CIRCLE_SPEED := 2.2
const WIND_SWIPE_VERTICAL_REACH := 47.0
const CHECKPOINT_WIND_ENTRY := 'wind_entry'
const CHECKPOINT_WIND_PREBOSS := 'wind_preboss'
const SHRINE_WIND := 'wind_shrine'
const SECTION_OBJECTIVE_WIND := 'objective_wind'
const WIND_SHRINE_RANGE := 60.0
# Wind Miniboss combat is tuned independently from temporary presentation.
const WIND_BOSS_HP := 12.0
const WIND_BOSS_NUMEN := 5
const WIND_BOSS_IDLE := 0.45
const WIND_BOSS_SWOOP_WARN := 0.85
const WIND_BOSS_GUST_WARN := 1.1
const WIND_BOSS_SWOOP_ACTIVE := 0.42
const WIND_BOSS_GUST_ACTIVE := 0.65
const WIND_BOSS_SWOOP_RECOVER := 1.35
const WIND_BOSS_GUST_RECOVER := 1.55
const WIND_BOSS_SWOOP_SPEED := 330.0
const WIND_BOSS_DROP_SPEED := 140.0
const WIND_BOSS_SWOOP_DAMAGE := 1.0
const WIND_BOSS_GUST_DAMAGE := 1.0
const WIND_BOSS_GUST_FORCE := 260.0
const WIND_BOSS_GUST_RANGE := 150.0
const WIND_BOSS_GUST_HEIGHT := 55.0
const WIND_BOSS_GROUND_Y := 300.0
const WIND_BOSS_CONTACT_RANGE := 27.0
const WIND_BOSS_CONTACT_HEIGHT := 29.0
const WIND_BOSS_SWOOP_HEIGHT := 280.0
const WIND_BOSS_RECOVERY_HEIGHT := 286.0
const WIND_BOSS_RECOVERY_OFFSET := 35.0
const WIND_BOSS_FACE_MARGIN := 8.0
const WIND_BOSS_LEFT := 7200.0
const WIND_BOSS_RIGHT := 7390.0

static func slipstream_cooldown(rank: int) -> float:
	return maxf(SLIPSTREAM_MIN_COOLDOWN, DASH_COOLDOWN - SLIPSTREAM_REDUCTION_PER_RANK * float(maxi(rank, 0)))

static func airborne_acceleration(rank: int) -> float:
	if rank <= 0:
		return PLAYER_AIR_ACCELERATION
	return minf(AIRBORNE_CONTROL_CAP, AIRBORNE_AIR_ACCELERATION_BASE + AIRBORNE_AIR_ACCELERATION_PER_RANK * float(rank - 1))

static func airborne_stopping(rank: int) -> float:
	if rank <= 0:
		return PLAYER_AIR_STOPPING
	return minf(AIRBORNE_CONTROL_CAP, AIRBORNE_AIR_STOPPING_BASE + AIRBORNE_AIR_STOPPING_PER_RANK * float(rank - 1))

static func stonehide_reduction(rank: int) -> float:
	if rank <= 0:
		return 0.0
	return minf(STONEHIDE_BASE_REDUCTION + STONEHIDE_REDUCTION_PER_RANK * float(rank - 1), STONEHIDE_MAX_REDUCTION)

static func reprisal_damage(rank: int) -> float:
	if rank <= 0:
		return 0.0
	return REPRISAL_BASE_DAMAGE + REPRISAL_DAMAGE_PER_RANK * float(rank - 1)

static func reprisal_radius(rank: int) -> float:
	if rank <= 0:
		return 0.0
	return minf(REPRISAL_BASE_RADIUS + REPRISAL_RADIUS_PER_RANK * float(rank - 1), REPRISAL_MAX_RADIUS)

static func barb_damage(rank: int) -> float:
	return BARB_BASE_DAMAGE + BARB_DAMAGE_PER_RANK * float(maxi(rank - 1, 0))

static func bramble_damage(rank: int) -> float:
	return BRAMBLE_BASE_DAMAGE + BRAMBLE_DAMAGE_PER_RANK * float(maxi(rank - 1, 0))

static func chain_reach(rank: int) -> float:
	return CHAIN_BASE_REACH + CHAIN_REACH_PER_RANK * float(maxi(rank - 1, 0))

static func chain_damage(rank: int) -> float:
	return CHAIN_BASE_DAMAGE + CHAIN_DAMAGE_PER_RANK * float(maxi(rank - 1, 0))

static func thunderbeat_reach(rank: int) -> float:
	return THUNDERBEAT_BASE_REACH + THUNDERBEAT_REACH_PER_RANK * float(maxi(rank - 1, 0))

static func thunderbeat_damage(rank: int) -> float:
	return THUNDERBEAT_BASE_DAMAGE + THUNDERBEAT_DAMAGE_PER_RANK * float(maxi(rank - 1, 0))


## Swipe reach for a given Flame Arc rank (0 = no upgrade).
static func swipe_reach(arc_rank: int) -> float:
	if arc_rank <= 0:
		return SWIPE_BASE_REACH
	return SWIPE_ARC_RANK1_REACH + SWIPE_ARC_REACH_PER_RANK * float(arc_rank - 1)


## Burn duration applied by Searing Claws hits (0 = no ignite).
static func burn_duration(burn_rank: int) -> float:
	if burn_rank <= 0:
		return 0.0
	return BURN_BASE_DURATION + BURN_DURATION_PER_RANK * float(burn_rank)


## True while the remaining swipe time sits inside the damage window.
static func swipe_is_active(attack_left: float) -> bool:
	return attack_left <= SWIPE_ACTIVE_LATE and attack_left > SWIPE_ACTIVE_EARLY


static func warn_duration(medium: bool) -> float:
	return MEDIUM_WARN_DURATION if medium else EASY_WARN_DURATION


static func lunge_duration(medium: bool) -> float:
	return MEDIUM_LUNGE_DURATION if medium else EASY_LUNGE_DURATION


static func lunge_speed(medium: bool) -> float:
	return MEDIUM_LUNGE_SPEED if medium else EASY_LUNGE_SPEED


static func recover_duration(medium: bool) -> float:
	return MEDIUM_RECOVER_DURATION if medium else EASY_RECOVER_DURATION


# --- World connections and shrine influence (issue #40) ---
# Sanctuary hub connects to all five sections.
const SANCTUARY_LEFT := 2000.0
const SANCTUARY_RIGHT := 2400.0
const SANCTUARY_GROUND_Y := 300.0
# Guardian location beneath the sanctuary; unlocked when all 5 shrines are awakened.
const GUARDIAN_LEFT := 2100.0
const GUARDIAN_RIGHT := 2300.0
const GUARDIAN_GROUND_Y := 300.0
const CHECKPOINT_GUARDIAN := 'guardian_entry'
const CHECKPOINT_SANCTUARY := 'sanctuary'
# --- Guardian elemental phase (issue #43) ---
# The final boss's first phase reuses the elemental ideas taught by the five
# section minibosses: Ember ground slam, Storm lightning, Thorn brambles, Stone
# charge, and Wind swoop. Every value below is authoritative gameplay tuning,
# independent of guardian art, animation frame count and effect playback.
const GUARDIAN_HP := 20.0
const GUARDIAN_IDLE := 0.9
const GUARDIAN_TRANSFORM_DURATION := 1.8
const GUARDIAN_HIT_HEIGHT := 44.0
const GUARDIAN_CONTACT_RANGE := 30.0
const GUARDIAN_LANE_WIDTH := 66.0
const GUARDIAN_LANE_COUNT := 3
# Ember ground slam: warned rush toward the player's position.
const GUARDIAN_SLAM_WARN := 1.0
const GUARDIAN_SLAM_ACTIVE := 0.4
const GUARDIAN_SLAM_SPEED := 300.0
const GUARDIAN_SLAM_RECOVER := 1.5
const GUARDIAN_SLAM_DAMAGE := 2.0
# Storm lightning: marked lanes, one unmarked safe lane.
const GUARDIAN_STORM_WARN := 1.15
const GUARDIAN_STORM_ACTIVE := 0.5
const GUARDIAN_STORM_RECOVER := 1.4
const GUARDIAN_STORM_DAMAGE := 2.0
# Thorn brambles: marked lanes, one clear opening.
const GUARDIAN_THORN_WARN := 1.05
const GUARDIAN_THORN_ACTIVE := 0.7
const GUARDIAN_THORN_RECOVER := 1.4
const GUARDIAN_THORN_DAMAGE := 1.5
# Stone charge into a stuck, exposed opening.
const GUARDIAN_STONE_WARN := 1.1
const GUARDIAN_STONE_CHARGE_SPEED := 320.0
const GUARDIAN_STONE_CHARGE_DURATION := 0.7
const GUARDIAN_STONE_STUCK := 1.4
const GUARDIAN_STONE_RECOVER := 0.6
const GUARDIAN_STONE_DAMAGE := 2.0
# Wind swoop that returns within baseline swipe reach.
const GUARDIAN_WIND_WARN := 0.9
const GUARDIAN_WIND_ACTIVE := 0.45
const GUARDIAN_WIND_SPEED := 330.0
const GUARDIAN_WIND_RECOVER := 1.4
const GUARDIAN_WIND_DAMAGE := 1.5
# --- Guardian mirror phase (issue #44) ---
# The copy uses independently tuned attack timings and damage. Player ranks
# may affect visual intensity without proportionally scaling boss power.
const MIRROR_IDLE := 0.6
const MIRROR_WARN := 0.45
const MIRROR_ACTIVE := 0.35
const MIRROR_RECOVER := 0.8
const MIRROR_SLAM_SPEED := 250.0
const MIRROR_SLAM_DAMAGE := 1.5
const MIRROR_STORM_DAMAGE := 1.5
const MIRROR_THORN_DAMAGE := 1.0
const MIRROR_CHARGE_SPEED := 260.0
const MIRROR_CHARGE_DURATION := 0.55
const MIRROR_STUCK := 1.1
const MIRROR_STONE_DAMAGE := 1.5
const MIRROR_SWOOP_SPEED := 270.0
const MIRROR_SWOOP_DAMAGE := 1.0
# Section adjacency map: each section connects to the sanctuary and its neighbors.
const SECTION_CONNECTIONS: Dictionary = {
	'ember': ['sanctuary', 'storm'],
	'storm': ['sanctuary', 'ember', 'thorn'],
	'thorn': ['sanctuary', 'storm', 'stone'],
	'stone': ['sanctuary', 'thorn', 'wind'],
	'wind': ['sanctuary', 'stone'],
}
# Influence sites: two per shrine outside its home section. Each site has a
# position, effect type, and effect-specific parameters. All are independently
# editable without touching gameplay logic.
const INFLUENCE_SITES: Array = [
	# Ember shrines influence Storm: timed vents that damage enemies periodically.
	{'id': 'ember_vent_1', 'shrine': SHRINE_EMBER, 'section': SECTION_STORM, 'x': 2520.0, 'effect': 'vent', 'radius': 60.0, 'damage': 1.0, 'interval': 2.8, 'active_time': 0.6},
	{'id': 'ember_vent_2', 'shrine': SHRINE_EMBER, 'section': SECTION_STORM, 'x': 3100.0, 'effect': 'vent', 'radius': 60.0, 'damage': 1.0, 'interval': 3.4, 'active_time': 0.6},
	# Storm shrines influence Thorn: strikeable conductive bursts.
	{'id': 'storm_burst_1', 'shrine': SHRINE_STORM, 'section': SECTION_THORN, 'x': 3700.0, 'effect': 'burst', 'radius': 80.0, 'damage': 2.0, 'strike_reach': 50.0},
	{'id': 'storm_burst_2', 'shrine': SHRINE_STORM, 'section': SECTION_THORN, 'x': 4350.0, 'effect': 'burst', 'radius': 80.0, 'damage': 2.0, 'strike_reach': 50.0},
	# Thorn shrines influence Stone: bounce plants that launch the player.
	{'id': 'thorn_bounce_1', 'shrine': SHRINE_THORN, 'section': SECTION_STONE, 'x': 4950.0, 'effect': 'bounce', 'bounce_speed': -380.0, 'reach': 30.0},
	{'id': 'thorn_bounce_2', 'shrine': SHRINE_THORN, 'section': SECTION_STONE, 'x': 5450.0, 'effect': 'bounce', 'bounce_speed': -380.0, 'reach': 30.0},
	# Stone shrines influence Wind: cover blocks and stepping platforms.
	{'id': 'stone_cover_1', 'shrine': SHRINE_STONE, 'section': SECTION_WIND, 'x': 6200.0, 'effect': 'cover', 'width': 40.0, 'height': 50.0, 'projectile_block': true},
	{'id': 'stone_cover_2', 'shrine': SHRINE_STONE, 'section': SECTION_WIND, 'x': 6700.0, 'effect': 'cover', 'width': 40.0, 'height': 50.0, 'projectile_block': true},
	# Wind shrines influence Ember: updraft columns that lift the player.
	{'id': 'wind_updraft_1', 'shrine': SHRINE_WIND, 'section': SECTION_EMBER, 'x': 800.0, 'effect': 'updraft', 'force': -280.0, 'width': 50.0, 'height': 200.0},
	{'id': 'wind_updraft_2', 'shrine': SHRINE_WIND, 'section': SECTION_EMBER, 'x': 1400.0, 'effect': 'updraft', 'force': -280.0, 'width': 50.0, 'height': 200.0},
]
# Shrine influence pulse: emitted on awakening to highlight map changes.
const SHRINE_PULSE_DURATION := 2.5
const SHRINE_PULSE_RADIUS := 350.0
# Neighbor visitor spawning near section connections.
const VISITOR_SPAWN_RANGE := 120.0
const VISITOR_MAX := 2

# --- Enemy modifiers (issue #41) ---
# When 3 shrines awaken, the 2 dormant sections become empowered. Every regular
# enemy and remaining miniboss there gets one non-native modifier, uniformly
# among the four elements other than its native element. Modifiers persist
# through death/rest/Continue. Already defeated minibosses stay defeated.
const MODIFIER_ELEMENTS: Array = ['ember', 'storm', 'thorn', 'stone', 'wind']
# Ember modifier: post-attack burn patch — after a successful lunge/swipe, leaves
# a small damaging zone at the impact point.
const MODIFIER_EMBER_PATCH_DURATION := 1.2
const MODIFIER_EMBER_PATCH_RADIUS := 28.0
const MODIFIER_EMBER_PATCH_INTERVAL := 0.35
const MODIFIER_EMBER_PATCH_DAMAGE := 0.5
const MODIFIER_EMBER_PATCH_WARN := 0.45
# Storm modifier: occasional short pulse — periodic radial burst that damages
# the player if too close.
const MODIFIER_STORM_PULSE_INTERVAL := 3.8
const MODIFIER_STORM_PULSE_RADIUS := 55.0
const MODIFIER_STORM_PULSE_DAMAGE := 1.0
const MODIFIER_STORM_PULSE_WARN := 0.6
# Thorn modifier: delayed shot — fires a single projectile after a longer delay
# than the native Thorn attack.
const MODIFIER_THORN_DELAY := 1.1
const MODIFIER_THORN_SHOT_SPEED := 155.0
const MODIFIER_THORN_SHOT_LIFETIME := 2.0
const MODIFIER_THORN_SHOT_DAMAGE := 1.0
const MODIFIER_THORN_SHOT_RADIUS := 11.0
# Stone modifier: periodic reduced-damage one-hit guard — every few seconds the
# enemy gains a frontal guard that blocks one hit, then breaks.
const MODIFIER_STONE_GUARD_INTERVAL := 5.0
const MODIFIER_STONE_GUARD_DURATION := 2.5
const MODIFIER_STONE_GUARD_BREAK_RECOVER := 0.8
# Wind modifier: occasional repositioning hop — periodically jumps to a new
# position near the player, briefly airborne.
const MODIFIER_WIND_HOP_INTERVAL := 4.2
const MODIFIER_WIND_HOP_SPEED := 220.0
const MODIFIER_WIND_HOP_HEIGHT := 120.0
const MODIFIER_WIND_HOP_DURATION := 0.35
