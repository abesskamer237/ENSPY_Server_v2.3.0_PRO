-- ENSPY Forum community upgrade.
-- Safe to run repeatedly.

ALTER TABLE forum_posts
  ADD COLUMN IF NOT EXISTS visibility TEXT NOT NULL DEFAULT 'all',
  ADD COLUMN IF NOT EXISTS level_id INTEGER REFERENCES levels(id) ON UPDATE CASCADE ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS attachment_count INTEGER NOT NULL DEFAULT 0;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'forum_posts_visibility_check'
  ) THEN
    ALTER TABLE forum_posts
      ADD CONSTRAINT forum_posts_visibility_check CHECK (visibility IN ('all','level'));
  END IF;
END $$;

CREATE TABLE IF NOT EXISTS forum_attachments (
  id SERIAL PRIMARY KEY,
  post_id INTEGER REFERENCES forum_posts(id) ON UPDATE CASCADE ON DELETE CASCADE,
  answer_id INTEGER REFERENCES forum_answers(id) ON UPDATE CASCADE ON DELETE CASCADE,
  file_url TEXT NOT NULL,
  original_name TEXT NOT NULL,
  mime_type TEXT NOT NULL DEFAULT 'application/octet-stream',
  file_size BIGINT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT forum_attachments_owner_check CHECK (
    (post_id IS NOT NULL AND answer_id IS NULL) OR
    (post_id IS NULL AND answer_id IS NOT NULL)
  )
);

CREATE INDEX IF NOT EXISTS forum_posts_visibility_idx
  ON forum_posts(visibility, level_id, created_at DESC);
CREATE INDEX IF NOT EXISTS forum_attachments_post_idx
  ON forum_attachments(post_id, created_at);
CREATE INDEX IF NOT EXISTS forum_attachments_answer_idx
  ON forum_attachments(answer_id, created_at);

-- Repair the counter if this migration is applied to an existing database.
UPDATE forum_posts p
SET attachment_count = (
  SELECT COUNT(*)::int FROM forum_attachments a WHERE a.post_id = p.id
);
