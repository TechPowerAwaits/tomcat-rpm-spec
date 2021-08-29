# tomcat-rpm-spec
RPM spec for Tomcat (currently 8.5, but can be use for future versions)

Contains a script to update the SPEC file to match the latest update of a given Major/Minor release

It can also build the SPEC file

Usage: ```./get-latest.sh [--no-install] [--no-delete]```

__--no-install:__ Don't install built RPM package

__--no-delete:__ Don't delete built RPM package and Build Data
