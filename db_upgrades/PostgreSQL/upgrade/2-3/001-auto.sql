-- Convert schema '/home/dt/dev/repo/EPPlication/script/../lib/EPPlication/../../db_upgrades/_source/deploy/2/001-auto.yml' to '/home/dt/dev/repo/EPPlication/script/../lib/EPPlication/../../db_upgrades/_source/deploy/3/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE test_tag DROP CONSTRAINT test_tag_fk_tag_id;

;
ALTER TABLE user_role DROP CONSTRAINT user_role_fk_role_id;

;
ALTER TABLE test_tag ADD CONSTRAINT test_tag_fk_tag_id FOREIGN KEY (tag_id)
  REFERENCES tag (id) ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE user_role ADD CONSTRAINT user_role_fk_role_id FOREIGN KEY (role_id)
  REFERENCES role (id) ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;

COMMIT;

