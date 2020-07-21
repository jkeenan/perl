
use Text::Wrap;
use Test::More tests => 3;
use warnings::register;

$Text::Wrap::columns = 4;
my $x;

{
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, $_[0]; };
    eval { $x = Text::Wrap::wrap('', '123', 'some text'); };
    is($@, '', "No error from wrap()");
    is($x, "some\n123t\n123e\n123x\n123t");
    SKIP: {
        skip "warnings not enabled", 1 unless warnings::enabled();
        like($warnings[0],
            qr/Increasing \$Text::Wrap::columns from \d+ to \d+ to accommodate length of subsequent tab/,
            "Got expected module-generated warning"
        );
    }
}

