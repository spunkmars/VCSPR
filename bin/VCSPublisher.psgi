#!/usr/bin/perl
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";
use utf8;

#use Plack::App::URLMap;
use Plack::Builder;
use Plack::Request;
use Dancer ':syntax';
use Dancer::Handler;

use POSIX;
use POSIX ":sys_wait_h";
$SIG{CHLD}='IGNORE'; #忽略对子进程的CHLD信号，避免子进程变成僵尸进程。

use SPMR::COMMON::MyCOMMON qw(DD l_debug $L_DEBUG);
$L_DEBUG = 1;

use VCSPublisher;


my $url_prefix='/VCS';

my $publisher = VCSPublisher->new();

my $SGitblitPush = sub {
    my ($req_info, $exec_status) = @_;
    my $post_ref = $req_info->{'req'}->body_parameters;
    my $git_push_data = $publisher->json_to_data($post_ref->{git_push_info});
    my $child = fork();
    if ($child == 0) {
        #$publisher->init_database();

        $publisher->record_vcs_push_log($git_push_data);
        $publisher->deploy($git_push_data);
        exit;
    }
    my %info = (
        );
    $exec_status->{'code'} = 1;
    $exec_status->{'message'} = 'Action completed successful';
    return \%info;
};


my $GitblitPush = sub {
    return $publisher->DTaskBase( shift, $SGitblitPush );
};

##################



my $SGitLabPush = sub {
    my ($req_info, $exec_status) = @_;
    my $post_ref = $req_info->{'req'}->content;
    my $git_push_data;
    my $child = fork();
    if ($child == 0) {

        $git_push_data = $publisher->json_to_data($post_ref);
        $git_push_data = $publisher->convert_git_push_data($git_push_data);
        $publisher->record_vcs_push_log($git_push_data);
        $publisher->deploy($git_push_data);
        exit;
    }
    my %info = (
        );
    $exec_status->{'code'} = 1;
    $exec_status->{'message'} = 'Action completed successful';
    return \%info;
};


my $GitLabPush = sub {
    $publisher->{'verify_level'} = 'basic';
    return $publisher->DTaskBase( shift, $SGitLabPush );
};


##################

my $SManualTrigger = sub {
    my ($req_info, $exec_status) = @_;
    my $post_ref = $req_info->{'post'};

    my $child = fork();
    if ($child == 0) {
        $publisher->deploy_by_trigger($post_ref->{data});
        exit;
    }
    my %info = (
        );
    $exec_status->{'code'} = 1;
    $exec_status->{'message'} = 'Action completed successful';
    return \%info;
};


my $ManualTrigger = sub {
    $publisher->{'verify_level'} = 'normal';
    return $publisher->DTaskBase( shift, $SManualTrigger );
};



##################
my $LResultReceive = sub {
    my ($req_info, $exec_status) = @_;
    my $post_ref = $req_info->{'post'};

    my $exec_dtask_report = $publisher->json_to_data($post_ref->{data});
    my $child = fork();
    if ($child == 0) {
        $publisher->record_exec_dtask_log( $exec_dtask_report );
        exit;
    }
    my %info = (
        );
    $exec_status->{'code'} = 1;
    $exec_status->{'message'} = 'Action completed successful';
    return \%info;

};


my $ResultReceive = sub {
    #$publisher->{'verify_level'} = 'normal';
    return $publisher->DTaskBase( shift, $LResultReceive );
};


my $MGetDTaskStatus = sub {
    my ($req_info, $exec_status) = @_;
    my $post_ref = $req_info->{'post'};
    my %info = (
        );
    my $exec_dtask_data = $publisher->get_dtask_status($post_ref->{data});
    $info{'repo_status'} = $exec_dtask_data->{data}->{info}->{repo_status};
    $exec_status->{'code'} = $exec_dtask_data->{exec_code};;
    $exec_status->{'message'} = 'Action completed successful';
    return \%info;
};


my $GetDTaskStatus = sub {
    #$publisher->{'verify_level'} = 'normal';
    return $publisher->DTaskBase( shift, $MGetDTaskStatus );
};


my $SMergeDeploy = sub {
    my ($req_info, $exec_status) = @_;
    my $post_ref = $req_info->{'post'};
    my %info = (
        );
    my ($is_merge_ok, $merge_msg) = (0, '');
    ($is_merge_ok, $merge_msg) = $publisher->merge_repo($post_ref->{data});
    my $child;
    if ($is_merge_ok == 1) {
        $child = fork();
        if ($child == 0) {
            $publisher->deploy_by_trigger($post_ref->{data});
            exit;
        }

        $info{'merge_status'} = { 
            'merge_msg' => "Merge Repo success : $merge_msg !",
            'merge_code' => 1,
        };

    } else {
        $info{'merge_status'} = { 
            'merge_msg' => "Merge Repo Fail : $merge_msg !",
            'merge_code' => 8,
        };
    }

    return \%info;
};


my $MergeDeploy = sub {
    #$publisher->{'verify_level'} = 'normal';
    return $publisher->DTaskBase( shift, $SMergeDeploy );
};


builder {
    mount "${url_prefix}/Gitblit.Push" => $GitblitPush;
    mount "${url_prefix}/GitLab.Push" => $GitLabPush;
    mount "${url_prefix}/Result.Receive" => $ResultReceive;
    mount "${url_prefix}/ManualTrigger.Receive" => $ManualTrigger;
    mount "${url_prefix}/DTask.Status" => $GetDTaskStatus;
    mount "${url_prefix}/MergeDeploy.Receive" => $MergeDeploy;
};
