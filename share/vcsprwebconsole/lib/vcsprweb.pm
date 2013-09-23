use utf8;
package vcsprweb;


use Crypt::SaltedHash;
use Template;
use FindBin;

use SPMR::COMMON::MyCOMMON qw(DD l_debug $L_DEBUG is_int_digit trim);
$L_DEBUG = 1;
use SPMR::DATE::MyDATE qw(trans_standtime_to_timestamp  get_date);

use Dancer ':syntax';
use Dancer::Plugin::DBIC;
use vcspr::schema;

use ManualTrigger;

our $VERSION = '0.3.4';

my $url_prefix = '';



######################################################################

#my $another_schema = vcspr::schema->connect(
#      "dbi:SQLite:dbname=/opt/VCSPR/data/Deploy.db",
#      undef,
#      undef,
#      undef,
#      { 
##            sqlite_unicode => 1,   #文档中说只启用此选项 就可使用 unicode [utf8] 编码。[未经验证] .
#            on_connect_do => [
#                                'PRAGMA foreign_keys=ON', 
#                                'PRAGMA encoding = "UTF-8"',
#                                'PRAGMA synchronous = OFF',    #此选项只在Linux平台有效.
#                                'PRAGMA cache_size = 800000',  #设定SQLite的Cache 使用内存大小为800M，默认为2M.
#                             ], 
#        }
#  );


sub get_columns_info {
    my ($schema, $table, $columns_ref) = @_;
    my $a_schema = schema $schema;
    my $t_source = $a_schema->source($table);
    my $columns_info;
    if (defined $columns_ref and ref $columns_ref eq 'ARRAY') {
        $columns_info = $t_source->columns_info($columns_ref);
    } else {
        $columns_info = $t_source->columns_info;
    }
    return $columns_info;
}


sub get_column_names {
    my ($schema, $table) = @_;
    my $a_schema = schema $schema;
    my $t_source = $a_schema->source($table);
    my @column_names = $t_source->columns;
    return @column_names;
}


sub convert_records {
    my ($column_names, $s_records) = @_;
    my @results = () ;
    foreach my $record ( @$s_records ) {
        my %rec;
        foreach my $column (@$column_names) {
            $rec{$column} = $record->get_column($column);
        }
        push (@results, \%rec);
    }
    return @results;
}


sub get_all_records {
    my ($schema, $table, $order_by_ref, $where_ref) = @_;
    my $a_schema = schema $schema;
    my @results = () ;
    my @all_records = ();
    my $where_h_ref = (defined $where_ref)?$where_ref:undef;
    if (defined $order_by_ref and defined $where_h_ref) {   
        #@all_records = $a_schema->resultset($table)->search(undef, {  order_by => { -desc => 'id' }, })->all;
        @all_records = $a_schema->resultset($table)->search($where_h_ref, {  order_by => $order_by_ref, })->all;
    } elsif (defined $where_h_ref) {
        @all_records = $a_schema->resultset($table)->search($where_h_ref,)->all;
    } elsif (defined $order_by_ref) {
        @all_records = $a_schema->resultset($table)->search(undef, {  order_by => $order_by_ref, })->all;
    } else {
        @all_records = $a_schema->resultset($table)->all;
    }
    my @column_names = get_column_names($schema, $table);
    #DD(\@all_records);
    @results = convert_records(\@column_names, \@all_records);
    return @results;

}


sub get_single_record {
    my ($schema, $table, $cond, $attrs_ref) = @_;
    $cond = (defined $cond)?$cond:{};
    $attrs_ref = (defined $attrs_ref)?$attrs_ref:{};
    my $a_schema = schema $schema;
    my @results = () ;
    my $records_ref = $a_schema->resultset($table)->search($cond, $attrs_ref)->first;
    my @column_names = get_column_names($schema, $table);
    if (defined $records_ref and @column_names > 0) {
        @results = convert_records(\@column_names, [$records_ref]);
    }
    return $results[0];

}


sub get_find_record {
    my ($schema, $table, $id) = @_;
    my $rec = get_single_record($schema, $table, {'id' => $id} );
    return $rec;
}

###########################################################################################


post '/ManualDeploy/' => sub {
    my $d_id = params->{deploy_id};
    my $trigger_type = params->{trigger_type};
    my $trigger_value = params->{trigger_value};
    my $respose_msg = '';
    if ($trigger_type ne 'undefined' and  $trigger_value ne 'undefined') {
        
        my $trigger_api = ManualTrigger->new();
        my $trigger_data = {
            'deploy_id' => $d_id,
            'trigger_type' => $trigger_type,
            'trigger_value' => $trigger_value,
        };
        my $report_d = $trigger_api->send_trigger($trigger_data);

        if ($report_d->{code} == 1) {
            $respose_msg = "send trigger success : deploy  $d_id  $trigger_type $trigger_value : >> $report_d->{code}   $report_d->{msg} !";
        } else {
            $respose_msg = "<font color=\"red\"> send trigger fail : deploy  $d_id  $trigger_type $trigger_value : >> $report_d->{code}   $report_d->{msg} ! </font>";
        }

    } else {
        $respose_msg = "<font color=\"red\"> send trigger fail : deploy $d_id invalid trigger_type [$trigger_type] or trigger_value [$trigger_value] ! </font>";
    }
    content_type 'application/json';
    return to_json { msg => $respose_msg };

};


post '/ManualDeploy2/' => sub {
    my $d_id = params->{deploy_id};

    my $deploy_record = get_find_record('vcspr', 'Deploy', $d_id);
    my $trigger_type = $deploy_record->{trigger}; #
    my $trigger_value = $deploy_record->{s_branch};# 临时测试之用。

    my $respose_msg = '';
    if ( 1 == 1 ) {        
        my $trigger_api = ManualTrigger->new();
        my $trigger_data = {
            'deploy_id' => $d_id,
            'trigger_type' => 'BRANCH',
            'trigger_value' => $trigger_value,
        };
        my $report_d = $trigger_api->send_trigger($trigger_data);

        if ($report_d->{code} == 1) {
            $respose_msg = "send trigger success : deploy  $d_id  $trigger_type $trigger_value : >> $report_d->{code}   $report_d->{msg} !";
        } else {
            $respose_msg = "<font color=\"red\"> send trigger fail : deploy  $d_id  $trigger_type $trigger_value : >> $report_d->{code}   $report_d->{msg} ! </font>";
        }

    } else {
        $respose_msg = "<font color=\"red\"> send trigger fail : deploy $d_id invalid trigger_type [$trigger_type] or trigger_value [$trigger_value] ! </font>";
    }
    content_type 'application/json';
    return to_json { msg => $respose_msg };

};



post '/MergeDeploy/' => sub {
    my $d_id = params->{deploy_id};
    my $respose_msg = '';
    if ( 1 == 1 ) {
        
        my $trigger_api = ManualTrigger->new();
        my $trigger_data = {
            'deploy_id' => $d_id,
            'trigger_type' => 'BRANCH',
            'trigger_value' => 'master',
        };
        my $report_d = $trigger_api->merge_deploy($trigger_data);

        my $merge_status = $report_d->{data}->{info}->{merge_status};

        if ($merge_status->{merge_code} == 1) {
            $respose_msg = "send MergeDeploy success : deploy  $d_id   : >> $report_d->{code}   $merge_status->{merge_msg} !";
        } else {
            $respose_msg = "<font color=\"red\"> send MergeDeploy fail : deploy  $d_id   : >> $report_d->{code}   $merge_status->{merge_msg} ! </font>";
        }

    } else {
        $respose_msg = "<font color=\"red\"> send MergeDeploy fail : deploy $d_id ! </font>";
    }
    content_type 'application/json';
    return to_json { msg => $respose_msg };
};


sub make_tt_output {
    my ($file, $vars) = @_;
    my $tt = Template->new({
        INCLUDE_PATH => "$FindBin::Bin/../views",
    });

    my $output = '';
    $tt->process($file, $vars, \$output) || die $tt->error;

    return $output;
}


sub make_arry_to_html {
    my $a_arry = shift @_;
    my $html_str = '';
    foreach my $strs ( @$a_arry) {
        $html_str .=  $strs . '<br />' 
    }
    return $html_str;
}


sub get_dtask_info {
    my $repo_status = shift @_;
    #DD($repo_status);
    my $dtask_info = {
        'commit_hash'               =>  $repo_status->{last_commit}->{commit_hash},
        'parent_hashes'               =>  $repo_status->{last_commit}->{parent_hashes},
        'tree_hash'               =>  $repo_status->{last_commit}->{tree_hash},
        'committer_date'               =>  $repo_status->{last_commit}->{committer_date},
        'committer'               =>  $repo_status->{last_commit}->{committer},
        'committer_email'               =>  $repo_status->{last_commit}->{committer_email},
        'author_date'               =>  $repo_status->{last_commit}->{author_date},
        'author'               =>  $repo_status->{last_commit}->{author},
        'author_email'               =>  $repo_status->{last_commit}->{author_email},
        'subject'               =>  $repo_status->{last_commit}->{subject},
        'has_up_to_date' => ( $repo_status->{has_up_to_date} )?'YES':'NO',
        'curr_branch'    => $repo_status->{curr_branch},
        'curr_remote'    => 'origin',
        'branch_list'               =>  join(', ', @{$repo_status->{branch_list}}),
        'remote_name'               =>  $repo_status->{all_remote_info}->{origin}->{remote_name},
        'fetch_url'               =>  $repo_status->{all_remote_info}->{origin}->{fetch_url},
        'push_url'               =>  $repo_status->{all_remote_info}->{origin}->{push_url},
        'remote_branch_list'               =>  join(', ', @{$repo_status->{remote_branch_list}}),
#        'l_b_git_pull'               =>  $repo_status->{},
#        'l_r_git_push'               =>  $repo_status->{},
        'git_status'               =>  make_arry_to_html($repo_status->{git_status}->[0]),
    };
    return $dtask_info;
}


post '/DTaskStatus/' => sub {
    my $dtask_id = trim(params->{dtask_id});
    my $respose_msg = '';
    my $repo_status = '';
    if ($dtask_id ne 'undefined' and  is_int_digit($dtask_id) ) {
        
        my $trigger_api = ManualTrigger->new();
        my $dtask_record = get_find_record('vcspr', 'DTask', $dtask_id);

        my $report_d = $trigger_api->get_repo_status($dtask_record);
        
        if ($report_d->{code} == 1) {

            my $dtask_info = get_dtask_info($report_d->{data}->{info}->{repo_status});
            my $vars = {
                result => $dtask_info,
            };

            $repo_status = make_tt_output('DTask_Status.tt', $vars);
            $respose_msg = " Get DTask [ $dtask_record->{name} ] Status success! >> $report_d->{code}   $report_d->{msg} !";
        } else {
            $respose_msg = "<font color=\"red\"> Get DTask [ $dtask_record->{name} ] Status fail! >> $report_d->{code}   $report_d->{msg} ! </font>";
        }

    } else {
        $respose_msg = "<font color=\"red\"> invalid trigger_type [$dtask_id] ! </font>";
    }
    content_type 'application/json';
    return to_json { msg => $respose_msg, repo_status => $repo_status };

};


post '/GitLabProjectList/' => sub {

    # GET /projects
    my $vcs_id = params->{vcs_id};
    my $uri_path = '/projects';
    my $trigger_api = ManualTrigger->new();
    my $vcs_ref = $trigger_api->get_vcs_info_by_vcs_id($vcs_id);
    my $uri_prefix = $vcs_ref->{'api_uri'};  
    my $private_token = $vcs_ref->{'api_private_token'};

    my $gitlab_info = $trigger_api->get_data_from_gitlab($uri_prefix, $uri_path, $private_token);
    my $proj_info = $gitlab_info->{'data'};

    my @proj_list;
    foreach my $proj (@$proj_info) {
        push @proj_list, {
                           proj_name => $proj->{'name'},
                           proj_id => $proj->{'id'},
                           proj_repo => $proj->{'path'}, 
        };
    }

    content_type 'application/json';
    return to_json { proj_list => \@proj_list };
};


post '/GitLabProject/' => sub {

    # GET /projects/:id
    my $trigger_api = ManualTrigger->new();
    my $deploy_id = params->{deploy_id};

    my $proj_info = $trigger_api->get_proj_info_by_deploy_id( params->{deploy_id} );
    my $proj_id = $proj_info->{'proj_id'};
    my $uri_prefix = $proj_info->{'proj_vcs_api_uri'};
    my $private_token = $proj_info->{'proj_private_token'};

    my $uri_path = "/projects/$proj_id";

    my $gitlab_info = $trigger_api->get_data_from_gitlab($uri_prefix, $uri_path, $private_token);
    my $proj_single_info = $gitlab_info->{'data'};
    content_type 'application/json';
    return to_json { proj_info => $proj_single_info };
};


sub sort_branch {
    my ($branch_list, $d_branch) = @_;
    my @temp_b;
    foreach my $branch (@$branch_list) {
         push(@temp_b, $branch) if  ("$branch" ne "$d_branch");
    }
    unshift(@temp_b, $d_branch) if ($d_branch);
    return @temp_b;
}


post '/GitLabRepoBranchList/' => sub {
    # GET /projects/:id/repository/branches
    my $deploy_id = params->{deploy_id};
    my $trigger_api = ManualTrigger->new();

    my $proj_info = $trigger_api->get_proj_info_by_deploy_id( params->{deploy_id} );
    my $proj_id = $proj_info->{'proj_id'};
    my $uri_prefix = $proj_info->{'proj_vcs_api_uri'};
    my $private_token = $proj_info->{'proj_private_token'};

    my $uri_path = "/projects/$proj_id/repository/branches";

    my $gitlab_info = $trigger_api->get_data_from_gitlab($uri_prefix, $uri_path, $private_token);
    my $branch_info = $gitlab_info->{'data'};

    my @branch_list;
    foreach my $branch (@$branch_info) {
        push @branch_list, $branch->{'name'};
    }

    my $d_branch = $trigger_api->get_d_branch_deploy_id($deploy_id);
    @branch_list = sort_branch(\@branch_list, $d_branch);

    content_type 'application/json';
    return to_json { branch_list => \@branch_list };
};


post '/GitLabRepoTagList/' => sub {

    # GET /projects/:id/repository/tags
    my $trigger_api = ManualTrigger->new();

    my $proj_info = $trigger_api->get_proj_info_by_deploy_id( params->{deploy_id} );
    my $proj_id = $proj_info->{'proj_id'};
    my $uri_prefix = $proj_info->{'proj_vcs_api_uri'};
    my $private_token = $proj_info->{'proj_private_token'};

    my $uri_path = "/projects/$proj_id/repository/tags";

    my $gitlab_info = $trigger_api->get_data_from_gitlab($uri_prefix, $uri_path, $private_token);
    my $tag_info = $gitlab_info->{'data'};

    my @tag_list;
    foreach my $tag (@$tag_info) {
        push @tag_list, $tag->{'name'};
    }
    content_type 'application/json';
    return to_json { tag_list => \@tag_list };
};


#curl --header "PRIVATE-TOKEN: vsdfervdrerw" "http://XXX.test.com/gitlab/api/v3/projects"

post '/GitLabRepoCommitList/' => sub {

    # GET /projects/:id/repository/commits
    my $trigger_api = ManualTrigger->new();

    my $proj_info = $trigger_api->get_proj_info_by_deploy_id( params->{deploy_id} );
    my $proj_id = $proj_info->{'proj_id'};
    my $uri_prefix = $proj_info->{'proj_vcs_api_uri'};
    my $private_token = $proj_info->{'proj_private_token'};

    my $uri_path = "/projects/$proj_id/repository/commits";

    my $gitlab_info = $trigger_api->get_data_from_gitlab($uri_prefix, $uri_path, $private_token);
    my $commit_info = $gitlab_info->{'data'};

    my @commit_list;
    foreach my $commit (@$commit_info) {
        push @commit_list, $commit->{'id'};
    }
    content_type 'application/json';
    return to_json { commit_list => \@commit_list };
};


##*****************************************
post '/DTaskSelectStr/' => sub {

    my $dtask_type = params->{dtask_type};

    my $respose_msg = '';
    if ($dtask_type ne 'undefined' and ($dtask_type eq 'group' or $dtask_type eq 'dtask') ) {
        $respose_msg = _perform_dtask_list_html_select_str();
    } else {
        $respose_msg = "invalid dtask_type [$dtask_type] !";
    }
    content_type 'application/json';
    return to_json { html_select_str => $respose_msg };

};




post '/DTaskGroupSelectStr/' => sub {

    my $dtask_type = params->{dtask_type};

    my $respose_msg = '';
    if ($dtask_type ne 'undefined' and ($dtask_type eq 'group' or $dtask_type eq 'dtask') ) {
        $respose_msg = _perform_dtaskgroup_list_html_select_str();
    } else {
        $respose_msg = "invalid dtask_type [$dtask_type] !";
    }
    content_type 'application/json';
    return to_json { html_select_str => $respose_msg };

};

##*****************************************


##-------------------------------------------------------------------

#get "$url_prefix/" => sub {
#    template 'index';
#};


#prefix '/home';

my $old_version_url = 'http://192.168.8.154:5004/';


before sub {
    if (! session('user') && request->path_info !~ m{^/login/}) {
        var requested_path => request->path_info;
        request->path_info('/login/');
    }
};


before_template sub {
    my $tokens = shift;
    $tokens->{user} = session('user');
    $tokens->{old_version_url} = $old_version_url;

};


get "$url_prefix/login/" => sub {
    template 'login', { path => vars->{requested_path} };
};
 

post "$url_prefix/login/" => sub {
    my $user = get_single_record('vcspr', 'User',
        { username => params->{user} }
    );
    if (!$user) {
            template 'login', { 
                path => vars->{requested_path},
                err_msg => "Failed login for unrecognised user " . params->{user},
            };
    } else {
        if (Crypt::SaltedHash->validate($user->{password}, params->{pass}))
        {
            my $user_i = {
                'id'       => $user->{id},
                'username' => $user->{username},
                'email'    => $user->{email},
            };
            session user => $user_i;
            redirect params->{path} || '/';
        } else {
            template 'login', { 
                path => vars->{requested_path},
                err_msg => "Login failed - password incorrect for " . params->{user},
            };
        }
    }
};


get "$url_prefix/logout/" => sub {
   session->destroy;
   redirect '/';
};


get "$url_prefix/" => sub {
    redirect '/deploy/list/';
};


##--------------------------------------------------------
get "$url_prefix/user/" => sub {
    redirect "$url_prefix/user/list/";
};


get "$url_prefix/user/list/" => sub {
    my @results = ();
    @results = _perform_user_list();
    template 'user_list', {
                         title => 'user list ',
                         results => \@results,
                       };
};


any ['get', 'post'] => "$url_prefix/user/add/" => sub {
    if ( request->method() eq "POST" ) {
        my $pass_s = trim(params->{password});
        my $pass_d;
        my $csh = Crypt::SaltedHash->new(algorithm => 'SHA-1');
        $csh->add($pass_s);
        $pass_d = $csh->generate;
        my %a_params = (
            id => params->{id},
            username => params->{username},
            password => $pass_d,
            email => params->{email},
            info => params->{info},
            is_active => params->{is_active},
        );
        my $result = _perform_user_add(\%a_params);
        return redirect "$url_prefix/user/list/";

    } else {
        template 'user_add', {
                         title => 'user add ',
                       };
    }

};


any ['get', 'post'] => "$url_prefix/user/edit/:id/" => sub {
    my $form_ref = get_find_record('vcspr', 'User', params->{id});
    if ( request->method() eq "POST" ) {
        my $pass_d;
        my $valid;
        my $is_change = 0;
        my $pass_s = trim(params->{password});
        if ($pass_s ne ''){
            $valid = Crypt::SaltedHash->validate($form_ref->{password}, $pass_s);
            $is_change = 1 unless ($valid);
        } else {
            $is_change = 0;
        }
        if ($is_change) {
            my $csh = Crypt::SaltedHash->new(algorithm => 'SHA-1');
            $csh->add($pass_s);
            $pass_d = $csh->generate;
        } else {
            $pass_d = $form_ref->{password};
        }

        my %a_params = (
            id => params->{id},
            username => params->{username},
            password => $pass_d,
            email => params->{email},
            info => params->{info},
            is_active => params->{is_active},
        );

        my $result = _perform_user_edit(\%a_params);
        return redirect "$url_prefix/user/edit/$a_params{id}/";

    } else {
        template 'user_edit', {
                         title => 'user edit ',
                         form  => $form_ref,
                       };
    }

};


get "$url_prefix/user/delete/:id/" => sub {
    my $result = _perform_user_delete(params->{id});
    return redirect "$url_prefix/user/list/";
};
##--------------------------------------------------------


any ['get', 'post'] => "$url_prefix/host/add/" => sub {
    if ( request->method() eq "POST" ) {
        my %a_params = (
            hostname => params->{hostname}, 
            alias_name => params->{aliasname},
            ip => params->{ip}, 
            info => params->{info}
        );
        my $result = _perform_host_add(\%a_params);
        return redirect "$url_prefix/host/list/";

    } else {
        template 'host_add', {
                         title => 'host add ',
                       };
    }

};


get "$url_prefix/host/" => sub {
    redirect "$url_prefix/host/list/";
};


get "$url_prefix/host/list/" => sub {
    my @results = ();
    @results = get_all_records('vcspr', 'Host');
    template 'host_list', {
                         title => 'host list ',
                         results => \@results,
                       };        

};


any ['get', 'post'] => "$url_prefix/host/edit/:id/" => sub {
    if ( request->method() eq "POST" ) {
        my %a_params = (
            id => params->{id},
            hostname => params->{hostname},
            alias_name => params->{aliasname},
            ip => params->{ip},
            info => params->{info}
        );
        my $result = _perform_host_edit(\%a_params);
        return redirect "$url_prefix/host/list/";

    } else {
        my $form_ref = get_find_record('vcspr', 'Host', params->{id});
        template 'host_edit', {
                         title => 'host edit ',
                         form  => $form_ref,
                       };
    }

};


get "$url_prefix/host/delete/:id/" => sub {
    my $result = _perform_host_delete(params->{id});
    return redirect "$url_prefix/host/list/";
};


##-------------------------------------------------------------


get "$url_prefix/vcs/" => sub {
    redirect "$url_prefix/vcs/list/";
};


get "$url_prefix/vcs/list/" => sub {
    my @results = ();
    @results = _perform_vcs_list();
    template 'vcs_list', {
                         title => 'vcs list ',
                         results => \@results,
                       };
};


any ['get', 'post'] => "$url_prefix/vcs/add/" => sub {
    if ( request->method() eq "POST" ) {
        my %a_params = (
            vcsname => params->{vcsname},
            alias_name => params->{aliasname},
            type => params->{type},
            source => params->{source},
            api_uri => params->{api_uri},
            api_private_token => params->{api_private_token},
            info => params->{info},
            is_active => params->{is_active},
        );
        my $result = _perform_vcs_add(\%a_params);
        return redirect "$url_prefix/vcs/list/";

    } else {

        my $vcs_type_html_select_str = _perform_vcs_type_list_html_select_str();
        template 'vcs_add', {
                         title => 'vcs add ',
                         vcs_type_html_select_str => $vcs_type_html_select_str,
                       };
    }

};


any ['get', 'post'] => "$url_prefix/vcs/edit/:id/" => sub {
    if ( request->method() eq "POST" ) {
        my %a_params = (
            id => params->{id},
            vcsname => params->{vcsname},
            alias_name => params->{aliasname},
            type => params->{type},
            source => params->{source},
            api_uri => params->{api_uri},
            api_private_token => params->{api_private_token},
            info => params->{info},
            is_active => params->{is_active},
        );
        my $result = _perform_vcs_edit(\%a_params);
        return redirect "$url_prefix/vcs/list/";
    } else {
        my $form_ref = get_find_record('vcspr', 'VCS', params->{id});
        my $vcs_type_html_select_str = _perform_vcs_type_list_html_select_str($form_ref->{type});
        template 'vcs_edit', {
                         title => 'vcs edit ',
                         form  => $form_ref,
                         vcs_type_html_select_str => $vcs_type_html_select_str,
                       };
    }

};


get "$url_prefix/vcs/delete/:id/" => sub {
    my $result = _perform_vcs_delete(params->{id});
    return redirect "$url_prefix/vcs/list/";
};


##---------------------------------------------------------------------


get "$url_prefix/project/" => sub {
    redirect "$url_prefix/project/list/";
};


get "$url_prefix/project/list/" => sub {
    my @results = ();
    @results = _perform_project_list();
    template 'project_list', {
                         title => 'project list ',
                         results => \@results,
                       };
};


any ['get', 'post'] => "$url_prefix/project/add/" => sub {
    if ( request->method() eq "POST" ) {
        my %a_params = (
            projectname => params->{projectname},
            alias_name => params->{aliasname},
            repo => params->{repo},
            proj_id => params->{proj_id},
            info => params->{info},
            is_active => params->{is_active},
            vcs => params->{vcs},
        );
        #DD(\%a_params);
        my $result = _perform_project_add(\%a_params);
        return redirect "$url_prefix/project/list/";

    } else {
        my $vcs_html_select_str = _perform_vcs_list_html_select_str();
        template 'project_add', {
                         title => 'project add ',
                         vcs_html_select_str => $vcs_html_select_str,
                       };
    }

};


any ['get', 'post'] => "$url_prefix/project/edit/:id/" => sub {
    if ( request->method() eq "POST" ) {
        my %a_params = (
            id => params->{id},
            projectname => params->{projectname},
            alias_name => params->{aliasname},
            repo => params->{repo},
            proj_id => params->{proj_id},
            info => params->{info},
            is_active => params->{is_active},
            vcs => params->{vcs},
        );
        my $result = _perform_project_edit(\%a_params);
        return redirect "$url_prefix/project/list/";

    } else {
        my $form_ref = get_find_record('vcspr', 'Project', params->{id});
        my $vcs_html_select_str = _perform_vcs_list_html_select_str($form_ref->{vcs});
        template 'project_edit', {
                         title => 'project edit ',
                         form  => $form_ref,
                         vcs_html_select_str => $vcs_html_select_str,
                       };
    }

};


get "$url_prefix/project/delete/:id/" => sub {
    my $result = _perform_project_delete(params->{id});
    return redirect "$url_prefix/project/list/";
};


##---------------------------------------------------------------------


get "$url_prefix/dtaskgroup/" => sub {
    redirect "$url_prefix/dtaskgroup/list/";
};


get "$url_prefix/dtaskgroup/list/" => sub {
    my @results = ();
    @results = _perform_dtaskgroup_list();
    template 'dtaskgroup_list', {
                         title => 'dtaskgroup list ',
                         results => \@results,
                       };
};


any ['get', 'post'] => "$url_prefix/dtaskgroup/add/" => sub {
    if ( request->method() eq "POST" ) {
        my %a_params = (
            dtaskgroupname => params->{dtaskgroupname}, 
            info => params->{info},
            is_active => params->{is_active}, 
        );
        my $result = _perform_dtaskgroup_add(\%a_params);
        return redirect "$url_prefix/dtaskgroup/list/";

    } else {
        template 'dtaskgroup_add', {
                         title => 'dtaskgroup add ',
                       };
    }

};


any ['get', 'post'] => "$url_prefix/dtaskgroup/edit/:id/" => sub {
    if ( request->method() eq "POST" ) {
        my %a_params = (
            id => params->{id},
            dtaskgroupname => params->{dtaskgroupname}, 
            info => params->{info},
            is_active => params->{is_active}, 
        );
        my $result = _perform_dtaskgroup_edit(\%a_params);
        return redirect "$url_prefix/dtaskgroup/list/";

    } else {
        my $form_ref = get_find_record('vcspr', 'DTaskGroup', params->{id});
        template 'dtaskgroup_edit', {
                         title => 'dtaskgroup edit ',
                         form  => $form_ref,
                       };
    }

};


get "$url_prefix/dtaskgroup/members/" => sub {
    my @results = ();
    template 'dtaskgroup_members', {
                         title => 'dtaskgroup members',
                         dtaskgroup_list_html_select_str => _perform_dtaskgroup_list_html_select_str(),
                       };
};


post '/DTaskGroupMembersStr/' => sub {

    my $dtask_gid = trim(params->{dtaskgroup_id});

    my $respose_msg = '';
    if (is_int_digit($dtask_gid)) {
        $respose_msg = _get_dtaskgroup_members($dtask_gid);
    } else {
        $respose_msg = "invalid dtask_type [$dtask_gid] !";
    }
    content_type 'application/json';
    return to_json { html_members_str => $respose_msg };

};


post '/DTaskGroupMembersStr2/' => sub {

    my $dtask_gid = trim(params->{dtaskgroup_id});

    my $respose_msg = '';
    if (is_int_digit($dtask_gid)) {
        $respose_msg = _get_dtaskgroup_members2($dtask_gid);
    } else {
        $respose_msg = "invalid dtask_type [$dtask_gid] !";
    }
    content_type 'application/json';
    return to_json { html_members_str => $respose_msg };

};


post '/DTaskSelectStr2/' => sub {

    my $dtask_gid = trim(params->{dtaskgroup_id});
    my $respose_msg = '';
    if (is_int_digit($dtask_gid)) {
        my @column_names = get_column_names('vcspr', 'DTask');
        my $where_ref = {
          id => { -not_in => \[
            'SELECT dtask_id FROM DTaskDTGroup WHERE dtask_gid = ?',
            $dtask_gid,
          ]},
        };
        my $schema = schema 'vcspr';
        my @all_records = $schema->resultset('DTask')->search($where_ref, {})->all;
        my @results = convert_records(\@column_names, \@all_records);
        my $html_select_str = '';
        foreach my $result (@results) {
            $html_select_str .= '<option value="' . $result->{'id'} . '">' . $result->{'name'} . '</option>';
        }
        $respose_msg = $html_select_str;
    } else {
        $respose_msg = "invalid dtask_type [$dtask_gid] !";
    }
    content_type 'application/json';
    return to_json { html_select_str => $respose_msg };

};


get "$url_prefix/dtaskgroup/delete/:id/" => sub {
    my $result = _perform_dtaskgroup_delete(params->{id});
    return redirect "$url_prefix/dtaskgroup/list/";
};


##---------------------------------------------------------------------
post "$url_prefix/dtaskdtgroup/add/" => sub {
        my %a_params = (
            dtask_gid => trim(params->{dtaskgroup_id}), 
            dtask_id => trim(params->{dtask_id}),
        );
        my $result_msg = '';
        my $dtask_name = '';
        my $dtaskgroup_name = '';
        if ( $a_params{dtask_gid} ne '' and $a_params{dtask_id} ne '' and is_int_digit($a_params{dtask_gid}) and is_int_digit($a_params{dtask_id}) ) {
            $dtask_name = get_find_record('vcspr', 'DTask', $a_params{dtask_id})->{name};
            $dtaskgroup_name = get_find_record('vcspr', 'DTaskGroup', $a_params{dtask_gid})->{name};
            my $result = _perform_dtaskdtgroup_add(\%a_params);
            $result_msg = "Add DTask [$dtask_name] to DTaskGroup [$dtaskgroup_name] success !\n";
        } else {
            $result_msg = "invalid dtask_gid [ $a_params{dtask_gid} ] or dtask_id [ $a_params{dtask_id} ] !\n";
        }

        content_type 'application/json';
        return to_json { result_msg => $result_msg };

};


post "$url_prefix/dtaskdtgroup/delete/" => sub {
        my %a_params = (
            dtask_gid => trim(params->{dtaskgroup_id}), 
            dtask_id => trim(params->{dtask_id}),
        );
        my $result_msg = '';
        my $dtask_name = '';
        my $dtaskgroup_name = '';
        if ( $a_params{dtask_gid} ne '' and $a_params{dtask_id} ne '' and is_int_digit($a_params{dtask_gid}) and is_int_digit($a_params{dtask_id}) ) {
            $dtask_name = get_find_record('vcspr', 'DTask', $a_params{dtask_id})->{name};
            $dtaskgroup_name = get_find_record('vcspr', 'DTaskGroup', $a_params{dtask_gid})->{name};
            my $result = _perform_dtaskdtgroup_delete(\%a_params);
            $result_msg = "Del DTask [$dtask_name] from DTaskGroup [$dtaskgroup_name] success !\n";
        } else {
            $result_msg = "invalid dtask_gid [ $a_params{dtask_gid} ] or dtask_id [ $a_params{dtask_id} ] !\n";
        }

        content_type 'application/json';
        return to_json { result_msg => $result_msg };

};


##---------------------------------------------------------------------


get "$url_prefix/dtask/list/" => sub {
    my @results = ();
    @results = _perform_dtask_list();
    template 'dtask_list', {
                         title => 'dtask list ',
                         results => \@results,
                       };
};


any ['get', 'post'] => "$url_prefix/dtask/add/" => sub {
    if ( request->method() eq "POST" ) {
        my %a_params = (
            dtaskname => params->{dtaskname},
            d_branch => params->{d_branch},
            d_dir => params->{d_dir},
            f_permissions => params->{f_permissions},
            priority_type => params->{priority_type},
            host => params->{host},
            is_active => params->{is_active},
        );
        my $result = _perform_dtask_add(\%a_params);
        return redirect "$url_prefix/dtask/list/";

    } else {
        my $host_html_select_str = _perform_host_list_html_select_str();
        template 'dtask_add', {
                         title => 'dtask add ',
                         host_html_select_str => $host_html_select_str,
                       };
    }

};


any ['get', 'post'] => "$url_prefix/dtask/edit/:id/" => sub {
    if ( request->method() eq "POST" ) {
        my %a_params = (
            id => params->{id},
            dtaskname => params->{dtaskname},
            d_branch => params->{d_branch},
            d_dir => params->{d_dir},
            f_permissions => params->{f_permissions},
            priority_type => params->{priority_type},
            host => params->{host},
            is_active => params->{is_active},
        );
        my $result = _perform_dtask_edit(\%a_params);
        return redirect "$url_prefix/dtask/list/";

    } else {
        my $form_ref = get_find_record('vcspr', 'DTask', params->{id});
        my $host_html_select_str = _perform_host_list_html_select_str($form_ref->{host});
        template 'dtask_edit', {
                         title => 'dtask edit ',
                         form  => $form_ref,
                         host_html_select_str => $host_html_select_str,
                       };
    }

};



get "$url_prefix/dtask/delete/:id/" => sub {
    my $result = _perform_dtask_delete(params->{id});
    return redirect "$url_prefix/dtask/list/";
};



#get "$url_prefix/dtask/list/" => sub {
#    my @results = ();
#    @results = get_all_records('vcspr', 'DTask');
#    my @column_names = get_column_names('vcspr', 'DTask');
#    template 'simple_list', {
#                         url_prefix => '/dtask',
#                         title => 'dtask list ',
#                         results => \@results,
#                         column_names => \@column_names,
#                       };
#};


##---------------------------------------------------------------------


get "$url_prefix/deploy/" => sub {
    redirect "$url_prefix/deploy/list/";
};


sub get_deploy_form {
    my $d_id = shift @_;
    my $deploy_form = qq{
<form name="form_${d_id}" action="" method="post">
    <label>Type:&nbsp;
    <select name="session_type_${d_id}" id="session_type_${d_id}" onchange="javascript:switch_input(${d_id})">
        <option value="undefined" selected="selected">-----</option>
        <option value="BRANCH">BRANCH</option>
<!--        <option value="TAG">TAG</option>
        <option value="COMMIT">COMMIT</option>
        <option value="REPO">REPO</option>   -->
    </select>
    </label>
&nbsp;
<span id="session_input_${d_id}">  </span>
&nbsp;<a title="" data-original-title="DEPLOY" href="javascript:openprompt(get_confirm_msg, send_deploy_trigger, $d_id, $d_id )" class="btn btn-mini btn-warning"><i class="icon-upload-alt"></i>&nbsp;DEPLOY</a>

</form>

 };
    return $deploy_form;

}


sub get_deploy_form2 {
    my $d_id = shift @_;
    my $deploy_form = qq{
<a title="" data-original-title="DEPLOY" href="javascript:openprompt2( send_deploy_trigger2, $d_id )" class="btn btn-mini btn-warning"><i class="icon-upload-alt"></i>&nbsp;DEPLOY</a>

</form>

 };
    return $deploy_form;

}


get "$url_prefix/deploy/list/" => sub {
    my @results = ();
    @results = _perform_deploy_list();
    template 'deploy_list', {
                         title => 'deploy list ',
                         results => \@results,
                       };
};


any ['get', 'post'] => "$url_prefix/deploy/add/" => sub {
    if ( request->method() eq "POST" ) {
        my %a_params = (
            s_branch => params->{s_branch},
            s_tag => params->{s_tag},
            s_commit_msg => params->{s_commit_msg},
            trigger => params->{trigger},
            dtask_type => params->{dtask_type},
            s_project => params->{s_project},
            dtask_value => params->{dtask_value},
            is_active => params->{is_active},
        );
        my $result = _perform_deploy_add(\%a_params);
        return redirect "$url_prefix/deploy/list/";

    } else {
        my $trigger_html_select_str = _perform_trigger_list_html_select_str();
        my $project_html_select_str = _perform_project_list_html_select_str();
        my $dtask_html_select_str = _perform_dtask_list_html_select_str();
        template 'deploy_add', {
                         title => 'deploy add ',
                         trigger_html_select_str => $trigger_html_select_str,
                         project_html_select_str => $project_html_select_str,
                         dtask_html_select_str => $dtask_html_select_str,
                       };
    }

};


any ['get', 'post'] => "$url_prefix/deploy/edit/:id/" => sub {
    if ( request->method() eq "POST" ) {
        my %a_params = (
            id => params->{id},
            s_branch => params->{s_branch},
            s_tag => params->{s_tag},
            s_commit_msg => params->{s_commit_msg},
            trigger => params->{trigger},
            dtask_type => params->{dtask_type},
            s_project => params->{s_project},
            dtask_value => params->{dtask_value},
            is_active => params->{is_active},
        );
        my $result = _perform_deploy_edit(\%a_params);
        return redirect "$url_prefix/deploy/list/";

    } else {
        my $form_ref = get_find_record('vcspr', 'Deploy', params->{id});
        my $trigger_html_select_str = _perform_trigger_list_html_select_str($form_ref->{trigger});
        my $project_html_select_str = _perform_project_list_html_select_str($form_ref->{s_project});
        my $dtask_html_select_str = '';
        if ($form_ref->{dtask_type} eq 'dtask') {
            $dtask_html_select_str = _perform_dtask_list_html_select_str($form_ref->{dtask_value});
        } else {
            $dtask_html_select_str = _perform_dtaskgroup_list_html_select_str($form_ref->{dtask_value});
        }
        template 'deploy_edit', {
                         title => 'deploy edit ',
                         form  => $form_ref,
                         trigger_html_select_str => $trigger_html_select_str,
                         project_html_select_str => $project_html_select_str,
                         dtask_html_select_str => $dtask_html_select_str,
                       };
    }

};


get "$url_prefix/deploy/delete/:id/" => sub {
    my $result = _perform_deploy_delete(params->{id});
    return redirect "$url_prefix/deploy/list/";
};



##---------------------------------------------------------------------


get "$url_prefix/vcspushlog/" => sub {
    redirect "$url_prefix/vcspushlog/list/";
};


get "$url_prefix/vcspushlog/list/" => sub {
    my @results = ();
    @results = _perform_vcspushlog_list();
    template 'vcspushlog_list', {
                         title => 'vcspushlog list ',
                         results => \@results,
                       };
};


get "$url_prefix/dtasklog/" => sub {
    redirect "$url_prefix/dtasklog/list/";
};


##---------------------------------------------------------------------

get "$url_prefix/dtasklog/list/" => sub {
    my @results = ();
    @results = _perform_dtasklog_list();
    template 'dtasklog_list', {
                         title => 'dtasklog list ',
                         results => \@results,
                       };
};



##++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


sub _perform_user_list {
    
    my @results;
    my @all_user = get_all_records('vcspr', 'User');
    foreach my $user (@all_user) {
       push @results, $user;
    }
    return @results;

}


sub _perform_user_add {
    my $params = shift;
    my $vcspr_schema = schema 'vcspr';
    my $new_user = $vcspr_schema->resultset('User')->create(
        { 
          username => $params->{username}, 
          password => $params->{password}, 
          email => $params->{email},
          info => $params->{info},
          is_active => $params->{is_active}, 
        }
    );
    $new_user->insert();
    return 1;
}


sub _perform_user_edit {
    my $params = shift;
    my $vcspr_schema = schema 'vcspr';
    my @user = $vcspr_schema->resultset('User')->find($params->{id});
    $user[0]->update(
        {
            id => $params->{id},
            username => $params->{username},
            password => $params->{password},
            email => $params->{email},
            info => $params->{info},
            is_active => $params->{is_active}, 
        }
    );

}


sub _perform_user_delete {
    my $user_id = shift;
    my $vcspr_schema = schema 'vcspr';
    my @users = $vcspr_schema->resultset('User')->find($user_id);
    if ( @users ) {
        $users[0]->delete();
    }
}


sub _perform_host_add {
    my $params = shift;
    my $vcspr_schema = schema 'vcspr';
    my $new_host = $vcspr_schema->resultset('Host')->create(
        { name => $params->{hostname}, 
          alias_name => $params->{alias_name}, 
          ip => $params->{ip}, 
          info => $params->{info},
        }
    );
    $new_host->insert();
    return 1;
}


sub _perform_host_edit {
    my $params = shift;
    my $vcspr_schema = schema 'vcspr';
    my @host = $vcspr_schema->resultset('Host')->find($params->{id});
    $host[0]->update(
        { 
          name => $params->{hostname},
          alias_name => $params->{alias_name},
          ip         => $params->{ip},
          info       => $params->{info},
        }
    );

}


sub  _perform_host_list_html_select_str {
    my $host_id;
    my $has_p = 0;
    if (@_ > 0) {
        $has_p = 1;
        $host_id = shift @_;
    }
    
    my $html_select_str;
    my @all_host = get_all_records('vcspr', 'Host');
    foreach my $host (@all_host) {
       if ( $has_p == 1 and $host->{id} == $host_id) {
       $html_select_str .= "                                                                                                <option value=\"$host->{id}\" selected=\"selected\">$host->{name}</option>\n";
       } else {
       $html_select_str .= "                                                                                                <option value=\"$host->{id}\">$host->{name}</option>\n";
       }
    }
    return $html_select_str;
}


sub _perform_host_delete {
    my $host_id = shift;
    my $vcspr_schema = schema 'vcspr';
    my @hosts = $vcspr_schema->resultset('Host')->find($host_id);
    if ( @hosts ) {
        $hosts[0]->delete();
    }


}


sub _perform_vcs_list {
    
    my @results;
    my @all_vcs = get_all_records('vcspr', 'VCS');
    foreach my $vcs (@all_vcs) {
       push @results, $vcs;
    }
    return @results;

}


sub _perform_vcs_add {
    my $params = shift;
    my $vcspr_schema = schema 'vcspr';
    my $new_vcs = $vcspr_schema->resultset('VCS')->create(
        { name => $params->{vcsname},
          alias_name => $params->{alias_name},
          type => $params->{type},
          source => $params->{source},
          api_uri => $params->{api_uri},
          api_private_token => $params->{api_private_token},
          info => $params->{info},
          is_active => $params->{is_active},
        }
    );
    $new_vcs->insert();
    return 1;
}



sub _perform_vcs_edit {
    my $params = shift;
    my $vcspr_schema = schema 'vcspr';
    my @vcs = $vcspr_schema->resultset('VCS')->find($params->{id});
    $vcs[0]->update(
        {
          name => $params->{vcsname},
          alias_name => $params->{alias_name},
          alias_name => $params->{alias_name},
          type => $params->{type},
          source => $params->{source},
          api_uri => $params->{api_uri},
          api_private_token => $params->{api_private_token},
          info => $params->{info},
          is_active => $params->{is_active},
        }
    );

}


sub  _perform_vcs_list_html_select_str {
    my $vcs_id;
    my $has_p = 0;
    if (@_ > 0) {
        $has_p = 1;
        $vcs_id = shift @_;
    }
   
    my $html_select_str; 
    if ( $has_p == 1 ) {
        $html_select_str .= "<option value=\"undefined\">-----</option>\n";
    } else {
        $html_select_str .= "<option value=\"undefined\" selected=\"selected\">-----</option>\n";
    }

    my @all_vcs = get_all_records('vcspr', 'VCS');
    foreach my $vcs (@all_vcs) {
       if ( $has_p == 1 and $vcs->{id} == $vcs_id) {
       $html_select_str .= "                                                                                                <option value=\"$vcs->{id}\" selected=\"selected\">$vcs->{name}</option>\n";
       } else {
       $html_select_str .= "                                                                                                <option value=\"$vcs->{id}\">$vcs->{name}</option>\n";
       }
    }
    return $html_select_str;
}


sub _perform_vcs_delete {
    my $vcs_id = shift;
    my $vcspr_schema = schema 'vcspr';
    my @vcss = $vcspr_schema->resultset('VCS')->find($vcs_id);
    if ( @vcss ) {
        $vcss[0]->delete();
    }


}


sub _perform_project_list {
    my $vcspr_schema = schema 'vcspr';
    my @results;
    my @all_project = get_all_records('vcspr', 'Project');
    foreach my $project (@all_project) {
       $project->{'vcs_id'} = $project->{'vcs'};
       $project->{'vcs_name'} = $vcspr_schema->resultset('VCS')->find($project->{vcs})->name;
       push @results, $project;
    }
    return @results;

}


sub _perform_project_add {
    my $params = shift;
    my $vcspr_schema = schema 'vcspr';
    my $new_project = $vcspr_schema->resultset('Project')->create(
        { name => $params->{projectname},
          alias_name => $params->{alias_name},
          repo => $params->{repo},
          proj_id => $params->{proj_id},
          info => $params->{info},
          is_active => $params->{is_active},
          vcs => $params->{vcs},
        }
    );
    $new_project->insert();
    return 1;
}


sub _perform_project_edit {
    my $params = shift;
    my $vcspr_schema = schema 'vcspr';
    my @project = $vcspr_schema->resultset('Project')->find($params->{id});
    $project[0]->update(
        {
          name => $params->{projectname},
          alias_name => $params->{alias_name},
          repo => $params->{repo},
          proj_id => $params->{proj_id},
          info => $params->{info},
          is_active => $params->{is_active},
          vcs => $params->{vcs},
        }
    );

}


sub  _perform_project_list_html_select_str {
    my $project_id;
    my $has_p = 0;
    if (@_ > 0) {
        $has_p = 1;
        $project_id = shift @_;
    }
    
    my $html_select_str; 
    if ( $has_p == 1 ) {
        $html_select_str .= "<option value=\"undefined\">-----</option>\n";
    } else {
        $html_select_str .= "<option value=\"undefined\" selected=\"selected\">-----</option>\n";
    }

    my @all_project = get_all_records('vcspr', 'Project');
    foreach my $project (@all_project) {
       if ( $has_p == 1 and $project->{id} == $project_id) {
       $html_select_str .= "                                                                                                <option value=\"$project->{id}\" selected=\"selected\">$project->{name}</option>\n";
       } else {
       $html_select_str .= "                                                                                                <option value=\"$project->{id}\">$project->{name}</option>\n";
       }
    }
    return $html_select_str;
}


sub _perform_project_delete {
    my $project_id = shift;
    my $vcspr_schema = schema 'vcspr';
    my @projects = $vcspr_schema->resultset('Project')->find($project_id);
    if ( @projects ) {
        $projects[0]->delete();
    }

}


sub _get_dtaskgroup_members {
    my $dtaskgroup_id = shift;
    my $all_members_str = '<table>';
    my @all_dtaskdtgroup = get_all_records('vcspr', 'DTaskDTGroup', undef, {'dtask_gid' => $dtaskgroup_id});
    foreach my $dtaskdtgroup (@all_dtaskdtgroup) {
        my $dtask_record = get_find_record('vcspr', 'DTask', $dtaskdtgroup->{'dtask_id'});
        #$all_members_str .= '<a href="/dtask/edit/' . $dtask_record->{'id'} . '/">' . $dtask_record->{'name'} . '</a>,&nbsp;&nbsp;';
        $all_members_str .= '<tr><td><a href="/dtask/edit/' . $dtask_record->{'id'} . '/">' . $dtask_record->{'name'} . '</a><td></tr>';
    }
    $all_members_str .= '</table>';
    return  $all_members_str;
}


sub _get_dtaskgroup_members2 {
    my $dtaskgroup_id = shift;
    my $all_members_str = '<table>';
    my @all_dtaskdtgroup = get_all_records('vcspr', 'DTaskDTGroup', undef, {'dtask_gid' => $dtaskgroup_id});
    foreach my $dtaskdtgroup (@all_dtaskdtgroup) {
        my $dtask_record = get_find_record('vcspr', 'DTask', $dtaskdtgroup->{'dtask_id'});
        $all_members_str .= '<tr><td><a href="/dtask/edit/' . $dtask_record->{'id'} . '/">' . $dtask_record->{'name'} . '</a><td><td><a href="javascript:del_dtask_from_dtaskgroup(' . $dtaskdtgroup->{'dtask_gid'} . ', ' . $dtaskdtgroup->{'dtask_id'} . ')" data-original-title="Delete" class="btn btn-mini btn-danger bootbox-confirm"><i class="icon-trash"></i>&nbsp;Delete</a></td></tr>';
    }
    $all_members_str .= '</table>';
    return  $all_members_str;
}


sub _perform_dtaskdtgroup_delete {
    my $params = shift;
    my $vcspr_schema = schema 'vcspr';
    my $dtaskdtgroup = $vcspr_schema->resultset('DTaskDTGroup')->search(
        { dtask_id => $params->{dtask_id}, 
          dtask_gid => $params->{dtask_gid},
        }, {}
    )->delete();
    return 1;
}


sub _perform_dtaskgroup_list {
    
    my @results;
    my @all_dtaskgroup = get_all_records('vcspr', 'DTaskGroup');
    foreach my $dtaskgroup (@all_dtaskgroup) {
        $dtaskgroup->{member} = _get_dtaskgroup_members($dtaskgroup->{'id'}); 
        push @results, $dtaskgroup;
    }
    return @results;

}


sub _perform_dtaskgroup_add {
    my $params = shift;
    my $vcspr_schema = schema 'vcspr';
    my $new_dtaskgroup = $vcspr_schema->resultset('DTaskGroup')->create(
        { name => $params->{dtaskgroupname}, 
          info => $params->{info},
          is_active => $params->{is_active}, 
        }
    );
    $new_dtaskgroup->insert();
    return 1;
}


sub _perform_dtaskgroup_edit {
    my $params = shift;
    my $vcspr_schema = schema 'vcspr';
    my @dtaskgroup = $vcspr_schema->resultset('DTaskGroup')->find($params->{id});
    $dtaskgroup[0]->update(
        { 
          name => $params->{dtaskgroupname},
          info       => $params->{info},
          is_active => $params->{is_active}, 
        }
    );

}


sub _perform_dtaskgroup_delete {
    my $dtaskgroup_id = shift;
    my $vcspr_schema = schema 'vcspr';
    my @dtaskgroups = $vcspr_schema->resultset('DTaskGroup')->find($dtaskgroup_id);
    if ( @dtaskgroups ) {
        $dtaskgroups[0]->delete();
    }
}


sub  _perform_dtaskgroup_list_html_select_str {
    my $dtaskgroup_id;
    my $has_p = 0;
    if (@_ > 0) {
        $has_p = 1;
        $dtaskgroup_id = shift @_;
    }
    
    my $html_select_str;
    my @all_dtaskgroup = get_all_records('vcspr', 'DTaskGroup');
    foreach my $dtaskgroup (@all_dtaskgroup) {
       if ( $has_p == 1 and $dtaskgroup->{id} == $dtaskgroup_id) {
       $html_select_str .= "                                                                                                <option value=\"$dtaskgroup->{id}\" selected=\"selected\">$dtaskgroup->{name}</option>\n";
       } else {
       $html_select_str .= "                                                                                                <option value=\"$dtaskgroup->{id}\">$dtaskgroup->{name}</option>\n";
       }
    }
    return $html_select_str;
}


sub _perform_dtaskdtgroup_add {
    my $params = shift;
    my $vcspr_schema = schema 'vcspr';
    my $new_dtaskdtgroup = $vcspr_schema->resultset('DTaskDTGroup')->create(
        { dtask_gid => $params->{dtask_gid}, 
          dtask_id => $params->{dtask_id},
        }
    );
    $new_dtaskdtgroup->insert();
    return $new_dtaskdtgroup;
}


sub _perform_dtask_list {
    my $vcspr_schema = schema 'vcspr';
    my @results;
    my @all_dtask = get_all_records('vcspr', 'DTask');
    foreach my $dtask (@all_dtask) {
       $dtask->{'host_id'} = $dtask->{'host'};
       $dtask->{'host_name'} = $vcspr_schema->resultset('Host')->find($dtask->{host})->name;
       push @results, $dtask;
    }
    return @results;

}



sub _perform_dtask_add {
    my $params = shift;
    my $vcspr_schema = schema 'vcspr';
    my $new_dtask = $vcspr_schema->resultset('DTask')->create(
        { name => $params->{dtaskname},
          d_branch => params->{d_branch},
          d_dir => params->{d_dir},
          f_permissions => params->{f_permissions},
          priority_type => params->{priority_type},
          host => params->{host},
          is_active => params->{is_active},
        }
    );
    $new_dtask->insert();
    return 1;
}


sub _perform_dtask_edit {
    my $params = shift;
    my $vcspr_schema = schema 'vcspr';
    my @dtask = $vcspr_schema->resultset('DTask')->find($params->{id});
    $dtask[0]->update(
        {
          name => $params->{dtaskname},
          d_branch => $params->{d_branch},
          d_dir => $params->{d_dir},
          f_permissions => $params->{f_permissions},
          priority_type => $params->{priority_type},
          host => $params->{host},
          is_active => $params->{is_active},
        }
    );

}


sub  _perform_dtask_list_html_select_str {
    my $dtask_id;
    my $has_p = 0;
    if (@_ > 0) {
        $has_p = 1;
        $dtask_id = shift @_;
    }
    
    my $html_select_str;
    my @all_dtask = get_all_records('vcspr', 'DTask');
    foreach my $dtask (@all_dtask) {
       if ( $has_p == 1 and $dtask->{id} == $dtask_id) {
       $html_select_str .= "                                                                                                <option value=\"$dtask->{id}\" selected=\"selected\">$dtask->{name}</option>\n";
       } else {
       $html_select_str .= "                                                                                                <option value=\"$dtask->{id}\">$dtask->{name}</option>\n";
       }
    }
    return $html_select_str;
}


sub _perform_dtask_delete {
    my $dtask_id = shift;
    my $vcspr_schema = schema 'vcspr';
    my @dtasks = $vcspr_schema->resultset('DTask')->find($dtask_id);
    if ( @dtasks ) {
        $dtasks[0]->delete();
    }

}


sub _perform_deploy_list {
    my $vcspr_schema = schema 'vcspr';
    my @results;
    my @all_deploys = get_all_records('vcspr', 'Deploy');
    foreach my $deploy (@all_deploys) {
       $deploy->{'project_id'} = $deploy->{'s_project'};
       $deploy->{'s_project_name'} = $vcspr_schema->resultset('Project')->find($deploy->{s_project})->name;
       if ( $deploy->{'dtask_type'} eq 'group' ) {
           $deploy->{'dtaskgroup_id'} =      $deploy->{'dtask_value'};
           $deploy->{'dtaskgroup_name'} = $vcspr_schema->resultset('DTaskGroup')->find($deploy->{dtask_value})->name;
       } else {
           $deploy->{'dtask_id'} =      $deploy->{'dtask_value'};
           $deploy->{'dtask_name'} = $vcspr_schema->resultset('DTask')->find($deploy->{dtask_value})->name;
       }
       $deploy->{'deploy_form'} = get_deploy_form2($deploy->{id});
       push @results, $deploy;
    }
    return @results;

}


sub _perform_deploy_add {
    my $params = shift;
    my $vcspr_schema = schema 'vcspr';
    my $new_deploy = $vcspr_schema->resultset('Deploy')->create(
        { 
          s_branch => $params->{s_branch},
          s_tag => $params->{s_tag},
          s_commit_msg => $params->{s_commit_msg},
          trigger => $params->{trigger},
          dtask_type => $params->{dtask_type},
          s_project => $params->{s_project},
          dtask_value => $params->{dtask_value},
          is_active => $params->{is_active},
        }
    );
    $new_deploy->insert();
    return 1;
}


sub _perform_deploy_edit {
    my $params = shift;
    my $vcspr_schema = schema 'vcspr';
    my @deploy = $vcspr_schema->resultset('Deploy')->find($params->{id});
    $deploy[0]->update(
        {
          s_branch => $params->{s_branch},
          s_tag => $params->{s_tag},
          s_commit_msg => $params->{s_commit_msg},
          trigger => $params->{trigger},
          dtask_type => $params->{dtask_type},
          s_project => $params->{s_project},
          dtask_value => $params->{dtask_value},
          is_active => $params->{is_active},
        }
    );

}


sub _perform_deploy_delete {
    my $deploy_id = shift;
    my $vcspr_schema = schema 'vcspr';
    my @deploys = $vcspr_schema->resultset('Deploy')->find($deploy_id);
    if ( @deploys ) {
        $deploys[0]->delete();
    }

}


sub _perform_vcspushlog_list {
    
    my @results;
    my $order_by_ref = { -desc => 'id' };
    my @all_vcspushlog = get_all_records('vcspr', 'VCSPushLog', $order_by_ref);
    foreach my $vcspushlog (@all_vcspushlog) {
       my $timestamp = trans_standtime_to_timestamp($vcspushlog->{create_date});
       $vcspushlog->{'create_date'} = get_date('%s', '', $timestamp);       
       push @results, $vcspushlog;
    }
    return @results;

}


sub _perform_dtasklog_list {
    
    my @results;
    my $order_by_ref = { -desc => 'id' };
    my @all_dtasklog = get_all_records('vcspr', 'DTaskLog', $order_by_ref);
    foreach my $dtasklog (@all_dtasklog) {
       my $timestamp = trans_standtime_to_timestamp($dtasklog->{create_date});
       $dtasklog->{'x_date'} = get_date('%s', '', $timestamp);
       push @results, $dtasklog;
    }
    return @results;

}


sub _perform_trigger_list_html_select_str {
    my $trigger_val;
    my $has_p = 0;
    if (@_ > 0) {
        $has_p = 1;
        $trigger_val = shift @_;
    }
    
    my $html_select_str;
    my @all_trigger = (
        {
            name => 'AUTO', 
            val  => 'AUTO',
        },
        {
            name => 'MANUAL',
            val  => 'MANUAL',
        },
        {
            name => 'BRANCH',
            val  => 'BRANCH',
        },
        {
            name => 'MERGE_DEPLOY',
            val  => 'MERGE_DEPLOY',
        },
        {
            name => 'COMMIT_MSG',
            val  => 'COMMIT_MSG',
        },
        {
            name => 'TAG',
            val  => 'TAG',
        },
        {
            name => 'NONE',
            val  => 'NONE',
        },
    );

    foreach my $trigger (@all_trigger) {
       if ( $has_p == 1 and $trigger->{val} eq $trigger_val) {
       $html_select_str .= "                                                                                                <option value=\"$trigger->{val}\" selected=\"selected\">$trigger->{name}</option>\n";
       } else {
       $html_select_str .= "                                                                                                <option value=\"$trigger->{val}\">$trigger->{name}</option>\n";
       }
    }
    return $html_select_str;

}


sub _perform_vcs_type_list_html_select_str {
    my $vcs_type_val;
    my $has_p = 0;
    if (@_ > 0) {
        $has_p = 1;
        $vcs_type_val = shift @_;
    }
    
    my $html_select_str;
    my @all_vcs_type = (
        {
            name => 'gitlab',
            val  => 'gitlab',
        },
        {
            name => 'gitblit',
            val  => 'gitblit',
        },
        {
            name => 'git',
            val  => 'git',
        },
        {
            name => 'github',
            val  => 'github',
        },
        {
            name => 'svn',
            val  => 'svn',
        },
    );

    foreach my $vcs_type (@all_vcs_type) {
       if ( $has_p == 1 and $vcs_type->{val} eq $vcs_type_val) {
       $html_select_str .= "                                                                                                <option value=\"$vcs_type->{val}\" selected=\"selected\">$vcs_type->{name}</option>\n";
       } else {
       $html_select_str .= "                                                                                                <option value=\"$vcs_type->{val}\">$vcs_type->{name}</option>\n";
       }
    }
    return $html_select_str;

}


true;
