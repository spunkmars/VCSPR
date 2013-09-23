use utf8;
package vcspr::schema::Result::DTaskLog;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

vcspr::schema::Result::DTaskLog

=cut

use strict;
use warnings;

#use base 'DBIx::Class::Core';

use base qw/DBIx::Class/; #1

__PACKAGE__->load_components(qw/UTF8Columns PK::Auto Core /); #1

=head1 TABLE: C<DTaskLog>

=cut

__PACKAGE__->table("DTaskLog");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 dtask_id

  data_type: 'integer'
  is_nullable: 0

=head2 vcs_push_log_create_uuid

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 dtask_name

  data_type: 'varchar'
  is_nullable: 0
  size: 255

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

=head2 trigger_by

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

=head2 priority_type

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 repo

  data_type: 'varchar'
  is_nullable: 0
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

=head2 s_tag

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 s_commit_id

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 host_name

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 host_alias_name

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 host_ip

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 d_branch

  data_type: 'varchar'
  default_value: 'master'
  is_nullable: 0
  size: 255

=head2 d_dir

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 f_perm

  data_type: 'varchar'
  is_nullable: 1
  size: 1000

=head2 exec_total_time

  data_type: 'integer'
  is_nullable: 1

=head2 exec_status

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 exec_code

  data_type: 'integer'
  is_nullable: 1

=head2 exec_info

  data_type: 'varchar'
  is_nullable: 1
  size: 1000

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "dtask_id",
  { data_type => "integer", is_nullable => 0 },
  "vcs_push_log_create_uuid",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "dtask_name",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "creater",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "create_date",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "create_uuid",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "trigger_by",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "vcs_name",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "vcs_alias_name",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "vcs_source",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "priority_type",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "repo",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "s_branch",
  {
    data_type => "varchar",
    default_value => "master",
    is_nullable => 0,
    size => 255,
  },
  "s_commit_msg",
  { data_type => "varchar", is_nullable => 1, size => 1000 },
  "s_tag",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "s_commit_id",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "host_name",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "host_alias_name",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "host_ip",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "d_branch",
  {
    data_type => "varchar",
    default_value => "master",
    is_nullable => 0,
    size => 255,
  },
  "d_dir",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "f_perm",
  { data_type => "varchar", is_nullable => 1, size => 1000 },
  "exec_total_time",
  { data_type => "integer", is_nullable => 1 },
  "exec_status",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "exec_code",
  { data_type => "integer", is_nullable => 1 },
  "exec_info",
  { data_type => "varchar", is_nullable => 1, size => 1000 },
);

__PACKAGE__->utf8_columns(qw/ id dtask_id  vcs_push_log_create_uuid  dtask_name  creater  create_date  create_uuid  trigger_by vcs_name  vcs_alias_name vcs_source priority_type repo  s_branch  s_commit_msg s_tag s_commit_id  host_name host_alias_name host_ip d_branch d_dir  f_perm exec_total_time exec_status exec_code exec_info/); #1

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
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:V7HLuQwMqe8mLa2WDSjvAg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
