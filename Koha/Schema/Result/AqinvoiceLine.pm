use utf8;
package Koha::Schema::Result::AqinvoiceLine;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Koha::Schema::Result::AqinvoiceLine

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<aqinvoice_lines>

=cut

__PACKAGE__->table("aqinvoice_lines");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 aqinvoices_invoiceid

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 aqorders_ordernumber

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 item_type

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 aqbudgets_budgetid

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 description

  data_type: 'mediumtext'
  is_nullable: 1

=head2 quantity

  data_type: 'integer'
  default_value: 1
  is_nullable: 0

=head2 list_price

  data_type: 'decimal'
  is_nullable: 1
  size: [28,6]

=head2 discount_rate

  data_type: 'decimal'
  is_nullable: 1
  size: [28,6]

=head2 discount_amount

  data_type: 'decimal'
  is_nullable: 1
  size: [28,6]

=head2 pre_tax_price

  data_type: 'decimal'
  is_nullable: 1
  size: [28,6]

=head2 tax_rate

  data_type: 'decimal'
  is_nullable: 1
  size: [28,6]

=head2 tax_amount

  data_type: 'decimal'
  is_nullable: 1
  size: [28,6]

=head2 total_price

  data_type: 'decimal'
  is_nullable: 1
  size: [28,6]

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "aqinvoices_invoiceid",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "aqorders_ordernumber",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "item_type",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "aqbudgets_budgetid",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "description",
  { data_type => "mediumtext", is_nullable => 1 },
  "quantity",
  { data_type => "integer", default_value => 1, is_nullable => 0 },
  "list_price",
  { data_type => "decimal", is_nullable => 1, size => [28, 6] },
  "discount_rate",
  { data_type => "decimal", is_nullable => 1, size => [28, 6] },
  "discount_amount",
  { data_type => "decimal", is_nullable => 1, size => [28, 6] },
  "pre_tax_price",
  { data_type => "decimal", is_nullable => 1, size => [28, 6] },
  "tax_rate",
  { data_type => "decimal", is_nullable => 1, size => [28, 6] },
  "tax_amount",
  { data_type => "decimal", is_nullable => 1, size => [28, 6] },
  "total_price",
  { data_type => "decimal", is_nullable => 1, size => [28, 6] },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 aqbudgets_budgetid

Type: belongs_to

Related object: L<Koha::Schema::Result::Aqbudget>

=cut

__PACKAGE__->belongs_to(
  "aqbudgets_budgetid",
  "Koha::Schema::Result::Aqbudget",
  { budget_id => "aqbudgets_budgetid" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "SET NULL",
    on_update     => "CASCADE",
  },
);

=head2 aqinvoices_invoiceid

Type: belongs_to

Related object: L<Koha::Schema::Result::Aqinvoice>

=cut

__PACKAGE__->belongs_to(
  "aqinvoices_invoiceid",
  "Koha::Schema::Result::Aqinvoice",
  { invoiceid => "aqinvoices_invoiceid" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 aqorders_ordernumber

Type: belongs_to

Related object: L<Koha::Schema::Result::Aqorder>

=cut

__PACKAGE__->belongs_to(
  "aqorders_ordernumber",
  "Koha::Schema::Result::Aqorder",
  { ordernumber => "aqorders_ordernumber" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 item_type

Type: belongs_to

Related object: L<Koha::Schema::Result::AuthorisedValue>

=cut

__PACKAGE__->belongs_to(
  "item_type",
  "Koha::Schema::Result::AuthorisedValue",
  { id => "item_type" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "SET NULL",
    on_update     => "CASCADE",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07046 @ 2019-04-04 11:26:07
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:A44JxCo3eSd6CdyEo2mOXQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
