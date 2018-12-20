package Koha::REST::V1::Acquisitions::Invoice::Lines;

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

use Koha::Acquisition::Invoice::Lines;

use Try::Tiny;

=head1 NAME

Koha::REST::V1::Acquisitions::Invoice::Lines

=head1 API

=head2 Methods

=head3 add_invoice_line

Method for adding an invoice line to an invoice

=cut

sub add_invoice_line {
    my $c = shift->openapi->valid_input or return;

    my $invoice_line = _to_model( $c->validation->param('body') );

    # Add invoiceid
    $invoice_line->{aqinvoices_invoiceid} = $c->validation->param('invoice_id');

    # Check invoice existance
    my $invoice = Koha::Acquisition::Invoices->find(
        $invoice_line->{aqinvoices_invoiceid} );
    unless ($invoice) {
        return $c->render(
            status  => 404,
            openapi => { error => "Invoice not found" }
        );
    }

    my $insert = Koha::Acquisition::Invoice::Line->new($invoice_line);

    return try {
        $insert->store;
        return $c->render(
            status  => 200,
            openapi => _to_api( $insert->TO_JSON )
        );
    }
    catch {
        if ( $_->isa('Koha::Exceptions::Object::FKConstraint') ) {
            if ( $_->broken_fk eq 'aqorders_ordernumber' ) {
                return $c->render(
                    status  => 400,
                    openapi => { error => "Referenced order not found" }
                );
            }
            elsif ( $_->broken_fk eq 'aqbudgets_budgetid' ) {
                return $c->render(
                    status  => 400,
                    openapi => { error => "Referenced budget not found" }
                );
            }
            else {
                return $c->render(
                    status  => 400,
                    openapi => { error => $_->message }
                );
            }
        }
        elsif ( $_->isa('DBIx::Class::Exception') ) {
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

=head3 list_invoice_lines

Method for retrieving Koha::Acquisition::Invoice:Line objects

=cut

sub list_invoice_lines {
    my $c         = shift->openapi->valid_input or return;
    my $invoiceID = $c->validation->param('invoice_id');
    my $orderID   = $c->validation->param('order_id');

    # Check invoice existance
    my $invoice = Koha::Acquisition::Invoices->find($invoiceID);
    unless ($invoice) {
        return $c->render(
            status  => 404,
            openapi => { error => "Invoice not found" }
        );
    }

    return try {
        my @invoice_lines = $invoice->lines->search(
            {
                (
                    defined($orderID)
                    ? ( aqorders_ordernumber => $orderID )
                    : ()
                )
            }
        )->as_list;
        @invoice_lines = map { _to_api( $_->TO_JSON ) } @invoice_lines;

        return $c->render( status => 200, openapi => \@invoice_lines );
    }
    catch {
        if ( $_->isa('DBIx::Class::Exception') ) {
            return $c->render(
                status  => 500,
                openapi => { error => $_->{msg} }
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

=head3 update_invoice_line

Controller function that handles updating a Koha::Acquisition::Invoice::Line object

=cut

sub update_invoice_line {
    my $c         = shift->openapi->valid_input or return;
    my $invoiceID = $c->validation->param('invoice_id');
    my $lineID    = $c->validation->param('line_id');

    # Check invoice_line existance
    my $invoice_line = Koha::Acquisition::Invoice::Lines->find($lineID);
    unless ($invoice_line) {
        return $c->render(
            status  => 404,
            openapi => { error => "Object not found" }
        );
    }

    return try {

        # Check invoice_line identified belongs to identified invoice.
        unless ( $invoice_line->aqinvoices_invoiceid == $invoiceID ) {
            return $c->render(
                status  => 400,
                openapi => {
                    error =>
"Identified invoice line does not belong to identified invoice"
                }
            );
        }

        # Update invoice line
        $invoice_line->set( _to_model( $c->validation->param('body') ) );
        $invoice_line->store();
        return $c->render(
            status  => 200,
            openapi => _to_api( $invoice_line->TO_JSON )
        );
    }
    catch {
        if ( $_->isa('Koha::Exceptions::Object') ) {
            return $c->render(
                status  => 500,
                openapi => { error => $_->message }
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

=head3 delete_invoice_line

Controller function that handles deleting a Koha::Acquisition::Invoice::Line object

=cut

sub delete_invoice_line {
    my $c         = shift->openapi->valid_input or return;
    my $invoiceID = $c->validation->param('invoice_id');
    my $lineID    = $c->validation->param('line_id');

    # Check invoice_line existance
    my $invoice_line = Koha::Acquisition::Invoice::Lines->find($lineID);
    unless ($invoice_line) {
        return $c->render(
            status  => 404,
            openapi => { error => "Object not found" }
        );
    }

    return try {

        # Check invoice_line identified belongs to identified invoice.
        unless ( $invoice_line->aqinvoices_invoiceid == $invoiceID ) {
            return $c->render(
                status  => 400,
                openapi => {
                    error =>
"Identified invoice line does not belong to identified invoice"
                }
            );
        }

        # Delete invoice line
        $invoice_line->delete;
        return $c->render(
            status  => 204,
            openapi => {}
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

=head3 _to_api

Helper function that maps unblessed Koha::Account::Lines objects
into REST API attribute names.

=cut

sub _to_api {
    my $invoice_line = shift;

    # Rename attributes
    foreach my $column (
        keys %{$Koha::REST::V1::Acquisitions::Invoice::Lines::to_api_mapping} )
    {
        my $mapped_column =
          $Koha::REST::V1::Acquisitions::Invoice::Lines::to_api_mapping
          ->{$column};
        if ( exists $invoice_line->{$column}
            && defined $mapped_column )
        {
            # key != undef
            $invoice_line->{$mapped_column} = delete $invoice_line->{$column};
        }
        elsif ( exists $invoice_line->{$column}
            && !defined $mapped_column )
        {
            # key == undef
            delete $invoice_line->{$column};
        }
    }

    return $invoice_line;
}

=head3 _to_model

Helper function that maps REST API objects into Koha::Account::Lines
attribute names.

=cut

sub _to_model {
    my $invoice_line = shift;

    foreach my $attribute (
        keys %{$Koha::REST::V1::Acquisitions::Invoice::Lines::to_model_mapping}
      )
    {
        my $mapped_attribute =
          $Koha::REST::V1::Acquisitions::Invoice::Lines::to_model_mapping
          ->{$attribute};
        if ( exists $invoice_line->{$attribute}
            && defined $mapped_attribute )
        {
            # key => !undef
            $invoice_line->{$mapped_attribute} =
              delete $invoice_line->{$attribute};
        }
        elsif ( exists $invoice_line->{$attribute}
            && !defined $mapped_attribute )
        {
            # key => undef / to be deleted
            delete $invoice_line->{$attribute};
        }
    }

    return $invoice_line;
}

=head2 Global variables

=head3 $to_model_mapping

=cut

our $to_model_mapping = {
    id              => 'id',
    order_id        => 'aqorders_ordernumber',
    budget          => 'aqbudgets_budgetid',
    item_type       => 'item_type',
    description     => 'description',
    quantity        => 'quantity',
    list_price      => 'list_price',
    discount_rate   => 'discount_rate',
    discount_amount => 'discount_amount',
    pre_tax_amount  => 'pre_tax_price',
    tax_rate        => 'tax_rate',
    tax_amount      => 'tax_amount',
    total_price     => 'total_price'
};

=head3 $to_api_mapping

=cut

our $to_api_mapping = { reverse %{$to_model_mapping} };

1;
