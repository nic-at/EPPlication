-- Convert schema '/home/david/dev/EPPlication/script/../lib/EPPlication/Util/../../../db_upgrades/_source/deploy/46/001-auto.yml' to '/home/david/dev/EPPlication/script/../lib/EPPlication/Util/../../../db_upgrades/_source/deploy/47/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE step ADD COLUMN condition character varying DEFAULT '1' NOT NULL;

;
COMMIT;

