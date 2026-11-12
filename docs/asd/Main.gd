extends Node2D
## CONTROLADOR PRINCIPAL: LASAGNA DEFENSE CON PERSISTENCIA DE DATOS (JSON)

# region 1. CONSTANTES Y CONFIGURACIÓN
const WIDTH := 1280.0
const HEIGHT := 720.0
const GROUND_Y := 570.0
const ALLY_START := 230.0
const ENEMY_START := 1060.0
const MAX_BASE_HP := 120
const POPULATION_LIMIT := 40
const TOWER_LIMIT := 3
const BASE_INCOME_PER_SECOND := 1
const MARA_RESPAWN_COST := 10 
const MARA_RESPAWN_DELAY := 30.0
# endregion

# region 2. ESTADO GLOBAL, PERSISTENCIA Y VARIABLES DE JUEGO
var state := "login" # Flujo: login -> global_menu -> difficulty_menu -> playing -> victory/defeat
var paused := false

# Datos de Cuenta y Persistencia (Save System)
var login_user := ""
var login_pass := ""
var active_login_field := "user"
var login_error := ""

var donas_doradas := 0
var global_upgrades := {"hero": 0, "troops": 0, "towers": 0} # Máximo nivel 5 por cada uno

# Variables de Instancia de Nivel
var legs := 8
var enemy_legs := 8
var ally_base_hp := MAX_BASE_HP
var enemy_base_hp := MAX_BASE_HP
var income_clock := 0.0
var enemy_decision_clock := 0.0
var enemy_build_clock := 0.0
var mara_respawn_clock := 0.0
var game_time_elapsed := 0.0 
var farm_count := 0 
const MAX_FARMS := 5
var difficulty_multiplier := 1.0 

var player_builds: Dictionary = {}
var enemy_build_queue: Array[String] = []
var active_menu := "units"
var message_log: Array[Dictionary] = []

var heroes: Array[Dictionary] = []
var allies: Array[Dictionary] = []
var enemies: Array[Dictionary] = []
var bolts: Array[Dictionary] = []
var player_towers: Array[Dictionary] = []
var enemy_towers: Array[Dictionary] = []
var tower_shots: Array[Dictionary] = []
var selected_tower_index := -1

func push_message(text: String) -> void:
	if not message_log.is_empty() and message_log[0].text == text and message_log[0].time > 3.5:
		message_log[0].time = 4.0; return
	message_log.push_front({"text": text, "time": 4.0})
	if message_log.size() > 3: message_log.pop_back()
# endregion

# region 3. SISTEMA DE GUARDADO (LOCAL JSON DB)
func save_game() -> void:
	var data = {
		"password": login_pass,
		"donas": donas_doradas,
		"upgrades": global_upgrades
	}
	var file = FileAccess.open("user://save_" + login_user + ".json", FileAccess.WRITE)
	file.store_string(JSON.stringify(data))

func attempt_login() -> void:
	if login_user.strip_edges() == "" or login_pass.strip_edges() == "":
		login_error = "Completá ambos campos"; return
		
	var path = "user://save_" + login_user + ".json"
	if FileAccess.file_exists(path):
		var file = FileAccess.open(path, FileAccess.READ)
		var data = JSON.parse_string(file.get_as_text())
		if data.has("password") and data.password == login_pass:
			donas_doradas = data.donas
			global_upgrades = data.upgrades
			login_error = ""
			state = "global_menu"
		else:
			login_error = "Contraseña incorrecta para el usuario"
	else:
		# Crea cuenta nueva
		donas_doradas = 0
		global_upgrades = {"hero": 0, "troops": 0, "towers": 0}
		save_game()
		state = "global_menu"
# endregion

# region 4. CICLO PRINCIPAL (CORE LOOP)
func _ready() -> void:
	queue_redraw()

func start_level() -> void:
	legs = 8; enemy_legs = int(8 * difficulty_multiplier)
	ally_base_hp = MAX_BASE_HP; enemy_base_hp = int(MAX_BASE_HP * difficulty_multiplier)
	farm_count = 0; game_time_elapsed = 0.0
	heroes.clear(); allies.clear(); enemies.clear()
	player_towers.clear(); enemy_towers.clear(); bolts.clear(); tower_shots.clear()
	player_builds.clear(); enemy_build_queue.clear()
	message_log.clear()
	
	spawn_hero()
	player_towers.append(make_tower("pepper", 0))
	enemy_towers.append(make_tower("pepper", 0))
	push_message("Hold the pantry!")
	state = "playing"

func _process(delta: float) -> void:
	game_time_elapsed += delta 
	
	if state != "playing" or paused:
		queue_redraw(); return
		
	for i in range(message_log.size() - 1, -1, -1):
		message_log[i].time -= delta
		if message_log[i].time <= 0: message_log.remove_at(i)
		
	income_clock += delta; enemy_decision_clock += delta
	if mara_respawn_clock > 0.0: mara_respawn_clock = max(0.0, mara_respawn_clock - delta)
		
	if income_clock >= 1.0:
		income_clock -= 1.0
		var income: int = BASE_INCOME_PER_SECOND + farm_count
		var enemy_income: int = max(1, int((BASE_INCOME_PER_SECOND + int(game_time_elapsed / 45.0)) * difficulty_multiplier))
		legs += income; enemy_legs += enemy_income
		
	if enemy_decision_clock >= 1.5: 
		enemy_decision_clock = 0.0; enemy_recruit()
		
	update_recruitment(delta)
	update_hero(delta); update_allies(delta); update_enemies(delta)
	update_towers(delta); update_bolts(delta)
	cleanup()
	
	if ally_base_hp <= 0:
		state = "defeat"
	elif enemy_base_hp <= 0:
		state = "victory"
		# Calculo de Donas Doradas por victoria
		var donas_ganadas = int(50 * difficulty_multiplier + (ally_base_hp * 0.5))
		donas_doradas += donas_ganadas
		save_game() # Persistimos la ganancia
		push_message("¡Ganaste %d Donas Doradas!" % donas_ganadas)
		
	queue_redraw()
# endregion

# region 5. LÓGICA DE ENTIDADES (CON MEJORAS GLOBALES APLICADAS)
func update_hero(delta: float) -> void:
	if heroes.is_empty(): return
	var h := heroes[0]
	h.x = clamp(h.x + Input.get_axis("ui_left", "ui_right") * 180.0 * delta, 170.0, 1180.0)
	h.cooldown = max(0.0, h.cooldown - delta); h.slash = max(0.0, h.slash - delta)
	if Input.is_action_just_pressed("ui_accept") and h.cooldown <= 0.0:
		h.cooldown = 0.75; h.slash = 0.18
		# Daño del héroe escalado con mejoras globales
		var dmg = 28.0 + (global_upgrades["hero"] * 12.0)
		for e in enemies:
			if abs(e.x - h.x) < 95.0: e.hp -= dmg
		push_message("Mara's skillet swing!")
	heroes[0] = h

func update_allies(delta: float) -> void:
	for a in allies:
		a.cooldown = max(0.0, a.cooldown - delta)
		var target: Dictionary = nearest_enemy(a.x)
		if not target.is_empty() and abs(target.x - a.x) <= a.range + 20.0:
			if a.cooldown <= 0.0:
				target.hp -= a.damage; a.cooldown = a.attack_cooldown
				bolts.append({"x": a.x + 16.0, "target_x": target.x, "life": 0.16, "color": a.color})
		elif target.is_empty():
			if a.x < 1065.0: a.x += a.speed * delta
		else:
			a.x += a.speed * delta
		if a.x >= 1055.0 and a.cooldown <= 0.0:
			enemy_base_hp -= int(a.damage); a.cooldown = 0.8

func update_enemies(delta: float) -> void:
	for e in enemies:
		e.cooldown = max(0.0, e.cooldown - delta)
		var target: Dictionary = nearest_ally(e.x)
		var hero: Dictionary = heroes[0] if not heroes.is_empty() else {}
		if not hero.is_empty() and abs(e.x - hero.x) < 150.0:
			if abs(e.x - hero.x) < 40.0:
				if e.cooldown <= 0.0: hero.hp -= e.damage; e.cooldown = 0.8; heroes[0] = hero
			else:
				e.x += sign(hero.x - e.x) * e.speed * delta
		elif not target.is_empty() and abs(e.x - target.x) < 34.0:
			if e.cooldown <= 0.0: target.hp -= e.damage; e.cooldown = 0.8
		else:
			e.x -= e.speed * delta
		if e.x < 140.0 and e.cooldown <= 0.0: ally_base_hp -= int(e.damage); e.cooldown = 0.9

func update_bolts(delta: float) -> void:
	for b in bolts: b.life -= delta
	for shot in tower_shots: shot.life -= delta

func update_towers(delta: float) -> void:
	for tower in player_towers:
		tower.cooldown = max(0.0, tower.cooldown - delta)
		var origin: Vector2 = tower_position(tower, true); var target: Dictionary = nearest_enemy(origin.x)
		if tower.priority == "strongest":
			var highest_hp: float = -1.0
			for candidate in enemies:
				if abs(candidate.x - origin.x) <= tower.range and candidate.hp > highest_hp:
					target = candidate; highest_hp = candidate.hp
		if not target.is_empty() and abs(target.x - origin.x) <= tower.range and tower.cooldown <= 0.0:
			target.hp -= tower.damage; tower.cooldown = tower.cooldown_time
			tower_shots.append({"from": origin, "to": Vector2(target.x, GROUND_Y - 45), "life": 0.12, "color": tower.color})
	for tower in enemy_towers:
		tower.cooldown = max(0.0, tower.cooldown - delta)
		var origin: Vector2 = tower_position(tower, false); var hero: Dictionary = heroes[0] if not heroes.is_empty() else {}
		var target: Dictionary = nearest_ally(origin.x); var target_position := Vector2.ZERO
		if not hero.is_empty() and abs(hero.x - origin.x) <= tower.range:
			target = hero; target_position = Vector2(hero.x, GROUND_Y - 55)
		elif not target.is_empty(): target_position = Vector2(target.x, GROUND_Y - 45)
		if not target.is_empty() and abs(target.x - origin.x) <= tower.range and tower.cooldown <= 0.0:
			target.hp -= tower.damage; tower.cooldown = tower.cooldown_time
			if not hero.is_empty() and target == hero: heroes[0] = hero
			tower_shots.append({"from": origin, "to": target_position, "life": 0.12, "color": tower.color})

func cleanup() -> void:
	allies = allies.filter(func(a): return a.hp > 0.0)
	enemies = enemies.filter(func(e): return e.hp > 0.0)
	bolts = bolts.filter(func(b): return b.life > 0.0)
	tower_shots = tower_shots.filter(func(shot): return shot.life > 0.0)
	if not heroes.is_empty() and heroes[0].hp <= 0.0:
		heroes.clear(); mara_respawn_clock = MARA_RESPAWN_DELAY
		push_message("Mara is down. Respawn unlocks in 30 seconds.")
# endregion

# region 6. SISTEMAS DE SPAWN Y COMPRAS
func spawn_hero() -> void:
	var hero_hp = 85.0 + (global_upgrades["hero"] * 25.0) # Vida escalada
	heroes.append({"x": 300.0, "hp": hero_hp, "max_hp": hero_hp, "cooldown": 0.0, "slash": 0.0})

func farm_cost() -> int: return 15 + (farm_count * 10)

func buy_farm() -> void:
	if state != "playing" or paused: return
	if farm_count >= MAX_FARMS: push_message("Max farms reached (5)"); return
	var cost = farm_cost()
	if legs < cost: push_message("Need %d legs for a farm" % cost); return
	legs -= cost; farm_count += 1
	push_message("Farm built! Income: +%d/s" % (BASE_INCOME_PER_SECOND + farm_count))

func tower_info(kind: String) -> Dictionary:
	var mult = 1.0 + (global_upgrades["towers"] * 0.25) # Mejoras globales de torre
	if kind == "kettle": return {"name": "Kettle Arc", "cost": 12, "damage": 18.0 * mult, "range": 315.0, "cooldown": 1.35, "color": Color("#9c72c7")}
	return {"name": "Pepper Popper", "cost": 7, "damage": 9.0 * mult, "range": 245.0, "cooldown": 0.68, "color": Color("#dc7858")}

func make_tower(kind: String, slot: int) -> Dictionary:
	var info = tower_info(kind)
	return {"kind": kind, "slot": slot, "cost": info.cost, "damage": info.damage, "range": info.range, "cooldown_time": info.cooldown, "cooldown": 0.0, "color": info.color, "level": 1, "priority": "nearest"}

func tower_position(tower: Dictionary, friendly: bool) -> Vector2: return Vector2(78.0 + tower.slot * 29.0 if friendly else 1178.0 - tower.slot * 29.0, 294.0)

func build_tower(kind: String) -> void:
	if state != "playing" or paused: return
	if player_towers.size() >= TOWER_LIMIT: push_message("Tower limit reached (3)"); return
	var info = tower_info(kind)
	if legs < info.cost: push_message("Need %d chicken legs" % info.cost); return
	legs -= info.cost; player_towers.append(make_tower(kind, player_towers.size()))
	push_message("%s built" % info.name)

func sell_tower(index: int) -> void:
	if index < 0 or index >= player_towers.size(): return
	var tower = player_towers[index]; var refund = roundi(tower.cost * 0.25)
	legs += refund; player_towers.remove_at(index); selected_tower_index = -1
	for i in player_towers.size(): player_towers[i].slot = i
	push_message("%s sold for %d chicken legs" % [tower_info(tower.kind).name, refund])

func tower_upgrade_cost(tower: Dictionary) -> int: return roundi(tower.cost * 0.75) if tower.level == 1 else roundi(tower.cost * 1.2)

func upgrade_selected_tower() -> void:
	if selected_tower_index < 0 or selected_tower_index >= player_towers.size(): push_message("Select one of your towers first"); return
	var tower = player_towers[selected_tower_index]
	if tower.level >= 3: push_message("That tower is already level 3"); return
	var cost = tower_upgrade_cost(tower)
	if legs < cost: push_message("Need %d chicken legs to upgrade" % cost); return
	legs -= cost; tower.level += 1
	tower.damage *= 1.35; tower.range += 35.0; tower.cooldown_time *= 0.90
	push_message("%s upgraded to level %d" % [tower_info(tower.kind).name, tower.level])

func cycle_selected_tower_priority() -> void:
	if selected_tower_index < 0 or selected_tower_index >= player_towers.size(): push_message("Select one of your towers first"); return
	var tower = player_towers[selected_tower_index]
	tower.priority = "strongest" if tower.priority == "nearest" else "nearest"
	push_message("Tower priority: %s" % tower.priority)

func spawn_ally(kind: String) -> void:
	if state != "playing" or paused: return
	var cost := 3 if kind == "fork" else (6 if kind == "roller" else 5)
	if allies.size() + player_builds.size() >= POPULATION_LIMIT: push_message("Population limit reached (40)"); return
	if player_builds.has(kind): push_message("Unit is already being prepared"); return
	if legs < cost: push_message("Need %d chicken legs" % cost); return
	legs -= cost; player_builds[kind] = 0.0
	push_message("Preparing unit...")

func finish_player_unit(kind: String) -> void:
	var mult = 1.0 + (global_upgrades["troops"] * 0.2) # Mejoras globales de tropas
	var hp: float = (34.0 if kind == "fork" else (76.0 if kind == "roller" else 25.0)) * mult
	var damage: float = (9.0 if kind == "fork" else (13.0 if kind == "roller" else 7.0)) * mult
	var speed: float = 48.0 if kind == "fork" else (24.0 if kind == "roller" else 34.0)
	var reach: float = 32.0 if kind == "fork" else (40.0 if kind == "roller" else 200.0)
	var color: Color = Color("#77d4ef") if kind == "fork" else (Color("#f5a75b") if kind == "roller" else Color("#83cb83"))
	var attack_cooldown: float = 1.05 if kind == "archer" else 0.75
	allies.append({"x": ALLY_START, "hp": hp, "max_hp": hp, "damage": damage, "speed": speed, "range": reach, "cooldown": 0.1, "attack_cooldown": attack_cooldown, "color": color, "kind": kind})

func finish_enemy_unit(kind: String) -> void:
	var tough: bool = kind == "ladle"
	var hp: float = (32.0 if not tough else 76.0) * difficulty_multiplier
	var damage: float = (8.0 if not tough else 13.0) * difficulty_multiplier
	enemies.append({"x": ENEMY_START, "hp": hp, "max_hp": hp, "damage": damage, "speed": 42.0 if not tough else 23.0, "cooldown": 0.4, "tough": tough, "kind": kind})

func update_recruitment(delta: float) -> void:
	for kind_variant in player_builds.keys():
		var kind: String = str(kind_variant)
		var build_time: float = 0.72 if kind == "fork" else (1.25 if kind == "roller" else 0.95)
		var elapsed: float = player_builds[kind] + delta
		if elapsed >= build_time:
			player_builds.erase(kind); finish_player_unit(kind)
		else: player_builds[kind] = elapsed
	if not enemy_build_queue.is_empty():
		enemy_build_clock += delta
		if enemy_build_clock >= 0.85: enemy_build_clock = 0.0; finish_enemy_unit(enemy_build_queue.pop_front())

func enemy_recruit() -> void:
	if enemies.size() + enemy_build_queue.size() >= POPULATION_LIMIT: return
	var kind: String = "spoon"; var cost: int = 3
	if enemy_legs >= 6 and enemies.size() % 3 == 2: kind = "ladle"; cost = 6
	if enemy_legs >= cost: enemy_legs -= cost; enemy_build_queue.append(kind)

func nearest_enemy(x: float) -> Dictionary:
	var best: Dictionary = {}; var distance: float = INF
	for e in enemies:
		if e.x >= x and e.x - x < distance: best = e; distance = e.x - x
	return best

func nearest_ally(x: float) -> Dictionary:
	var best: Dictionary = {}; var distance: float = INF
	for a in allies:
		if a.x <= x and x - a.x < distance: best = a; distance = x - a.x
	return best
# endregion

# region 7. ENTRADAS DE USUARIO (INPUTS Y MAQUINA DE ESTADOS)
func get_upgrade_cost(level: int) -> int:
	return (level + 1) * 100 # Costo de los cubitos: 100, 200, 300, 400, 500 Donas

func _unhandled_input(event: InputEvent) -> void:
	# --- ESTADO LOGIN ---
	if state == "login":
		if event is InputEventKey and event.pressed:
			if event.keycode == KEY_TAB:
				active_login_field = "pass" if active_login_field == "user" else "user"
			elif event.keycode == KEY_ENTER:
				if login_user.strip_edges() != "" and login_pass.strip_edges() == "":
					active_login_field = "pass"
				else:
					attempt_login()
			elif event.keycode == KEY_BACKSPACE:
				if active_login_field == "user" and login_user.length() > 0: login_user = login_user.substr(0, login_user.length() - 1)
				elif active_login_field == "pass" and login_pass.length() > 0: login_pass = login_pass.substr(0, login_pass.length() - 1)
			elif event.unicode != 0:
				var char_str = char(event.unicode)
				if char_str.is_valid_identifier() or char_str.is_valid_int():
					if active_login_field == "user" and login_user.length() < 12: login_user += char_str
					elif active_login_field == "pass" and login_pass.length() < 12: login_pass += char_str
		return

	# --- ESTADO MENU GLOBAL ---
	if state == "global_menu":
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var m = event.position
			if Rect2(500, 550, 280, 70).has_point(m): # Boton JUGAR
				state = "difficulty_menu"
			
			# Comprar mejoras (Cubitos)
			var categories = ["hero", "troops", "towers"]
			for i in 3:
				var cat = categories[i]
				var lvl = global_upgrades[cat]
				if lvl < 5:
					var cost = get_upgrade_cost(lvl)
					if Rect2(140 + i*370, 450, 260, 50).has_point(m):
						if donas_doradas >= cost:
							donas_doradas -= cost
							global_upgrades[cat] += 1
							save_game()
		return
		
	# --- ESTADO DIFICULTAD ---
	if state == "difficulty_menu":
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var rects = [Rect2(165, 415, 210, 210), Rect2(410, 415, 210, 210), Rect2(655, 415, 210, 210), Rect2(900, 415, 210, 210)]
			var mults = [0.8, 1.0, 1.5, 2.5]
			for i in 4:
				if rects[i].has_point(event.position):
					difficulty_multiplier = mults[i]
					start_level()
		return

	# --- ESTADO JUEGO Y PAUSA ---
	if event.is_action_pressed("ui_cancel"):
		paused = not paused
		push_message("Paused" if paused else "Back to the kitchen")
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_Q: active_menu = "units"; push_message("Unit menu")
		elif event.keycode == KEY_E: active_menu = "towers"; push_message("Tower menu")
		elif event.keycode == KEY_1 and active_menu == "units": spawn_ally("fork")
		elif event.keycode == KEY_2 and active_menu == "units": spawn_ally("roller")
		elif event.keycode == KEY_5 and active_menu == "units": spawn_ally("archer")
		elif event.keycode == KEY_3 and active_menu == "towers": build_tower("pepper")
		elif event.keycode == KEY_4 and active_menu == "towers": build_tower("kettle")
		elif event.keycode == KEY_U: upgrade_selected_tower()
		elif event.keycode == KEY_T: cycle_selected_tower_priority()
		elif event.keycode == KEY_H: respawn_mara()
		elif event.keycode == KEY_F: buy_farm()
		elif event.keycode == KEY_R and state != "playing": state = "global_menu" # Vuelve al menu de donas
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			var m = event.position
			if active_menu == "units" and Rect2(16,135,150,70).has_point(m): spawn_ally("fork")
			elif active_menu == "units" and Rect2(174,135,150,70).has_point(m): spawn_ally("roller")
			elif active_menu == "units" and Rect2(332,135,150,70).has_point(m): spawn_ally("archer")
			elif active_menu == "towers" and Rect2(16,135,150,70).has_point(m): build_tower("pepper")
			elif active_menu == "towers" and Rect2(174,135,150,70).has_point(m): build_tower("kettle")
			else:
				var tower_index = -1
				for i in player_towers.size():
					if m.distance_to(tower_position(player_towers[i], true)) < 80.0: tower_index = i
				if tower_index >= 0:
					selected_tower_index = tower_index
					push_message("Tower %d selected · [U] upgrade · [T] target priority" % (tower_index + 1))
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			var tower_index = -1
			for i in player_towers.size():
				if event.position.distance_to(tower_position(player_towers[i], true)) < 80.0: tower_index = i
			if tower_index >= 0: sell_tower(tower_index)

func respawn_mara() -> void:
	if not heroes.is_empty(): push_message("Mara is already fighting")
	elif mara_respawn_clock > 0.0: push_message("Mara returns in %d seconds" % ceili(mara_respawn_clock))
	elif legs < MARA_RESPAWN_COST: push_message("Need %d chicken leg for Mara" % MARA_RESPAWN_COST)
	else:
		legs -= MARA_RESPAWN_COST; spawn_hero()
		push_message("Mara is back in the kitchen!")
# endregion

# region 8. RENDERING PROCEDURAL (MENUS, LOGIN, JUEGO)
func _draw() -> void:
	# Dibujado según el Estado de la Máquina
	if state == "login":
		draw_rect(Rect2(0, 0, WIDTH, HEIGHT), Color("#3d2f47"))
		draw_string(ThemeDB.fallback_font, Vector2(400, 180), "SISTEMA DE CUENTAS LOCAL", HORIZONTAL_ALIGNMENT_LEFT, -1, 32, Color.WHITE)
		draw_string(ThemeDB.fallback_font, Vector2(400, 220), "Si la cuenta no existe, se creará automáticamente en tu PC.", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.GRAY)
		
		# Consejo movido arriba
		draw_string(ThemeDB.fallback_font, Vector2(400, 270), "💡 CONSEJO: Usa TAB o ENTER para pasar a la contraseña.", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color.YELLOW)
		
		draw_string(ThemeDB.fallback_font, Vector2(400, 320), "USUARIO", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
		draw_rect(Rect2(400, 340, 400, 40), Color.DARK_GRAY if active_login_field == "user" else Color.DIM_GRAY)
		draw_string(ThemeDB.fallback_font, Vector2(410, 365), login_user + ("_" if active_login_field == "user" else ""), HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color.WHITE)
		
		draw_string(ThemeDB.fallback_font, Vector2(400, 420), "CONTRASEÑA", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
		draw_rect(Rect2(400, 440, 400, 40), Color.DARK_GRAY if active_login_field == "pass" else Color.DIM_GRAY)
		draw_string(ThemeDB.fallback_font, Vector2(410, 465), "*".repeat(login_pass.length()) + ("_" if active_login_field == "pass" else ""), HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color.WHITE)
		
		if login_error != "": draw_string(ThemeDB.fallback_font, Vector2(400, 520), login_error, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color.RED)
		draw_string(ThemeDB.fallback_font, Vector2(400, 560), "Presiona ENTER para iniciar", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color.WHITE)
		return

	if state == "global_menu":
		draw_rect(Rect2(0, 0, WIDTH, HEIGHT), Color("#2a1e35"))
		draw_string(ThemeDB.fallback_font, Vector2(50, 80), "MENÚ GLOBAL - DONAS DORADAS", HORIZONTAL_ALIGNMENT_LEFT, -1, 36, Color("#ffe6a7"))
		draw_string(ThemeDB.fallback_font, Vector2(WIDTH - 300, 80), "Saldo: %d 🍩" % donas_doradas, HORIZONTAL_ALIGNMENT_LEFT, -1, 32, Color("#f4c663"))
		
		var categories = ["hero", "troops", "towers"]
		var names = ["MARA (HÉROE)", "TROPAS ALIADAS", "DEFENSAS (TORRES)"]
		var desc = ["+ Vida y Daño Físico", "+ Vida, Daño y Armadura", "+ Daño Estructural"]
		
		# Dibujar las 3 Columnas/Pestañas
		for i in 3:
			var cx = 140 + i * 370
			var cy = 180
			var lvl = global_upgrades[categories[i]]
			
			draw_rect(Rect2(cx, cy, 260, 340), Color(0.1, 0.1, 0.15, 1.0))
			draw_rect(Rect2(cx, cy, 260, 340), Color("#567d74"), false, 4.0)
			
			draw_string(ThemeDB.fallback_font, Vector2(cx + 20, cy + 30), names[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color.WHITE)
			draw_string(ThemeDB.fallback_font, Vector2(cx + 20, cy + 60), desc[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.GRAY)
			
			# Mini-retrato procedural central
			var px = cx + 130
			var py = cy + 150
			draw_circle(Vector2(px, py), 40, Color.DARK_SLATE_GRAY)
			if i == 0: # Hero Portrait
				draw_rect(Rect2(px - 15, py - 20, 30, 40), Color("#2c9e9b"))
				draw_circle(Vector2(px, py - 30), 12, Color("#f5cba3"))
				draw_rect(Rect2(px - 10, py - 50, 20, 15), Color.WHITE) # Gorrito
			elif i == 1: # Troops
				draw_rect(Rect2(px - 15, py - 20, 30, 40), Color("#77d4ef"))
				draw_circle(Vector2(px, py - 30), 10, Color("#f2c89f"))
				draw_line(Vector2(px+10, py-20), Vector2(px+25, py-35), Color.WHITE, 4) # Arma
			elif i == 2: # Tower
				draw_rect(Rect2(px - 10, py - 30, 20, 60), Color("#3b4555"))
				draw_rect(Rect2(px - 12, py - 10, 24, 10), Color("#dc7858"))
			
			# Dibujar los 5 Cubitos
			for c in 5:
				var c_rect = Rect2(cx + 25 + c * 45, cy + 230, 30, 30)
				draw_rect(c_rect, Color("#4ade80") if c < lvl else Color(0.2, 0.2, 0.2))
				draw_rect(c_rect, Color.WHITE, false, 2.0)
				
			# Botón de Compra
			var btn_rect = Rect2(cx, cy + 270, 260, 50)
			var hover = btn_rect.has_point(get_viewport().get_mouse_position())
			draw_rect(btn_rect, Color("#3d2f47") if not hover else Color("#6d435a"))
			draw_rect(btn_rect, Color.WHITE, false, 2.0)
			
			if lvl < 5:
				var cost = get_upgrade_cost(lvl)
				var c_color = Color.WHITE if donas_doradas >= cost else Color.RED
				draw_string(ThemeDB.fallback_font, Vector2(cx + 60, cy + 302), "Mejorar: %d 🍩" % cost, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, c_color)
			else:
				draw_string(ThemeDB.fallback_font, Vector2(cx + 80, cy + 302), "MAX LEVEL", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color.YELLOW)

		# Botón Jugar Gigante
		var play_btn = Rect2(500, 550, 280, 70)
		var p_hover = play_btn.has_point(get_viewport().get_mouse_position())
		draw_rect(play_btn, Color.DARK_GREEN if not p_hover else Color.GREEN)
		draw_string(ThemeDB.fallback_font, Vector2(580, 595), "DEFENDER", HORIZONTAL_ALIGNMENT_LEFT, -1, 32, Color.WHITE)
		return

	# --- RENDERIZADO DEL JUEGO NORMAL ---
	draw_kitchen_background()
	
	draw_rect(Rect2(55, 390, 80, 180), Color("#e8c57c")); draw_rect(Rect2(48, 370, 94, 32), Color("#c95745"))
	draw_string(ThemeDB.fallback_font, Vector2(54, 355), "PANTRY", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color.WHITE)
	bar(Vector2(48, 365), ally_base_hp, MAX_BASE_HP, 94, Color("#74df89"))
	
	draw_rect(Rect2(1110, 405, 90, 165), Color("#634d69")); draw_circle(Vector2(1155, 402), 34, Color("#9e6381"))
	draw_string(ThemeDB.fallback_font, Vector2(1100, 355), "PEST NEST", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color.WHITE)
	bar(Vector2(1100, 365), enemy_base_hp, MAX_BASE_HP * difficulty_multiplier if difficulty_multiplier > 1.0 else MAX_BASE_HP, 104, Color("#f47070"))
	
	for tower in player_towers: draw_tower(tower, true)
	for tower in enemy_towers: draw_tower(tower, false)
	for a in allies: draw_ally_unit(a)
	for e in enemies: draw_enemy_unit(e)
	for h in heroes: draw_mara(h)
	for b in bolts: draw_line(Vector2(b.x, GROUND_Y - 31), Vector2(b.target_x, GROUND_Y - 31), b.color, 3)
	for shot in tower_shots: draw_line(shot.from, shot.to, shot.color, 4)
	
	if state == "difficulty_menu":
		draw_rect(Rect2(0, 0, WIDTH, HEIGHT), Color(0.05, 0.04, 0.08, 0.85)) 
		draw_string(ThemeDB.fallback_font, Vector2(WIDTH/2 - 290, 85), "SELECCIONA TU DIFICULTAD", HORIZONTAL_ALIGNMENT_LEFT, -1, 44, Color(0.9, 0.9, 0.9, 0.95))
		
		var mouse: Vector2 = get_viewport().get_mouse_position()
		var hovered_level = 0 
		var colors = [Color("#4ade80"), Color("#fb923c"), Color("#f87171"), Color("#c084fc")]
		var names = ["FACIL", "MEDIO", "DIFICIL", "IMPOSIBLE"]
		var mults = ["Stats x0.8", "Stats x1.0", "Stats x1.5", "Stats x2.5"]
		var text_offset_x = [68, 62, 57, 30] 
		
		for i in 4:
			var r = Rect2(165 + i * 245, 415, 210, 210)
			var hover = r.has_point(mouse)
			if hover: hovered_level = i
			draw_rect(r, Color(0.08, 0.08, 0.08, 1.0))
			draw_rect(r, colors[i], false, 6.0 if hover else 2.0)
			draw_string(ThemeDB.fallback_font, r.position + Vector2(text_offset_x[i], 95), names[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 24, colors[i])
			draw_string(ThemeDB.fallback_font, r.position + Vector2(65, 135), mults[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
			
		draw_epic_portrait(Vector2(WIDTH/2, 220), hovered_level)
		return 
	
	# Interfaz (UI) del juego
	draw_rect(Rect2(14, 14, 650, 111), Color(0.05, 0.07, 0.12, 0.84))
	draw_string(ThemeDB.fallback_font, Vector2(28, 43), "LASAGNA DEFENSE", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color("#ffe6a7"))
	draw_string(ThemeDB.fallback_font, Vector2(28, 70), "Chicken legs: %d   |   Population: %d / %d   |   Income: +%d / sec" % [legs, allies.size() + player_builds.size(), POPULATION_LIMIT, BASE_INCOME_PER_SECOND + farm_count], HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color.WHITE)
	
	draw_string(ThemeDB.fallback_font, Vector2(28, 99), "[Q] Units  [E] Towers  ·  [F] Buy Farm (%s)  ·  [U] upgrade [T] priority" % ("Max" if farm_count >= MAX_FARMS else str(farm_cost())), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#c8d8ed"))
	
	if active_menu == "units":
		draw_card(Rect2(16, 135, 150, 70), "1", "Fork Scout", "3 legs · 0.72 sec", Color("#77d4ef"))
		draw_card(Rect2(174, 135, 150, 70), "2", "Rolling Pin", "6 legs · 1.25 sec", Color("#f5a75b"))
		draw_card(Rect2(332, 135, 150, 70), "5", "Tea Archer", "5 legs · 0.95 sec", Color("#83cb83"))
	else:
		draw_card(Rect2(16, 135, 150, 70), "3", "Pepper Popper", "7 legs · tower", Color("#dc7858"))
		draw_card(Rect2(174, 135, 150, 70), "4", "Kettle Arc", "12 legs · tower", Color("#9c72c7"))
		
	if player_builds.has("fork"): draw_build_clock(Vector2(690, 48), "FORK", player_builds["fork"], 0.72, Color("#77d4ef"))
	if player_builds.has("roller"): draw_build_clock(Vector2(750, 48), "ROLL", player_builds["roller"], 1.25, Color("#f5a75b"))
	if player_builds.has("archer"): draw_build_clock(Vector2(810, 48), "ARCH", player_builds["archer"], 0.95, Color("#83cb83"))
	
	if heroes.is_empty(): draw_string(ThemeDB.fallback_font, Vector2(820, 50), "Mara: %ds" % ceili(mara_respawn_clock) if mara_respawn_clock > 0.0 else "Mara: H to return (%d)" % MARA_RESPAWN_COST, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("#ffe6a7"))
		
	if selected_tower_index >= 0 and selected_tower_index < player_towers.size():
		var sel = player_towers[selected_tower_index]
		draw_string(ThemeDB.fallback_font, Vector2(680, 90), "Tower %d L%d · %s · [U] %d legs · [T] %s" % [selected_tower_index + 1, sel.level, tower_info(sel.kind).name, tower_upgrade_cost(sel) if sel.level < 3 else 0, sel.priority], HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#ffe6a7"))
		
	for i in message_log.size():
		var msg = message_log[i]
		var alpha = clamp(msg.time, 0.0, 1.0) 
		var y_pos = 685 - (i * 35) 
		draw_rect(Rect2(14, y_pos - 20, msg.text.length() * 9.5 + 20, 28), Color(0.05, 0.07, 0.12, 0.8 * alpha))
		draw_string(ThemeDB.fallback_font, Vector2(24, y_pos), msg.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1.0, 0.95, 0.75, alpha))
	
	if paused or state == "victory" or state == "defeat":
		draw_rect(Rect2(0, 0, WIDTH, HEIGHT), Color(0.05, 0.04, 0.1, 0.85))
		var headline: String = "PAUSED" if paused else ("PANTRY SAVED!" if state == "victory" else "PANTRY OVERRUN")
		draw_string(ThemeDB.fallback_font, Vector2(WIDTH/2 - 180, 315), headline, HORIZONTAL_ALIGNMENT_LEFT, -1, 42, Color("#ffe6a7"))
		draw_string(ThemeDB.fallback_font, Vector2(WIDTH/2 - 190, 360), "Presiona R para volver al Menú Principal", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color.WHITE)

func draw_epic_portrait(center: Vector2, level: int) -> void:
	if level == 2: draw_circle(center, 75, Color(0.8, 0.2, 0.1, 0.3))
	elif level == 3:
		draw_circle(center, 85, Color(0.6, 0.2, 0.8, 0.4))
		for i in 12: draw_line(center + Vector2(0, -60).rotated(i * TAU/12.0 + game_time_elapsed * 1.5), center + Vector2(0, -110).rotated(i * TAU/12.0 + game_time_elapsed * 1.5), Color("#c084fc"), 4)

	draw_polygon(PackedVector2Array([center + Vector2(-35, -5), center + Vector2(35, -5), center + Vector2(50, 60), center + Vector2(-50, 60)]), PackedColorArray([Color("#d63c3c")]))
	draw_rect(Rect2(center.x - 30, center.y - 10, 60, 70), Color("#422d35")); draw_rect(Rect2(center.x - 26, center.y - 6, 52, 66), Color("#2c9e9b"))
	draw_circle(center + Vector2(0, -20), 30, Color("#f5cba3"))
	
	draw_rect(Rect2(center.x - 20, center.y - 70, 40, 30), Color.WHITE); draw_circle(center + Vector2(-22, -70), 20, Color.WHITE); draw_circle(center + Vector2(22, -70), 20, Color.WHITE); draw_circle(center + Vector2(0, -90), 28, Color.WHITE) 
	
	var eye_y = -22
	if level == 0:
		draw_circle(center + Vector2(-12, eye_y), 5, Color("#3e3040")); draw_circle(center + Vector2(12, eye_y), 5, Color("#3e3040"))
		draw_arc(center + Vector2(0, -8), 12, 0, PI, 12, Color("#3e3040"), 3) 
	elif level == 1:
		draw_circle(center + Vector2(-12, eye_y), 5, Color("#3e3040")); draw_circle(center + Vector2(12, eye_y), 5, Color("#3e3040"))
		draw_line(center + Vector2(-22, eye_y - 10), center + Vector2(-6, eye_y - 5), Color("#3e3040"), 4); draw_line(center + Vector2(22, eye_y - 10), center + Vector2(6, eye_y - 5), Color("#3e3040"), 4)
		draw_line(center + Vector2(-10, -5), center + Vector2(10, -5), Color("#3e3040"), 3) 
	elif level == 2:
		draw_circle(center + Vector2(-12, eye_y), 6, Color("#f87171")); draw_circle(center + Vector2(12, eye_y), 6, Color("#f87171"))
		draw_line(center + Vector2(-25, eye_y - 12), center + Vector2(-5, eye_y - 3), Color("#3e3040"), 5); draw_line(center + Vector2(25, eye_y - 12), center + Vector2(5, eye_y - 3), Color("#3e3040"), 5)
		draw_arc(center + Vector2(0, 3), 12, PI, TAU, 12, Color("#3e3040"), 4) 
	elif level == 3:
		draw_circle(center + Vector2(-12, eye_y), 7, Color.WHITE); draw_circle(center + Vector2(12, eye_y), 7, Color.WHITE)
		draw_circle(center + Vector2(-12, eye_y), 12, Color(0.8, 0.4, 1.0, 0.5)); draw_circle(center + Vector2(12, eye_y), 12, Color(0.8, 0.4, 1.0, 0.5))
		draw_rect(Rect2(center.x - 30, center.y - 42, 60, 16), Color("#c084fc")) 
		draw_line(center + Vector2(-25, eye_y - 12), center + Vector2(-5, eye_y - 3), Color.BLACK, 6); draw_line(center + Vector2(25, eye_y - 12), center + Vector2(5, eye_y - 3), Color.BLACK, 6)
		draw_arc(center + Vector2(0, 3), 12, PI, TAU, 12, Color("#3e3040"), 4)
		draw_line(center + Vector2(-25, -2), center + Vector2(-12, 18), Color("#d63c3c"), 3)

func bar(pos: Vector2, val: float, mx: float, w: float, col: Color) -> void:
	draw_rect(Rect2(pos, Vector2(w, 7)), Color("#342d3b")); draw_rect(Rect2(pos, Vector2(w * clamp(val / mx, 0.0, 1.0), 7)), col)

func draw_build_clock(center: Vector2, kind: String, elapsed: float, duration: float, color: Color) -> void:
	var progress = clamp(elapsed / duration, 0.0, 1.0)
	draw_circle(center, 22, Color("#25283b")); draw_arc(center, 17, -PI / 2.0, -PI / 2.0 + TAU * progress, 24, color, 5, true)
	draw_string(ThemeDB.fallback_font, center + Vector2(-14, 4), kind, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color.WHITE)

func draw_card(rect: Rect2, hotkey: String, title: String, detail: String, color: Color) -> void:
	var hover = rect.has_point(get_viewport().get_mouse_position())
	draw_rect(rect, Color("#29354e") if not hover else Color("#405777"), true); draw_rect(rect, color, false, 2.0)
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(9, 24), hotkey + "   " + title, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color.WHITE)
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(9, 49), detail, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#d4e5ef"))

func draw_kitchen_background() -> void:
	draw_rect(Rect2(0, 0, WIDTH, HEIGHT), Color("#3d2f47")); draw_rect(Rect2(0, 150, WIDTH, 350), Color("#6d435a")) 
	draw_circle(Vector2(1010, 280), 90, Color("#d45d4e")); draw_circle(Vector2(1010, 280), 75, Color("#f2a65a")) 
	for i in 18: draw_circle(Vector2(25 + i * 74, 210 + (i % 4) * 19), 2.0, Color("#933b47"))
	for i in 9:
		var bh = 72.0 + float((i * 31) % 85); var bx = float(i * 155 - 40)
		draw_rect(Rect2(bx, GROUND_Y - bh, 112, bh), Color("#7a3641"))
		for w in 4: draw_rect(Rect2(bx + 14 + w * 23, GROUND_Y - bh + 21, 8, 12), Color("#eab67c"))
	draw_rect(Rect2(35, 248, 430, 12), Color("#562a32"))
	for jar in 6:
		var jx = 58.0 + jar * 63.0
		draw_rect(Rect2(jx, 215 + (jar % 2) * 8, 29, 32), Color("#567d74") if jar % 2 == 0 else Color("#a84a3c"))
		draw_rect(Rect2(jx + 4, 209 + (jar % 2) * 8, 21, 8), Color("#d4c09d"))
	draw_line(Vector2(880, 230), Vector2(880, 286), Color("#562a32"), 4)
	draw_circle(Vector2(880, 298), 26, Color("#364451")); draw_circle(Vector2(880, 298), 19, Color("#55636a"))
	draw_rect(Rect2(0, GROUND_Y - 44, WIDTH, 44), Color("#7a4034"))
	for tile in 16: draw_rect(Rect2(tile * 82, GROUND_Y - 40, 78, 36), Color("#d19760"), false, 2.0)
	draw_rect(Rect2(0, GROUND_Y, WIDTH, HEIGHT - GROUND_Y), Color("#a3563f")); draw_rect(Rect2(0, GROUND_Y, WIDTH, 8), Color("#e0c080"))
	for i in 14: draw_line(Vector2(i * 98, GROUND_Y + 43), Vector2(i * 98 + 58, HEIGHT), Color("#7a3c30"), 3.0)
	for farm in farm_count:
		var fx = 205.0 + farm * 110.0
		draw_rect(Rect2(fx, 378, 78, 74), Color("#e0b96f")); draw_rect(Rect2(fx - 7, 366, 92, 17), Color("#b94f47"))
		draw_line(Vector2(fx + 18, 452), Vector2(fx + 18, 485), Color("#81513c"), 5); draw_line(Vector2(fx + 58, 452), Vector2(fx + 58, 485), Color("#81513c"), 5)
		draw_circle(Vector2(fx + 38, 414), 13, Color("#f4c663")); draw_string(ThemeDB.fallback_font, Vector2(fx + 10, 359), "FARM +1/s", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#f8e4aa"))

func draw_ally_unit(a: Dictionary) -> void:
	var x = a.x; var suit = a.color
	draw_circle(Vector2(x, GROUND_Y - 3), 16, Color(0.12, 0.08, 0.12, 0.35))
	draw_rect(Rect2(x - 14, GROUND_Y - 49, 28, 32), Color("#422d35")); draw_rect(Rect2(x - 12, GROUND_Y - 47, 24, 28), suit)
	draw_rect(Rect2(x - 8, GROUND_Y - 39, 16, 20), Color("#f3ece0")); draw_circle(Vector2(x, GROUND_Y - 58), 12, Color("#f2c89f"))
	draw_arc(Vector2(x, GROUND_Y - 60), 12, 3.25, 6.2, 12, Color("#49313b"), 5)
	draw_line(Vector2(x - 10, GROUND_Y - 39), Vector2(x - 20, GROUND_Y - 25), Color("#f2c89f"), 4); draw_line(Vector2(x + 10, GROUND_Y - 39), Vector2(x + 18, GROUND_Y - 30), Color("#f2c89f"), 4)
	draw_line(Vector2(x - 7, GROUND_Y - 19), Vector2(x - 9, GROUND_Y - 5), Color("#35445b"), 5); draw_line(Vector2(x + 7, GROUND_Y - 19), Vector2(x + 9, GROUND_Y - 5), Color("#35445b"), 5)
	if a.kind == "fork":
		draw_line(Vector2(x + 14, GROUND_Y - 37), Vector2(x + 29, GROUND_Y - 61), Color("#d9edf0"), 3)
		for tooth in 3: draw_line(Vector2(x + 27 + tooth * 3, GROUND_Y - 63), Vector2(x + 29 + tooth * 3, GROUND_Y - 70), Color("#d9edf0"), 2)
	elif a.kind == "roller":
		draw_line(Vector2(x + 12, GROUND_Y - 34), Vector2(x + 31, GROUND_Y - 53), Color("#9d613c"), 6); draw_rect(Rect2(x + 25, GROUND_Y - 61, 15, 16), Color("#d59a5e"))
	else:
		draw_arc(Vector2(x + 21, GROUND_Y - 45), 16, -1.25, 1.25, 12, Color("#c69058"), 3)
		draw_line(Vector2(x + 20, GROUND_Y - 61), Vector2(x + 20, GROUND_Y - 29), Color("#f0e0b5"), 1); draw_line(Vector2(x + 12, GROUND_Y - 39), Vector2(x + 34, GROUND_Y - 45), Color("#d8e5d0"), 2)
	bar(Vector2(x - 20, GROUND_Y - 83), a.hp, a.max_hp, 40, Color("#79df93"))

func draw_enemy_unit(e: Dictionary) -> void:
	var x = e.x; var coat = Color("#733f67") if e.tough else Color("#b65f5b")
	draw_circle(Vector2(x, GROUND_Y - 3), 16, Color(0.12, 0.08, 0.12, 0.35))
	draw_rect(Rect2(x - 14, GROUND_Y - 49, 28, 32), Color("#422d35")); draw_rect(Rect2(x - 12, GROUND_Y - 47, 24, 28), coat); draw_rect(Rect2(x - 10, GROUND_Y - 46, 20, 5), Color("#e4bd5e"))
	draw_circle(Vector2(x, GROUND_Y - 58), 12 if not e.tough else 14, Color("#dcae91")); draw_rect(Rect2(x - 13, GROUND_Y - 69, 26, 7), Color("#362b45"))
	draw_line(Vector2(x + 10, GROUND_Y - 39), Vector2(x + 20, GROUND_Y - 28), Color("#dcae91"), 4)
	draw_line(Vector2(x - 8, GROUND_Y - 19), Vector2(x - 10, GROUND_Y - 5), Color("#352d42"), 5); draw_line(Vector2(x + 8, GROUND_Y - 19), Vector2(x + 10, GROUND_Y - 5), Color("#352d42"), 5)
	if e.tough: draw_line(Vector2(x - 10, GROUND_Y - 37), Vector2(x - 30, GROUND_Y - 58), Color("#b7c2ca"), 5); draw_circle(Vector2(x - 32, GROUND_Y - 60), 8, Color("#b7c2ca"))
	else: draw_line(Vector2(x - 12, GROUND_Y - 39), Vector2(x - 28, GROUND_Y - 52), Color("#b7c2ca"), 3); draw_circle(Vector2(x - 30, GROUND_Y - 54), 5, Color("#b7c2ca"))
	bar(Vector2(x - 20, GROUND_Y - 83), e.hp, e.max_hp, 40, Color("#f27670"))

func draw_mara(h: Dictionary) -> void:
	var x = h.x
	draw_circle(Vector2(x, GROUND_Y - 2), 24, Color(0.12, 0.08, 0.12, 0.38))
	draw_polygon(PackedVector2Array([Vector2(x - 18, GROUND_Y - 55), Vector2(x + 18, GROUND_Y - 55), Vector2(x + 25, GROUND_Y - 10), Vector2(x - 35, GROUND_Y - 10)]), PackedColorArray([Color("#d63c3c")]))
	draw_rect(Rect2(x - 21, GROUND_Y - 59, 42, 44), Color("#422d35")); draw_rect(Rect2(x - 18, GROUND_Y - 56, 36, 38), Color("#2c9e9b")); draw_rect(Rect2(x - 12, GROUND_Y - 49, 24, 29), Color("#f7ead7"))
	draw_circle(Vector2(x, GROUND_Y - 71), 17, Color("#f5cba3")); draw_arc(Vector2(x, GROUND_Y - 73), 17, 3.25, 6.25, 16, Color("#55384a"), 7)
	draw_circle(Vector2(x - 6, GROUND_Y - 72), 2, Color("#3e3040")); draw_circle(Vector2(x + 6, GROUND_Y - 72), 2, Color("#3e3040"))
	draw_rect(Rect2(x - 14, GROUND_Y - 100, 28, 25), Color.WHITE) 
	draw_circle(Vector2(x - 15, GROUND_Y - 100), 12, Color.WHITE); draw_circle(Vector2(x + 15, GROUND_Y - 100), 12, Color.WHITE); draw_circle(Vector2(x, GROUND_Y - 114), 18, Color.WHITE) 
	draw_line(Vector2(x - 15, GROUND_Y - 48), Vector2(x - 29, GROUND_Y - 31), Color("#f5cba3"), 5); draw_line(Vector2(x + 15, GROUND_Y - 48), Vector2(x + 25, GROUND_Y - 40), Color("#f5cba3"), 5)
	draw_line(Vector2(x - 10, GROUND_Y - 18), Vector2(x - 13, GROUND_Y - 3), Color("#394b61"), 7); draw_line(Vector2(x + 10, GROUND_Y - 18), Vector2(x + 13, GROUND_Y - 3), Color("#394b61"), 7)
	draw_line(Vector2(x + 22, GROUND_Y - 42), Vector2(x + 43, GROUND_Y - 57), Color("#62483c"), 6); draw_circle(Vector2(x + 48, GROUND_Y - 61), 13, Color("#48525e")); draw_circle(Vector2(x + 48, GROUND_Y - 61), 8, Color("#65727e"))
	if h.slash > 0.0: draw_arc(Vector2(x + 18, GROUND_Y - 45), 61, -0.9, 0.9, 16, Color("#fff4b3"), 7)
	bar(Vector2(x - 30, GROUND_Y - 135), h.hp, h.max_hp, 60, Color("#78e49a"))

func draw_tower(tower: Dictionary, friendly: bool) -> void:
	var p = tower_position(tower, friendly); var facing = 1.0 if friendly else -1.0; var acc = tower.color
	if friendly and tower.slot == selected_tower_index: draw_arc(p + Vector2(0, 44), 32, 0.0, TAU, 20, Color("#fff1a8"), 3)
	draw_rect(Rect2(p.x - 16, p.y, 32, 102), Color("#3b4555")); draw_rect(Rect2(p.x - 21, p.y + 90, 42, 12), Color("#252e3b")); draw_rect(Rect2(p.x - 14, p.y + 10, 28, 14), acc)
	draw_circle(Vector2(p.x, p.y + 16), 9, Color("#f3d78b"))
	if tower.kind == "kettle": draw_circle(Vector2(p.x + facing * 6, p.y - 4), 19, acc); draw_line(Vector2(p.x, p.y + 4), Vector2(p.x + facing * 42, p.y - 18), Color("#c8d7e0"), 8)
	else: draw_circle(Vector2(p.x, p.y - 4), 16, acc); draw_line(Vector2(p.x, p.y - 4), Vector2(p.x + facing * 38, p.y - 12), Color("#c8d7e0"), 6)
	draw_string(ThemeDB.fallback_font, p + Vector2(-22, -27), "T%d L%d" % [tower.slot + 1, tower.level], HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color.WHITE)
# endregion
