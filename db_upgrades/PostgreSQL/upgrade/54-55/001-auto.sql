-- Convert schema '/home/david/dev/EPPlication/script/../lib/EPPlication/Util/../../../db_upgrades/_source/deploy/54/001-auto.yml' to '/home/david/dev/EPPlication/script/../lib/EPPlication/Util/../../../db_upgrades/_source/deploy/55/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE step ADD COLUMN highlight boolean DEFAULT '0' NOT NULL;

;

COMMIT;

