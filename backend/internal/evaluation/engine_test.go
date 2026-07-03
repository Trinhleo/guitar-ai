package evaluation_test

import (
	"testing"

	"github.com/Trinhleo/guitar-ai/backend/internal/evaluation"
)

func TestEvaluatePerformance_PerfectMatch(t *testing.T) {
	cfg := evaluation.InstrumentConfig{PitchToleranceCents: 50, TimingToleranceMs: 80}
	notes := []evaluation.Note{
		{Note: "E4", StartMs: 0, DurationMs: 500},
		{Note: "E4", StartMs: 600, DurationMs: 500},
	}

	result := evaluation.EvaluatePerformance(notes, notes, cfg)

	if result.PitchAccuracy != 100 {
		t.Fatalf("pitch accuracy = %v, want 100", result.PitchAccuracy)
	}
	if result.TimingAccuracy != 100 {
		t.Fatalf("timing accuracy = %v, want 100", result.TimingAccuracy)
	}
	if result.TechniqueScore != 100 {
		t.Fatalf("technique score = %v, want 100", result.TechniqueScore)
	}
	if result.InstrumentSpecificMetrics.MatchedNotes != 2 {
		t.Fatalf("matched notes = %d, want 2", result.InstrumentSpecificMetrics.MatchedNotes)
	}
}

func TestEvaluatePerformance_WrongPitch(t *testing.T) {
	cfg := evaluation.InstrumentConfig{TimingToleranceMs: 80}
	expected := []evaluation.Note{{Note: "E4", StartMs: 0, DurationMs: 500}}
	played := []evaluation.Note{{Note: "G4", StartMs: 0, DurationMs: 500}}

	result := evaluation.EvaluatePerformance(expected, played, cfg)

	if result.PitchAccuracy >= 100 {
		t.Fatalf("pitch accuracy = %v, want less than 100", result.PitchAccuracy)
	}
	if result.OverallScore >= 100 {
		t.Fatalf("overall score = %v, want less than 100", result.OverallScore)
	}
}

func TestEvaluatePerformance_TimingDrift(t *testing.T) {
	cfg := evaluation.InstrumentConfig{TimingToleranceMs: 80}
	expected := []evaluation.Note{{Note: "E4", StartMs: 0, DurationMs: 500}}
	played := []evaluation.Note{{Note: "E4", StartMs: 200, DurationMs: 500}}

	result := evaluation.EvaluatePerformance(expected, played, cfg)

	if result.TimingAccuracy >= 100 {
		t.Fatalf("timing accuracy = %v, want less than 100", result.TimingAccuracy)
	}
}

func TestEvaluatePerformance_EmptyPlayedNotes(t *testing.T) {
	cfg := evaluation.InstrumentConfig{TimingToleranceMs: 80}
	expected := []evaluation.Note{{Note: "E4", StartMs: 0, DurationMs: 500}}

	result := evaluation.EvaluatePerformance(expected, nil, cfg)

	if result.OverallScore != 0 {
		t.Fatalf("overall score = %v, want 0", result.OverallScore)
	}
	if result.InstrumentSpecificMetrics.MatchedNotes != 0 {
		t.Fatalf("matched notes = %d, want 0", result.InstrumentSpecificMetrics.MatchedNotes)
	}
}

func TestParseNote(t *testing.T) {
	tests := []struct {
		note string
		ok   bool
	}{
		{"E4", true},
		{"C#5", true},
		{"Bb3", true},
		{"invalid", false},
	}

	for _, tt := range tests {
		_, ok := evaluation.ParseNote(tt.note)
		if ok != tt.ok {
			t.Fatalf("ParseNote(%q) ok = %v, want %v", tt.note, ok, tt.ok)
		}
	}
}
