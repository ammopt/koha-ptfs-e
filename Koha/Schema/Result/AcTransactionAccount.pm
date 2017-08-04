use utf8;
package Koha::Schema::Result::AcTransactionAccount;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Koha::Schema::Result::AcTransactionAccount

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<ac_transaction_accounts>

=cut

__PACKAGE__->table("ac_transaction_accounts");

=head1 ACCESSORS

=head2 accountline_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 transaction_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 status

  data_type: 'tinyint'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "accountline_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "transaction_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "status",
  { data_type => "tinyint", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</transaction_id>

=back

=cut

__PACKAGE__->set_primary_key("accountline_id", "transaction_id");

=head1 RELATIONS

=head2 accountline

Type: belongs_to

Related object: L<Koha::Schema::Result::Accountline>

=cut

__PACKAGE__->belongs_to(
  "accountline",
  "Koha::Schema::Result::Accountline",
  { accountlines_id => "accountline_id" },
  { is_deferrable => 1, on_delete => "RESTRICT", on_update => "RESTRICT" },
);

=head2 transaction

Type: belongs_to

Related object: L<Koha::Schema::Result::AcTransaction>

=cut

__PACKAGE__->belongs_to(
  "transaction",
  "Koha::Schema::Result::AcTransaction",
  { transaction_id => "transaction_id" },
  { is_deferrable => 1, on_delete => "RESTRICT", on_update => "RESTRICT" },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2015-06-25 22:19:49
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:LaUhuRjFbx54yZQeeWqsKw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
