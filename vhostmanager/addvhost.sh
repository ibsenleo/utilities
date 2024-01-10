#!/bin/bash

# permissions
if [ "$(whoami)" != "root" ]; then
	echo "Root privileges are required to run this, try running with sudo..."
	exit 2
fi

current_directory="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
hosts_file="/etc/hosts"
apache_vhosts_path="/etc/apache2/sites-available/"
apache_template_path="$current_directory/vhost.template.conf"
web_root="/var/www/"
web_user="www-data"


# user input passed as options?
site_url=0
relative_doc_root=0
php_version=0

while getopts ":u:d:t:p:" o; do
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
            apache_template_path=${OPTARG}
            ;;
		p)
			php_version=${OPTARG}
			;;
	esac
done

# prompt if not passed as options
if [ $site_url == 0 ]; then
	read -p "Please enter the desired URL: " site_url
fi

if [ $relative_doc_root == 0 ]; then
	# read -p "Please enter the site path relative to the web root: $web_root_path" relative_doc_root
	echo "Web root set to $web_root$site_url"
	relative_doc_root=$site_url
fi

if [ $php_version == 0 ]; then
	php_version="8.2"
	echo "PHP version omitted. Setting default "$php_version
fi

FILE=$apache_vhosts_path$site_url.conf
if test -f "$FILE"; then
    echo "$FILE exists."
	exit 2
fi

# construct absolute path
absolute_doc_root=$web_root$relative_doc_root

# create directory if it doesn't exists
if [ ! -d "$absolute_doc_root" ]; then

	# create directory
	`mkdir "$absolute_doc_root/"`
	`chown -R $SUDO_USER:$web_user "$absolute_doc_root/"`

	# create index file
	indexfile="$absolute_doc_root/index.html"
	`touch "$indexfile"`
	echo "<html><head></head><body>Welcome!</body></html>" >> "$indexfile"

	echo "Created directory $absolute_doc_root/"
fi

# update apache vhost
vhost=`cat "$apache_template_path"`
vhost=${vhost//@site_url@/$site_url}
vhost=${vhost//@site_docroot@/$absolute_doc_root}
vhost=${vhost//@php_version@/$php_version}
echo "Using PHP version "$php_version

`touch $apache_vhosts_path$site_url.conf`
echo "$vhost" > "$apache_vhosts_path$site_url.conf"
echo "Updated vhosts in Apache config"

# update hosts file
echo "127.0.0.1	$site_url" >> $hosts_file
echo "Updated the hosts file"

# restart apache
echo "Enabling site in Apache..."
echo `a2ensite $site_url`

echo "Restarting Apache..."
echo `/etc/init.d/apache2 restart`

echo "Process complete, check out the new site at http://$site_url"

exit 0