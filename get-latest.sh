#!/bin/bash

# The mirror of Tomcat to download from
mirrorbase="http://mirrors.ukfast.co.uk/sites/ftp.apache.org/tomcat"

# The major and minor versions of the version of Tomcat to download
tomcat_major_version=8
tomcat_minor_version=5

###############################################################################

# Helper variables
color_bold="\e[1m"
color_success="\e[1;92m"
color_failure="\e[1;91m"
color_reset="\e[0m"

# Check configuration parameters
if [ "x$mirrorbase" == "x" ]; then
	echo -e "${color_failure}mirrorbase not set - edit script configuration before running${color_reset}"
	exit 1;
fi
if [ "x$tomcat_major_version" == "x" ]; then
	echo -e "${color_failure}tomcat_major_version not set - edit script configuration before running${color_reset}"
	exit 1;
fi
if [ "x$tomcat_minor_version" == "x" ]; then
	echo -e "${color_failure}tomcat_minor_version not set - edit script configuration before running${color_reset}"
	exit 1;
fi

# Download directory listing
wget --quiet -O /tmp/tc${tomcat_major_version}-index.html "${mirrorbase}/tomcat-${tomcat_major_version}" > /dev/null
if [ "x$?" != "x0" ]; then
	echo -e "${color_failure}Tomcat version check download failed${color_reset}"
	exit 1;
fi

# Get a list of version numbers that are available
cat /tmp/tc${tomcat_major_version}-index.html | fgrep '[DIR]' | grep -E "v${tomcat_major_version}.${tomcat_minor_version}.[0-9]+/" | grep -Eo '<a[ \t]+href[ \t]*=[ \t]*"[^"]*"' | grep -Eo "v${tomcat_major_version}\.${tomcat_minor_version}\.[^\"]*" | sed 's|/$||' > /tmp/tc${tomcat_major_version}-versions.txt

# Sort the release numbers to get the latest release
tomcat_release=`cat /tmp/tc${tomcat_major_version}-versions.txt | cut -d. -f3 | sort -nr | head -n1`
tomcat_version=${tomcat_major_version}.${tomcat_minor_version}.${tomcat_release}
tomcat_url=${mirrorbase}/tomcat-${tomcat_major_version}/v${tomcat_version}/bin/apache-tomcat-${tomcat_version}.tar.gz

# Tidy up
rm -f /tmp/tc${tomcat_major_version}-index.html
rm -f /tmp/tc${tomcat_major_version}-versions.txt

# Figure out where to download to based on the location of this script
our_path=$(dirname $(readlink -f $0))
download_path=${our_path}/SOURCES/apache-tomcat-${tomcat_version}.tar.gz

# Debug output
echo -e "Detected latest version: ${color_success}${tomcat_version}${color_reset}"
echo -e "Using URL: ${color_success}${tomcat_url}${color_reset}"
echo -e "Saving to: ${color_success}${download_path}${color_reset}"
echo
echo "Downloading..."

# Download Tomcat
wget --quiet -O ${download_path} $tomcat_url
if [ "x$?" != "x0" ]; then
	echo -e "${color_failure}Failed to download Tomcat${color_reset}"
	exit 1;
fi

echo -e "${color_success}Download succeeded.${color_reset} You should verify that the correct package has been downloaded."

echo -ne "\n${color_bold}Update the RPM spec file to the latest version [y/n]? ${color_reset}"
read update

if [ "x$update" == "xy" ] || [ "x$update" == "xY" ]; then
	spec_path_1=${our_path}/SPECS/tomcat.spec
	#SPEC_PATH_2=${our_path}/SPECS/tomcatnative.spec

	# Get the version currently in the spec file
	old_spec_version=$(grep -E "^\s*%define\s+tomcat_version\s+" ${spec_path_1} | sed -r 's/^\s*%define\s+tomcat_version\s+//;s/\s*$//')

	# Update the spec file tomcat_version line
	sed -ri "s/^(\s*%define\s+tomcat_version\s+)[0-9\.]+\s*/\1${tomcat_version}/" ${spec_path_1}
	if [ "x$?" != "x0" ]; then
		echo -e "${color_failure}RPM spec file update failed${color_reset}"
		exit 1
	fi
	#sed -ri "s/^(\s*%define\s+tomcat_version\s+)[0-9\.]+\s*/\1${tomcat_version}/" ${SPEC_PATH_2}
	#if [ "x$?" != "x0" ]; then
	#	echo -e "${color_failure}RPM spec file update failed${color_reset}"
	#	exit 1
	#fi

	# If the version in the spec file has changed we should reset the 
	# release back to 1
	if [ "x${old_spec_version}" != "x${tomcat_version}" ]; then
		echo "Previous spec file tomcat_version was ${old_spec_version}. Resetting tomcat_release to 1."
		sed -ri "s/^(\s*%define\s+tomcat_release\s+)[^\s]+\s*/\11/" ${spec_path_1}
		if [ "x$?" != "x0" ]; then
			echo -e "${color_failure}RPM spec file update failed${color_reset}"
			exit 1
		fi
		#sed -ri "s/^(\s*%define\s+tomcat_release\s+)[^\s]+\s*/\11/" ${SPEC_PATH_2}
		#if [ "x$?" != "x0" ]; then
		#	echo -e "${color_failure}RPM spec file update failed${color_reset}"
		#	exit 1
		#fi
	fi

	echo -ne "${color_bold}Build updated RPMs [y/n]? ${color_reset}"
	read build

	if [ "x$build" == "xy" ] || [ "x$build" == "xY" ]; then
		${our_path}/build.sh
	fi
fi
