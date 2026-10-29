class_name OnlineLobby
extends Control
signal back_requested
var address_picker: OptionButton
var code_input: LineEdit
var invitation: LineEdit
var message: Label
var host_button: Button
var join_button: Button

func _ready() -> void:
	theme = UI.theme()
	var shade := ColorRect.new()
	shade.color = Color(0.02,0.01,0.03,0.94)
	add_child(UI.place(shade,0,0,1280,720))
	add_child(UI.place(UI.label("DIRECT CONNECT · SESSION CODE",33,UI.GOLD,true),50,45,1180,55))
	add_child(UI.place(UI.label("Two devices on the same Wi-Fi / reachable network · Both players use V6",20,UI.IVORY),70,108,1140,36))
	add_child(UI.place(UI.label("CREATE A SESSION",24,UI.CYAN),100,188,480,42))
	add_child(UI.place(UI.label("JOIN A SESSION",24,UI.ORANGE),700,188,480,42))
	address_picker = OptionButton.new()
	for address in SessionCode.local_addresses(): address_picker.add_item(address)
	add_child(UI.place(address_picker,100,248,480,48))
	host_button = UI.button("CREATE SESSION",host_session,true)
	add_child(UI.place(host_button,100,315,480,55))
	invitation = LineEdit.new()
	invitation.editable = false
	invitation.placeholder_text = "Your session code will appear here"
	invitation.add_theme_font_size_override("font_size",17)
	add_child(UI.place(invitation,100,393,480,52))
	add_child(UI.place(UI.button("COPY CODE",func():
		if OnlineSession.code != "":
			DisplayServer.clipboard_set(OnlineSession.code)
			message.text = "Code copied. Send it to the other player on your Wi-Fi network."),100,465,480,48))
	code_input = LineEdit.new()
	code_input.placeholder_text = "Paste the complete ID6 session code"
	code_input.max_length = 96
	code_input.add_theme_font_size_override("font_size",18)
	code_input.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_PASSWORD
	add_child(UI.place(code_input,700,248,480,52))
	code_input.text_submitted.connect(func(_text: String): join_session())
	join_button = UI.button("CONNECT",join_session,true)
	add_child(UI.place(join_button,700,315,480,55))
	message = UI.label("",19,UI.IVORY)
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(UI.place(message,130,543,1020,76))
	add_child(UI.place(UI.label("Session codes connect directly. Other Wi-Fi networks / mobile data require routing or a relay server.",16,UI.MUTED),80,618,1120,30))
	add_child(UI.place(UI.button("BACK",func(): back_requested.emit()),440,660,400,46))
	refresh()

func host_session() -> void:
	if address_picker.item_count == 0:
		message.text = "No Wi-Fi IPv4 address found. Connect to Wi-Fi and reopen this screen."
		return
	var result := OnlineSession.host(address_picker.get_item_text(address_picker.selected))
	if result == "": message.text = OnlineSession.last_error
	refresh()

func join_session() -> void:
	if not OnlineSession.join(code_input.text): message.text = OnlineSession.last_error
	refresh()

func refresh() -> void:
	if not message: return
	invitation.text = OnlineSession.code if OnlineSession.local_slot == 0 else ""
	var busy: bool = OnlineSession.phase in ["connecting","hosting"]
	host_button.disabled = busy
	join_button.disabled = busy
	address_picker.disabled = busy
	code_input.editable = not busy
	if OnlineSession.phase == "hosting": message.text = "Waiting for the other device. Copy this code and choose CONNECT on their device."
	elif OnlineSession.phase == "connecting": message.text = "Connecting… Keep both apps open."
	elif OnlineSession.last_error != "": message.text = OnlineSession.last_error
