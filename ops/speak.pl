sub speak {
  my $phrase = shift;
  `espeak "$phrase"`;
}

$commands{'speak'} = \&speak;
$command_params{'speak'} = "Phrase:str";

1;
