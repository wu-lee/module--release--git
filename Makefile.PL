use ExtUtils::MakeMaker;

require 5.006;

eval "use Test::Manifest 1.21";

WriteMakefile(
	'NAME'	       => 'Module::Release::Git',
	'ABSTRACT'     => 'Use Git instead of CVS with Module::Release',
	'VERSION_FROM' => 'lib/Git.pm',
	'LICENSE'      => 'perl',
	'AUTHOR'       => 'brian d foy <bdfoy@gmail.com>',

	'BUILD_REQUIRES'    => { 
		'Test::More'      => '0',
        },
	'PREREQ_PM'    => { 
		'Module::Release' => '2.05_05',
	},

	'PM'           => {
		'lib/Git.pm'         => '$(INST_LIBDIR)/Git.pm',
		},

	'MAN3PODS'     => {
		'lib/Git.pm' => '$(INST_MAN3DIR)/Module::Release::Git.3',
		},

	clean  => { FILES    => q|Module-Release-Git-*| },

	);
