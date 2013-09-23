use utf8;
package vcspr::schema::Result::VCSPushLog;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

vcspr::schema::Result::VCSPushLog

=cut

use strict;
use warnings;

#use base 'DBIx::Class::Core';

use base qw/DBIx::Class/; #1

__PACKAGE__->load_components(qw/UTF8Columns PK::Auto Core /); #1

=head1 TABLE: C<VCSPushLog>

=cut

__PACKAGE__->table("VCSPushLog");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 creater

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 create_date

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 create_uuid

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 vcs_name

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 vcs_alias_name

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 vcs_source

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 repo

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 s_command_type

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 s_commit_id

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 s_commit_timestamp

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 s_commit_author

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 s_commit_email

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 s_ref_type

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 s_ref_value

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 s_branch

  data_type: 'varchar'
  default_value: 'master'
  is_nullable: 0
  size: 255

=head2 s_commit_msg

  data_type: 'varchar'
  is_nullable: 1
  size: 1000

=head2 is_trigger

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "creater",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "create_date",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "create_uuid",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "vcs_name",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "vcs_alias_name",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "vcs_source",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "repo",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "s_command_type",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "s_commit_id",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "s_commit_timestamp",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "s_commit_author",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "s_commit_email",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "s_ref_type",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "s_ref_value",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "s_branch",
  {
    data_type => "varchar",
    default_value => "master",
    is_nullable => 0,
    size => 255,
  },
  "s_commit_msg",
  { data_type => "varchar", is_nullable => 1, size => 1000 },
  "is_trigger",
  { data_type => "integer", is_nullable => 1 },
);

__PACKAGE__->utf8_columns(qw/ id creater create_date create_uuid vcs_name  vcs_alias_name vcs_source repo s_command_type s_commit_id  s_commit_timestamp  s_commit_author  s_commit_email  s_ref_type  s_ref_value  s_branch  s_commit_msg is_trigger /); #1

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<id_create_uuid_unique>

=over 4

=item * L</id>

=item * L</create_uuid>

=back

=cut

__PACKAGE__->add_unique_constraint("id_create_uuid_unique", ["id", "create_uuid"]);


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2013-08-12 18:26:08
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:LBi85NXCREhr38koaczKnA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
