-- Convert schema '/home/david/dev/EPPlication/script/../lib/EPPlication/../../db_upgrades/_source/deploy/20/001-auto.yml' to '/home/david/dev/EPPlication/script/../lib/EPPlication/../../db_upgrades/_source/deploy/21/001-auto.yml':;

;
BEGIN;

;
CREATE INDEX job_idx_test_id on job (test_id);

;
ALTER TABLE job ADD CONSTRAINT job_fk_test_id FOREIGN KEY (test_id)
  REFERENCES test (id) ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;

COMMIT;

