/*
	This file drops and creates all procedures and triggers for the
	part tracker database.
*/
--set client_min_messages TO WARNING;
--\set VERBOSE terse
/*************************** Begin mecb_config fiddly bits ****************/
/*
	The api_config_ins procedure inserts a new record into the mecb_config
	table.  This is a standalone configuration record and defines the
	configuration type id (config_type_id) that is associated with it.  The
	association between the mecb_config and mecb_config_type tables is
	many to one.  Multiple mecb_config records can have the same
	config_type_id.

	Currently, the procedure itself is called directly to effect changes
	to the underlying table.  The table itself should not be accessed
	directly when inserting a record into this table:

	CALL api_config_ins (<new config>,<associated config type>)
*/
DROP PROCEDURE IF EXISTS api_config_ins CASCADE;
CREATE OR REPLACE PROCEDURE api_config_ins(
       c_name	  VARCHAR,
       ct_name	  VARCHAR,
       slots	  INTEGER DEFAULT 1
) AS $$
DECLARE
	_counter	INTEGER:= 0;
	_rowcount	INTEGER:= 0;
	_max_id		BIGINT:= 0;
	_ct_id		BIGINT:= 0;
BEGIN

	IF c_name IS NULL OR LENGTH(TRIM(c_name)) = 0 THEN
	   RAISE EXCEPTION '00201: Configuration must be non blank.';
	END IF;

	IF ct_name IS NULL OR LENGTH(TRIM(ct_name)) = 0 THEN
	   RAISE EXCEPTION '00202: Configuration type must be non blank.';
	END IF;
	
	-- Obtain the next config_id in the mecb_config table.
	SELECT
		COALESCE(MAX(config_id) + 1,1)
	INTO
		_max_id
	FROM
		mecb_config;

	-- Obtain the config_type_id from the mecb_config_type table.
	SELECT
		COALESCE(config_type_id,0)
	INTO
		_ct_id
	FROM
		mecb_config_type
	WHERE
		config_type	= ct_name;

	IF _ct_id = 0 OR _ct_id IS NULL THEN
	   RAISE EXCEPTION '00203 Configuration type not found.';
	END IF;

	-- See if the configuration already exists.
	SELECT
		COUNT(*)
	INTO
		_counter
	FROM
		mecb_config
	WHERE
		config		= c_name;

	IF _counter > 0 THEN
	   RAISE EXCEPTION '00204: Configuration already exists.';
	END IF;

	-- Slots have to be at least one.
	IF slots < 1 THEN
	   slots = 1;
	END IF;
	
	-- Insert the new configuration record into the mecb_config table.
	-- Since this is a new record, the config_id, parent_config_id
	-- and ancestor_config_id are all the same.
	INSERT INTO mecb_config (
	       config,
	       config_id,
	       ancestor_config_id,
	       parent_config_id,
	       config_type_id,
	       tot_slots,
	       level)
	VALUES	(
		c_name,
		_max_id,
		_max_id,
		_max_id,
		_ct_id,
		slots,
		0);

	GET DIAGNOSTICS _rowcount = row_count;

	IF _rowcount = 0 THEN
	   RAISE EXCEPTION '00205: Insert into mecb_config failed.';
	END IF;

/*
	INSERT INTO mecb_config_audit (
	       config_id,
	       hist_id,
	       action)
	VALUES (
	       _max_id,
	       1,
	       'Create');
*/
END; $$
LANGUAGE plpgsql;

/*
	The api_config_upd is the procedure used to move configurations
	around.

	This API will make a configuration the child of another configuration
	or will remove the configuration as a child and make it a
	standalone configuration.
*/
DROP PROCEDURE IF EXISTS api_config_upd CASCADE;
CREATE OR REPLACE PROCEDURE api_config_upd (
       parent_config	    VARCHAR,
       part_config	    VARCHAR) AS $$
DECLARE
	_c_id			BIGINT:= 0;
	_pc_id			BIGINT:= 0;
	_ac_id			BIGINT:= 0;
	_level			INTEGER:= 0;
	_counter		INTEGER:= 0;
	_rowcount		INTEGER:= 0;
	_hist_id		INTEGER:= 0;
BEGIN

	IF parent_config IS NULL OR LENGTH(TRIM(parent_config)) = 0 THEN
	   RAISE EXCEPTION '00211 Parent configuration must be non blank.';
	END IF;

	IF part_config IS NULL OR LENGTH(TRIM(part_config)) = 0 THEN
	   RAISE EXCEPTION '00212 Configuration must be non blank.';
	END IF;
	
	-- Ensure that the part configuration exists.
	SELECT
		config_id
	INTO
		_c_id
	FROM
		mecb_config
	WHERE
		config		= part_config;

	IF _c_id IS NULL THEN
	   RAISE EXCEPTION '00213: This configuration does not exist in '
	   	 'mecb_config table.';
	END IF;

	-- Ensure that the parent configuration exists.
	SELECT
		ancestor_config_id,
		config_id,
		_level
	INTO
		_ac_id,
		_pc_id
	FROM
		mecb_config
	WHERE
		config		= parent_config;

	IF _pc_id IS NULL ThEN
	   RAISE EXCEPTION '00214: This parent_config_id does not exist in '
	   	 'mecb_config table.';
	END IF;

	-- Ensure that different configs with same types cannot be in same tree
	SELECT
		COUNT(*)
	INTO
		_rowcount
	FROM
		mecb_config		a,
		mecb_config		b,
		mecb_config_type	c
	WHERE
		a.config_id		= _c_id
	AND	b.config_id		= _pc_id
	AND	b.config_id		!= a.config_id
	AND	c.config_type_id	= a.config_type_id
	AND	c.config_type_id	= b.config_type_id;

     	IF _rowcount > 0 THEN
     	   RAISE EXCEPTION '00215: Cannot have two configurations with the '
	   	 'same type in the same tree.';
	END IF;

	-- Ensure that configurations cannot be parents of each other.
	SELECT
		COUNT(*)
	INTO
		_counter
	FROM
		mecb_config	a,
		mecb_config	b
	WHERE
		b.config_id	= a.parent_config_id
	AND	a.config	= part_config
	AND	b.config	= parent_config
	AND	b.config	!= a.config;

	IF _counter > 0 THEN
	   RAISE EXCEPTION '00216: ''%'' is already a child of ''%''.',
	   	 part_config, parent_config;
	END IF;
 
	-- Ensure that configurations cannot be moved to the same tree.
	SELECT
		COUNT(*)
	INTO
		_counter
	FROM
		mecb_config	a,
		mecb_config	b
	WHERE
		a.ancestor_config_id	= b.ancestor_config_id
	AND	a.config		= part_config
	AND	b.config		= parent_config
	AND	b.config		!= a.config;

	IF _counter > 0 THEN
	   RAISE EXCEPTION '00217: ''%'' and ''%'' are in the same '
	   	 'configuration tree.', parent_config, part_config;
	END IF;

	-- Ensure that no parts are attached to the configuration.
	SELECT
		COUNT(*)
	INTO
		_rowcount
	FROM
		mecb_part		a,
		mecb_config		b
	WHERE
		b.config_id		= _c_id
	AND	a.config_id		= b.config_id
	AND	a.part_id		!= a.parent_part_id;

	IF _rowcount > 0 THEN
	   RAISE EXCEPTION '00218: Cannot move a configuration with '
	   	 'parts still attached to it.';
	END IF;

	-- If a config is removed entirely from its parent.
	IF part_config = parent_config THEN
	   _ac_id = _c_id;
	   _pc_id = _c_id;
	   _level = -1;
	END IF;
	
	UPDATE
		mecb_config
	SET
		ancestor_config_id	= _ac_id,
		parent_config_id	= _pc_id,
		level = _level + 1
	WHERE
		config_id		= _c_id;

	GET DIAGNOSTICS _rowcount = row_count;

	IF _rowcount = 0 THEN
	   RAISE EXCEPTION '00219: Was not able to update the mecb_config '
	   	 'table.';
	END IF;
/*
	SELECT
		COALESCE(MAX(hist_id) + 1,1)
	INTO
		_hist_id
	FROM
		mecb_config_audit
	WHERE
		config_id = _c_id;

	INSERT INTO mecb_config_audit (
	       config_id,
	       hist_id,
	       action)
	VALUES (
	       _c_id,
	       _hist_id,
	       'Update');
*/
END; $$
LANGUAGE plpgsql;

/*
	When a change is made to a configuration, this function ensures that
	all configurations in the same tree and lower than the configuratiion
	changed will also be changed to reflect the changes.  Basically, this
	means that the ancestor_config_id will be changed to reflect the new
	ancestor_config_id in the changed configuration.  This is done
	recursively to ensure everything is updated correctly.
*/
DROP FUNCTION IF EXISTS p_config_tree_upd CASCADE;
CREATE OR REPLACE FUNCTION p_config_tree_upd() RETURNS TRIGGER AS $$
DECLARE
	_c_id		BIGINT:= new.config_id;
	_pc_id		BIGINT:= new.parent_config_id;
	_rowcount	INTEGER:= 0;
	_counter	INTEGER:= 0;
BEGIN

	-- Ensure that no parts are attached to the configuration.
	SELECT
		COUNT(*)
	INTO
		_rowcount
	FROM
		mecb_part
	WHERE
		config_id	= _c_id;

	IF _rowcount > 0 THEN
	   RAISE EXCEPTION '00301: Cannot move configuration while parts '
	   	 'are attached to it.';
	END IF;

	-- Fix the ancestor id for those rows needing it.
	UPDATE
		mecb_config		a
	SET
		ancestor_config_id	= b.ancestor_config_id
	FROM
		mecb_config		b
	WHERE
		a.parent_config_id	= b.config_id
	AND	a.config_id		= _c_id
	AND	a.parent_config_id	= _pc_id
	AND	a.config_id		!= b.config_id
	AND	a.ancestor_config_id	!= b.ancestor_config_id;

	GET DIAGNOSTICS _rowcount = row_count;

	/*
		If this is a top level configuration, the ancester_config_id,
		parent_config_id and the config_id all need to be the same.
	*/
	IF _rowcount = 0 THEN
	   UPDATE
		mecb_config
	   SET
		ancestor_config_id	= _c_id
	   WHERE
		config_id		= _c_id
	   AND	parent_config_id	= config_id
	   AND	ancestor_config_id	!= parent_config_id;
	END IF;

	-- Recurse through the tree.
	UPDATE
		mecb_config		a
	SET
		parent_config_id	= b.config_id,
		ancestor_config_id	= b.ancestor_config_id,
		level			= b.level + 1
	FROM
		mecb_config		b
	WHERE
		a.parent_config_id	= b.config_id
	AND	b.config_id		= _c_id
	AND	a.config_id		!= b.config_id;

	RETURN NEW;
END; $$
LANGUAGE plpgsql;

CREATE TRIGGER r_config_tree_upd
       AFTER UPDATE OF parent_config_id ON mecb_config
       FOR EACH ROW
       EXECUTE PROCEDURE p_config_tree_upd();

/*
	api_config_del

	This is the API for deleting a configuration.
*/
DROP PROCEDURE IF EXISTS api_config_del;
CREATE OR REPLACE PROCEDURE api_config_del (
       c_name	  	VARCHAR) AS $$
DECLARE
	_c_id		BIGINT:= 0;
	_rowcount	BIGINT:= 0;
BEGIN

	IF c_name IS NULL OR LENGTH(TRIM(c_name)) = 0 THEN
	   RAISE EXCEPTION '00401: Configuration name must be entered.';
	END IF;

	SELECT
		config_id
	INTO
		_c_id
	FROM
		mecb_config
	WHERE
		config		= c_name;

	IF _c_id IS NULL THEN
	   RAISE EXCEPTION '00402: Invalid cofiguration name.';
	END IF;

	-- Ensure that no parts are attached to the configuration.
	SELECT
		COUNT(*)
	INTO
		_rowcount
	FROM
		mecb_part		a,
		mecb_config		b
	WHERE
		b.config_id		= _c_id
	AND	a.config_id		= b.config_id
	AND	a.part_id		!= a.parent_part_id;

      IF _rowcount = 0 THEN
      	 SELECT
		COUNT(*)
	INTO
		_rowcount
	FROM
		mecb_part	a,
		mecb_config	b
	WHERE
		b.config_id	= _c_id
	AND	a.config_id	= b.config_id;
	END IF;

	IF _rowcount > 0 THEN
	   RAISE EXCEPTION '00403: Cannot delete configuration while parts '
	   	 'are attached to it.';
	END IF;

	DELETE FROM
		mecb_config
	WHERE
		config_id	= _c_id;
		
	GET DIAGNOSTICS _rowcount = row_count;

	IF _rowcount = 0 THEN
	   RAISE EXCEPTION '00404: Deletion of the configuration failed.';
	END IF;

END; $$
LANGUAGE plpgsql;

/*
	p_config_tree_del

	This function is called everytime a row in the mecb_config table is
	deleted.  This allows for the deletion of a configuration and all of 
	the members of that configuration's tree.
*/
DROP FUNCTION IF EXISTS p_config_tree_del CASCADE;
CREATE OR REPLACE FUNCTION p_config_tree_del() RETURNS TRIGGER AS $$
DECLARE
	_c_id		BIGINT:= old.config_id;
	_rowcount	INTEGER:= 0;
BEGIN
	-- Ensure that no parts are attached to the configuration.
	SELECT
		COUNT(*)
	INTO
		_rowcount
	FROM
		mecb_part		a,
		mecb_part_type		b,
		mecb_config_type	c,
		mecb_config		d
	WHERE
		d.config_id		= _c_id
	AND	c.config_type_id	= d.config_type_id
	AND	b.part_type_id		= c.part_type_id
	AND	a.part_type_id		= b.part_type_id
	AND	b.part_type_id		IS NOT NULL;

	IF _rowcount > 0 THEN
	   RAISE EXCEPTION '00501: Cannot delete configuration while parts '
	   	 'are attached to it.';
	END IF;

	-- Remove any history associated with this configuration.
	/*
	DELETE FROM
	       mecb_config_audit
	WHERE
		config_id	= _c_id;
	*/

	DELETE FROM
		mecb_config
	WHERE
		parent_config_id	= _c_id;
		
	RETURN OLD;

END; $$
LANGUAGE plpgsql;

CREATE TRIGGER r_config_tree_del
       AFTER DELETE ON mecb_config
       FOR EACH ROW
       EXECUTE FUNCTION p_config_tree_del();

/*
	api_config_rem
	This API rmoves (not deletes) a configuration from its parent, then
	goes down the tree and removes all other configurations also, thus
	making every configuration in the removal chain a top-level
	configuration.
*/
DROP PROCEDURE IF EXISTS api_config_rem CASCADE;
CREATE OR REPLACE PROCEDURE api_config_rem (
        c_name	        VARCHAR) AS $$
DECLARE
	_c_id		BIGINT:= 0;
	_rowcount	INTEGER:= 0;
	_hist_id	INTEGER:= 0;
BEGIN

	IF c_name IS NULL OR LENGTH(TRIM(c_name)) = 0 THEN
	   RAISE EXCEPTION '00601: Configuration name cannot be blank.';
	END IF;

	SELECT
		COALESCE(config_id,0)
	INTO
		_c_id
	FROM
		mecb_config
	WHERE
		config		= c_name;

	IF (_c_id = 0 OR _c_id IS NULL) THEN
	   RAISE EXCEPTION '00602: Configuration not found.';
	END IF;

	-- Ensure that no parts are attached to the configuration.
	SELECT
		COUNT(*)
	INTO
		_rowcount
	FROM
		mecb_config	a,
		mecb_part	b
	WHERE
		a.config_id	= _c_id
	AND	b.config_id	= a.config_id;

	IF _rowcount > 0 THEN
	   RAISE EXCEPTION '00603: Cannot remove configuration while a part '
	   	 'is attached to it.';
	END IF;

	-- remove the selected branch and leaves from the main tree.
	WITH RECURSIVE ctename as (
    	SELECT
		config_id,
		config,
		config as path
     	FROM
		mecb_config
     	WHERE
		config_id = _c_id
     	UNION
     	SELECT
		a.config_id,
		a.config,
		ctename.path || '->' || a.config
     	FROM
		mecb_config	a
		JOIN ctename on a.parent_config_id = ctename.config_id
     	WHERE
		a.ancestor_config_id	!= a.config_id
	)
	UPDATE
		mecb_config b
	SET
		ancestor_config_id	= ctename.config_id,
		parent_config_id	= ctename.config_id
	FROM
		ctename
	WHERE
		b.config_id	= ctename.config_id;

	GET DIAGNOSTICS _rowcount = row_count;

	IF _rowcount = 0 THEN
	   RAISE EXCEPTION '00604: Configuration removal failed.';
	END IF;
/*
	SELECT
		COALESCE(MAX(hist_id) + 1,1)
	INTO
		_hist_id
	FROM
		mecb_config_audit
	WHERE
		config_id = _c_id;

	INSERT INTO mecb_config_audit (
	       config_id,
	       hist_id,
	       action)
	VALUES (
	       _c_id,
	       _hist_id,
	       'Remove');
*/
END; $$
LANGUAGE plpgsql;

/*
	config_list_tree_func

	Gets a list of all nodes in the selected tree.
*/
DROP FUNCTION IF EXISTS config_list_tree_func;
CREATE OR REPLACE FUNCTION config_list_tree_func (
       c_name	  VARCHAR
)
	RETURNS TABLE (
		cc_name		VARCHAR,
		cc_id		BIGINT
) AS $$
DECLARE
	c_id	BIGINT;
BEGIN

	IF c_name IS NULL THEN
	   RAISE EXCEPTION '00701: The configuration name cannot be blank.';
	END IF;

	SELECT
		config_id
	INTO
		c_id
	FROM
		mecb_config
	WHERE
		config	= c_name;

	IF c_id = 0 OR c_id IS NULL THEN
	   RAISE EXCEPTION '00702: The configuraton not found.';
	END IF;

	RETURN QUERY
	WITH RECURSIVE ctename as (
	SELECT
		config_id, config --, config as path
     	FROM
		mecb_config
     	WHERE
		config_id = c_id
     	UNION
	SELECT
		a.config_id, a.config --, ctename.path || '->' || a.config
     	FROM
		mecb_config	a
			JOIN ctename on a.parent_config_id = ctename.config_id
     	WHERE
		a.ancestor_config_id	!= a.config_id
	)
	SELECT ctename.config, ctename.config_id FROM ctename;

END; $$
LANGUAGE plpgsql;

/*
	api_config_list

	Gets a tree list starting with a selected configuration.  Returns
	either an indented list (indent type = true) or an arrow separated list
	(indent	type = false).

	Only the first two parameters are used for input by the user.
	Everythinng else is used by the procedure.  The second parameter is an
	optional one, since indented output is the default.

	This is designed to work within a transaction, so BEGIN TRANSACTION
	needs to be executed before calling the procedure, followed by a
	COMMIT.
*/
DROP PROCEDURE IF EXISTS api_config_list;
CREATE OR REPLACE PROCEDURE api_config_list (
       c_name	  	    VARCHAR DEFAULT NULL,
       indent_type	    BOOL DEFAULT TRUE,
       c_id	  	    BIGINT  DEFAULT NULL,
       ret_path		    VARCHAR DEFAULT '',
       indent	  	    INTEGER DEFAULT 0
) AS $$
DECLARE
	_tmp_id BIGINT:= 0;
	_c_id	BIGINT:= 0;
	_cname 	VARCHAR;
	indent_jam	VARCHAR:= '';
BEGIN

	-- We need the configuration name when we first start.
	IF LENGTH(TRIM(c_name)) = 0  AND c_id IS NULL THEN
	   RAISE EXCEPTION '03301: Configuratino name has to be non blank.';
	END IF;

	IF LENGTH(TRIM(c_name)) > 0 THEN
	   SELECT
		config_id
	   INTO
		c_id
	   FROM
		mecb_config
	   WHERE
		config	= c_name;

	   IF c_id IS NULL THEN
	      RAISE EXCEPTION '03302: Invalid configuration name.';
	   END IF;

	   -- Drop is done so that we get a fresh start even if inside a
	   -- transaction.
	   
	   DELETE FROM  mecb_config_tmp;

	   ret_path = c_name;
	END IF;

	-- Get the next monotonically increasing id number.
	SELECT
		COALESCE(MAX(tmp_id) + 1,1)
	INTO
		_tmp_id
	FROM
		mecb_config_tmp;

	-- If the list is to be indented, then we set up indent_jam.
	IF indent_type THEN
	   -- Calculate indentation level.
	   FOR i in 1..indent LOOP
	       indent_jam = indent_jam || ' ';
	   END LOOP;
	END IF;

	-- Insert the result into the temporary table.
	INSERT INTO mecb_config_tmp (
	       tmp_id,
	       tmp_name)
	VALUES (
	       _tmp_id,
	       indent_jam || ret_path);

	FOR
		_c_id,
		_cname
	IN SELECT
		config_id,
		config
	FROM
		mecb_config
	WHERE
		parent_config_id = c_id
	AND	parent_config_id != config_id LOOP

		-- If this is an indented list, pass the config name otherwise
		-- pass the config path in arrow format.
		IF indent_type THEN
		   	call api_config_list ('',indent_type,_c_id,_cname ,
			     indent + 1);
		ELSE
			call api_config_list ('',indent_type,_c_id,
			     ret_path || '-->' || _cname , indent + 1);
		END IF;
		
	END LOOP;

END; $$
LANGUAGE plpgsql;

/*************************** End mecb_config fiddly bits ******************/
/*********************** Begin mecb_config_type fiddly bits ***************/

/*
	api_config_type_ins

	Ensures the config type doesn't already exist and creates one with a
	config_type_id = to the maximum id + 1;
*/
DROP PROCEDURE IF EXISTS api_config_type_ins;
CREATE OR REPLACE PROCEDURE api_config_type_ins (
     ct_name	VARCHAR,
     pt_name	VARCHAR
) AS $$
DECLARE
	_ct_id		BIGINT:= 0;
	_pt_id		BIGINT:= 0;
	_rowcount	INTEGER:= 0;
BEGIN

	IF LENGTH(TRIM(ct_name)) = 0 THEN
	   RAISE EXCEPTION '00801: The Configuration type must be entered.';
	END IF;

	-- See if the configuration type exists.
	SELECT
		COALESCE(config_type_id,0)
	INTO
		_ct_id
	FROM
		mecb_config_type
	WHERE
		config_type	= ct_name;

	IF _ct_id > 0 THEN
	   RAISE EXCEPTION '00802: The selected configuration type already '
	   	 'exists.';
	END IF;

	-- See if the part type exists.
	SELECT
		COALESCE(part_type_id,0)
	INTO
		_pt_id
	FROM
		mecb_part_type
	WHERE
		part_type	= pt_name;

	IF _pt_id = 0 OR _pt_id IS NULL THEN
	   RAISE EXCEPTION '00803: The selected part type does not exist.';
	END IF;

	SELECT
		COUNT(*)
	INTO
		_rowcount
	FROM
		mecb_part_type		a,
		mecb_config_type	b
	WHERE
		a.part_type_id		= _pt_id
	AND	b.part_type_id		= a.part_type_id;

	IF _rowcount > 0 THEN
	   RAISE EXCEPTION '00804: The part type is already being used by a '
	   	 ' configuration type.';
	END IF;
	
	-- Get the next sequence number for the config type.
	SELECT
		COALESCE(MAX(config_type_id) + 1,1)
	INTO
		_ct_id
	FROM
		mecb_config_type;

	INSERT INTO mecb_config_type (
	       config_type,
	       config_type_id,
	       part_type_id)
	VALUES (
	       ct_name,
	       _ct_id,
	       _pt_id);

	GET DIAGNOSTICS _rowcount = row_count;

	IF _rowcount = 0 THEN
	   RAISE EXCEPTION '00805: Creation of new configuraton type failed.';
	END IF;
	
END; $$
LANGUAGE plpgsql;

/*
	api_config_type_del

	Deletes a configuration type.
*/
DROP PROCEDURE IF EXISTS api_config_type_del;
CREATE OR REPLACE PROCEDURE api_config_type_del (
       ct_name	  VARCHAR
) AS $$
DECLARE
	_ct_id		BIGINT:= 0;
	_rowcount	INTEGER:= 0;
BEGIN

	IF ct_name IS NULL OR LENGTH(TRIM(ct_name)) = 0 THEN
	   RAISE EXCEPTION '01001: Configuration type name must be entered.';
	END IF;

	-- Ensure the configuration type exists.
	SELECT
		COALESCE(config_type_id,0)
	INTO
		_ct_id
	FROM
		mecb_config_type
	WHERE
		config_type = ct_name;

	IF _ct_id = 0 OR _ct_id IS NULL THEN
	   RAISE EXCEPTION '01002: Configuration type doesn''t exist.';
	END IF;

	-- Ensure that no configurations are using this configuration type.
	SELECT
		COUNT(*)
	INTO
		_rowcount
	FROM
		mecb_config
	WHERE
		config_type_id	= _ct_id;

	IF _rowcount > 0 THEN
	   RAISE EXCEPTION '01003: Configuration type being used by a '
	   	 'configuration.';
	END IF;

	DELETE FROM
	       mecb_config_type
	WHERE
		config_type_id	= _ct_id;

	GET DIAGNOSTICS _rowcount = row_count;

	IF _rowcount = 0 THEN
	   RAISE EXCEPTION '01004: Deletion of the configuration type failed.';
	END IF;
END; $$
LANGUAGE plpgsql;

/************************ End mecb_config_type fiddly bits ****************/
/************************ Begin mecb_part_type fiddly bits ****************/

/*
	api_part_type_ins

	Creates a new part type.
*/
DROP PROCEDURE IF EXISTS api_part_type_ins;
CREATE OR REPLACE PROCEDURE api_part_type_ins (
       pt_name	  VARCHAR
) AS $$
DECLARE
	_pt_id		BIGINT:= 0;
	_rowcount	INTEGER:= 0;
BEGIN

	IF pt_name IS NULL OR TRIM(pt_name) = '' THEN
	   RAISE EXCEPTION '01101: The part type needs to be entered.';
	END IF;

	-- Check to see if the part type already exists.
	SELECT
		COALESCE(part_type_id,0)
	INTO
		_pt_id
	FROM
		mecb_part_type
	WHERE
		part_type	= pt_name;

	IF _pt_id > 0 THEN
	   RAISE EXCEPTION '01102: The part type already exists.';
	END IF;

	-- Get the next monotonically increasing part_type_id.
	SELECT
		COALESCE(MAX(part_type_id) + 1,1)
	INTO
		_pt_id
	FROM
		mecb_part_type;
		
	-- Create a new part type.
	INSERT INTO mecb_part_type (
	       part_type,
	       part_type_id)
	VALUES (pt_name,
	       _pt_id);

	GET DIAGNOSTICS _rowcount = row_count;

	IF _rowcount = 0 THEN
	   RAISE EXCEPTION '01103: Creation of part type ''%'' failed.',
	   	 pt_name;
	END IF;

END; $$
LANGUAGE plpgsql;

/*
	api_part_type_del

	This procedure will delete a part type after ensuring that said
	part type has no parts connected to it.
*/
DROP PROCEDURE IF EXISTS api_part_type_del;
CREATE OR REPLACE PROCEDURE api_part_type_del (
     pt_name   VARCHAR
) AS $$
DECLARE
	_pt_id		BIGINT:= 0;
	_p_id		BIGINT:= 0;
	_rowcount	INTEGER;
	_counter	INTEGER;
BEGIN

	IF pt_name IS NULL THEN
	   RAISE EXCEPTION '00901: The part type name cannot be blank.';
	END IF;

	-- Ensure that the part type exists.
	SELECT
		COALESCE(part_type_id,0)
	INTO
		_pt_id
	FROM
		mecb_part_type
	WHERE
		part_type	= pt_name;

	IF _pt_id = 0 OR _pt_id IS NULL THEN
	   RAISE EXCEPTION '00902: The part type ''%'' does not exist.',
	   	 pt_name;
	END IF;

	-- Ensure that no parts are connected to this part type.
	SELECT
		COUNT(*)
	INTO
		_counter
	FROM
		mecb_part
	WHERE
		part_type_id		= _pt_id;

	IF _counter > 0 THEN
	   RAISE EXCEPTION '00903: Cannot remove part type because at least '
	   	 'one part is connected to it.';
	END IF;

	/* Ensure that no configuration types are using the part type.n*/
	SELECT
		COUNT(*)
	INTO
		_counter
	FROM
		mecb_config_type
	WHERE
		part_type_id	= _pt_id;

	IF _counter > 0 THEN
	   RAISE EXCEPTION '00904: Cannot remove part type because it is being '
	   	 'used by a configuration type.';
	END IF;

	-- Delete the part type.
	DELETE FROM
	       mecb_part_type
	WHERE
		part_type_id	= _pt_id;

	GET DIAGNOSTICS _rowcount = row_count;

	IF _rowcount = 0 THEN
	   RAISE EXCEPTION '00905; Part type ''%'' not removed.',pt_name;
	END IF;

END; $$
LANGUAGE plpgsql;
	
/************************ End mecb_part_type fiddly bits ******************/
/************************ Begin mecb_part fiddly bits*** ******************/

/*
	api_part_ins

	Ensures the part doesn't already exist and creates one with a
	part_id = to the maximum id + 1;
*/
DROP PROCEDURE IF EXISTS api_part_ins CASCADE;
CREATE OR REPLACE PROCEDURE api_part_ins (
     p_name	VARCHAR,
     pt_name	VARCHAR
) AS $$
DECLARE
	_p_id		BIGINT:= 0;
	_pt_id		BIGINT:= 0;
	_rowcount	INTEGER:= 0;
	_hist_id	INTEGER:= 0;
BEGIN

	IF p_name IS NULL OR LENGTH(TRIM(p_name)) = 0 THEN
	   RAISE EXCEPTION '00801: Part name must be non-blank.';
	END IF;

	IF pt_name IS NULL OR LENGTH(TRIM(pt_name)) = 0 THEN
	   RAISE EXCEPTION '00802: Part type name must be non-blank.';
	END IF;

	-- See if the part exists.
	SELECT
		COALESCE(part_id,0)
	INTO
		_p_id
	FROM
		mecb_part
	WHERE
		LOWER(part)		= LOWER(p_name);

	IF _p_id > 0 THEN
	   RAISE EXCEPTION '00803: The selected part already exists.';
	END IF;

	-- Enaure that the part type exists.
	SELECT
		COALESCE(part_type_id,0)
	INTO
		_pt_id
	FROM
		mecb_part_type
	WHERE
		LOWER(part_type)	= LOWER(pt_name);

	IF _pt_id = 0 OR _pt_id IS NULL THEN
	   RAISE EXCEPTION '00804: The part type does not exist for the '
	   	 'configuration.';
	END IF;

	-- Get a new id for the part
	SELECT
		COALESCE(MAX(part_id) + 1,1)
	INTO
		_p_id
	FROM
		mecb_part;

	-- Create the new part.
	INSERT INTO mecb_part (
	       part,
	       part_id,
	       ancestor_part_id,
	       parent_part_id,
	       part_type_id,
	       config_id)
	VALUES (p_name,
	       _p_id,
	       _p_id,
	       _p_id,
	       _pt_id,
	       0);

	GET DIAGNOSTICS _rowcount = row_count;

	IF _rowcount = 0 THEN
	   RAISE EXCEPTION '00805: The part ''%'' was not created.',
	   	 pt_name;
	END IF;

/*
	-- Delete all part audit transactions > 7 days old.
	DELETE FROM
	       mecb_part_audit
	WHERE
		current_date - transaction_date > 7;
		
	SELECT
		COALESCE(MAX(hist_id) + 1,1)
	INTO
		_hist_id
	FROM
		mecb_part_audit
	WHERE
		part_id = _p_id;

	INSERT INTO mecb_part_audit (
	       part_id,
	       hist_id,
	       action)
	VALUES (
	       _p_id,
	       _hist_id,
	       'Insert');
	*/
END; $$
LANGUAGE plpgsql;

/*
	api_part_upd

	The api for moving parts around.  It has two parms which are required
	(pp_name and p_name).

	The part can only be moved to a valid part that belongs to a
	configuration.
*/
DROP PROCEDURE IF EXISTS api_part_upd CASCADE;
CREATE PROCEDURE api_part_upd (
       pp_name	 	VARCHAR,
       p_name	 	VARCHAR
) AS $$
DECLARE
	_p_id		BIGINT:= 0;
	_pp_id		BIGINT:= 0;
	_c_id		BIGINT:= 0;
	_dup_p_name	VARCHAR:= '';
	_counter	INTEGER:= 0;
	_rowcount	INTEGER:= 0;
	_p_name		VARCHAR;
	_pp_name	VARCHAR;
	_num_slots	INTEGER:= 0;
	_num_conf_slots	INTEGER:= 0;
	_slots_used	INTEGER:= 0;
	_hist_id	INTEGER:= 0;
BEGIN

	IF p_name IS NULL OR LENGTH(TRIM(p_name)) = 0 THEN
	   RAISE EXCEPTION '01201: Part name cannot be blank.';
	END IF;

	IF pp_name IS NULL OR LENGTH(TRIM(pp_name)) = 0 THEN
	   RAISE EXCEPTION '01202: The parent part cannot be blank.';
	END IF;

	-- Does the new parent exist?
	SELECT
		part_id
	INTO
		_pp_id
	FROM
		mecb_part
	WHERE
		part	= pp_name;

	IF _pp_id IS NULL THEN
	   RAISE EXCEPTION '01203: The parent part name is invalid.';
	END IF;

	-- Does the part exist?
	SELECT
		part_id
	INTO
		_p_id
	FROM
		mecb_part
	WHERE
		part	= p_name;

	IF _p_id IS NULL THEN
	   RAISE EXCEPTION '01205: The part name is invalid.';
	END IF;

	-- Does the configuration exist?
	SELECT
		a.config_id
	INTO
		_c_id
	FROM
		mecb_part	a,
		mecb_config	b
	WHERE
		a.part_id	= _p_id
	AND	b.config_id	= a.config_id;

	-- If is not assigned a configuration yet.
	IF (_c_id IS NULL OR _c_id < 1) AND _p_id != _pp_id THEN
	   RAISE EXCEPTION '01206: The part has not been assigned to a '
	   	 'configuration.';
	END IF;

	/*
		Find out if the configuration for the proposed parent part
		allows this part to be attached to the parent.
	*/
	SELECT
		COUNT(*)
	INTO
		_rowcount
	FROM
		mecb_part		a,
		mecb_part		b,
		
		mecb_config_type	d,
		mecb_config		e,
		mecb_config_type	g,
		mecb_config		h
	WHERE
		a.part_id		= _pp_id
	AND	b.part_id		= _p_id
	AND	h.config_id		= _c_id
	AND	d.part_type_id		= a.part_type_id
	AND	e.config_type_id	= d.config_type_id
	AND	g.part_type_id		= b.part_type_id
	AND	h.config_type_id	= g.config_type_id
	AND	h.parent_config_id	= e.config_id;

	IF _rowcount = 0 AND _c_id > 0 AND _p_id != _pp_id THEN
	   RAISE EXCEPTION '01207: Invalid part type for the configuration.';
	END IF;

	-- Ensure that a part can only be attached to a parent that is in a
	-- configuration.
	SELECT
		COUNT(*)
	INTO
		_rowcount
	FROM
		mecb_part
	WHERE
		part_id		= _pp_id
	AND	config_id	> 0;

	IF _rowcount = 0 AND _p_id != _pp_id THEN
	   RAISE EXCEPTION '01208: Parent part ''%'' not assigned to a '
	   	 'configuration.', pp_name;
	END IF;

	-- Ensure that the part is not already attached to the slot.
	SELECT
		COUNT(*)
	INTO
		_rowcount
	FROM
		mecb_part	a,
		mecb_part	b
	WHERE
		a.part_id		= _pp_id
	AND	b.part_id		= _p_id
	AND	_pp_id			!= _p_id
	AND	b.parent_part_id	= a.part_id;

	IF _rowcount > 0 THEN
	   RAISE EXCEPTION '01209: This part is already attached to this slot.';
	END IF;

	-- Get the number of slots available.
	SELECT
		tot_slots
	INTO
		_num_slots
	FROM
		mecb_part	a,
		mecb_config	b
	WHERE
		a.part_id	= _p_id
	AND	b.config_id	= a.config_id;

	-- Get the number of configuration slots available.
	SELECT
		count(*)
	INTO
		_num_conf_slots
	FROM
		mecb_part	a,
		mecb_config	b,
		mecb_config	c
	WHERE
		a.part_id		= _p_id
	AND	b.config_id		= a.config_id
	AND	c.parent_config_id	= b.parent_config_id
	AND	b.parent_config_id	!= b.config_id
	AND	c.parent_config_id	!= c.config_id;

	-- If there are more config slots than part slots, we need to know.
	IF _num_conf_slots > _num_slots THEN
	   _num_slots = _num_conf_slots;
	END IF;

	-- Get the number of slots used.
	SELECT
		COUNT(*)
	INTO
		_slots_used
	FROM
		mecb_part	a
	WHERE
		a.parent_part_id	= _pp_id
	AND	a.parent_part_id	!= a.part_id;

	IF _num_slots - _slots_used <= 0 AND _p_id != _pp_id THEN
	   RAISE EXCEPTION '01212: This slot is already filled by another '
	   	 'part % % % %.', _num_slots, _slots_used, _num_conf_slots, _c_id;
	END IF;

	-- Set the initial value which starts the recursive update cycle.
	UPDATE
		mecb_part
	SET
		parent_part_id	= _pp_id,
		config_id	= _c_id
	WHERE
		part_id		= _p_id;

	GET DIAGNOSTICS _rowcount = row_count;

	IF _rowcount = 0 THEN
	   RAISE EXCEPTION '01213: Was not able to update the part table.';
	END IF;
/*
	SELECT
		COALESCE(MAX(hist_id) + 1,1)
	INTO
		_hist_id
	FROM
		mecb_part_audit
	WHERE
		part_id = _p_id;

	INSERT INTO mecb_part_audit (
	       part_id,
	       hist_id,
	       action)
	VALUES (
	       _p_id,
	       _hist_id,
	       'Update');
	*/
END; $$
LANGUAGE plpgsql;

/*
	p_part_tree_upd

	Update the mecb_part table recursively.  Accessed via the
	api_part_upd procedure.
*/
DROP FUNCTION IF EXISTS p_part_tree_upd CASCADE;
CREATE OR REPLACE FUNCTION p_part_tree_upd() RETURNS TRIGGER AS $$
DECLARE
        _p_id		 BIGINT:= new.part_id;
	_pp_id	 	 BIGINT:= new.parent_part_id;
	_old_p_id	 BIGINT:= old.part_id;
	_c_id		 BIGINT:= 0;
	_rowcount	INTEGER;
BEGIN
	-- Fix the ancestor id for those rows that need to have it fixed.
	UPDATE
		mecb_part	a
	SET
		ancestor_part_id	= b.ancestor_part_id
	FROM
		mecb_part	b
	WHERE
		a.parent_part_id	= b.part_id
	AND	a.part_id		= _p_id
	AND	a.parent_part_id	= _pp_id
	AND	a.part_id		!= b.part_id
	AND	a.ancestor_part_id	!= b.ancestor_part_id;

	GET DIAGNOSTICS _rowcount = row_count;

	/*
		If this is a top level part, the ancestor id,
		parent id and part id all need to be the same.
	*/
	IF (_rowcount = 0) THEN
	   UPDATE
		mecb_part
	   SET
		ancestor_part_id	= _old_p_id
	   WHERE
		part_id			= _p_id
	   AND	parent_part_id		= part_id
	   AND	ancestor_part_id	!= parent_part_id;
	END IF;

	/*
		Find out if the configuration for the proposed parent part
		allows this part to be attached to the parent.

		This passes the child configuration of the parent back
		to this recursively called function.
	*/
      	SELECT
		e.config_id
	INTO
		_c_id
	FROM
		mecb_part		a,
		mecb_part		b,
		
		mecb_config_type	d,
		mecb_config		e
	WHERE
		a.part_id		= _pp_id
	AND	b.part_id		= _p_id
	
	AND	d.part_type_id		= b.part_type_id
	AND	e.config_type_id	= d.config_type_id

	AND	e.parent_config_id	= a.config_id
	AND	e.config_id		= b.config_id;

	-- See if there is no configuration for this part.
	SELECT
		COUNT(*)
	INTO
		_rowcount
	FROM
		mecb_part
	WHERE
		part_id			= _p_id
	AND	parent_part_id		= _pp_id
	AND	config_id		= 0;

	IF _rowcount > 0 THEN
	   RAISE EXCEPTION '01303: Invalid part type for the part.';
	END IF;

	-- Update the current row's config_id.
	IF _c_id IS NULL AND _p_id != _pp_id THEN
	   RAISE EXCEPTION '01304: Invalid or incomplete configuration tree.';
	END IF;
	
	-- Do a recursive update through the tree.
	UPDATE
		mecb_part		a
	SET
		parent_part_id		= b.part_id,
		ancestor_part_id	= b.ancestor_part_id
	FROM
		mecb_part		b
	WHERE
		a.parent_part_id	= b.part_id
	AND	b.part_id		= _p_id
	AND	a.part_id		!= b.part_id;

	RETURN NEW;

END; $$
LANGUAGE plpgsql;

CREATE TRIGGER r_part_tree_upd
       AFTER UPDATE OF parent_part_id ON mecb_part
       FOR EACH ROW
       EXECUTE PROCEDURE p_part_tree_upd();

DROP FUNCTION IF EXISTS f_part_chk_func CASCADE;
CREATE OR REPLACE FUNCTION f_part_chk_func (
       pp_name	VARCHAR,
       p_name	VARCHAR
)
	RETURNS TABLE (
	      _cc_id  BIGINT
) AS $$
BEGIN
	RETURN QUERY
	SELECT
		h.config_id
--	INTO
--		_c_id
	FROM
		mecb_part		a,
		mecb_part		b,

		mecb_config_type	d,
		mecb_config		e,
		mecb_config_type	g,
		mecb_config		h
	WHERE
		a.part			= pp_name
	AND	b.part		  	= p_name
--	AND	h.config_id		= _c_id
	
	AND	d.part_type_id		= a.part_type_id
	AND	e.config_type_id	= d.config_type_id
	
	AND	g.part_type_id		= b.part_type_id
	AND	h.config_type_id	= g.config_type_id

	AND	h.parent_config_id	= e.config_id;
END; $$
LANGUAGE plpgsql;


/*
	api_part_rem

	Removes all parts in a selected branch of the tree from their
	from their parents (keeps their configurations).
*/
DROP PROCEDURE IF EXISTS api_part_rem CASCADE;
CREATE OR REPLACE PROCEDURE api_part_rem (
        p_name	        VARCHAR) AS $$
DECLARE
	_p_id		BIGINT:= 0;
	_rowcount	INTEGER:= 0;
	_hist_id	INTEGER:= 0;
BEGIN

	IF p_name IS NULL  OR LENGTH(TRIM(p_name)) = 0 THEN
	   RAISE EXCEPTION '01401: Part name cannot be blank.';
	END IF;

	SELECT
		part_id
	INTO
		_p_id
	FROM
		mecb_part
	WHERE
		part		= p_name;

	IF (_p_id IS NULL) THEN
	   RAISE EXCEPTION '01402: Part not found.';
	END IF;

	-- remove the selected branch and leaves from the main tree.
	WITH RECURSIVE ctename1 as (
	     SELECT
		part_id, part, parent_part_id, part as path
     	FROM
		mecb_part
     		WHERE
		part_id = _p_id
     	UNION
     	SELECT
		a.part_id, a.part, a.parent_part_id, ctename1.path || '->' || a.part
     	FROM
		mecb_part	a
		JOIN ctename1 on a.parent_part_id = ctename1.part_id
     	WHERE
		a.ancestor_part_id	!= a.part_id
	)
	UPDATE
		mecb_part b
	SET
		ancestor_part_id	= ctename1.part_id,
		parent_part_id		= ctename1.part_id
--		config_id		= 0
	FROM
		ctename1
	WHERE
		b.part_id		= ctename1.part_id;

	GET DIAGNOSTICS _rowcount = row_count;

	IF _rowcount = 0 THEN
	   RAISE EXCEPTION '01403: Part removal failed.';
	END IF;
/*
	SELECT
		COALESCE(MAX(hist_id) + 1,1)
	INTO
		_hist_id
	FROM
		mecb_part_audit
	WHERE
		part_id = _p_id;

	INSERT INTO mecb_part_audit (
	       part_id,
	       hist_id,
	       action)
	VALUES (
	       _p_id,
	       _hist_id,
	       'Remove');
*/
END; $$
LANGUAGE plpgsql;

/*
	api_part_del

	This is the API for deleting a part.
*/
DROP PROCEDURE IF EXISTS api_part_del;
CREATE OR REPLACE PROCEDURE api_part_del (
       p_name	  	VARCHAR) AS $$
DECLARE
	_p_id		BIGINT:= 0;
	_rowcount	BIGINT:= 0;
BEGIN

	IF p_name IS NULL OR LENGTH(TRIM(p_name)) = 0 THEN
	   RAISE EXCEPTION '01501: Part name must be entered.';
	END IF;

	SELECT
		part_id
	INTO
		_p_id
	FROM
		mecb_part
	WHERE
		part		= p_name;

	IF _p_id IS NULL THEN
	   RAISE EXCEPTION '01502: Invalid part name.';
	END IF;

	-- Delete the first part in a tree, thus starting the recursive delete.
	DELETE FROM
		mecb_part
	WHERE
		part_id	= _p_id;
		
	GET DIAGNOSTICS _rowcount = row_count;

	IF _rowcount = 0 THEN
	   RAISE EXCEPTION '01503: Deletion of the part failed.';
	END IF;
/*
	-- Remove any history associated with this part.
	DELETE FROM
	       mecb_part_audit
	WHERE
		part_id	= _p_id;
*/
END; $$
LANGUAGE plpgsql;

/*
	p_part_tree_del

	This function is called everytime a row in the mecb_part table is
	deleted.  This allows for the deletion of a part and all of 
	the members of that part's tree.
*/
DROP FUNCTION IF EXISTS p_part_tree_del CASCADE;
CREATE OR REPLACE FUNCTION p_part_tree_del() RETURNS TRIGGER AS $$
DECLARE
	_p_id		BIGINT:= old.part_id;
	_pp_id		BIGINT:= old.parent_part_id;
	_counter	INTEGER;
BEGIN

	-- Delete part locations as without the parts we no longer need them.
	DELETE FROM
		mecb_part_loc
	WHERE
		part_id		= _p_id;

	-- Delete all scheduled maintenance actions for this part;
	DELETE FROM
	       mecb_sched_maint
	WHERE
		part_id	= _p_id;

	-- Delete part maintenance history.
	DELETE FROM
	       mecb_maint_hist
	WHERE
		part_id = _p_id;
		
	-- Recurse through all deletions of the selected tree.
	DELETE FROM
		mecb_part
	WHERE
		parent_part_id		= _p_id;
		
	RETURN OLD;

END; $$
LANGUAGE plpgsql;

CREATE TRIGGER r_part_tree_del
       AFTER DELETE ON mecb_part
       FOR EACH ROW
       EXECUTE FUNCTION p_part_tree_del();

/*
	api_part_list

	Gets a tree list starting with a selected part.  Returns either an
	indented list (indent type = true) or an arrow separated list (indent
	type = false).

	Only the first two parameters are used for input by the user.
	Everythinng else is used by the procedure.  The second parameter is an
	optional one, since indented output is the default.

	This cannot be assigned within the transaction since the sql connection
	package being used doesn't support dirty reads.
*/
DROP PROCEDURE IF EXISTS api_part_list;
CREATE OR REPLACE PROCEDURE api_part_list (
       p_name	  	    VARCHAR DEFAULT NULL,
       indent_type	    BOOL DEFAULT TRUE,
       p_id	  	    BIGINT  DEFAULT NULL,
       ret_path		    VARCHAR DEFAULT '',
       indent	  	    INTEGER DEFAULT 0
) AS $$
DECLARE
	_tmp_id BIGINT:= 0;
	_p_id	BIGINT:= 0;
	_pname 	VARCHAR;
	indent_jam	VARCHAR:= '';
BEGIN

	-- We need the part name when we first start.
	IF LENGTH(TRIM(p_name)) = 0  AND p_id IS NULL THEN
	   RAISE EXCEPTION '03201: Part name has to be non blank.';
	END IF;

	IF LENGTH(TRIM(p_name)) > 0 THEN
	   SELECT
		part_id
	   INTO
		p_id
	   FROM
		mecb_part
	   WHERE
		part	= p_name;

	   IF p_id IS NULL THEN
	      RAISE EXCEPTION '03202: Invalid part name.';
	   END IF;

	   -- Drop is done so that we get a fresh start even if inside a
	   -- transaction.
	   DELETE FROM
	   	  mecb_part_tmp;
	   /*
	   CREATE TABLE IF NOT EXISTS mecb_part_tmp (
	   	  tmp_id	BIGINT,
		  tmp_name	VARCHAR
	   );
*/
	   ret_path = p_name;		  
	END IF;

	-- Get the next monotonically increasing id number.
	SELECT
		COALESCE(MAX(tmp_id) + 1,1)
	INTO
		_tmp_id
	FROM
		mecb_part_tmp;

	-- If the list is to be indented, then we set up indent_jam.
	IF indent_type THEN
	   -- Calculate indentation level.
	   FOR i in 1..indent LOOP
	       indent_jam = indent_jam || ' ';
	   END LOOP;
	END IF;

	-- Insert the result into the temporary table.
	INSERT INTO mecb_part_tmp (
	       tmp_id,
	       tmp_name)
	VALUES (
	       _tmp_id,
	       indent_jam || ret_path);

	FOR
		_p_id,
		_pname
	IN SELECT
		part_id,
		part
	FROM
		mecb_part
	WHERE
		parent_part_id = p_id
	AND	parent_part_id != part_id LOOP

		-- If this is an indented list, pass the part name otherwise
		-- pass the part path in arrow format.
		IF indent_type THEN
		   	call api_part_list ('',indent_type,_p_id,_pname ,
			     indent + 1);
		ELSE
			call api_part_list ('',indent_type,_p_id,
			     ret_path || '-->' || _pname , indent + 1);
		END IF;
		
	END LOOP;

END; $$
LANGUAGE plpgsql;

/************************ End mecb_part fiddly bits **********************/
/************************ Begin mecb_part_config fiddly bits *************/
/*
	api_part_config_upd

	Updates the config_id in the part table to a new configuration.
*/
DROP PROCEDURE IF EXISTS api_part_config_upd CASCADE;
CREATE PROCEDURE api_part_config_upd (
       p_name VARCHAR,
       c_name VARCHAR) AS $$
DECLARE
	_rowcount	INTEGER	:= 0;
	_p_id		BIGINT	:= 0;
	_pp_id		BIGINT	:= 0;
	_c_id		BIGINT	:= 0;
BEGIN
	
	IF p_name IS NULL OR LENGTH(TRIM(p_name)) = 0 THEN
	   RAISE EXCEPTION '01601: Part name needs to be entered.';
	END IF;

	IF c_name IS NULL OR LENGTH(TRIM(c_name)) = 0 THEN
	   RAISE EXCEPTION '01602: Configuration name needs to be entered.';
	END IF;

	SELECT
		part_id,
		parent_part_id
	INTO
		_p_id,
		_pp_id
	FROM
		mecb_part
	WHERE
		part	= p_name;

	IF _p_id IS NULL THEN
	   RAISE EXCEPTION '01603: Invalid part name.';
	END IF;

	IF (_p_id != _pp_id) THEN
	   RAISE EXCEPTION '01604: part needs to be detached before reconfig.';
	END IF;

	SELECT
		COUNT(*)
	INTO
		_rowcount
	FROM
		mecb_part
	WHERE
		parent_part_id	= _p_id
	AND	part_id		!= parent_part_id;

	IF _rowcount > 0 THEN
	   RAISE EXCEPTION '01605: All children of this part need to be '
	   	 'detached before reconfig.';
	END IF;

	/*
		If a '0 is passed in, it means a part is being disassociated
		from it's configuration.
	*/
	IF lower(c_name) = 'nil' THEN
	   _c_id = 0;
	ELSE
	   SELECT
		config_id
	   INTO
		_c_id
	   FROM
		mecb_config
	   WHERE
		config	= c_name;

	END IF;
	
	IF _c_id IS NULL THEN
	   RAISE EXCEPTION '01606: Invalid configuration name.';
	END IF;

	/*
		Check to see if this configuration will accept this part at
		this level.
	*/
	SELECT
		COUNT(*)
	INTO
		_rowcount
	FROM
		mecb_part		a,
		mecb_part		b,
		
		mecb_config_type	d,
		mecb_config		e,
		mecb_config_type	g,
		mecb_config		h
	WHERE
		a.part_id		= _pp_id
	AND	b.part_id		= _p_id
	AND	h.config_id		= _c_id
	AND	d.part_type_id		= a.part_type_id
	AND	e.config_type_id	= d.config_type_id
	AND	g.part_type_id		= b.part_type_id
	AND	h.config_type_id	= g.config_type_id
	AND	h.parent_config_id	= e.config_id;

	IF _rowcount = 0 AND _c_id != 0 THEN

	   IF _p_id = _pp_id THEN
		SELECT
			COUNT(*)
		INTO
			_rowcount
		FROM
			mecb_part		a,
			mecb_config		b,
			mecb_config_type	c
		WHERE
			a.part_id		= _p_id
		AND	b.config_id		= _c_id
		AND	c.config_type_id	= b.config_type_id
		AND	c.part_type_id		= a.part_type_id;
	   END IF;

	   IF _rowcount = 0 THEN
	   	   RAISE EXCEPTION '01607: Invalid part type for the '
		   	 'configuration.';
	   END IF;

	END IF;

	UPDATE
		mecb_part
	SET
		config_id	= _c_id
	WHERE
		part_id		= _p_id;

	GET DIAGNOSTICS _rowcount = row_count;

	IF (_rowcount = 0) THEN
	   RAISE EXCEPTION '01608: Failure on insert into part_config table.';
	END IF;

END; $$
LANGUAGE plpgsql;

/************************ End mecb_part_config fiddly bits ***************/
/************************ Begin mecb_part_loc fiddly bits ****************/
/*
	api_part_loc_ins

	Inserts a location into the mecb_part_loc table, which holds info
	for both the mecb_part and mecb_loc tables.
*/
DROP PROCEDURE IF EXISTS api_part_loc_ins CASCADE;
CREATE OR REPLACE PROCEDURE api_part_loc_ins (
       p_name	  VARCHAR,
       l_name	  VARCHAR,
       l_type	  VARCHAR DEFAULT 'LOC'
) AS $$
DECLARE
	_p_id		BIGINT:= 0;
	_l_id		BIGINT:= 0;
	_lt_id		INTEGER:= 0;
	_rowcount	INTEGER:= 0;
BEGIN

	IF p_name IS NULL OR LENGTH(TRIM(p_name)) = 0 THEN
	   RAISE EXCEPTION '01701: The part name must be non blank.';
	END IF;

	IF l_name IS NULL OR LENGTH(TRIM(l_name)) = 0 THEN
	   RAISE EXCEPTION '01702: The location name must be non blank.';
	END IF;
	SELECT
		part_id
	INTO
		_p_id
	FROM
		mecb_part
	WHERE
		LOWER(part)	= LOWER(p_name);

	IF _p_id IS NULL THEN
	   RAISE EXCEPTION '01703: The part does not exist in the mecb_part '
	   	 'table.';
	END IF;

	SELECT
		loc_id
	INTO
		_l_id
	FROM
		mecb_loc
	WHERE
		LOWER(loc)	= LOWER(l_name);

	IF _l_id IS NULL THEN
	   RAISE EXCEPTION '01704: The location does not exist in the loc '
	   	 'table.';
	END IF;

	SELECT
		loc_type_id
	INTO
		_lt_id
	FROM
		mecb_loc_type
	WHERE
		LOWER(loc_type)	= LOWER(l_type);

	IF _lt_id IS NULL THEN
	   RAISE EXCEPTION '01705: Location type doesn''t exist.';
	END IF;

	SELECT
		COUNT(*)
	INTO
		_rowcount
	FROM
		mecb_part_loc
	WHERE
		loc_type_id	= _lt_id
	AND	part_id		= _p_id;

	IF _rowcount > 0 THEN
	   RAISE EXCEPTION '01706: This part already has a location for this '
	   	 'type.';
	END IF;

	INSERT INTO mecb_part_loc (
	       part_id,
	       loc_id,
	       loc_type_id)
	VALUES (
	       _p_id,
	       _l_id,
	       _lt_id);

	GET DIAGNOSTICS _rowcount = row_count;

	IF _rowcount = 0 THEN
	   RAISE EXCEPTION '01707: The creation of this location in the '
	   	 'mecb_part_loc table failed.';
	END IF;

END; $$
LANGUAGE plpgsql;

/*
	api_part_loc_del

	Deletes the location info from the mecb_part_loc table.
*/
DROP PROCEDURE IF EXISTS api_part_loc_del CASCADE;
CREATE OR REPLACE PROCEDURE api_part_loc_del (
       p_name	  VARCHAR,
       l_name	  VARCHAR,
       lt_name	  VARCHAR
) AS $$
DECLARE
	_p_id		BIGINT:= 0;
	_l_id		BIGINT:= 0;
	_lt_id		BIGINT:= 0;
	_rowcount	INTEGER:= 0;
BEGIN

IF LENGTH(TRIM(p_name)) = 0 THEN
	   RAISE EXCEPTION '01801: The part name must be non blank.';
	END IF;

	IF LENGTH(TRIM(l_name)) = 0 THEN
	   RAISE EXCEPTION '01802: The location name must be non blank.';
	END IF;

	-- Get the part id.
	SELECT
		part_id
	INTO
		_p_id
	FROM
		mecb_part
	WHERE
		LOWER(part)	= LOWER(p_name);

	IF _p_id IS NULL THEN
	   RAISE EXCEPTION '01803: Invalid part name.';
	END IF;

	-- Get the location id.
	SELECT
		loc_id
	INTO
		_l_id
	FROM
		mecb_loc
	WHERE
		LOWER(loc)	= LOWER(l_name);

	IF _l_id IS NULL THEN
	   RAISE EXCEPTION '01804: Invalid location name.';
	END IF;

	IF LENGTH(TRIM(lt_name)) > 0 THEN
	   SELECT
		loc_type_id
	   INTO
		_lt_id
	   FROM
		mecb_loc_type
	   WHERE
		LOWER(loc_type)	= LOWER(lt_name);

	   IF _lt_id IS NULL THEN
	      RAISE EXCEPTION '01805: Invalid location type name.';
	   END IF;

	   DELETE FROM
	       mecb_part_loc
	   WHERE
		loc_id		= _l_id
	   AND	part_id		= _p_id
	   AND	loc_type_id	= _lt_id;

	ELSE
	   DELETE FROM
	       mecb_part_loc
	   WHERE
		loc_id		= _l_id
	   AND	part_id		= _p_id;
	END IF;
	
	GET DIAGNOSTICS _rowcount = row_count;

	IF _rowcount = 0 THEN
	   RAISE EXCEPTION '01806: Location for part not found.';
	END IF;
	
END; $$
LANGUAGE plpgsql;

/************************ End mecb_part_loc fiddly bits ******************/
/************************ Begin mecb_loc fiddly bits *********************/

/*
	api_loc_ins

	Creates a new location.
*/
DROP PROCEDURE IF EXISTS api_loc_ins CASCADE;
CREATE OR REPLACE PROCEDURE api_loc_ins (
     l_name       VARCHAR
) AS $$
DECLARE
	_loc_id	BIGINT:= 0;
BEGIN
	IF l_name IS NULL OR LENGTH(TRIM(l_name)) = 0 THEN
	   RAISE EXCEPTION '01901: The new location cannot be blank.';
	END IF;

	SELECT
		loc_id
	INTO
		_loc_id
	FROM
		mecb_loc
	WHERE
		loc	= l_name;

	IF _loc_id IS NOT NULL THEN
	   RAISE EXCEPTION '01902: The location already exists.';
	END IF;

	SELECT
		COALESCE(MAX(loc_id) + 1,1)
	INTO
		_loc_id
	FROM
		mecb_loc;
		
	INSERT INTO mecb_loc (
	       loc,
	       loc_id)
	VALUES (
	       l_name,
	       _loc_id);
END; $$
LANGUAGE plpgsql;

/*
	api_loc_upd

	Renames a location.
*/
DROP PROCEDURE IF EXISTS api_loc_upd CASCADE;
CREATE OR REPLACE PROCEDURE api_loc_upd (
       old_name	  VARCHAR,
       new_name	  VARCHAR
) AS $$
DECLARE
	_l_id	BIGINT:= 0;
BEGIN

	IF old_name IS NULL OR LENGTH(TRIM(old_name)) = 0 THEN
	   RAISE EXCEPTION '02001: A valid location name needs to be entered.';
	END IF;

	IF new_name IS NULL OR LENGTH(TRIM(new_name)) = 0 THEN
	   RAISE EXCEPTION '02002: A location name to be created needs to be '
	   	 'entered.';
	END IF;

	SELECT
		loc_id
	INTO
		_l_id
	FROM
		mecb_loc
	WHERE
		loc	= old_name;

	IF _l_id IS NULL THEN
	   RAISE EXCEPTION '02003: The location name to be changed does not '
	   	 'exist in the location table.';
	END IF;

	UPDATE
		mecb_loc
	SET
		loc	= new_name
	WHERE
		loc_id	= _l_id;
		
END; $$
LANGUAGE plpgsql;

/*
	api_loc_del

	Deletes a location from the mecb)loc table if the location is also not
	in the mecb_part_loc table.
*/
DROP PROCEDURE IF EXISTS api_loc_del CASCADE;
CREATE OR REPLACE PROCEDURE api_loc_del (
       l_name	  VARCHAR
) AS $$
DECLARE
	_l_id		BIGINT:= 0;
	_rowcount	BIGINT:= 0;
BEGIN
	IF l_name IS NULL OR LENGTH(TRIM(l_name)) = 0 THEN
	   RAISE EXCEPTION '02101: The location name must be non-blank.';
	END IF;

	-- Ensure that the entered location name exists.
	SELECT
		loc_id
	INTO
		_l_id
	FROM
		mecb_loc
	WHERE
		loc	= l_name;

	IF _l_id IS NULL THEN
	   RAISE EXCEPTION '02102: The location name does not exist in the '
	   	 'location table.';
	END IF;

	-- See if any parts are using this before we try to delete it.
	SELECT
		COUNT(*)
	INTO
		_rowcount
	FROM
		mecb_part_loc
	WHERE
		loc_id	= _l_id;

	IF _rowcount > 0 THEN
	   RAISE EXCEPTION '02103: The location cannot be deleted as it has '
	   	 'parts using it.';
	END IF;

	-- See if any contacts are using this location before we try deletion.
	SELECT
		COUNT(*)
	INTO
		_rowcount
	FROM
		mecb_contact_loc
	WHERE
		loc_id	= _l_id;

	IF _rowcount > 0 THEN
	   RAISE EXCEPTION '02103: The location cannot be eleted as it has '
	   	 'contacts using it.';
	END IF;
	
	DELETE FROM
	       mecb_loc
	WHERE
		loc_id	= _l_id;

	GET DIAGNOSTICS _rowcount = row_count;

	IF _rowcount = 0 THEN
	   RAISE EXCEPTION '02104: The location delete failed.';
	END IF;
END; $$
LANGUAGE plpgsql;

/************************ End mecb_loc fiddly bits ***********************/
/************************ Begin mecb_addr_loc fiddly bits ****************/

/*
	api_addr_loc_ins

	Inserts an address record into the mecb_addr_loc table for a location.
*/
DROP PROCEDURE IF EXISTS api_addr_loc_ins;
CREATE OR REPLACE PROCEDURE api_addr_loc_ins (
       l_name	  VARCHAR,
       a_name	  VARCHAR
) AS $$
DECLARE
	_l_id		BIGINT:= 0;
	_a_id		BIGINT:= 0;
	_rowcount	INTEGER:= 0;
BEGIN

	IF l_name IS NULL OR LENGTH(TRIM(l_name)) = 0 THEN
	   RAISE EXCEPTION '02201: Location name must be non blank.';
	END IF;

	IF a_name IS NULL OR LENGTH(TRIM(a_name)) = 0 THEN
	   RAISE EXCEPTION '02202: Address must be non blank.';
	END IF;
	
	SELECT
		loc_id
	INTO
		_l_id
	FROM
		mecb_loc
	WHERE
		loc	= l_name;

	IF _l_id IS NULL THEN
	   RAISE EXCEPTION '02203: Invalid location name.';
	END IF;

	SELECT
		COALESCE(MAX(address_id) + 1,1)
	INTO
		_a_id
	FROM
		mecb_addr_loc
	WHERE
		loc_id	= _l_id;

	INSERT INTO mecb_addr_loc (
	       loc_id,
	       address_id,
	       address)
	VALUES (
	       _l_id,
	       _a_id,
	       a_name);

	GET DIAGNOSTICS _rowcount = row_count;

	IF _rowcount = 0 THEN
	   RAISE EXCEPTION '02204: Creation of address record failed.';
	END IF;
		
END; $$
LANGUAGE plpgsql;

/*
	api_addr_loc_del

	Deletes addresses for a location.
*/
DROP PROCEDURE IF EXISTS api_addr_loc_del CASCADE;
CREATE OR REPLACE PROCEDURE api_addr_loc_del (
       l_name	  VARCHAR,
       l_addr	  VARCHAR
) AS $$
DECLARE
	_l_id		BIGINT:= 0;
	_rowcount	INTEGER:= 0;
BEGIN
	IF l_name IS NULL OR LENGTH(TRIM(l_name)) = 0 THEN
	   RAISE EXCEPTION '02301: Location name cannot be blank.';
	END IF;

	-- Find the location id.
	SELECT
		loc_id
	INTO
		_l_id
	FROM
		mecb_loc
	WHERE
		loc	= l_name;

	IF _l_id IS NULL THEN
	   RAISE EXCEPTION '02302: Invalid location name.';
	END IF;

	IF LENGTH(l_addr) > 0  THEN
		DELETE FROM
		       mecb_addr_loc
		WHERE
			loc_id		= _l_id
	   AND	LOWER(address)	= LOWER(l_addr);
	ELSE	
		DELETE FROM
	       	       mecb_addr_loc
		WHERE
			loc_id	= _l_id;
	END IF;

	GET DIAGNOSTICS _rowcount = row_count;

	IF _rowcount = 0 THEN
	   RAISE EXCEPTION '02303: Address does not exist for location.';
	END IF;
	
END; $$
LANGUAGE plpgsql;

/************************ End mecb_addr_loc fiddly bits ******************/
/************************ Begin mecb_contact fiddly bits *****************/

/*
	api_contact_ins

	Creates a new contact.
*/
DROP PROCEDURE IF EXISTS api_contact_ins CASCADE;
CREATE OR REPLACE PROCEDURE api_contact_ins (
       c_name	  VARCHAR
) AS $$
DECLARE
	_c_id		INTEGER:= 0;
	_rowcount	INTEGER:= 0;
BEGIN

	IF c_name IS NULL OR LENGTH(TRIM(c_name)) = 0 THEN
	   RAISE EXCEPTION '02401: The contact name cannot be blank.';
	END IF;

	-- See if the contact already exists.
	SELECT
		contact_id
	INTO
		_c_id
	FROM
		mecb_contact
	WHERE
		contact	= LOWER(c_name);

	IF _c_id IS NOT NULL THEN
	   RAISE EXCEPTION '02402: The contact name already exists.';
	END IF;

	SELECT
		COALESCE(MAX(contact_id) + 1,1)
	INTO
		_c_id
	FROM
		mecb_contact;
		
	-- Create the new contact in lowercase format to avoid duplicate names.
	INSERT INTO mecb_contact (
	       contact,
	       contact_id)
	VALUES (
	       LOWER(c_name),
	       _c_id);

	GET DIAGNOSTICS _rowcount = row_count;

	IF _rowcount = 0 THEN
	   RAISE EXCEPTION '02403: Could not create the new contact.';
	END IF;
	
END; $$
LANGUAGE plpgsql;

/*
	api_contact_upd

	Edit the contact name.
*/
DROP PROCEDURE IF EXISTS api_contact_upd CASCADE;
CREATE OR REPLACE PROCEDURE api_contact_upd (
       old_name	  VARCHAR,
       new_name	  VARCHAR
) AS $$
DECLARE
	_c_id		INTEGER:= 0;
	_rowcount	INTEGER:= 0;
BEGIN

	IF old_name IS NULL OR LENGTH(TRIM(old_name)) = 0 THEN
	   RAISE EXCEPTION '02501: The contact name has to be non blank.';
	END IF;

	IF new_name IS NULL OR LENGTH(TRIM(new_name)) = 0 THEN
	   RAISE EXCEPTION '02502: The edited contact name has to be '
	   	 'non blank.';
	END IF;

	-- Get the current contact_id (everything is lowercased).
	SELECT
		contact_id
	INTO
		_c_id
	FROM
		mecb_contact
	WHERE
		contact		= LOWER(old_name);

	IF _c_id IS NULL THEN
	   RAISE EXCEPTION '02503: Invalid contact name.';
	END IF;

	-- Ensure that the new info doesn't already exist.
	SELECT
		COUNT(*)
	INTO
		_rowcount
	FROM
		mecb_contact
	WHERE
		contact		= LOWER(new_name);

	IF _rowcount > 0 THEN
	   RAISE EXCEPTION '02504: The edit already exists.';
	END IF;

	-- Update the requisite contact info, ensuring it is lower case.
	UPDATE
		mecb_contact
	SET
		contact		= LOWER(new_name)
	WHERE
		contact_id	= _c_id;

	GET DIAGNOSTICS _rowcount = row_count;

	IF _rowcount = 0 THEN
	   RAISE EXCEPTION '02505: Unable to update the edits.';
	END IF;
END; $$
LANGUAGE plpgsql;

/*
	api_contact_del

	Deletes the contact from the mecb_contact table.
*/
DROP PROCEDURE IF EXISTS api_contact_del;
CREATE OR REPLACE PROCEDURE api_contact_del (
       c_name	 VARCHAR
) AS $$
DECLARE
	_c_id		BIGINT:= 0;
	_rowcount	INTEGER:= 0;
BEGIN

	IF c_name IS NULL OR LENGTH(TRIM(c_name)) = 0 THEN
	   RAISE EXCEPTION '02601: The contact name must be non blank.';
	END IF;

	-- get the contact id from the mecb_contact table.
	SELECT
		contact_id
	INTO
		_c_id
	FROM
		mecb_contact
	WHERE
		contact		= LOWER(c_name);

	IF _c_id IS NULL THEN
	   RAISE EXCEPTION '02602: Invalid contact name.';
	END IF;

	-- Ensure that the contact doesn't already exist in mecb_contact_loc.
	SELECT
		COUNT(*)
	INTO
		_rowcount
	FROM
		mecb_contact_loc
	WHERE
		contact_id	= _c_id;

	IF _rowcount > 0 THEN
	   RAISE EXCEPTION '02603: Cannot delete a contact used by a part.';
	END IF;

	-- Delete the detail info (phone, fax, email, etc.)
	DELETE FROM
	       mecb_contact_det
	WHERE
		contact_id	= _c_id;

	-- Delete the contact.
	DELETE FROM
	       mecb_contact
	WHERE
		contact_id	= _c_id;

	GET DIAGNOSTICS _rowcount = row_count;

	IF _rowcount = 0 THEN
	   RAISE EXCEPTION '02604: Wasn''t able to delete the contact.';
	END IF;
	
END; $$
LANGUAGE plpgsql;

/************************ End mecb_contact fiddly bits *******************/
/************************ Begin mecb_contact_loc fiddly bits**************/

/*
	api_contact_loc_ins

	Associate a contact with a location.
*/
DROP PROCEDURE IF EXISTS api_contact_loc_ins CASCADE;
CREATE OR REPLACE PROCEDURE api_contact_loc_ins (
       c_name	  VARCHAR,
       l_name	  VARCHAR
) AS $$
DECLARE
	_c_id		BIGINT:= 0;
	_l_id		BIGINT:= 0;
	_rowcount	INTEGER:= 0;
BEGIN

	IF c_name IS NULL OR LENGTH(TRIM(c_name)) = 0 THEN
	   RAISE EXCEPTION '02701: The contact name must be non blank.';
	END IF;

	IF l_name IS NULL OR LENGTH(TRIM(l_name)) = 0 THEN
	   RAISE EXCEPTION '02702: The location name must be non blank.';
	END IF;

	SELECT
		contact_id
	INTO
		_c_id
	FROM
		mecb_contact
	WHERE
		contact		= c_name;

	IF _c_id IS NULL THEN
	   RAISE EXCEPTION '02703: Invalid contact name.';
	END IF;

	SELECT
		loc_id
	INTO
		_l_id
	FROM
		mecb_loc
	WHERE
		loc	= l_name;

	IF _l_id IS NULL THEN
	   RAISE EXCEPTION '02704: Invalid location name.';
	END IF;

	SELECT
		COUNT(*)
	INTO
		_rowcount
	FROM
		mecb_contact_loc
	WHERE
		loc_id		= _l_id
	AND	contact_id	= _c_id;

	IF _rowcount > 0 THEN
	   RAISE EXCEPTION '02705: The contact already exists for the location';
	END IF;

	INSERT INTO mecb_contact_loc (
	       loc_id,
	       contact_id)
	VALUES (
	       _l_id,
	       _c_id);

	GET DIAGNOSTICS _rowcount = row_count;

	IF _rowcount = 0 THEN
	   RAISE EXCEPTION '02706: The contact wasn''t associated with the '
	   	 'location.';
	END IF;
	
END; $$
LANGUAGE plpgsql;

/*
	api_contact_loc_del

	Removes a contact from associated locations.
*/
DROP PROCEDURE IF EXISTS api_contact_loc_del;
CREATE OR REPLACE PROCEDURE api_contact_loc_del (
       c_name	  VARCHAR,
       l_name	  VARCHAR DEFAULT ''
) AS $$
DECLARE
	_c_id		BIGINT:= 0;
	_l_id		BIGINT:= 0;
	_rowcount	INTEGER:= 0;
BEGIN

	IF c_name IS NULL OR LENGTH(TRIM(c_name)) = 0 THEN
	   RAISE EXCEPTION '02801: The contact name must be non blank.';
	END IF;

	-- Get the contact id.
	SELECT
		contact_id
	INTO
		_c_id
	FROM
		mecb_contact
	WHERE
		contact		= c_name;

	-- If the location was enteed, ensure it is valid.
	IF LENGTH(TRIM(l_name)) > 0 THEN
	   SELECT
		loc_id
	   INTO
		_l_id
	   FROM
		mecb_loc
	   WHERE
		LOWER(loc)	= LOWER(l_name);

	   IF _l_id IS NULL THEN
	      RAISE EXCEPTION '02802: Invalid location name.';
	   END IF;

	END IF;
	
	IF _c_id IS NULL THEN
	   RAISE EXCEPTION '02803: Invalid contact name.';
	END IF;

	-- If _l_id = 0 delete all contact ids for location, otherwise onel
	-- delete a specific contact from a location.
	SELECT
		COUNT(*)
	INTO
		_rowcount
	FROM
		mecb_contact_loc
	WHERE
		(contact_id	= _c_id
	AND	_l_id		= 0)
	OR	(contact_id	= _c_id
	AND	loc_id		= _l_id);

	IF _rowcount = 0 THEN
	   RAISE EXCEPTION '02804: Contact isn''t associated with '
	   	 'location(s).';
	END IF;

	-- Either delete only one contact id or all of them for a location.
	DELETE FROM
	       mecb_contact_loc
	WHERE
		(contact_id	= _c_id
	AND	_l_id		= 0)
	OR	(contact_id	= _c_id
	AND	loc_id		= _l_id);

	GET DIAGNOSTICS _rowcount = row_count;

	IF _rowcount = 0 THEN
	   RAISE EXCEPTION '02805: Wasn''t able to delete the record.';
	END IF;
	
END; $$
LANGUAGE plpgsql;


/************************ End mecb_contact_loc fiddly bits ***************/
/************************ Begin mecb_contact_det fiddly bits *************/

/*
	api_contact_det_ins

	Inserts new contact information into the mecb_contact_det table as
	defined by the mecb_contact_det_type table.
*/
DROP PROCEDURE IF EXISTS api_contact_det_ins CASCADE;
CREATE OR REPLACE PROCEDURE api_contact_det_ins (
       c_name	  	    VARCHAR,
       c_type		    VARCHAR,
       det_stuff	    VARCHAR
) AS $$
DECLARE
	_c_id		BIGINT:= 0;
	_c_type_id	BIGINT:= 0;
	_d_id		BIGINT:= 0;
	_rowcount	INTEGER:= 0;
BEGIN

	IF c_name IS NULL OR LENGTH(TRIM(c_name)) = 0 THEN
	   RAISE EXCEPTION '02901: Contact name has to be non blank.';
	END IF;

	IF c_type IS NULL OR LENGTH(TRIM(c_type)) = 0 THEN
	   RAISE EXCEPTION '02902: Contact type has to be non blank.';
	END IF;

	IF det_stuff IS NULL OR LENGTH(TRIM(det_stuff)) = 0 THEN
	   RAISE EXCEPTION '02903: Details must be non blank.';
	END IF;
	
	SELECT
		contact_id
	INTO
		_c_id
	FROM
		mecb_contact
	WHERE
		contact		= LOWER(c_name);

	IF _c_id IS NULL THEN
	   RAISE EXCEPTION '02904: Invalid contact name.';
	END IF;

	SELECT
		contact_type_id
	INTO
		_c_type_id
	FROM
		mecb_contact_det_type
	WHERE
		contact_type	= LOWER(c_type);

	IF _c_type_id IS NULL THEN
	   RAISE EXCEPTION '02905: Invalid contact type.';
	END IF;

	SElECT
		COALESCE(MAX(det_id) + 1,1)
	INTO
		_d_id
	FROM
		mecb_contact_det
	WHERE
		contact_id	= _c_id;

	SELECT
		COUNT(*)
	INTO
		_rowcount
	FROM
		mecb_contact_det
	WHERE
		contact_id	= _c_id
	AND	contact_type_id	= _c_type_id;

	IF _rowcount > 0 THEN
	   RAISE EXCEPTION '02906: The contact detail type already exists.';
	END IF;
		
	INSERT INTO mecb_contact_det (
	       det_id,
	       contact_id,
	       contact_type_id,
	       details)
	VALUES (
	       _d_id,
	       _c_id,
	       _c_type_id,
	       det_stuff);

	GET DIAGNOSTICS _rowcount = row_count;

	IF _rowcount = 0 THEN
	   RAISE EXCEPTION '02907: The new contact detail type information '
	   	 'not created.';
	END IF;
	
END; $$
LANGUAGE plpgsql;

/*
	api_contact_det_upd

	Edits the details of the contact.
*/
DROP PROCEDURE IF EXISTS api_contact_det_upd;
CREATE OR REPLACE PROCEDURE api_contact_det_upd (
       c_name	  	    VARCHAR,
       ct_name		    VARCHAR,
       det_stuff	    VARCHAR
) AS $$
DECLARE
	_c_id		BIGINT:= 0;
	_ct_id		BIGINT:= 0;
	_det_stuff_id	BIGINT:= 0;
	_rowcount	INTEGER:= 0;
BEGIN

	IF c_name IS NULL OR LENGTH(TRIM(c_name)) = 0 THEN
	   RAISE EXCEPTION '03001: Contact name has to be non blank.';
	END IF;

	IF ct_name IS NULL OR LENGTH(TRIM(ct_name)) = 0 THEN
	   RAISE EXCEPTION '03002: Contact type has to be non blank.';
	END IF;

	IF det_stuff IS NULL OR LENGTH(TRIM(det_stuff))= 0 THEN
	   RAISE EXCEPTION '03003: Details must be non blank.';
	END IF;

	SELECT
		contact_id
	INTO
		_c_id
	FROM
		mecb_contact
	WHERE
		contact		= LOWER(c_name);

	IF _c_id IS NULL THEN
	   RAISE EXCEPTION '03004: Invalid contact name.';
	END IF;

	SELECT
		contact_type_id
	INTO
		_ct_id
	FROM
		mecb_contact_det_type
	WHERE
		contact_type	= ct_name;

	IF _ct_id IS NULL THEN
	   RAISE EXCEPTION '03005: Invalid contact details type.';
	END IF;

	SELECT
		COUNT(*)
	INTO
		_rowcount
	FROM
		mecb_contact_det
	WHERE
		contact_id	= _c_id
	AND	contact_type_id	= _ct_id;

	IF _rowcount = 0 THEN
	   RAISE EXCEPTION '03006: This contact information does not exist.';
	END IF;

	UPDATE
		mecb_contact_det
	SET
		details		= det_stuff
	WHERE
		contact_id	= _c_id
	AND	contact_type_id	= _ct_id;

	GET DIAGNOSTICS _rowcount = row_count;

	IF _rowcount = 0 THEN
	   RAISE EXCEPTION '03007: Wasn''t able to edit this contact detail.';
	END IF;
END; $$
LANGUAGE plpgsql;

/*
	api_contect_det_del

	Deletes details of a contact.
*/
DROP PROCEDURE IF EXISTS api_contact_det_del;
CREATE OR REPLACE PROCEDURE api_contact_det_del (
       c_name	  	    VARCHAR,
       ct_name		    VARCHAR DEFAULT ''
) AS $$
DECLARE
	_c_id		BIGINT:= 0;
	_ct_id		BIGINT:= 0;
	_rowcount	INTEGER:= 0;
BEGIN

	IF c_name IS NULL OR LENGTH(TRIM(c_name)) = 0 THEN
	   RAISE EXCEPTION '03101: Contact name has to be non blank.';
	END IF;

	SELECT
		contact_id
	INTO
		_c_id
	FROM
		mecb_contact
	WHERE
		contact		= c_name;

	IF _c_id IS NULL THEN
	   RAISE EXCEPTION '03102: Invalid contact name.';
	END IF;
	
	IF ct_name IS NULL OR LENGTH(TRIM(ct_name)) = 0 THEN
	   DELETE FROM
	   	  mecb_contact_det
	   WHERE
		contact_id	= _c_id;
	ELSE
		SELECT
			contact_type_id
		INTO
			_ct_id
		FROM
			mecb_contact_det_type
		WHERE
			contact_type	= ct_name;

		IF _ct_id IS NULL THEN
		   RAISE EXCEPTION '03103: Invalid contact type.';
		END IF;

		SELECT
			COUNT(*)
		INTO
			_rowcount
		FROM
			mecb_contact_det
		WHERE
			contact_id	= _c_id
		AND	contact_type_id	= _ct_id;

		IF _rowcount = 0 THEN
		   RAISE EXCEPTION '03104: Contact details don''t exist for '
		   	 'this contact type.';
		END IF;
		
		DELETE FROM
		       mecb_contact_det
		WHERE
			contact_id	= _c_id
		AND	contact_type_id	= _ct_id;
	END IF;

	GET DIAGNOSTICS _rowcount = row_count;

	IF _rowcount = 0 THEN
	   RAISE EXCEPTION '03105: Wasn''t able do delete contact details.'
	   	 USING HINT = 'It may not already exist';
	END IF;
	
END; $$
LANGUAGE plpgsql;

/************************ End mecb_contact_det fiddly bits ***************/
/************************ Begin mecb_maint_type fiddly bits **************/
/*
	api_maint_type_ins

	Creates maintenance type for use by the maintenance subsystem.
*/
DROP PROCEDURE IF EXISTS api_maint_type_ins;
CREATE OR REPLACE PROCEDURE api_maint_type_ins (
     m_type    VARCHAR
) AS $$
DECLARE
	_m_type_id	BIGINT:= 0;
	_rowcount	INTEGER:= 0;
BEGIN

	IF m_type IS NULL OR LENGTH(TRIM(m_type)) = 0 THEN
	   RAISE EXCEPTION '03401 New maintenance type has to be non blank.';
	END IF;

	-- Ensure the maintenance type doesn't already exist.
	SELECT
		COUNT(*)
	INTO
		_rowcount
	FROM
		mecb_maint_type
	WHERE
		LOWER(maint_type)	= LOWER(m_type);

	IF _rowcount > 0 THEN
	   RAISE EXCEPTION '03402 Maintenance type already exists.';
	END IF;

	-- Find the next monotonically increasing id.
	SELECT
		COALESCE(MAX(maint_type_id) + 1,1)
	INTO
		_m_type_id
	FROM
		mecb_maint_type;

	INSERT INTO mecb_maint_type (
	       maint_type_id,
	       maint_type)
	VALUES (
	       _m_type_id,
	       m_type);

	GET DIAGNOSTICS _rowcount = row_count;

	IF _rowcount = 0 THEN
	   RAISE EXCEPTION '03403 Wasn''t able to create the new maintenance '
	   	 'type.';
	END IF;
	
END; $$
LANGUAGE plpgsql;

/*
	api_maint_type_upd

	Edits the maintenance type.
*/
DROP PROCEDURE IF EXISTS api_maint_type_upd;
CREATE OR REPLACE PROCEDURE api_maint_type_upd (
     old_type  VARCHAR,
     new_type  VARCHAR
) AS $$
DECLARE
	_old_type_id	BIGINT:= 0;
	_new_type_id	BIGINT:= 0;
	_rowcount	INTEGER:= 0;
BEGIN

	IF old_type IS NULL OR LENGTH(TRIM(old_type)) = 0 THEN
	   RAISE EXCEPTION '03501: The maintenance type to change has to be '
	   	 'non blank.';
	END IF;

	-- Ensure the type to be changed exists.
	SELECT
		maint_type_id
	INTO
		_old_type_id
	FROM
		mecb_maint_type
	WHERE
		LOWER(maint_type)	= LOWER(old_type);

	IF _old_type_id IS NULL THEN
	   RAISE EXCEPTION '03503: Invalid maintenance type.';
	END IF;

	-- Ensure that the new edits don't already exist.
	SELECT
		COUNT(*)
	INTO
		_rowcount
	FROM
		mecb_maint_type
	WHERE
		LOWER(maint_type)	= LOWER(new_type);

	IF _rowcount THEN
	   RAISE EXCEPTION '03504: The changes conflict with a type that '
	   	 'already exists.';
	END IF;

	UPDATE
		mecb_maint_type
	SET
		maint_type	= new_type
	WHERE
		maint_type_id	= _old_type_id;

	GET DIAGNOSTICS _rowcount = row_count;

	IF _rowcount = 0 THEN
	   RAISE EXCEPTION '03505; Wasn''t able to make the change.';
	END IF;
	
END; $$
LANGUAGE plpgsql;

/*
	api_maint_type_del

	Deletes a maintenance type as long as it is not attached to any
	maintenance action.
*/
DROP PROCEDURE IF EXISTS api_maint_type_del;
CREATE OR REPLACE PROCEDURE api_maint_type_del (
       m_type	  VARCHAR
) AS $$
DECLARE
	_m_type_id	BIGINT:= 0;
	_rowcount	INTEGER:= 0;
BEGIN

	IF m_type IS NULL OR LENGTH(TRIM(m_type)) = 0 THEN
	   RAISE EXCEPTION '03601 Maintenance type to be deleted must be non '
	   	 'blank.';
	END IF;

	-- Ensure the maintenance type to be deleted exists first.
	SELECT
		maint_type_id
	INTO
		_m_type_id
	FROM
		mecb_maint_type
	WHERE
		LOWER(maint_type)	= LOWER(m_type);

	IF _m_type_id IS NULL THEN
	   RAISE EXCEPTION '03602 Invalid maintenance type.';
	END IF;

	SELECT
		COUNT(*)
	INTO
		_rowcount
	FROM
		mecb_sched_maint
	WHERE
		maint_type_id	= _m_type_id;

	IF _rowcount > 0 THEN
	   RAISE EXCEPTION '03603: The maintenance type is being used by a '
	   	 'maintenance action.';
	END IF;
	
	DELETE FROM
	       mecb_maint_type
	WHERE
		maint_type_id	= _m_type_id;

	GET DIAGNOSTICS _rowcount = row_count;

	IF _rowcount = 0 THEN
	   RAISE EXCEPTION '03604 Wasn''t able to delete the maintenance type.';
	END IF;
	
END; $$
LANGUAGE plpgsql;

/************************ End mecb_maint_type fiddly bits ****************/
/************************ Begin mecb_sched_maint fiddly bits *************/
/*
	api_sched_maint_ins

	Schedules dates to start and complete a maintenance action.
*/
DROP PROCEDURE IF EXISTS api_sched_maint_ins;
CREATE OR REPLACE PROCEDURE api_sched_maint_ins (
       p_name	  	    VARCHAR,
       m_type		    VARCHAR,
       b_date		    VARCHAR,
       e_date		    VARCHAR
) AS $$
DECLARE
	_p_id		BIGINT:= 0;
	_m_type_id	BIGINT:= 0;
	_b_date		DATE;
	_e_date		DATE;
	_rowcount	INTEGER:= 0;
BEGIN

	IF p_name IS NULL OR LENGTH(TRIM(p_name)) = 0 THEN
	   RAISE EXCEPTION '03701: Part name has to be non blank.';
	END IF;

	IF m_type IS NULL OR LENGTH(TRIM(m_type)) = 0 THEN
	   RAISE EXCEPTION '03702: Maintenance type has to be non blank.';
	END IF;

	IF b_date IS NULL OR LENGTH(TRIM(b_date)) = 0 THEN
	   RAISE EXCEPTION '03703: Beginning date has to be non blank.';
	END IF;

	IF e_date IS NULL OR LENGTH(TRIM(e_date)) = 0 THEN
	   RAISE EXCEPTION '03704: Ending date has to be non blank.';
	END IF;

	SELECT
		part_id
	INTO
		_p_id
	FROM
		mecb_part
	WHERE
		LOWER(part)	= LOWER(p_name);

	IF _p_id IS NULL THEN
	   RAISE EXCEPTION '03705: Invalid part name.';
	END IF;

	SELECT
		maint_type_id
	INTO
		_m_type_id
	FROM
		mecb_maint_type
	WHERE
		LOWER(maint_type)	= LOWER(m_type);

	IF _m_type_id IS NULL THEN
	   RAISE EXCEPTION '03706: Invalid maintenance type.';
	END IF;
	
	SELECT
		COUNT(*)
	INTO
		_rowcount
	FROM
		mecb_sched_maint
	WHERE
		part_id		= _p_id
	AND	maint_type_id	= _m_type_id;

	IF _rowcount > 0 THEN
	   RAISE EXCEPTION '03707: Maintenance record for this part and type '
	   	 'already exists.';
	END IF;

	SELECT
		DATE(b_date)
	INTO
		_b_date;

	IF _b_date IS NULL THEN
	   RAISE EXCEPTION '03708: Invalid begin date.';
	END IF;

	SELECT
		DATE(e_date)
	INTO
		_e_date;

	IF _e_date IS NULL THEN
	   RAISE EXCEPTION '03709: Invalid end date.';
	END IF;

	INSERT INTO mecb_sched_maint (
	       part_id,
	       maint_type_id,
	       begin_date,
	       end_date)
	VALUES (
	       _p_id,
	       _m_type_id,
	       _b_date,
	       _e_date);

	GET DIAGNOSTICS _rowcount = row_count;

	IF _rowcount = 0 THEN
	   RAISE EXCEPTION '03710: Wasn''t able to create new scheduled '
	   	 'maintenance record.';
	END IF;
	
END; $$
LANGUAGE plpgsql;

/*
	api_sched_maint_del

	Deletes a scheduled maintenance action.
*/
DROP PROCEDURE IF EXISTS api_sched_maint_del;
CREATE OR REPLACE PROCEDURE api_sched_maint_del (
       p_name	  VARCHAR,
       m_type	  VARCHAR
) AS $$
DECLARE
	_p_id		BIGINT:= 0;
	_mt_id		BIGINT:= 0;
	_rowcount	INTEGER:= 0;
BEGIN

	IF p_name IS NULL OR LENGTH(TRIM(p_name)) = 0 THEN
	   RAISE EXCEPTION '03801: Part name must be non blank.';
	END IF;

	IF m_type IS NULL OR LENGTH(TRIM(m_type)) = 0 THEN
	   RAISE EXCEPTION '03802: Maintenance type must be non blank.';
	END IF;

	SELECT
		part_id
	INTO
		_p_id
	FROM
		mecb_part
	WHERE
		LOWER(part)	= LOWER(p_name);

	IF _p_id IS NULL THEN
	   RAISE EXCEPTION '03803: Invalid part name.';
	END IF;

	SELECT
		maint_type_id
	INTO
		_mt_id
	FROM
		mecb_maint_type
	WHERE
		LOWER(maint_type)	= LOWER(m_type);

	IF _mt_id IS NULL THEN
	   RAISE EXCEPTION '03804: Invalid maintenance type.';
	END IF;

	DELETE FROM
	       mecb_sched_maint
	WHERE
		part_id		= _p_id
	AND	maint_type_id	= _mt_id;

	GET DIAGNOSTICS _rowcount = row_count;

	IF _rowcount = 0 THEN
	   RAISE EXCEPTION '03805: Wasn''t able to delete maintenance action.';
	END IF;
	
END; $$
LANGUAGE plpgsql;

/************************ End mecb_sched_maint fiddly bits ***************/
/************************ Begin mecb_maint_hist fiddly bits **************/
/*
	api_maint_hist_ins

	Creates a history record for a maintenance action.
*/
DROP PROCEDURE IF EXISTS api_maint_hist_ins;
CREATE OR REPLACE PROCEDURE api_maint_hist_ins (
       p_name	  VARCHAR,
       mt_name	  VARCHAR,
       act_date	  VARCHAR,
       m_stuff	  VARCHAR
) AS $$
DECLARE
	_p_id		BIGINT:= 0;
	_h_id		BIGINT:= 0;
	_act_date	DATE;
	_rowcount	INTEGER:= 0;
BEGIN

	IF p_name IS NULL OR LENGTH(TRIM(p_name)) = 0 THEN
	   RAISE EXCEPTION '03901: Part name must be non blank.';
	END IF;

	IF mt_name IS NULL OR LENGTH(TRIM(mt_name)) = 0 THEN
	   RAISE EXCEPTION '03902: Maintenance type must be non blank.';
	END IF;
	
	IF act_date IS NULL OR LENGTH(TRIM(act_date)) = 0 THEN
	   RAISE EXCEPTION '03903: Action date must not be blank.';
	END IF;

	IF m_stuff IS NULL OR LENGTH(TRIM(m_stuff)) = 0 THEN
	   RAISE EXCEPTION '03904: Maintenance record has to be non blank.';
	END IF;
	
	-- Ensure that the part exists.
	SELECT
		part_id
	INTO
		_p_id
	FROM
		mecb_part
	WHERE
		LOWER(part)	= LOWER(p_name);

	IF _p_id IS NULL THEN
	   RAISE EXCEPTION '03905: Invalid part name.';
	END IF;

	-- Get the next monotonically increasing history id for the part.
	SELECT
		COALESCE(MAX(hist_id) + 1, 1)
	INTO
		_h_id
	FROM
		mecb_maint_hist
	WHERE
		part_id		= _p_id;
		
	-- Ensure that the maintenance type exists.
	SELECT
		COUNT(*)
	INTO
		_rowcount
	FROM
		mecb_maint_type
	WHERE
		LOWER(maint_type)	= LOWER(mt_name);

	IF _rowcount = 0 THEN
	   RAISE EXCEPTION '03906: Invalid maintenance type.';
	END IF;
	
	SELECT
		DATE(act_date)
	INTO
		_act_date;

	IF _act_date IS NULL THEN
	   RAISE EXCEPTION '03907: Invalid action date.';
	END IF;

	INSERT INTO mecb_maint_hist (
	       part_id,
	       hist_id,
	       action_complete,
	       maint_type,
	       maint)
	VALUES (
	       _p_id,
	       _h_id,
	       _act_date,
	       mt_name,
	       _act_date || ' ' || mt_name || ': ' || m_stuff);

	GET DIAGNOSTICS _rowcount = row_count;

	IF _rowcount = 0 THEN
	   RAISE EXCEPTION '03908: Wasn''t able to create maintenance history '
	   	 'record.';
	END IF;
	
END; $$
LANGUAGE plpgsql;

/************************ End mecb_maint_hist fiddly bits ****************/
/************************ Begin mecb_security_init fiddly bits **************/

/*
	Insert or update the on privilege.
*/
DROP PROCEDURE IF EXISTS api_security_init_ins;
CREATE OR REPLACE PROCEDURE api_security_init_ins (
       user_name  VARCHAR,
       isOn	  BOOL DEFAULT 'f',
       userIsOn	  BOOL DEFAULT 'f'
) AS $$
DECLARE
	_rowcount	BIGINT;
BEGIN
      SELECT
		COUNT(*)
	INTO
		_rowcount
	FROM
		mecb_security_init
	WHERE
		LOWER(name)	= 'general';

	IF _rowcount = 0 THEN
	   INSERT INTO mecb_security_init (
	   	  name,
		  is_on)
	   VALUES ('general',
	   	  isOn);
	ELSE
	   UPDATE
		mecb_security_init
	  SET
		is_on	= isOn
	  WHERE
		LOWER(name)	= 'general';
	END IF;

	IF LENGTH(TRIM(user_name)) > 0 THEN
	   SELECT
		COUNT(*)
	   INTO
		_rowcount
	   FROM
		pg_catalog.pg_user
	   WHERE
		LOWER(usename)	= LOWER(user_name);

	   IF _rowcount = 0 THEN
	      RAISE EXCEPTION '04001: Invalid user name.';
	   END IF;

	   UPDATE
		mecb_security_init
	   SET
		is_on	= userIsOn
	   WHERE
		LOWER(name)	= LOWER(user_name);

          GET DIAGNOSTICS _rowcount = row_count;

	  IF _rowcount = 0 THEN
	     INSERT INTO mecb_security_init (
	     	    name,
		    is_on)
	     VALUES (user_name,
	     	    userIsOn);
	  END IF;
	  
	END IF;

        GET DIAGNOSTICS _rowcount = row_count;

	IF _rowcount = 0 THEN
	   RAISE EXCEPTION '04002: Unable to create the privileges for user.';
	END IF;
END; $$
LANGUAGE plpgsql;

/************************ End mecb_security_init fiddly bits **************/
/************************ Begin mecb_security_privs fiddly bits **************/

/*
	Insert privileges.
*/
DROP PROCEDURE IF EXISTS api_security_privs_ins;
CREATE OR REPLACE PROCEDURE api_security_privs_ins (
       user_name  VARCHAR,
       procs	  VARCHAR,
       privs	  VARCHAR
) AS $$
DECLARE
	_rowcount	BIGINT;
BEGIN

	IF LENGTH(TRIM(user_name)) = 0 THEN
	   RAISE EXCEPTION '04101: User name cannot be blank.';
	END IF;

	IF LENGTH(TRIM(procs)) = 0 THEN
	   RAISE EXCEPTION '04102: Procedure name cannot be blank.';
	END IF;

	SELECT
		COUNT(*)
	INTO
		_rowcount
	FROM
		pg_catalog.pg_user
	WHERE
		LOWER(usename)	= LOWER(user_name);

	IF _rowcount = 0 THEN
	   RAISE EXCEPTION '04103: Invalid user name.';
	END IF;

	SELECT
		COUNT(*)
	INTO
		_rowcount
	FROM
		mecb_security_procs
	WHERE
		LOWER(proc)	= LOWER(procs);

	IF _rowcount = 0 THEN
	   RAISE EXCEPTION '04104: Invalid procedure name.';
	END IF;

	SELECT
		COUNT(*)
	INTO
		_rowcount
	FROM
		mecb_security_privs
	WHERE
		LOWER(name)	= LOWER(user_name)
	AND	LOWER(proc)	= LOWER(procs);

	IF _rowcount > 0 THEN
	   RAISE EXCEPTION '04105: Privilege already exists.';
	END IF;

	IF LENGTH(TRIM(privs)) = 0 THEn
	   privs = 'None';
	END IF;

	INSERT INTO mecb_security_privs (
	       name,
	       proc,
	       priv)
	VALUES (
	       user_name,
	       procs,
	       privs);

	GET DIAGNOSTICS _rowcount = row_count;

	IF _rowcount = 0 THEN
	   RAISE EXCEPTION '04106: Wasn''t able to update privileges.';
	END IF;

END; $$
LANGUAGE plpgsql;

/*
	Update privileges.
*/
DROP PROCEDURE IF EXISTS api_security_privs_upd;
CREATE OR REPLACE PROCEDURE api_security_privs_upd (
       user_name  VARCHAR,
       procs	  VARCHAR,
       privs	  VARCHAR
) AS $$
DECLARE
	_rowcount	BIGINT;
BEGIN

	IF LENGTH(TRIM(user_name)) = 0 THEN
	   RAISE EXCEPTION '04201: User name cannot be blank.';
	END IF;

	IF LENGTH(TRIM(procs)) = 0 THEN
	   RAISE EXCEPTION '04202: Procedure name cannot be blank.';
	END IF;

	SELECT
		COUNT(*)
	INTO
		_rowcount
	FROM
		pg_catalog.pg_user
	WHERE
		LOWER(usename)	= LOWER(user_name);

	IF _rowcount = 0 THEN
	   RAISE EXCEPTION '04203: Invalid user name.';
	END IF;

	SELECT
		COUNT(*)
	INTO
		_rowcount
	FROM
		mecb_security_procs
	WHERE
		LOWER(proc)	= LOWER(procs);

	IF _rowcount = 0 THEN
	   RAISE EXCEPTION '04204: Invalid procedure name.';
	END IF;

	SELECT
		COUNT(*)
	INTO
		_rowcount
	FROM
		mecb_security_privs
	WHERE
		LOWER(name)	= LOWER(user_name)
	AND	LOWER(proc)	= LOWER(procs);

	IF LENGTH(TRIM(privs)) = 0 THEN
	   privs = 'None';
	END IF;

	IF _rowcount = 0 THEN
	   INSERT INTO mecb_security_privs (
	   	  name,
		  proc,
		  priv)
	   VALUES (LOWER(user_name),
	   	  LOWER(procs),
		  privs);
	ELSE
	   UPDATE
		mecb_security_privs
	   SET
		priv	= privs
	   WHERE
		name	= user_name
	   AND	proc	= procs;
	END IF;
	
	GET DIAGNOSTICS _rowcount = row_count;

	IF _rowcount = 0 THEN
	   RAISE EXCEPTION '04206: Wasn''t able to update privileges.';
	END IF;

END; $$
LANGUAGE plpgsql;

/*
	Delete privileges.
*/
DROP PROCEDURE IF EXISTS api_security_privs_del;
CREATE OR REPLACE PROCEDURE api_security_privs_del (
       user_name  VARCHAR,
       procs	  VARCHAR,
       privs	  VARCHAR
) AS $$
DECLARE
	_rowcount	BIGINT;
BEGIN

	IF LENGTH(TRIM(user_name)) = 0 THEN
	   RAISE EXCEPTION '04301: User name cannot be blank.';
	END IF;

	SELECT
		COUNT(*)
	INTO
		_rowcount
	FROM
		mecb_security_privs
	WHERE
		LOWER(name)	= LOWER(user_name);

	IF LENGTH(TRIM(procs)) = 0 AND _rowcount > 0 THEN
	   DELETE FROM
	   	  mecb_security_privs
	   WHERE
		LOWER(name)	= LOWER(user_name);

	   GET DIAGNOSTICS _rowcount = row_count;

	   IF _rowcount = 0 THEN
	      RAISE EXCEPTION '04302: Couldn''t delete privileges.';
    	   END IF;

	ELSEIF _rowcount > 0 THEN
	   DELETE FROM
	       mecb_security_privs
	   WHERE
		LOWER(name)	= LOWER(user_name)
	   AND	LOWER(proc)	= LOWER(procs);

	   GET DIAGNOSTICS _rowcount = row_count;

	   IF _rowcount = 0 THEN
	      RAISE EXCEPTION '04305: Wasn''t able to delete privileges.';
	   END IF;
 
	END IF;
	
END; $$
LANGUAGE plpgsql;

/************************ End mecb_security_privs fiddly bits **************/

