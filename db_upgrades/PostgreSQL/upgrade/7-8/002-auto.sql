-- Convert schema '/home/dt/dev/repo/EPPlication/script/../lib/EPPlication/../../db_upgrades/_source/deploy/7/001-auto.yml' to '/home/dt/dev/repo/EPPlication/script/../lib/EPPlication/../../db_upgrades/_source/deploy/8/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE test ADD CONSTRAINT test_name UNIQUE (name);

;

COMMIT;

