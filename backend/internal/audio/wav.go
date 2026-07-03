package audio

import (
	"encoding/binary"
	"fmt"
	"math"
)

type WAVData struct {
	SampleRate int
	Samples    []float64
}

func ParseWAV(data []byte) (WAVData, error) {
	if len(data) < 44 {
		return WAVData{}, fmt.Errorf("invalid wav: too short")
	}
	if string(data[0:4]) != "RIFF" || string(data[8:12]) != "WAVE" {
		return WAVData{}, fmt.Errorf("invalid wav header")
	}

	offset := 12
	var sampleRate int
	var bitsPerSample int
	var numChannels int
	var dataOffset int
	var dataSize int

	for offset+8 <= len(data) {
		chunkID := string(data[offset : offset+4])
		chunkSize := int(binary.LittleEndian.Uint32(data[offset+4 : offset+8]))
		chunkStart := offset + 8

		switch chunkID {
		case "fmt ":
			if chunkStart+16 <= len(data) {
				numChannels = int(binary.LittleEndian.Uint16(data[chunkStart+2 : chunkStart+4]))
				sampleRate = int(binary.LittleEndian.Uint32(data[chunkStart+4 : chunkStart+8]))
				bitsPerSample = int(binary.LittleEndian.Uint16(data[chunkStart+14 : chunkStart+16]))
			}
		case "data":
			dataOffset = chunkStart
			dataSize = chunkSize
		}

		offset = chunkStart + chunkSize
	}

	if dataOffset == 0 || sampleRate == 0 || bitsPerSample != 16 {
		return WAVData{}, fmt.Errorf("unsupported wav format")
	}

	end := dataOffset + dataSize
	if end > len(data) {
		end = len(data)
	}

	raw := data[dataOffset:end]
	samples := make([]float64, 0, len(raw)/2)
	for i := 0; i+1 < len(raw); i += 2 * numChannels {
		sample := int16(binary.LittleEndian.Uint16(raw[i : i+2]))
		samples = append(samples, float64(sample)/32768.0)
	}

	return WAVData{SampleRate: sampleRate, Samples: samples}, nil
}

func DetectNotes(data WAVData, windowMs, hopMs int) []DetectedNote {
	if len(data.Samples) == 0 {
		return nil
	}

	windowSize := data.SampleRate * windowMs / 1000
	hopSize := data.SampleRate * hopMs / 1000
	if windowSize <= 0 {
		windowSize = data.SampleRate / 10
	}
	if hopSize <= 0 {
		hopSize = windowSize / 2
	}

	var notes []DetectedNote
	startMs := 0
	for i := 0; i+windowSize <= len(data.Samples); i += hopSize {
		freq := estimateFrequency(data.Samples[i : i+windowSize], data.SampleRate)
		if freq > 0 {
			if noteName, ok := frequencyToNote(freq); ok {
				notes = append(notes, DetectedNote{
					Note:       noteName,
					StartMs:    startMs,
					DurationMs: windowMs,
				})
			}
		}
		startMs += hopMs
	}

	return dedupeNotes(notes)
}

type DetectedNote struct {
	Note       string
	StartMs    int
	DurationMs int
}

func estimateFrequency(samples []float64, sampleRate int) float64 {
	minFreq := 70.0
	maxFreq := 1200.0
	minLag := int(float64(sampleRate) / maxFreq)
	maxLag := int(float64(sampleRate) / minFreq)
	if maxLag >= len(samples)/2 {
		maxLag = len(samples)/2 - 1
	}
	if minLag < 1 {
		minLag = 1
	}

	bestLag := 0
	bestCorr := 0.0
	for lag := minLag; lag <= maxLag; lag++ {
		corr := 0.0
		for i := 0; i < len(samples)-lag; i++ {
			corr += samples[i] * samples[i+lag]
		}
		if corr > bestCorr {
			bestCorr = corr
			bestLag = lag
		}
	}

	if bestLag == 0 {
		return 0
	}
	return float64(sampleRate) / float64(bestLag)
}

func frequencyToNote(freq float64) (string, bool) {
	if freq <= 0 {
		return "", false
	}
	names := []string{"C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"}
	midi := int(math.Round(69 + 12*math.Log2(freq/440)))
	if midi < 0 {
		return "", false
	}
	name := names[midi%12]
	octave := midi/12 - 1
	return fmt.Sprintf("%s%d", name, octave), true
}

func dedupeNotes(notes []DetectedNote) []DetectedNote {
	if len(notes) == 0 {
		return notes
	}
	result := []DetectedNote{notes[0]}
	for i := 1; i < len(notes); i++ {
		last := result[len(result)-1]
		if notes[i].Note == last.Note {
			last.DurationMs += notes[i].DurationMs
			result[len(result)-1] = last
			continue
		}
		result = append(result, notes[i])
	}
	return result
}
