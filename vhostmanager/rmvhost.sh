#!/bin/bash
# sudo ./addvhost.sh -u test.ibs -d test.ibs -t ./template.ibs.conf -p

# permissions
if [ "$(whoami)" != "root" ]; then
	echo "Root privileges are required to run this, try running with sudo..."
	exit 2
fi

# debug
# hosts_file="./test.hosts"
# apache_vhosts_path="./"


hosts_file="/etc/hosts"
apache_vhosts_path="/etc/apache2/sites-available/"

apache_vhost_conf=0
apache_vhost_dir=0
# web_user="www-data"


# user input passed as options?
site_url=0

while getopts ":u:" o; do
	case "${o}" in
		u)
			#site domain name
			site_url=${OPTARG}
			;;
	esac
done

# prompt if not passed as options
if [ $site_url == 0 ]; then
	read -p "Please enter the desired URL: " site_url
fi

echo "site: " $site_url

# Getting site info
apache_vhost_conf=$apache_vhosts_path$site_url.conf
apache_vhost_dir=$(sed -n "/<Directory.*/p" $apache_vhost_conf | sed 's/<Directory//g' | sed 's/>//g' | sed 's/ *$//g')

if [ $apache_vhost_dir == 0 ]; then
	echo "Directory not found for " $site_url ". Nothing has changed."
    exit 1
fi

# Disabling apache site
echo "Disabling site in Apache..."
echo `a2dissite $site_url`

# Deleting folder
echo "Deleting folder " $apache_vhost_dir
echo `rm -R $apache_vhost_dir`

# Deleting conf file
echo "Deleting file " $apache_vhost_conf
echo `rm $apache_vhost_conf`

# update hosts file
echo "Updated the hosts file"
echo `sed  -i "/.*$site_url/d" $hosts_file`

echo "Restarting Apache..."
echo `/etc/init.d/apache2 restart`

echo "Process complete, $site_url has been removed."

exit 0

