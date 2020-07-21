#!/usr/bin/perl


use lib '..';
use Memoize;


print "1..11\n";

sub timelist {
  return (time) x $_[0];
}

memoize('timelist');

my @t1 = &timelist(1);
sleep 2;
my @u1 = &timelist(1);
{ no warnings 'ambiguous'; print ((("@t1" eq "@u1") ? '' : 'not '), "ok 1\n"); }

my @t7 = &timelist(7);
print (((@t7 == 7) ? '' : 'not '), "ok 2\n");
my $BAD = 0;
for (my $i = 1; $i < 7; $i++) {
  $BAD++ unless $t7[$i-1] == $t7[$i];
}
print (($BAD ? 'not ' : ''), "ok 3\n");

sleep 2;
my @u7 = &timelist(7);
print (((@u7 == 7) ? '' : 'not '), "ok 4\n");
$BAD = 0;
for (my $i = 1; $i < 7; $i++) {
  $BAD++ unless $u7[$i-1] == $u7[$i];
}
print (($BAD ? 'not ' : ''), "ok 5\n");
# Properly memoized?
print ((("@t7" eq "@u7") ? '' : 'not '), "ok 6\n");

sub con {
  return wantarray()
}

# Same arguments yield different results in different contexts?
memoize('con');
my $s = con(1);
my @a = con(1);
print ((($s == $a[0]) ? 'not ' : ''), "ok 7\n");

# Context propagated correctly?
print ((($s eq '') ? '' : 'not '), "ok 8\n"); # Scalar context
print ((("@a" eq '1' && @a == 1) ? '' : 'not '), "ok 9\n"); # List context

# Context propagated correctly to normalizer?
sub n {
  my $arg = shift;
  my $test = shift;
  no strict 'subs';
  if (wantarray) {
    print ((($arg eq ARRAY) ? '' : 'not '), "ok $test\n"); # List context
  } else {
    print ((($arg eq SCALAR) ? '' : 'not '), "ok $test\n"); # Scalar context
  }
}

sub f { 1 }
memoize('f', NORMALIZER => 'n');
$s = f('SCALAR', 10);		# Test 10
@a = f('ARRAY' , 11);		# Test 11

