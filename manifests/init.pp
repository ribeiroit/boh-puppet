#
# Bag Of Holding
#
class boh(
    $environment = Enum['dev','prod'],
    $language = Enum['en', 'pt-br'],
    $python_version = Enum['2','3'],
    $debug = Enum['True', 'False'],
    $create_superuser = Enum['true', 'false'],
    $allowed_hosts = ['localhost', '127.0.0.1'],
    $pkg_url = 'https://github.com/ribeiroit/bag-of-holding/archive/translation.tar.gz',
    $pkg_checksum = '7ddbde7bfedeb34f77894be7a7dea20f',
    $pkg_name = '/opt/bag-of-holding-translation/',
    $tarball = '/opt/boh.tar.gz',
    $superuser_password = 'default',
    $domain = 'boh.localhost',
    $basename = '/opt/bag-of-holding/',
    $user = 'boh',
    $db_host = 'localhost',
    $db_name = 'boh',
    $db_user = 'boh',
    $db_password = 'boh',
) {
    $settings = "${basename}project/project/settings/${environment}.py"

    $nginx = $::operatingsystem ? {
        default => 'nginx',
    }

    $python2 = $::operatingsystem ? {
        default => 'python',
    }

    $python3 = $::operatingsystem ? {
        CentOS  => 'python34',
        default => 'python3',
    }

    $python2_dev = $::operatingsystem ? {
        default => 'python-devel',
    }

    $python3_dev = $::operatingsystem ? {
        CentOS  => 'python34-devel',
        default => 'python3-devel',
    }

    $pip2 = $::operatingsystem ? {
        default => 'python2-pip',
    }

    $pip3 = $::operatingsystem ? {
        CentOS  => 'python34-pip',
        default => 'python3-pip',
    }

    $uwsgi2 = $::operatingsystem ? {
        default => 'uwsgi-plugin-python',
    }

    $uwsgi3 = $::operatingsystem ? {
        default => 'uwsgi-plugin-python3',
    }

    $mariadb_srv = $::operatingsystem ? {
        default => 'mariadb-server',
    }

    $mariadb_dev = $::operatingsystem ? {
        default => 'mariadb-devel',
    }

    package { $nginx:
        ensure => present,
        alias  => 'nginx',
    }

    if $environment == 'prod' {
        package { $mariadb_dev:
            ensure => present,
            alias  => 'mariadb_dev',
        }
    }

    package { 'gcc':
        ensure => present,
    }

    package { 'gcc-c++':
        ensure => present,
    }

    package { 'make':
        ensure => present,
    }

    if $python_version == 2 {
        package { $python2:
            ensure => present,
        }

        package { $python2_dev:
            ensure => present,
        }

        package { $pip2:
            ensure => present,
        }

        package { $uwsgi2:
            ensure => present,
        }
    } elsif $python_version == 3 {
        package { $python3:
            ensure => present,
        }

        package { $python3_dev:
            ensure => present,
        }

        package { $pip3:
            ensure => present,
        }

        package { $uwsgi3:
            ensure => present,
        }
    }

    user { $user:
        ensure => present,
        shell  => '/bin/false',
        system => true,
    }

    file { $basename:
        ensure  => directory,
        owner   => $user,
        group   => $user,
        mode    => '0744',
        require => User[$user],
    }

    exec {
        'boh-download':
            command => "/usr/bin/curl -L -o $tarball $pkg_url",
            creates => $tarball;

        'boh-unpack':
            command => "/bin/tar xvf ${tarball}",
            creates => $pkg_name,
            cwd     => '/opt',
            onlyif  => "/bin/bash -c \"export CHK=\$(/usr/bin/md5sum ${tarball}|/usr/bin/cut -d' ' -f1); if [ '\$CHK' == '${pkg_checksum}' ]; then /bin/echo 0; else /bin/echo 1;fi\"",
            require => Exec['boh-download'];

        'boh-bind':
            command => "/bin/mount --bind $pkg_name $basename",
            require => Exec['boh-unpack'];

        'boh-install-virtualenv':
            command => "/usr/bin/pip${python_version} install virtualenv",
            require => Exec['boh-bind'];

        'boh-create-env':
            command => "/usr/bin/virtualenv ${basename}env",
            require => Exec['boh-install-virtualenv'];

        'boh-install-deps':
            command => "${basename}env/bin/pip${python_version} install -r ${basename}requirements/${environment}.txt",
            require => Exec['boh-create-env'];
    }

    file { $settings:
        ensure  => file,
        owner   => $user,
        group   => $user,
        mode    => '0744',
        content => template('boh/settings.erb'),
        require => Exec['boh-install-deps'],
    }

    exec {
        'boh-makemigrations':
            command => "${basename}env/bin/python${python_version} ${basename}project/manage.py makemigrations",
            require => File[$settings];

        'boh-migrate':
            command => "${basename}env/bin/python${python_version} ${basename}project/manage.py migrate",
            require => Exec['boh-makemigrations'];

        'boh-compilemessages':
            command => "${basename}env/bin/django-admin.py compilemessages",
            require => Exec['boh-migrate'];
    }

    if $environment == 'dev' {
        exec {
            'boh-start':
                command => "/bin/bash -c \"export DJANGO_SETTINGS_MODULE='project.settings.${environment}';${basename}env/bin/python${python_version} ${basename}project/manage.py runserver\"",
                require => Exec['boh-compilemessages'];
        }
    }
}
