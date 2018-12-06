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

    plan tests => 14;

    $schema->storage->txn_begin;

    # Clean up acq here to give us a clean start to test against.

    my ( $unauthorized_borrowernumber, $unauthorized_session_id ) =
      create_user_and_session( { authorized => 0 } );
    my ( $authorized_borrowernumber, $authorized_session_id ) =
      create_user_and_session( { authorized => 1 } );

    # Add Order to test against
    my $basket = $builder->build_object(
        {
            class => 'Koha::Acquisition::Baskets'
        }
    )->store;
    $basket->discard_changes;
    my $order = $builder->build_object(
        {
            class => 'Koha::Acquisition::Orders',
            value => { basketno => $basket->basketno }
        }
    )->store;
    $order->discard_changes;
    my $order_id = $order->ordernumber;

    # Add Invoice to test against
    my $invoice = $builder->build_object(
        {
            class => 'Koha::Acquisition::Invoices',
        },
    );
    $invoice->discard_changes;
    $order->invoiceid( $invoice->invoiceid )->store;
    $order->discard_changes;
    $invoice->discard_changes;
    my $invoice_id   = $invoice->invoiceid;
    my $budget_id    = undef;
    my $invoice_line = {
        "order_id"        => $order_id,
        "budget"          => $budget_id,
        "description"     => "",
        "discount_amount" => 1,
        "discount_rate"   => 79,
        "id"              => undef,
        "list_price"      => 17.23,
        "pre_tax_amount"  => 12.38,
        "quantity"        => 1,
        "tax_amount"      => 7.23,
        "tax_rate"        => 4,
        "total_price"     => 89.73,
        "item_type"       => undef,
    };

    # Unauthenticated attempt to add invoice line
    my $tx =
      $t->ua->build_tx(
        POST   => "/api/v1/acquisitions/invoices/$invoice_id/lines" =>
          json => $invoice_line );
    $tx->req->env( { REMOTE_ADDR => $remote_address } );
    $t->request_ok($tx)->status_is(401);

    # Unauthorized attempt to add invoice line
    $tx =
      $t->ua->build_tx(
        POST   => "/api/v1/acquisitions/invoices/$invoice_id/lines" =>
          json => $invoice_line );
    $tx->req->cookies(
        { name => 'CGISESSID', value => $unauthorized_session_id } );
    $tx->req->env( { REMOTE_ADDR => $remote_address } );
    $t->request_ok($tx)->status_is(403);

    # Authorized attempt to add invoice lines (with a bad invoice id)
    $tx =
      $t->ua->build_tx( POST => "/api/v1/acquisitions/invoices/1/lines" =>
          json => $invoice_line );
    $tx->req->cookies(
        { name => 'CGISESSID', value => $authorized_session_id } );
    $tx->req->env( { REMOTE_ADDR => $remote_address } );
    $t->request_ok($tx)->status_is( 404, "Invoice Not Found" );

    # Authorized attempt to add invoice lines (with a bad order id)
    $invoice_line->{order_id} = 54321;
    $tx =
      $t->ua->build_tx(
        POST   => "/api/v1/acquisitions/invoices/$invoice_id/lines" =>
          json => $invoice_line );
    $tx->req->cookies(
        { name => 'CGISESSID', value => $authorized_session_id } );
    $tx->req->env( { REMOTE_ADDR => $remote_address } );
    $t->request_ok($tx)->status_is(400)->json_is(
        '/error' => 'Referenced order not found',
        'Referenced order not found'
    );
    $invoice_line->{order_id} = $order_id;

    # Authorized attempt to add invoice lines (with a bad budget id)
    $invoice_line->{budget} = 12345;
    $tx =
      $t->ua->build_tx(
        POST   => "/api/v1/acquisitions/invoices/$invoice_id/lines" =>
          json => $invoice_line );
    $tx->req->cookies(
        { name => 'CGISESSID', value => $authorized_session_id } );
    $tx->req->env( { REMOTE_ADDR => $remote_address } );
    $t->request_ok($tx)->status_is(400)->json_is(
        '/error' => 'Referenced budget not found',
        'Referenced budget not found'
    );
    $invoice_line->{budget} = undef;

    # Authorized attempt to add invoice lines (success)
    $tx =
      $t->ua->build_tx(
        POST   => "/api/v1/acquisitions/invoices/$invoice_id/lines" =>
          json => $invoice_line );
    $tx->req->cookies(
        { name => 'CGISESSID', value => $authorized_session_id } );
    $tx->req->env( { REMOTE_ADDR => $remote_address } );
    $t->request_ok($tx)->status_is(200);

    $schema->storage->txn_rollback;
};

sub create_user_and_session {

    my $args = shift;
    my $flags = ( $args->{authorized} ) ? 2052 : 0;

    # my $flags = ( $args->{authorized} ) ? $args->{authorized} : 0;
    my $dbh = C4::Context->dbh;

    my $user = $builder->build(
        {
            source => 'Borrower',
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
