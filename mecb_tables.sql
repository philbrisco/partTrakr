/*
	This file drops and creates all tables for the part tracker database.
*/
--set client_min_messages TO WARNING;

\r
DROP TABLE IF EXISTS mecb_config CASCADE;\qecho '        mecb config'

CREATE TABLE IF NOT EXISTS mecb_config (
       config	    	   	VARCHAR,
       config_id		BIGINT UNIQUE NOT NULL DEFAULT 0,
       ancestor_config_id	BIGINT NOT NULL DEFAULT 0,
       parent_config_id		BIGINT NOT NULL DEFAULT 0,
       config_type_id		BIGINT NOT NULL DEFAULT 0,
       level			INTEGER NOT NULL DEFAULT 0,
       PRIMARY KEY		(config)
);\qecho '        mecb_config';

DROP INDEX IF EXISTS mecb_config_idx CASCADE\g
\qecho '        mecb_config_idx'

CREATE UNIQUE INDEX mecb_config_idx ON mecb_config(config_id)\g
\qecho '        mecb_config_idx'

DROP TABLE IF EXISTS mecb_part_type CASCADE\g\qecho '       mecb_part_type'

CREATE TABLE IF NOT EXISTS mecb_part_type (
       part_type		VARCHAR,
       part_type_id		BIGINT 	   UNIQUE NOT NULL DEFAULT 0,
       part_type_class		INTEGER    DEFAULT 0, -- no dups by default
       PRIMARY KEY		(part_type)
);\qecho '       mecb_part_type'

DROP INDEX IF EXISTS mecb_part_type_idx CASCADE\g
\qecho '        mecb_part_type_idx'

CREATE UNIQUE INDEX mecb_part_type_idx ON
       mecb_part_type(part_type_id)\g\qecho '        mecb_part_type_idx'

DROP TABLE IF EXISTS mecb_config_type CASCADE\g\qecho '        mecb_config_type'

CREATE TABLE IF NOT EXISTS mecb_config_type  (
       config_type		 VARCHAR,
       config_type_id		 BIGINT UNIQUE NOT NULL DEFAULT 0,
       part_type_id		 BIGINT,
       PRIMARY KEY		 (config_type)
);\qecho '        mecb_config_type'

DROP INDEX IF EXISTS mecb_config_type_idx CASCADE\g
\qecho '       mecb_config_type_idx'

CREATE UNIQUE INDEX mecb_config_type_idx ON
       mecb_config_type (config_type_id)\g\qecho '        mecb_config_type_idx'
       
DROP TABLE IF EXISTS mecb_part CASCADE\g\qecho '        mecb_part'

CREATE TABLE IF NOT EXISTS mecb_part (
       part			VARCHAR,
       part_id			BIGINT UNIQUE NOT NULL DEFAULT 0, 
       ancestor_part_id		BIGINT,
       parent_part_id		BIGINT,
       part_type_id		BIGINT,
       config_id		BIGINT DEFAULT 0,
       PRIMARY KEY		(part)
);\qecho '        mecb_part'

DROP INDEX IF EXISTS mecb_part_idx\g\qecho '        mecb_part_idx'

CREATE UNIQUE INDEX mecb_part_idx ON mecb_part (part_id)\g
\qecho '        mecb_part_idx'

-- Keeps track of insert, update and removal info on the configuration.
DROP TABLE IF EXISTS mecb_config_audit\g\qecho '       mecb_config_audit'

CREATE TABLE IF NOT EXISTS mecb_config_audit (
     config_id	     		 BIGINT,
     hist_id			 INTEGER,
     action			 VARCHAR,
     transaction_date		 DATE NOT NULL DEFAULT current_date,
     transaction_time		 TIME NOT NULL DEFAULT current_time,
     cur_user			 NAME NOT NULL DEFAULT current_user,
     sess_user			  NAME NOT NULL DEFAULT session_user,
     client_add			 INET NOT NULL DEFAULT inet_client_addr(),
     client_port		 INT NOT NULL DEFAULT inet_client_port(),
     PRIMARY KEY		 (config_id, hist_id)
);\qecho '        mecb_config_audit'

-- Keeps track of insert, removal and update info on the parts.
DROP TABLE IF EXISTS mecb_part_audit\g\qecho '       mecb_config_audit'

CREATE TABLE IF NOT EXISTS mecb_part_audit (
     part_id	     		 BIGINT,
     hist_id			 INTEGER,
     action			 VARCHAR,
     transaction_date		 DATE NOT NULL DEFAULT current_date,
     transaction_time		 TIME NOT NULL DEFAULT current_time,
     cur_user			 NAME NOT NULL DEFAULT current_user,
     sess_user			  NAME NOT NULL DEFAULT session_user,
     client_add			 INET NOT NULL DEFAULT inet_client_addr(),
     client_port		 INT NOT NULL DEFAULT inet_client_port(),
     PRIMARY KEY		 (part_id, hist_id)
);\qecho '        mecb_part_audit'

-- Location data.
DROP TABLE IF EXISTS mecb_loc\g\qecho '        mecb_loc'

CREATE TABLE IF NOT EXISTS mecb_loc (
       loc		   VARCHAR,
       loc_id	    	   BIGINT,
       PRIMARY KEY	   (loc)
);\qecho '        mecb_loc'

DROP INDEX IF EXISTS mecb_loc_idx\g\qecho '        mecb_loc_idx'

CREATE UNIQUE INDEX mecb_loc_idx ON mecb_loc (loc_id)\g
\qecho '        mecb_loc_idx'

-- Cross reference parts to location.
DROP TABLE IF EXISTS mecb_part_loc\g\qecho '        mecb_part_loc'

CREATE TABLE IF NOT EXISTS mecb_part_loc (
       part_id		   BIGINT,
       loc_id	    	   BIGINT,
       loc_type_id	   BIGINT,
       PRIMARY KEY	   (part_id, loc_id)
);\qecho '        mecb_part_loc'

-- Address
DROP TABLE IF EXISTS mecb_addr_loc\g\qecho '        mecb_addr_loc'

CREATE TABLE IF NOT EXISTS mecb_addr_loc (
       loc_id	    BIGINT,
       address_id   BIGINT,
       address	    VARCHAR,
       PRIMARY KEY  (loc_id, address_id)
);\qecho '        mecb_addr_loc'

-- Contact
DROP TABLE IF EXISTS mecb_contact\g\qecho '        mecb_contact'

CREATE TABLE IF NOT EXISTS mecb_contact (
       contact	    VARCHAR,
       contact_id   INTEGER,
       PRIMARY KEY  (contact)
);\qecho '        mecb_contact'

DROP INDEX IF EXISTS mecb_contact_idx;

CREATE UNIQUE INDEX mecb_contact_idx ON mecb_contact (contact_id);

-- Location contacts.
DROP TABLE IF EXISTS mecb_contact_loc\g\qecho '        mecb_contact_loc'

CREATE TABLE IF NOT EXISTS mecb_contact_loc (
       loc_id	    BIGINT,
       contact_id   INTEGER,
       PRIMARY KEY (loc_id, contact_id)
);\qecho '        mecb_contact_loc'

-- Contact details (phone #, email, fax, etc.
DROP TABLE IF EXISTS mecb_contact_det\g\qecho '        mecb_contact_det'

CREATE TABLE IF NOT EXISTS mecb_contact_det (
       contact_id   	   BIGINT,
       det_id	    	    BIGINT,
       contact_type_id	    BIGINT,
       details		    VARCHAR,
       PRIMARY KEY (contact_id,det_id)
);\qecho '        mecb_contact_det'

/******************** Utility tables ***********************/

-- Location type
DROP TABLE IF EXISTS mecb_loc_type\g\qecho '        mecb_loc_type'

CREATE TABLE IF NOT EXISTS mecb_loc_type (
       loc_type	     VARCHAR UNIQUE NOT NULL,
       loc_type_id   BIGINT UNIQUE NOT NULL,
       description	     VARCHAR
);\qecho '        mecb_loc_type'

INSERT INTO mecb_loc_type (
       loc_type,
       loc_type_id,
       description)
VALUES (
       'LOC',
       1,
       'Part location');
       
INSERT INTO mecb_loc_type (
       loc_type,
       loc_type_id,
       description)
VALUES (
       'MAN',
       2,
       'Manufacture location');
       
-- contact details type
DROP TABLE IF EXISTS mecb_contact_det_type\g
     \qecho '        mecb_contact_det_type'
CREATE TABLE IF NOT EXISTS mecb_contact_det_type (
     contact_type_id    BIGINT UNIQUE NOT NULL,
     contact_type	VARCHAR UNIQUE NOT NULL,
     description	VARCHAR
);\qecho '      mecb_contact_det_type'


INSERT INTO mecb_contact_det_type (
       contact_type_id,
       contact_type,
       description)
VALUES (1,
       'mobile',
       'Mobile phone');

INSERT INTO mecb_contact_det_type (
       contact_type_id,
       contact_type,
       description)
VALUES (2,
       'home',
       'Home phone');

INSERT INTO mecb_contact_det_type (
       contact_type_id,
       contact_type,
       description)
VALUES (3,
       'business',
       'Business phone');

INSERT INTO mecb_contact_det_type (
       contact_type_id,
       contact_type,
       description)
VALUES (4,
       'fax',
       'Fax phone');

INSERT INTO mecb_contact_det_type (
       contact_type_id,
       contact_type,
       description)
VALUES (5,
       'ext',
       'Phone extension');

INSERT INTO mecb_contact_det_type (
       contact_type_id,
       contact_type,
       description)
VALUES (6,
       'pemail',
       'Personal email');

INSERT INTO mecb_contact_det_type (
       contact_type_id,
       contact_type,
       description)
VALUES (7,
       'bemail',
       'Business email');
