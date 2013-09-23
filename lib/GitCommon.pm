package GitCommon;
use base 'Exporter';
use vars qw/@EXPORT/;
@EXPORT = qw();

use strict;
use warnings;

use utf8;
use Carp;
#$SIG{__DIE__} =  \&confess;
#$SIG{__WARN__} = \&confess;

use SPMR::COMMON::MyCOMMON qw(DD l_debug $L_DEBUG is_int_digit trim is_exist_in_array);
$L_DEBUG = 1;

use Git::Repository;
use Try::Tiny;


sub new {
    my $invocant  = shift;
    my ($options_ref) = @_;
    my $self      = bless( {}, ref $invocant || $invocant );
    my %options = (
        git => '/usr/bin/git',
        env => {
            GIT_COMMITER_EMAIL => 'developer@spunkmars.org',
            GIT_COMMITER_NAME  => 'developer',
        },
    );

    if (defined $options_ref) {
        if (ref $options_ref eq 'HASH') {
            %options = (%options, %$options_ref);
        } else {
            confess "\$options_ref must be an HASH ref";
        }
    }
    
    $self->init(\%options);

    return $self;
}


sub init {
    my $self = shift;
    my ($options_ref) = @_;
    confess "\$options_ref must be an HASH ref" if (ref $options_ref ne 'HASH');
    $self->{options} = $options_ref;
    $self->{msgs} = [];
    $self->{msg} = '';
    $self->{code} = 1;
}


sub name {
    my $self = shift @_;
    my $name;
    if ( @_ >= 2 ) {
        my $value;
        ( $name, $value ) = @_;
        $self->{$name} = $value;
    }
    else {
        $name = shift @_;
    }

    return $self->{$name};
}


sub log {
    my $self = shift @_;
    my $msg = shift @_;
    push(@{$self->{msgs}}, $msg);
    $self->{msg} = join('\n', @{$self->{msgs}});
}


sub get_status_raw {
    my $self = shift @_;
    my $dir = shift @_;
    my @status_raw = ();
    try {
        my $r = Git::Repository->new(
            work_tree => $dir,
            $self->{options}
        );
        #$self->log("$dir is a repo!");
        @status_raw = $r->run('status');
    }
    catch {
        $self->log(" the dir is not a repo!");
    };
    return \@status_raw;
}


sub is_repo1 {
    my $self = shift @_;
    my $dir = shift @_;
    eval {
        my $r = Git::Repository->new(
            work_tree => $dir,
            $self->{options}
        );
        return 1;
    };
    if ($@) {
        $self->log("$dir is not a repo!");
        return 0;
    }
}


sub is_repo {
    my $self = shift @_;
    my $dir = shift @_;
    my $is_repo = 0;
    try {
        my $r = Git::Repository->new(
            work_tree => $dir,
            $self->{options}
        );
        #$self->log("$dir is a repo!");
        $is_repo = 1;
    }
    catch {
        $self->log(" the dir is not a repo!");
        $is_repo = 0;
    };
    return $is_repo;
}


sub is_valid_repo {
    my $self = shift @_;
    my ($dtask_info) = @_;
    my $is_valid = 0;
    if ( $self->is_repo($dtask_info->{dir}) ) {
        $is_valid = 1;
        #if ($self->$get_curr_branch($dir) eq $d_branch) {
        #    $is_valid = 1;
        #} else {
        #    $is_valid = 0;
        #}
    }

    return $is_valid;
}


sub get_branch_raw {
    my $self = shift @_;
    my $dir = shift @_;
    my $r = Git::Repository->new(
        work_tree => $dir,
        $self->{options}
    );
    my @branch = $r->run('branch');
    return @branch;
}


sub get_branch_list {
    my $self = shift @_;
    my $dir = shift @_;
    my @branch = $self->get_branch_raw($dir);
    my $split_s = sub {
        my $str = shift @_;
        $str =~ s/^\*//g;
        $str = trim($str);
        return $str;
    };
    @branch = map { $split_s->($_) } @branch; 
    return @branch;

}


sub get_curr_branch {
    my $self = shift @_;
    my $dir = shift @_;
    my $branch;
    my @math_branch;
    my @branchs = $self->get_branch_raw($dir);
    @math_branch = grep { $_ =~ m/^\*/ } @branchs;
    $branch = shift @math_branch;
    $branch =~ s/^\*//;
    $branch = trim($branch);
    return $branch;

}


sub get_remote_list {
    my $self = shift @_;
    my $dir = shift @_;
    my $r = Git::Repository->new(
        work_tree => $dir,
        $self->{options}
    );

    my @remotes = $r->run('remote');
    @remotes = map { trim($_) } @remotes;
    return @remotes;

}


sub get_remote_info {
    my $self = shift @_;
    my $dir = shift @_;
    my $remote = shift @_;
    my $r = Git::Repository->new(
        work_tree => $dir,
        $self->{options}
    );
    my @remote_raw = $r->run('remote', 'show', $remote);
    
    my %remote_info = (
        'remote_name'    => '',
        'fetch_url'      => '',
        'push_url'       => '',
        'head_branch'    => '',
        'remote_branches' => {},
        'l_b_git_pull'   => {},
        'l_r_git_push'   => {},
    );
    
    my ($remote_name_done, $fetch_url_done, $push_url_done, $head_branch_done) = (0, 0, 0, 0);
    
    my $remote_branches_begin = 0;
    my $l_b_git_pull_begin = 0;
    my $l_r_git_push_begin = 0;
    
    foreach my $s_line (@remote_raw) {

        if ( $remote_name_done == 0 and $s_line =~ m/^\*\s+remote\s+(.*)$/ ) {
            $remote_info{'remote_name'} = trim($1);
            $remote_name_done = 1;
            next;
        }
    
        if ( $fetch_url_done == 0 and $s_line =~ m/Fetch\s+URL:(.*)$/ ) {
            $remote_info{'fetch_url'} = trim($1);
            $fetch_url_done = 1;
            next;
        }
    
        if ( $push_url_done == 0 and $s_line =~ m/Push\s+URL:(.*)$/ ) {
            $remote_info{'push_url'} = trim($1);
            $push_url_done = 1;
            next;
        }
    
        if ( $head_branch_done == 0 and $s_line =~ m/HEAD\s+branch:(.*)$/ ) {
            $remote_info{'head_branch'} = trim($1);
            $head_branch_done = 1;
            next;
        }
    
        if ( $remote_branches_begin == 0 and $s_line =~ m/Remote\s+branch(es)?:/ ) {
            $remote_branches_begin = 1;
            next;
        }   
         
        if ( $s_line =~ m/Local\s+branch/) {
            $l_b_git_pull_begin = 1;
            $remote_branches_begin = 0;
            next;
        }
    
        if ( $s_line =~ m/Local\s+ref/ ) {
            $l_r_git_push_begin = 1;
            $l_b_git_pull_begin = 0;
            $remote_branches_begin = 0;
            next;
        }
    
        if ( ($remote_branches_begin == 1) && ($l_b_git_pull_begin == 0) && ($l_r_git_push_begin == 0)  ) {
            my ($key, $val) = split(/\s+/, trim($s_line) );
            $remote_info{'remote_branches'}->{$key} = $val;
            next;
        }
    
        if ( ($l_b_git_pull_begin == 1) && ($remote_branches_begin == 0) && ($l_r_git_push_begin ==0) ) {
            if ( $s_line =~ m/(.*)\s+merges\s+with\s+remote\s+(.*)/ ) {
                $remote_info{'l_b_git_pull'}->{trim($1)} = trim($2);
                next;
            }
    
        }
    
        if ( ($l_r_git_push_begin == 1) && ($remote_branches_begin == 0) && ($l_b_git_pull_begin == 0) ) {
            if ( $s_line =~ m/(.*)\s+pushes\s+to\s+(\S+)\s+\((.*)\)/ ) {
                my $l_ref = trim($1);
                my $r_ref = trim($2);
                my $l_r_status = trim($3);
                my ($local_out_of_date, $fast_forwardable, $up_to_date) = (0, 0, 0); 
    
                $local_out_of_date = 1 if ($l_r_status =~ m/local\s+out\s+of\s+date/);
                $fast_forwardable = 1 if ($l_r_status =~ m/fast-forwardable/);
                $up_to_date = 1 if ($l_r_status =~ m/up\s+to\s+date/);
    
                $remote_info{'l_r_git_push'}->{$l_ref} = {
                    'r_ref'  => $r_ref,
                    'l_r_status' => $l_r_status,
                    'local_out_of_date' => $local_out_of_date,
                    'fast_forwardable' => $fast_forwardable,
                    'up_to_date' => $up_to_date,
                };
                next;
            }
    
        }
    
    }
    return %remote_info;

}


sub get_all_remote_info {
    my $self = shift @_;
    my $dir = shift @_;
    my %all_remote_info;
    my @remote_list = $self->get_remote_list($dir);
    foreach my $remote (@remote_list) {
        my %remote_info = $self->get_remote_info($dir, $remote);
        $all_remote_info{$remote} = \%remote_info;
    }
    return %all_remote_info;
}


sub has_up_to_date {
    my $self = shift @_;
    my ($dir, $l_branch, $remote) = @_;
    $l_branch = $self->get_curr_branch($dir) unless (defined $l_branch);
    $remote = 'origin' unless (defined $remote);
    my @branch_list = $self->get_branch_list($dir);
    my @remote_list = $self->get_remote_list($dir);
    die "branch [$l_branch] not exists !\n" if ( (grep {$_ eq $l_branch} @branch_list) < 1); 
    die "remote [$remote] not exists !\n" if ( (grep {$_ eq $remote} @remote_list) < 1); 
    my %remote_info = $self->get_remote_info($dir, $remote);
    if ( $remote_info{l_r_git_push}->{$l_branch}->{up_to_date} == 1 ){
        return 1;
    } else {
        return 0;
    }
}


sub get_commit {
    my $self = shift @_;
    my $dir = shift @_;
    my $commit_total = shift @_;
    die "[ $commit_total ] is not a valid parameter! \n" unless( is_int_digit($commit_total) ); 
    $commit_total = 0 unless (defined $commit_total);
    my $r = Git::Repository->new(
        work_tree => $dir,
        $self->{options}
    );
    my @log_formats = (
        'COMMIT_HASH:%H',
        'ABB_COMMIT_HASH:%h',
        'TREE_HASH:%T',
        'ABB_TREE_HASH:%t',
        'PARENT_HASHES:%P',
        'ABB_PARENT_HASHES:%p',
        'AUTHOR:%an',
        'AUTHOR_EMAIL:%ae',
        'AUTHOR_DATE:%ad',
        'AUTHOR_DATE_RELA:%ar',
        'COMMITTER:%cn',
        'COMMITTER_EMAIL:%ce',
        'COMMITTER_DATE:%cd',
        'COMMITTER_DATE_RELA:%cr',
        'SUBJECT:%s'
    );
   
    ######################
    ##  Option  Description of Output
    ##  %H  Commit hash
    ##  %h  Abbreviated commit hash
    ##  %T  Tree hash
    ##  %t  Abbreviated tree hash
    ##  %P  Parent hashes
    ##  %p  Abbreviated parent hashes
    ##  %an Author name
    ##  %ae Author e-mail
    ##  %ad Author date (format respects the --date= option)
    ##  %ar Author date, relative
    ##  %cn Committer name
    ##  %ce Committer email
    ##  %cd Committer date
    ##  %cr Committer date, relative
    ##  %s  Subject
    ######################

    my $delimiter = '#!!#';
    my $log_format = join($delimiter, @log_formats);
    
    my @log_command_parameters = ('log');
    if ($commit_total != 0) {
        push(@log_command_parameters, "-${commit_total}");
    }
    push(@log_command_parameters, "--pretty=format:$log_format");

    my @commit_raw = $r->run(@log_command_parameters);
    my @all_commit_log;
    foreach my $commit_line (@commit_raw) {
        my @commit = split($delimiter, $commit_line);
        my %commit_log;
        foreach my $commit_line (@commit) {
            my $key;
            my $value;
    
            if ($commit_line =~ m/^((?:[A-Z]|_)+):(.*)$/) {
                $key = $1;
                $value = $2;
                $key =~ tr/[A-Z]/[a-z]/;
                $commit_log{$key} = $value;
            }
        }
        push(@all_commit_log, \%commit_log);
    }
    
    return @all_commit_log;
}


sub get_last_commit {
    my $self = shift @_;
    my $dir = shift @_;
    my @last_commit;
    @last_commit = $self->get_commit($dir, 1);
    return $last_commit[0];
}


sub clone_repo {
    my $self = shift @_;
    my ($url, $dir) =  @_;
    try {
        Git::Repository->run( clone => $url, $dir);
        return 0;
    }
    catch {
        $self->log("clone $url into $dir falil! ");
        return 1;
    };
     
}


sub init_repo {
    my $self = shift @_;
    my $dir= shift @_;
    try {
        mkdir($dir) unless (-d $dir);
        Git::Repository->run(  init => $dir );
        return 0;
    }
    catch {
        $self->log("init repo [XX] into $dir falil! ");
        return 1;

    };
}


sub get_remote_branch_list {
    my $self = shift @_;
    my ($dir, $remote) = @_;
    $remote = 'origin' unless (defined $remote);
    my @branchs;
    my %remote_info = $self->get_remote_info($dir, $remote);
    @branchs = keys %{ $remote_info{remote_branches} };
    return @branchs;
}


sub has_l_branch {
    my $self = shift @_;
    my ($dir, $branch) = @_;
    my @branch_list = $self->get_branch_list($dir);
    if ( is_exist_in_array(\@branch_list, $branch) ) {
        return 1;
    } else {
        return 0;
    }
}


sub has_r_branch {
    my $self = shift @_;
    my ($dir, $branch) = @_;
    my @branch_list = $self->get_remote_branch_list($dir, 'origin');
    if ( is_exist_in_array(\@branch_list, $branch) ) {
        return 1;
    } else {
        return 0;
    }

}


sub git_fetch {
    my $self = shift @_;
    my ($dir) = @_;
    my $do_result;
    try {
        my $r = Git::Repository->new(
            work_tree => $dir,
            $self->{options}
        );
        #$r->run('checkout', '-f');
        $do_result = $r->run('fetch');
        $self->log("$do_result");
        return 0;
    }
    catch {
        $self->log("git fetch  error!");
        return 1;
    };  
}


sub git_merge {
    my $self = shift @_;
    my ($dir, $branch) = @_;
    my $do_result;
    try {
        my $r = Git::Repository->new(
            work_tree => $dir,
            $self->{options}
        );
        #$r->run('checkout', '-f');
        if ( $self->has_r_branch($dir, $branch) ) {
            $do_result = $r->run('merge', '--no-edit', 'origin', $branch);
            $self->log("$do_result");
            return 0;
        } else {
            $self->log("git fetch  error: r_branch [$branch] is not exist !");
            return 1;
        }
    }
    catch {
        $self->log("git fetch  error!");
        return 1;
    };  

}


sub git_pull {
    my $self = shift @_;
    my ($dir, $remote, $branch) = @_;
    my $do_result;
    try {
        my $r = Git::Repository->new(
            work_tree => $dir,
            $self->{options}
        );
        #$r->run('checkout', '-f');
        if ( $self->has_r_branch($dir, $branch) ) {
            $do_result = $r->run('pull', '--no-edit', $remote, $branch);
            if ($do_result =~ m/(unmerged\s+files)|(needs\s+merge)|(CONFLICT|Merge\s+conflict|merge\s+failed)/) {
                $self->log("git pull error: Automatic merge failed!");
                $self->log("$do_result");
                return 1;
            } else {
                $self->log("$do_result");
                return 0;
            }
        } else {
            $self->log("git pull  error: r_branch [$branch] is not exist !");
            return 1;
        }
    }
    catch {
        $self->log("git pull  error!");
        return 1;
    };  

}


sub git_checkout {

    my $self = shift @_;
    my ($dir, $ref_value) = @_;
    my $do_result;
    try {
        my $r = Git::Repository->new(
            work_tree => $dir,
            $self->{options}
        );
        #$r->run('checkout', '-f');
        $do_result = $r->run('checkout', $ref_value);
        if ($do_result =~ m/needs\s+merge/) {
            $self->log("git checkout [$ref_value] error: needs merge !");
            $self->log("$do_result");
            return 1;
        } else {
            $self->log("$do_result");
            return 0;
        }
    }
    catch {
        $self->log("git checkout [$ref_value]  error!");
        return 1;
    };  

}


sub git_push {

    my $self = shift @_;
    my ($dir, $remote_name, $r_branch) = @_;

    my $remote = defined $remote_name?$remote_name:'origin';
    my $branch = defined $r_branch?$r_branch:'master';

    my $do_result;
    try {
        my $r = Git::Repository->new(
            work_tree => $dir,
            $self->{options}
        );
        #$r->run('checkout', '-f');
        #$do_result = $r->run('push', $remote, $branch, '--force');
        $do_result = $r->run('push', $remote, $branch);
        $self->log("push:$do_result");
        return 0;
    }
    catch {
        $self->log("git push error!");
        return 1;
    };  

}


sub pull_repo {
    my $self = shift @_;
    my ($dtask_info) = @_;
    my $ref_value = $dtask_info->{d_branch}; # $dtask_info->{d_branch} |  $dtask_info->{s_ref_value}
    my $checkout_result;
    my $pull_result;
    try {
        my $r = Git::Repository->new(
            work_tree => $dtask_info->{dir},
            $self->{options}
        );
        my $curr_branch = $self->get_curr_branch($dtask_info->{dir});
        try {
            $r->run('checkout', '-f');
        }
        catch {
            $self->log("pull repo $dtask_info->{s_ref_type} [ $dtask_info->{s_ref_value} ] error: cmd [checkout -f] !");
            return 1;
        };


#        $self->git_pull($dtask_info->{dir}, 'origin', $dtask_info->{d_branch});

#        if ( $self->git_fetch($dtask_info->{dir}) == 0 ) {
#            $self->log("pull_repo: git fetch sucessfully !");
#        } else {
#            $self->log("pull_repo: git fetch error !");
#            #return 1;
#        }


        if ( $curr_branch =~ m/no\s+branch/ ) {
            $self->git_fetch($dtask_info->{dir});
#            $self->git_merge($dtask_info->{dir}, $dtask_info->{d_branch});
#            #$self->git_pull($dtask_info->{dir}, 'origin', $dtask_info->{d_branch}); #以上两条语句，可用此句代替。
        } else {
            $pull_result = $r->run('pull');
            $self->log("$pull_result");
        }
      
        if ( $dtask_info->{s_ref_type} eq 'BRANCH' ) {
            my $ref_v = $dtask_info->{d_branch}; # $dtask_info->{s_ref_value} #限定branch为 DTask记录中的 d_branch字段。
            #my $ref_v = $dtask_info->{s_ref_value}; # $dtask_info->{d_branch}

#            if ( $self->git_merge($dtask_info->{dir}, $ref_v) == 0 ) {
#                $self->log("git merge origin [$ref_v] sucessfully!");
#            }

            if ( $curr_branch ne $ref_v ) { 
                if ( $self->git_checkout($dtask_info->{dir}, $ref_v)  == 0 ) {
                    $self->log("change branch from [$curr_branch] to [ $ref_v ] sucessfully!");
                } else {
                    $self->log("change branch from [$curr_branch] to [ $ref_v ] fail!");
                    return 1;
                }
            }

#        } elsif ( $dtask_info->{s_ref_type} eq 'TAG' ) {
#            if ($dtask_info->{s_ref_value} !~ m/^(v|V)/ ) {
#                $self->log("invalid TAG format: $dtask_info->{s_ref_value}");
#                return 1; 
#            }
#
#            if ( $self->git_checkout($dtask_info->{dir}, $dtask_info->{s_ref_value})  == 0 ) {
#                $self->log("checkout code to TAG [ $dtask_info->{s_ref_value} ] sucessfully!");
#            } else {
#                $self->log("checkout code to TAG [ $dtask_info->{s_ref_value}  fail!");
#                return 1; 
#            };
#
#        } elsif ( $dtask_info->{s_ref_type} eq 'COMMIT' ) {
#
#            if ( $self->git_checkout($dtask_info->{dir}, $dtask_info->{s_ref_value})  == 0 ) {
#                $self->log("checkout code to COMMIT [ $dtask_info->{s_ref_value} ] sucessfully!");
#            } else {
#                $self->log("checkout code to COMMIT [ $dtask_info->{s_ref_value}  fail!");
#                return 1; 
#            };

        } else {
            $self->log("invalid ref_type format: $dtask_info->{s_ref_type} !");
            return 1;
        }

        return 0;
    }
    catch {
        $self->log("pull repo to $dtask_info->{s_ref_type} [ $dtask_info->{s_ref_value} ] error!");
        return 1;
    };    
}


sub add_new_remote {
    my $self = shift @_;



}


sub del_remote {
    my $self = shift @_;


}


sub modify_remote {
    my $self = shift @_;



}


sub task_do {
    my $self = shift @_;
    my ( $dtask_info ) = @_;
    my $url = $dtask_info->{url};
    my $repo = $dtask_info->{repo};
    my $s_branch = $dtask_info->{s_branch};
    my $d_branch = $dtask_info->{d_branch};
    my $dir = $dtask_info->{dir};
    my $s_ref_type = $dtask_info->{s_ref_type};
    my $s_ref_value = $dtask_info->{s_ref_value};

    if ( -d $dir) {
        if ( $self->is_valid_repo( $dtask_info ) ) {
            if ( $self->pull_repo( $dtask_info ) == 0) {
                $self->log("dtask exec success!");
            } else {
                $self->log("dtask exec fail!");
                $self->{code} = -2;

            }
        } else {
            $self->log("[$dir] is exists, but it is not a valid repo!");
            $self->{code} = -1;
        }
    } else {
        if ( $self->clone_repo($url, $dir) == 0){ 
            if ( $self->pull_repo( $dtask_info ) == 0) {
                $self->log("dtask exec success!");
            } else {
                $self->log("dtask exec fail!");
                $self->{code} = -3;
            }
        } else {
            $self->log("dtask exec fail!");
            $self->{code} = -4;
        }

    }
}


1;
