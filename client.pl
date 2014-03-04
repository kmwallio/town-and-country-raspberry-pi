#/usr/bin/perl

use warnings;
use diagnostics;
use strict;
use threads;
use threads::shared;

our %SETTINGS;
    $SETTINGS{SERVER} = 'server.com';
    # Web Server to connect to for content
    $SETTINGS{SVRWEB} = '8080';
    # Port to connect to for PUSH notifications
    $SETTINGS{SVRPUB} = '8081';
    # Password used for simple handshaking
    $SETTINGS{SVRPSW} = 'SECRET-CODE';
    # Path on the local server for this script and content
    $SETTINGS{MEDIAP} = '/home/pi/t-and-c';
    $SETTINGS{OMXOPS} = '-o local';
    $SETTINGS{PINAME} = 'CarPi';


##################################
#         Stop Editing           #
##################################


my @load = (
  "./ops",
  "./mods",
);

our %commands;
our %command_params;
our %cli_commands;
our $client_state = 'MUSIC';

# Load Operators and Mods
foreach my $folder (@load) {
  opendir (DIR, $folder);
  foreach my $file (sort(grep(!/^\./, readdir(DIR)))) {
    require "$folder/$file";
  }
  closedir (DIR);
}

while (1) {
  sleep(60);
}

exit 0;
