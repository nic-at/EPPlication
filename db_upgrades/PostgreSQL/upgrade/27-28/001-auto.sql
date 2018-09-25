-- Convert schema '/home/david/dev/EPPlication/script/../lib/EPPlication/../../db_upgrades/_source/deploy/27/001-auto.yml' to '/home/david/dev/EPPlication/script/../lib/EPPlication/../../db_upgrades/_source/deploy/28/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE job DROP CONSTRAINT job_fk_user_id;

;
ALTER TABLE job ADD CONSTRAINT job_fk_user_id FOREIGN KEY (user_id)
  REFERENCES "user" (id) ON DELETE CASCADE DEFERRABLE;

;

COMMIT;

