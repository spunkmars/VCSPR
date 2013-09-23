use utf8;
package ManualTrigger;
use FindBin;
use lib "$FindBin::Bin/../../../lib";

use base 'APIBase';

use URI;
use SPMR::COMMON::MyCOMMON qw(DD l_debug $L_DEBUG is_int_digit);
$L_DEBUG = 1;
use SPMR::DBI::MyDBISqlite;

sub new {
    my $invocant  = shift;
    my ( $cc ) = @_;
    my $self      = bless( {}, ref $invocant || $invocant );
    my %options = (
        );

    my $pub_conf = $self->read_config("$FindBin::Bin/../../../etc/publisher.xml");
    $self->{pub_conf} = $pub_conf;

    my $sqlite_file = $self->{pub_conf}->{db_info}->{db_file};
    my $dsn = "dbi:SQLite:dbname=${sqlite_file}";
    $self->{mysqlite} = SPMR::DBI::MyDBISqlite->new($dsn);
    $self->{pub_host} = $self->{pub_conf}->{app_info}->{listen_host};

    $options{'conf_info'} = $self->{pub_conf};
    $options{'is_encrypt'} = 1;
    $options{'force_encrypt'} = 1;
    $options{'is_verify'} = 1;

    $self->init( \%options );

    
    return $self;
}


sub init {
    my $self = shift @_;
    $self->SUPER::init( @_);
}


sub get_data_from_gitlab {
    my $self = shift @_;
    my ($uri_prefix, $uri_path, $private_token) = @_;
    my $uri = ${uri_prefix} . ${uri_path};
    my $sender_info = {};
    $sender_info->{'http_method'} = 'get';
    
    $sender_info->{'header'} = {
        'PRIVATE-TOKEN' => $private_token,
        'User-Agent'   => $self->{pub_conf}->{app_info}->{agent},
    };
    my $send_data = {};
    my $receive_data = $self->send_http_to_host($uri, $send_data, $sender_info);

    if ( $receive_data->{'is_success'} == 1 ){
        $receive_data->{'data'} = $self->json_to_data($receive_data->{'raw_content'});
    }
    return $receive_data;
}


sub get_vcs_source_by_deploy_id {



}


sub get_proj_id_by_deploy_id {
    my $self = shift @_;
    my $d_id = shift @_;

    my $sql = "SELECT * FROM Deploy WHERE is_active=1 AND id='" . $d_id ."'";
    $self->{mysqlite}->connect_DB();
    my $deploys_ref = $self->{mysqlite}->get_table_from_query('hash_ref', $sql);

    my $project = $deploys_ref->{'s_project'};
    $sql = "SELECT * FROM Project WHERE is_active=1 AND id='" . $project ."'";
    my $proj_ref = $self->{mysqlite}->get_table_from_query('hash_ref', $sql);

    my $proj_id = $proj_ref->{'proj_id'};

    $self->{mysqlite}->disconnect_DB();
    return $proj_id;
}


sub get_proj_info_by_deploy_id {
    my $self = shift @_;
    my $d_id = shift @_;

    my $sql = "SELECT * FROM Deploy WHERE is_active=1 AND id='" . $d_id ."'";
    $self->{mysqlite}->connect_DB();
    my $deploys_ref = $self->{mysqlite}->get_table_from_query('hash_ref', $sql);

    my $project = $deploys_ref->{'s_project'};
    $sql = "SELECT * FROM Project WHERE is_active=1 AND id='" . $project ."'";
    my $proj_ref = $self->{mysqlite}->get_table_from_query('hash_ref', $sql);

    my $proj_id = $proj_ref->{'proj_id'};


    $sql = "SELECT * FROM VCS WHERE is_active=1 AND id='" . $proj_ref->{'vcs'} ."'";
    my $vcs_ref = $self->{mysqlite}->get_table_from_query('hash_ref', $sql);

    my $proj_vcs_api_uri = $vcs_ref->{'api_uri'};
    my $proj_private_token = $vcs_ref->{'api_private_token'};

    my %proj_info = (
        'proj_id' => $proj_id,
        'proj_private_token' => $proj_private_token,
        'proj_vcs_api_uri' => $proj_vcs_api_uri,
    );
    $self->{mysqlite}->disconnect_DB();
    return \%proj_info;
}


sub get_vcs_info_by_vcs_id {
    my $self = shift @_;
    my $v_id = shift @_;
    my $sql = "SELECT * FROM VCS WHERE is_active=1 AND id='" . $v_id ."'";
    $self->{mysqlite}->connect_DB();
    my $vcs_ref = $self->{mysqlite}->get_table_from_query('hash_ref', $sql);
    $self->{mysqlite}->disconnect_DB();
    return $vcs_ref;


}


sub get_d_branch_deploy_id {
    my $self = shift @_;
    my $d_id = shift @_;
    my $sql = "SELECT * FROM Deploy WHERE is_active=1 AND id='" . $d_id ."'";
    $self->{mysqlite}->connect_DB();
    my $deploys_ref = $self->{mysqlite}->get_table_from_query('hash_ref', $sql);

    my $dtask_id = $deploys_ref->{'dtask_value'};
    $sql = "SELECT * FROM DTask WHERE is_active=1 AND id='" . $dtask_id ."'";
    my $dtask_ref = $self->{mysqlite}->get_table_from_query('hash_ref', $sql);

    my $d_branch = $dtask_ref->{'d_branch'};

    $self->{mysqlite}->disconnect_DB();
    return $d_branch;

}


sub send_trigger {
    my $self = shift @_;
    my ($trigger_data) = @_;
    my $uri = URI->new();
    $uri->scheme('http');
    $uri->host($self->{pub_host});
    $uri->port(5001);
    $uri->path('/VCS/ManualTrigger.Receive');  
    my $trigger_url  = $uri->as_string;
    my $report_d = $self->send_data_to_host($trigger_url, $trigger_data);
    return $report_d;
}


sub get_repo_status {
    my $self = shift @_;
    my ($req_data) = @_;
    my $uri = URI->new();
    $uri->scheme('http');
    $uri->host($self->{pub_host});
    $uri->port(5001);
    $uri->path('/VCS/DTask.Status');  
    my $repo_status_url  = $uri->as_string;
    my $report_d = $self->send_data_to_host($repo_status_url, $req_data);
    return $report_d;

}

sub merge_deploy {
    my $self = shift @_;
    my ($req_data) = @_;
    my $uri = URI->new();
    $uri->scheme('http');
    $uri->host($self->{pub_host});
    $uri->port(5001);
    $uri->path('/VCS/MergeDeploy.Receive');  
    my $repo_status_url  = $uri->as_string;
    my $report_d = $self->send_data_to_host($repo_status_url, $req_data);
    return $report_d;

}


1;
