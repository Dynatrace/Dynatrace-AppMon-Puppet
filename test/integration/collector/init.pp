class { 'dynatraceappmon::role::collector':
  # installer_file_url => 'https://files.dynatrace.com/downloads/OnPrem/dynaTrace/6.5/6.5.0.1289/dynatrace-collector-6.5.0.1289-linux-x86.jar',
  jvm_xms           => '256M',
  jvm_xmx           => '1024M',
  jvm_perm_size     => '256m',
  jvm_max_perm_size => '384m',
}
