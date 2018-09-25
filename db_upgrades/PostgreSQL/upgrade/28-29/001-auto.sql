-- Convert schema '/home/david/dev/EPPlication/script/../lib/EPPlication/../../db_upgrades/_source/deploy/28/001-auto.yml' to '/home/david/dev/EPPlication/script/../lib/EPPlication/../../db_upgrades/_source/deploy/29/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE job ADD COLUMN comment character varying;

;

COMMIT;

