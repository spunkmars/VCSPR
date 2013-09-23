#!/usr/bin/perl
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";
use utf8;

use Plack::Builder;
use Plack::Request;

use POSIX;
use POSIX ":sys_wait_h";
$SIG{CHLD}='IGNORE'; #忽略对子进程的CHLD信号，避免子进程变成僵尸进程。

use SPMR::COMMON::MyCOMMON qw(DD l_debug $L_DEBUG);
$L_DEBUG = 1;

use VCSReceiver;

my $url_prefix='/Deploy';

my $receiver = VCSReceiver->new();

my $MDTaskDo = sub {
    my ($req_info, $exec_status) = @_;

    my $post_ref = $req_info->{'post'};


    my $command_data = $receiver->json_to_data($post_ref->{data});
    my $child = fork(); 
    if ($child == 0) {
        $receiver->exec_dtask($command_data);
        exit;
    }
    my %info = (
    );
    $exec_status->{'code'} = 1;
    $exec_status->{'message'} = 'Action completed successful';
    return \%info;
};


my $MGetDTaskStatus = sub {

    my ($req_info, $exec_status) = @_;

    my $post_ref = $req_info->{'post'};

    my %info = (
    );

    my $command_data = $receiver->json_to_data($post_ref->{data});
    my $exec_dtask_report = $receiver->get_dtask_status($command_data);
  
    $info{'repo_status'} = $exec_dtask_report->{repo_status};

    $exec_status->{'code'} = 1;
    $exec_status->{'message'} = 'Action completed successful';
    return \%info;
};


my $DTaskList = sub {
    return $receiver->DTaskBase( shift, $MDTaskDo );
};


my $DTaskDo = sub {
    #$receiver->{'verify_level'} = 'normal';
    return $receiver->DTaskBase( shift, $MDTaskDo );
};


my $DTaskAdd = sub {
    return $receiver->DTaskBase( shift, $MDTaskDo );
};


my $GetDTaskStatus = sub {
    return $receiver->DTaskBase( shift, $MGetDTaskStatus );
};

builder {
    mount "${url_prefix}/DTask.List" => $DTaskList;
    mount "${url_prefix}/DTask.Do" => $DTaskDo;
    mount "${url_prefix}/DTask.Add" => $DTaskAdd;
    mount "${url_prefix}/DTask.Status" => $GetDTaskStatus;
};
