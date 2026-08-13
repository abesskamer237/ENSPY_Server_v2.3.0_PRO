CREATE TABLE IF NOT EXISTS academic_years (
  id SERIAL PRIMARY KEY,
  label TEXT NOT NULL UNIQUE,
  is_active BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE TABLE IF NOT EXISTS semesters (
  id SERIAL PRIMARY KEY,
  academic_year_id INTEGER NOT NULL REFERENCES academic_years(id) ON UPDATE CASCADE ON DELETE CASCADE,
  level_id INTEGER NOT NULL REFERENCES levels(id) ON UPDATE CASCADE ON DELETE RESTRICT,
  number INTEGER NOT NULL CHECK (number IN (1,2)),
  title TEXT NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT semesters_year_level_number_unique UNIQUE (academic_year_id, level_id, number)
);
CREATE TABLE IF NOT EXISTS semester_subjects (
  id SERIAL PRIMARY KEY,
  semester_id INTEGER NOT NULL REFERENCES semesters(id) ON UPDATE CASCADE ON DELETE CASCADE,
  subject_id INTEGER NOT NULL REFERENCES subjects(id) ON UPDATE CASCADE ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT semester_subject_unique UNIQUE (semester_id, subject_id)
);
CREATE TABLE IF NOT EXISTS academic_resources (
  id SERIAL PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT,
  resource_type TEXT NOT NULL DEFAULT 'lesson',
  level_id INTEGER NOT NULL REFERENCES levels(id) ON UPDATE CASCADE ON DELETE RESTRICT,
  semester_id INTEGER REFERENCES semesters(id) ON UPDATE CASCADE ON DELETE SET NULL,
  subject_id INTEGER REFERENCES subjects(id) ON UPDATE CASCADE ON DELETE SET NULL,
  file_url TEXT,
  external_url TEXT,
  mime_type TEXT,
  original_name TEXT,
  file_size BIGINT,
  academic_year_id INTEGER REFERENCES academic_years(id) ON UPDATE CASCADE ON DELETE SET NULL,
  status TEXT NOT NULL DEFAULT 'published',
  uploaded_by_id INTEGER REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT academic_resources_source_check CHECK (file_url IS NOT NULL OR external_url IS NOT NULL)
);
ALTER TABLE notifications ADD COLUMN IF NOT EXISTS level_id INTEGER REFERENCES levels(id) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE notifications ADD COLUMN IF NOT EXISTS semester_id INTEGER REFERENCES semesters(id) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE notifications ADD COLUMN IF NOT EXISTS subject_id INTEGER REFERENCES subjects(id) ON UPDATE CASCADE ON DELETE CASCADE;
CREATE TABLE IF NOT EXISTS admin_audit_logs (
  id BIGSERIAL PRIMARY KEY,
  admin_id INTEGER REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL,
  action TEXT NOT NULL,
  entity_type TEXT NOT NULL,
  entity_id INTEGER,
  details JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS semesters_level_idx ON semesters(level_id, number);
CREATE INDEX IF NOT EXISTS semester_subjects_semester_idx ON semester_subjects(semester_id);
CREATE INDEX IF NOT EXISTS semester_subjects_subject_idx ON semester_subjects(subject_id);
CREATE INDEX IF NOT EXISTS academic_resources_level_idx ON academic_resources(level_id, semester_id, subject_id, created_at DESC);
CREATE INDEX IF NOT EXISTS academic_resources_type_idx ON academic_resources(resource_type, created_at DESC);
CREATE INDEX IF NOT EXISTS notifications_target_level_idx ON notifications(level_id, semester_id, subject_id, created_at DESC);
CREATE INDEX IF NOT EXISTS admin_audit_created_idx ON admin_audit_logs(created_at DESC);
INSERT INTO filieres (name, code, level_id, description)
SELECT 'Tronc Commun', 'TC', l.id, CASE WHEN l.name='Niveau 1' THEN 'Tronc commun première année' ELSE 'Tronc commun deuxième année' END
FROM levels l WHERE l.name IN ('Niveau 1','Niveau 2')
AND NOT EXISTS (SELECT 1 FROM filieres f WHERE f.level_id=l.id AND f.code='TC');
INSERT INTO academic_years (label,is_active) VALUES ('2026/2027',TRUE)
ON CONFLICT(label) DO UPDATE SET is_active=TRUE;
INSERT INTO semesters (academic_year_id,level_id,number,title,is_active)
SELECT ay.id,l.id,s.number,CASE WHEN s.number=1 THEN 'Semestre 1' ELSE 'Semestre 2' END,(s.number=1)
FROM academic_years ay CROSS JOIN levels l CROSS JOIN (VALUES(1),(2)) s(number)
WHERE ay.label='2026/2027' AND l.name IN ('Niveau 1','Niveau 2')
ON CONFLICT (academic_year_id,level_id,number) DO NOTHING;
