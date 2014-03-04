my $playing_song = 0;

sub play_song {
  my $file = shift;
  if ($playing_song) {
    quit_song();
  }

  local $SIG{'STOP'} = sub { print "Pause\n"; };
  local $SIG{'CONT'} = sub { print "Resume\n"; };
  open (PROC, "-|", "mpg123 \"$file\"");
  $playing_song = 1;
  close(PROC);
  $playing_song = 0;
  threads->exit;
}

sub pause_song {
  `pkill -STOP mpg123`;
}

sub resume_song {
  `pkill -CONT mpg123`;
}

sub quit_song {
  `killall mpg123`;
  $playing_song = 0;
}

$commands{'play_song'} = \&play_song;
$command_params{'play_song'} = "Path:str";
$commands{'pause_song'} = \&pause_song;
$command_params{'pause_song'} = "";
$commands{'resume_song'} = \&resume_song;
$command_params{'resume_song'} = "";
$commands{'quit_song'} = \&quit_song;
$command_params{'quit_song'} = "";

1;
