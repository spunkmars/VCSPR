use utf8;
package vcspr::schema::Result::Deploy;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

vcspr::schema::Result::Deploy

=cut

use strict;
use warnings;

#use base 'DBIx::Class::Core';

use base qw/DBIx::Class/; #1

__PACKAGE__->load_components(qw/UTF8Columns PK::Auto Core /); #1

=head1 TABLE: C<Deploy>

=cut

__PACKAGE__->table("Deploy");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 s_project

  data_type: 'integer'
  is_nullable: 0

=head2 s_branch

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 s_tag

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 s_commit_msg

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 trigger

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 dtask_type

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 dtask_value

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 is_active

  data_type: 'integer'
  default_value: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "s_project",
  { data_type => "integer", is_nullable => 0 },
  "s_branch",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "s_tag",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "s_commit_msg",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "trigger",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "dtask_type",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "dtask_value",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "is_active",
  { data_type => "integer", default_value => 1, is_nullable => 1 },
);

__PACKAGE__->utf8_columns(qw/ id s_project  s_branch s_tag s_commit_msg trigger  dtask_type dtask_value is_active /); #1
=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2013-08-12 18:26:08
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Zpz41QXePSnCi+gU9THZuQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
