-- Convert schema '/home/david/dev/EPPlication/script/../lib/EPPlication/Util/../../../db_upgrades/_source/deploy/59/001-auto.yml' to '/home/david/dev/EPPlication/script/../lib/EPPlication/Util/../../../db_upgrades/_source/deploy/60/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE "branch" (
  "id" serial NOT NULL,
  "name" character varying NOT NULL,
  PRIMARY KEY ("id"),
  CONSTRAINT "branch_name" UNIQUE ("name")
);

;
ALTER TABLE test DROP CONSTRAINT test_name;

;
-- originally created SQL from schema
-- ALTER TABLE test ADD COLUMN branch_id integer NOT NULL;
-- BEGIN manual SQL
INSERT INTO branch(id, name) VALUES (1,'master');
ALTER TABLE test ADD COLUMN branch_id integer;
UPDATE test SET branch_id = 1;
ALTER TABLE test ALTER COLUMN branch_id SET NOT NULL;
-- END manual SQL

;
CREATE INDEX test_idx_branch_id on test (branch_id);

;
ALTER TABLE test ADD CONSTRAINT test_branch_id_name UNIQUE (branch_id, name);

;
ALTER TABLE test ADD CONSTRAINT test_fk_branch_id FOREIGN KEY (branch_id)
  REFERENCES branch (id) ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;

COMMIT;

