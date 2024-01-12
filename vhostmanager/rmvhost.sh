#!/bin/bash
# sudo ./addvhost.sh -u test.ibs -d test.ibs -t ./template.ibs.conf -p

CheckService() {
	echo `systemctl is-active $1`
}

# permissions
if [ "$(whoami)" != "root" ]; then
	echo "Root privileges are required to run this, try running with sudo..."
	exit 2
fi

# debug
# hosts_file="./test.hosts"
# available_sites_path="./"


hosts_file="/etc/hosts"
vhost_root="/var/www/"
available_sites_path=""
web_service="apache2"

conf_file_path=0
vhost_folder=0
# web_user="www-data"


# user input passed as options?
site_url=0

while getopts ":u:s:" o; do
	case "${o}" in
		u)
			#site domain name
			site_url=${OPTARG}
			;;
		s)
			web_service=${OPTARG}
			;;
	esac
done

# Precheck
if [ $(CheckService $web_service) != 'active' ]; then
	echo "$web_service service is not running."
	exit 1
fi


## building conf file path
case "${web_service}" in
	apache2)
		available_sites_path="/etc/apache2/sites-available/"
		conf_file_path=$available_sites_path$site_url.conf
		# vhost_folder=$(sed -n "/<Directory.*/p" $conf_file_path | sed 's/<Directory//g' | sed 's/>//g' | sed 's/ *$//g;q')
		vhost_folder=$(sed -n "/<Directory.*/p" $conf_file_path | sed 's/<Directory//g' | sed 's/>//g' | sed 's/ *$//g' | sed 's/\/var\/www\///g' | sed 's/\/.*//g;q')
		vhost_folder=$(echo $vhost_folder | tr -d '\t')/
		;;
	nginx)
		available_sites_path="/etc/nginx/sites-available/"
		enabled_sites_path="/etc/nginx/sites-enabled/"
		conf_file_path=$available_sites_path$site_url
		vhost_folder=$(sed -n "/root\s*.*\;$/p" $conf_file_path  | sed 's/;//g' | sed 's/root//g' | sed 's/;//g' | sed 's/ *$//g' | sed 's/\/var\/www\///g' | sed 's/\/.*//g;q')
		# vhost_folder=$(sed -n "/root\s*.*\;$/p" $conf_file_path  | sed 's/;//g' | sed 's/root//g' | sed 's/;//g' | sed 's/ *$//g;q')
		vhost_folder=$(echo $vhost_folder | tr -d '\t')/
		;;
esac

# prompt if not passed as options
if [ $site_url == 0 ]; then
	read -p "Please enter the desired URL: " site_url
fi

echo "site: " $site_url

# Getting site info

if [ $vhost_folder == 0 ]; then
	echo "Directory in config file not found for " $site_url ". Nothing has changed."
    exit 1
fi

# Disabling service site
echo "Disabling site in $web_service..."

case "${web_service}" in
	apache2)
		echo `a2dissite $site_url`
		;;
	nginx)
		echo `rm $enabled_sites_path$site_url`
		;;
esac


# Deleting folder

echo "Checking if $vhost_root$vhost_folder exists..."
if [[ ! -z "$vhost_folder" ]] && [[ $vhost_folder != "/" ]] && [[ -d "$vhost_root$vhost_folder" ]]; then
	echo "Deleting folder " $vhost_root$vhost_folder
	`rm -R $vhost_root$vhost_folder`
else
	echo "Folder is already removed. Nothing to delete."
fi

# Deleting conf file from available vhosts
echo "Deleting file " $conf_file_path
`rm $conf_file_path`

# update hosts file
`sed  -i "/.*$site_url/d" $hosts_file`
echo "Updated the hosts file"

echo "Restarting $web_service..."
`/etc/init.d/$web_service restart`

echo "Process complete, $site_url has been removed."

exit 0

