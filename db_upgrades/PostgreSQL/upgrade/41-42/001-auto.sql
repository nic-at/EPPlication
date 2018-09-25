-- Convert schema '/home/david/dev/EPPlication/script/../lib/EPPlication/Util/../../../db_upgrades/_source/deploy/41/001-auto.yml' to '/home/david/dev/EPPlication/script/../lib/EPPlication/Util/../../../db_upgrades/_source/deploy/42/001-auto.yml':;

;
BEGIN;

-- a job needs two position columns:
--    a) "node_position" holds the position of a node
--       relative to its parent node
--    b) "position" holds the absolute position within
--       a job
;
ALTER TABLE step_result ADD COLUMN node_position integer;
;
UPDATE step_result SET node_position = position;
;
ALTER TABLE step_result ALTER COLUMN node_position SET NOT NULL;
;
REINDEX INDEX step_result_idx_job_id_node_position;

;
COMMIT;
