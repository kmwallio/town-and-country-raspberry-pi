# This is the music management player
# It starts up the default playlist,
# switches playlists, adds other music
# to the queue, and yeah.

# We only support shuffling for now.

my $Playlist = get_default_playlist();
my $music_thread = 0;
sub start_music {
  # Make sure we're not already playing...
  if (!$music_thread || !$music_thread->is_running()) {
    $music_thread = threads->create('play_playlist', $Playlist);
  }
}

sub play_playlist {
  my $pl = shift;
  my $last_song = -1;
  my %next_song = get_song($pl, $last_song);
  $last_song = $next_song{'id'};
  my $play_thread = threads->create('play_song', "$SETTINGS{MEDIAP}/Music/$next_song{'id'}.mp3");
  while ($play_thread->is_running()) {
    # Wait on the thread playing the song
    $play_thread->join();
    # Make sure we're in the same state
    if ($client_state eq 'MUSIC') {
      %next_song = get_song($pl, $last_song);
      $last_song = $next_song{'id'};
      $play_thread = threads->create('play_song', "$SETTINGS{MEDIAP}/Music/$next_song{'id'}.mp3");
    }
  }
  threads->exit;
}

if ($client_state eq 'MUSIC') {
  start_music();
}

1;
