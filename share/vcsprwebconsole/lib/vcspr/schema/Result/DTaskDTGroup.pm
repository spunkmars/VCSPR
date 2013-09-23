use utf8;
package vcspr::schema::Result::DTaskDTGroup;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

vcspr::schema::Result::DTaskDTGroup

=cut

use strict;
use warnings;

#use base 'DBIx::Class::Core';

use base qw/DBIx::Class/; #1

__PACKAGE__->load_components(qw/UTF8Columns PK::Auto Core /); #1

=head1 TABLE: C<Host>

=cut

__PACKAGE__->table("DTaskDTGroup");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 dtask_id

  data_type: 'integer'
  is_nullable: 0

=head2 dtask_gid

  data_type: 'integer'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "dtask_id",
  { data_type => "integer", is_nullable => 0 },
  "dtask_gid",
  { data_type => "integer", is_nullable => 0 },
);

__PACKAGE__->utf8_columns(qw/ id dtask_id  dtask_gid /); #1

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
