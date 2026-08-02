extends RefCounted
## DSP minimo partilhado pelas confirmacoes de progressao. Frequencias,
## duracoes e volume pertencem a progression.json.


static func make_chirp(config: Dictionary) -> AudioStreamWAV:
	var rate := int(config.get("sample_rate_hz", 0))
	var duration := float(config.get("duration_s", 0.0))
	var start_hz := float(config.get("start_hz", 0.0))
	var end_hz := float(config.get("end_hz", 0.0))
	var sample_count := maxi(1, int(duration * rate))
	var bytes := PackedByteArray()
	bytes.resize(sample_count * 2)
	var phase := 0.0
	for index: int in sample_count:
		var progress := float(index) / float(sample_count)
		phase += TAU * lerpf(start_hz, end_hz, progress) / float(rate)
		var envelope := sin(PI * progress)
		var sample := sin(phase) * envelope * 0.45
		bytes.encode_s16(index * 2, int(clampf(sample, -1.0, 1.0) * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.data = bytes
	return stream
