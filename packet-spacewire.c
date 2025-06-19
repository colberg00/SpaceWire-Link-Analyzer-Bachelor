#include "config.h" 
#include <epan/packet.h> // Core wireshark dissector API
#include <ctype.h>       // For isprint()
#define ETHERTYPE_SPACEWIRE 0x88B5 // Custom unreserved ethertype

/* Define protocol and fields */
static int proto_spacewire = -1;              // Protocol handle/ID
static int hf_spacewire_address = -1;         // Address field handle
static int hf_spacewire_data = -1;            // Data field handle

/* Tree handle */
static gint ett_spacewire = -1;               // Handle for the main protocol tree

/* Dissector function */
static int dissect_spacewire(tvbuff_t *tvb, packet_info *pinfo, proto_tree *tree, void *data _U_) {
    col_set_str(pinfo->cinfo, COL_PROTOCOL, "SpaceWire"); // Set protocol column to SpaceWire
    col_clear(pinfo->cinfo, COL_INFO);                    // Clear info column

    proto_item *ti = proto_tree_add_item(tree, proto_spacewire, tvb, 0, -1, ENC_NA); // Add protocol item to the tree
    proto_tree *spacewire_tree = proto_item_add_subtree(ti, ett_spacewire);         // Create a subtree for SpaceWire

    gint length = tvb_captured_length(tvb); // Get total length of the packet

    // Address byte (first byte)
    if (length >= 1) {
        guint8 address_byte = tvb_get_uint8(tvb, 0); // Read the first byte as the address
        char addr_str[2] = { isprint(address_byte) ? address_byte : '.', '\0' }; // Printable address string
        proto_tree_add_string_format(spacewire_tree, hf_spacewire_address, tvb, 0, 1,
            addr_str,
            "Address: '%c' (0x%02X)", isprint(address_byte) ? address_byte : '.', address_byte); // Add address field
    }

    // Remaining data bytes
    for (gint i = 1; i < length; ++i) {
        guint8 byte = tvb_get_uint8(tvb, i); // Read data byte
        char byte_str[2] = { isprint(byte) ? byte : '.', '\0' }; // Printable character string
        proto_tree_add_string_format(spacewire_tree, hf_spacewire_data, tvb, i, 1,
            byte_str,
            "Data Byte %d: '%c' (0x%02X)", i, isprint(byte) ? byte : '.', byte); // Add data byte field
    }

    return tvb_captured_length(tvb); // Return number of bytes consumed
}

/* Protocol registration */
void proto_register_spacewire(void) {
    static hf_register_info hf[] = {
        { &hf_spacewire_address, // Field info for address
            { "Address", "spacewire.address", // Display name and filter name
            FT_STRING, BASE_NONE,             // ASCII string format
            NULL, 0x0,
            NULL, HFILL }
        },
        { &hf_spacewire_data, // Field info for data bytes
            { "Data Byte", "spacewire.data", // Display name and filter name
            FT_STRING, BASE_NONE,            // ASCII string format
            NULL, 0x0,
            NULL, HFILL }
        }
    };

    static gint *ett[] = {
        &ett_spacewire // Register main protocol tree
    };

    proto_spacewire = proto_register_protocol( // Register protocol with names
        "SpaceWire",	 	  /* Name */
        "SpaceWire",              /* Short name */
        "spacewire"               /* Filter name */
    );

    proto_register_field_array(proto_spacewire, hf, array_length(hf)); // Register field handles
    proto_register_subtree_array(ett, array_length(ett));              // Register tree handles
}

/* Protocol handoff */
void proto_reg_handoff_spacewire(void) { // Hooks dissector into decoding stack
    static dissector_handle_t spacewire_handle;

    spacewire_handle = create_dissector_handle(dissect_spacewire, proto_spacewire); // Create dissector handle

    dissector_add_uint("ethertype", ETHERTYPE_SPACEWIRE, spacewire_handle); // Add dissector with custom ethertype
}

