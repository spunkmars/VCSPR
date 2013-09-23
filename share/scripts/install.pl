#!/usr/bin/perl
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../../lib";

use base 'APIBase';

use XML::Simple;
use IO::File;
use SPMR::COMMON::MyCOMMON qw(DD l_debug $L_DEBUG is_int_digit);
$L_DEBUG = 1;
use SPMR::DBI::MyDBISqlite;

sub new {
    my $invocant  = shift;
    my ( $cc ) = @_;
    my $self      = bless( {}, ref $invocant || $invocant );
    my %options = (
        );

    my $pub_conf = $self->read_config("$FindBin::Bin/../../etc/publisher.xml");
    $self->{pub_conf} = $pub_conf;

    my $sqlite_file = $self->{pub_conf}->{db_info}->{db_file};
    my $dsn = "dbi:SQLite:dbname=${sqlite_file}";
    $self->{mysqlite} = SPMR::DBI::MyDBISqlite->new($dsn);
    $self->{pub_host} = $self->{pub_conf}->{app_info}->{listen_host};
    $self->SUPER::init(  $self->{pub_conf} );
    return $self;
}


sub create_config_info {
    my $self = shift @_;
    #$self->{mysqlite}->do_basic_query("PRAGMA cache_size = 20000");

    $self->{mysqlite}->do_basic_query(<<EOF);
CREATE TABLE IF NOT EXISTS Deploy (
    id INTEGER NOT NULL PRIMARY KEY,
    s_project INTEGER NOT NULL,
    s_branch VARCHAR(255),
    s_tag VARCHAR(255),
    s_commit_msg VARCHAR(255),
    trigger VARCHAR(255) NOT NULL,
    dtask_type VARCHAR(255) NOT NULL,
    dtask_value VARCHAR(255) NOT NULL,
    is_active INTEGER DEFAULT 1,
    UNIQUE(id)
)
EOF


    $self->{mysqlite}->do_basic_query(<<EOF);
CREATE TABLE IF NOT EXISTS Project (
    id INTEGER NOT NULL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    alias_name VARCHAR(255) NOT NULL,
    repo VARCHAR(255),
    vcs  INTEGER NOT NULL,
    proj_id INTEGER NOT NULL,
    info VARCHAR(255),
    is_active INTEGER DEFAULT 1,
    UNIQUE(id, name, alias_name)
)
EOF



    $self->{mysqlite}->do_basic_query(<<EOF);
CREATE TABLE IF NOT EXISTS VCS (
    id INTEGER NOT NULL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    alias_name VARCHAR(255) NOT NULL,
    type VARCHAR(255) NOT NULL,
    source VARCHAR(255) NOT NULL,
    api_uri VARCHAR(255),
    api_private_token VARCHAR(255),
    info VARCHAR(255),
    is_active INTEGER DEFAULT 1,
    UNIQUE(id, name, alias_name)
)
EOF


    $self->{mysqlite}->do_basic_query(<<EOF);
CREATE TABLE IF NOT EXISTS Host (
    id INTEGER NOT NULL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    alias_name VARCHAR(255),
    ip VARCHAR(255) NOT NULL,
    info VARCHAR(255),
    UNIQUE(id)
)
EOF


    $self->{mysqlite}->do_basic_query(<<EOF);
CREATE TABLE IF NOT EXISTS DTask (
    id INTEGER NOT NULL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    host INTEGER NOT NULL,
    d_branch VARCHAR(255) NOT NULL,
    d_dir VARCHAR(255) NOT NULL,
    f_permissions VARCHAR(255),
    priority_type VARCHAR(255) DEFAULT 'last',
    is_active INTEGER DEFAULT 1,
    UNIQUE(id)
)
EOF

    $self->{mysqlite}->do_basic_query(<<EOF);
CREATE TABLE IF NOT EXISTS DTaskGroup (
    id INTEGER NOT NULL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    info VARCHAR(255),    
    is_active INTEGER DEFAULT 1, 
    UNIQUE(id)
)
EOF


    $self->{mysqlite}->do_basic_query(<<EOF);
CREATE TABLE IF NOT EXISTS DTaskDTGroup (
    id INTEGER NOT NULL PRIMARY KEY,
    dtask_id INTEGER NOT NULL,
    dtask_gid INTEGER NOT NULL,
    UNIQUE(id)
)
EOF


   $self->{mysqlite}->do_basic_query(<<EOF);
CREATE TABLE IF NOT EXISTS DTaskLog (
        id INTEGER NOT NULL PRIMARY KEY,
        dtask_id INTEGER NOT NULL,
        vcs_push_log_create_uuid  VARCHAR(255) NOT NULL,
        dtask_name VARCHAR(255) NOT NULL,
        creater VARCHAR(255),
        create_date VARCHAR(255) NOT NULL,
        create_uuid VARCHAR(255) NOT NULL,
        trigger_by VARCHAR(255) NOT NULL,
        vcs_name VARCHAR(255) NOT NULL,
        vcs_alias_name VARCHAR(255),
        vcs_source VARCHAR(255),
        priority_type VARCHAR(255),
        repo VARCHAR(255) NOT NULL,
        s_branch VARCHAR(255) NOT NULL DEFAULT 'master',
        s_commit_msg VARCHAR(1000),
        s_tag  VARCHAR(255),
        s_commit_id VARCHAR(255),
        host_name VARCHAR(255),
        host_alias_name VARCHAR(255),
        host_ip  VARCHAR(255) NOT NULL,
        d_branch VARCHAR(255) NOT NULL DEFAULT 'master',
        d_dir VARCHAR(255) NOT NULL,
        f_perm VARCHAR(1000),
        exec_total_time INTEGER,
        exec_status VARCHAR(255),
        exec_code INTEGER,
        exec_info VARCHAR(1000),
        UNIQUE(id, create_uuid)
)
EOF


   $self->{mysqlite}->do_basic_query(<<EOF);
CREATE TABLE IF NOT EXISTS VCSPushLog (
        id INTEGER NOT NULL PRIMARY KEY,
        creater VARCHAR(255),
        create_date VARCHAR(255) NOT NULL,
        create_uuid VARCHAR(255) NOT NULL,
        vcs_name VARCHAR(255) NOT NULL,
        vcs_alias_name VARCHAR(255),
        vcs_source VARCHAR(255),
        repo VARCHAR(255) NOT NULL,

        s_command_type VARCHAR(255),
        s_commit_id VARCHAR(255),
        s_commit_timestamp VARCHAR(255),
        s_commit_author VARCHAR(255),
        s_commit_email VARCHAR(255),
        s_ref_type VARCHAR(255),
        s_ref_value VARCHAR(255),
        s_branch VARCHAR(255) NOT NULL DEFAULT 'master',
        s_commit_msg VARCHAR(1000),

        is_trigger INTEGER,
        UNIQUE(id, create_uuid)
)
EOF


    $self->{mysqlite}->do_basic_query(<<EOF);
CREATE TABLE IF NOT EXISTS User (
    id INTEGER NOT NULL PRIMARY KEY,
    username VARCHAR(255) NOT NULL,
    password VARCHAR(255) NOT NULL,
    email VARCHAR(255),
    info VARCHAR(255),
    is_active INTEGER DEFAULT 1, 
    UNIQUE(id)
)
EOF

}

    
sub init_config_info {
    my $self = shift @_;
}


sub init_user {
    use Crypt::SaltedHash;
    my $csh = Crypt::SaltedHash->new(algorithm => 'SHA-1');
    $csh->add('admin');
    my $salted = $csh->generate;
    my $valid = Crypt::SaltedHash->validate($salted, 'admin');
    $self->{mysqlite}->do_basic_query("INSERT INTO "User" ("id","username","password","email","info","is_active") VALUES ('2','admin','{SSHA}Nm9482j5XwJtKWNcvN5K9oGig1j3iKxg','admin@spunkmars.org','admin','1')");
}


sub show_all_table_field_info {
    my $self = shift @_;
    my $cc_ref;
    my $tbs_ref = $self->{mysqlite}->get_table_list();
    foreach(@$tbs_ref){
        print "$_ :\n";
        $cc_ref = $self->{mysqlite}->get_table_info($_);
        DD($cc_ref);
    }
}


sub show_table_info {
    my $self = shift @_;
    my $db_name = shift;
    my $cc_ref = $self->{mysqlite}->get_array_from_query("SELECT * FROM $db_name");
    print "$db_name :\n";
    DD($cc_ref);

}


sub show_all_table_info {
    my $self = shift @_;
    my $cc_ref;
    my $tbs_ref = $self->{mysqlite}->get_table_list();
    foreach(@$tbs_ref){
        show_table_info($_);
        print "\n ----------------- \n";       
    }
}


sub init_database {
    my $self = shift @_;
    $self->{mysqlite}->connect_DB();
    $self->create_config_info();
    $self->init_config_info();
    #$self->show_all_table_info();
    $self->{mysqlite}->disconnect_DB();

}


sub write_config {
    my ($path, $xml_ref) = @_;
    my $xml = XML::Simple->new();

    die "invalid xml_ref \n" unless (ref $xml_ref);
    open my $fh, '>:encoding(utf-8)', $path or die "open($path): $!";
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
    my $path = shift @_;
    my $xml = XML::Simple->new();
    my $data = $xml->XMLin(
                      $path,
                      );
    return $data;
}


my $publisher_config = {

        'send_info' => {
            'username'  => 'admin',
            'password'  => 'admin123',
            'lang'      => 'en',
            'from'      => 'spunkmars@spunkmars.org',
            'timeout'      => 10,
            'format'      => 'json',
        },  
            
        'app_info' => {
            'server_type' => 'nginx',
            'listen_host' => 'vcspr.spunkmars.org',
            'listen_port' => 5001,
            'url_prefix' => '/Deploy',
            'app_ver' => '0.1.0',
            'agent_ver' => '0.1.0',
            'agent'     => 'DepolyClient/0.1.0',
        },  
                
        'verify_info' => {
            'allow_lang'  => 'en, cn',
            'allow_format'  => [
                'json', 'xml',
            ],
            'allow_ver'  => '0.1.0',
            'allow_agent'  => [
                'DepolyClient/0.1.0', 'VCSPR',
            ], 
            'allow_agent_ver'  => '0.1.0',
            'allow_account' => [
               {'username' => 'admin', 'passwd' => 'admin123', privilege => 'admin'},
               {'username' => 'guest', 'passwd' => 'guest123', privilege => 'guest'},
            ],
            'verify_level' => 'normal',
            'allow_hosts' => [
               '192.168.8.154',
            ],
            'allow_hostname' => [
                'vcspr.spunkmars.org', 'test2.spunkmars.org',
            ],
            
        },      


        'db_info' => {
            'db_type' => 'sqlite',
            'db_file' => '/opt/VCSPR/Deploy.db',
        },
};


my $receiver_config =  {
        'send_info' => {
            'username'  => 'admin',
            'password'  => 'admin123',
            'lang'      => 'en',
            'from'      => 'spunkmars@spunkmars.org',
            'timeout'      => 10,
            'format'      => 'json',
        },

        'app_info' => {
            'server_type' => 'nginx',
            'listen_host' => 'test2.spunkmars.org',
            'listen_port' => 5002,
            'url_prefix' => '/Deploy',
            'app_ver' => '0.1.0',
            'agent_ver' => '0.1.0',
            'agent'     => 'DepolyClient/0.1.0',
        },

        'verify_info' => {
            'allow_lang'  => 'en, cn',
            'allow_format'  => [
                'json', 'xml',
            ],
            'allow_ver'  => '0.1.0',
            'allow_agent'  => [
                'DepolyClient/0.1.0', 'VCSPR',
            ],
            'allow_agent_ver'  => '0.1.0',
            'allow_account' => [
               {'username' => 'admin', 'passwd' => 'admin123', privilege => 'admin'},
               {'username' => 'guest', 'passwd' => 'guest123', privilege => 'guest'},
            ],
            'verify_level' => 'normal',
            'allow_hosts' => [
               '192.168.8.154',
            ],
            'allow_hostname' => [
                'vcspr.spunkmars.org', 'test2.spunkmars.org',
            ],
            
        },

        'define_info' => {
            'sys_dir' => {
                'WEB_DIR' => '/data/htdocs/www',
                'PROD_WEB_DIR' => '/data/htdocs/www',
                'TEST_WEB_DIR' => '/data/htdocs/www',
            }, 
            'sys_account' => {
                'user' => {
                     'web'  => 'www',
                     'manager'  => 'root',
                },
                'group' => {
                     'web'  => 'www',
                     'manager'  => 'root',
                 },
            },
            'vcs'   => [
                {'vcs_name' => 'git server3', 'host_name' => 'gitlabserver.spunkmars.org', 'type' => 'gitlab', 'uri' => 'git@gitlabserver.spunkmars.org', 'desc' => 'none',},
                {'vcs_name' => 'git server2', 'host_name' => 'gitlabserver.spunkmars.org', 'type' => 'gitlab', 'uri' => 'git@gitlabserver.spunkmars.org', 'desc' => 'none',},

            ],
        },
};


my $pub_xml = '/opt/VCSPR/etc/publisher.xml';
my $rec_xml = '/opt/VCSPR/etc/receiver.xml';


write_config($pub_xml, $publisher_config);
write_config($rec_xml, $receiver_config);


#$publisher->init_database();
