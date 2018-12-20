package Koha::REST::V1::Acquisitions::Funds;

# This file is part of Koha.
#
# Koha is free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free Software
# Foundation; either version 3 of the License, or (at your option) any later
# version.
#
# Koha is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Koha; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

use Modern::Perl;

use Mojo::Base 'Mojolicious::Controller';

use Koha::Acquisition::Funds;

=head1 API

=head2 Class Methods

=head3 list

    Controller function that handles listing Koha::Acquisition::Funds objects

=cut

sub list {
    my $c = shift->openapi->valid_input or return;

    my @funds = Koha::Acquisition::Funds->search;
    @funds = map { _to_api($_) } @funds;

    return $c->render( status => 200, openapi => \@funds);
}

=head3 _to_api

    Helper function to ensure the API returns property names that refer
    to "fund" rather than "budget"

=cut

sub _to_api {
    my $fund = shift;

    my $fund_hash = $fund->unblessed;

    my %out;
    while (my ($key, $value) = each %{$fund_hash}) {
        $key=~s/budget/fund/g;
        $out{$key} = $value;
    }

    return \%out;
}

1;
