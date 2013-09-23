package VCSPublisher;

use base 'Exporter';
use vars qw/@EXPORT/;
@EXPORT = qw();

use FindBin qw($Bin);
use URI;

use SPMR::DBI::MyDBISqlite;
use SPMR::COMMON::MyCOMMON qw(DD l_debug $L_DEBUG);
$L_DEBUG = 1;

use SPMR::DATE::MyDATE qw(trans_standtime_to_timestamp);
use SPMR::FILE::MyFILE qw(make_dir);
use GitCommon;

use base 'APIBase';

sub new {
    my $invocant  = shift;
    my ( $cc ) = @_;
    my $self      = bless( {}, ref $invocant || $invocant );
    my %options = (
        );

    my $pub_conf = $self->read_config("$Bin/../etc/publisher.xml");
    $self->{pub_conf} = $pub_conf;
    $options{'conf_info'} = $self->{pub_conf};
    $options{'is_encrypt'} = 1;
    $options{'force_encrypt'} = 0;
    $options{'is_verify'} = 1;

    $self->init( \%options );

    my $sql_server = $self->{pub_conf}->{db_info}->{db_type};
    my $dsn;

    if ( $sql_server eq 'sqlite' ) {
        my $sqlite_file = $self->{pub_conf}->{db_info}->{db_file};
        $dsn .= "dbi:SQLite:dbname=${sqlite_file}";
        $self->{mysqlite} = SPMR::DBI::MyDBISqlite->new($dsn);
    } elsif ( $sql_server eq 'mysql' ) {

    } 
    return $self;
}


sub init {
    my $self = shift;
    $self->SUPER::init( @_);
}


#-----------------------
sub get_dtask_status {
    my $self = shift @_;
    my $post_data = shift @_;
    my $task_info = $self->json_to_data( $post_data );

    my $dtask_record = $self->get_dtask_by_id( $task_info->{'id'} );
    my $host_record  = $self->get_host_by_id( $dtask_record->{'host'} );
    my $uri = URI->new();
    $uri->scheme('http');
    $uri->host($host_record->{'name'});
    $uri->port(5002);
    $uri->path('/Deploy/DTask.Status');  
    my $host_uri = $uri->as_string;

    my $s_dtask_obj = {
        d_dir => $dtask_record->{'d_dir'},
        d_branch => $dtask_record->{'d_branch'},
        f_permissions => $dtask_record->{'f_permissions'},
    };
    $send_report = $self->send_data_to_host($host_uri, $s_dtask_obj); #FIX ME

    if ($send_report->{code} == 1 ){
        if ($send_report->{data}->{status}->{code} == 1) {
            $exec_dtask_data->{exec_info} = 'client has receive';
            $exec_dtask_data->{exec_status} = 'send_success';
            $exec_dtask_data->{exec_code} = 0;
            $exec_dtask_data->{data} = $send_report->{data};

        }else {
            $exec_dtask_data->{exec_info} = 'send dtask fail, client vefipy error or unknown error';
            $exec_dtask_data->{exec_status} = 'send_fail';
            $exec_dtask_data->{exec_code} = -1;
            $exec_dtask_data->{data} = $send_report->{data};
        }
    } else {
        $exec_dtask_data->{exec_info} = 'send dtask fail, it may be occur network error !';
        $exec_dtask_data->{exec_status} = 'send_fail';
        $exec_dtask_data->{exec_code} = -2;
    }
    return $exec_dtask_data;
}


sub merge_repo {
    my $self = shift @_;
    my $post_data = shift @_;
    my $is_merge_ok = 0;
    my $merge_msg = '';
    my $task_info = $self->json_to_data( $post_data );
    my $merge_repo_base_dir = '/data/VCSPR/merge_repo';

    my $deploy_record = $self->get_deploy_by_id($task_info->{deploy_id});
    my $proj_record = $self->get_project_by_id($deploy_record->{s_project});
    my $vcs_record = $self->get_vcs_by_id($proj_record->{vcs});

    my $merge_repo_dir = $merge_repo_base_dir . '/' . $proj_record->{repo};
    my $l_s_branch = 'master';
    my $r_m_branch = 'develop';
    my $url = $self->create_repo_uri($vcs_record->{type}, $vcs_record->{source}, $proj_record->{repo});
    my $remote_name = 'origin';


    make_dir($merge_repo_base_dir) unless (-d $merge_repo_base_dir);

    my $git = GitCommon->new(
            {   
                git => '/usr/bin/git',
                env => {
                    GIT_COMMITER_EMAIL => 'developer@spunkmars.org',
                    GIT_COMMITER_NAME  => 'developer',
                },
            }        
    );

    if (-d $merge_repo_dir) {
        if ($git->is_repo($merge_repo_dir)) {
            if ( $git->git_checkout($merge_repo_dir, $l_s_branch) == 0 ) {
                $merge_msg .= "git checkout success!\n ";
                if ( $git->git_pull( $merge_repo_dir, $remote_name, $l_s_branch) == 0 ) {
                    $merge_msg .= "git pull 1 success!\n ";
                    if ( $git->git_pull( $merge_repo_dir, $remote_name, $r_m_branch) == 0 ) {
                        $merge_msg .= "git pull 2 success!\n ";
                        if  ( $git->git_push( $merge_repo_dir ) == 0 ) {
                            $is_merge_ok = 1;
                            $merge_msg .= "git push success!\n ";
                        } else {
                            $is_merge_ok = 0;
                            $merge_msg .= "git push fail!\n ";
                        }
                    } else {
                        $is_merge_ok = 0;
                        $merge_msg .= "git pull 2 fail!\n ";
                    }
                } else {
                    $is_merge_ok = 0;
                    $merge_msg .= "git pull 1 fail!\n ";
                }
            } else {
                $is_merge_ok = 0;
                $merge_msg .= "git checkout fail!\n ";
            }
        } else {
            $is_merge_ok = 0;
            $merge_msg .= "The dir [$merge_repo_dir] is exists, but it is not a valid repo !\n ";
        }
    } else {
        if ($git->clone_repo($url, $merge_repo_dir) == 0) {
            $merge_msg .= "git clone success!\n ";
            if ( $git->git_checkout($merge_repo_dir, $l_s_branch) == 0 ) {
                $merge_msg .= "git checkout success!\n ";
                if ( $git->git_pull( $merge_repo_dir, $remote_name, $l_s_branch) == 0 ) {
                    $merge_msg .= "git pull 1 success!\n ";
                    if ( $git->git_pull( $merge_repo_dir, $remote_name, $r_m_branch) == 0 ) {
                        $merge_msg .= "git pull 2 success!\n ";
                        if  ( $git->git_push( $merge_repo_dir ) == 0 ) {
                            $is_merge_ok = 1;
                            $merge_msg .= "git push success!\n ";
                        } else {
                            $is_merge_ok = 0;
                            $merge_msg .= "git push fail!\n ";
                        }
                    } else {
                        $is_merge_ok = 0;
                        $merge_msg .= "git pull 2 fail!\n ";
                    }
                } else {
                    $is_merge_ok = 0;
                    $merge_msg .= "git pull 1 fail!\n ";
                }
            } else {
                $is_merge_ok = 0;
                $merge_msg .= "git checkout fail!\n ";
            }
        } else {
            $is_merge_ok = 0;
            $merge_msg .= "git clone fail [ url = $url ]!\n ";
        }
    }

    $merge_msg .= $git->{msg};
  
    return ($is_merge_ok, $merge_msg)
}
#-----------------------


sub split_ref {
    my $self = shift @_;
    my $ref = shift @_;
    my %ref_info;
    my @refs =  split(/\//, $ref);
    my %ref_type = (
        'heads'  => 'BRANCH',
        'tags'   => 'TAG',
    );
    $ref_info{type} =  $ref_type{ $refs[-2] };
    $ref_info{value} = $refs[-1];
    return \%ref_info;
}


sub get_vcs_name_by_source {
    my $self = shift @_;
    my ($vcs_source) = @_;
    my $vcs_name;
    my $sql = "SELECT * FROM VCS WHERE source='" . $vcs_source ."'";
    $self->{mysqlite}->connect_DB();
    my $vcs = $self->{mysqlite}->get_table_from_query('hash_ref', $sql);
    $self->{mysqlite}->disconnect_DB();
    $vcs_name = $vcs->{name};
    return $vcs_name;
}


sub get_vcs_source_by_url {
    my $self = shift @_;
    my ($url) = @_;
    my $vcs_source;
    my @decl = split(':', $url);
    pop(@decl) if (@decl >= 2);
    $vcs_source = join(':', @decl);
    return $vcs_source;
}


sub convert_git_push_data {
    my $self = shift @_;
    my $git_push_data = shift @_;
    my $tmp_git_push_data = {};
    my $last_commit = $git_push_data->{commits}->[-1];

    my $ref_info = $self->split_ref( $git_push_data->{ref} );
    my $vcs_source = $self->get_vcs_source_by_url($git_push_data->{repository}->{url});
    $tmp_git_push_data->{url} = $git_push_data->{repository}->{url};
    $tmp_git_push_data->{repository_name} = $git_push_data->{repository}->{name};
    $tmp_git_push_data->{username} = $git_push_data->{user_name};

    $tmp_git_push_data->{vcs_name} = $self->get_vcs_name_by_source($vcs_source);
    $tmp_git_push_data->{ref_type} =$ref_info->{type};
    $tmp_git_push_data->{ref_value} = $ref_info->{value};

    $tmp_git_push_data->{command_type} = 'update';

    $tmp_git_push_data->{commit_id} = $last_commit->{id};
    $tmp_git_push_data->{commit_timestamp} = $last_commit->{timestamp};
    $tmp_git_push_data->{commit_author} = $last_commit->{author}->{name};
    $tmp_git_push_data->{commit_email} = $last_commit->{author}->{email};
    $tmp_git_push_data->{commit_message} = $last_commit->{message};

    return $tmp_git_push_data;
}


sub get_vcs_by_name {

    my $self = shift @_;
    my $vcs_name = shift;
    my $sql = "SELECT * FROM VCS WHERE is_active=1 AND name='" . $vcs_name ."'";
    $self->{mysqlite}->connect_DB();
    my $vcs = $self->{mysqlite}->get_table_from_query('hash_ref', $sql);
    $self->{mysqlite}->disconnect_DB();
    return $vcs;
}


sub get_deploys {

    my $self = shift @_;
    my ($vcs, $repo) = @_;

    my $sql;
    $self->{mysqlite}->connect_DB();

    $sql = "SELECT * FROM Project WHERE is_active=1 AND vcs='" . $vcs->{id} ."' AND repo='" . $repo  ."'";
    my $proj_record = $self->{mysqlite}->get_table_from_query('hash_ref', $sql);

    $sql = "SELECT * FROM Deploy WHERE is_active=1 AND s_project ='" . $proj_record->{id} ."'";
    my $deploys_ref = $self->{mysqlite}->get_array_from_query($sql);

    $self->{mysqlite}->disconnect_DB();
    return $deploys_ref;
}


sub is_trigger_deploy {
    my $self = shift @_;
    my ($git_push_data, $deploy) = @_;
    my $is_trigger = 0;

    if ($deploy->{trigger} eq 'COMMIT_MSG' ) {
        $deploy->{s_commit_msg} =~ s/\///g;
        $is_trigger = 1 if ( $git_push_data->{commit_message} =~ m/\Q$deploy->{s_commit_msg}\E/ );
    } elsif ( $deploy->{trigger} eq 'TAG' ) { # gitlab 在得到tag时，是不会触发hook的。
        $git_push_data->{ref_value} =~ s/\///g;
        $is_trigger = 1 if ( $git_push_data->{ref_value} =~ m/\Q$deploy->{s_tag}\E/ );
    } elsif ( $deploy->{trigger} eq 'BRANCH') {
        $is_trigger = 1 if ($git_push_data->{ref_value} eq $deploy->{s_branch});
    } elsif ( $deploy->{trigger} eq 'MANUAL') { #除 MANUAL MERGE_DEPLOY 与 NONE外都会自动触发更新。
        $is_trigger = 0 if (1);
    } elsif ( $deploy->{trigger} eq 'MERGE_DEPLOY') { #除 MERGE_DEPLOY MANUAL 与 NONE外都会自动触发更新。
        $is_trigger = 0 if (1);
    } elsif ( $deploy->{trigger} == 'AUTO') {
        $is_trigger = 1 if (1);
    } elsif ( $deploy->{trigger} == 'NONE') { #除 MANUAL  MERGE_DEPLOY 与 NONE外都会自动触发更新。
        $is_trigger = 0 if (1);
    } else {
        $is_trigger = 0;
    } 

    return $is_trigger;
}


sub get_trigger_deploy {
    my $self = shift @_;
    my ($git_push_data, $deploys) = @_;
    my $trigger_deploys = [];
    my $deploy;

    foreach $deploy (@$deploys){
         if ($self->is_trigger_deploy($git_push_data, $deploy) ){
            push(@$trigger_deploys, $deploy);
         }
    }    
    return $trigger_deploys;
}


sub get_single_dtask {
    my $self = shift @_;
    my ($git_push_data, $deploy, $proj_record, $vcs_record, $dtask_id) = @_;
    my $dtask_obj;
    my $sql;
    my $dtask_record;
    my $host_record;

    $sql = "SELECT * FROM DTask WHERE id='" . $dtask_id . "'";
    $dtask_record = $self->{mysqlite}->get_table_from_query('hash_ref', $sql);

    $sql = "SELECT * FROM Host WHERE id='" . $dtask_record->{host} . "'";
    $host_record = $self->{mysqlite}->get_table_from_query('hash_ref', $sql);
    
    my $trigger_by = '';
    if (exists $git_push_data->{'trigger_by'}) {   # 在手动触发时，把trigger 改写为Manual 或者其它。
        $trigger_by = $git_push_data->{'trigger_by'};
    } else {
        $trigger_by = $deploy->{trigger};
    }

    $dtask_obj = {
        'dtask_id' => $dtask_record->{id},
        'vcs_push_log_create_uuid'  => $self->{vcs_push_log_create_uuid},
        'dtask_name' => $dtask_record->{name},
        'create_date' => $self->get_create_date(),
        'creater'    =>  $git_push_data->{username},
        'create_uuid' => $self->get_uuid(),
        'trigger_by'  =>  $trigger_by,
        'vcs_name'    => $vcs_record->{name},
        'vcs_type'    => $vcs_record->{type},
        'vcs_alias_name' => $vcs_record->{alias_name},
        'vcs_source'   => $git_push_data->{url},
        'repo'         => $git_push_data->{repository_name},
        #'repo'         => $proj_record->{repo},  #为保持一致性，暂时使用 $git_push_data->{repository_name} 替代。
        'command_type'  => $git_push_data->{command_type},

        's_commit_id'  => $git_push_data->{commit_id},
        's_commit_timestamp'  => $git_push_data->{commit_timestamp},
        's_commit_author'  => $git_push_data->{commit_author},
        's_commit_email'  => $git_push_data->{commit_email},
        's_ref_type'  => $git_push_data->{ref_type},
        's_ref_value'  => $git_push_data->{ref_value},
        's_branch'     => $git_push_data->{ref_value},
        's_commit_msg' => $git_push_data->{commit_message},

        'host_name'    =>  $host_record->{name},
        'host_alias_name' => $host_record->{alias_name},
        'host_ip'      => $host_record->{ip},
        'd_branch'     => $dtask_record->{d_branch},
        'd_dir'        => $dtask_record->{d_dir},
        'f_perm'       => $dtask_record->{f_permissions},
        'priority_type' => $dtask_record->{priority_type},
    };

    return $dtask_obj;
}


sub get_dtask_list {
    my $self = shift @_;
    my ($git_push_data, $trigger_deploys) = @_;
    my $dtask_list = [];
    my $dtask_obj;
    my $sql;
    my $proj_record;
    my $vcs_record;

    $self->{mysqlite}->connect_DB();
    foreach my $deploy (@$trigger_deploys) {

        $sql = "SELECT * FROM Project WHERE id='" . $deploy->{s_project} . "'";
        $proj_record = $self->{mysqlite}->get_table_from_query('hash_ref', $sql);
    
        $sql = "SELECT * FROM VCS WHERE id='" . $proj_record->{vcs} . "'";
        $vcs_record = $self->{mysqlite}->get_table_from_query('hash_ref', $sql);

        if ($deploy->{dtask_type} eq 'group') {
            $sql = "SELECT * FROM DTaskDTGroup WHERE dtask_gid ='" . $deploy->{dtask_value} . "'";
            my $dtaskdtgroups_ref = $self->{mysqlite}->get_array_from_query($sql);
            foreach my $dtaskdtgroup_record (@$dtaskdtgroups_ref) {
                $dtask_obj = $self->get_single_dtask($git_push_data, $deploy, $proj_record, $vcs_record, $dtaskdtgroup_record->{dtask_id});
                push(@$dtask_list, $dtask_obj);
            }
        } elsif ($deploy->{dtask_type} eq 'dtask') {
            $dtask_obj = $self->get_single_dtask($git_push_data, $deploy, $proj_record, $vcs_record, $deploy->{dtask_value});
            push(@$dtask_list, $dtask_obj);
        } else {
            die "invalid  dtask_type [ $deploy->{dtask_type} ] !\n";
        }
        
    }

    $self->{mysqlite}->disconnect_DB();
    return $dtask_list;
}


sub get_project_by_id {
    my $self = shift @_;
    my ($p_id) = @_;
    my $sql = "SELECT * FROM Project WHERE is_active=1 AND id='" . $p_id ."'";
    $self->{mysqlite}->connect_DB();
    my $project_ref = $self->{mysqlite}->get_table_from_query('hash_ref', $sql);
    $self->{mysqlite}->disconnect_DB();
    return $project_ref;

}


sub get_deploy_by_id {
    my $self = shift @_;
    my ($d_id) = @_;
    my $sql = "SELECT * FROM Deploy WHERE is_active=1 AND id='" . $d_id ."'";
    $self->{mysqlite}->connect_DB();
    my $deploys_ref = $self->{mysqlite}->get_table_from_query('hash_ref', $sql);
    $self->{mysqlite}->disconnect_DB();
    return $deploys_ref;
}


sub get_vcs_by_id {
    my $self = shift @_;
    my ($v_id) = @_;
    my $sql = "SELECT * FROM VCS WHERE id='" . $v_id ."'";
    $self->{mysqlite}->connect_DB();
    my $vcs_ref = $self->{mysqlite}->get_table_from_query('hash_ref', $sql);
    $self->{mysqlite}->disconnect_DB();
    return $vcs_ref;
}


sub get_dtask_by_id {
    my $self = shift @_;
    my ($v_id) = @_;
    my $sql = "SELECT * FROM DTask WHERE id='" . $v_id ."'";
    $self->{mysqlite}->connect_DB();
    my $dtask_ref = $self->{mysqlite}->get_table_from_query('hash_ref', $sql);
    $self->{mysqlite}->disconnect_DB();
    return $dtask_ref;
}


sub get_host_by_id {
    my $self = shift @_;
    my ($v_id) = @_;
    my $sql = "SELECT * FROM Host WHERE id='" . $v_id ."'";
    $self->{mysqlite}->connect_DB();
    my $host_ref = $self->{mysqlite}->get_table_from_query('hash_ref', $sql);
    $self->{mysqlite}->disconnect_DB();
    return $host_ref;
}


sub create_repo_uri {
    my $self = shift @_;
    my ($vcs_type, $vcs_source, $repo_name) = @_;
    my $repo_uri = '';
    if ( $vcs_type eq 'gitlab' ) {
        $repo_uri = $vcs_source . ':' . $repo_name . '.git';
    } elsif( $vcs_type eq 'gitblit' ) {
        $repo_uri = $vcs_source . ':' . $repo_name . '.git';
    } else {
        die "invalid  vcs_type [$vcs_type] !\n";
    }

    return $repo_uri;
}


sub get_push_data_from_trigger {
    my $self = shift @_;
    my $trigger_info = shift @_;
    my $deploy_info = $self->get_deploy_by_id( $trigger_info->{deploy_id} );
    my $project = $self->get_project_by_id( $deploy_info->{s_project} );
    my $vcs = $self->get_vcs_by_id( $project->{vcs} );
    my $tmp_git_push_data = {};
    $tmp_git_push_data->{url} = $self->create_repo_uri( $vcs->{type}, $vcs->{source}, $project->{repo} );
    $tmp_git_push_data->{vcs_name} = $vcs->{name};
    $tmp_git_push_data->{repository_name} = $project->{repo};
    $tmp_git_push_data->{username} = 'ManualTrigger';
    $tmp_git_push_data->{ref_type} = $trigger_info->{trigger_type};
    $tmp_git_push_data->{ref_value} = (exists $trigger_info->{trigger_value})?$trigger_info->{trigger_value}:$deploy_info->{s_branch};
    $tmp_git_push_data->{s_branch} = (exists $trigger_info->{trigger_value})?$trigger_info->{trigger_value}:$deploy_info->{s_branch};

    #$tmp_git_push_data->{ref_value} = $deploy_info->{s_branch};
    #$tmp_git_push_data->{s_branch} = $deploy_info->{s_branch}; #FIX ME

    $tmp_git_push_data->{command_type} = 'update';
    $tmp_git_push_data->{commit_id} = '8888888888888888888888888888888888888888';
    $tmp_git_push_data->{commit_timestamp} = '1970-12-12T12:12:12+12:12';
    $tmp_git_push_data->{commit_author} = 'ManualTrigger';
    $tmp_git_push_data->{commit_email} = 'ManualTrigger@spunkmars.org';
    $tmp_git_push_data->{commit_message} = 'ManualTrigger';
    $tmp_git_push_data->{trigger_by} = 'MANUAL';

    return $tmp_git_push_data;
}


sub deploy_by_id {
    my $self = shift @_;
        my ($git_push_data, $trigger_info) = @_;

        my $deploy_info = $self->get_deploy_by_id( $trigger_info->{deploy_id} );
        my @temp_deploys;
        push @temp_deploys, $deploy_info;
        my $dtask_list = $self->get_dtask_list($git_push_data, \@temp_deploys);
        $self->send_dtask_to_host($dtask_list);

}


sub deploy_by_trigger {
        my $self = shift @_;
        my $post_data = shift @_;
        my $trigger_info = $self->json_to_data( $post_data );
        my $git_push_data = $self->get_push_data_from_trigger($trigger_info);

        $self->record_vcs_push_log($git_push_data);
        if ( $trigger_info->{trigger_type} eq 'REPO') {
            $self->deploy($git_push_data);
        } elsif ( $trigger_info->{trigger_type} eq 'TAG' ) {
            $self->deploy_by_id($git_push_data, $trigger_info);
        } elsif ( $trigger_info->{trigger_type} eq 'BRANCH' ) {
            $self->deploy_by_id($git_push_data, $trigger_info);
        } elsif ( $trigger_info->{trigger_type} eq 'COMMIT' ) {
            $self->deploy_by_id($git_push_data, $trigger_info);
        }

}


sub create_new_dtask_log {
    my $self = shift @_;
    my $dtask_obj = shift @_;
    my $sql = "INSERT INTO DTaskLog 
                         (dtask_id, vcs_push_log_create_uuid, dtask_name, create_date, creater, create_uuid, trigger_by, vcs_name, vcs_alias_name, vcs_source, repo, s_branch, s_commit_msg, s_tag, s_commit_id, host_name, host_alias_name, host_ip, d_branch, d_dir, f_perm, priority_type, exec_status, exec_code, exec_info)
                 VALUES 
                         ('" . $dtask_obj->{dtask_id} . "', '" . $dtask_obj->{vcs_push_log_create_uuid} . "', '" . $dtask_obj->{dtask_name} . "', '" . $dtask_obj->{create_date} . "', '" . $dtask_obj->{creater} . "', '" . $dtask_obj->{create_uuid} . "', '" . $dtask_obj->{trigger_by} . "', '" . $dtask_obj->{vcs_name} . "', '" . $dtask_obj->{vcs_alias_name} . "', '" . $dtask_obj->{vcs_source} . "', '" . $dtask_obj->{repo} . "', '" . $dtask_obj->{s_branch} . "', '" . $dtask_obj->{s_commit_msg} . "', '" . $dtask_obj->{s_tag} . "', '" . $dtask_obj->{s_commit_id} . "', '" . $dtask_obj->{host_name} . "', '" . $dtask_obj->{host_alias_name} . "', '" . $dtask_obj->{host_ip} . "', '" . $dtask_obj->{d_branch} . "', '" . $dtask_obj->{d_dir} . "', '" . $dtask_obj->{f_perm} . "', '" . $dtask_obj->{priority_type} . "', 'create', 0, 'created by VCSPublisher' ) 
    ";
    $self->{mysqlite}->connect_DB();
    $self->{mysqlite}->do_basic_query($sql);  
    $self->{mysqlite}->disconnect_DB();      
}


sub update_dtask_log {
    my $self = shift @_;
    my ($dtask_obj_create_uuid, $exec_dtask_data) = @_;
    my $sql = "UPDATE DTaskLog  SET exec_status='" . $exec_dtask_data->{exec_status} . "', exec_info='" . $exec_dtask_data->{exec_info} . "', exec_code='" . $exec_dtask_data->{exec_code} . "' WHERE create_uuid='" . ${dtask_obj_create_uuid} . "'";
    $self->{mysqlite}->connect_DB();   
    $self->{mysqlite}->do_basic_query($sql);
    $self->{mysqlite}->disconnect_DB(); 
}


sub send_dtask_to_host {
    my $self = shift @_;
    my ($dtask_list) = @_;
    
    my $send_report;
    my $exec_dtask_data = {};
    foreach my $dtask_obj (@$dtask_list) {### 为组发布功能做准备。
    
        $self->create_new_dtask_log($dtask_obj);
    
        my $uri = URI->new();
        $uri->scheme('http');
        $uri->host($dtask_obj->{host_name});
        $uri->port(5002);
        $uri->path('/Deploy/DTask.Do');  
        my $host_uri = $uri->as_string;
    
        my $s_dtask_obj = {
            create_uuid => $dtask_obj->{create_uuid},
            vcs_name => $dtask_obj->{vcs_name},
            vcs_type => $dtask_obj->{vcs_type},
            vcs_source => $dtask_obj->{vcs_source},
            s_branch => $dtask_obj->{s_branch},
            d_branch => $dtask_obj->{d_branch},
            s_ref_type => $dtask_obj->{s_ref_type},
            s_ref_value => $dtask_obj->{s_ref_value},
            repo => $dtask_obj->{repo},
            d_dir => $dtask_obj->{d_dir},
            f_perm => $dtask_obj->{f_perm},
        };
        $send_report = $self->send_data_to_host($host_uri, $s_dtask_obj); #FIX ME
    
        if ($send_report->{code} == 1 ){
            if ($send_report->{data}->{status}->{code} == 1) {
                $exec_dtask_data->{exec_info} = 'client has receive';
                $exec_dtask_data->{exec_status} = 'send_success';
                $exec_dtask_data->{exec_code} = 0;
                $self->update_dtask_log($dtask_obj->{create_uuid}, $exec_dtask_data);
            }else {
                $exec_dtask_data->{exec_info} = 'send dtask fail, client vefipy error or unknown error';
                $exec_dtask_data->{exec_status} = 'send_fail';
                $exec_dtask_data->{exec_code} = -1;
                $self->update_dtask_log($dtask_obj->{create_uuid}, $exec_dtask_data );
            }
        } else {
            $exec_dtask_data->{exec_info} = 'send dtask fail, it may be occur network error !';
            $exec_dtask_data->{exec_status} = 'send_fail';
            $exec_dtask_data->{exec_code} = -2;
            $self->update_dtask_log($dtask_obj->{create_uuid}, $exec_dtask_data);
    
        }

    }####

}


sub deploy {
    my $self = shift @_;
    my $git_push_data = shift @_;
    $git_push_data = $git_push_data || {};

    my $vcs = $self->get_vcs_by_name($git_push_data->{vcs_name});
    my $deploys = $self->get_deploys($vcs, $git_push_data->{repository_name});
    my $trigger_deploys = $self->get_trigger_deploy($git_push_data, $deploys);
    my $dtask_list = $self->get_dtask_list($git_push_data, $trigger_deploys);

    $self->{mysqlite}->connect_DB();
    $self->send_dtask_to_host($dtask_list);   
    $self->{mysqlite}->disconnect_DB();
}


sub record_vcs_push_log {
    my $self = shift @_;
    my $git_push_data = shift @_;
    $git_push_data = $git_push_data || {};

    my $creater = $git_push_data->{username};
    my $create_date = $self->get_create_date();
    my $create_uuid = $self->get_uuid();
    my $vcs_name = $git_push_data->{vcs_name};
    my $vcs_source = $git_push_data->{url};
    my $repo = $git_push_data->{repository_name};
    my $command_type = $git_push_data->{command_type}; 
    my $commit_id = $git_push_data->{commit_id}; 
    my $commit_timestamp = $git_push_data->{commit_timestamp};
    my $commit_author = $git_push_data->{commit_author}; 
    my $commit_email = $git_push_data->{commit_email}; 
    my $ref_type = $git_push_data->{ref_type}; 
    my $ref_value = $git_push_data->{ref_value};

    my $s_branch = $git_push_data->{ref_value};
    my $s_commit_msg = $git_push_data->{commit_message};

    my $sql = " INSERT INTO VCSPushLog 
                    (id, creater, create_date, create_uuid, vcs_name,  vcs_source, repo, s_command_type, s_commit_id, s_commit_timestamp, s_commit_author, s_commit_email, s_ref_type, s_ref_value, s_branch, s_commit_msg)
                  VALUES 
                    (Null, '" . $creater . "', '" . $create_date . "', '" . $create_uuid . "', '" . $vcs_name . "', '" . $vcs_source . "', '" . $repo . "', '" . $command_type . "', '" . $commit_id . "', '" . $commit_timestamp . "', '" . $commit_author . "', '" . $commit_email . "', '" . $ref_type . "', '" . $ref_value . "', '" . $s_branch . "', '" . $s_commit_msg ."') 
    ";
    $self->{mysqlite}->connect_DB();
    $self->{mysqlite}->do_basic_query($sql);        
    $self->{mysqlite}->disconnect_DB();
    $self->{vcs_push_log_create_uuid} = $create_uuid;
}


sub count_exec_total_time {
    my $self = shift @_;
    my ($dtask_create_uuid, $exec_complite_date) = @_;

    my $exec_total_time = 0;
    my $sql = "SELECT * FROM DTaskLog WHERE create_uuid='" . $dtask_create_uuid . "'";
    $self->{mysqlite}->connect_DB();
    my $dtasklog_record = $self->{mysqlite}->get_table_from_query('hash_ref', $sql);
    $self->{mysqlite}->disconnect_DB();
    my $dtask_create_date = $dtasklog_record->{create_date};

    $exec_total_time = int( trans_standtime_to_timestamp($exec_complite_date) ) - int( trans_standtime_to_timestamp($dtask_create_date) );

    return $exec_total_time;  
}


sub record_exec_dtask_log {
    my $self = shift @_;
    my $exec_dtask_report = shift @_;

    my $exec_total_time = $self->count_exec_total_time($exec_dtask_report->{dtask_create_uuid}, $exec_dtask_report->{exec_complite_date});
    my $exec_status;
    if ( $exec_dtask_report->{exec_code} == 1 ) {
        $exec_status = 'exec_success';
    } else {
        $exec_status = 'exec_fail';
    }

    my $sql = "UPDATE DTaskLog  SET exec_status='" . $exec_status . "', exec_info='" . $exec_dtask_report->{exec_info} . "', exec_code='" . $exec_dtask_report->{exec_code} . "', exec_total_time='" .$exec_total_time . "' WHERE create_uuid='" . $exec_dtask_report->{dtask_create_uuid}. "'";
    $self->{mysqlite}->connect_DB();
    $self->{mysqlite}->do_basic_query($sql);
    $self->{mysqlite}->disconnect_DB();
}


1;
