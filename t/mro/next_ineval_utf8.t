#!/usr/bin/perl

BEGIN {
    chdir 't' if -d 't';
    require './test.pl';
    set_up_inc('../lib');
}
use warnings;
use utf8;
use open qw( :utf8 :std );

plan(tests => 1);

=pod

This tests the use of an eval{} block to wrap a next::method call.

=cut

{
    package అ;
    use mro 'c3'; 

    sub ຟǫ {
      die 'అ::ຟǫ died';
      return 'అ::ຟǫ succeeded';
    }
}

{
    package ｂ;
    use base 'అ';
    use mro 'c3'; 
    
    sub ຟǫ {
      eval {
        return 'ｂ::ຟǫ => ' . (shift)->next::method();
      };

      if ($@) {
        return $@;
      }
    }
}

like(ｂ->ຟǫ, 
   qr/^అ::ຟǫ died/u, 
   'method resolved inside eval{}');


