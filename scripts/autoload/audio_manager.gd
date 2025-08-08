extends Node

# Audio Manager - Handles all game audio
class_name AudioManager

signal audio_settings_changed

# Audio Players
var music_player: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []
var ambient_player: AudioStreamPlayer

# Audio Streams
var audio_streams = {
	# Music
	"main_theme": null,
	"mining_ambient": null,
	"danger_theme": null,
	
	# Sound Effects
	"dig": null,
	"jump": null,
	"land": null,
	"coin_collect": null,
	"upgrade_purchase": null,
	"conveyor_place": null,
	"conveyor_operate": null,
	"material_drop": null,
	"game_over": null,
	"menu_select": null,
	"menu_confirm": null,
	"robot_damage": null,
	"mole_attack": null,
	"base_process": null
}

# Audio Settings
var master_volume: float = 1.0
var music_volume: float = 0.7
var sfx_volume: float = 1.0
var ambient_volume: float = 0.5

# Current Music
var current_music: String = ""

func _ready():
	setup_audio_players()
	load_audio_streams()
	apply_audio_settings()

func setup_audio_players():
	# Create music player
	music_player = AudioStreamPlayer.new()
	music_player.name = "MusicPlayer"
	music_player.bus = "Music"
	add_child(music_player)
	
	# Create ambient player
	ambient_player = AudioStreamPlayer.new()
	ambient_player.name = "AmbientPlayer"
	ambient_player.bus = "Ambient"
	add_child(ambient_player)
	
	# Create SFX players (pool of 8 players)
	for i in range(8):
		var sfx_player = AudioStreamPlayer.new()
		sfx_player.name = "SFXPlayer" + str(i)
		sfx_player.bus = "SFX"
		add_child(sfx_player)
		sfx_players.append(sfx_player)

func load_audio_streams():
	# Load audio streams from assets
	# For now, we'll create placeholder streams
	# In a real implementation, these would be loaded from .ogg or .wav files
	
	# Create simple tone generators for placeholder sounds
	audio_streams["dig"] = create_tone_stream(200, 0.1)
	audio_streams["jump"] = create_tone_stream(400, 0.2)
	audio_streams["land"] = create_tone_stream(150, 0.3)
	audio_streams["coin_collect"] = create_tone_stream(800, 0.1)
	audio_streams["upgrade_purchase"] = create_tone_stream(600, 0.2)
	audio_streams["conveyor_place"] = create_tone_stream(300, 0.15)
	audio_streams["conveyor_operate"] = create_tone_stream(250, 0.5)
	audio_streams["material_drop"] = create_tone_stream(180, 0.2)
	audio_streams["game_over"] = create_tone_stream(100, 1.0)
	audio_streams["menu_select"] = create_tone_stream(500, 0.05)
	audio_streams["menu_confirm"] = create_tone_stream(600, 0.1)
	audio_streams["robot_damage"] = create_tone_stream(120, 0.4)
	audio_streams["mole_attack"] = create_tone_stream(80, 0.6)
	audio_streams["base_process"] = create_tone_stream(350, 0.3)

func create_tone_stream(frequency: float, duration: float) -> AudioStreamGenerator:
	var stream = AudioStreamGenerator.new()
	stream.mix_rate = 44100
	stream.buffer_length = duration
	
	var playback = stream.get_stream_playback()
	var frames = int(duration * 44100)
	
	for i in range(frames):
		var t = float(i) / 44100.0
		var sample = sin(2.0 * PI * frequency * t) * 0.3
		playback.push_frame(Vector2(sample, sample))
	
	return stream

func play_sound(sound_name: String, volume: float = 1.0):
	if not audio_streams.has(sound_name):
		print("Warning: Sound '", sound_name, "' not found!")
		return
	
	# Find available SFX player
	var available_player: AudioStreamPlayer = null
	for player in sfx_players:
		if not player.playing:
			available_player = player
			break
	
	if not available_player:
		# If no player available, use the first one
		available_player = sfx_players[0]
	
	available_player.stream = audio_streams[sound_name]
	available_player.volume_db = linear_to_db(volume * sfx_volume)
	available_player.play()

func play_music(music_name: String, fade_in: bool = true):
	if not audio_streams.has(music_name):
		print("Warning: Music '", music_name, "' not found!")
		return
	
	if current_music == music_name and music_player.playing:
		return
	
	current_music = music_name
	
	if fade_in and music_player.playing:
		# Fade out current music
		var tween = create_tween()
		tween.tween_property(music_player, "volume_db", -80.0, 0.5)
		tween.tween_callback(func(): 
			music_player.stream = audio_streams[music_name]
			music_player.volume_db = linear_to_db(music_volume)
			music_player.play()
			var fade_in_tween = create_tween()
			fade_in_tween.tween_property(music_player, "volume_db", linear_to_db(music_volume), 0.5)
		)
	else:
		music_player.stream = audio_streams[music_name]
		music_player.volume_db = linear_to_db(music_volume)
		music_player.play()

func stop_music(fade_out: bool = true):
	if fade_out and music_player.playing:
		var tween = create_tween()
		tween.tween_property(music_player, "volume_db", -80.0, 0.5)
		tween.tween_callback(music_player.stop)
	else:
		music_player.stop()
	current_music = ""

func play_ambient(ambient_name: String, loop: bool = true):
	if not audio_streams.has(ambient_name):
		print("Warning: Ambient '", ambient_name, "' not found!")
		return
	
	ambient_player.stream = audio_streams[ambient_name]
	ambient_player.volume_db = linear_to_db(ambient_volume)
	ambient_player.play()
	
	if loop:
		ambient_player.finished.connect(func(): ambient_player.play(), CONNECT_ONE_SHOT)

func stop_ambient():
	ambient_player.stop()

func set_master_volume(volume: float):
	master_volume = clamp(volume, 0.0, 1.0)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(master_volume))
	audio_settings_changed.emit()

func set_music_volume(volume: float):
	music_volume = clamp(volume, 0.0, 1.0)
	music_player.volume_db = linear_to_db(music_volume)
	audio_settings_changed.emit()

func set_sfx_volume(volume: float):
	sfx_volume = clamp(volume, 0.0, 1.0)
	audio_settings_changed.emit()

func set_ambient_volume(volume: float):
	ambient_volume = clamp(volume, 0.0, 1.0)
	ambient_player.volume_db = linear_to_db(ambient_volume)
	audio_settings_changed.emit()

func apply_audio_settings():
	# Apply settings from GameManager
	var settings = GameManager.game_settings
	set_master_volume(settings.get("audio_master", 1.0))
	set_music_volume(settings.get("audio_music", 0.7))
	set_sfx_volume(settings.get("audio_sfx", 1.0))

func save_audio_settings():
	GameManager.game_settings["audio_master"] = master_volume
	GameManager.game_settings["audio_music"] = music_volume
	GameManager.game_settings["audio_sfx"] = sfx_volume
	GameManager.save_game_settings()

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_audio_settings()
