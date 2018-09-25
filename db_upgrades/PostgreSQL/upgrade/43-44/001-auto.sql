-- Convert schema '/home/david/dev/EPPlication/script/../lib/EPPlication/Util/../../../db_upgrades/_source/deploy/43/001-auto.yml' to '/home/david/dev/EPPlication/script/../lib/EPPlication/Util/../../../db_upgrades/_source/deploy/44/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE job ADD COLUMN sticky boolean DEFAULT '0' NOT NULL;

;

COMMIT;

