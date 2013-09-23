package VCSReceiver;

use base 'Exporter';
use vars qw/@EXPORT/;
@EXPORT = qw();

use FindBin qw($Bin);
use URI;

use SPMR::DBI::MyDBISqlite;
use SPMR::COMMON::MyCOMMON qw(DD l_debug $L_DEBUG is_int_digit);
$L_DEBUG = 1;

use SPMR::FILE::MyFILE qw(safe_path is_safe_path list_dir1 );

use base 'APIBase';
use GitCommon;


sub new {
    my $invocant  = shift;
    my ($cc) = @_;
    my $self      = bless( {}, ref $invocant || $invocant );
    my %options = (
        );

    my $rec_conf = $self->read_config("$Bin/../etc/receiver.xml");
    $self->{rec_conf} = $rec_conf;
    my $publisher_host = $self->{rec_conf}->{app_info}->{publisher_host};
    my $publisher_port = $self->{rec_conf}->{app_info}->{publisher_port}; 

    my $uri = URI->new();
    $uri->scheme('http');
    $uri->host($publisher_host);
    $uri->port($publisher_port);
    $uri->path('/VCS/Result.Receive');  
    $self->{publisher_result_receive_url} = $uri->as_string;

    $options{'conf_info'} = $self->{rec_conf};
    $options{'is_encrypt'} = 1;
    $options{'force_encrypt'} = 1;
    $options{'is_verify'} = 1;

    $self->init( \%options );

    return $self;
}

sub init {
    $self = shift;
    $self->SUPER::init(@_);

    my %vcs_info = (
    );

    my %sys_dir = (
        'WEB_DIR' => '/data/htdocs/www',
        'PROD_WEB_DIR' => '/data/vhost',
        'TEST_WEB_DIR' => '/data/vhost',
        'TEMP_DIR' => '/tmp',
        'R_DIR'    => '/var/run',
    );

    my %sys_account = (
        'user' => {
            'web'  => 'www',
            'manager' => 'root',
            'nobody'    => 'nobody',
         },
        'group' => {
            'web'  => 'www',
            'manager' => 'root',
            'nobody'    => 'nobody',
         }
    );

    #$self->{sys_dir} = \%sys_dir;
    #$self->{sys_account} = \%sys_account;
 
    $self->{sys_dir} = (exists $self->{rec_conf}->{define_info}->{sys_dir})?$self->{rec_conf}->{define_info}->{sys_dir}:\%sys_dir;
    $self->{sys_account} = (exists $self->{rec_conf}->{define_info}->{sys_account})?$self->{rec_conf}->{define_info}->{sys_account}:\%sys_account;

}


sub split_f_perm {
    my $self = shift @_;
    my $f_perm_str = shift @_;
    my @all_f_perm = ();
    
    my $f_item_deli = '#';
    my $f_perm_deli = '\|';
    
    my @f_items = split($f_item_deli, $f_perm_str);
    
    foreach my $f_perm_item (@f_items) {
        my @f_perm = split($f_perm_deli, $f_perm_item);
        if ( @f_perm == 6 ) {
            my %f_perm_s = (
                'path' => $f_perm[0],
                'type' => $f_perm[1],
                'perm' => $f_perm[2],
                'recursion' => $f_perm[3],
                'user' => $f_perm[4],
                'group' => $f_perm[5],
            );
            push(@all_f_perm, \%f_perm_s);
    
        } else {
            print " [ $f_perm_item ] is not a valid file perm !\n";
        }
    }
    return @all_f_perm;
}


sub replace_sys_account {
    my $self = shift @_;
    my ($f_perm) = @_;
    my $has_err = 0;

   if ( exists $self->{sys_account}->{'user'}->{ $f_perm->{'user'} } ) {
        $f_perm->{'user'} = $self->{sys_account}->{'user'}->{ $f_perm->{'user'} };
        $has_err = 0;
   } else {
        $has_err = 1;
   }

   if ( $has_err == 0 and exists $self->{sys_account}->{'group'}->{ $f_perm->{'group'} } ) {
        $f_perm->{'group'} = $self->{sys_account}->{'group'}->{ $f_perm->{'group'} };
        $has_err = 0;
   } else {
        $has_err = 1;
   }

   return $has_err;
}


sub replace_sys_path {
    my $self = shift @_;
    my ($f_perm) = @_;
    my $has_err = 0;
    if ($f_perm->{'path'} =~ m/^((?:[A-Z]|_)+_DIR)/ ) {
        my $p_key = $1;
        if ( exists $self->{sys_dir}->{ $p_key } ) {        
            $f_perm->{'path'} =~ s/\Q$p_key\E/$self->{sys_dir}->{ $p_key }/;
            $has_err = 1 unless ( is_safe_path( $f_perm->{'path'}  ) );
        } else {
            $has_err = 1;
        }
    } else {
        $has_err = 1;
    }
   return $has_err;
}


sub analyze_f_perm {
    my $self = shift @_;
    my $f_perm_str = shift @_;
    my @avild_f_perm = ();
    my @all_f_perm = $self->split_f_perm($f_perm_str);
    my $has_err = 0;
    foreach my $f_perm_hsh (@all_f_perm) {
        $has_err = 0;
        $has_err = $self->replace_sys_account($f_perm_hsh) if ($has_err == 0);
        $has_err = $self->replace_sys_path($f_perm_hsh) if ($has_err == 0);
        push(@avild_f_perm, $f_perm_hsh) if ($has_err == 0);

    }
    return @avild_f_perm;
}


sub exec_f_perm_task {
    my $self = shift @_;
    my $f_perm_str = shift @_;
    my @f_perm_t = $self->analyze_f_perm($f_perm_str);
    
    foreach my $f_perm_hsh (@f_perm_t) {
        if ( -e $f_perm_hsh->{path} ) {
             my $uid = getpwnam($f_perm_hsh->{user});
             my $gid = getgrnam($f_perm_hsh->{group});
             my $p_mode = oct($f_perm_hsh->{perm});
             if ( $f_perm_hsh->{type} eq 'd' and -d $f_perm_hsh->{path} and $f_perm_hsh->{recursion} eq 'y') {
                 my @all_files = list_dir1($f_perm_hsh->{path});
                 chown  $uid, $gid, @all_files;
                 chmod  $p_mode, @all_files;
             } else {
                 chown  $uid, $gid, $f_perm_hsh->{path};
                 chmod  $p_mode, $f_perm_hsh->{path};
             }
         } else {
             die "[ $f_perm_hsh->{path} ] does not exists!\n";
         }
    }
}


sub parse_dir {
    my $self = shift @_;
    my $dir = shift @_; 
    my $has_err = 0;
    if ( $dir =~ m/^((?:[A-Z]|_)+_DIR)/ ) {
        my $p_key = $1;
        if ( exists $self->{sys_dir}->{ $p_key } ) {
            $dir =~ s/\Q$p_key\E/$self->{sys_dir}->{ $p_key }/;
            $has_err = 1 and die "unsafe dir [$dir] !\n" unless ( is_safe_path( $dir ) );
        } else {
            $has_err = 1;
            die "not a valid dir [$dir ]\n";
        }
    } else {
        die "not a valid dir [$dir ]\n";
    }

    return $dir;

}


sub parse_command {
    my $self = shift @_;
    my $command_data = shift @_;
    my $task_info = {};
    $task_info->{d_branch} = $command_data->{d_branch};
    $task_info->{dir} = $self->parse_dir( $command_data->{d_dir} );
    
    if ($command_data->{vcs_type} eq 'gitlab') {
        $task_info->{url} = $command_data->{vcs_source};
    } elsif ($command_data->{vcs_type} eq 'gitblit'){
        $task_info->{url} = 'gitblit地址 这里为暂时禁用。';
    } else {
        die "unknown vcs type [ $command_data->{vcs_type}  ]";
    }

    $task_info->{s_branch} = $command_data->{s_branch};

    $task_info->{d_branch} = $command_data->{d_branch}; #限定branch为 DTask记录中的 d_branch字段。

    $task_info->{repo} = $command_data->{repo};
    $task_info->{f_perm} = $command_data->{f_perm};
    $task_info->{s_ref_type} = $command_data->{s_ref_type};
    $task_info->{s_ref_value} = $command_data->{s_ref_value};
    return $task_info;
}


sub exec_command {
    my $self = shift @_;
    my ($command_data, $exec_dtask_report) = @_;

    my $task_info = $self->parse_command($command_data);

    my $git = GitCommon->new(
            {   
                git => '/usr/bin/git',
                env => {
                    GIT_COMMITER_EMAIL => 'developer@spunkmars.org',
                    GIT_COMMITER_NAME  => 'developer',
                },
            }        
    );
    $git->task_do($task_info);
    if ( $git->{code} == 1 and $task_info->{f_perm} ){
        $self->exec_f_perm_task($task_info->{f_perm}); #fix me
    }

    $exec_dtask_report->{dtask_create_uuid} = $command_data->{create_uuid};
    $exec_dtask_report->{exec_complite_date} = $self->get_create_date();
    $exec_dtask_report->{exec_code} = $git->{code};
    $exec_dtask_report->{exec_info} = $git->{msg};
}


sub get_dtask_status {
    my $self = shift @_;
    my ($command_data, $exec_dtask_report) = @_;

    my $repo_dir = $self->parse_dir( $command_data->{d_dir});

    my $git = GitCommon->new(
            {   
                git => '/usr/bin/git',
                env => {
                    GIT_COMMITER_EMAIL => 'developer@spunkmars.org',
                    GIT_COMMITER_NAME  => 'developer',
                },
            }        
    );



    my @git_status = $git->get_status_raw($repo_dir);
    
    my @branch_list = $git->get_branch_list($repo_dir);
    
    my $curr_branch = $git->get_curr_branch($repo_dir);
    
    my $has_up_to_date = $git->has_up_to_date($repo_dir);

    my @remote_list = $git->get_remote_list($repo_dir);
    
    my @remote_branch_list = $git->get_remote_branch_list($repo_dir);
    
    my %all_remote_info = $git->get_all_remote_info($repo_dir);
    
#    my @all_commits = $git->get_commit($repo_dir, 5);
    my @all_commits = ();
    
    my $last_commit = $git->get_last_commit($repo_dir);

    my $repo_status = {
        'git_status'  => \@git_status,
        'branch_list'  => \@branch_list,
        'curr_branch'  => $curr_branch,
        'has_up_to_date' => $has_up_to_date,
        'remote_list'  => \@remote_list,
        'remote_branch_list'  => \@remote_branch_list,
        'all_remote_info'  => \%all_remote_info,
        'all_commits'  => \@all_commits,
        'last_commit'  => $last_commit,
    };

    $exec_dtask_report->{repo_status} = $repo_status;
    $exec_dtask_report->{exec_complite_date} = $self->get_create_date();
    $exec_dtask_report->{exec_code} = $git->{code};
    $exec_dtask_report->{exec_info} = $git->{msg};
    return $exec_dtask_report;
}


sub git_push {

}


sub exec_dtask {
    my $self = shift @_;
    my $command_data = shift @_;
    $command_data = $command_data || {};
    my $exec_dtask_report = {};
    $self->exec_command($command_data, $exec_dtask_report);
    $self->send_data_to_host($self->{publisher_result_receive_url}, $exec_dtask_report);
}


1;
