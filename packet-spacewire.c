#include "config.h" 
#include <epan/packet.h> // Wiresharks centrale API for at lave dissesctors
#include <ctype.h>       // Til at tjekke om bytes er printable med isprint()

#define ETHERTYPE_SPACEWIRE 0x88B5 // Vores egne pakker identificeres med denne Ethertype

/* Define protocol and fields */
static int proto_spacewire = -1;              // ID for SpaceWire-protokollen
static int hf_spacewire_address = -1;         // Felt-ID for adressebyte
static int hf_spacewire_data = -1;            // Felt-ID for efterfølgende databytes

/* Tree handle */
static gint ett_spacewire = -1;               // ID til den visuelle trækstruktur i Wireshark

/* Dissector function */
static int dissect_spacewire(tvbuff_t *tvb, packet_info *pinfo, proto_tree *tree, void *data _U_) {
    col_set_str(pinfo->cinfo, COL_PROTOCOL, "SpaceWire"); // Sæt protokolnavn i Wireshark GUI
    col_clear(pinfo->cinfo, COL_INFO);                    // Udelad indhold i INFO-kolonnen i Wireshark GUI

    // Tilføj hovedprotokolobjektet til træet
    proto_item *ti = proto_tree_add_item(tree, proto_spacewire, tvb, 0, -1, ENC_NA); 
    proto_tree *spacewire_tree = proto_item_add_subtree(ti, ett_spacewire);

    gint length = tvb_captured_length(tvb); // Læs hvor lang pakken er

    // Den første byte tolkes som en adresse
    if (length >= 1) {
        guint8 address_byte = tvb_get_uint8(tvb, 0);
        char addr_str[2] = { isprint(address_byte) ? address_byte : '.', '\0' };
        proto_tree_add_string_format(spacewire_tree, hf_spacewire_address, tvb, 0, 1,
            addr_str,
            "Address: '%c' (0x%02X)", isprint(address_byte) ? address_byte : '.', address_byte);
    }

    // Resten af pakken tolkes som data (1 byte ad gangen)
    for (gint i = 1; i < length; ++i) {
        guint8 byte = tvb_get_uint8(tvb, i); // Read data byte
        char byte_str[2] = { isprint(byte) ? byte : '.', '\0' }; // Printable character string
        proto_tree_add_string_format(spacewire_tree, hf_spacewire_data, tvb, i, 1,
            byte_str,
            "Data Byte %d: '%c' (0x%02X)", i, isprint(byte) ? byte : '.', byte); // Add data byte field
    }

    return tvb_captured_length(tvb); // Fortæl Wireshark hvor mange bytes vi har brugt
}

/* Registrering af de felter vi gerne vil kunne vise og filtrere på */
void proto_register_spacewire(void) {
    static hf_register_info hf[] = {
        { &hf_spacewire_address,
            { "Address", "spacewire.address", 
            FT_STRING, BASE_NONE,
            NULL, 0x0,
            NULL, HFILL }
        },
        { &hf_spacewire_data,
            { "Data Byte", "spacewire.data",
            FT_STRING, BASE_NONE,
            NULL, 0x0,
            NULL, HFILL }
        }
    };

    static gint *ett[] = {
        &ett_spacewire // Register main protocol tree
    };

    proto_spacewire = proto_register_protocol( // Register protocol with names
        "SpaceWire",	 	  /* Fulde navn */
        "SpaceWire",              /* Kort navn til GUI */
        "spacewire"               /* Filter-navn */
    );

    proto_register_field_array(proto_spacewire, hf, array_length(hf));
    proto_register_subtree_array(ett, array_length(ett));
}

/* Dette binder protokollen til en bestemt Ethertype */
void proto_reg_handoff_spacewire(void) { 
    static dissector_handle_t spacewire_handle;

    spacewire_handle = create_dissector_handle(dissect_spacewire, proto_spacewire); // Skab handle til dissectoren

    dissector_add_uint("ethertype", ETHERTYPE_SPACEWIRE, spacewire_handle);
}

