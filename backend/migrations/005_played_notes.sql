ALTER TABLE performance_metrics
  ADD COLUMN IF NOT EXISTS played_notes JSONB DEFAULT '[]';
