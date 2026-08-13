-- ENSPY v2.3 PRO additive migration.
-- No existing table or column is removed. Safe to run repeatedly.

-- Forum reactions (keeps legacy votes untouched).
CREATE TABLE IF NOT EXISTS forum_reactions (
  id BIGSERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(id) ON UPDATE CASCADE ON DELETE CASCADE,
  target_type TEXT NOT NULL CHECK (target_type IN ('post','answer')),
  target_id INTEGER NOT NULL,
  reaction TEXT NOT NULL CHECK (reaction IN ('like','heart','laugh','fire','clap')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT forum_reactions_unique UNIQUE(user_id,target_type,target_id)
);
CREATE INDEX IF NOT EXISTS forum_reactions_target_idx
  ON forum_reactions(target_type,target_id,created_at DESC);

-- Moderation reports.
CREATE TABLE IF NOT EXISTS forum_reports (
  id BIGSERIAL PRIMARY KEY,
  reporter_id INTEGER NOT NULL REFERENCES users(id) ON UPDATE CASCADE ON DELETE CASCADE,
  post_id INTEGER REFERENCES forum_posts(id) ON UPDATE CASCADE ON DELETE CASCADE,
  answer_id INTEGER REFERENCES forum_answers(id) ON UPDATE CASCADE ON DELETE CASCADE,
  reason TEXT NOT NULL CHECK (reason IN ('SPAM','INSULT','HARASSMENT','INAPPROPRIATE','MISINFORMATION','COPYRIGHT','OTHER')),
  details TEXT,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','reviewed','dismissed','actioned')),
  reviewed_by INTEGER REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL,
  reviewed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT forum_reports_target_check CHECK (
    (post_id IS NOT NULL AND answer_id IS NULL) OR
    (post_id IS NULL AND answer_id IS NOT NULL)
  )
);
CREATE INDEX IF NOT EXISTS forum_reports_status_idx ON forum_reports(status,created_at DESC);
CREATE INDEX IF NOT EXISTS forum_reports_reporter_idx ON forum_reports(reporter_id,created_at DESC);

-- Academic event reminders/preferences. Delivery can be handled later by a worker.
CREATE TABLE IF NOT EXISTS event_reminders (
  id BIGSERIAL PRIMARY KEY,
  event_id INTEGER NOT NULL REFERENCES calendar_events(id) ON UPDATE CASCADE ON DELETE CASCADE,
  user_id INTEGER NOT NULL REFERENCES users(id) ON UPDATE CASCADE ON DELETE CASCADE,
  minutes_before INTEGER NOT NULL CHECK (minutes_before IN (30,60,1440)),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  delivered_at TIMESTAMPTZ,
  CONSTRAINT event_reminders_unique UNIQUE(event_id,user_id,minutes_before)
);
CREATE INDEX IF NOT EXISTS event_reminders_due_idx
  ON event_reminders(delivered_at,event_id,minutes_before);

-- Useful text-search indexes. They are additive and safe on existing data.
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE INDEX IF NOT EXISTS forum_posts_title_trgm_idx ON forum_posts USING GIN (title gin_trgm_ops);
CREATE INDEX IF NOT EXISTS forum_posts_content_trgm_idx ON forum_posts USING GIN (content gin_trgm_ops);
CREATE INDEX IF NOT EXISTS documents_title_trgm_idx ON documents USING GIN (title gin_trgm_ops);
CREATE INDEX IF NOT EXISTS academic_resources_title_trgm_idx ON academic_resources USING GIN (title gin_trgm_ops);
