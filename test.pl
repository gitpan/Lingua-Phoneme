# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 1 };
use Lingua::Phoneme;
ok(1);

print "Please see the docs on how to install,\nand then run tests.pl.\n\n";
exit;