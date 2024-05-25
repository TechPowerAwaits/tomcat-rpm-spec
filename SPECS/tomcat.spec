%define __jar_repack %{nil}
%define tomcat_group tomcat
%define tomcat_user tomcat
%define tomcat_home /usr/share/tomcat
%define tomcat_user_home /srv/tomcat
%define tomcat_cache_home /var/cache/tomcat
%define tomcat_conf_home %{_sysconfdir}/tomcat
%define tomcat_log_home /var/log/tomcat
%define systemd_dir /usr/lib/systemd/system/
%define major 8
%define version 8.5.78
%define release 1

Summary:    Apache Servlet/JSP Engine, RI for Servlet 3.1/JSP 2.3 API
Name:       tomcat%{major}
Version:    %{version}
BuildArch:  noarch
Release:    %{release}
License:    Apache Software License
Group:      Networking/Daemons
Provides:   tomcat
Recommends: java-1.8.0-openjdk-devel java-1_8_0-openjdk-devel
Suggests:   tomcat-native
URL:        http://tomcat.apache.org/
Source0:    apache-tomcat-%{version}.tar.gz
Source1:    tomcat.service
Source2:    tomcat.sysconfig
Source3:    tomcat.logrotate
BuildRoot:  %{_tmppath}/tomcat-%{version}-%{release}-root-%(%{__id_u} -n)

%description
Tomcat is the servlet container that is used in the official Reference
Implementation for the Java Servlet and JavaServer Pages technologies.
The Java Servlet and JavaServer Pages specifications are developed by
Oracle under the Java Community Process.

Tomcat is developed in an open and participatory environment and
released under the Apache Software License. Tomcat is intended to be
a collaboration of the best-of-breed developers from around the world.
We invite you to participate in this open development project. To
learn more about getting involved, click here.

This package contains the base tomcat installation that depends on Oracle's JDK 
and not on JPP packages.

%prep
%setup -q -n apache-tomcat-%{version}

%build

%install
install -d -m 755 %{buildroot}/%{tomcat_home}/
cp -R * %{buildroot}/%{tomcat_home}/

# Remove all the useless webapps. manager and host-manager are packaged 
# in subpackages and are %excluded from the main package
rm -rf %{buildroot}/%{tomcat_home}/webapps/examples
rm -rf %{buildroot}/%{tomcat_home}/webapps/docs
rm -rf %{buildroot}/%{tomcat_home}/webapps/ROOT
install -d -m 775 %{buildroot}%{tomcat_user_home}/webapps
cd %{buildroot}/%{tomcat_user_home}/webapps
ln -s %{tomcat_home}/webapps/manager
ln -s %{tomcat_home}/webapps/host-manager
chmod 775 %{buildroot}/%{tomcat_user_home}
cd -

# Remove windows bat files
rm -f %{buildroot}/%{tomcat_home}/bin/*.bat

# Remove the 'safeToDelete.tmp'
rm -f %{buildroot}/%{tomcat_home}/temp/safeToDelete.tmp

# Remove useless doc files
rm -f %{buildroot}/%{tomcat_home}/LICENSE
rm -f %{buildroot}/%{tomcat_home}/NOTICE
rm -f %{buildroot}/%{tomcat_home}/RELEASE-NOTES
rm -f %{buildroot}/%{tomcat_home}/RUNNING.txt

# Put logging in a custom location and link back.
rm -rf %{buildroot}/%{tomcat_home}/logs
install -d -m 755 %{buildroot}%{tomcat_log_home}/
cd %{buildroot}/%{tomcat_home}/
ln -s %{tomcat_log_home}/ logs
cd -

# Put conf in a custom location and link back.
install -d -m 755 %{buildroot}/%{_sysconfdir}
mv %{buildroot}/%{tomcat_home}/conf %{buildroot}/%{tomcat_conf_home}
cd %{buildroot}/%{tomcat_home}/
ln -s %{tomcat_conf_home} conf
cd -

# Replace the appBase in the server.xml appropriately
sed -i 's|\(^ *<Host.*appBase="\)[^"]*|\1%{tomcat_user_home}/webapps|' %{buildroot}/%{tomcat_conf_home}/server.xml

# Put temp and work in a custom location and link back.
install -d -m 775 %{buildroot}%{tomcat_cache_home}
mv %{buildroot}/%{tomcat_home}/temp %{buildroot}/%{tomcat_cache_home}/
mv %{buildroot}/%{tomcat_home}/work %{buildroot}/%{tomcat_cache_home}/
cd %{buildroot}/%{tomcat_home}/
ln -s %{tomcat_cache_home}/temp
ln -s %{tomcat_cache_home}/work
chmod 775 %{buildroot}/%{tomcat_cache_home}/temp
chmod 775 %{buildroot}/%{tomcat_cache_home}/work
cd -

# systemd service
install -d -m 755 %{buildroot}/%{systemd_dir}
install    -m 644 %_sourcedir/tomcat.service %{buildroot}/%{systemd_dir}/tomcat.service

# sysconfig script
install -d -m 755 %{buildroot}/%{_sysconfdir}/sysconfig/
install    -m 644 %_sourcedir/tomcat.sysconfig %{buildroot}/%{_sysconfdir}/sysconfig/tomcat

# logrotate script
install -d -m 755 %{buildroot}/%{_sysconfdir}/logrotate.d
install    -m 644 %_sourcedir/tomcat.logrotate %{buildroot}/%{_sysconfdir}/logrotate.d/tomcat

%clean
rm -rf %{buildroot}

%pre
getent group %{tomcat_group} >/dev/null || groupadd -g 91 -r %{tomcat_group}
getent passwd %{tomcat_user} >/dev/null || /usr/sbin/useradd -u 91 --comment "Apache Tomcat" --shell /sbin/nologin -M -r -g %{tomcat_group} --home %{tomcat_home} %{tomcat_user}

%files
%defattr(-,%{tomcat_user},%{tomcat_group},0770)
%{tomcat_log_home}/
%defattr(-,root,root)
%{tomcat_user_home}
%{tomcat_home}
%{systemd_dir}/tomcat.service
%{_sysconfdir}/logrotate.d/tomcat
%defattr(-,root,%{tomcat_group})
%{tomcat_cache_home}
%exclude %{tomcat_home}/webapps/manager
%exclude %{tomcat_home}/webapps/host-manager
%exclude %{tomcat_user_home}/webapps/manager
%exclude %{tomcat_user_home}/webapps/host-manager
%config(noreplace) %{_sysconfdir}/sysconfig/tomcat
%config(noreplace) %{tomcat_conf_home}/*

%post
/bin/systemctl daemon-reload

%package admin-webapps

Summary:    Admin Webapps for Apache Tomcat
Version:    %{version}
BuildArch:  noarch
Release:    %{release}
License:    Apache Software License
Group:      Networking/Daemons
Provides:   tomcat-admin-webapps
Requires:   tomcat >= %{version}-%{release}
BuildRoot:  %{_tmppath}/tomcat-admin-webapps-%{version}-%{release}-root-%(%{__id_u} -n)

%description admin-webapps
Tomcat is the servlet container that is used in the official Reference
Implementation for the Java Servlet and JavaServer Pages technologies.
The Java Servlet and JavaServer Pages specifications are developed by
Oracle under the Java Community Process.

Tomcat is developed in an open and participatory environment and
released under the Apache Software License. Tomcat is intended to be
a collaboration of the best-of-breed developers from around the world.

This package contains the manager and host-manager webapps used to
assist in the deploying and configuration of Tomcat. 

%files admin-webapps

%{tomcat_home}/webapps/manager/
%{tomcat_home}/webapps/host-manager/
%{tomcat_user_home}/webapps/manager
%{tomcat_user_home}/webapps/host-manager
