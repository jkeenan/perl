# -lucb has been reported to be fatal for perl5 on Solaris.
# Thus we deliberately don't include it here.
no strict 'vars';
$self->{LIBS} = ["-lndbm", "-ldbm"];
