package APICommon;

use base 'Exporter';
use vars qw/@EXPORT/;
@EXPORT = qw();

use strict;
use warnings;

use utf8;
use Carp;
#$SIG{__DIE__} =  \&confess;
#$SIG{__WARN__} = \&confess;

use JSON;
use LWP::UserAgent;
use HTTP::Headers;
use URI;
use UUID::Tiny;
use XML::Simple;

use SPMR::COMMON::MyCOMMON qw(DD l_debug $L_DEBUG);
$L_DEBUG = 1;
use SPMR::DATE::MyDATE qw(get_date get_current_date);

#use Encrypt;


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
    
    $self->init(\%options);
    return $self;
}


sub init {
    my $self = shift;
    my ($options_ref) = @_;
    confess "\$options_ref must be an HASH ref" if (ref $options_ref ne 'HASH');
    $self->{'enc'} = $options_ref->{'enc'};
    $self->{'is_encrypt'} = $options_ref->{'is_encrypt'};
    $self->{'sender_info'} = $options_ref->{'sender_info'};
    $self->{'conf'} = $options_ref->{'conf'};
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


sub logger {
    my $self = shift @_;
    my $var = shift  @_;
    my $log_file = '/tmp/plack.log';
    open(CONFFILE, '>>', $log_file) || confess "Can't open file [$log_file] :$!";
    print CONFFILE ("$var \n");
    close(CONFFILE);

}


sub data_to_json {
    my $self = shift @_;
    my $json = JSON->new->utf8;
    my $var = $json->encode(shift);
    #$self->logger("data_to_json -> $var");
    return $var;
}


sub json_to_data {
    my $self = shift @_;
    my $json = JSON->new->utf8;
    my $var = $json->decode(shift);
    return $var
}


sub send_http_to_host {
    my $self = shift @_;
    my ($url, $send_data, $sender_info) = @_;

    my $browser = LWP::UserAgent->new();
    $browser->timeout($sender_info->{timeout});

    #$browser->credentials("www.example.com:80", "Some Realm", "foo", "secret"); # $netloc, $realm, $uname, $pass
    my $response;
    
    $browser->default_header( %{$sender_info->{'header'}} );

    #my $uri = URI->new($url);
    #$browser->default_header( 'Host' => $uri->host );

    if ( $sender_info->{http_method} eq 'post' ) {
        $response = $browser->post($url, $send_data );
    } elsif ( $sender_info->{http_method} eq 'get' ) {
        $response = $browser->get($url, $send_data );
    } elsif ( $sender_info->{http_method} eq 'head' ) {
    } elsif ( $sender_info->{http_method} eq 'put' ) {
    } elsif ( $sender_info->{http_method} eq 'delete' ) {
    } elsif ( $sender_info->{http_method} eq 'trace' ) {
    } else {
        confess "unknown http method $sender_info->{http_method}";
    }

    my $receive_data = {};
    $receive_data->{'is_success'} = 0;
#    if ($response->is_success){
    if ( 1 == 1 ){

        my @header_field_names =  $response->header_field_names();
        my %header;
        foreach my $header_field ( @header_field_names ) {
            $header{$header_field} =  $response->header($header_field);
        }
        my  $content = $response->decoded_content();

        $receive_data->{'is_success'} = 1;
        $receive_data->{'code'} = $response->code;
        $receive_data->{'status_line'} = $response->status_line;
        $receive_data->{'message'} = $response->message;
        $receive_data->{'header'} =  \%header;
        $receive_data->{'raw_content'} =  $content;
    }
    return $receive_data;
}



sub send_data_to_host {
    my $self = shift @_;
    my ($url, $send_msg) = @_;

    my %send_report = (
        'code' => 1,
        'msg'  => '',
        'data' => '',
    );

    my $sender_info = $self->{sender_info}; #FIX ME

    my $encode_msg = $sender_info->{'encode_func'}->($send_msg);

    my $uri = URI->new($url);
    my $d_host = $uri->host;

    $sender_info->{'header'}->{'HK'} = $self->{conf}->{app_info}->{listen_host};

    if ( $self->{'is_encrypt'} == 1 ) {
        $self->{'enc'}->set_public_key($d_host);
        my ($e_key, $e_data) = $self->{'enc'}->e_data($encode_msg);
        $encode_msg = $e_data;
        $sender_info->{'header'}->{'RK'} = $e_key;
    }

    my $send_data = {
        'login_username' => $sender_info->{username}, 
        'login_password' => $sender_info->{password}, 
        'format' => $sender_info->{format}, 
        'lang' => $sender_info->{lang}, 
        'version' => $sender_info->{version},  
        'data' => $encode_msg,

    };

    my $receive_data = $self->send_http_to_host($url, $send_data, $sender_info);
    if ( $receive_data->{'is_success'} == 1 ){
        my $content = $receive_data->{'raw_content'};

        if ( exists $receive_data->{'header'}->{'RK'} ) {
            $self->{'enc'}->set_private_key( $self->{conf}->{app_info}->{listen_host} );
            $content = $self->{'enc'}->d_data($receive_data->{'header'}->{'RK'}, $content);
        }

        if ( $receive_data->{'code'} != 200) {
            $send_report{code} = -2;
        } else {
            $send_report{code} = 1;
            $send_report{data} = $sender_info->{'decode_func'}->($content);
        }  
        $send_report{msg} = $receive_data->{'message'};
    } else {
        $send_report{code} = -1;
        $send_report{msg} = $receive_data->{'message'};
    }
    return \%send_report;

}


sub get_uuid {
    my $self = shift @_;
    my $uuid_string;
    my $v4_rand_UUID_string = UUID_to_string( create_UUID(UUID_V4) );
    my $v1_mc_UUID_string = create_UUID_as_string(UUID_V1);
    $uuid_string = $v1_mc_UUID_string . '-' . $v4_rand_UUID_string;
    return $uuid_string;
}


sub get_create_date {
    my $self = shift @_;
    #return get_date( '%Y-%m-%d %H:%M:%S' );
    return get_date( '%Y%m%d%H%M%S' );
}


sub write_config {
    my $self = shift @_;
    my ($path, $xml_ref) = @_;
    my $xml = XML::Simple->new();

    confess "invalid xml_ref \n" unless (ref $xml_ref);
    open my $fh, '>:encoding(utf-8)', $path or confess "open($path): $!";
    my $xml_res = $xml->XMLout(
             $xml_ref,
             RootName => 'data',
             KeepRoot   => 1,
             NoAttr => 1,
             NoSort => 1,
             XMLDecl => "<?xml version='1.0'?>",
             OutputFile => $fh,
             );

    close($fh);

    return $xml_res;
}


sub read_config {
    my $self = shift @_;
    my $path = shift @_;
    my $xml = XML::Simple->new();
    my $data = $xml->XMLin(
                      $path,
                      );
    return $data;
}



1;
