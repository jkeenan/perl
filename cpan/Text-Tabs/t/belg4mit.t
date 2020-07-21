#!/usr/bin/perl -I.

use Text::Wrap;
use Test::More tests => 2;
use warnings::register;

$Text::Wrap::columns = 1;
{
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, $_[0]; };
    eval { wrap('', '', 'H4sICNoBwDoAA3NpZwA9jbsNwDAIRHumuC4NklvXTOD0KSJEnwU8fHz4Q8M9i3sGzkS7BBrm
OkCTwsycb4S3DloZuMIYeXpLFqw5LaMhXC2ymhreVXNWMw9YGuAYdfmAbwomoPSyFJuFn2x8
Opr8bBBidccAAAA'); };

    if ($@) {
        my $e = $@;
        $e =~ s/^/# /gm;
        print $e;
    }
    is($@, '', "No error from wrap()");

    SKIP: {
        skip "warnings not enabled", 1 unless warnings::enabled();
        like($warnings[0],
            qr/Increasing \$Text::Wrap::columns from \d+ to \d+/,
            "Got expected module-generated warning"
        );
    }
}
