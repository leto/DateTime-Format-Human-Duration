#!perl -T

use Test::More 'tests' => 1;

SKIP: {
    eval 'use Test::Pod::Coverage 1.04';
    skip 'Test::Pod::Coverage 1.04 required for testing POD coverage', 1 if $@;

    Test::Pod::Coverage::pod_coverage_ok( "DateTime::Format::Human::Duration", { 'trustme' => [qr/^(new)$/,], } );
}

# Locale.pm, es.pm, and fr.pm don;t have POD
# all_pod_coverage_ok();
