			      PartTrakr

Legal:
	This project is distributed under the Creative Commons license.

Version:
	1.2.3
	12/05/2020	Phillip Brisco
	Fixed a bug that would delete a part type even if a part was using it.

	Added a check to handle blank input in:
	      api_config_type_del
	      api_config_ins
	      api_config_upd
	      api_config_del
	      api_config_rem
	      api_part_ins
	      api_part_config_upd
	      api_part_del

	Fixed a bug in api_config_rem that was seeing parts connected to a
	configuration when no parts were actually connected.

	Fixed a bug in api_contact_loc_ins where it was monotonically
	increasing the contact id when it should have been using the entered
	contact id.
	
	Added the ability to either only disassociate a contact from one
	location or disassociate a contact from all locations
	(api_contact_loc_del).

	Disabled the configuration and part audit features as they are not
	very necessary to the project and they have a huge performance hit.
	
	1.2.1
	12/4/2020	Phillip Brisco
	Fixed a bug in api_part_config_upd that allowed a part that was not
	standalone to be reconfigured.

	Added slots to api_mecb_config_ins since implicitly deriving slots
	was giving ambiguous results.  Now we know exactly how many parts a
	configuration can handle for a given tree.

	Changed the mecb_part_audit table so that all records > 7 days old are
	deleted (This table can get huge fast in the normal course of use).
	These records are not critical and just provide an audit trail of
	updates made to the parts.

	Fixed the search for the part name, location name and location type to
	be case insensitive in api_part_loc_ins.

	Fixed the search for the part and location names to be case insensitive
	for api_part_loc_ins.
	
	1.2
	12/2/2020	Phillip Brisco
	The configuration of a part could be changed automatically when it
	was added to a part tree.  Changed this so that an error is thrown
	instead, unless the user also enters the new configuration of the
	part.

	Fixed some error numbers that were incorrect.

	Added some maintenance subsystem stuff (api_maint_type_ins,
	api_maint_type_upd, api_maint_type_del, api_sched_maint_ins,
	api_sched_maint_del and api_maint_hist_ins).

	Took away the ability for api_part_upd to change the configuration of
	a given part as the results could be ambiguous since a given part in
	a tree could have multiple children.
	
	1.1
	12/1/2020	Phillip Brisco
	Created procedures api_config_list and api_part_list which give a
	hierarchical list of a selected configuration or part and all of its
	progeny;
	
	1.0	(the pandemc build)
	11/30/2020
	Conceived, designed and written by Phillip Brisco
	
Summary:

	This is a backend for tracking parts.  It allows for the hierarchical
	association of parts into a tree structure which can then be associated
	with any valid parent.

	This is accomplished by setting up a configuration (or pattern) on how
	parts should be organized and their relationships to each other.

	This is written entirely in SQL using procedures, functions and
	triggers.

Setup:
	This distribution currently consists of two files, mecb_tables.sql and
	mecb_procs.sql.

	They are both written to use the plpgsql language.  After creating a
	database, the user will need to run each of these in succession.  One
	way of doing this is to enter the command line of plgp and type in
	'\i mecb_tables.sql' followed by '\i mecb_procs.sql'.  This will set up
	the backend database for access by a user-created front end.

	I will eventually write a front end for this project and originally I
	wasn't going to release it without one, but decided that since the main
	focus is the backend, to go ahead and release it for the nonce.

	This allows the user to create their own front end that should be rather
	trivial as it will need to call the api in order to update the
	database.

Notes:
	This version allows users to create configurations (or patterns),
	associate parts in a tree-like structure based on said patterns, create
	parts and associate them with part types, create locations, contacts
	and contact details.

	There is much more to be done (maintenance, cost, etc.) which I will be
	releasing over time.

Conventions:
	The programming conventions for the procedures in this backend are:

	table names always have mecb_ prepended to them for easy identification.
	
	Underscores are used to begin local variables.
	
	The errors currently have an error number assigned to them for
	easy access in the code to where the error occurred.  This is a 5
	digit number that is monotonically increasing by 100 for each new
	procedure.

	The error messages themselves have no hard and fast conventions but
	should be descriptive, brief and to the poine.

	All modificatons to the database should be done only through those
	procedures and functions which begin with 'api_'.  Modifying the
	tables directly can be dangerous as there are several with triggers
	on them which can cause unexpected consequences.  Also, the procedures
	have extensive error check to ensure that the data being modified is
	correct.

	For the string parameters being passed to procedures and functions, I
	check for null as well as length out of an abundance of caution.  This
	probably doesn't need to be done like this, but oh well.

Programming Interface:
	api_config_ins
	api_config_upd
	api_config_rem
	api_config_del

	api_config_type_ins
	api_config_type_del

	api_part_type_ins
	api_part_type_del

	api_part_ins
	api_part_upd
	api_part_rem
	api_part_del

	api_part_config_upd

	api_loc_ins
	api_loc_upd
	api_loc_del

	api_part_loc_ins
	api_part_loc_del

	api_addr_loc_ins
	api_addr_loc_upd

	api_contact_ins
	api_contact_upd
	api_contact_del

	api_contact_loc_ins
	api_contact_loc_del

	api_contact_det_ins
	api_contact_det_upd
	api_contact_det_del

	api_maint_type_ins
	api_maint_type_upd
	api_maint_type_del

	api_sched_maint_ins
	api_sched_maint_del

	api_config_list
	api_part_list
	
	Additionally, two tables are currently used as utility tables to
	support the database.  The first is the mecb_loc_type table which is
	used to hold the types of locations.  These are curently 3-letter
	mnemonics used to indicate location types:
	
		  LOC  location of the part
		  MAN  location of the manufacture of the part

	The second table is mecb_contact_det_type which is used to hold the
	detail types for the contact:

	          mobile     mobile phone
		  home	     home phone
		  business   business phone
		  fax	     fax number
		  ext	     extension
		  pemail     personal email
		  bemail     business email
Tables:

	mecb_config		Configuration pattern
	mecb_part_type		Part type table
	mecb_config_type	Configuration type table
	mecb_part		Part table
	mecb_config_audit	Keeps track of changes made to mecb_config
	mecb_part_audit		Keeps track of changes made to mecb_part
	mecb_loc		Location
	mecb_part_loc		Part location
	mecb_addr_loc		Location address
	mecb_contact		Contact
	mecb_contact_loc	Location contact
	mecb_contact_det	Contact detail (phone, fax, email, etc.)
	mec_sched_maint		Scheduled maintenance action
	mecb_loc_type		Location types
	mecb_contact_det_type	Contact detail type
	mecb_maint_type		Maintenance type
	mecb_maint_hist		Maintenance history for the part
	
	mecb_config_tmp		Temporary table holds configuration list tree.
	mecb_part_tmp		Temporary table holds the part list tree.
	
Order of Execution:

	The first thing that needs to be done is to create a part type and
	associate it with a configuration type.  Configurations need to be
	created and arranged in a hierarchical manner.  Parts next need to be
	created and associated with a configuration.  Lastly, the parts need
	to be arranged in a hierarchical manner.  Executing the following
	routines in order will create a configuration and it's associated part.

	api_part_type_ins   		  Creates a part type
	api_config_type_ins		  Creates a configuration type
					  and associates it with a part type
	api_config_ins			  Creates a configuration
	api_config_upd			  Arranges configurations in a tree
					  structure
	api_part_ins			  Creates a part
	api_part_config_upd		  Associates a part with a configuration
	api_part_upd			  Arranges parts into a tree structure.

What the core APIs do:

	API_PART_TYPE_INS has 1 parameter which is the name of a part type
	that is created by this procedure.  A part type is a unique string of
	characters that is used to identify the type of a part as opposed to
	the actual part itself.  When a part is created it is assigned a part
	type.

	API_PART_TYPE_DEL has 1 parameter which is the name of the part type
	to delete.  It will only delete the part type if there are no parts
	using ig.

	API_CONFIG_TYPE_INS has 2 parameters, a configuration type and a part
	type which is to be associated with the configuration type.  The part
	type has to already exist in the mecb_part_type table for the new
	association to occur.

	API_CONFIG_TYPE_DEL has 1 parameter, the configuration type to delete.
	The procedure ensures that the type is deleted only if there are no
	configurations using it.

	API_CONFIG_INS has 3 parameters, the name of the configuration which is
	to be associated with a configuration type created with the
	api_config_type_ins procedure, the configuration type and an optional
	number of configuration slots.  The slot is tell how many parts can be
	connected to the same tree using this configuration.  The default is 1.

	API_CONFIG_UPD has 2 parameters, the name of a new parent and the name
	of the child.  They both must already exist.  This will make the child
	the child of the parent as long as it is valid to do so (configuration
	can't be children of each other and configurations with the same types
	cannot be in the same direct tree).  Associating a configuration with
	itself, removes it from the current configuration tree (if it has a
	parent) and makes it a top level part.  No configuration can be moved
	once parts are attached to it (in this case, all parts have to be
	removed first).

	API_CONFIG_REM has one parameter, the configuration.  This will remove
	a configuration and all of its progeny from a tree, thus making each
	configuration a top-level one.  This cannot be used if parts are
	associated with a configuration.

	API_CONFIG_DEL has one parameter, the configuration.  It deletes the
	current configuration and all of its progeny.  It only does this if no
	parts are associated with the configuration.

	API_PART_INS has 2 parameters, the new part name which is to be
	associated with an existing part type.

	API_PART_CONFIG_UPD has 2 parameters, the name of the part and the
	name of the configuration it is to be associated with.  This
	association must take place to initialize the part's configuration.
	The part can be reconfigured to a different configuration that has the
	same configuration type, but can only be done if it is a stand alone
	part with no parents and no children.  So for a tree of parts to be
	reconfigured, first they all have to be made top-level parts,
	reconfigured individually, then put back together.  Somewhat of a pain,
	true, but necessary so as not to break the configuration pattern.  If
	multiple parts are the same type, it is probably best to make them all
	of the same configuration.

	API_PART_UPD has 2 paramters, the name of the new parent and the name
	of the child to be attached to the parent.  Both parts must already
	exist and be configured.  The parts are attached to each other via the ]
	rules set down in their configurations.

	API_PART_REM has 1 parameter, the part name.  It removes the part and
	its progeny from each other, making each part a top-level part.  It
	keeps the configuration of each part though.

	API_PART_DEL has 1 parameter, the part name.  It deletes a part and all
	of its progeny.  It also deletes all associated rows in the tables
	mecb_maint_history and mecb_sched_maint.

Location APIs:

	 These APis handle creating, updating and deleting locations and
	 associating them with parts.
	 
	api_loc_ins		Creates a new location
	api_loc_upd		Edits an existing location
	api_loc_del		Deletes an existing location

	api_part_loc_ins	Associates a part with a location
	api_part_loc_del	Disassociates a part from a location

        api_addr_loc_ins	Inserts new address and associates it with a
				location.
	api_addr_loc_del	Deletes all addresses associated with a
				location.

	API_LOC_INS has 1 paramete, the name of a new location which this
	procedure uses to create a new location.

	API_LOC_UPD has 2 parameters, the current name of a location, and the
	name it is to be changed to.

	API_LOC_DEL has 1 parameter, the name of a location to be deleted.  The
	location can only be deleted if parts are not using it.

	API_PART_LOC_INS  has 3 parameters, the existing name of a part, the
	existing name of a location and a valid location type.

	API_PART_LOC_DEL has 2 parameters, the name of an existing part and
	the name of an existing location that it is to be disassociated from.

	API_ADDR_LOC_INS has 2 parameters, an existing location name and a new
	address line.  Multiple address lines can be created for the location.

	API_ADDR_LOC_DEL has 1 parameter, the location name.  This will delete
	all addresses associated with this location.

Contact APIs:

	These APIs create and handle contacts, contact locations, addresses
	and contact details (phone, fax, email, etc.).
 
	api_contact_ins	    	    Creates a new contact
	api_contact_upd		    Edits an existing contact
	api_contact_del		    Deletes an existing contact

	api_contact_loc_ins	    Associates a contact with a location
	api_contact_loc_del	    Disassociates a contact from either a
				    location or all locations.

	api_contact_det_ins	    Inserts contact detail info
	api_contact_det_upd	    Edits contact detail info
	api_contact_det_del	    Deletes contact detail info

	API_CONTACT_INS has 1 parameter, the contact name which is used to
	create a new unique contact.

	API_CONTACT_UPD has 2 parameters, the current contact name and the new
	one.  The current must already exist and will be replaced with the new
	name.

	API_CONTACT_DEL	has 1 parameter, the contact name to be deleted.  If a
	part is associated with a contact, the contact won't be deleted.

	API_CONTACT_LOC_INS has 2 parameters, the contact name and the location
	name.  This associates an existing contact with an existing location.

	API_CONTACT_LOC_DEL has 2 parameters, the contact name and an optional
	location. Entering a location will disassociate the contact from that
	location, otherwise the contact will be disassociated from all
	locations.

	API_CONTACT_DET_INS has 3 parameters, an existing contact name, an
	existing contact type and the contact detail (phone, ext, email, etc.)
	info.

	API_CONTACT_DET_UPD has 3 parameters, the existing contact name, the
	contact type and the stuff to replace the current detail info.

	API_CONTACT_DET_DEL has 2 parameters, the existing contact name and the
	optional contact type.  If the contact type is not given, then all
	detail for contact is deleted, otherwise only the detail for the
	chosen type is deleted.

Maintenance APIs (1.2):

	    API_MAINT_TYPE_INS has 1 parameter, a new maintenance type to be
	    created. This is a unique value.

	    API_MAINT_TYPE_UPD has 2 parameters, the current maintenance type
	    value, and the value that is to replace it.  The new value is
	    checked first to ensure that it doesn't already exist.

	    API_MAINT_TYPE_DEL has 1 parameter, the maintenance type.  This
	    will be deleted if it is not being used by a maintenance action.

	    API_SCHED_MAINT_INS has 4 parameters, the part name, the maintenance
	    type, the scheduled begin date and the scheduled end date.  This
	    creates a new maintenance action.

	    API_SCHED_MAINT_DEL has 2 parameters, the part name and the
	    maintenance type.  This will delete a specific maintenance action.

	    API_MAINT_HIST_INS has 4 parameters, the part name, the maintenance
	    type, the date the action took place for the maintenance action and
	    the remarks about the action.  All parameters are required.
	    
List APis (1.1):

     API_CONFIG_LIST has 5 parameters, only 2 of which are needed by the user.
     The c_name parameter is the name of the configuration tree to list and
     the indent_type gives the type of list returned (true = indented list,
     false = arrow list).  True is the default, so the user has the option of
     only entering the configuration name, if so desired.  Tbis routine creates
     and inserts the output into the mecb_config_tmp table, which is dropped
     after the transacton is committed.  Therefore, in order to access this
     table, it will have to be done within a transaction (BEGIN TRANSACTION
     statement).  Executing the COMMIT statement will drop the table.

     API_PART_LIST is the sister procedure for the api_config_list procedure.
     It essentially does everything for the parts that the api_config_list
     procedure does for the configurations.  Its temporary table is
     mecb_part_tmp.  The result tree is in the tmp_name column (for both
     tables).  The results can be ordered by the tmp_id column.
     
To Do:

	A maintenance subsystem that includes the maintenance and history of
	individual parts.

	A cost system that gives the cost in hours and money.  This shoud also
	be tied to the maintenance subsystem so that the cost of maintenance
	is easily derived.

	Writing sample queries to show how to obtain information from the
	database.

	Security system to allow different levels of privileges to access
	different functionality.

	Front ends for various platforms need to be written.
	
