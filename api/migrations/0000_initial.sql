-- ENSPY Platform - initial database schema
-- Safe to run more than once on the same database.

CREATE TABLE IF NOT EXISTS levels (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  description TEXT NOT NULL DEFAULT ''
);

CREATE TABLE IF NOT EXISTS filieres (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  code TEXT NOT NULL,
  level_id INTEGER NOT NULL REFERENCES levels(id) ON UPDATE CASCADE ON DELETE RESTRICT,
  description TEXT
);

CREATE TABLE IF NOT EXISTS users (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  email TEXT NOT NULL UNIQUE,
  password_hash TEXT NOT NULL,
  role TEXT NOT NULL DEFAULT 'student',
  level_id INTEGER NOT NULL DEFAULT 1 REFERENCES levels(id) ON UPDATE CASCADE ON DELETE RESTRICT,
  filiere_id INTEGER NOT NULL DEFAULT 1 REFERENCES filieres(id) ON UPDATE CASCADE ON DELETE RESTRICT,
  avatar_url TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS subjects (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  code TEXT NOT NULL,
  level_id INTEGER NOT NULL REFERENCES levels(id) ON UPDATE CASCADE ON DELETE RESTRICT,
  filiere_id INTEGER NOT NULL REFERENCES filieres(id) ON UPDATE CASCADE ON DELETE RESTRICT,
  coefficient REAL
);

CREATE TABLE IF NOT EXISTS documents (
  id SERIAL PRIMARY KEY,
  title TEXT NOT NULL,
  doc_type TEXT NOT NULL,
  subject_id INTEGER NOT NULL REFERENCES subjects(id) ON UPDATE CASCADE ON DELETE RESTRICT,
  file_url TEXT NOT NULL,
  description TEXT,
  year INTEGER,
  uploaded_by_id INTEGER NOT NULL REFERENCES users(id) ON UPDATE CASCADE ON DELETE RESTRICT,
  download_count INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS forum_posts (
  id SERIAL PRIMARY KEY,
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  author_id INTEGER NOT NULL REFERENCES users(id) ON UPDATE CASCADE ON DELETE CASCADE,
  subject_id INTEGER REFERENCES subjects(id) ON UPDATE CASCADE ON DELETE SET NULL,
  votes INTEGER NOT NULL DEFAULT 0,
  resolved BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS forum_answers (
  id SERIAL PRIMARY KEY,
  content TEXT NOT NULL,
  post_id INTEGER NOT NULL REFERENCES forum_posts(id) ON UPDATE CASCADE ON DELETE CASCADE,
  author_id INTEGER NOT NULL REFERENCES users(id) ON UPDATE CASCADE ON DELETE CASCADE,
  votes INTEGER NOT NULL DEFAULT 0,
  is_accepted BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS forum_votes (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(id) ON UPDATE CASCADE ON DELETE CASCADE,
  target_type TEXT NOT NULL,
  target_id INTEGER NOT NULL,
  value INTEGER NOT NULL CHECK (value IN (-1, 1)),
  CONSTRAINT forum_votes_one_vote UNIQUE (user_id, target_type, target_id)
);

CREATE TABLE IF NOT EXISTS calendar_events (
  id SERIAL PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT,
  event_type TEXT NOT NULL DEFAULT 'exam',
  start_date TIMESTAMPTZ NOT NULL,
  end_date TIMESTAMPTZ,
  location TEXT,
  level_id INTEGER REFERENCES levels(id) ON UPDATE CASCADE ON DELETE SET NULL,
  filiere_id INTEGER REFERENCES filieres(id) ON UPDATE CASCADE ON DELETE SET NULL,
  subject_id INTEGER REFERENCES subjects(id) ON UPDATE CASCADE ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS favorites (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(id) ON UPDATE CASCADE ON DELETE CASCADE,
  document_id INTEGER NOT NULL REFERENCES documents(id) ON UPDATE CASCADE ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT favorites_one_document_per_user UNIQUE (user_id, document_id)
);

CREATE TABLE IF NOT EXISTS notifications (
  id SERIAL PRIMARY KEY,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  notif_type TEXT NOT NULL DEFAULT 'system',
  is_read BOOLEAN NOT NULL DEFAULT FALSE,
  user_id INTEGER REFERENCES users(id) ON UPDATE CASCADE ON DELETE CASCADE,
  related_id INTEGER,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS contributions (
  id SERIAL PRIMARY KEY,
  title TEXT NOT NULL,
  file_url TEXT NOT NULL,
  doc_type TEXT NOT NULL,
  subject_id INTEGER NOT NULL REFERENCES subjects(id) ON UPDATE CASCADE ON DELETE RESTRICT,
  contributor_id INTEGER NOT NULL REFERENCES users(id) ON UPDATE CASCADE ON DELETE CASCADE,
  status TEXT NOT NULL DEFAULT 'pending',
  admin_note TEXT,
  description TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS users_email_idx ON users (LOWER(email));
CREATE INDEX IF NOT EXISTS documents_subject_idx ON documents (subject_id);
CREATE INDEX IF NOT EXISTS documents_created_at_idx ON documents (created_at DESC);
CREATE INDEX IF NOT EXISTS forum_posts_created_at_idx ON forum_posts (created_at DESC);
CREATE INDEX IF NOT EXISTS forum_answers_post_idx ON forum_answers (post_id);
CREATE INDEX IF NOT EXISTS calendar_events_start_date_idx ON calendar_events (start_date);
CREATE INDEX IF NOT EXISTS notifications_user_idx ON notifications (user_id, is_read);
CREATE INDEX IF NOT EXISTS contributions_status_idx ON contributions (status, created_at DESC);