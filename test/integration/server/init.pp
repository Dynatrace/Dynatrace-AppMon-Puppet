class { 'dynatraceappmon::role::server':
  # installer_file_url => 'https://files.dynatrace.com/downloads/OnPrem/dynaTrace/6.5/6.5.0.1289/dynatrace-server-6.5.0.1289-linux-x86.jar',
}

class { 'dynatraceappmon::role::pwh_connection':
  require            => [ Class['dynatraceappmon::role::server'] ]
}
