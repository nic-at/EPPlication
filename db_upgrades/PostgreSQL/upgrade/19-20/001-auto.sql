-- Convert schema '/home/david/dev/EPPlication/script/../lib/EPPlication/../../db_upgrades/_source/deploy/19/001-auto.yml' to '/home/david/dev/EPPlication/script/../lib/EPPlication/../../db_upgrades/_source/deploy/20/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE "job" (
  "id" serial NOT NULL,
  "test_id" integer NOT NULL,
  "type" character varying NOT NULL,
  "status" character varying DEFAULT 'pending' NOT NULL,
  PRIMARY KEY ("id")
);

;

COMMIT;

