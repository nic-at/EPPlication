-- Convert schema '/home/david/dev/EPPlication/script/../lib/EPPlication/Util/../../../db_upgrades/_source/deploy/40/001-auto.yml' to '/home/david/dev/EPPlication/script/../lib/EPPlication/Util/../../../db_upgrades/_source/deploy/41/001-auto.yml':;

;
BEGIN;

;


-- most likely no need to drop index because i removed the create line in
-- db_upgrades/PostgreSQL/upgrade/38-39/001-auto.sql
-- to be on the safe side still drop it but add a "IF EXISTS"

--        DROP INDEX step_result_idx_job_id_length_node_node_position;
DROP INDEX IF EXISTS step_result_idx_job_id_length_node_node_position;

;
CREATE INDEX step_result_idx_job_id_node_position on step_result (job_id, node, position);

;

COMMIT;

