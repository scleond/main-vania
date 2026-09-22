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
const ROOM_RIGHT_BOUND := 5890.0
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
	return attack_left < SWIPE_ACTIVE_LATE and attack_left > SWIPE_ACTIVE_EARLY


static func warn_duration(medium: bool) -> float:
	return MEDIUM_WARN_DURATION if medium else EASY_WARN_DURATION


static func lunge_duration(medium: bool) -> float:
	return MEDIUM_LUNGE_DURATION if medium else EASY_LUNGE_DURATION


static func lunge_speed(medium: bool) -> float:
	return MEDIUM_LUNGE_SPEED if medium else EASY_LUNGE_SPEED


static func recover_duration(medium: bool) -> float:
	return MEDIUM_RECOVER_DURATION if medium else EASY_RECOVER_DURATION
