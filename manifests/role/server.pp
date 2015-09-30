class dynatrace::role::server (
  $ensure                  = 'present',
  $role_name               = 'Dynatrace Server',
  $version                 = $dynatrace::version,
  $installer_prefix_dir    = $dynatrace::server_installer_prefix_dir,
  $installer_file_name     = $dynatrace::server_installer_file_name,
  $installer_file_url      = $dynatrace::server_installer_file_url,
  $license_file_name       = $dynatrace::server_license_file_name,
  $license_file_url        = $dynatrace::server_license_file_url,
  $collector_port          = $dynatrace::server_collector_port,
  $do_pwh_connection       = $dynatrace::server_do_pwh_connection,
  $pwh_connection_hostname = $dynatrace::server_pwh_connection_hostname,
  $pwh_connection_port     = $dynatrace::server_pwh_connection_port,
  $pwh_connection_dbms     = $dynatrace::server_pwh_connection_dbms,
  $pwh_connection_database = $dynatrace::server_pwh_connection_database,
  $pwh_connection_username = $dynatrace::server_pwh_connection_username,
  $pwh_connection_password = $dynatrace::server_pwh_connection_password,
  $dynatrace_owner         = $dynatrace::dynatrace_owner,
  $dynatrace_group         = $dynatrace::dynatrace_group
) {
  
  validate_bool($do_pwh_connection)
  validate_string($installer_prefix_dir, $installer_file_name, $license_file_name)
  validate_string($collector_port)
  validate_string($pwh_connection_hostname, $pwh_connection_port, $pwh_connection_dbms, $pwh_connection_database, $pwh_connection_username, $pwh_connection_password)

  case $::kernel {
    'Linux': {
      $installer_script_name = 'install-server.sh'
      $service = 'dynaTraceServer'
      $init_scripts = [$service, 'dynaTraceFrontendServer', 'dynaTraceBackendServer']
    }
    default: {}
  }
  
  $directory_ensure = $ensure ? {
    'present' => 'directory',
    'absent'  => 'absent',
    default   => 'directory',
  }
  
  $link_ensure = $ensure ? {
    'present' => 'link',
    'absent'  => 'absent',
    default   => 'link',
  }

  $installation_ensure = $ensure ? {
    'present' => 'installed',
    'absent'  => 'uninstalled',
    default   => 'installed',
  }
  
  $service_ensure = $ensure ? {
    'present' => 'running',
    'absent'  => 'stopped',
    default   => 'running',
  }

  $installer_cache_dir = "${settings::vardir}/dynatrace"


#  class { 'dynatrace::role::dynatrace_user':
#    dynatrace_owner => $dynatrace_owner,
#    dynatrace_group => $dynatrace_group
#  }
#
#  file { 'Create the installer cache directory':
#    ensure  => $directory_ensure,
#    path    => $installer_cache_dir,
#    require => Class['dynatrace::role::dynatrace_user']
#  }

  dynatrace::resource::copy_or_download_file { "Copy or download the ${role_name} installer":
    ensure    => $ensure,
    file_name => $installer_file_name,
    file_url  => $installer_file_url,
    path      => "${installer_cache_dir}/${installer_file_name}",
    require   => File['Create the installer cache directory'],
    notify    => [
      File["Configure and copy the ${role_name}'s install script"],
      #Dynatrace_installation["Install the ${role_name}"]
    ]
  }

  file { "Configure and copy the ${role_name}'s install script":
    ensure  => $ensure,
    path    => "${installer_cache_dir}/${installer_script_name}",
    content => template("dynatrace/server/${installer_script_name}"),
    mode    => '0744',
    before  => Exec["Run the ${role_name}'s install script"],
  }
  
  exec { "Run the ${role_name}'s install script":
    command     => "${installer_cache_dir}/${installer_script_name}",
    creates     => "/opt/dynatrace-${version}/server",  
    path        => ['/bin', '/usr/bin', '/usr/sbin'],
    user        => 'root',
    group       => 'root',
  }

  file { "Create symbolic lync for dynatrace server":
    ensure => $link_ensure,
    path   => "${installer_prefix_dir}/dynatrace",
    target => "${installer_prefix_dir}/dynatrace-${version}",
  }

#  dynatrace_installation { "Install the ${role_name}":
#    ensure                => $installation_ensure,
#    installer_prefix_dir  => $installer_prefix_dir,
#    installer_file_name   => $installer_file_name,
#    installer_file_url    => $installer_file_url,
#    installer_script_name => $installer_script_name,
#    installer_path_part   => 'server',
#    installer_owner       => $dynatrace_owner,
#    installer_group       => $dynatrace_group,
#    installer_cache_dir   => $installer_cache_dir
#  }
#
  if $::kernel == 'Linux' {
    dynatrace::resource::configure_init_script { $init_scripts:
      ensure               => $ensure,
      role_name            => $role_name,
      installer_prefix_dir => $installer_prefix_dir,
      owner                => $dynatrace_owner,
      group                => $dynatrace_group,
      #notify               => Service["Start and enable the ${role_name}'s service: '${service}'"]
    }
  }

  service { "Start and enable the ${role_name}'s service: '${service}'":
    ensure  => $service_ensure,
    require => Dynatrace::Resource::Configure_init_script[$init_scripts],
    name    => $service,
    enable  => true
  }

  wait_until_port_is_open { $collector_port:
    ensure  => $ensure,
    require => Service["Start and enable the ${role_name}'s service: '${service}'"]
  }

#  wait_until_port_is_open { '2021':
#    ensure  => $ensure,
#    require => Service["Start and enable the ${role_name}'s service: '${service}'"]
#  }
#
#  wait_until_port_is_open { '6699':
#    ensure  => $ensure,
#    require => Service["Start and enable the ${role_name}'s service: '${service}'"]
#  }
#
#  wait_until_port_is_open { '8021':
#    ensure  => $ensure,
#    require => Service["Start and enable the ${role_name}'s service: '${service}'"]
#  }
#
#  wait_until_port_is_open { '9911':
#    ensure  => $ensure,
#    require => Service["Start and enable the ${role_name}'s service: '${service}'"]
#  }

#  if $do_pwh_connection {
#    wait_until_rest_endpoint_is_ready { 'https://localhost:8021/rest/management/pwhconnection/config':
#      ensure  => $ensure,
#      require => Service["Start and enable the ${role_name}'s service: '${service}'"]
#    }
#
#    configure_pwh_connection { $pwh_connection_dbms:
#      ensure   => $ensure,
#      hostname => $pwh_connection_hostname,
#      port     => $pwh_connection_port,
#      database => $pwh_connection_database,
#      username => $pwh_connection_username,
#      password => $pwh_connection_password,
#      require  => Wait_until_rest_endpoint_is_ready['https://localhost:8021/rest/management/pwhconnection/config']
#    }
#  }
}
