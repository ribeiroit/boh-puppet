# boh-puppet

Puppet module to install Bag Of Holding application.

Usage
=====

Puppet Master Configuration:

  	cd /etc/puppet/modules
  	git clone git@github.com:ribeiroit/boh-puppet.git
  	vi /etc/puppet/manifests/site.pp
  
  	# adding boh module to the node
  	node 'boh.domain' {
    	class { 'boh':
        	python_version => 3,
        	environment => 'dev',
        	language => 'pt-br',
        	debug => 'True',
        	create_superuser => 'true',
        	pkg_checksum => '86b0164f7fd6c5e4aa43c8f056f08cea',
    	}
  	}
  
On your node just run:

  	puppet agent -t
  
If don't have a puppet master infrastructure, just clone to your standalone host and run:

		puppet apply
  
  
