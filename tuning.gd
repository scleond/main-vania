extends RefCounted
## Central gameplay tuning for the Ember combat slice (issue #20).
##
## This is the authoritative source for swipe timing, reach, damage, burn,
## knockback, and enemy warning/recovery behavior. player.gd and main.gd read
## these values; visual.gd (presentation) must never change them. Animation
## frame counts and playback speeds do not trigger or determine damage windows.
const PLAYER_MOVE_SPEED := 115.0
const PLAYER_DASH_SPEED := 340.0
const DASH_DURATION := 0.13
const DASH_COOLDOWN := 0.65
const MIXED_DASH_COOLDOWN := 0.4
const JUMP_SPEED := 310.0
const GRAVITY := 850.0
const COYOTE_DURATION := 0.1
const JUMP_BUFFER_DURATION := 0.1
const ROOM_LEFT_BOUND := 15.0
const ROOM_RIGHT_BOUND := 625.0
const PLAYER_MAX_HP := 6.0
const INVULNERABLE_DURATION := 0.85
const HIT_LAUNCH_Y := -135.0
# Swipe: full motion length, cooldown, and the authoritative active window
# expressed in remaining attack time (attack_left). Visual frames are cosmetic.
const SWIPE_DURATION := 0.26
const SWIPE_COOLDOWN := 0.38
const SWIPE_ACTIVE_LATE := 0.22
const SWIPE_ACTIVE_EARLY := 0.07
const SWIPE_BASE_REACH := 38.0
const SWIPE_ARC_RANK1_REACH := 58.0
const SWIPE_ARC_REACH_PER_RANK := 6.0
const SWIPE_DAMAGE := 1.0
const SWIPE_KNOCKBACK := 7.0
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
const EASY_WARN_DURATION := 0.65
const EASY_LUNGE_SPEED := 140.0
const EASY_LUNGE_DURATION := 0.22
const EASY_RECOVER_DURATION := 0.85
const EASY_DAMAGE := 1.0
const EASY_NUMEN := 1
const MEDIUM_HP := 6.0
const MEDIUM_APPROACH_SPEED := 30.0
const MEDIUM_TRIGGER_RANGE := 72.0
const MEDIUM_WARN_DURATION := 0.85
const MEDIUM_LUNGE_SPEED := 200.0
const MEDIUM_LUNGE_DURATION := 0.32
const MEDIUM_RECOVER_DURATION := 1.25
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
