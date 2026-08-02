class_name NecromancyAudio
extends AudioStreamPlayer
## Ferro raspado e pulsação grave sintetizados uma vez em memória. Não há
## binário novo; a taxa de amostragem vem do catálogo de apresentação inimiga.

var _cues: Dictionary = {}


func configure(presentation: Dictionary) -> bool:
	var sample_rate := int(presentation.get("audio_sample_rate_hz", 0))
	if sample_rate <= 0:
		return false
	_cues = {
		"raise": _synth_cue(sample_rate, 0.42, 58.0, 103.0, 0.38),
		"order": _synth_cue(sample_rate, 0.24, 92.0, 138.0, 0.12),
	}
	return true


func cue_count() -> int:
	return _cues.size()


func play_cue(cue_id: String) -> void:
	var cue := _cues.get(cue_id) as AudioStreamWAV
	if cue == null:
		return
	stream = cue
	play()


func _synth_cue(sample_rate: int, duration_s: float, base_hz: float,
		scrape_hz: float, scrape_mix: float) -> AudioStreamWAV:
	var sample_count := maxi(roundi(float(sample_rate) * duration_s), 1)
	var pcm := PackedByteArray()
	pcm.resize(sample_count * 2)
	for sample_index: int in sample_count:
		var time_s := float(sample_index) / float(sample_rate)
		var progress := float(sample_index) / float(sample_count)
		var envelope := (1.0 - progress) * (1.0 - progress)
		var pulse := sin(TAU * base_hz * time_s) \
			+ sin(TAU * base_hz * 0.5 * time_s) * 0.35
		var scrape := sin(TAU * scrape_hz * time_s \
			+ sin(TAU * 17.0 * time_s) * 2.4)
		var value := (pulse * (1.0 - scrape_mix) + scrape * scrape_mix) \
			* envelope * 0.52
		pcm.encode_s16(sample_index * 2,
			clampi(roundi(value * 32767.0), -32768, 32767))
	var cue := AudioStreamWAV.new()
	cue.format = AudioStreamWAV.FORMAT_16_BITS
	cue.mix_rate = sample_rate
	cue.stereo = false
	cue.data = pcm
	return cue
