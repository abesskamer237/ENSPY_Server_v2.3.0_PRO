-- ENSPY Platform v2.2.0 PATCH3
-- Exact Niveau 1 / Niveau 2 curriculum for 2026/2027.
-- Idempotent: safe to run more than once.

-- Multimedia attachments for announcements.
ALTER TABLE notifications ADD COLUMN IF NOT EXISTS media_url TEXT;
ALTER TABLE notifications ADD COLUMN IF NOT EXISTS media_type TEXT;
ALTER TABLE notifications ADD COLUMN IF NOT EXISTS media_name TEXT;
ALTER TABLE notifications ADD COLUMN IF NOT EXISTS media_mime_type TEXT;
ALTER TABLE notifications ADD COLUMN IF NOT EXISTS media_size BIGINT;
ALTER TABLE notifications ADD COLUMN IF NOT EXISTS semester_id INTEGER REFERENCES semesters(id) ON UPDATE CASCADE ON DELETE SET NULL;
ALTER TABLE notifications ADD COLUMN IF NOT EXISTS subject_id INTEGER REFERENCES subjects(id) ON UPDATE CASCADE ON DELETE SET NULL;
CREATE INDEX IF NOT EXISTS notifications_media_idx ON notifications(media_type, created_at DESC);

-- Make sure the 2026/2027 academic structure exists.
UPDATE academic_years SET is_active=TRUE WHERE label='2026/2027';
INSERT INTO academic_years (label,is_active)
SELECT '2026/2027', TRUE
WHERE NOT EXISTS (SELECT 1 FROM academic_years WHERE label='2026/2027');

UPDATE semesters sem
SET title=CASE WHEN sem.number=1 THEN 'Semestre 1' ELSE 'Semestre 2' END,
    is_active=CASE WHEN sem.number=1 THEN TRUE ELSE FALSE END
FROM academic_years ay, levels l
WHERE sem.academic_year_id=ay.id
  AND sem.level_id=l.id
  AND ay.label='2026/2027'
  AND l.name IN ('Niveau 1','Niveau 2');

INSERT INTO semesters (academic_year_id,level_id,number,title,is_active)
SELECT ay.id,l.id,s.number,CASE WHEN s.number=1 THEN 'Semestre 1' ELSE 'Semestre 2' END,
       CASE WHEN s.number=1 THEN TRUE ELSE FALSE END
FROM academic_years ay
CROSS JOIN levels l
CROSS JOIN (VALUES(1),(2)) s(number)
WHERE ay.label='2026/2027' AND l.name IN ('Niveau 1','Niveau 2')
  AND NOT EXISTS (
    SELECT 1 FROM semesters existing
    WHERE existing.academic_year_id=ay.id
      AND existing.level_id=l.id
      AND existing.number=s.number
  );

-- Exact curriculum supplied by the ENSPY project owner.
-- This file is executed by a single psql session. Keep the temporary
-- curriculum table for the whole session; ON COMMIT DROP would remove it
-- immediately because psql runs statements in autocommit mode.
CREATE TEMP TABLE _enspy_curriculum (
  level_no INTEGER,
  semester_no INTEGER,
  code TEXT,
  name TEXT,
  credits REAL
);

INSERT INTO _enspy_curriculum(level_no,semester_no,code,name,credits) VALUES
(1,1,'LANG1','Langue 1',2),
(1,1,'EM1','Électromagnétique 1',4),
(1,1,'EPS1','EPS',1),
(1,1,'TPPHY1','TP Physique 1',4),
(1,1,'MEC1','Mécanique 1',4),
(1,1,'CHIM1','Chimie générale',4),
(1,1,'ALGGEN1','Algèbre générale',4),
(1,1,'ANR1','Analyse Réelle 1',4),
(1,1,'INFO1','Informatique 1',3),

(1,2,'LANG2','Langue 2',1),
(1,2,'ETHMAN1','Éthique 1 et management 1',2),
(1,2,'ELEC2','Électroniques 2',4),
(1,2,'ALGL1','Algèbre linéaire',4),
(1,2,'GEOAE1','Géométrie Aff&Eucl',4),
(1,2,'MATSCI1','Science des matériaux',4),
(1,2,'DESSIN1','Dessin technique',4),
(1,2,'ANR2','Analyse Relle 2',4),

(2,1,'LANG3','Langue 3',1),
(2,1,'EPS2','EPS',1),
(2,1,'ETHMAN1','Éthique 1 et management 1',2),
(2,1,'INFO3','Informatique 3',3),
(2,1,'PROB2','Probabilité et statistiques',4),
(2,1,'ELECIN2','Électrocinétique',4),
(2,1,'MEC2','Mécanique 2',4),
(2,1,'TPPHY2','TP Physique 2',4),
(2,1,'SERINT2','Séries et intégrales',4),
(2,1,'ALGMULT2','Algèbre multilinéaire',4),

(2,2,'LANG4','Langue 4',1),
(2,2,'EPS2','EPS',1),
(2,2,'ETHMAN2','Éthique 2 et management 2',2),
(2,2,'OPG2','Optique géométrique',4),
(2,2,'CEE2','Circuits électriques et électroniques',4),
(2,2,'THERMO2','Thermodynamique',4),
(2,2,'STAT2','Statique',4),
(2,2,'INFO4','Informatique 4',3),
(2,2,'ANV2','Analyse vectoriel',4),
(2,2,'ANNUM2','Analyse numéro',4);

-- Update existing records with the supplied names/credits and create missing ones.
UPDATE subjects s
SET name=c.name, coefficient=c.credits
FROM _enspy_curriculum c
JOIN levels l ON l.name='Niveau '||c.level_no
JOIN filieres f ON f.level_id=l.id AND f.code='TC'
WHERE s.level_id=l.id AND s.filiere_id=f.id AND s.code=c.code;

INSERT INTO subjects(name,code,level_id,filiere_id,coefficient)
SELECT c.name,c.code,l.id,f.id,c.credits
FROM _enspy_curriculum c
JOIN levels l ON l.name='Niveau '||c.level_no
JOIN filieres f ON f.level_id=l.id AND f.code='TC'
WHERE NOT EXISTS (
  SELECT 1 FROM subjects s
  WHERE s.level_id=l.id AND s.filiere_id=f.id AND s.code=c.code
);

-- Rebuild only the 2026/2027 semester assignments for levels 1 and 2.
DELETE FROM semester_subjects ss
USING semesters sem, academic_years ay
WHERE ss.semester_id=sem.id
  AND sem.academic_year_id=ay.id
  AND ay.label='2026/2027'
  AND sem.level_id IN (
    SELECT id FROM levels WHERE name IN ('Niveau 1','Niveau 2')
  );

INSERT INTO semester_subjects(semester_id,subject_id)
SELECT sem.id,s.id
FROM _enspy_curriculum c
JOIN levels l ON l.name='Niveau '||c.level_no
JOIN filieres f ON f.level_id=l.id AND f.code='TC'
JOIN subjects s ON s.level_id=l.id AND s.filiere_id=f.id AND s.code=c.code
JOIN academic_years ay ON ay.label='2026/2027'
JOIN semesters sem ON sem.academic_year_id=ay.id
  AND sem.level_id=l.id
  AND sem.number=c.semester_no
WHERE NOT EXISTS (
  SELECT 1 FROM semester_subjects existing
  WHERE existing.semester_id=sem.id
    AND existing.subject_id=s.id
);
