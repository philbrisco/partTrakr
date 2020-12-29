			PartTrakr for the Mac

PartTrakr allows a user to create and track parts and part configurations in a PostgreSQL
database.

It consists of two parts.  A backend written in SQL pprocedures which access a PostgreSQL
database and a frontend that is a user interface for the backend written in Xcode and Swift.

This was set up using homebrew's version of postgreSQL and perfect.org's setup.  Instructions
for setting this up can be found at:

    http://www.perfect.org/docs/PostgreSQL.html

After this is done, a database will need to be set up so that the PartTrakr frontend for the
Mac can use it.  The frontend will prompt the user for a database name and a password.

---------------------------------------------------

The problem with keeping track of parts or groups of parts is ensuring that if a part is
modified or moved, all of its children are also modified or moved correctly.  In
PartTrakr, this is accomplished by using a tree structure for all parts and configurations.

A configuration is a pattern that explains how parts are attached to each other, so that
parts cannot inadvertently be attached incorrectly (i.e a tire attached to an engine).

The user creates a configuration of parts out of configuration types and attaches these
configurations in a tree like structure.  This is the pattern that parts, which are are
put together, are done in accordance with the way the configuration is put together.  The
configuration is the pattern and multiple parts can use the same configuration.

For example, you can create a pattern for a type of airplane.  Multiple planes with the
same configuration could be tracked using this single pattern.

During maintenance operations, when an engine is removed from the airplane for overhaul,
it is very simple to remove the engine from the database and assign it to the place
that is doing the overhaul.  All of the children parts with the engine are also transferred
at the same time.  This is accomplished by a single calling a postgreSQL procedure
(api_part_upd) with the name of the part to be moved and the parent that it is to be
moved to.

The procedure checks to ensure that the new parent is valid before making the transfer.
If everything checks out, the part is transferred without any further ado.  If there is
a problem, an appropriate error message is displayed.

------------------------------------------------------

The Mac frontend is a quick and dirty program which works very well, but was written more
for testing the backend than to provide an elegant and comfortable experience for the
end user.

Hopefully, that will change as time goes on.  Currently, the plan is to upload all
source software for the program along with the storyboard.  Hopefully, it won't be too
difficult to import the storyboard into your project.  Ultimately, it is to be hoped that
a turnkey system can be built that merely requires opening a DMG file.

------------------------------------------------------

When the program is first run, a splash screen is displayed (which is also the about
screen) giving a brief blurb about the program and current state of development.  Clicking
anywhere (or hitting any key,for that matter) on the screen will cause the splash screen
to disappear.  Opening access to the database you've created requires either using the
menu File->Open or command-O to bring up the alert to enter in the database name.  For
the time being there is no password required as it is assumed that the users will have
the appropriate privileges to access the database without one.  I know this is untenable
but the plans are to change this in the near future to provide more security.

in the File menu, there are a number of other menuitems other than 'close'.  Under
File->New, there are currently three menuitems.  These are listed in the order that they
should be used.

File->New->Part Type:
	Allows a user to easily create a new part type.  This is designed to cover a class
	of parts rather than individual parts.  For example, you might define a part type
	as 'Nutty Chocolates'.  Then various manufacturers of nutty chocolates would have
	their appropriate chocolates classified as this part type.  As you see, there can
	be quite a large amount of different parts from different manufacturers meeting
	this specification.

File->New-Config Type:
	Creates a new configuration type and assigns it a part type created in the previous
	step.  The part type and the configuration type are 1 to 1, so there can never be
	more than one configuration type with the same part type.  The same is also true in
	reverse, there can never be more that one part type for each configuratin type.
	Configuration types are used in configurations to let parts know what their
	parent/child relationship with other parts ar.

File->New->Part Configuration:
	This one is actually done after parts have been created and given a part type.
	Before a part can be used in this system, it has to be assigned a configuration.
	The configuration lets the part know how the parts can be attached to each other.

Under File->Utilities are a number of menuitems that are not generally used or are not as
important so some of the day-to-day procedures.

File->Utilities->Configuration List:
	Lists the configuration selected and all of its progeny is a tree-like format.
	There are two formats: Indented and Arrow.  Indented gives a space-indented
	list where each space before a configuration indicates the location in the
	hierarchy that a configuration is.  As an example, if a configuration is indented
	by one more space that the configuration that precedes it, that configuration is
	a child of the preceeding one  In the case of an arrow listing, the entire tree
	of the branch to that poit is listed with arrow separating each configuration.

Part->Utilities->Part List:
	The same thing as the configuration list, but with parts instead of configurations.

Part->Utilities->Maintenance Type:
	Allows for the creation of types of maintenance which can be used when creating
	mainenance actions.

Part->Utilities->Locations:
	Allows users to create locations which can be assigned to parts and contacts.

Part->Utilities->Address Location:
	Creates addresses for locations.  As many address lines per location as desired
	can be entered.

Part->Utilities->Contact:
	Creates new contacts.

Part->Utilities->Contact Locations:
	Creates locations for contacts.  A contact can have multiple locations

Part->Utilities->Contact Detail:
	Creates detail informatin (phone, email, etc.) for a contact.  The detail types
	are currently not editable.

The menuitems under Part->Edit are the work houses of the PartTrakr system.  These items
are used to keep the parts up to date.

Part->Edit->Configutation:
	Creates individual configurations, assign them a configuration type  and places
	them in a parent/child relationship with other configurations.

Part->Edit->Part:
	Creates parts, assigns them a part type and places them in a parent/child
	relatioship with their fellow parts.

Part->Edit->History:
	Creates a history record of a maintenance action for a part.

Part->Edit->Part Location:
	Associates a part with a given location.

Part->Edit->Maintenance:
	Creates a maintenance action that is usually in the future.  Designed to schedule
	maintenance.

----------------------------------------------------------

The general order of accomplishing the main tasks are:

1.  	    File->New->Part Type
2.  	    File->New-Config Type
3/4.	    Part->Edit->Configutation
3/4.	    Part->Edit->Part
5.	    File->New->Part Configuration
6.	    Part->Edit->Part

These are the core routines which make the updates to the parts possible.

---------------------------------------------------------

While a part generally is attached to another part, when it is first created, it is
attached to itself, which makesit a top level part.  In eacn part tree there is
one top-level part.  To remove a part from a tree without attaching it to another tree,
the part is simply attached to itself, which makes it a top-level part as it has
no parent.  This comes in handy when a part is removed temporarily or sent to a nearby
location for maintenance

The same is also true of configurations, although a configuration cannot be removed if
there are parts attached to it.

---------------------------------------------------------
Version 1.0
Written by Phillip Brisco
