#!/usr/bin/perl
use strict;
use warnings;


use FindBin;
use lib "$FindBin::Bin/../../lib";

use utf8;
use Encrypt;

my $enc = Encrypt->new( {
        'key_basedir'  => '/opt/VCSPR/data/keys',
        'rsa_keyname'  => 'default',
        'rsa_keypass'  => '12345678',
} );

my @hosts;

@hosts = qw(
        test.spunkmars.org
        vcspr.spunkmars.org
);


foreach my $hostname (@hosts) {
    print "get rsa key for [$hostname] ...\n";
    $enc->set_private_key($hostname);
    $enc->set_public_key($hostname);
    $enc->create_rsa_keys($hostname);
}
