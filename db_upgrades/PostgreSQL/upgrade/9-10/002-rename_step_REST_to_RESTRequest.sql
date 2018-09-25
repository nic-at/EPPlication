-- step type REST has been renamed to RESTRequest
UPDATE step SET type = 'RESTRequest' WHERE type = 'REST';
