package Koha::Acquisition::Invoice::Line;

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

use Carp;

use Koha::Database;

use base qw(Koha::Object);

=head1 NAME

Koha::Acquisition::Invoice::Line - Koha Invoice Line class

=head1 API

=head2 Class Methods

=head3 order

my $order = $invoice_line->order

Return the order associated with this invoice line

=cut

sub order {
    my ($self) = @_;
    return Koha::Acquisition::Order->_new_from_dbic(
        $self->_result->aqorders_ordernumber );
}

=head3 store

Order line specific store method to ensure orders are updated

=cut

sub store {
    my ($self) = @_;

    $self->_result->result_source->schema->txn_do(
        sub {

            if ( $self->aqorders_ordernumber ) {
                my $order = $self->order;

                # Check order present
                unless ( $order->in_storage ) {
                    Koha::Exceptions::Object::FKConstraint->throw(
                        broken_fk => 'ordernumber',
                        value     => $self->aqorders_ordernumber,
                    );
                }

                # Store invoice line
                $self = $self->SUPER::store;

                # Update order line
                if ( $self->pre_tax_price || $self->total_price ) {
                    my $total_pre_tax =
                      $order->_result->aqinvoice_lines->get_column(
                        'pre_tax_price')->sum_rs->as_query;
                    my $total_post_tax =
                      $order->_result->aqinvoice_lines->get_column(
                        'total_price')->sum_rs->as_query;
                    $order->_result->update(
                        {
                            tax_rate_on_receiving  => undef,
                            unitprice_tax_excluded => $total_pre_tax,
                            unitprice_tax_included => $total_post_tax
                        }
                    );
                }

            }
            else {
                $self = $self->SUPER::store;
            }
        }
    );

    return $self;
}

=head3 delete

$invoice_line->delete

Delete invoice with trigger to update order line

=cut

sub delete {
    my ($self) = @_;

    my $deleted;
    $self->_result->result_source->schema->txn_do(
        sub {
            if ( $self->aqorders_ordernumber ) {
                my $order = $self->order;

                # Check order present
                unless ( $order->in_storage ) {
                    Koha::Exceptions::Object::FKConstraint->throw(
                        broken_fk => 'ordernumber',
                        value     => $self->aqorders_ordernumber,
                    );
                }

                # Delete the invoice line
                $deleted = $self->SUPER::delete;

                # Update the order line
                if ( $self->pre_tax_price || $self->total_price ) {
                    my $total_pre_tax =
                      $order->_result->aqinvoice_lines->get_column(
                        'pre_tax_price')->sum_rs->as_query;
                    my $total_post_tax =
                      $order->_result->aqinvoice_lines->get_column(
                        'total_price')->sum_rs->as_query;
                    $order->_result->update(
                        {
                            tax_rate_on_receiving  => undef,
                            unitprice_tax_excluded => $total_pre_tax,
                            unitprice_tax_included => $total_post_tax
                        }
                    );
                }

            }
            else {
                $deleted = $self->SUPER::delete;
            }
        }
    );

    return $deleted;
}

=head3 type

=cut

sub _type {
    return 'AqinvoiceLine';
}

1;
