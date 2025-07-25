node server1.home.arpa {
  include webserver
  include linuxextras
  include hostips
}

node server2.home.arpa {
  include logserver
  include linuxextras
  include hostips
}
