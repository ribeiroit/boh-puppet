#
# Bag Of Holding
#
class boh(
    Enum['dev','prod'] $environment = 'dev',
    Enum['en', 'pt-br'] $language = 'en',
    Enum['sqlite3', 'mysql', 'postgresql', 'oracle'] $db_engine = 'sqlite3',
    Enum['2','3'] $python_version = '3',
    Boolean $debug = false,
    Array $allowed_hosts = ['localhost', '127.0.0.1'],
    String $pkg_url = 'https://github.com/ribeiroit/bag-of-holding/archive/translation.tar.gz',
    String $pkg_name = '/opt/bag-of-holding-translation/',
    String $tarball = '/opt/boh.tar.gz',
    String $superuser_default_pw = 'default',
    String $domain = 'boh.localhost',
    String $basename = '/opt/bag-of-holding/',
    String $user = 'boh',
    String $db_host = 'localhost',
    String $db_name = 'boh',
    String $db_user = 'boh',
    String $db_password = 'boh',
) {
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

    $mariadb_dev = $::operatingsystem ? {
        default => 'mariadb-devel',
    }

    package { $nginx:
        ensure => present,
        alias  => 'nginx',
    }

    package { $mariadb_dev:
        ensure => present,
        alias  => 'mariadb_dev',
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
    }

    exec {
        'boh-download':
            command => "/usr/bin/curl -L -o $tarball $pkg_url",
            creates => $tarball;

        'boh-unpack':
            command => "/bin/tar xvf ${tarball}",
            creates => $pkg_name,
            cwd     => '/opt',
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
            command => "${basename}env/bin/pip${python_version} install -r ${basename}requirements.txt",
            require => Exec['boh-create-env'];
    }
}
