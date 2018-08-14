package C4::Linker::BestMatch;

# Copyright 2011 C & P Bibliography Services
#
# This file is part of Koha.
#
# Koha is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# Koha is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Koha; if not, see <http://www.gnu.org/licenses>.

use strict;
use warnings;
use Carp;
use C4::Heading;
use C4::AuthoritiesMarc;
use C4::Linker::Default;    # Use Default for flipping

use base qw(C4::Linker);

sub new {
    my $class = shift;
    my $param = shift;

    my $self = $class->SUPER::new($param);
    $self->{'default_linker'} = C4::Linker::Default->new($param);
    bless $self, $class;
    return $self;
}

sub get_link {
    my $self        = shift;
    my $heading     = shift;
    my $search_form = $heading->search_form();
    my $authid;
    my $fuzzy = 0;

    my $fieldasstring =
      lc $heading->field()->as_string('abcdefghijklmnopqrstuvwxyz');

    # Remove subdivisions - they mess up our search here
    $fieldasstring =~
s/(generalsubdiv|formsubdiv|chronologicalsubdiv|geographicalsubdiv|\s|,|-|;)//g;
    $fieldasstring =~ s/&/and/g;    # Normalise to and

    if ( $self->{'cache'}->{$fieldasstring}->{'cached'} ) {
        $authid = $self->{'cache'}->{$fieldasstring}->{'authid'};
        $fuzzy  = $self->{'cache'}->{$fieldasstring}->{'fuzzy'};

        #warn "Cached result for $fieldasstring as $authid (Fuzzy: $fuzzy)";
    }
    else {
        #look for matching authorities
        my $authorities =
          $heading->authorities( 1, 9999999 );    # $skipmetadata = true
        if ( $#{$authorities} >= 0 ) {
            my %authcodes = (
                'PERSO_NAME', '100', 'CORPO_NAME', '110', 'MEETI_NAME', '111',
                'UNIF_TITLE', '130', 'CHRON_TERM', '148', 'TOPIC_TERM', '150',
                'GEOGR_NAME', '151', 'GENRE/FORM', '155', 'GEN_SUBDIV', '180',
                'GEO_SUBDIV', '181', 'CHRON_SUBD', '182', 'FORM_SUBD',  '185'
            );
            for ( my $n = 0 ; $n <= $#{$authorities} ; $n = $n + 1 ) {
                my $auth = GetAuthority( $authorities->[$n]->{'authid'} );
                my $auth_field =
                  $auth->field( $authcodes{ $heading->{'auth_type'} } );
                my $authfieldstring =
                  lc $auth->field( $authcodes{ $heading->{'auth_type'} } )
                  ->as_string('abcdefghijklmnopqrstuvwxyz');
                $authfieldstring =~
s/(generalsubdiv|formsubdiv|chronologicalsubdiv|geographicalsubdiv|\s|,|-|;)//g;
                $authfieldstring =~ s/&/and/g;
                if ( $fieldasstring eq $authfieldstring ) {
                    $authid = $authorities->[$n]->{'authid'};
                    $n = $#{$authorities} + 1;    # break out of the loop
                }
            }
            if ( !defined $authid ) {
                warn "No authority could be perfectly matched for "
                  . $heading->field()->as_string('abcdefghijklmnopqrstuvwxyz')
                  . "\n";
                $fieldasstring =~
                  s/(\d|\.)//g;    # Try alos removing full-stops and numbers
                for ( my $n = 0 ; $n <= $#{$authorities} ; $n = $n + 1 ) {
                    my $auth = GetAuthority( $authorities->[$n]->{'authid'} );
                    my $auth_field =
                      $auth->field( $authcodes{ $heading->{'auth_type'} } );
                    my $authfieldstring =
                      lc $auth->field( $authcodes{ $heading->{'auth_type'} } )
                      ->as_string('abcdefghijklmnopqrstuvwxyz');
                    $authfieldstring =~
s/(generalsubdiv|formsubdiv|chronologicalsubdiv|geographicalsubdiv|\s|\d|,|-|;|\.)//g;
                    if ( $fieldasstring eq $authfieldstring ) {
                        warn
"Fuzzy matching $fieldasstring with $authfieldstring\n";
                        $authid = $authorities->[$n]->{'authid'};
                        $fuzzy  = 1;
                        $n = $#{$authorities} + 1;    # break out of the loop
                    }
                }
            }
            if ( !defined $authid ) {
                warn "No match found\n";
            }
        }
        else {
            warn "No match found\n";
        }
        $self->{'cache'}->{$fieldasstring}->{'cached'} = 1;
        $self->{'cache'}->{$fieldasstring}->{'authid'} = $authid;
        $self->{'cache'}->{$fieldasstring}->{'fuzzy'}  = $fuzzy;
    }

    return $self->SUPER::_handle_auth_limit($authid), $fuzzy;
}

sub update_cache {
    my $self    = shift;
    my $heading = shift;
    my $authid  = shift;
    $self->{'default_linker'}->update_cache( $heading, $authid );
}

sub flip_heading {
    my $self    = shift;
    my $heading = shift;

    return $self->{'default_linker'}->flip($heading);
}

1;
__END__

=head1 NAME

C4::Linker::BestMatch - match against the authority record that is identical or near identical (fuzzy)

=cut
