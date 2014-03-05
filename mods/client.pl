use Net::EasyTCP;
use JSON;
use Digest::SHA1 qw(sha1_hex);
use File::Copy;

#
# This is a list of commands and handlers
# Default commands are in this file.
$cli_commands{'PING'} = \&cli_ping;
$cli_commands{'HELO'} = \&cli_helo;
$cli_commands{'WGET'} = \&cli_download;
$cli_commands{'LIST'} = \&cli_send_commands;
$cli_commands{'EXIT'} = \&close_connection;
$cli_commands{'MUSIC'} = \&cli_play_music;
$cli_commands{'VIDEO'} = \&cli_play_video;
$cli_commands{'SAY'} = \&cli_speak;

our $client;

# Internal: Sends message to server
#
# $message - Message to send
#
# Example
#
#    cli_send('Hello Server');
#
# Returns void
sub cli_send {
  my $message = shift;
  $client->send($message);
}

# Internal: Starts client connection to server
#
# Example
#
#    client_start();
#
# Returns void
sub client_start {
  #
  # Connect here to preven blocking on start,
  # especially if no connection is available.
  $client = new Net::EasyTCP(
    mode => "client",
    host => $SETTINGS{SERVER},
    port => $SETTINGS{SVRPUB}) || threads->exit();

  my %handshake;
  $handshake{'cmd'} = 'HELO';
  $handshake{'cli'} = $SETTINGS{PINAME};

  #
  # The Handshake simply moves the client from
  # a noop state, to fully operable state.
  # This consists of verifying the secret code
  # stored in the client.  This does not affect
  # the encryption used by Net::TCP, it just a
  # simple preventative measure of knowing who
  # should be able to use the server.
  cli_send(to_json(\%handshake));

  my $reply = $client->receive();
  #
  # Loop to continue processing commands
  while ($reply) {
    my %response = from_json($reply);

    if (exists($cli_commands{$response{'cmd'}})) {
      #
      # Command is standard command
      $cli_commands{$response{'cmd'}}(\%response);
    } elsif (exists($commands{$response{'cmd'}})) {
      #
      # Command is an Op command
      $commands{$response{'cmd'}}(split('|', $response{'args'}));
    }

    $reply = $client->receive();
  }
}

# Internal: Tell client to start video
#
# $video - ID of video to play
#
# Example
#
#    cli_play_video(43);
#
# Returns void.
sub cli_play_video {
  my $video = shift;
  my $video_path = "$SETTINGS{MEDIAP}/Movies/$video.mp4";
  if (-e $video_path) {
    $client_state = 'CHANGING';
    $commands{'quit_song'}();
    $commands{'quit_video'}();
    $video_thread = threads->create('play_video', $video_path);
  }
}

# Internal: Tell client to TTS a phrase
#
# %message - The message from the server, a
#            reference to a hash.
#
# Example
#
#    cli_speak(\%server_message);
#
# Returns void.
sub cli_speak {
  my %message = %{shift};
  if(exists($commands{'speak'})) {
    $commands{'speak'}($message('phrase'));
  }
}

# Internal: Client starts downloading a file.
#
# $type - Tells if file is movie or music
# $id - ID to associate with the file
# $url - Location of file to download
#
# Example:
#
#    download_file('movie', 43, 'asdf3RF3');
#
# Returns void, sends signal to server upon completion.
sub download_file {
  my $type = shift;
  my $id = shift;
  my $url = shift;

  #
  # @TODO: Add download to database, incase we stop
  #        early somehow (disconnect, power off).

  open (DWNLD, "-|", "curl -o \"$SETTINGS{MEDIAP}/tmp/$id\" $SETTINGS{SERVER}:$SETTINGS{SVRWEB}/$url");
  close(DWNLD);

  if ($type eq 'movie') {
    move("$SETTINGS{MEDIAP}/tmp/$id", "$SETTINGS{MEDIAP}/Movies/$id.mp4");
  } elsif ($type eq 'music') {
    move("$SETTINGS{MEDIAP}/tmp/$id", "$SETTINGS{MEDIAP}/Music/$id.mp3");
  }

  #
  # @TODO: Remove download from the database.

  my %dl_finish;
  $dl_finish{'cmd'} = 'FINISHDL';
  $dl_finish{'id'} = $id;
  $dl_finish{'url'} = $url;
  cli_send(to_json(\%dl_finish));
  threads->exit();
}

# Internal: Tell client to download content
#
# %response - The message from the server, a
#             reference to a hash.
#
# Example
#
#    cli_download(\%server_message);
#
# Returns void, starts a thread to process download.
sub cli_download {
  my %response = %{shift};
  my %dl_start;
  $dl_start{'cmd'} = 'STARTDL';
  $dl_start{'message'} = 'OK';

  my $dl_thread = threads->create('download_file', $response{'type'}, $response{'id'}, $response{'url'});
}

# Internal: Handshare with server
#
# %response - The message from the server, a
#             reference to a hash.
#
# Example
#
#    cli_helo(\%server_message);
#
# Returns void.
sub cli_helo {
  my %response = %{shift};
  my %auth;

  $auth{'cmd'} = 'AUTH';
  #
  # Using Net::EasyTCP can encrypt the traffic, we just want
  # to make sure clients who connect to our server are ones
  # we want, a simple way to do this is to send a message from
  # the server, then have the client hash it with a know
  # phrase.  It's simple and we might want to improve it later.
  $auth{'code'} = sha1_hex($SETTINGS{SVRPSW} . $response{'code'});

  cli_send(to_json(\%auth));
}

# Internal: Sends a list of registered commands to the
#           server.
#
# This is used by the server to determine what controls
# or features to show to people browsing the controller
# for this raspberry pi.
# So if other people use an extend this, it's not that
# difficult for people to do without changing a lot of
# internals.  We'll see how well this model works.
#
# Example
#
#    cli_send_commands();
#
# Returns void.
sub cli_send_commands {
  my %av_commands;
  $av_commands{'cmd'} = 'LIST';
  my @ar_cmds;
  my @ar_cmds_params;
  foreach my $key (keys(%commands)) {
    push(@ar_cmds, $key);
    push(@ar_cmds_params, $command_params{$key});
  }
  $av_commands{'commands'} = \@ar_cmds;
  $av_commands{'parameters'} = \@ar_cmds_params;

  cli_send(to_json(\%av_commands));
}

# Internal: Sends a pong to a ping
#
# @TODO: Check if needed...
#
# Example
#
#    cli_ping();
#
# Returns void.
sub cli_ping {
  my %pong;
  $pong{'cmd'} = 'PONG';
  cli_send(to_json(\%pong));
}

# Internal: Tells the client to close connection
#
# Example
#
#    close_connection();
#
# Returns void.
sub close_connection {
  $client->close();
}

1;
