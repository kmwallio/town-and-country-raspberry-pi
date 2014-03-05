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

our $client = new Net::EasyTCP(
  mode => "client",
  host => $SETTINGS{SERVER},
  port => $SETTINGS{SVRPUB});

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

sub cli_play_video {
  my
}

sub cli_speak {
  my %message = %{shift};
  if(exists($commands{'speak'})) {
    $commands{'speak'}($message('phrase'));
  }
}

sub download_file {
  my $type = shift;
  my $id = shift;
  my $url = shift;

  open (DWNLD, "-|", "curl -o \"$SETTINGS{MEDIAP}/tmp/$id\" $SETTINGS{SERVER}:$SETTINGS{SVRWEB}/$url");
  close(DWNLD);

  if ($type eq 'movie') {
    move("$SETTINGS{MEDIAP}/tmp/$id", "$SETTINGS{MEDIAP}/Movies/$id.mp4");
  } elsif ($type eq 'music') {
    move("$SETTINGS{MEDIAP}/tmp/$id", "$SETTINGS{MEDIAP}/Music/$id.mp3");
  }

  # @TODO: Log download in the database.

  $dl_start{'cmd'} = 'FINISHDL';
  $dl_start{'id'} = $id;
}

sub cli_download {
  my %response = %{shift};
  my %dl_start;
  $dl_start{'cmd'} = 'STARTDL';
  $dl_start{'message'} = 'OK';

  my $dl_thread = threads->create('download_file', $response{'type'}, $response{'id'}, $response{'url'});
}

sub cli_helo {
  my %response = %{shift};
  my %auth;
  $auth{'cmd'} = 'AUTH';
  $auth{'code'} = sha1_hex($SETTINGS{SVRPSW} . $response{'code'});

  cli_send(to_json(\%auth));
}

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

sub cli_ping {
  my %pong;
  $pong{'cmd'} = 'PONG';
  cli_send(to_json(\%pong));
}

sub close_connection {
  $client->close();
}

1;
