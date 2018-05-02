#!/usr/bin/perl
use strict;
use warnings;
use FindBin qw( $Bin );

use Test::More;
use Test::DBIx::Class;

use_ok('Koha::Edifact::Transport');

my $t = Koha::Edifact::Transport->new(1);

isa_ok($t,'Koha::Edifact::Transport');

fixtures_ok [
    EdifactMessage => [
        [ 'id', 'message_type', 'filename' ],
        [ 9000, 'TEST', 'duplicatefilename' ],
    ],
], 'Installed fixtures';

#ok ResultSet('EdifactMessage'), "Some messages";
#ok ResultSet( EdifactMessage => { filename=>{ '=' => 'duplicatefilename' }}), "Got a dup";

#$t->ingest( {}, 'duplicatefilename' );


done_testing();
