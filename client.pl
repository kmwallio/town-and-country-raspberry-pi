#!/usr/bin/perl

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
  "$SETTINGS{MEDIAP}/ops",
  "$SETTINGS{MEDIAP}/mods",
);

#
# %commands are generic commands provided by
#   anyone
# %command_params are a list of what type of
#   parameters are expected
# %cli_commands are standard commands, however
#   it does use some of the generic commands
our %commands;
our %command_params;
our %cli_commands;
our $client_state = 'MUSIC';
our $music_thread = 0;
our $video_thread = 0;
our $server_thread = 0;

# Load Operators and Mods
foreach my $folder (@load) {
  opendir (DIR, $folder);
  foreach my $file (sort(grep(!/^\./, readdir(DIR)))) {
    require "$folder/$file";
  }
  closedir (DIR);
}

while (1) {
  #
  # If we're not connected to the server,
  # attempt to reconnect.

  sleep(120);
}

exit 0;
