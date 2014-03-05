# Public: Makes Pi say a phrase
#
# $phrase - The sentence to say out loud
#
# Example
#
#    speak('Miles is  sexy');
#
# Returns void.
sub speak {
  my $phrase = shift;
  `espeak "$phrase"`;
}

$commands{'speak'} = \&speak;
$command_params{'speak'} = "Phrase:str";

1;
