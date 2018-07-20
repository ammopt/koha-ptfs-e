#!/usr/bin/env perl

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

use Test::More tests => 1;
use Test::Mojo;
use Test::Warn;

use t::lib::TestBuilder;
use t::lib::Mocks;

use C4::Auth;
use Koha::Acquisition::Booksellers;
use Koha::Database;

my $schema  = Koha::Database->new->schema;
my $builder = t::lib::TestBuilder->new;

# FIXME: sessionStorage defaults to mysql, but it seems to break transaction handling
# this affects the other REST api tests
t::lib::Mocks::mock_preference( 'SessionStorage', 'tmp' );

my $remote_address = '127.0.0.1';
my $t              = Test::Mojo->new('Koha::REST::V1');

subtest 'invoice_line add() tests' => sub {

    plan tests => 0;

    $schema->storage->txn_begin;

    my ( $borrowernumber, $session_id )
        = create_user_and_session( { authorized => 1 } );

    # Unauthorized
    # Authorized
    ## Bad invoice
    ## Bad order
    ## Bad budget
    ## Success

    ## Unauthorized user test

    ## Authorized user tests
    # No vendors, so empty array should be returned
    my $tx = $t->ua->build_tx( POST => "/api/v1/acquisitions/orders/$order_id/invoices/$invoice_id/lines" );
    $tx->req->cookies( { name => 'CGISESSID', value => $session_id } );
    $tx->req->env( { REMOTE_ADDR => $remote_address } );
    $t->request_ok($tx)
      ->status_is(200)
      ->json_is( [] );

    $schema->storage->txn_rollback;
};

sub create_user_and_session {

    my $args = shift;
    my $flags = ( $args->{authorized} ) ? 2052 : 0;

    # my $flags = ( $args->{authorized} ) ? $args->{authorized} : 0;
    my $dbh = C4::Context->dbh;

    my $user = $builder->build(
        {   source => 'Borrower',
            value  => { flags => $flags }
        }
    );

    # Create a session for the authorized user
    my $session = C4::Auth::get_session('');
    $session->param( 'number',   $user->{borrowernumber} );
    $session->param( 'id',       $user->{userid} );
    $session->param( 'ip',       '127.0.0.1' );
    $session->param( 'lasttime', time() );
    $session->flush;

    if ( $args->{authorized} ) {
        $dbh->do(
            q{
            INSERT INTO user_permissions (borrowernumber,module_bit,code)
            VALUES (?,11,'vendors_manage')},
            undef, $user->{borrowernumber}
        );
    }

    return ( $user->{borrowernumber}, $session->id );
}

1;
