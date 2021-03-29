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
if [ -z $mirrorbase ]; then
	echo -e "${color_failure}mirrorbase not set - edit script configuration before running${color_reset}"
	exit 1;
fi
if [ -z $tomcat_major_version ]; then
	echo -e "${color_failure}tomcat_major_version not set - edit script configuration before running${color_reset}"
	exit 1;
fi
if [ -z $tomcat_minor_version ]; then
	echo -e "${color_failure}tomcat_minor_version not set - edit script configuration before running${color_reset}"
	exit 1;
fi

# Download directory listing
wget --quiet -O /tmp/tc${tomcat_major_version}-index.html "${mirrorbase}/tomcat-${tomcat_major_version}" > /dev/null
if [ $? -ne 0 ]; then
	echo -e "${color_failure}Tomcat version check download failed${color_reset}"
	exit 1;
fi

# Attempt to get the Patch Version Number
first_v=0
first_dot=0
second_dot=0
tomcat_version_str=$(grep -o [v"$tomcat_major_version"."$tomcat_minor_version".0-9] < /tmp/tc"$tomcat_major_version"-index.html)
tomcat_patch_version=""

for char in $tomcat_version_str; do
    if [ $first_v -eq 0 ] && [ $char == "v" ]; then
        first_v=1
    fi
    if [ $first_v -eq 1 ] && [ $char == "v" ]; then
        break
    fi
    if [ $first_v ] && [ $char == "." ]; then
        if [ $first_dot -eq 0 ]; then
            first_dot=1
        else
            second_dot=1
        fi
    fi
    if [ $second_dot -eq 1 ] && [ $char != "." ]; then
        tomcat_patch_version=$(echo "$tomcat_patch_version""$char")
    fi
done

tomcat_version=${tomcat_major_version}.${tomcat_minor_version}.${tomcat_patch_version}
tomcat_url=${mirrorbase}/tomcat-${tomcat_major_version}/v${tomcat_version}/bin/apache-tomcat-${tomcat_version}.tar.gz

# Tidy up
rm -f /tmp/tc${tomcat_major_version}-index.html

# Figure out where to download to based on the location of this script
script_path=$(dirname $(readlink -f $0))
download_path=${script_path}/SOURCES/apache-tomcat-${tomcat_version}.tar.gz

# Debug output
echo -e "Detected latest version: ${color_success}${tomcat_version}${color_reset}"
echo -e "Using URL: ${color_success}${tomcat_url}${color_reset}"
echo -e "Saving to: ${color_success}${download_path}${color_reset}"
echo
echo "Downloading..."

# Download Tomcat
wget --quiet -O ${download_path} $tomcat_url
if [ $? -ne 0 ]; then
	echo -e "${color_failure}Failed to download Tomcat${color_reset}"
	exit 1;
fi

echo -e "${color_success}Download succeeded.${color_reset} You should verify that the correct package has been downloaded."

echo -ne "\n${color_bold}Update the RPM spec file to the latest version [y/n]? ${color_reset}"
read update_prompt

if [ $update_prompt == "y" ] || [ $update_prompt == "Y" ]; then
	tc_spec_path=${script_path}/SPECS/tomcat.spec

	# Get the version currently in the spec file
	spec_tomcat_version=$(grep -E "^\s*%define\s+tomcat_version\s+" ${tc_spec_path} | sed -r 's/^\s*%define\s+tomcat_version\s+//;s/\s*$//')

	# Update the spec file tomcat_version line
	sed -ri "s/^(\s*%define\s+tomcat_version\s+)[0-9\.]+\s*/\1${tomcat_version}/" ${tc_spec_path}
	if [ $? -ne 0 ]; then
		echo -e "${color_failure}RPM spec file update failed${color_reset}"
		exit 1
	fi

	# If the version in the spec file has changed we should reset the 
	# release back to 1
	if [ $spec_tomcat_version != $tomcat_version ]; then
		echo "Previous spec file tomcat_version was ${spec_tomcat_version}. Resetting tomcat_patch_version to 1."
		sed -ri "s/^(\s*%define\s+tomcat_patch_version\s+)[^\s]+\s*/\11/" ${spec_path_1}
		if [ $? -ne 0 ]; then
			echo -e "${color_failure}RPM spec file update failed${color_reset}"
			exit 1
		fi
	fi

	echo -ne "${color_bold}Build updated RPMs [y/n]? ${color_reset}"
	read build_prompt

	if [ $build_prompt == "y" ] || [ $build_prompt == "Y" ]; then
		${script_path}/build.sh
	fi
fi
