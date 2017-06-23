class docker_ee_cvd::docker::engine(
  # Docker UCP is a containerized application that requires Docker CS Engine 1.13.0 or above to run
  #
  $version           = 1.13,
  $docker_public_key = "https://sks-keyservers.net/pks/lookup?op=get&search=0xee6d536cf7dc86e2d7d56f59a178ac6c6238f52e"
 ){

    $os_version   = $facts['os']['release']['major']

    # Docker Datacenter requires some TCP and UDP ports to be opened
    # to facilitate communication between its container infrastructure
    # services running on cluster nodes.
    # TCP 443 for Web app and CLI client access to UCP.
    # TCP 2375 for Heartbeat for nodes, to ensure they are running.
    # TCP 2377 used by ucp controller replica
    # TCP 2376 for Swarm manager accepts requests from UCP controller.
    # TCP + UDP for 4789 Overlay networking.
    # TCP + UDP for 7946 Overlay networking.
    # TCP 12376 for Proxy for TLS, provides access to UCP, Swarm, and Engine.
    # TCP 12379 for Internal node configuration, cluster configuration, and HA.
    # TCP 12380 for Internal node configuration, cluster configuration, and HA.
    # TCP 12381 for Proxy for TLS, provides access to UCP.
    # TCP 12382 to Manages TLS and requests from swarm manager.
    # TCP 12383 Used by the authentication storage backend.
    # TCP 12384 Used by authentication storage backend for replication across controllers.
    # TCP 12385 The port where the authentication API is exposed.
    # TCP 12386 Used by the authentication worker.
    # TCP 12387 Used by the authentication worker. 
    # TCP 19002 for ucp controller port
    #
    $tcp_fw_ports = [
      80, 443, 2375, 2376, 2377, 4789, 7946,
      12376, 12379, 12380, 12381, 12382, 12383,
      12384, 12385, 12386, 12387, 19002
    ]
    $udp_fw_ports=[4789,7946]
  
    # Docker Datacenter requires nodes participating in the cluster
    # to have their system time be in sync with the external source.
    # We do this by installing NTP services and configuring it to
    # remain in sync with the system time 
    #
    include '::ntp'

    class { 'firewalld': }

    $tcp_fw_ports.each |Integer $tport| {
      firewalld_port { "Open tport ${tport} in the public Zone":
        ensure   => 'present',
        zone     => 'public',
        port     => "${tport}",
        protocol => 'tcp',
        }
    } 

    $udp_fw_ports.each |Integer $uport| {
      firewalld_port { "Open uport ${uport} in the public Zone":
        ensure   => 'present',
        zone     => 'public',
        port     => "${uport}",
        protocol => 'udp',
        }
    }

    #Working on this will remove once fixed
    #
    exec { 'Docker-public-key':
      command => "rpm --import ${docker_public_key}",
      path    => ['/usr/bin', '/usr/sbin']
    }

    #Working on this will remove once fixed
    #
    yumrepo { "dockerrepo":
      baseurl  => "https://packages.docker.com/${version}/yum/repo/main/centos/${os_version}",
      descr    => "Docker Repo",
      enabled  => 1,
      gpgcheck => 0,
    }

    class { 'docker':
      docker_cs      => true,
      storage_driver => 'devicemapper'
    }
}
