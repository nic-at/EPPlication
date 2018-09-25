-- Convert schema '/home/david/dev/EPPlication/script/../lib/EPPlication/../../db_upgrades/_source/deploy/23/001-auto.yml' to '/home/david/dev/EPPlication/script/../lib/EPPlication/../../db_upgrades/_source/deploy/24/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE job DROP CONSTRAINT job_fk_test_id;

;
ALTER TABLE job ADD CONSTRAINT job_fk_test_id FOREIGN KEY (test_id)
  REFERENCES test (id) ON DELETE CASCADE DEFERRABLE;

;

COMMIT;

