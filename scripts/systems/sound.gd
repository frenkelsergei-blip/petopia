class_name Sound
extends Node
## Music and sound effects (chiptune, made by tools/build_sounds.py).
## Sound.play("jump") anywhere; Sound.music("meadow") crossfades the loop.
## Buses: Master (Sound setting) > Music (Music setting) and SFX.

const MUSIC_DB=-7.0
const VOICES=10
static var _node: Sound
static var _cache: Dictionary={}
## Child and Foxy voice blips can be switched off in Settings.
static var voices=true
const VOICE_SOUNDS=["child_hup","child_yay","child_ouch","fox_yip","fox_happy","fox_whine","fox_yawn","fox_purr","fox_snore"]

var players: Array[AudioStreamPlayer]=[]
var next_voice=0
var music_a: AudioStreamPlayer
var music_b: AudioStreamPlayer
var track=""
var last_played: Dictionary={}

static func _instance() -> Sound:
	if is_instance_valid(_node): return _node
	# Headless runs (tests, imports) have no speakers: stay silent.
	if DisplayServer.get_name()=="headless": return null
	var tree=Engine.get_main_loop() as SceneTree
	if tree==null: return null
	_node=Sound.new()
	_node.name="Sound"
	_node.process_mode=Node.PROCESS_MODE_ALWAYS
	tree.root.add_child.call_deferred(_node)
	return _node

static func _bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name)>=0: return
	AudioServer.add_bus()
	var index=AudioServer.bus_count-1
	AudioServer.set_bus_name(index,bus_name)
	AudioServer.set_bus_send(index,"Master")

func _init() -> void:
	_bus("Music")
	_bus("SFX")
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"),MUSIC_DB)
	for i in VOICES:
		var p=AudioStreamPlayer.new()
		p.bus="SFX"
		add_child(p)
		players.append(p)
	music_a=AudioStreamPlayer.new()
	music_b=AudioStreamPlayer.new()
	for m in [music_a,music_b]:
		m.bus="Music"
		m.volume_db=-60.0
		add_child(m)

func _ready() -> void:
	get_tree().node_added.connect(_on_node_added)
	# Buttons built before this node existed (the first menu) get taps too.
	for b in get_tree().root.find_children("*","BaseButton",true,false): _on_node_added(b)
	# Music asked for before this node joined the tree starts now.
	if track!="":
		var wanted=track
		track=""
		music(wanted)

func _exit_tree() -> void:
	for p in players+[music_a,music_b]:
		p.stop()
		p.stream=null
	_cache.clear()

## Every button in the game gets a tap (Close/Back a softer close sound).
func _on_node_added(node: Node) -> void:
	if not node is BaseButton or node.has_meta("silent") or node.has_meta("tap_sound"): return
	var b: BaseButton=node
	b.set_meta("tap_sound",true)
	b.pressed.connect(func():
		var label=String(b.name).to_lower()
		play("ui_close" if ("close" in label or "back" in label) else "ui_tap",0.03))

static func _stream(path: String) -> AudioStream:
	if _cache.has(path): return _cache[path]
	var s: AudioStream=load(path) if ResourceLoader.exists(path) else null
	_cache[path]=s
	return s

## One-shot effect with a little pitch variety so repeats don't sound robotic.
static func play(effect: String, pitch_jitter=0.05, volume_db=0.0) -> void:
	if not voices and effect in VOICE_SOUNDS: return
	var n=_instance()
	if n==null or not n.is_inside_tree(): return
	var stream=_stream("res://assets/audio/sfx/%s.wav"%effect)
	if stream==null: return
	# The same sound twice in one frame (e.g. several coins) plays once.
	var now=Time.get_ticks_msec()
	if now-int(n.last_played.get(effect,-1000))<40: return
	n.last_played[effect]=now
	var p: AudioStreamPlayer=n.players[n.next_voice]
	n.next_voice=(n.next_voice+1)%VOICES
	p.stream=stream
	p.volume_db=volume_db
	p.pitch_scale=1.0+randf_range(-pitch_jitter,pitch_jitter)
	p.play()

## Crossfade to a looping music track ("" stops the music).
static func music(name: String) -> void:
	var n=_instance()
	if n==null or n.track==name: return
	n.track=name
	if not n.is_inside_tree(): return
	var old: AudioStreamPlayer=n.music_a if n.music_a.playing and n.music_a.volume_db>-59 else n.music_b
	var fresh: AudioStreamPlayer=n.music_b if old==n.music_a else n.music_a
	if name!="":
		var stream=_stream("res://assets/audio/music/%s.wav"%name)
		if stream!=null:
			fresh.stream=stream
			fresh.volume_db=-40.0
			fresh.play()
			var up=n.create_tween()
			up.tween_property(fresh,"volume_db",0.0,1.2).set_trans(Tween.TRANS_SINE)
	if old.playing:
		var down=n.create_tween()
		down.tween_property(old,"volume_db",-60.0,0.9)
		down.tween_callback(old.stop)

## Apply the Sound and Music settings.
static func apply_settings(prefs: Dictionary) -> void:
	_instance()
	AudioServer.set_bus_mute(0,not bool(prefs.get("sound",true)))
	voices=bool(prefs.get("voices",true))
	var music_bus=AudioServer.get_bus_index("Music")
	if music_bus>=0:
		AudioServer.set_bus_mute(music_bus,not bool(prefs.get("music",true)))
		AudioServer.set_bus_volume_db(music_bus,MUSIC_DB+linear_to_db(float(prefs.get("music_volume",75))/75.0))
	var sfx_bus=AudioServer.get_bus_index("SFX")
	if sfx_bus>=0: AudioServer.set_bus_volume_db(sfx_bus,linear_to_db(float(prefs.get("sfx_volume",100))/100.0))
