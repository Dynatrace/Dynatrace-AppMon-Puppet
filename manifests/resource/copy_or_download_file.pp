define dynatrace::resource::copy_or_download_file(
  $ensure = 'present',
  $file_name,
  $file_url,
  $path,
) {
  validate_re($ensure, ['^present$', '^absent$'])  
  validate_absolute_path($path)
  if $ensure == present {
	  exec { "Check for the presence of ${path}":
	    command => '/bin/false',
	    returns => 1,
	    unless  => "/usr/bin/test -e ${path}"
	  }
	
	  if $file_url {
	    exec { "Download ${file_url} to ${path}":
	      command => "/usr/bin/wget -q ${file_url} -O ${path}",
	      creates => $path,
	      require => Exec["Check for the presence of ${path}"]
	    }
	  } else {
	    file { "Copy ${file_name} to ${path}":
	      path   => $path,
	      source => "puppet:///modules/dynatrace/${file_name}",
	      ensure => present,
	      require => Exec["Check for the presence of ${path}"]
	    }
	  }
  } else {
    file { $path:
      ensure => 'absent',
    }
  }
}
