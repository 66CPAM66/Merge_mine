extends Control

const COLS := 7
const ROWS := 10
const CELL_MIN_SIZE := Vector2(42, 48)
const COLORS := {"stone": Color("#59636D"), "coal": Color("#303942")}
const NAMES := {"stone": "Камень", "coal": "Уголь"}

var blocks: Array = []
var resources := {"stone": 0, "coal": 0}
var mining_index := -1
var mining_progress := 0.0
var mining_duration := 1.6
var cell_buttons: Array[Button] = []
var root_column: VBoxContainer
var resource_label: Label
var status_label: Label
var progress_bar: ProgressBar
var progress_label: Label
var grid: GridContainer

func _ready() -> void:
	_build_blocks()
	_show_workshop()

func _build_blocks() -> void:
	blocks.clear()
	for y in range(ROWS):
		for x in range(COLS):
			var kind := "stone"
			if (x == 2 and y >= 2 and y <= 4) or (x == 5 and y >= 6 and y <= 8) or (x == 3 and y == 9):
				kind = "coal"
			blocks.append({"kind": kind, "dug": false})

func _clear_ui() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	cell_buttons.clear()
	grid = null

func _base_ui() -> VBoxContainer:
	var bg := ColorRect.new()
	bg.color = Color("#10151A")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	add_child(margin)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 14)
	margin.add_child(col)
	return col

func _show_workshop() -> void:
	_clear_ui()
	root_column = _base_ui()
	var spacer := Control.new()
	spacer.custom_minimum_size.y = 24
	root_column.add_child(spacer)
	var title := _label("МАСТЕРСКАЯ", 29, Color("#E6E1D8"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root_column.add_child(title)
	var subtitle := _label("Старый дедовский сарай", 15, Color("#A8B0B8"))
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root_column.add_child(subtitle)
	var gap := Control.new()
	gap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_column.add_child(gap)
	var bench := PanelContainer.new()
	bench.add_theme_stylebox_override("panel", _panel_style(Color("#202830"), Color("#59636D"), 12))
	root_column.add_child(bench)
	var inside := VBoxContainer.new()
	inside.add_theme_constant_override("separation", 12)
	bench.add_child(inside)
	var bench_title := _label("ВЕРСТАК", 20, Color("#E0C28C"))
	bench_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inside.add_child(bench_title)
	var pick := _label("⛏   Ржавая кирка лежит на столе", 16, Color("#D7DDE2"))
	pick.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pick.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inside.add_child(pick)
	var resources_text := _label("Склад пока пуст", 14, Color("#A8B0B8"))
	resources_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inside.add_child(resources_text)
	var gap2 := Control.new()
	gap2.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_column.add_child(gap2)
	var mine_button := Button.new()
	mine_button.text = "⛏  СПУСТИТЬСЯ В ШАХТУ"
	mine_button.custom_minimum_size.y = 64
	mine_button.add_theme_font_size_override("font_size", 18)
	mine_button.add_theme_color_override("font_color", Color("#F2E8D6"))
	mine_button.add_theme_stylebox_override("normal", _panel_style(Color("#765A38"), Color("#D1B17A"), 10))
	mine_button.add_theme_stylebox_override("hover", _panel_style(Color("#8A6B43"), Color("#E4C58D"), 10))
	mine_button.pressed.connect(_show_mine)
	root_column.add_child(mine_button)
	var note := _label("Под сараем скрываются залежи полезных ископаемых...", 12, Color("#7F8B95"))
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root_column.add_child(note)

func _show_mine() -> void:
	_clear_ui()
	mining_index = -1
	mining_progress = 0.0
	root_column = _base_ui()
	var top := HBoxContainer.new()
	root_column.add_child(top)
	var back := Button.new()
	back.text = "← Мастерская"
	back.custom_minimum_size = Vector2(135, 44)
	back.focus_mode = Control.FOCUS_NONE
	back.pressed.connect(_show_workshop)
	top.add_child(back)
	var title := _label("ШАХТА", 23, Color("#E6E1D8"))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	top.add_child(title)
	var subtitle := _label("Коснись доступного блока", 13, Color("#A8B0B8"))
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root_column.add_child(subtitle)
	var panel := PanelContainer.new()
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _panel_style(Color("#1B2229"), Color("#2D3740"), 10))
	root_column.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 7)
	panel.add_child(margin)
	grid = GridContainer.new()
	grid.columns = COLS
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	margin.add_child(grid)
	for i in range(COLS * ROWS):
		var b := Button.new()
		b.custom_minimum_size = CELL_MIN_SIZE
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.size_flags_vertical = Control.SIZE_EXPAND_FILL
		b.focus_mode = Control.FOCUS_NONE
		b.add_theme_font_size_override("font_size", 16)
		b.pressed.connect(_on_block_pressed.bind(i))
		grid.add_child(b)
		cell_buttons.append(b)
	var mining_panel := PanelContainer.new()
	mining_panel.add_theme_stylebox_override("panel", _panel_style(Color("#202830"), Color("#35414B"), 10))
	root_column.add_child(mining_panel)
	var mining_col := VBoxContainer.new()
	mining_col.add_theme_constant_override("separation", 5)
	mining_panel.add_child(mining_col)
	status_label = _label("Выбери блок, чтобы начать добычу", 14, Color("#E6E1D8"))
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mining_col.add_child(status_label)
	progress_bar = ProgressBar.new()
	progress_bar.custom_minimum_size.y = 15
	progress_bar.max_value = 100
	progress_bar.show_percentage = false
	mining_col.add_child(progress_bar)
	progress_label = _label("ГОТОВ К РАБОТЕ", 11, Color("#9CA8B2"))
	progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mining_col.add_child(progress_label)
	resource_label = _label("", 15, Color("#E0C28C"))
	resource_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root_column.add_child(resource_label)
	_refresh_grid()
	_update_resource_text()

func _process(delta: float) -> void:
	if mining_index < 0 or progress_bar == null:
		return
	mining_progress += delta
	progress_bar.value = min(100.0, mining_progress / mining_duration * 100.0)
	progress_label.text = "ДОБЫЧА  %d%%" % int(progress_bar.value)
	if mining_progress >= mining_duration:
		_finish_mining()

func _on_block_pressed(index: int) -> void:
	var block: Dictionary = blocks[index]
	if block["dug"]:
		status_label.text = "Здесь уже пусто — выбери соседний блок"
		return
	if not _is_accessible(index):
		status_label.text = "Сначала открой путь к этому блоку"
		return
	if mining_index == index:
		status_label.text = "Уже добываем этот блок..."
		return
	mining_index = index
	mining_progress = 0.0
	var kind: String = block["kind"]
	mining_duration = 2.3 if kind == "coal" else 1.6
	status_label.text = "Добываем: " + NAMES[kind]
	progress_bar.value = 0
	progress_label.text = "ДОБЫЧА  0%"
	_refresh_grid()

func _finish_mining() -> void:
	var block: Dictionary = blocks[mining_index]
	var kind: String = block["kind"]
	block["dug"] = true
	blocks[mining_index] = block
	resources[kind] += 1
	mining_index = -1
	mining_progress = 0.0
	progress_bar.value = 0
	status_label.text = "Добыто: " + NAMES[kind] + "!"
	progress_label.text = "ГОТОВО К РАБОТЕ"
	_refresh_grid()
	_update_resource_text()

func _is_accessible(index: int) -> bool:
	var y := int(index / COLS)
	var x := index % COLS
	if y == 0:
		return true
	var neighbors: Array[int] = []
	if x > 0: neighbors.append(index - 1)
	if x < COLS - 1: neighbors.append(index + 1)
	if y > 0: neighbors.append(index - COLS)
	if y < ROWS - 1: neighbors.append(index + COLS)
	for neighbor in neighbors:
		if blocks[neighbor]["dug"]:
			return true
	return false

func _refresh_grid() -> void:
	if cell_buttons.is_empty():
		return
	for i in range(cell_buttons.size()):
		var button: Button = cell_buttons[i]
		var block: Dictionary = blocks[i]
		if block["dug"]:
			button.text = ""
			button.disabled = true
			button.add_theme_stylebox_override("normal", _panel_style(Color("#13191E"), Color("#202830"), 4))
			continue
		var kind: String = block["kind"]
		var accessible := _is_accessible(i)
		button.disabled = not accessible
		button.text = ("◆" if accessible else "·") if kind == "coal" else ("▪" if accessible else "·")
		if i == mining_index: button.text = "⛏"
		var fill: Color = COLORS[kind] if accessible else Color("#252C33")
		if i == mining_index: fill = Color("#8B714C")
		button.add_theme_color_override("font_color", Color("#F0E7D8") if accessible else Color("#46515B"))
		button.add_theme_stylebox_override("normal", _panel_style(fill, Color("#414C56"), 4))
		button.add_theme_stylebox_override("hover", _panel_style(fill.lightened(0.12), Color("#D1B17A"), 4))
		button.add_theme_stylebox_override("pressed", _panel_style(fill.darkened(0.1), Color("#D1B17A"), 4))

func _update_resource_text() -> void:
	if resource_label:
		resource_label.text = "КАМЕНЬ  %d     •     УГОЛЬ  %d" % [resources["stone"], resources["coal"]]

func _label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label

func _panel_style(fill: Color, border_color: Color, corner: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border_color
	style.set_border_width_all(1)
	style.set_corner_radius_all(corner)
	style.content_margin_left = 6
	style.content_margin_right = 6
	style.content_margin_top = 5
	style.content_margin_bottom = 5
	return style
