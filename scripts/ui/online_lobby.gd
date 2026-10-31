class_name OnlineLobby
extends Control
signal back_requested
var code_input: LineEdit
var invitation: Label
var message: Label
var host_button: Button
var join_button: Button
var cancel_button: Button

func _ready() -> void:
	theme = UI.theme()
	var shade := ColorRect.new()
	shade.color = Color("0a0c17")
	add_child(UI.place(shade,0,0,1280,720))
	add_child(UI.place(UI.label("PLAY TOGETHER",17,UI.CYAN),70,44,1140,32))
	add_child(UI.place(UI.label("ONE CODE. ONE DUEL.",42,UI.IVORY,true),60,88,1160,65))
	add_child(UI.place(UI.label("The host keeps the session open · Two devices on the same Wi-Fi · V16 on both devices",19,UI.MUTED),65,166,1150,38))
	for x in [70,670]:
		var panel := UI.panel()
		panel.add_theme_stylebox_override("panel",UI.style(Color("131827"),Color("2b344b"),1))
		add_child(UI.place(panel,x,238,540,326))
	add_child(UI.place(UI.label("01   CREATE A SESSION",23,UI.CYAN),95,258,490,42))
	add_child(UI.place(UI.label("02   ENTER YOUR FRIEND'S CODE",22,UI.ORANGE),695,258,490,42))
	invitation = UI.label("— — — — — —",39,UI.IVORY,true)
	add_child(UI.place(invitation,100,330,480,75))
	host_button = UI.button("CREATE SESSION",host_session,true)
	add_child(UI.place(host_button,100,432,480,55))
	add_child(UI.place(UI.button("COPY CODE",func():
		if OnlineSession.local_slot == 0:
			DisplayServer.clipboard_set(OnlineSession.code)
			message.text = "Code copied. Share these six characters with the other player."),100,498,480,42))
	code_input = LineEdit.new()
	code_input.placeholder_text = "6 CHARACTERS"
	code_input.max_length = 16
	code_input.alignment = HORIZONTAL_ALIGNMENT_CENTER
	code_input.add_theme_font_size_override("font_size",37)
	code_input.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_DEFAULT
	code_input.virtual_keyboard_enabled = true
	code_input.text_changed.connect(func(text: String):
		var cleaned := SessionCode.normalize(text)
		if cleaned != text:
			code_input.text = cleaned
			code_input.caret_column = cleaned.length())
	add_child(UI.place(code_input,700,336,480,65))
	code_input.text_submitted.connect(func(_text: String): join_session())
	join_button = UI.button("CONNECT",join_session,true)
	add_child(UI.place(join_button,700,432,480,55))
	cancel_button = UI.button("CANCEL SESSION",func():
		OnlineSession.close()
		message.text = "Session closed. Create a new code or join your friend."
		refresh())
	add_child(UI.place(cancel_button,700,498,480,42))
	message = UI.label("Create a code or paste your friend's six-character code.",18,UI.IVORY)
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(UI.place(message,100,578,1080,52))
	add_child(UI.place(UI.label("Keep both games open. Use regular Wi-Fi or a phone hotspot. Guest isolation and VPN can block connecting. Codes work on the same network.",14,UI.MUTED),70,631,1140,25))
	add_child(UI.place(UI.button("BACK",func(): back_requested.emit()),440,667,400,42))
	refresh()

func host_session() -> void:
	if OnlineSession.host() == "": message.text = OnlineSession.last_error
	refresh()

func join_session() -> void:
	if not OnlineSession.join(code_input.text): message.text = OnlineSession.last_error
	refresh()

func refresh() -> void:
	if not message: return
	invitation.text = OnlineSession.code if OnlineSession.local_slot == 0 else "— — — — — —"
	var busy: bool = OnlineSession.phase in ["discovering","connecting","hosting"]
	host_button.disabled = busy
	join_button.disabled = busy
	code_input.editable = not busy
	cancel_button.disabled = not busy
	if OnlineSession.phase == "hosting": message.text = "Session open. Share the six-character code. Waiting for your friend…"
	elif OnlineSession.phase == "discovering": message.text = "Finding your friend's session… Keep both devices on the same Wi-Fi."
	elif OnlineSession.phase == "connecting": message.text = "Session found. Connecting…"
	elif OnlineSession.last_error != "": message.text = OnlineSession.last_error
