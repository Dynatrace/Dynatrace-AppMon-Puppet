class dynatrace::role::collector (
  $role_name            = 'Dynatrace Collector',
  $installer_bitsize    = $dynatrace::params::collector_installer_bitsize,
  $installer_prefix_dir = $dynatrace::params::collector_installer_prefix_dir,
  $installer_file_name  = $dynatrace::params::collector_installer_file_name,
  $installer_file_url   = $dynatrace::params::collector_installer_file_url,
  $agent_port           = $dynatrace::params::collector_agent_port,
  $server_hostname      = $dynatrace::params::collector_server_hostname,
  $server_port          = $dynatrace::params::collector_server_port
) inherits dynatrace::params {
  
  validate_re($installer_bitsize, ['^32', '64'])
  validate_string($installer_prefix_dir, $installer_file_name)
  validate_string($agent_port, $server_hostname, $server_port)

  case $::kernel {
    'Linux': {
      $installer_script_name = 'install-collector.sh'
      $service = 'dynaTraceCollector'
      $init_scripts = [$service]
    }
  }

  $installer_cache_dir = "${settings::vardir}/dynatrace"


  require dynatrace::role::dynatrace_user

  file { "Create the installer cache directory":
    path   => $installer_cache_dir,
    ensure => directory
  }

  dynatrace::resource::copy_or_download_file { "Copy or download the ${role_name} installer":
    file_name => $installer_file_name,
    file_url  => $installer_file_url,
    path      => "${installer_cache_dir}/${installer_file_name}",
    require   => File["Create the installer cache directory"],
    notify    => [
      File["Configure and copy the ${role_name}'s install script"],
      Dynatrace_installation["Install the ${role_name}"]
    ]
  }

  file { "Configure and copy the ${role_name}'s install script":
    path    => "${installer_cache_dir}/${installer_script_name}",
    content => template("dynatrace/collector/${installer_script_name}"),
    mode    => '0744',
    before  => Dynatrace_installation["Install the ${role_name}"]
  }

  if $::dynatrace_collector_service_installed {
    service { "Stop and disable the ${role_name}'s service(s): '$service'":
      name      => $service,
      ensure    => stopped,
      enable    => false,
      subscribe => Dynatrace_installer["Fetch the ${role_name} installer"],
      before    => Dynatrace_installation["Install the ${role_name}"]
    }
  }

  dynatrace_installation { "Install the ${role_name}":
    installer_prefix_dir  => $installer_prefix_dir,
    installer_file_name   => $installer_file_name,
    installer_file_url    => $installer_file_url,
    installer_script_name => $installer_script_name,
    installer_path_part   => 'collector',
    installer_cache_dir   => $installer_cache_dir,
    ensure                => installed
  }

  if $::kernel == 'Linux' {
    dynatrace::resource::configure_init_script { $init_scripts:
      role_name            => $role_name,
      installer_prefix_dir => $installer_prefix_dir,
      notify               => Service["Start and enable the ${role_name}'s service: '${service}'"]
    }
  }

  service { "Start and enable the ${role_name}'s service: '${service}'":
    name   => $service,
    ensure => running,
    enable => true
  }

  wait_until_port_is_open { $agent_port:
    require => Service["Start and enable the ${role_name}'s service: '${service}'"]
  }
}
