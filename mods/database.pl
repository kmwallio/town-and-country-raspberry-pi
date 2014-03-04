use DBI;

my $dbh;
if (-e "$SETTINGS{MEDIAP}/cli.db") {
  $dbh = DBI->connect("dbi:SQLite:dbname=$SETTINGS{MEDIAP}/cli.db", "", "");
} else {
  $dbh = DBI->connect("dbi:SQLite:dbname=$SETTINGS{MEDIAP}/cli.db", "", "");
  install_cli_db();
}

sub get_song {
}

sub queue_song {
}

sub dequeue_song {
}

sub clear_song_queue {
}

sub get_movie {
}

sub get_default_playlist {
}

sub set_default_playlist {
}

sub add_playlist {
}

sub remove_song_from_playlist {
}

sub remove_song {
}

sub remove_movie {
}

sub add_movie {
}

sub add_song_to_playlist {
}

sub add_song {
}

sub install_cli_db {
}

sub verify_db {
}

1;
