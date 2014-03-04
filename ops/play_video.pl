use POSIX;

my $playing_video = 0;

sub play_video {
  my $file = shift;

  if ($playing_video) {
    `killall omxplayer`;
  }

  if (-e "$SETTINGS{MEDIAP}/omx") {
    unlink("$SETTINGS{MEDIAP}/omx");
  }

  mkfifo ("$SETTINGS{MEDIAP}/omx", 0777);
  open(VIDPLYR, "|-", "omxplayer $SETTINGS{OMXOPS} \"$file\" < $SETTINGS{MEDIAP}/omx &");
  `echo -n . > "$SETTINGS{MEDIAP}/omx"`;
  $playing_video = 1;
  close(VIDPLYR);
  $playing_video = 0;
  if (-e "$SETTINGS{MEDIAP}/omx") {
    unlink("$SETTINGS{MEDIAP}/omx");
  }
  threads->exit;
}

sub pause_video {
  if ($playing_video && -e "$SETTINGS{MEDIAP}/omx") {
    `echo -n p > "$SETTINGS{MEDIAP}/omx"`;
  }
}

sub resume_video {
  if ($playing_video && -e "$SETTINGS{MEDIAP}/omx") {
    `echo -n p > "$SETTINGS{MEDIAP}/omx"`;
  }
}

sub forward_video {
  if ($playing_video && -e "$SETTINGS{MEDIAP}/omx") {
    `echo -n \$'\x1b\x5b\x43' > "$SETTINGS{MEDIAP}/omx"`;
  }
}

sub rewind_video {
  if ($playing_video && -e "$SETTINGS{MEDIAP}/omx") {
    `echo -n \$'\x1b\x5b\x44' > "$SETTINGS{MEDIAP}/omx"`;
  }
}

sub quit_video {
  if ($playing_video && -e "$SETTINGS{MEDIAP}/omx") {
    `echo -n q > "$SETTINGS{MEDIAP}/omx"`;
  }
  `killall omxplayer`;
  `killall omxplayer.bin`;
  if (-e "$SETTINGS{MEDIAP}/omx") {
    unlink("$SETTINGS{MEDIAP}/omx");
  }
  $playing_video = 0;
}

$commands{'play_video'} = \&play_video;
$command_params{'play_video'} = "Path:str";
$commands{'pause_video'} = \&pause_video;
$command_params{'pause_video'} = "";
$commands{'resume_video'} = \&resume_video;
$command_params{'resume_video'} = "";
$commands{'forward_video'} = \&forward_video;
$command_params{'forward_video'} = "";
$commands{'rewind_video'} = \&rewind_video;
$command_params{'rewind_video'} = "";
$commands{'quit_video'} = \&quit_video;
$command_params{'quit_video'} = "";

1;
