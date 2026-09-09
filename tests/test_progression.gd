extends SceneTree
## Focused progression-rule cases for issue #20.
## Run: godot --headless --path . --script tests/test_progression.gd
## Covers dominance, tied-leader choice, typed overflow, repeated selection,
## Fully evolved, the full threshold ladder, catalog gating, and tuning sanity.
## Multi-element fixtures exercise the shared model without implying later
## elements are playable (session offers stay Ember-gated).
var Progression = load('res://progression.gd')
var Tuning = load('res://tuning.gd')
var failures := 0
var checks := 0

func check(name, cond, detail = ''):
	checks += 1
	if cond:
		print('PASS: ', name)
	else:
		failures += 1
		printerr('FAIL: ', name, ' :: ', detail)

func fresh():
	return Progression.new()

func earn_to(p, total):
	# Earn ember souls until lifetime reaches total (test helper only).
	while p.lifetime < total:
		p.earn('ember', 1)

func _initialize():
	# --- Threshold ladder and window requirements ---
	var p = fresh()
	check('initial threshold is 8', p.next_threshold() == 8, str(p.next_threshold()))
	check('initial requirement is 8', p.window_requirement() == 8, str(p.window_requirement()))
	p.earn('ember', 8)
	check('8 souls unlock one level-up', p.pending_level_ups() == 1, str(p.pending_level_ups()))
	check('offer is Ember paths', p.offer()['kind'] == 'paths' and p.offer()['element'] == 'ember', str(p.offer()))
	check('select searing_claws', p.select_path('searing_claws'), 'rejected')
	check('selection consumed, window empty', p.window_total() == 0 and p.pending_level_ups() == 0, '%d/%d' % [p.window_total(), p.pending_level_ups()])
	check('second requirement is 6 (14-8)', p.window_requirement() == 6, str(p.window_requirement()))
	check('rank recorded', p.rank_of('searing_claws') == 1, str(p.rank_of('searing_claws')))

	# --- Dominance: 5 Ember + 3 Stone offers Ember paths ---
	p = fresh()
	p.earn('ember', 5)
	p.earn('stone', 3)
	check('dominant element is ember', p.dominant_elements() == ['ember'], str(p.dominant_elements()))
	check('typed counts preserved', p.window_counts()['ember'] == 5 and p.window_counts()['stone'] == 3, str(p.window_counts()))

	# --- Tied leaders: 4 Ember / 4 Wind asks which element first ---
	p = fresh()
	p.earn('ember', 4)
	p.earn('wind', 4)
	var tied_offer = p.offer()
	check('tie offers element choice', tied_offer['kind'] == 'elements', str(tied_offer))
	check('tie lists both leaders', tied_offer['elements'].has('ember') and tied_offer['elements'].has('wind'), str(tied_offer))
	check('path pick blocked before element choice', not p.select_path('searing_claws'), 'allowed too early')
	check('unknown element rejected', not p.choose_element('storm'), 'accepted outsider')
	check('choose ember leader', p.choose_element('ember'), 'rejected')
	var after = p.offer()
	check('element choice resolves to Ember paths', after['kind'] == 'paths' and after['element'] == 'ember' and after['paths'].size() == 2, str(after))
	check('cross-element path rejected', not p.select_path('slipstream'), 'allowed wind path for ember')
	check('select searing after tie-break', p.select_path('searing_claws'), 'rejected')
	check('tie-break consumed 8, kept 0 typed of 8-window', p.window_total() == 0, str(p.window_total()))

	# --- Typed overflow: 7 counted + 3 reward consumes 8, carries 2 typed ---
	p = fresh()
	p.earn('ember', 7)
	check('no level-up at 7', p.pending_level_ups() == 0, str(p.pending_level_ups()))
	p.earn('ember', 3)
	check('overflow still one level-up', p.pending_level_ups() == 1, str(p.pending_level_ups()))
	check('select flame_arc', p.select_path('flame_arc'), 'rejected')
	check('overflow carries 2 typed ember', p.window_total() == 2 and p.window_counts()['ember'] == 2, str(p.window_counts()))
	check('next window needs 6', p.window_requirement() == 6, str(p.window_requirement()))

	# --- Mixed overflow keeps elements: storm souls survive consumption order ---
	p = fresh()
	p.earn('storm', 5)
	p.earn('ember', 3)
	check('mixed window totals 8', p.window_total() == 8, str(p.window_total()))
	check('storm-led fixture offers storm paths at rule level', p.offer()['element'] == 'storm', str(p.offer()))
	check('session withholds not-yet-playable storm', p.session_offer()['kind'] == 'withheld', str(p.session_offer()))

	# --- Repeated selection: same path to rank 8 stays legal, both stay open ---
	p = fresh()
	var ladder_ok := true
	for i in range(7):
		earn_to(p, int(Progression.THRESHOLDS[i]))
		if p.pending_level_ups() != 1:
			ladder_ok = false
		if not p.select_path('flame_arc'):
			ladder_ok = false
	check('ladder earns 7 selections on one path', ladder_ok and p.rank_of('flame_arc') == 7, 'rank=%d' % p.rank_of('flame_arc'))
	var pre_cap = p.offer()
	earn_to(p, 42)
	check('both paths offered before cap', p.offer()['kind'] == 'paths' and p.offer()['paths'].size() == 2, str(pre_cap))
	check('8th selection on same path allowed', p.select_path('flame_arc'), 'rejected')
	check('eight selections in one path possible', p.rank_of('flame_arc') == 8 and p.selections == 8, 'rank=%d sel=%d' % [p.rank_of('flame_arc'), p.selections])

	# --- Fully evolved: cap stops accumulation, offers end ---
	check('fully evolved at 8', p.is_fully_evolved(), 'not evolved')
	check('no next threshold at cap', p.next_threshold() == -1, str(p.next_threshold()))
	var frozen = p.window_total()
	p.earn('ember', 5)
	check('no souls accumulate at cap', p.window_total() == frozen and p.pending_level_ups() == 0, '%d/%d' % [p.window_total(), p.pending_level_ups()])
	check('offer none at cap', p.offer()['kind'] == 'none', str(p.offer()))
	check('select rejected at cap', not p.select_path('searing_claws'), 'allowed over cap')

	# --- Catalog: extensible, ten paths, session gates to Ember ---
	check('catalog holds ten paths', Progression.PATH_CATALOG.size() == 10, str(Progression.PATH_CATALOG.size()))
	var elements_seen := {}
	for path_id in Progression.PATH_CATALOG:
		elements_seen[Progression.PATH_CATALOG[path_id]['element']] = true
	check('catalog spans five elements', elements_seen.size() == 5, str(elements_seen))
	p = fresh()
	p.earn('ember', 8)
	check('session offers Ember paths live', p.session_offer()['kind'] == 'paths' and p.session_offer()['paths'].size() == 2, str(p.session_offer()))

	# --- Reset restores a fresh earning window (new session boundary) ---
	p.reset()
	check('reset clears window/ranks/selections', p.window_total() == 0 and p.selections == 0 and p.rank_of('flame_arc') == 0, 'dirty')

	# --- Tuning sanity: windows, growth, readable enemy timings ---
	check('swipe window ordered', Tuning.SWIPE_ACTIVE_LATE > Tuning.SWIPE_ACTIVE_EARLY, 'inverted')
	check('swipe active inside window', Tuning.swipe_is_active(0.15) and not Tuning.swipe_is_active(0.25) and not Tuning.swipe_is_active(0.02), 'window wrong')
	check('no-arc reach is base 38', Tuning.swipe_reach(0) == 38.0, str(Tuning.swipe_reach(0)))
	check('rank-1 arc reach is 58', Tuning.swipe_reach(1) == 58.0, str(Tuning.swipe_reach(1)))
	check('arc reach grows per rank', Tuning.swipe_reach(8) > Tuning.swipe_reach(1), str(Tuning.swipe_reach(8)))
	check('rank-1 burn is 2.2s', Tuning.burn_duration(1) == 2.2, str(Tuning.burn_duration(1)))
	check('burn grows per rank', Tuning.burn_duration(8) > Tuning.burn_duration(1), str(Tuning.burn_duration(8)))
	check('no-claws means no ignite', Tuning.burn_duration(0) == 0.0, str(Tuning.burn_duration(0)))
	check('warn/recover readable', Tuning.EASY_WARN_DURATION > 0.0 and Tuning.MEDIUM_WARN_DURATION > Tuning.EASY_WARN_DURATION and Tuning.MEDIUM_RECOVER_DURATION > Tuning.EASY_RECOVER_DURATION, 'timings')
	check('medium worth two souls, easy one', Tuning.MEDIUM_SOULS == 2 and Tuning.EASY_SOULS == 1, 'rewards')
	check('threshold ladder exact', Progression.THRESHOLDS == [8, 14, 20, 26, 30, 34, 38, 42] and Progression.SELECTION_CAP == 8, 'ladder')

	# --- Presentation separation: alternate swipe set differs in frame count ---
	var Visual = load('res://visual.gd')
	var visual = Visual.new()
	check('alternate swipe uses fewer frames', visual.swipe_boxes_alt.size() == 2 and visual.swipe_boxes.size() == 4, '%d/%d' % [visual.swipe_boxes_alt.size(), visual.swipe_boxes.size()])
	visual.free()

	print('---')
	print('checks: %d failures: %d' % [checks, failures])
	if failures > 0:
		printerr('PROGRESSION TESTS FAILED')
		quit(1)
	else:
		print('ALL PROGRESSION TESTS PASSED')
		quit(0)
