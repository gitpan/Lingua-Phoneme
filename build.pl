use strict;
our $VERSION = sprintf("%d.%02d", q$Revision: 0.01 $ =~ /(\d+)\.(\d+)/);
use Lingua::Accent;

die "edit me!";
my $o = new Lingua::Accent(
		USERNAME => 'x',
		PASSWORD => 'y',
		CHAT	 => 1,
);

$o->build;
exit;


