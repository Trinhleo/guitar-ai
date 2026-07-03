package audio_test

import (
	"encoding/binary"
	"math"
	"testing"

	"github.com/Trinhleo/guitar-ai/backend/internal/audio"
)

func TestParseWAVAndDetectNotes(t *testing.T) {
	const sampleRate = 44100
	const durationSec = 0.5
	const freq = 329.63 // E4

	samples := make([]int16, int(sampleRate*durationSec))
	for i := range samples {
		samples[i] = int16(32767 * math.Sin(2*math.Pi*freq*float64(i)/sampleRate))
	}

	data := make([]byte, 44+len(samples)*2)
	copy(data[0:4], "RIFF")
	binary.LittleEndian.PutUint32(data[4:8], uint32(len(data)-8))
	copy(data[8:12], "WAVE")
	copy(data[12:16], "fmt ")
	binary.LittleEndian.PutUint32(data[16:20], 16)
	binary.LittleEndian.PutUint16(data[20:22], 1)
	binary.LittleEndian.PutUint16(data[22:24], 1)
	binary.LittleEndian.PutUint32(data[24:28], sampleRate)
	binary.LittleEndian.PutUint32(data[28:32], sampleRate*2)
	binary.LittleEndian.PutUint16(data[32:34], 2)
	binary.LittleEndian.PutUint16(data[34:36], 16)
	copy(data[36:40], "data")
	binary.LittleEndian.PutUint32(data[40:44], uint32(len(samples)*2))
	for i, sample := range samples {
		binary.LittleEndian.PutUint16(data[44+i*2:44+i*2+2], uint16(sample))
	}

	parsed, err := audio.ParseWAV(data)
	if err != nil {
		t.Fatalf("parse wav: %v", err)
	}

	notes := audio.DetectNotes(parsed, 200, 200)
	if len(notes) == 0 {
		t.Fatal("expected detected notes")
	}
	if notes[0].Note != "E4" {
		t.Fatalf("note = %s, want E4", notes[0].Note)
	}
}
