#!./perl

BEGIN {
    chdir 't' if -d 't';
    require './test.pl';
    set_up_inc('../lib');
}

use Config;

plan(tests => 78);

my $foo;
is(vec($foo,0,1), 0);
is(length($foo), undef);
vec($foo,0,1) = 1;
is(length($foo), 1);
is(unpack('C',$foo), 1);
is(vec($foo,0,1), 1);

is(vec($foo,20,1), 0);
vec($foo,20,1) = 1;
is(vec($foo,20,1), 1);
is(length($foo), 3);
is(vec($foo,1,8), 0);
vec($foo,1,8) = 0xf1;
is(vec($foo,1,8), 0xf1);
is((unpack('C',substr($foo,1,1)) & 255), 0xf1);
is(vec($foo,2,4), 1);;
is(vec($foo,3,4), 15);

my $Vec;
vec($Vec, 0, 32) = 0xbaddacab;
is($Vec, "\xba\xdd\xac\xab");
is(vec($Vec, 0, 32), 3135089835);

# ensure vec() handles numericalness correctly
my ($bar, $baz);
$foo = $bar = $baz = 0;
vec($foo = 0,0,1) = 1;
vec($bar = 0,1,1) = 1;
$baz = $foo | $bar;
ok($foo eq "1" && $foo == 1);
ok($bar eq "2" && $bar == 2);
ok("$foo $bar $baz" eq "1 2 3");

# error cases

my $x = eval { vec $foo, 0, 3 };
like($@, qr/^Illegal number of bits in vec/);
$@ = undef;
$x = eval { vec $foo, 0, 0 };
like($@, qr/^Illegal number of bits in vec/);
$@ = undef;
$x = eval { vec $foo, 0, -13 };
like($@, qr/^Illegal number of bits in vec/);
$@ = undef;
$x = eval { vec($foo, -1, 4) = 2 };
like($@, qr/^Negative offset to vec in lvalue context/);
$@ = undef;
ok(! vec('abcd', 7, 8));

# UTF8
# N.B. currently curiously coded to circumvent bugs elswhere in UTF8 handling

$foo = "\x{100}" . "\xff\xfe";
$x = substr $foo, 1;
is(vec($x, 0, 8), 255);
$@ = undef;
{
    no warnings 'deprecated';
    eval { vec($foo, 1, 8) };
    ok(! $@);
    $@ = undef;
    eval { vec($foo, 1, 8) = 13 };
    ok(! $@);
    if ($::IS_EBCDIC) {
        is($foo, "\x8c\x0d\xff\x8a\x69");
    }
    else {
        is($foo, "\xc4\x0d\xc3\xbf\xc3\xbe");
    }
}
$foo = "\x{100}" . "\xff\xfe";
$x = substr $foo, 1;
vec($x, 2, 4) = 7;
is($x, "\xff\xf7");

# mixed magic

$foo = "\x61\x62\x63\x64\x65\x66";
is(vec(substr($foo, 2, 2), 0, 16), 25444);
vec(substr($foo, 1,3), 5, 4) = 3;
is($foo, "\x61\x62\x63\x34\x65\x66");

# A variation of [perl #20933]
{
    my $s = "";
    vec($s, 0, 1) = 0;
    vec($s, 1, 1) = 1;
    my @r;
    $r[$_] = \ vec $s, $_, 1 for (0, 1);
    ok(!(${ $r[0] } != 0 || ${ $r[1] } != 1)); 
}


my $destroyed;
{ package Class; DESTROY { ++$destroyed; } }

$destroyed = 0;
{
    my $x = '';
    vec($x,0,1) = 0;
    $x = bless({}, 'Class');
}
is($destroyed, 1, 'Timely scalar destruction with lvalue vec');

use constant roref => \1;
eval { for (roref) { vec($_,0,1) = 1 } };
like($@, qr/^Modification of a read-only value attempted at /,
        'err msg when modifying read-only refs');


{
    # downgradeable utf8 strings should be downgraded before accessing
    # the byte string.
    # See the p5p thread with Message-ID:
    # <CAMx+QJ6SAv05nmpnc7bmp0Wo+sjcx=ssxCcE-P_PZ8HDuCQd9A@mail.gmail.com>


    my $x = substr "\x{100}\xff\xfe", 1; # a utf8 string with all ords < 256
    my $v;
    $v = vec($x, 0, 8);
    is($v, 255, "downgraded utf8 try 1");
    $v = vec($x, 0, 8);
    is($v, 255, "downgraded utf8 try 2");
}

# [perl #128260] assertion failure with \vec %h, \vec @h
{
    my %h = 1..100;
    my @a = 1..100;
    is ${\vec %h, 0, 1}, vec(scalar %h, 0, 1), '\vec %h';
    is ${\vec @a, 0, 1}, vec(scalar @a, 0, 1), '\vec @a';
}


# [perl #130915] heap-buffer-overflow in Perl_do_vecget

{
    # ensure that out-of-STRLEN-range offsets are handled correctly. This
    # partially duplicates some tests above, but those cases are repeated
    # here for completeness.
    #
    # Note that all the 'Out of memory!' errors trapped eval {} are 'fake'
    # croaks generated by pp_vec() etc when they have detected something
    # that would have otherwise overflowed. The real 'Out of memory!'
    # error thrown by safesysrealloc() etc is not trappable. If it were
    # accidentally triggered in this test script, the script would exit at
    # that point.


    my $s = "abcdefghijklmnopqrstuvwxyz";
    my $x;

    # offset is SvIOK_UV

    $x = vec($s, ~0, 8);
    is($x, 0, "RT 130915: UV_MAX rval");
    eval { vec($s, ~0, 8) = 1 };
    like($@, qr/^Out of memory!/, "RT 130915: UV_MAX lval");

    # offset is negative

    $x = vec($s, -1, 8);
    is($x, 0, "RT 130915: -1 rval");
    eval { vec($s, -1, 8) = 1 };
    like($@, qr/^Negative offset to vec in lvalue context/,
                                            "RT 130915: -1 lval");

    # offset positive but doesn't fit in a STRLEN

    SKIP: {
        skip 'IV is no longer than size_t', 2
                    if $Config{ivsize} <= $Config{sizesize};

        my $size_max = (1 << (8 *$Config{sizesize})) - 1;
        my $sm2 = $size_max * 2;

        $x = vec($s, $sm2, 8);
        is($x, 0, "RT 130915: size_max*2 rval");
        eval { vec($s, $sm2, 8) = 1 };
        like($@, qr/^Out of memory!/, "RT 130915: size_max*2 lval");
    }

    # (offset * num-bytes) could overflow

    for my $power (1..3) {
        my $bytes = (1 << $power);
        my $biglog2 = $Config{sizesize} * 8 - $power;
        for my $i (0..1) {
            my $offset = (1 << $biglog2) - $i;
            $x = vec($s, $offset, $bytes*8);
            is($x, 0, "large offset: bytes=$bytes biglog2=$biglog2 i=$i: rval");
            eval { vec($s, $offset, $bytes*8) = 1; };
            like($@, qr/^Out of memory!/,
                      "large offset: bytes=$bytes biglog2=$biglog2 i=$i: rval");
        }
    }
}

# Test multi-byte gets partially beyond the end of the string.
# It's supposed to pretend there is a stream of \0's following the string.

{
    my $s = "\x01\x02\x03\x04\x05\x06\x07";
    my $s0 = $s . ("\0" x 8);

    for my $bytes (1, 2, 4, 8) {
        for my $offset (0..$bytes) {
            if ($Config{ivsize} < $bytes) {
                pass("skipping multi-byte bytes=$bytes offset=$offset");
                next;
            }
            no warnings 'portable';
            is (vec($s,  8 - $offset, $bytes*8),
                vec($s0, 8 - $offset, $bytes*8),
                "multi-byte bytes=$bytes offset=$offset");
        }
    }
}

# RT #131083 maybe-lvalue out of range should only croak if assigned to

{
    sub  RT131083 { if ($_[0]) { $_[1] = 1; } $_[1]; }
    my $s = "abc";
    my $off = -1;
    my $v = RT131083(0, vec($s, $off, 8));
    is($v, 0, "RT131083 rval -1");
    $v = eval { RT131083(1, vec($s, $off, 8)); };
    like($@, qr/Negative offset to vec in lvalue context/, "RT131083 lval -1");

    $off = ~0;
    $v = RT131083(0, vec($s, $off, 8));
    is($v, 0, "RT131083 rval ~0");
    $v = eval { RT131083(1, vec($s, $off, 8)); };
    like($@, qr/Out of memory!/, "RT131083 lval ~0");
}
