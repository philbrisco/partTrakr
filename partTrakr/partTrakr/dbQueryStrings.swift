//
//  dbQueryStrings.swift
//  partTrakr
//
//  Created by Phillip Brisco on 12/17/20.
//

import Foundation

// Returns query string fo find all queries that can be reconfigured.
func partConfigVC_partsCan () -> String {
    let dbQuery =
        "SELECT " +
        "    a.part " +
        "FROM " +
        "    mecb_part        a " +
        "WHERE " +
        "       a.parent_part_id    = a.part_id " +
        "AND    a.part_id not in " +
        "       (SELECT " +
        "           b.part_id " +
        "       FROM " +
        "           mecb_part    b, " +
        "           mecb_part    c " +
        "       WHERE " +
        "           c.parent_part_id    = b.part_id " +
        "       AND    c.part_id        != b.part_id); "

    return dbQuery
}

// Returns the current configuration for a part.
func partConfigVC_configField (part: String) -> String {
    let dbQuery =
        "SELECT " +
        "   b.config " +
        "FROM " +
        "   mecb_part   a, " +
        "   mecb_config b " +
        "WHERE " +
        "       a.part      = '\(part)' " +
        "AND    b.config_id = a.config_id "

        return dbQuery
}

// Returns all valid configurations for a given part.
func partConfigVC_allConfigs (part: String) -> String {
    let dbQuery =
        "SELECT " +
        "    c.config " +
        "FROM " +
        "    mecb_part        a, " +
        "    mecb_config_type    b, " +
        "    mecb_config        c " +
        "WHERE " +
            "    a.part            = '\(part)' " +
        "AND    b.part_type_id        = a.part_type_id " +
        "AND    c.config_type_id    = b.config_type_id; "
    
    return dbQuery
}

// Returns the part type for a given part.
func partVC_partType (part: String) -> String {
    let dbQuery =
        "SELECT " +
        "   b.part_type, " +
        "   c.config_type " +
        "FROM " +
        "   mecb_part a, " +
        "   mecb_part_type b, " +
        "   mecb_config_type c " +
        "WHERE " +
        "       a.part          = '\(part)' " +
        "AND    b.part_type_id  = a.part_type_id " +
        "AND    c.part_type_id  = b.part_type_id "

    return dbQuery
}

// Returns the configuration type for the current configuration.
func configVC_configType (config: String) -> String {
    let dbQuery =
        "SELECT " +
        "   b.config_type " +
        "FROM " +
        "   mecb_config      a, " +
        "   mecb_config_type b " +
        "WHERE " +
        "       a.config            = '\(config)' " +
        "AND    b.config_type_id    = a.config_type_id "
    
    return dbQuery
}

// Returns all parts which are associated with maintenance
func maintTypeVC_part (maint_type: String) -> String {
        let dbQuery =
            "SELECT " +
            "   c.part " +
            "FROM " +
            "   mecb_maint_type     a, " +
            "   mecb_sched_maint    b, " +
            "   mecb_part           c " +
            "WHERE " +
            "       a.maint_type        = '\(maint_type)' " +
            "AND    b.maint_type_id     = a.maint_type_id " +
            "AND    c.part_id           = b.part_id"
    
        return dbQuery
}

// Returns all history items for a part.
func histVC_maint (part: String) -> String {
    let dbQuery =
        "SELECT " +
        "   b.maint " +
        "FROM " +
        "   mecb_part a, " +
        "   mecb_maint_hist b " +
        "WHERE " +
        "       a.part      = '\(part)' " +
        "AND    b.part_id   = a.part_id "
    
        return dbQuery
}

// Returns the config_type for an associated part_type.
func partVC_configType (part_type: String) -> String {
    let dbQuery =
        "SELECT " +
        "      b.config_type " +
        "FROM " +
        "       mecb_part_type      a, " +
        "       mecb_config_type    b " +
        "WHERE " +
        "       a.part_type         = '\(part_type)' " +
        "AND    b.part_type_id      = a.part_type_id "
    
        return dbQuery
}

func partLocVC_loc (part: String, locType: String) -> String {
    let dbQuery =
        "SELECT " +
        "    d.loc " +
        "FROM " +
        "   mecb_part        a, " +
        "   mecb_part_loc    b, " +
        "   mecb_loc_type    c, " +
        "   mecb_loc         d " +
        "WHERE " +
        "   a.part         = '\(part)' " +
        "AND    b.part_id        = a.part_id " +
        "AND    c.loc_type_id    = b.loc_type_id " +
        "AND    c.loc_type       = '\(locType)' " +
        "AND    d.loc_id     = b.loc_id "

    return dbQuery
}

// Returns the addresses for a location.
func addrLocVC_addr (location: String) -> String {
    let dbQuery =
        "SELECT " +
        "   b.address " +
        "FROM " +
        "   mecb_loc        a, " +
        "   mecb_addr_loc   b " +
        "WHERE " +
        "       a.loc       = '\(location)' " +
        "AND    b.loc_id    = a.loc_id "
    
    return dbQuery
}

// Returns the locations for a contact.
func contactLocVC_loc (contact: String) -> String{
    let dbQuery =
        "SELECT " +
        "   c.loc " +
        "FROM " +
        "   mecb_contact        a, " +
        "   mecb_contact_loc    b, " +
        "   mecb_loc            c " +
        "WHERE " +
        "       a.contact       = '\(contact)' " +
        "AND    b.contact_id    = a.contact_id " +
        "AND    c.loc_id        = b.loc_id "
    
    return dbQuery
}

// Returns the details for a contact.
func contactDetVC_det (contact: String) -> String {
    let dbQuery =
        "SELECT " +
        "   c.description, " +
        "   b.details " +
        "FROM " +
        "   mecb_contact            a, " +
        "   mecb_contact_det        b, " +
        "   mecb_contact_det_type   c " +
        "WHERE " +
        "       a.contact           = '\(contact)' " +
        "AND    b.contact_id        = a.contact_id " +
        "AND    c.contact_type_id   = b.contact_type_id " +
        "ORDER BY " +
        "   c.contact_type_id"
    
    return dbQuery
}

// Returns the part type for a given config type
func configTypeVC_partType (configType: String) -> String {
    let dbQuery =
        "SELECT " +
        "   b.part_type " +
        "FROM " +
        "   mecb_config_type    a, " +
        "   mecb_part_type      b " +
        "WHERE " +
        "       a.config_type   = '\(configType)' " +
        "AND    b.part_type_id  = a.part_type_id "
    
    return dbQuery
}
