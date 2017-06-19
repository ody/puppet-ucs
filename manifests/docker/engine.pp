class docker_ee_cvd::docker::engine(
 $version           = 1.12,
 $docker_public_key = 'https://sks-keyservers.net/pks/lookup?op=get&search=0xee6d536cf7dc86e2d7d56f59a178ac6c6238f52e'
){

  $os_version   = $facts['os']['release']['major']
  $tcp_fw_ports = [
    80, 443, 2375, 2376, 2377, 4789, 7946,
    12376, 12379, 12380, 12381, 12382, 12383,
    12384, 12385, 12386, 12387, 19002, 8443
  ]
  $udp_fw_ports = [ 4789, 7946 ]

  # No reason to manually implement the management of NTP here, use the
  # Puppet module.  TBH doing anything else it likely to cause people
  # a good amount of annoyance since it would likely cause resource
  # conflicts because they are very likely to already be managing NTP
  # this way.[1]
  #
  # [1] https://forge.puppet.com/puppetlabs/ntp
  include ntp

  $tcp_fw_ports.each |Integer $tport| {
    firewalld_port { "Open tport ${tport} in the public Zone":
      ensure   => present,
      zone     => 'public',
      port     => $tport,
      protocol => 'tcp',
    }
  }

  $udp_fw_ports.each |Integer $uport| {
    firewalld_port { "Open uport ${uport} in the public Zone":
      ensure   => present,
      zone     => 'public',
      port     => $uport,
      protocol => 'udp',
    }
  }

  # It is highly unlikely that firewalld needs to be restarted after adding
  # rules.  In the event it does than this exec needs to be set refreshonly[1]
  # or it will restart firewalld on every run of Puppet, which is rather
  # inappropriate.  To make sure this works as intended, explicity
  # relationships should also be defined.[2]
  #
  # [1] https://docs.puppet.com/puppet/latest/types/exec.html#exec-attribute-refreshonly
  # [2] https://docs.puppet.com/puppet/4.10/lang_relationships.html#syntax-relationship-metaparameters
  #
  exec { 'firewalld-restart':
    command => 'service firewalld restart',
    path    => ['/usr/bin', '/usr/sbin']
  }

  # This should probably be removed because garethr/docker explicitly
  # requests it be installed.[1]
  #
  # [1] https://github.com/garethr/garethr-docker/blob/257c0d8d000677fd886ff18b2648c238c71a5318/manifests/repos.pp#L69-L74
  #
  package { 'epel-release': ensure => absent }

  # Likely not a requirement, yum refreshes caches every time it goes to
  # install a package
  exec { 'database-cleanup':
    command => 'yum clean all',
    path    => ['/usr/bin', '/usr/sbin']
  }

  # If Puppet works, this package should not be required or is already
  # installed
  package {'yum-utils':
    ensure => present
  }

  # All repo setup should be handled by the garehtr/docker module
  exec { 'Docker-public-key':
    command => "rpm --import ${docker_public_key}",
    path    => ['/usr/bin', '/usr/sbin']
  }

  # All repo setup should be handled by the garehtr/docker module.
  yumrepo { "dockerrepo":
    baseurl  => "https://packages.docker.com/${version}/yum/repo/main/centos/${os_version}",
    descr    => "Docker Repo",
    enabled  => 1,
    gpgcheck => 0,
  }

  # Super pointless, does nothing in a Puppet context
  exec { 'yum-repolist':
    command => 'yum repolist',
    path    => ['/usr/bin', '/usr/sbin']
  }

  # This all that should be required for getting docker engine on the host[1][2]
  #
  # [1] https://github.com/garethr/garethr-docker/blob/master/manifests/init.pp#L521
  # [2] https://github.com/garethr/garethr-docker/blob/master/manifests/repos.pp#L11
  #
  class { 'docker': docker_cs => true }
}
