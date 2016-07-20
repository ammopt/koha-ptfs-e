#!/usr/bin/perl

use strict;
use warnings;
use Text::SpellChecker;
use JSON;
use CGI;
use Data::Dumper;

# Keep taint mode happy
$ENV{PATH} = "/bin";

my $q = CGI->new();

my $qs = $q->param('spellcheck');

my %misses = ();

my $checker = Text::SpellChecker->new(text => $qs);

while (my $word = $checker->next_word) {
  my $sugg = $checker->suggestions;
  $misses{$word} = $sugg;
}

my $json = JSON::encode_json({ suggestions => \%misses });

print "Content-type: application/json\n\n";
print $json;
