package evaluation_test

import (
	"testing"

	"github.com/Trinhleo/guitar-ai/backend/internal/evaluation"
)

func TestTechniqueHintsLowPitch(t *testing.T) {
	hints := evaluation.TechniqueHints(evaluation.Scores{PitchAccuracy: 50, TimingAccuracy: 95, TechniqueScore: 90})
	found := false
	for _, hint := range hints {
		if hint.Code == "pitch_low" {
			found = true
		}
	}
	if !found {
		t.Fatal("expected pitch_low hint")
	}
}

func TestTechniqueHintsExcellent(t *testing.T) {
	hints := evaluation.TechniqueHints(evaluation.Scores{
		PitchAccuracy:  95,
		TimingAccuracy: 95,
		TechniqueScore: 95,
	})
	if len(hints) != 1 || hints[0].Code != "excellent" {
		t.Fatalf("expected excellent hint, got %+v", hints)
	}
}
