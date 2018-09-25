-- Convert schema '/home/david/dev/EPPlication/script/../lib/EPPlication/Util/../../../db_upgrades/_source/deploy/58/001-auto.yml' to '/home/david/dev/EPPlication/script/../lib/EPPlication/Util/../../../db_upgrades/_source/deploy/59/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE tag ADD COLUMN color character varying DEFAULT '#ffffff' NOT NULL;

;

COMMIT;

