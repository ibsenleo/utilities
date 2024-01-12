#!/bin/bash

################################################################################
# Help                                                                         #
################################################################################

Help()
{
   # Display Help
   echo "Creates a virtualhost for apache in ubuntu/debian distro."
   echo
   echo "Syntax: addvhost [-u|d|t|p|h]"
   echo "options:"
   echo "-u     Url for the virtualhost."
   echo "-d     Relative path under the web server root. (without trailing slash)"
   echo "-t     Template to use to fill .conf file. Default ./vhost.template.conf"
   echo "-p     PHP version for the php fastCGI. Default 8.2."
   echo "-s     Web service running. Default apache2."
   echo
   
}

CheckService() {
	echo `systemctl is-active $1`
}

################################################################################
# Main                                                                         #
################################################################################



# permissions
if [ "$(whoami)" != "root" ]; then
	echo "Root privileges are required to run this, try running with sudo..."
	exit 2
fi

current_directory="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
hosts_file="/etc/hosts"
template_path=""
web_root="/var/www/"
web_user="www-data"
web_service="apache2"
available_sites_path=""
enabled_sites_path=""


# user input passed as options?
site_url=0
relative_doc_root=0
php_version=0
create_index=0

while getopts ":u:d:t:p:s:ih" o; do
	case "${o}" in
		u)
			#site domain name
			site_url=${OPTARG}
			;;
		d)
			#directory under web root
			relative_doc_root=${OPTARG}
			;;
        t)
			#template path
            template_path=${OPTARG}
            ;;
		p)
			php_version=${OPTARG}
			;;
		s)
			web_service=${OPTARG}
			;;
		i)
			create_index=1
			;;
		h)
			Help
			exit 0
			;;
		
		\?) # Invalid option
         echo "Error: Invalid option"
         exit;;
	esac
done


# Precheck
if [ $(CheckService $web_service) != 'active' ]; then
	echo "$web_service service is not running."
	exit 1
fi

# setting template path
if [ -z $template_path ]; then
	template_path=$current_directory/$web_service.template.conf
fi

## building conf file path
case "${web_service}" in
	apache2)
		available_sites_path="/etc/apache2/sites-available/"
		conf_file_path=$available_sites_path$site_url.conf
		;;
	nginx)
		available_sites_path="/etc/nginx/sites-available/"
		enabled_sites_path="/etc/nginx/sites-enabled/"
		conf_file_path=$available_sites_path$site_url
		;;
esac

# check if conf file already exists
if test -f "$conf_file_path"; then
    echo "$conf_file_path exists."
	exit 2
fi

###################
## PARSE ARGS
# prompt if not passed as options
if [ $site_url == 0 ]; then
	read -p "Please enter the desired URL: " site_url
fi

if [ $relative_doc_root == 0 ]; then
	# read -p "Please enter the site path relative to the web root: $web_root_path" relative_doc_root
	echo "Web root set to $web_root$site_url"
	relative_doc_root=$site_url
else
	relative_doc_root=${relative_doc_root#/}
fi

if [ $php_version == 0 ]; then
	php_version="8.2"
	echo "PHP version omitted. Setting default "$php_version
fi
###################

# construct absolute path
absolute_doc_root=$web_root$relative_doc_root

# create web root directory if it doesn't exists
if [ ! -d "$absolute_doc_root" ]; then

	# create directory
	`mkdir -p "$absolute_doc_root/"`
	`chown -R $SUDO_USER:$web_user "$absolute_doc_root/"`

	# create index file
	if [ $create_index == 1 ]; then
		indexfile="$absolute_doc_root/index.php"
		`touch "$indexfile"`
		echo "<html><head></head><body>Welcome!</body></html>" >> "$indexfile"
	fi

	echo "Created directory $absolute_doc_root/"
else 
	echo "Directory already exist."
fi


# update vhost file
vhost=`cat "$template_path"`
vhost=${vhost//@site_url@/$site_url}
vhost=${vhost//@site_docroot@/$absolute_doc_root}
vhost=${vhost//@php_version@/$php_version}
echo "Using PHP version "$php_version

case "${web_service}" in
	apache2)
		`touch $available_sites_path$site_url.conf`
		echo "$vhost" > "$available_sites_path$site_url.conf"
		echo "Updated vhosts in Apache config"

		# restart apache
		echo "Enabling site in Apache..."
		echo `a2ensite $site_url`

		echo "Restarting Apache..."
		echo `/etc/init.d/apache2 restart`
		
		;;
	nginx)
		`touch $available_sites_path$site_url`
		echo "$vhost" > "$available_sites_path$site_url"
		echo "Updated vhosts in nginx config"

		# restart apache
		echo "Enabling site in Nginx..."
		echo `ln -s $available_sites_path$site_url $enabled_sites_path$site_url`

		echo "Restarting Nginx..."
		echo `/etc/init.d/nginx restart`
		;;
esac

# update hosts file
echo "127.0.0.1	$site_url" >> $hosts_file
echo "Updated the hosts file"

echo "Process complete, check out the new site at http://$site_url"

exit 0