use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
    'NAME'		=> 'Lingua::Phoneme',
    'VERSION_FROM'	=> 'Phoneme.pm', # finds $VERSION
    'PREREQ_PM'		=> {
		DBI=>'0.1',
	}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Phoneme.pm', # retrieve abstract from module
       AUTHOR     => 'Lee Goddard <lgoddard@cpan.org') : ()),
);

print <<"_STOP_";

Once you have done make install, please read the
documentation to learn how to install the dictionary
DB table using buld.pl.

Once it is installed, please run tests.pl.

_STOP_
;
exit;