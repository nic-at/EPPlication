-- rename role 'can_copy_users' to 'can_clone_users'
UPDATE role SET name = 'can_clone_users' WHERE name = 'can_copy_users';
