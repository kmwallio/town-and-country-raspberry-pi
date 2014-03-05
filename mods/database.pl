use DBI;

our $autostart = 1;
unless (-e "$SETTINGS{MEDIAP}/cli.db") {
  install_cli_db();
  $autostart = 0;
}

# Internal: Returns handle to database
#
# Example
#
#    my $dbh = db_connect();
#
# Returns database handle
sub db_connect {
  my $dbh = DBI->connect("dbi:SQLite:dbname=$SETTINGS{MEDIAP}/cli.db", "", "", {AutoCommit => 1});
  return $dbh;
}

# Internal: Gets a song from the specified playlist
#
# $playlist  - Playlist to choose song from, if blank,
#              we'll choose any song available
# $last_song - The last song played, so we don't play it
#              again.
#
# Example
#
#    my %song_to_play = get_song(2, 37);
#
# Returns a hash with song information.
sub get_song {
  my $playlist = shift;
  my $last_song = shift;

  #
  # Check if we've already queued a song
  my %next_song = dequeue_song();

  #
  # No queued song, pick one from the playlist
  # @TODO: It is possible a playlist only has 1 song.
  unless (%next_song) {
    my $dbh = db_connect();
    my $sth = $dbh->prepare("SELECT songs.id as id, songs.title as title, songs.artist as artist FROM songs, playlist_link WHERE songs.id=playlist_link.song_id AND songs.id<>? AND playlist_link.playlist_id=? ORDER BY RAND() LIMIT 1");
    $sth->execute($last_song, $playlist);
    %next_song = %{$sth->fetchrow_array};
    $dbh->disconnect();
  }

  return %next_song;
}

# Internal: Adds a song to the queue
#
# $song - ID of the song to queue
#
# Example
#
#    queue_song(24);
#
# Returns void.
sub queue_song {
  my $song = shift;

  my $dbh = db_connect();

  #
  # Check to make sure the song exists
  # @TODO: Probably check the DB...
  if (-e "$SETTINGS{MEDIAP}/Music/$song.mp3") {
    my $sth = $dbh->prepare("INSERT INTO song_queue (song, queue_time) VALUES (?, ?)");
    $sth->execute($song, time());
    $dbh->disconnect();
  }
}

# Internal: Remove a song from the queue
#
# Example
#
#    my %next_song = dequeue_song();
#
# Returns a hash of the song, or void.
sub dequeue_song {
  my %next_song;

  my $dbh = db_connect();

  #
  # Get the item from the queue
  my $song_ref = $dbh->selectrow_hashref("SELECT * FROM song_queue ORDER BY queue_time ASC LIMIT 1");
  if ($song_ref) {
    my %song = %{$song_ref};
    %next_song = %{$dbh->selectrow_hashref("SELECT * FROM songs WHERE id=?", undef, %song{'song'})};
    $dbh->do("DELETE FROM song_queue WHERE queue_time=? LIMIT 1", undef, %song{'queue_time'});
    $dbh->disconnect();
  }

  return %next_song;
}

# Internal: Empty song queue
#
# Example
#
#    clear_song_queue();
#
# Returns void.
sub clear_song_queue {
  my $dbh = connect_db();
  $dbh->do("DELETE FROM song_queue WHERE queue_time<>0");
  $dbh->disconnect();
}

# Internal: Get's movie info
#
# $movie_id - ID of movie in database
#
# Example
#
#    my %movie = get_movie(43);
#
# Returns a hash with movie info.
sub get_movie {
  my $movie_id = shift;

  my $dbh = connect_db();
  my %movie_info = %{$dbh->selectrow_hashref("SELECT * FROM movies WHERE id=?", undef, $movie_id)};
  $dbh->disconnect();

  return %movie_info;
}

# Internal: Get's the default playlist from the DB
#
# Example
#
#    my $playlist = get_default_playlist();
#
# Returns the default playlist id
sub get_default_playlist {
  my $dbh = connect_db();

  my ($default_playlist) = shift($dbh->selectrow_array("SELECT value FROM settings WHERE setting='default_playlist'"));

  return $default_playlist;
}

# Internal: Change the default playlist
#
# $playlist_id - New default playlist
#
# Example
#
#    set_default_platlist(3);
#
# Returns void.
sub set_default_playlist {
  #
  # @TODO: Check to see if playlist exists on device
  my $playlist_id = shift;
  my $dbh = connect_db();

  $dbh->do("UPDATE settings SET value=? WHERE setting='default_playlist'", undef, $playlist_id);

  $dbh->disconnect();
}

# Internal: Add a new playlist
#
# $playlist_id - ID of playlist
# $playlist_title - Title of Playlist
#
# Example
#
#    add_playlist(2, 'Miles\'s Jamz');
#
# Returns void.
sub add_playlist {
  my ($playlist_id, $playlist_title) = @_;

  my $dbh = connect_db();

  $dbh->do("INSERT INTO playlists (id, title) VALUES (?, ?)", undef, $playlist_id, $playlist_title);

  $dbh->disconnect();
}

# Internal: Removes a song from a playlist
#
# $song_id - ID of song
# $playlist_id - ID of playlist
#
# Example
#
#    remove_song_from_playlist(2, 2);
#
# Returns void.
sub remove_song_from_playlist {
  my ($song_id, $playlist_id) = @_;

  my $dbh = connect_db();
  $dbh->do("DELETE FROM playlist_link WHERE song_id=? AND playlist_id=?", undef, $song_id, $playlist_id);
  $dbh->disconnect();
}

# Internal: Add a song to the playlist
#
# $song_id - ID of song
# $playliat_id - ID of playlist
#
# Example
#
#    add_song_to_playlist(2, 2)
sub add_song_to_playlist {
  my ($song_id, $playlist_id) = @_;

  #
  # @TODO: We should probably actually check the DB.
  if (-e "$SETTINGS{MEDIAP}/Music/$song_id.mp3") {
    my $dbh = connect_db();
    $dbh->do("INSERT INTO playlist_link (song_id, playlist_id) VALUES (?, ?)", undef, $song_id, $playlist_id);
    $dbh->disconnect();
  }
}

# Internal: Removes a song from the pi
#
# $song_id - ID of song to remove
#
# Example
#
#    remove_song(24);
#
# Returns void.
sub remove_song {
  my $song_id = shift;

  if (-e "$SETTINGS{MEDIAP}/Music/$song_id.mp3") {
    my $dbh = connect_db();

    $dbh->do("DELETE FROM playlist_link WHERE song_id=?", undef, $song_id);
    $dbh->do("DELETE FROM songs WHERE id=?", undef, $song_id);

    unlink("$SETTINGS{MEDIAP}/Music/$song_id.mp3");
  }
}

# Internal: Removes a movie from the pi
#
# $movie_id - ID of movie to remove
#
# Example
#
#    remove_movie(43);
#
# Returns void.
sub remove_movie {
  my $movie_id = shift;

  if (-e "$SETTINGS{MEDIAP}/Movies/$movie_id.mp4") {
    my $dbh = connect_db();

    $dbh->do("DELETE FROM movies WHERE id=?", undef, $movie_id);

    unlink("$SETTINGS{MEDIAP}/Movies/$movie_id.mp4");
  }
}

# Internal: Adds movie to database
#
# $movie_id - ID of movie to add
# $movie_title - Title of movie
sub add_movie {
  my ($movie_id, $movie_title) = @_;

  if (-e "$SETTINGS{MEDIAP}/Movies/$movie_id.mp4") {
    my $dbh = connect_db();

    $dbh->do("INSERT INTO movies (id, title) VALUES (?, ?)", undef, $movie_id, $movie_title);

    $dbh->disconnect();
  }
}

# Internal: Adds song to database
#
# $song_id - ID of song
# $song_title - Title of song
# $song_artist - Song artist
#
# Example
#
#    add_song(1, 'Every New Day', 'Five Iron Frenzy');
#
# Returns void.
sub add_song {
  my ($song_id, $song_title, $song_artist) = @_;

  if (-e "$SETTINGS{MEDIAP}/Music/$song_id.mp3") {
    my $dbh = connect_db();

    $dbh->do("INSERT INTO songs (id, title, artist) VALUES (?, ?, ?)", undef, $song_id, $song_title, $song_artist);

    $dbh->disconnect();
  }
}

# Internal: Setup and install Database
#
# Example
#
#    install_cli_db();
#
# Returns void.
sub install_cli_db {
  my $dbh = connect_db();

  $dbh->do('CREATE TABLE "songs" ("id" INTEGER, "title", TEXT, "artist" TEXT);');
  $dbh->do('CREATE TABLE "movies" ("id" INTEGER, "title" TEXT);');
  $dbh->do('CREATE TABLE "playlists ("id" INTEGER, "title" TEXT);"');
  $dbh->do('CREATE TABLE "settings" ("setting" TEXT, "value" TEXT);');
  $dbh->do('CREATE TABLE "playlist_link" (playlist_id INTEGER REFERENCES "playlists" (id), song_id INTEGER REFERENCES "songs" (id));');

  $dbh->disconnect();
}

# Internal: Verify files exist for items in DB
#
# Example
#
#    verify_db();
#
# Returns void.
#sub verify_db {
#}

1;
