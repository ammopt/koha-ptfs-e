package Koha::REST::V1::Acquisitions::Invoices;

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

use Koha::Acquisition::Invoices;

use Try::Tiny;

=head1 NAME

Koha::REST::V1::Acquisitions::Invoices

=head1 API

=head2 Methods

#=head3 add_invoice
#
#Controller function that handles adding a new Koha::Acquisition::Invoice object
#
#=cut
#
#sub add_invoice {
#    my $c = shift->openapi->valid_input or return;
#
#    my $invoice = Koha::Acquisition::Invoice->new(
#        _to_model( $c->validation->param('body') ) );
#
#    return try {
#        $invoice->store;
#        return $c->render(
#            status  => 200,
#            openapi => _to_api( $invoice->TO_JSON )
#        );
#    }
#    catch {
#        if ( $_->isa('DBIx::Class::Exception') ) {
#            return $c->render(
#                status  => 500,
#                openapi => { error => $_->msg }
#            );
#        }
#        else {
#            return $c->render(
#                status  => 500,
#                openapi => { error => "Something went wrong, check the logs." }
#            );
#        }
#    };
#}

=head3 add_invoice_line

Method for adding an invoice line to an invoice

=cut

sub add_invoice_line {
    my $c         = shift->openapi->valid_input or return;
    my $invoiceID = $c->param('invoice_id');
    my $orderID   = $c->param('order_id');
    my $invoice_line = $c->param('data');
    $invoice_line->{aqinvoices_invoiceid} = $invoiceID;
    $invoice_line->{aqinvoices_ordernumber} = $orderID;

    my $insert = Koha::Acquisition::Invoice::Line->new($invoice_line);

    return try {
        $insert->store;
        return $c->render(
            status  => 200,
            openapi => _to_api( $insert->TO_JSON )
        );
    }
    catch {
        if ( $_->isa('DBIx::Class::Exception') ) {
            return $c->render(
                status  => 500,
                openapi => { error => $_->msg }
            );
        }
        else {
            return $c->render(
                status  => 500,
                openapi => { error => "Something went wrong, check the logs." }
            );
        }
    };
}

#=head3 get_invoice_lines_by_order
#
#Conroller function that handles listing Koha::Acquisition::Invoice:Line objects
#
#=cut
#
#sub get_invoice_lines_by_order {
#    my $c         = shift->openapi->valid_input or return;
#    my $invoiceID = $c->param('invoice_id');
#    my $orderID   = $c->param('order_id');
#
#    my @invoice_lines;
#    return try {
#        @invoice_lines = Koha::Acquisition::Invoices->search(
#            {
#                aqorders_ordernumber => $orderID,
#                aqinvoices_invoiceid => $invoiceID
#            }
#        )->as_list;
#
#        return $c->render( status => 200, openapi => \@invoice_lines );
#
#    }
#    catch {
#        if ( $_->isa('DBIx::Class::Exception') ) {
#            return $c->render(
#                status  => 500,
#                openapi => { error => $_->{msg} }
#            );
#        }
#        else {
#            return $c->render(
#                status  => 500,
#                openapi => { error => "Something went wrong, check the logs." }
#            );
#        }
#    };
#}

#=head3 list_vendor_invoices
#
#Controller function that handles listing Koha::Acquisition::Invoice objects
#
#=cut
#
#sub list_vendor_invoices {
#    my $c = shift->openapi->valid_input or return;
#
#    my $filter;
#
#    my @invoices;
#    return try {
#        @invoices = Koha::Acquisition::Invoice::Lines->search($filter);
#        @invoices = map { $_->TO_JSON } @invoices;
#        return $c->render(
#            status  => 200,
#            openapi => \@invoices
#        );
#    }
#    catch {
#        if ( $_->isa('DBIx::Class::Exception') ) {
#            return $c->render(
#                status  => 500,
#                openapi => { error => $_->{msg} }
#            );
#        }
#        else {
#            return $c->render(
#                status  => 500,
#                openapi => { error => "Something went wrong, check the logs." }
#            );
#        }
#    };
#}

#=head3 get_invoice
#
#Controller function that handles retrieving a single Koha::Acquisition::Invoice
#
#=cut
#
#sub get_invoice {
#    my $c = shift->openapi->valid_input or return;
#
#    my $invoice =
#      Koha::Acquisition::Invoices->find( $c->validation->param('invoice_id') );
#    unless ($invoice) {
#        return $c->render(
#            status  => 404,
#            openapi => { error => "Invoice not found" }
#        );
#    }
#
#    return $c->render(
#        status  => 200,
#        openapi => _to_api( $invoice->TO_JSON )
#    );
#}

#=head3 update_invoice
#
#Controller function that handles updating a Koha::Acquisition::Invoice object
#
#=cut
#
#sub update_invoice {
#    my $c = shift->openapi->valid_input or return;
#
#    my $invoice;
#
#    return try {
#        $invoice = Koha::Acquisition::Invoices->find(
#            $c->validation->param('invoice_id') );
#        $invoice->set( _to_model( $c->validation->param('body') ) );
#        $invoice->store();
#        return $c->render(
#            status  => 200,
#            openapi => _to_api( $invoice->TO_JSON )
#        );
#    }
#    catch {
#        if ( not defined $invoice ) {
#            return $c->render(
#                status  => 404,
#                openapi => { error => "Object not found" }
#            );
#        }
#        elsif ( $_->isa('Koha::Exceptions::Object') ) {
#            return $c->render(
#                status  => 500,
#                openapi => { error => $_->message }
#            );
#        }
#        else {
#            return $c->render(
#                status  => 500,
#                openapi => { error => "Something went wrong, check the logs." }
#            );
#        }
#    };
#
#}

#=head3 delete_invoice
#
#Controller function that handles deleting a Koha::Acquisition::Invoice object
#
#=cut
#
#sub delete_invoice {
#    my $c = shift->openapi->valid_input or return;
#
#    my $invoice;
#
#    return try {
#        $invoice = Koha::Acquisition::Invoices->find(
#            $c->validation->param('invoice_id') );
#        $invoice->delete;
#        return $c->render(
#            status  => 200,
#            openapi => q{}
#        );
#    }
#    catch {
#        if ( not defined $invoice ) {
#            return $c->render(
#                status  => 404,
#                openapi => { error => "Object not found" }
#            );
#        }
#        elsif ( $_->isa('DBIx::Class::Exception') ) {
#            return $c->render(
#                status  => 500,
#                openapi => { error => $_->msg }
#            );
#        }
#        else {
#            return $c->render(
#                status  => 500,
#                openapi => { error => "Something went wrong, check the logs." }
#            );
#        }
#    };
#
#}

=head3 _to_api

Helper function that maps unblessed Koha::Account::Line objects
into REST API attribute names.

=cut

sub _to_api {
    my $account_line = shift;

    # Rename attributes
    foreach my $column ( keys %{ $Koha::REST::V1::Patrons::Account::to_api_mapping } ) {
        my $mapped_column = $Koha::REST::V1::Patrons::Account::to_api_mapping->{$column};
        if (    exists $account_line->{ $column }
             && defined $mapped_column )
        {
            # key != undef
            $account_line->{ $mapped_column } = delete $account_line->{ $column };
        }
        elsif (    exists $account_line->{ $column }
                && !defined $mapped_column )
        {
            # key == undef
            delete $account_line->{ $column };
        }
    }

    return $account_line;
}

=head3 _to_model

Helper function that maps REST API objects into Koha::Account::Line
attribute names.

=cut

sub _to_model {
    my $account_line = shift;

    foreach my $attribute ( keys %{ $Koha::REST::V1::Patrons::Account::to_model_mapping } ) {
        my $mapped_attribute = $Koha::REST::V1::Patrons::Account::to_model_mapping->{$attribute};
        if (    exists $account_line->{ $attribute }
             && defined $mapped_attribute )
        {
            # key => !undef
            $account_line->{ $mapped_attribute } = delete $account_line->{ $attribute };
        }
        elsif (    exists $account_line->{ $attribute }
                && !defined $mapped_attribute )
        {
            # key => undef / to be deleted
            delete $account_line->{ $attribute };
        }
    }

    return $account_line;
}

=head2 Global variables

=head3 $to_api_mapping

=cut

our $to_api_mapping = {
    accountlines_id   => 'account_line_id',
    accountno         => undef,                  # removed
    accounttype       => 'account_type',
    amountoutstanding => 'amount_outstanding',
    borrowernumber    => 'patron_id',
    dispute           => undef,
    issue_id          => 'checkout_id',
    itemnumber        => 'item_id',
    manager_id        => 'user_id',
    note              => 'internal_note',
};

=head3 $to_model_mapping

=cut

our $to_model_mapping = {
    account_line_id    => 'accountlines_id',
    account_type       => 'accounttype',
    amount_outstanding => 'amountoutstanding',
    checkout_id        => 'issue_id',
    internal_note      => 'note',
    item_id            => 'itemnumber',
    patron_id          => 'borrowernumber',
    user_id            => 'manager_id'
};

1;
