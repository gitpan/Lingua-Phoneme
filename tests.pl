# imf - Test GD supply an object write to file
use strict;
our $VERSION = sprintf("%d.%02d", q$Revision: 0.01 $ =~ /(\d+)\.(\d+)/);

use Test;
BEGIN { plan tests => 7 };

warn "*"x53,"\n";
warn "This script should only be run once the db is set up.\n";
warn "You can use build.pl from the tardist to build the db.\n";
warn "*"x53,"\n";

use Lingua::Phoneme;
print "ok 1\n";


my $o = new Lingua::Phoneme(
		USERNAME => 'Administrator',
		PASSWORD => 'shalom37',
		CHAT	 => 1,
);

(ref $o eq 'Lingua::Phoneme')? print "ok 2\n" : print "not ok 2\n";

$_ = $o->phoneme("house");
($_ eq ",h/&//U/s")? print "ok 3\n" : print "not ok 3 : *$_*";

@_ = $o->phoneme("house");
if ($_[0] eq ",h" and $_[1] eq '&' and $_[2] eq '' and $_[3] eq 'U' and $_[4] eq 's' ){
	print "ok 4\n";
} else {
	print "not 4 3\n";
}

my ($ps,$p,$s) = $o->phoneme_accent("house");
(ref $ps eq 'ARRAY')? print "ok 5\n" : print "not ok 5\n";
($p eq '0')?          print "ok 6\n" : print "not ok 6\n";
($s eq undef)?        print "ok 7\n" : print "not ok 7\n";

exit;


