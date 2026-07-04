package evaluation

type TechniqueHint struct {
	Code     string `json:"code"`
	Message  string `json:"message"`
	Severity string `json:"severity"`
}

func TechniqueHints(scores Scores) []TechniqueHint {
	hints := []TechniqueHint{}

	if scores.PitchAccuracy < 70 {
		hints = append(hints, TechniqueHint{
			Code:     "pitch_low",
			Message:  "Pitch needs work — practice slowly with a tuner and match each target note.",
			Severity: "warning",
		})
	} else if scores.PitchAccuracy < 90 {
		hints = append(hints, TechniqueHint{
			Code:     "pitch_ok",
			Message:  "Pitch is decent — focus on intonation at chord changes.",
			Severity: "info",
		})
	}

	if scores.TimingAccuracy < 70 {
		hints = append(hints, TechniqueHint{
			Code:     "timing_low",
			Message:  "Timing is off — use a metronome at 50–75% speed, then increase tempo.",
			Severity: "warning",
		})
	} else if scores.TimingAccuracy < 90 {
		hints = append(hints, TechniqueHint{
			Code:     "timing_ok",
			Message:  "Good rhythm — tighten note onsets for cleaner transitions.",
			Severity: "info",
		})
	}

	if scores.TechniqueScore < 75 {
		hints = append(hints, TechniqueHint{
			Code:     "technique",
			Message:  "Technique: practice bends with half-step targets and smooth vibrato on sustained notes.",
			Severity: "info",
		})
	}

	if len(hints) == 0 {
		hints = append(hints, TechniqueHint{
			Code:     "excellent",
			Message:  "Excellent performance — try a harder lesson or increase practice speed.",
			Severity: "info",
		})
	}

	return hints
}

func ScoresWithHints(scores Scores) map[string]any {
	return map[string]any{
		"overallScore":              scores.OverallScore,
		"pitchAccuracy":             scores.PitchAccuracy,
		"timingAccuracy":            scores.TimingAccuracy,
		"techniqueScore":            scores.TechniqueScore,
		"expressionScore":           scores.ExpressionScore,
		"consistencyScore":          scores.ConsistencyScore,
		"instrumentSpecificMetrics": scores.InstrumentSpecificMetrics,
		"techniqueHints":            TechniqueHints(scores),
	}
}
