-- Convert schema '/home/david/dev/EPPlication/script/../lib/EPPlication/../../db_upgrades/_source/deploy/22/001-auto.yml' to '/home/david/dev/EPPlication/script/../lib/EPPlication/../../db_upgrades/_source/deploy/23/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE job ADD COLUMN data character varying;

;

COMMIT;

