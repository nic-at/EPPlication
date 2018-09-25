-- Convert schema '/home/david/dev/EPPlication/script/../lib/EPPlication/Util/../../../db_upgrades/_source/deploy/38/001-auto.yml' to '/home/david/dev/EPPlication/script/../lib/EPPlication/Util/../../../db_upgrades/_source/deploy/39/001-auto.yml':;

;
BEGIN;

-- BEGIN custom SQL
;
ALTER TABLE step_result ADD COLUMN details character varying;
;
UPDATE step_result SET details = "in" || E'\n' || "out";
;
ALTER TABLE step_result DROP COLUMN "in";
;
ALTER TABLE step_result DROP COLUMN "out";

;
ALTER TABLE step_result ADD COLUMN node character varying;
;

-- 1      => 1.1
-- 99     => 1.1
-- 100    => 1.2
-- 101    => 1.2
-- 200    => 1.3
-- 201    => 1.3
UPDATE step_result SET node = '1.' || ((position - 1) / 100) + 1;
;

-- 1      => 1
-- 2      => 2
-- 99     => 99
-- 100    => 100
-- 101    => 1
-- 200    => 100
-- 201    => 1
UPDATE step_result SET position = ( (position - 1) % 100) + 1;
;
DROP INDEX step_result_idx_job_id_position;
;

-- this is not the index so i commented it but left it here for documentation reasons
--CREATE INDEX step_result_idx_job_id_length_node_node_position ON step_result (job_id, length(node), node, position);

-- END custom SQL

;
COMMIT;

