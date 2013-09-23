package APIBase;

use base 'Exporter';
use vars qw/@EXPORT/;
@EXPORT = qw();

use base 'APICommon';

use strict;
use warnings;

use utf8;
use Carp;
#$SIG{__DIE__} =  \&confess;
#$SIG{__WARN__} = \&confess;

use Plack::Builder;
use Plack::Request;

use SPMR::COMMON::MyCOMMON qw(DD l_debug $L_DEBUG is_exist_in_array);
$L_DEBUG = 1;
use Encrypt;

use constant  IS_ENCRYPT => 1;  #设置是否启用通信加密。
use constant  FORCE_ENCRYPT => 1; #强制返回Response数据都启用加密[会导致无法接收非加密的gitlab push信息]。
use constant  IS_VERIFY => 1;   #设置是否启用验证模块。

sub new {
    my $invocant  = shift;
    my ($options_ref) = @_;
    my $self      = bless( {}, ref $invocant || $invocant );
    my %options = (
        );

    if (defined $options_ref) {
        if (ref $options_ref eq 'HASH') {
            %options = (%options, %$options_ref);
        } else {
            confess "\$options_ref must be an HASH ref";
        }
    }
    $self->init(%options);

    return $self;
}


sub init {

    my $self = shift;
    my $enc = Encrypt->new( {
            'key_basedir'  => '/opt/VCSPR/data/keys',
            'rsa_keyname'  => 'default',
            'rsa_keypass'  => '2T_qZn7-X4gHxmwrLPGley',
    } );

    $self->{'enc'} = $enc;

    my $options_ref = shift @_;
    my $conf_info = $options_ref->{'conf_info'};

    $self->{'is_encrypt'} = exists $options_ref->{'is_encrypt'}?$options_ref->{'is_encrypt'}:IS_ENCRYPT;
    $self->{'force_encrypt'} = exists $options_ref->{'force_encrypt'}?$options_ref->{'force_encrypt'}:FORCE_ENCRYPT;

    $self->{'is_verify'} = exists $options_ref->{'is_verify'}?$options_ref->{'is_verify'}:IS_VERIFY;

    $self->{sender_info} = {
        'agent'         => 'DepolyClient/0.1.2',
        'agent_ver'         => '0.1.2',
        'version'       => '0.1.2',
        'host'          => '',
        'from'          => 'vcspr@spunkmars.org',
        'username'      => 'admin',
        'password'      => 'admin123',
        'format'        => 'json',
        'lang'          => 'en',
        'timeout'       =>  10,
    };

    $self->{conf} = $conf_info;
    my $sender = $self->{conf}->{send_info};
    $sender->{agent} = $self->{conf}->{app_info}->{agent};
    $sender->{agent_ver} = $self->{conf}->{app_info}->{agent_ver};
    
    $self->{sender} = (defined $sender)?$sender:{};
    my %tmp_sender = (%{$self->{sender_info}}, %{$self->{sender}});
    $self->{sender_info} = \%tmp_sender;
    $self->{sender_info}->{'header'} = {
        #'Content-Type' => 'application/x-www-form-urlencoded',
        'Content-Type' => 'application/json',
        #'PRIVATE-TOKEN' => 'vvvvvv',
        'User-Agent'   => $sender->{agent},
        'From'   =>  $self->{sender_info}->{'from'},
    };

    $self->{sender_info}->{http_method} = 'post';

    if ( $self->{sender_info}->{format} eq 'json' ) {
        $self->{sender_info}->{'encode_func'} = sub { $self->data_to_json(@_) };
        $self->{sender_info}->{'decode_func'} = sub { $self->json_to_data(@_) };
    } elsif ( $self->{sender_info}->{format} eq 'xml' )  {
        $self->{sender_info}->{'encode_func'} = sub { $self->data_to_json(@_) };
        $self->{sender_info}->{'decode_func'} = sub { $self->json_to_data(@_) };
    }

    $self->{'default_verify_level'} = (exists $self->{conf}->{verify_info}->{verify_level})?$self->{conf}->{verify_info}->{verify_level}:'normal';
    $self->{'verify_level'} = $self->{'default_verify_level'}; #初始化验证级别。

    my $super_options = {
        'enc' => $self->{'enc'},
        'sender_info' => $self->{sender_info},
        'conf' => $self->{conf},
        'is_encrypt' => $self->{'is_encrypt'},
    };
    $self->SUPER::init($super_options);
}


sub VerifyUser {
    my $self = shift @_;
    my $req = shift @_;
    my $post_c = $req->body_parameters;
    my ($login_username, $login_password) = ( $post_c->{'login_username'}, $post_c->{'login_password'} );

    foreach my $account (@{ $self->{conf}->{verify_info}->{allow_account} }) {
        if ($login_username eq $account->{username} && $login_password eq $account->{passwd} ) {
            return 1;
        } else {
            return -1;
        }
    }
}


sub VerifyUseragent {
    my $self = shift @_;
    my $req = shift @_;
    my $useragent = $req->user_agent;
    if (is_exist_in_array($self->{conf}->{verify_info}->{allow_agent}, $useragent) ) {
        return 1;
    } else {
        return 4;
    }
}


sub VerifyUseragentVersion {
    my $self = shift @_;
}


sub VerifyHttpMethod {
    my $self = shift @_;
    my $req = shift @_;
    my $method = $req->method;
    if ( $method eq 'POST' ){
        return 1;
    } else {
        return 2;
    }

}


sub VerifyClientHost {
    my $self = shift @_;
    my $req = shift @_;
    my $host = $req->address;
    if ( is_exist_in_array($self->{conf}->{verify_info}->{allow_hosts}, $host) ) {
        return 1;
    } else {
        return 5;
    }
}


sub VerifyUserPermission {
    my $self = shift @_;
    my $req = shift @_;
}


sub DefinedVerifyLevel {
    my $self = shift @_;
    my %verify_level = (
        'none'    => [],
        'basic'   => [sub {$self->VerifyHttpMethod(@_)}],
        'normal'  => [sub {$self->VerifyHttpMethod(@_)} , sub {$self->VerifyUseragent(@_)}, sub { $self->VerifyUser(@_)}],
        'strict'  => [sub {$self->VerifyHttpMethod(@_)} , sub {$self->VerifyUseragent(@_)}, sub { $self->VerifyUser(@_)}, sub {$self->VerifyClientHost(@_)}],
        'highest' => [sub {$self->VerifyHttpMethod(@_)} , sub {$self->VerifyUseragent(@_)}, sub { $self->VerifyUser(@_)}, sub {$self->VerifyClientHost(@_)}, sub {$self->VerifyUseragentVersion(@_)} ],
        'gitlab'  => [sub {$self->VerifyHttpMethod(@_)}],
    );
    return %verify_level;
}


sub AnalyzeVerifyLevel {
    my $self = shift @_;
    my ($verify_func_ref, $req) = @_;
    #DD($req);
    my $ver_code = 0;

    foreach my $func_ref (@$verify_func_ref) {
        $ver_code = $func_ref->($req);
        if ( $ver_code != 1 ) {
            return $ver_code;
            last;
        }
    }

    return $ver_code;
}


sub VerifyP {
    my $self = shift @_;
    my ($req) = @_;
    my $post_c = $req->body_parameters;
    my $ver_code = 0;

    my %verify_level = $self->DefinedVerifyLevel();

    if ( exists $verify_level{ $self->{'verify_level'} } ) {
        $ver_code = $self->AnalyzeVerifyLevel($verify_level{ $self->{'verify_level'} }, $req);
    } else {
        die " unknown verify_lever [ $self->{'verify_level'} ] \n";
    }

    $self->{'verify_level'} = $self->{'default_verify_level'}; #恢复初始验证级别。

    return $ver_code;
}


sub CResponseStatus {
    my $self = shift @_;
    my %status;
    my $exec_status = shift;
    $status{'version'} = $self->{conf}->{app_info}->{app_ver};
    $status{'code'}    = $exec_status->{'code'};
    $status{'create_at'} = $self->get_create_date();
    $status{'message'}  = $exec_status->{'message'};
    return \%status;
}


sub CResponseData {
    my $self = shift @_;
    my %data;
    my ($req_info, $call_func) = @_;
    my %exec_status = (
        'code' => 1,
        'message' => '',
    );
    $data{'info'}  = $call_func->($req_info, \%exec_status);
    $data{'status'} = $self->CResponseStatus( \%exec_status );
    return \%data;
}


sub CErrorResponseData {
    my $self = shift @_;
    my $ver_code = shift;
    #$self->logger("CErrorResponseData -> $ver_code");
    my %ver_code_info = (
       'en' => {
                '-1' => 'login fail',
                '-2' => 'no permission',
                '2'  => 'only support POST method',
                '3'  => 'unknown error',
                '4'  => 'no allow client',
                '5'  => 'no allow host',
               }
    );
    
    my %exec_status = (
        'code' => $ver_code,
        'message' => $ver_code_info{'en'}->{$ver_code},
    );

    my %data;
    $data{'status'} = $self->CResponseStatus( \%exec_status );
    return \%data;
}


sub CResponse {
    my $self = shift @_;
    my $Response;
    my $req_info = shift;
    my $ver_code = shift;
    my $call_func = shift;
    my $response_code = 200;
    my $res;
    if ( $ver_code != 1 ) {
        $Response = $self->CErrorResponseData($ver_code);
    } else {
        $Response = $self->CResponseData($req_info, $call_func);
    } 
    $res  = $req_info->{'req'}->new_response( ${response_code} );


    $res->content_type('application/json');

    my %res_header = (
        'Server'=>$self->{conf}->{app_info}->{server_type},
        'HK'=>$self->{conf}->{app_info}->{listen_host},
    );
    my $encode_msg = $self->{sender_info}->{'encode_func'}->($Response);

    if ( $self->{'force_encrypt'} == 1 or exists $req_info->{'header'}->{'RK'} ) {
        $self->{'enc'}->set_public_key(  $req_info->{'header'}->{'HK'} );
        my ($e_key, $e_data) = $self->{'enc'}->e_data($encode_msg);
        $encode_msg = $e_data;
        $res_header{'RK'} = $e_key;
    }

    $res->content( $encode_msg );

    my $h = HTTP::Headers->new;
    $h->header(%res_header);
    #$h->header( %{ $self->{sender_info}->{'header'} } );
    $res->headers($h);
    return $res->finalize;

}


sub DTaskBase {
    my $self = shift @_;
    my ($rEnv, $call_func) = @_;
    my $req = Plack::Request->new($rEnv);
    my $response;
    my $ver_code = 0;
    my $post_ref = $req->body_parameters;
    my $req_header = $req->headers;
    my @header_field_names =  $req_header->header_field_names;
    my %header;
    foreach my $header_field ( @header_field_names ) {
        $header{$header_field} =  $req_header->header($header_field);
    }
    if ( $self->{'force_encrypt'} == 1 or exists $header{'RK'} ) {
        $self->{'enc'}->set_private_key( $self->{conf}->{app_info}->{listen_host} );
        $post_ref->{data} = $self->{'enc'}->d_data($header{'RK'}, $post_ref->{data});        
    }
    my $req_info = {
        'req' => $req,
        'post' => $post_ref,
        'header' => \%header,
    };

    if ( IS_VERIFY == 1) {
        $ver_code = $self->VerifyP($req);
    } else {
        $ver_code = 1;
    }

    $response = $self->CResponse( $req_info, $ver_code, $call_func );
    return $response;
}


1;
