#!/bin/sh

# Check that we're not running as root!
if [ "$(id -u)" -eq 0 ]; then
	echo "Do NOT run this script as root. Switch to the makerpm user first."
	exit 1
fi

# Default to signing, but allow us not to
if [ "$1" = "--no-sign" ]; then
	sign=""
else
	sign="--sign"
fi

# Figure out the fully-qualified path of this script
script_path="$(dirname "$(readlink -f "$0")")"

# Call rpmbuild, defining _topdir to be the fully qualified path to the
# directory containing this script (which has an rpm buildroot in it)
/bin/rpmbuild "$sign" --define "_topdir $script_path" -bb "$script_path"/SPECS/tomcat.spec
