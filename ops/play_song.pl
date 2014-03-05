my $playing_song = 0;

# Public: Starts playing a song using mpg123
#
# $file - Path to the file
#
# Example
#
#    play_song('./song.mp3');
#
# Returns void
sub play_song {
  my $file = shift;
  #
  # Make sure the file exists
  if (-e $file) {
    if ($playing_song) {
      quit_song();
    }

    local $SIG{'STOP'} = sub { print "Pause\n"; };
    local $SIG{'CONT'} = sub { print "Resume\n"; };
    #
    # By using open and close, we can wait for
    # the process to finish running.
    open (PROC, "-|", "mpg123 \"$file\"");
    $playing_song = 1;
    close(PROC);
    $playing_song = 0;
  }
  threads->exit;
}

# Public: Pauses the song
#
# Example
#
#    pause_song();
#
# Returns void
sub pause_song {
  if ($playing_song) {
    `pkill -STOP mpg123`;
  }
}

# Public: Resumes playing of song
#
# Example
#
#    resume_song();
#
# Returns void
sub resume_song {
  if ($playing_song) {
    `pkill -CONT mpg123`;
  }
}

# Public: Quits song playback
#
# Example
#
#    quit_song();
#
# Returns void
sub quit_song {
  #
  # We don't check if we're currently
  # playing in case there was a miss
  # communication somwhere, or someone
  # started playing media in the wrong
  # way.
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
