These dates correspond to Mountain Standard Time.

### 03-29-2021
* Removed commented-out code from _get-latest.sh_ related to the unimplemented Tomcat Native Spec File.
* Fixed the retrieving of the Tomcat Patch Version Number from a mirror in _get-latest.sh_.
* _get-latest.sh_ now keeps the index file if the download of the Tomcat package fails.
* _get-latest.sh_ doesn't download index file if it already exists. (Useful for debugging.)

### 03-27-2021
* Change all instances of _uostomcat_ to _tomcat_.
* Remove the outdated _push.sh_ script.
* All the scripts now use lowercase variable names in order to avoid conflict with environment variables.
* Changed some variable names in the scripts.
* Simplified the syntax of the scripts.

### 03-25-2021
* The beginning of this fork and the creation of the CHANGELOG.
