use utf8;
package Koha::Schema::Result::Biblio;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Koha::Schema::Result::Biblio

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<biblio>

=cut

__PACKAGE__->table("biblio");

=head1 ACCESSORS

=head2 biblionumber

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 frameworkcode

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 4

=head2 author

  data_type: 'longtext'
  is_nullable: 1

=head2 title

  data_type: 'longtext'
  is_nullable: 1

=head2 unititle

  data_type: 'longtext'
  is_nullable: 1

=head2 notes

  data_type: 'longtext'
  is_nullable: 1

=head2 serial

  data_type: 'tinyint'
  is_nullable: 1

=head2 seriestitle

  data_type: 'longtext'
  is_nullable: 1

=head2 copyrightdate

  data_type: 'smallint'
  is_nullable: 1

=head2 timestamp

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: current_timestamp
  is_nullable: 0

=head2 datecreated

  data_type: 'date'
  datetime_undef_if_invalid: 1
  is_nullable: 0

=head2 abstract

  data_type: 'longtext'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "biblionumber",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "frameworkcode",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 4 },
  "author",
  { data_type => "longtext", is_nullable => 1 },
  "title",
  { data_type => "longtext", is_nullable => 1 },
  "unititle",
  { data_type => "longtext", is_nullable => 1 },
  "notes",
  { data_type => "longtext", is_nullable => 1 },
  "serial",
  { data_type => "tinyint", is_nullable => 1 },
  "seriestitle",
  { data_type => "longtext", is_nullable => 1 },
  "copyrightdate",
  { data_type => "smallint", is_nullable => 1 },
  "timestamp",
  {
    data_type => "timestamp",
    datetime_undef_if_invalid => 1,
    default_value => \"current_timestamp",
    is_nullable => 0,
  },
  "datecreated",
  { data_type => "date", datetime_undef_if_invalid => 1, is_nullable => 0 },
  "abstract",
  { data_type => "longtext", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</biblionumber>

=back

=cut

__PACKAGE__->set_primary_key("biblionumber");

=head1 RELATIONS

=head2 biblioitems

Type: has_many

Related object: L<Koha::Schema::Result::Biblioitem>

=cut

__PACKAGE__->has_many(
  "biblioitems",
  "Koha::Schema::Result::Biblioitem",
  { "foreign.biblionumber" => "self.biblionumber" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 items

Type: has_many

Related object: L<Koha::Schema::Result::Item>

=cut

__PACKAGE__->has_many(
  "items",
  "Koha::Schema::Result::Item",
  { "foreign.biblionumber" => "self.biblionumber" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 old_reserves

Type: has_many

Related object: L<Koha::Schema::Result::OldReserve>

=cut

__PACKAGE__->has_many(
  "old_reserves",
  "Koha::Schema::Result::OldReserve",
  { "foreign.biblionumber" => "self.biblionumber" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 reserves

Type: has_many

Related object: L<Koha::Schema::Result::Reserve>

=cut

__PACKAGE__->has_many(
  "reserves",
  "Koha::Schema::Result::Reserve",
  { "foreign.biblionumber" => "self.biblionumber" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 reviews

Type: has_many

Related object: L<Koha::Schema::Result::Review>

=cut

__PACKAGE__->has_many(
  "reviews",
  "Koha::Schema::Result::Review",
  { "foreign.biblionumber" => "self.biblionumber" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 tags_all

Type: has_many

Related object: L<Koha::Schema::Result::TagAll>

=cut

__PACKAGE__->has_many(
  "tags_all",
  "Koha::Schema::Result::TagAll",
  { "foreign.biblionumber" => "self.biblionumber" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 tags_indexes

Type: has_many

Related object: L<Koha::Schema::Result::TagsIndex>

=cut

__PACKAGE__->has_many(
  "tags_indexes",
  "Koha::Schema::Result::TagsIndex",
  { "foreign.biblionumber" => "self.biblionumber" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 virtualshelfcontents

Type: has_many

Related object: L<Koha::Schema::Result::Virtualshelfcontent>

=cut

__PACKAGE__->has_many(
  "virtualshelfcontents",
  "Koha::Schema::Result::Virtualshelfcontent",
  { "foreign.biblionumber" => "self.biblionumber" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07046 @ 2019-04-04 11:12:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:v6vo6FqcBYRlHlQyTqVKIQ

1;
