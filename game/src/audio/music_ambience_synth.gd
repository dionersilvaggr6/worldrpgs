class_name MusicAmbienceSynth
extends RefCounted
## Camas de ambiente deterministas da Fatia 1.
##
## [CODEX] Brumal e Toca usam receitas diferentes e uma unica voz cada.
## Razao: a transicao ouve-se sem transformar ambiente em faixa musical nem
## multiplicar loops residentes. Alternativa descartada: reutilizar Brumal com
## pitch mais baixo na Toca; mudava a cor, nao a identidade do lugar.

const RATE := 22050
const LOOP_SECONDS := 8.0


static func make(entry_id: String) -> AudioStreamWAV:
	match entry_id:
		"amb_brumal_bed":
			return make_brumal()
		"amb_toca_bed":
			return make_toca()
		"amb_rest_campfire":
			return make_campfire()
		_:
			return null


static func make_brumal() -> AudioStreamWAV:
	var rng := _seeded_rng(0x4252554d)
	var canopy := _controls(rng, 96)
	var air := _controls(rng, 1536)
	var leaves := _controls(rng, 4096)
	var samples := _buffer(LOOP_SECONDS)
	for index in samples.size():
		var time := float(index) / RATE
		var cycle := time / LOOP_SECONDS
		var breath := 0.64 + sin(TAU * cycle * 2.0 + 0.3) * 0.17 \
			+ sin(TAU * cycle * 5.0 + 1.1) * 0.07
		var low_air := _cyclic_noise(canopy, cycle * canopy.size())
		var moving_air := _cyclic_noise(air, cycle * air.size())
		var leaf_position := cycle * leaves.size()
		var leaf_edge := _cyclic_noise(leaves, leaf_position) \
			- _cyclic_noise(leaves, leaf_position - 1.8)
		var leaf_gust := _soft_pulse(time, 1.35, 0.65) \
			+ _soft_pulse(time, 4.85, 0.82) * 0.78 \
			+ _soft_pulse(time, 7.15, 0.46) * 0.55
		samples[index] = (low_air * 0.12 + moving_air * 0.16) * breath \
			+ leaf_edge * leaf_gust * 0.09
	return _stream(samples)


static func make_toca() -> AudioStreamWAV:
	var rng := _seeded_rng(0x544f4341)
	var stone_air := _controls(rng, 128)
	var rough_air := _controls(rng, 768)
	var samples := _buffer(LOOP_SECONDS)
	var drip_centres := PackedFloat32Array([0.72, 3.18, 6.43])
	var drip_frequencies := PackedFloat32Array([1180.0, 860.0, 1370.0])
	for index in samples.size():
		var time := float(index) / RATE
		var cycle := time / LOOP_SECONDS
		var pressure := _cyclic_noise(stone_air, cycle * stone_air.size())
		var grain := _cyclic_noise(rough_air, cycle * rough_air.size())
		var air := pressure * 0.105 + grain * 0.035
		var resonance := sin(TAU * 73.0 * time + sin(TAU * cycle) * 0.4) * 0.018
		var drops := 0.0
		for drip_index in drip_centres.size():
			var elapsed := fposmod(time - drip_centres[drip_index], LOOP_SECONDS)
			if elapsed < 0.31:
				var envelope := exp(-elapsed * 19.0)
				var frequency := drip_frequencies[drip_index]
				drops += sin(TAU * frequency * elapsed) * envelope * 0.13
				drops += sin(TAU * frequency * 0.47 * elapsed) * envelope * 0.045
		samples[index] = air + resonance + drops
	return _stream(samples)


static func make_campfire() -> AudioStreamWAV:
	var rng := _seeded_rng(0x53454755)
	var flame := _controls(rng, 768)
	var sparks := _controls(rng, 4096)
	var centres := PackedFloat32Array([0.34, 0.91, 1.48, 2.37, 3.05, 3.62,
		4.41, 5.28, 5.83, 6.56, 7.17, 7.71])
	var samples := _buffer(LOOP_SECONDS)
	for index in samples.size():
		var time := float(index) / RATE
		var cycle := time / LOOP_SECONDS
		var body := _cyclic_noise(flame, cycle * flame.size()) * 0.12
		var sharp := _cyclic_noise(sparks, cycle * sparks.size())
		var crackle := 0.0
		for centre in centres:
			var elapsed := fposmod(time - centre, LOOP_SECONDS)
			if elapsed < 0.055:
				crackle += sharp * exp(-elapsed * 98.0) * 0.34
		var breathing := 0.78 + sin(TAU * cycle * 4.0 + 0.2) * 0.09
		samples[index] = body * breathing + crackle
	return _stream(samples)


static func decoded_bytes(stream: AudioStreamWAV) -> int:
	return stream.data.size()


static func peak(stream: AudioStreamWAV) -> float:
	var peak_sample := 0
	for byte_index in range(0, stream.data.size(), 2):
		peak_sample = maxi(peak_sample, absi(stream.data.decode_s16(byte_index)))
	return float(peak_sample) / 32767.0


static func seam_delta(stream: AudioStreamWAV) -> float:
	if stream.data.size() < 4:
		return 1.0
	return absf(float(stream.data.decode_s16(0) \
		- stream.data.decode_s16(stream.data.size() - 2))) / 32767.0


static func _stream(samples: PackedFloat32Array) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for index in samples.size():
		bytes.encode_s16(index * 2,
			int(clampf(samples[index], -1.0, 1.0) * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.data = bytes
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = samples.size()
	return stream


static func _buffer(seconds: float) -> PackedFloat32Array:
	var samples := PackedFloat32Array()
	samples.resize(int(seconds * RATE))
	return samples


static func _seeded_rng(seed_value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


static func _controls(rng: RandomNumberGenerator, count: int) -> PackedFloat32Array:
	var values := PackedFloat32Array()
	values.resize(count)
	for index in count:
		values[index] = rng.randf_range(-1.0, 1.0)
	return values


static func _cyclic_noise(values: PackedFloat32Array, position: float) -> float:
	var wrapped := fposmod(position, float(values.size()))
	var left := int(floorf(wrapped))
	var fraction := wrapped - float(left)
	var smooth := fraction * fraction * (3.0 - 2.0 * fraction)
	return lerpf(values[left], values[(left + 1) % values.size()], smooth)


static func _soft_pulse(time: float, centre: float, half_width: float) -> float:
	var distance := absf(time - centre)
	if distance >= half_width:
		return 0.0
	var amount := 1.0 - distance / half_width
	return amount * amount * (3.0 - 2.0 * amount)
