-- Convert schema '/home/david/dev/EPPlication/script/../lib/EPPlication/../../db_upgrades/_source/deploy/26/001-auto.yml' to '/home/david/dev/EPPlication/script/../lib/EPPlication/../../db_upgrades/_source/deploy/27/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE job ADD COLUMN user_id integer;

;
CREATE INDEX job_idx_user_id on job (user_id);

;
ALTER TABLE job ADD CONSTRAINT job_fk_user_id FOREIGN KEY (user_id)
  REFERENCES "user" (id) ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;

-- BEGIN MANUAL EDIT
UPDATE job SET user_id = (SELECT id FROM "user" WHERE name = 'admin');
ALTER TABLE job ALTER COLUMN user_id SET NOT NULL;
-- END MANUAL EDIT

COMMIT;

