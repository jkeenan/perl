#!./perl -w

use Test::More tests => 1;

# FileCache is documented to rely upon symbolic references, so all programs
# that use it must relax strict 'refs'
no strict 'refs';

# Try using FileCache without importing to make sure everything's 
# initialized without it.
{
    package Y;
    use FileCache ();

    my $file = 'foo';
    END { unlink $file }
    FileCache::cacheout($file);
    print $file "bar";
    close $file;

    FileCache::cacheout("<", $file);
    ::ok( <$file> eq "bar" );
    close $file;
}
