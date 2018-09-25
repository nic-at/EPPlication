-- Convert schema '/home/dt/dev/repo/EPPlication/script/../lib/EPPlication/../../db_upgrades/_source/deploy/1/001-auto.yml' to '/home/dt/dev/repo/EPPlication/script/../lib/EPPlication/../../db_upgrades/_source/deploy/2/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE test DROP CONSTRAINT test_fk_user_id;

;
DROP INDEX test_idx_user_id;

;
ALTER TABLE test DROP COLUMN user_id;

;

COMMIT;

