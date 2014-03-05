# This is the music management player
# It starts up the default playlist,
# switches playlists, adds other music
# to the queue, and yeah.

# We only support shuffling for now.

my $Playlist = get_default_playlist();

# Internal: Starts music player thread using the
#           playlist in $Playlist
#
# Example
#
#    start_music();
#
# Returns void.
sub start_music {
  # Make sure we're not already playing...
  if (!$music_thread || !$music_thread->is_running()) {
    $music_thread = threads->create('play_playlist', $Playlist);
  }
}

# Internal: Starts playing music from a playlist
#
# $pl - The playlist to play
#
# Example
#
#    play_playlist(1);
#
# Returns void.
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

# Internal: Changes a playlist.
#
# $new_playlist - The new playlist to play
#
# Example
#
#    change_playlist(2);
#
# Returns void.
sub change_playlist {
  my $new_playlist = shift;

  if ($new_playlist) {
    $Playlist = $new_playlist;
    #
    # Change state so other's can see
    if ($client_state eq 'MUSIC') {
      $client_state = 'CHANGING';
    }

    #
    # Quit other media that's running
    $commands{'quit_song'}();
    $commands{'quit_video'}();

    #
    # Start the music again
    $client_state = 'MUSIC';
    start_music();
  }
}

if ($client_state eq 'MUSIC' && $autostart) {
  start_music();
}

1;
