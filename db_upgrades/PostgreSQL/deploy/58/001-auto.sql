-- 
-- Created by SQL::Translator::Producer::PostgreSQL
-- Created on Mon Apr 16 12:08:52 2018
-- 
;
--
-- Table: role
--
CREATE TABLE "role" (
  "id" serial NOT NULL,
  "name" character varying NOT NULL,
  PRIMARY KEY ("id"),
  CONSTRAINT "role_name" UNIQUE ("name")
);

;
--
-- Table: tag
--
CREATE TABLE "tag" (
  "id" serial NOT NULL,
  "name" character varying NOT NULL,
  PRIMARY KEY ("id"),
  CONSTRAINT "tag_name" UNIQUE ("name")
);

;
--
-- Table: test
--
CREATE TABLE "test" (
  "id" serial NOT NULL,
  "name" character varying NOT NULL,
  PRIMARY KEY ("id"),
  CONSTRAINT "test_name" UNIQUE ("name")
);

;
--
-- Table: user
--
CREATE TABLE "user" (
  "id" serial NOT NULL,
  "name" character varying NOT NULL,
  "password" text NOT NULL,
  PRIMARY KEY ("id"),
  CONSTRAINT "user_name" UNIQUE ("name")
);

;
--
-- Table: step
--
CREATE TABLE "step" (
  "id" serial NOT NULL,
  "name" character varying NOT NULL,
  "position" integer NOT NULL,
  "active" boolean DEFAULT '1' NOT NULL,
  "highlight" boolean DEFAULT '0' NOT NULL,
  "condition" character varying DEFAULT '1' NOT NULL,
  "test_id" integer NOT NULL,
  "type" character varying NOT NULL,
  "parameters" character varying,
  PRIMARY KEY ("id")
);
CREATE INDEX "step_idx_test_id" on "step" ("test_id");
CREATE INDEX "step_idx_type" on "step" ("type");

;
--
-- Table: job
--
CREATE TABLE "job" (
  "id" serial NOT NULL,
  "test_id" integer,
  "user_id" integer,
  "config_id" integer,
  "type" character varying NOT NULL,
  "comment" character varying,
  "duration" character varying,
  "num_steps" integer,
  "errors" integer,
  "status" character varying DEFAULT 'pending' NOT NULL,
  "sticky" boolean DEFAULT '0' NOT NULL,
  "created" timestamp NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "job_idx_config_id" on "job" ("config_id");
CREATE INDEX "job_idx_test_id" on "job" ("test_id");
CREATE INDEX "job_idx_user_id" on "job" ("user_id");

;
--
-- Table: test_tag
--
CREATE TABLE "test_tag" (
  "id" serial NOT NULL,
  "test_id" integer NOT NULL,
  "tag_id" integer NOT NULL,
  PRIMARY KEY ("id"),
  CONSTRAINT "test_tag_test_id_tag_id" UNIQUE ("test_id", "tag_id")
);
CREATE INDEX "test_tag_idx_tag_id" on "test_tag" ("tag_id");
CREATE INDEX "test_tag_idx_test_id" on "test_tag" ("test_id");

;
--
-- Table: user_role
--
CREATE TABLE "user_role" (
  "id" serial NOT NULL,
  "user_id" integer NOT NULL,
  "role_id" integer NOT NULL,
  PRIMARY KEY ("id"),
  CONSTRAINT "user_role_user_id_role_id" UNIQUE ("user_id", "role_id")
);
CREATE INDEX "user_role_idx_role_id" on "user_role" ("role_id");
CREATE INDEX "user_role_idx_user_id" on "user_role" ("user_id");

;
--
-- Table: step_result
--
CREATE TABLE "step_result" (
  "id" serial NOT NULL,
  "job_id" integer NOT NULL,
  "test_id" integer,
  "step_id" integer,
  "node" character varying,
  "details" character varying,
  "node_position" integer NOT NULL,
  "position" integer NOT NULL,
  "name" character varying NOT NULL,
  "type" character varying NOT NULL,
  "status" character varying NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "step_result_idx_job_id" on "step_result" ("job_id");
CREATE INDEX "step_result_idx_job_id_node_position" on "step_result" ("job_id", "node", "position");

;
--
-- Foreign Key Definitions
--

;
ALTER TABLE "step" ADD CONSTRAINT "step_fk_test_id" FOREIGN KEY ("test_id")
  REFERENCES "test" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "job" ADD CONSTRAINT "job_fk_config_id" FOREIGN KEY ("config_id")
  REFERENCES "test" ("id") ON DELETE SET NULL DEFERRABLE;

;
ALTER TABLE "job" ADD CONSTRAINT "job_fk_test_id" FOREIGN KEY ("test_id")
  REFERENCES "test" ("id") ON DELETE SET NULL DEFERRABLE;

;
ALTER TABLE "job" ADD CONSTRAINT "job_fk_user_id" FOREIGN KEY ("user_id")
  REFERENCES "user" ("id") ON DELETE SET NULL DEFERRABLE;

;
ALTER TABLE "test_tag" ADD CONSTRAINT "test_tag_fk_tag_id" FOREIGN KEY ("tag_id")
  REFERENCES "tag" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "test_tag" ADD CONSTRAINT "test_tag_fk_test_id" FOREIGN KEY ("test_id")
  REFERENCES "test" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "user_role" ADD CONSTRAINT "user_role_fk_role_id" FOREIGN KEY ("role_id")
  REFERENCES "role" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "user_role" ADD CONSTRAINT "user_role_fk_user_id" FOREIGN KEY ("user_id")
  REFERENCES "user" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "step_result" ADD CONSTRAINT "step_result_fk_job_id" FOREIGN KEY ("job_id")
  REFERENCES "job" ("id") ON DELETE CASCADE DEFERRABLE;

;
