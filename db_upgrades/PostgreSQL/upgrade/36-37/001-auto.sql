-- Convert schema '/home/david/dev/EPPlication/script/../lib/EPPlication/../../db_upgrades/_source/deploy/36/001-auto.yml' to '/home/david/dev/EPPlication/script/../lib/EPPlication/../../db_upgrades/_source/deploy/37/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE "step_result" (
  "id" serial NOT NULL,
  "job_id" integer NOT NULL,
  "test_id" integer,
  "step_id" integer,
  "name" character varying NOT NULL,
  "type" character varying NOT NULL,
  "status" character varying NOT NULL,
  "in" character varying NOT NULL,
  "out" character varying NOT NULL,
  "position" integer NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "step_result_idx_job_id" on "step_result" ("job_id");
CREATE INDEX "step_result_idx_job_id_position" on "step_result" ("job_id", "position");

;
ALTER TABLE "step_result" ADD CONSTRAINT "step_result_fk_job_id" FOREIGN KEY ("job_id")
  REFERENCES "job" ("id") ON DELETE CASCADE DEFERRABLE;

;
ALTER TABLE job ADD COLUMN num_steps integer;

;
ALTER TABLE job ADD COLUMN errors integer;

;
ALTER TABLE job ADD COLUMN warnings integer;

;

COMMIT;

