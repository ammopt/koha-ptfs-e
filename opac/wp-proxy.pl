#!/usr/bin/perl -wT

use strict;
use Lingua::Ispell;
use JSON;
use CGI;

# Keep taint mode happy
$ENV{PATH} = "/bin";

my $q = CGI->new();

my $qs = $q->param('spellcheck');

my %misses = ();

for my $r(Lingua::Ispell::spellcheck( $qs )) {
	if ($r->{'type'} eq 'miss') {
		$misses{$r->{'term'}} = \@{$r->{'misses'}};
	}
}

my $json = JSON::encode_json({ suggestions => \%misses });

print "Content-type: application/json\n\n";
print $json;
