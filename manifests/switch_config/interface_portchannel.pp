define ucs::switch_config::interface_portchannel(
  $interface_name="port-channel1",
  $description="default",
  $switchport_mode="disabled",
  $vpc_id=undef,
  $vpc_peer_link=undef,
  $switchport_trunk_native_vlan="default",
  $switchport_trunk_allowed_vlan="default",
  $stp_port_type="default",
  $stp_guard="default",
){
    cisco_interface{ "${interface_name}":
        ensure                       => "present",
        shutdown                     => "false",
        description                  => $description,
        vpc_id                       => $vpc_id,
        vpc_peer_link                => $vpc_peer_link,
        switchport_mode              => $switchport_mode,
        switchport_trunk_native_vlan => $switchport_trunk_native_vlan,
        switchport_trunk_allowed_vlan=> $switchport_trunk_allowed_vlan,
        stp_port_type                => $stp_port_type,
        stp_guard                    => $stp_guard,
    }

    if ( $stp_port_type =~  "/edge trunk/") {
        cisco_interface_portchannel { "${interface_name}":
            lacp_graceful_convergence => false,
        }
    }
}
