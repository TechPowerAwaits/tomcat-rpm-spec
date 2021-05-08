#!/bin/sh
# shellcheck disable=SC2059 # Some variables are format strings

# The mirror of Tomcat to download from
mirrorbase="https://downloads.apache.org/tomcat"

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
if [ -z "$mirrorbase" ]; then
	printf "${color_failure}mirrorbase not set - edit script configuration before running${color_reset}\n"
	exit 1
fi
if [ -z "$tomcat_major_version" ]; then
	printf "${color_failure}tomcat_major_version not set - edit script configuration before running${color_reset}\n"
	exit 1
fi
if [ -z "$tomcat_minor_version" ]; then
	printf "${color_failure}tomcat_minor_version not set - edit script configuration before running${color_reset}\n"
	exit 1
fi

# Download directory listing
if ! wget --quiet -O /tmp/tc"${tomcat_major_version}"-index.html "${mirrorbase}/tomcat-${tomcat_major_version}" >/dev/null; then
	printf "${color_failure}Tomcat version check download failed${color_reset}\n"
	exit 1
fi

# Get a list of version numbers that are available
grep -F '[DIR]' /tmp/tc"${tomcat_major_version}"-index.html | grep -E "v${tomcat_major_version}.${tomcat_minor_version}.[0-9]+/" | grep -Eo '<a[ \t]+href[ \t]*=[ \t]*"[^"]*"' | grep -Eo "v${tomcat_major_version}\.${tomcat_minor_version}\.[^\"]*" | sed 's|/$||' >/tmp/tc"${tomcat_major_version}"-versions.txt

# Sort the release numbers to get the latest release
tomcat_patch_version=$(cut -d. -f3 /tmp/tc"${tomcat_major_version}"-versions.txt | sort -nr | head -n1)
tomcat_version="${tomcat_major_version}"."${tomcat_minor_version}"."${tomcat_patch_version}"
tomcat_url=${mirrorbase}/tomcat-${tomcat_major_version}/v${tomcat_version}/bin/apache-tomcat-${tomcat_version}.tar.gz

# Tidy up
rm -f /tmp/tc"${tomcat_major_version}"-index.html
rm -f /tmp/tc"${tomcat_major_version}"-versions.txt

# Figure out where to download to based on the location of this script
script_path="$(dirname "$(readlink -f "$0")")"
download_path="${script_path}"/SOURCES/apache-tomcat-${tomcat_version}.tar.gz

# Debug output
printf "Detected latest version: ${color_success}%s${color_reset}\n" "$tomcat_version"
printf "Using URL: ${color_success}%s${color_reset}\n" "$tomcat_url"
printf "Saving to: ${color_success}%s${color_reset}\n" "$download_path"
echo
echo "Downloading..."

# Download Tomcat
if ! wget --quiet -O "${download_path}" "$tomcat_url"; then
	printf "${color_failure}Failed to download Tomcat${color_reset}\n"
	exit 1
fi

printf "${color_success}Download succeeded.${color_reset} You should verify that the correct package has been downloaded.\n"

printf "\n${color_bold}Updating the RPM spec file to the latest version ${color_reset}"

tc_spec_path="${script_path}"/SPECS/tomcat.spec

# Get the version currently in the spec file
spec_tomcat_version=$(grep -E "^\s*%define\s+version\s+" "${tc_spec_path}" | sed -r 's/^\s*%define\s+version\s+//;s/\s*$//')

# Update the spec file tomcat_version line
if ! sed -ri "s/^(\s*%define\s+version\s+)[0-9\.]+\s*/\1${tomcat_version}/" "${tc_spec_path}"; then
	printf "${color_failure}Failed to update version in RPM spec file${color_reset}\n"
	exit 1
fi

# Update major version number
if ! sed -ri "s/^(\s*%define\s+major\s+)[0-9\.]+\s*/\1${tomcat_major_version}/" "${tc_spec_path}"; then
	printf "${color_failure}Failed to update major version number in RPM spec file${color_reset}\n"
	exit 1
fi

# If the version in the spec file has changed we should reset the
# release back to 1
if [ "$spec_tomcat_version" != "$tomcat_version" ]; then
	echo "Previous spec file tomcat_version was ${spec_tomcat_version}."
	if ! sed -ri "s/^(\s*%define\s+release\s+)[^\s]+\s*/\11/" "${tc_spec_path}"; then
		printf "${color_failure}Failed to set release to 1 in RPM spec file${color_reset}\n"
		exit 1
	fi
fi

printf "${color_bold}Building updated RPMs${color_reset}"

# Call rpmbuild, defining _topdir to be the fully qualified path to the
# directory containing this script (which has an rpm buildroot in it)
rpmbuild --define "_topdir $script_path" -bb "$script_path"/SPECS/tomcat.spec
arch=noarch
rpmdir="$script_path"/RPMS/"$arch"

if [ "$1" != "--no-install" ] && [ "$2" != "--no-install" ]; then
	printf "\n${color_bold}Installing RPMs${color_reset}"
	sudo rpm -i "$rpmdir"/*.rpm
fi

if [ "$1" != "--no-delete" ] && [ "$2" != "--no-delete" ]; then
	printf "\n${color_bold}Removing RPMs and Build Data${color_reset}"
	rm "$rpmdir"/*.rpm
	sudo rm -rf "$script_path"/BUILD/apache-tomcat-*
fi
