class webserver {
  package { 'apache2': ensure => 'latest', }
  service { 'apache2':
    ensure => 'running',
    enable => true,
    require => Package['apache2'],
  }
}

class logserver {
  package { 'rsyslog': ensure => 'latest', }
  package { 'logwatch': ensure => 'latest', }
  service { 'rsyslog':
    ensure => 'running',
    enable => true,
    require => Package['rsyslog'],
  }
}

class linuxextras {
  package { 'sl': ensure => 'latest', }
  $mypackages = ['cowsay', 'fortune', 'shellcheck']
  package { $mypackages: ensure => 'latest', }
}

class hostips {
  host { 'hostvm-mgmt':
    ip           => '172.16.1.1',
    host_aliases => 'puppet',
  }
  host { 'server1-mgmt': ip => '172.16.1.10' }
  host { 'server2-mgmt': ip => '172.16.1.12' }
}
