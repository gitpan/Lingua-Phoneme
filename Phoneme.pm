#! perl -w
package Lingua::Phoneme;
our $VERSION = 0.011;

use strict;
use warnings;
use Carp;

=head1 NAME

Lingua::Phoneme - MySQL-based accent-lookups.

=head1 SYNOPSIS

First time, to install the dictionary, manually create
an MySQL database whose name is as described in
$Lingua::Phoneme::DATABASE - by defaul this is C<accents>:

	mysqladmin create accents

Then run these following lines of Perl:

	use Lingua::Phoneme;
	my $o = new Lingua::Phoneme(
		USERNAME => 'myusername',
		PASSWORD => 'mypassword',
	);
	$o->build;

You can supply a parameter to C<build> that should be the
directory in which this module is located.

Thereafter:

	use Lingua::Phoneme;
	my $o = new Lingua::Phoneme(
		USERNAME => 'myusername',
		PASSWORD => 'mypassword',
	};
	$_ = $o->phoneme("house");
	@_ = $o->phoneme("house");
	my ($ps,$p,$s) = $o->phoneme_accent("house");

	__END__


=head1 PREREQUISITES

L<DBI.pm|<DBI.pm>,
L<DBD::mysql.pm|<DBD::mysql>,

=cut

use DBI();
use DBD::mysql;

=head1 DESCRIPTION

This module is intended to provide information on the phonemes
and stress of English-language words.

Currently it uses the Moby Pronunciation Dictionary in a
MySQL DB, but you can change the DB settings at construction time,
and there is no reason why it can't be extended to other languages
should dictionaries be made available.

=head1 NOTES ON THE DATABASE

From the Moby README file:

	Each pronunciation vocabulary entry consists of a word or phrase
	field followed by a field delimiter of space and the IPA-equivalent
	field that is coded using the following ASCII symbols (case is
	significant). Spaces between words in the word or phrase or
	pronunciation field is denoted with underbar "_".

	/&/     sounds like the "a" in "dab"
	/(@)/   sounds like the "a" in "air"
	/A/     sounds like the "a" in "far"
	/eI/    sounds like the "a" in "day"
	/@/     sounds like the "a" in "ado"
	        or the glide "e" in "system" (dipthong schwa)
	/-/     sounds like the "ir" glide in "tire"
	        or the  "dl" glide in "handle"
	        or the "den" glide in "sodden" (dipthong little schwa)
	/b/     sounds like the "b" in "nab"
	/tS/    sounds like the "ch" in "ouch"
	/d/     sounds like the "d" in "pod"
	/E/     sounds like the "e" in "red"
	/i/     sounds like the "e" in "see"
	/f/     sounds like the "f" in "elf"
	/g/     sounds like the "g" in "fig"
	/h/     sounds like the "h" in "had"
	/hw/    sounds like the "w" in "white"
	/I/     sounds like the "i" in "hid"
	/aI/    sounds like the "i" in "ice"
	/dZ/    sounds like the "g" in "vegetably"
	/k/     sounds like the "c" in "act"
	/l/     sounds like the "l" in "ail"
	/m/     sounds like the "m" in "aim"
	/N/     sounds like the "ng" in "bang"
	/n/     sounds like the "n" in "and"
	/Oi/    sounds like the "oi" in "oil"
	/A/     sounds like the "o" in "bob"
	/AU/    sounds like the "ow" in "how"
	/O/     sounds like the "o" in "dog"
	/oU/    sounds like the "o" in "boat"
	/u/     sounds like the "oo" in "too"
	/U/     sounds like the "oo" in "book"
	/p/     sounds like the "p" in "imp"
	/r/     sounds like the "r" in "ire"
	/S/     sounds like the "sh" in "she"
	/s/     sounds like the "s" in "sip"
	/T/     sounds like the "th" in "bath"
	/D/     sounds like the "th" in "the"
	/t/     sounds like the "t" in "tap"
	/@/     sounds like the "u" in "cup"
	/@r/    sounds like the "u" in "burn"
	/v/     sounds like the "v" in "average"
	/w/     sounds like the "w" in "win"
	/j/     sounds like the "y" in "you"
	/Z/     sounds like the "s" in "vision"
	/z/     sounds like the "z" in "zoo"

	Moby Pronunciator contains many common names and phrases borrowed from
	other languages; special sounds include (case is significant):

	"A"  sounds like the "a" in "ami"
	"N"  sounds like the "n" in "Francoise"
	"R"  sounds like the "r" in "Der"
	/x/  sounds like the "ch" in "Bach"
	/y/  sounds like the "eu" in "cordon bleu"
	"Y"  sounds like the "u" in "Dubois"

	Words and Phrases adopted from languages other than English
	have the unaccented  form of the roman spelling. For example,
	"etude" has an initial accented "e" but is spelled without the
	accent in the Moby Pronunciator II database.

=head1 INSTALLATION OF THE DATABASE

See L<build>.

=head1 CONSTRUCTOR new

Accepts name/value pairs as a hash or hash-like structure:

=over 4

=item CHAT

Real-time info about progress on C<STDERR>.

=item DATABASE

The name of the rhyming dictionary database that
will be created. Defaults to C<accents>.

=item DRIVER

The C<DBI::*> driver: defaults to C<mysql>.

=item USER. PASSWORD

Used to access the DB - no default values.

=item HOSTNAME, PORT

The following variables must be set by the user to access the database.
Defaults are C<localhost>, C<3306>

=back

=cut

sub new { my $class = shift;
    unless (defined $class) {
    	carp "Usage: ".__PACKAGE__."->new( {key=>value} )\n";
    	return undef;
	}
	my %args;

	# Take parameters and place in object slots/set as instance variables
	if (ref $_[0] eq 'HASH'){	%args = %{$_[0]} }
	elsif (not ref $_[0]){		%args = @_ }
	else {
		carp "Usage: $class->new( { key=>values, } )";
		return undef;
	}
	my $self = bless {}, $class;

	# Fields that have default values:
	$self->{DATABASE} = "accents";
	$self->{HOSTNAME} = "localhost";
	$self->{PORT}     = "3306";
	$self->{DRIVER}   = "mysql";

	# Set/overwrite public slots with user's values
	foreach (keys %args) {
		$self->{$_} = $args{$_};
	}

	# Over-write user-suppiled fields with required field values

	# Catch bad field-paramter errors
	croak "No USERNAME!" if not $self->{USERNAME};
	croak "No PASSWORD!" if not $self->{PASSWORD};

	return $self;
}


=head2 METHOD &build ($optional_path_to_db)

Calling this method will fill the database, dropping
and re-making all tables if they already exist.

Optionally, supply an arugment which is the full path
to the Moby Pronounciation dictionary file - the default
is to use C<MobyPron> in the C<$perl/site/lib/Lingua/Phoneme/dict/EN>
directory.

=cut


sub build { my $self=shift;
	local (*WORDS,*PhonemeS);
	my ($base, $oldchat)=('',$self->{CHAT});
	$self->{CHAT} = 1;
	if (defined $_[0]){
		$base = shift;
	} else {
		foreach (@INC){
			if (/site/){
				$base = $_;
				last;
			}
		}
		$base.='/Lingua/Phoneme/dict/EN/MobyPron.txt';
	}

	croak "No USERNAME and/or PASSWORD" if not $self->{USERNAME} and not $self->{PASSWORD};
	croak "Could not find file from which to build db!\nNo $base" if not -e $base;

	warn "Setting up db connection...\n" if $self->{CHAT};
	my $dsn = "DBI:$self->{DRIVER}:database=$self->{DATABASE};host=$self->{HOSTNAME};port=$self->{PORT}";
	my $dbh = DBI->connect($dsn, $self->{USERNAME}, $self->{PASSWORD}) or die "Could not connect\n$!";
	DBI->install_driver("mysql");

	#
	# Create a new tables: **words**
	#
	warn "Building table words...\n" if $self->{CHAT};
	$dbh->do("DROP TABLE IF EXISTS words");
	$dbh->do("CREATE TABLE words "
			."("
				. "entry int NOT NULL, "
				. "word	char(255) NOT NULL, "
				. "pron	char(255) NOT NULL, "
				. "PRIMARY KEY(entry) "
			. ")"
	);

	open WORDS,$base or die "Couldn't find MobyPron.txt from which to build db table!";
	my $i=0;
	while (<WORDS>){
		chomp;
		my ($word, $pron) = split " ",$_,2;
		$dbh->do("INSERT INTO words (entry,word,pron) VALUES ( "
			.$dbh->quote($i)
			.","
			.$dbh->quote($word)
			.","
			.$dbh->quote($pron)
			.")"
		);
		$i++;
	}
	close WORDS;

	warn "All built without problems, disconnecting...\n" if $self->{CHAT};
	$dbh->disconnect();
	warn "...disconnected from db.\n" if $self->{CHAT};
	$self->{CHAT} = $oldchat;
} # End sub build



#
# Private method _connect just sets up the dbh is not already done so
# stores in _connected field
#
sub _connect { my $self=shift;
	if (defined $self->{_connected}) {
		#warn "Already connected to db.\n" if $self->{CHAT}; return $self->{connected};
	}
	warn "Connecting to db...\n" if $self->{CHAT};
	my $dsn = "DBI:$self->{DRIVER}:database=$self->{DATABASE};host=$self->{HOSTNAME};port=$self->{PORT}";
	my $dbh = DBI->connect($dsn, $self->{USERNAME}, $self->{PASSWORD});
	if (not $dbh){
		croak "Failed to connect with $self->{USERNAME}, $self->{PASSWORD}";
	}
	DBI->install_driver("mysql");
	$self->{_connected} = $dbh;
	return $dbh;
}

#
# Private subroutine _disconnect disconnects the global connection if it exists, otherwise
# can disconnect a specific dbh if passed.
#
sub _disconnect { my $self=shift;
	warn "Disconnecting from db.\n" if $self->{CHAT};
	if (defined $self->{_connected}) {
		$self->{_connected}->disconnect()
	} elsif ($_[0]) {
		$_[0]->disconnect()
	}
}


=head2 METHOD raw

Accepts database handle and scalar of the word to lookup

Returns raw Moby phoneme scalar from DB, or C<undef> on failure
to find the word (not necessarily an error).

You are advised to use other methods to look up data in the db:
if you do use this, note that the DB keys have _underscores_
instead of spaces. You can use the C<&prepare> function to
convert these.

=cut

sub raw { my ($self,$dbh,$lookup) = (shift,shift,shift);
	my $sth;
	my $Phonemes_ref;
	croak "No self-ref" if not $self;
	croak "No dbh" if not $dbh;
	croak "No lookup" if not $lookup;
	warn "Looking up phoneme for '$lookup' ... \n" if $self->{CHAT};
	$sth = $dbh->prepare("SELECT pron FROM words WHERE word = ".$dbh->quote($lookup) );
	$sth->execute();
	my $syl_ref = $sth->fetchrow_arrayref();
	warn "... and got @$syl_ref[0] \n" if defined $syl_ref and $self->{CHAT};
	return defined $syl_ref? @$syl_ref[0]  : undef;
}



=head2 METHOD phoneme ($word_to_lookup)

Accepts a word to look up.

Returns the phonemes of the word, as a scalar or array,
depending on the calling context,
or C<undef> if the word isn't in the dictionary.

The phoneme pattern is defined in the Moby documentation:
see C<PHONEMES>.

=cut

sub phoneme { my ($self,$lookup) = (shift,shift);
	$lookup = prepare($lookup);
	my $s = $self->raw(
		$self->_connect,
		$lookup
	);
	$self->_disconnect;
	return undef if not defined $s;
	wantarray? return split /\//,$s : $s;
}



=head2 METHOD phoneme_accent ($word_to_lookup)

Accepts a word to look up.

Returns a reference to an array of the phonemes of the word,
plus the index in that array of the primary accent,
and if there is a secondary accent, its index too.
Returns C<undef> if the word isn't in the dictionary.

The phoneme pattern is defined in the Moby documentation:
see C<PHONEMES>.

Note that the Moby documentation describes the primary
punctuation mark thus:

	 "'" (uncurled apostrophe) marks primary stress
	"," (comma) marks secondary stress.

This is plainly in reverse, as the entry for C<house> is
C<house ,h/&//U/s>.

=cut

sub phoneme_accent { my ($self,$lookup) = (shift,shift);
	my ($p,$s);
	$lookup = prepare($lookup);
	my $str = $self->raw(
		$self->_connect,
		$lookup
	);
	$self->_disconnect;
	return undef if not defined $str;
	@_ = split/\//,$str;
	for ($_=0;$_<=$#_;$_++){
		$p=$_ if $_[$_]=~/,/;
		$s=$_ if $_[$_]=~/'/;
	}
	return \@_,$p,$s;
}


#
# Prepare a scalar for lookup by converting \s to _
#
sub prepare {
	$_ = shift;
	s/\s+/_/sg;
	return $_;
}


1;
__END__


=head1 SEE ALSO

L<DBI>, L<DBD::mysql>,
L<Lingua::Rhyme>.

=head1 KEYWORDS

Phoneme, phoneme, syllable.

=head1 ACKNOWLEDGMENTS

The Moby dictionary was found at
described as I<Moby (tm) Pronunciator II...(22 June 93)>
with the contact address: I<3449 Martha Ct.,
Arcata, CA 95521-4884, USA, +1 (707) 826-7715>.

=head1 AUTHOR

Lee Goddard <lgoddard@cpan.org>

=head1 COPYRIGHT

THis module is Copyright (C) Lee Goddard, 10 June 2002.

This is free software, and can be used/modified under the same terms as Perl itself.

The Moby dictionary is Copyright (c) 1988-93, Grady Ward. All Rights Reserved.

=cut
