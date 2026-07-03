package evaluation

import (
	"math"
	"regexp"
)

var notePattern = regexp.MustCompile(`^([A-G])(#|b)?(\d+)$`)

var noteToSemitone = map[byte]int{
	'C': 0, 'D': 2, 'E': 4, 'F': 5, 'G': 7, 'A': 9, 'B': 11,
}

type Note struct {
	Note       string `json:"note"`
	StartMs    int    `json:"startMs"`
	DurationMs int    `json:"durationMs"`
}

type InstrumentConfig struct {
	PitchToleranceCents int `json:"pitchToleranceCents"`
	TimingToleranceMs   int `json:"timingToleranceMs"`
}

type InstrumentMetrics struct {
	MatchedNotes int `json:"matchedNotes"`
	TotalNotes   int `json:"totalNotes"`
}

type Scores struct {
	OverallScore              float64           `json:"overallScore"`
	PitchAccuracy             float64           `json:"pitchAccuracy"`
	TimingAccuracy            float64           `json:"timingAccuracy"`
	TechniqueScore            float64           `json:"techniqueScore"`
	ExpressionScore           float64           `json:"expressionScore"`
	ConsistencyScore          float64           `json:"consistencyScore"`
	InstrumentSpecificMetrics InstrumentMetrics `json:"instrumentSpecificMetrics"`
}

func ParseNote(note string) (int, bool) {
	return parseNote(note)
}

func parseNote(note string) (int, bool) {
	matches := notePattern.FindStringSubmatch(note)
	if matches == nil {
		return 0, false
	}

	semitone := noteToSemitone[matches[1][0]]
	switch matches[2] {
	case "#":
		semitone++
	case "b":
		semitone--
	}

	octave := 0
	for _, ch := range matches[3] {
		octave = octave*10 + int(ch-'0')
	}

	return semitone + (octave+1)*12, true
}

func noteMatches(expected, played Note) bool {
	e, okE := parseNote(expected.Note)
	p, okP := parseNote(played.Note)
	return okE && okP && e == p
}

func timingMatches(expected, played Note, toleranceMs int) bool {
	diff := expected.StartMs - played.StartMs
	if diff < 0 {
		diff = -diff
	}
	return diff <= toleranceMs
}

func clampScore(value float64) float64 {
	return math.Max(0, math.Min(100, math.Round(value*100)/100))
}

func EvaluatePerformance(expectedNotes, playedNotes []Note, cfg InstrumentConfig) Scores {
	toleranceMs := cfg.TimingToleranceMs
	if toleranceMs == 0 {
		toleranceMs = 80
	}

	total := len(expectedNotes)
	if total == 0 {
		return Scores{
			InstrumentSpecificMetrics: InstrumentMetrics{TotalNotes: 0},
		}
	}

	pitchHits := 0
	timingHits := 0
	matchedNotes := 0

	for i := 0; i < total; i++ {
		expected := expectedNotes[i]
		if i >= len(playedNotes) {
			continue
		}
		played := playedNotes[i]

		pitchOk := noteMatches(expected, played)
		timingOk := timingMatches(expected, played, toleranceMs)

		if pitchOk {
			pitchHits++
		}
		if timingOk {
			timingHits++
		}
		if pitchOk && timingOk {
			matchedNotes++
		}
	}

	totalF := float64(total)
	pitchAccuracy := clampScore(float64(pitchHits) / totalF * 100)
	timingAccuracy := clampScore(float64(timingHits) / totalF * 100)
	techniqueScore := clampScore(float64(matchedNotes) / totalF * 100)
	expressionScore := clampScore(timingAccuracy * 0.9)
	consistencyScore := clampScore(pitchAccuracy * 0.95)

	overallScore := clampScore(
		pitchAccuracy*0.4 +
			timingAccuracy*0.35 +
			techniqueScore*0.15 +
			expressionScore*0.07 +
			consistencyScore*0.03,
	)

	return Scores{
		OverallScore:     overallScore,
		PitchAccuracy:    pitchAccuracy,
		TimingAccuracy:   timingAccuracy,
		TechniqueScore:   techniqueScore,
		ExpressionScore:  expressionScore,
		ConsistencyScore: consistencyScore,
		InstrumentSpecificMetrics: InstrumentMetrics{
			MatchedNotes: matchedNotes,
			TotalNotes:   total,
		},
	}
}
