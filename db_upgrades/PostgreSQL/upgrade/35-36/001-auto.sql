-- Convert schema '/home/david/dev/EPPlication/script/../lib/EPPlication/../../db_upgrades/_source/deploy/35/001-auto.yml' to '/home/david/dev/EPPlication/script/../lib/EPPlication/../../db_upgrades/_source/deploy/36/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE job DROP CONSTRAINT job_fk_config_id;

;
ALTER TABLE job DROP CONSTRAINT job_fk_test_id;

;
ALTER TABLE job DROP CONSTRAINT job_fk_user_id;

;
ALTER TABLE job ALTER COLUMN test_id DROP NOT NULL;

;
ALTER TABLE job ALTER COLUMN user_id DROP NOT NULL;

;
ALTER TABLE job ADD CONSTRAINT job_fk_config_id FOREIGN KEY (config_id)
  REFERENCES test (id) ON DELETE SET NULL DEFERRABLE;

;
ALTER TABLE job ADD CONSTRAINT job_fk_test_id FOREIGN KEY (test_id)
  REFERENCES test (id) ON DELETE SET NULL DEFERRABLE;

;
ALTER TABLE job ADD CONSTRAINT job_fk_user_id FOREIGN KEY (user_id)
  REFERENCES "user" (id) ON DELETE SET NULL DEFERRABLE;

;

COMMIT;

