-- Create a table for device metrics
CREATE TABLE device_metrics (
  device_id TEXT PRIMARY KEY,
  characters INTEGER DEFAULT 0,
  words INTEGER DEFAULT 0,
  practiced INTEGER DEFAULT 0,
  last_seen TIMESTAMP DEFAULT NOW()
);

-- Create a view for global metrics
CREATE VIEW global_metrics AS
SELECT 
  COUNT(*) as total_users,
  COALESCE(SUM(characters), 0) as total_characters_learned,
  COALESCE(SUM(words), 0) as total_words_learned,
  COALESCE(SUM(practiced), 0) as total_characters_practiced,
  COUNT(*) as daily_active_users,
  NOW() as last_updated
FROM device_metrics;

-- Enable Row Level Security
ALTER TABLE device_metrics ENABLE ROW LEVEL SECURITY;

-- Create a policy that allows anonymous access
CREATE POLICY "Allow anonymous access" ON device_metrics
  FOR ALL USING (true) WITH CHECK (true);