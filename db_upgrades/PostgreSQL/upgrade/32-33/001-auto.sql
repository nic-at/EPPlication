-- Convert schema '/home/david/dev/EPPlication/script/../lib/EPPlication/../../db_upgrades/_source/deploy/32/001-auto.yml' to '/home/david/dev/EPPlication/script/../lib/EPPlication/../../db_upgrades/_source/deploy/33/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE job ADD COLUMN config_id integer;

;
CREATE INDEX job_idx_config_id on job (config_id);

;
ALTER TABLE job ADD CONSTRAINT job_fk_config_id FOREIGN KEY (config_id)
  REFERENCES test (id) DEFERRABLE;

;

COMMIT;

