-- Convert schema '/home/david/dev/EPPlication/script/../lib/EPPlication/Util/../../../db_upgrades/_source/deploy/37/001-auto.yml' to '/home/david/dev/EPPlication/script/../lib/EPPlication/Util/../../../db_upgrades/_source/deploy/38/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE job DROP COLUMN warnings;

;

COMMIT;

