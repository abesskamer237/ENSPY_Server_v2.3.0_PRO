-- =============================================
--  ENSPY Platform — Données initiales
--  Exécuter APRÈS la première migration Drizzle
-- =============================================

-- Niveaux
INSERT INTO levels (name, description) VALUES
  ('Niveau 1', 'Première année du cycle ingénieur'),
  ('Niveau 2', 'Deuxième année du cycle ingénieur')
ON CONFLICT (name) DO UPDATE SET description = EXCLUDED.description;

-- Niveaux 1 et 2 : tronc commun. Les spécialisations sont volontairement absentes.
INSERT INTO filieres (name, code, level_id, description)
SELECT seed.name, seed.code, levels.id, seed.description
FROM (VALUES
  ('Tronc Commun','TC','Niveau 1','Tronc commun première année'),
  ('Tronc Commun','TC','Niveau 2','Tronc commun deuxième année')
) AS seed(name,code,level_name,description)
JOIN levels ON levels.name=seed.level_name
WHERE NOT EXISTS (SELECT 1 FROM filieres WHERE filieres.level_id=levels.id AND filieres.code=seed.code);

-- Compte administrateur initial — changez immédiatement le mot de passe en production.
-- Le hash ci-dessous correspond au mot de passe de démonstration historique.
INSERT INTO users (name, email, password_hash, role, level_id, filiere_id)
SELECT
  'Admin ENSPY',
  'admin@enspy.cm',
  '$2b$10$6wqnQsjpy05N34wqXW765ecM1/tczJOYo00TGfhgV2cW7DGEh3RrC',
  'admin',
  levels.id,
  filieres.id
FROM levels
JOIN filieres ON filieres.level_id = levels.id AND filieres.code = 'TC'
WHERE levels.name = 'Niveau 1'
ON CONFLICT (email) DO NOTHING;

-- Matières de base
INSERT INTO subjects (name, code, level_id, filiere_id, coefficient)
SELECT seed.name, seed.code, levels.id, filieres.id, seed.coefficient
FROM (
  VALUES
    ('Algèbre Linéaire',            'ALGL1', 'Niveau 1', 'TC',   3::real),
    ('Analyse Mathématique',        'ANAL1', 'Niveau 1', 'TC',   3::real),
    ('Physique Générale',           'PHYG1', 'Niveau 1', 'TC',   2::real),
    ('Programmation C',             'PROGC', 'Niveau 1', 'TC',   2::real),
    ('Probabilités & Statistiques', 'PROB1', 'Niveau 1', 'TC',   2::real),
    ('Algorithmes & Structures',    'ALGO2', 'Niveau 2', 'TC',   4::real),
    ('Base de Données',             'BDD2',  'Niveau 2', 'TC',   3::real),
    ('Réseaux Informatiques',       'RES2',  'Niveau 2', 'TC',   3::real),
    ('Mécanique des Fluides',       'MECF2', 'Niveau 2', 'TC',   3::real),
    ('Électronique',                'ELEC2', 'Niveau 2', 'TC',   3::real)
) AS seed(name, code, level_name, filiere_code, coefficient)
JOIN levels ON levels.name = seed.level_name
JOIN filieres ON filieres.level_id = levels.id AND filieres.code = seed.filiere_code
WHERE NOT EXISTS (
  SELECT 1 FROM subjects
  WHERE subjects.level_id = levels.id
    AND subjects.filiere_id = filieres.id
    AND subjects.code = seed.code
);

-- Notification de bienvenue
INSERT INTO notifications (title, message, notif_type)
SELECT
  'Bienvenue sur ENSPY Platform',
  'La plateforme académique de l''ENSPY est maintenant en ligne. Accédez à vos cours, TD et épreuves.',
  'system'
WHERE NOT EXISTS (
  SELECT 1 FROM notifications
  WHERE title = 'Bienvenue sur ENSPY Platform'
    AND message = 'La plateforme académique de l''ENSPY est maintenant en ligne. Accédez à vos cours, TD et épreuves.'
);
