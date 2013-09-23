use utf8;
package vcspr::schema::Result::DTaskGroup;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

vcspr::schema::Result::DTaskGroup

=cut

use strict;
use warnings;

#use base 'DBIx::Class::Core';

use base qw/DBIx::Class/; #1

__PACKAGE__->load_components(qw/UTF8Columns PK::Auto Core /); #1

=head1 TABLE: C<Host>

=cut

__PACKAGE__->table("DTaskGroup");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 info

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 is_active

  data_type: 'integer'
  default_value: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "info",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "is_active",
  { data_type => "integer", default_value => 1, is_nullable => 1 },
);

__PACKAGE__->utf8_columns(qw/ id name info is_active /); #1

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2013-08-12 18:26:08
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Fo+ZWkexOyRbvfaTmGBYjg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
