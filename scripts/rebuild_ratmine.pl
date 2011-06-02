#!/usr/bin/perl
# rebuild_ratmine.pl
# by Andrew Vallejos

use strict;

my $HOME = '/home/intermine/';
my $PROJECT = 'build/intermine_current/ratmine/';

#step 1 take down webapp and back up user data
my $webapp_home = $HOME . $PROJECT . 'webapp/';

chdir($webapp_home);
print `ant default remove-webapp`;
print `ant write-userprofile-xml`;
print `cp ${webapp_home}build/userprofile.xml $HOME`;

#step 2 rebuild database
my $db_home = $HOME . $PROJECT . 'dbmodel/';

chdir($db_home);
print `ant clean build-db`;
chdir($HOME.$PROJECT);
print `perl ../bio/scripts/project_build -v localhost dump`;

#step 3 rebuild userdata
chdir($webapp_home);
print `ant create-db-userprofile`;
print `cp ${HOME}userprofile.xml ${webapp_home}build/userprofile.xml`;
print `ant read-userprofile-xml`;

#step 4 precompute templates and release webapp
print `ant precompute-templates`;
print `ant default remove-webapp release-webapp`;
