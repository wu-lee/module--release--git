#!/usr/bin/perl
use strict;
use warnings;
use vars qw($run_output);

use Test::More tests => 55;

my $class  = 'Module::Release::Git';
my $method = 'vcs_tag';

use_ok( 'Module::Release' );
use_ok( $class );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

=pod

To test these functions, I want to give them some sample git 
output and ensure they do what I want them to do. Instead of
running git, I override the run() method to return whatever 
is passed to it.

FIXME apparently we need to parse tgz and zip extensions!  I don't
think the current version of Module::Release::dist_version does that.

=cut

{
package Null;

sub new { bless {}, __PACKAGE__ }
sub AUTOLOAD { "" }

package main;
no warnings qw(redefine once);
*Module::Release::run         = sub { $main::run_output = $_[1] };
*Module::Release::remote_file = sub { $_[0]->{remote_file} };
*Module::Release::_warn       = sub { 1 };
*Module::Release::_print      = sub { 1 };
}

my $release = Module::Release->new;

# Note: this emits 'redefined' warnings, but only when run under 'make test',
# and my efforts to squelch them have so far failed.
$release->load_mixin($class);

can_ok( $release, $method );

# Define our test cases.  'tag' is passed to ->vcs_tag, and 'expect'
# is the tag we expect to get supplied to Git (or a regex matching the
# error).  If remote_file is specified, then this key and it's valye
# is inserted into the $release object, emulating the release of a
# distro with that file name.
my @cases = (
    {
        desc => 'an arbitrary tag argument', 
        tag => 'foo',
        expect => 'foo',
    },
    {
        desc => 'no tag info',
        tag => undef,
        expect => 'RELEASE__',
    },
    {
        desc => 'two-number version',
        tag => undef, remote_file => 'Foo-Bar-45.98.tar.gz',
        expect => 'RELEASE_45_98',
    },
    {
        desc => 'two-number dev version',
        tag => undef, remote_file => 'Foo-Bar-45.98_01.tar.gz',
        expect => 'RELEASE_45_98_01',
    },

    # (The following tests have been adapted from similar ones added
    # in Module::Release to test the same things)
    { 
        desc => "two-part version string with leading 'v'",
        remote_file => 'Foo-v3.45.tar.gz',
        expect => 'RELEASE_V3_45_0',
    },
    {
        desc => "three-part version string with leading 'v'",
        remote_file => 'Foo-v3.45.1.tar.gz',
        expect => 'RELEASE_V3_45_1',
    },
    {
        desc => "three-part development version string with leading 'v'",
        remote_file => 'Foo-v3.45_1.tar.gz',
        expect => 'RELEASE_V3_45_1',
    },

    # Capitalisation, various suffixes
    {
        desc => "three-part version string with capitalised leading 'V'",
        remote_file => 'Foo-V3.45.1.tar.gz',
        expect => 'RELEASE_V3_45_1',
    },
    {
        desc => "...with capitalised suffix",
        remote_file => 'Foo-v3.45.1.TAR.GZ',
        expect => 'RELEASE_V3_45_1',
    },
    {
        desc => "...with no suffix",
        remote_file => 'Foo-v3.45.1',
        expect => 'RELEASE_V3_45_1',
    },
    
    # Test three-part version numbers with no leading 'v'.  Not sure if
    # this occurs in the wild, but presumably this should result in the
    # same as above.
    {
        desc => "three-part version string with no leading 'v'",
        remote_file => 'Foo-3.45.1.tar.gz',
        expect => 'RELEASE_V3_45_1',
    },
    {
        desc => "...with capitalised suffix",
        remote_file => 'Foo-3.45.1.TAR.GZ',
        expect => 'RELEASE_V3_45_1',
    },
    {
        desc => "...with no suffix",
        remote_file => 'Foo-3.45.1',
        expect => 'RELEASE_V3_45_1',
    },
    
    # Test four-part version development numbers with no leading 'v'.
    # (Note, four, since the three case must be backward compatible and return
    # the same as the earlier test above.)
    {
        desc => "four-part version string with no leading 'v'",
        remote_file => 'Foo-3.45.1.1.tar.gz',
        expect => 'RELEASE_V3_45_1_1',
    },
    {
        desc => "four-part development version string with no leading 'v'",
        remote_file => 'Foo-3.45.1_1.tar.gz',
        expect => 'RELEASE_V3_45_1_1',
    },
    
    # Test distros with no version
    {
        desc => "no version",
        remote_file => 'Foo.tar.gz',
        expect => 'RELEASE__',
    },
    {
        desc => "...with no suffix",
        remote_file => 'Foo',
        expect => 'RELEASE__',
    },

    
    # Test git_default_tag option
    {
        desc => 'no tag info, non-default default tag, unpermissive tags',
        options => {
            git_default_tag => 'Some.other-default -/tag',
            git_allow_non_cvs_tags => 1,
        },
        expect => 'Some.other-default---tag',
    },
    {
        desc => 'no tag info, non-default default, permissive tags',
        options => {
            git_default_tag => 'Some.other-default -/tag',
        },
        expect => 'SOME_OTHER_DEFAULT___TAG',
    },

    # Test git_parse_version_or_die option
    {
        desc => 'no tag info, die on parse failure',
        options => {
            git_parse_version_or_die => 1,
        },
        expect => qr/Could not parse/,
    },
    {
        desc => 'unparsable version, die on parse failure',
        tag => undef, remote_file => 'Foo-Bar-45.xx.tar.gz',
        options => {
            git_parse_version_or_die => 1,
        },
        expect => qr/Could not parse/,
    },

    # Test git_allow_non_cvs_tags option
    { 
        desc => "two-part version string, permissive tags",
        options => {
            git_allow_non_cvs_tags => 1,
        },
        remote_file => 'Foo-3.45.tar.gz',
        expect => 'release-3.45',
    },
    { 
        desc => "two-part dev version string, permissive tags",
        options => {
            git_allow_non_cvs_tags => 1,
        },
        remote_file => 'Foo-3.45_01.tar.gz',
        expect => 'release-3.45_01',
    },
    { 
        desc => "two-part version string with leading 'v', permissive tags",
        options => {
            git_allow_non_cvs_tags => 1,
        },
        remote_file => 'Foo-v3.45.tar.gz',
        expect => 'release-v3.45.0',
    },
    {
        desc => "three-part version string with leading 'v', permissive tags",
        options => {
            git_allow_non_cvs_tags => 1,
        },
        remote_file => 'Foo-v3.45.1.tar.gz',
        expect => 'release-v3.45.1',
    },
    {
        desc => "three-part development version string with leading 'v', permissive tags",
        options => {
            git_allow_non_cvs_tags => 1,
        },
        remote_file => 'Foo-v3.45_1.tar.gz',
        expect => 'release-v3.45_1',
    },
    {
        desc => "three-part version string with capitalised leading 'V', permissive tags",
        options => {
            git_allow_non_cvs_tags => 1,
        },
        remote_file => 'Foo-V3.45.1.tar.gz',
        expect => 'release-v3.45.1',
    },
);



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# quotes values, but maps undefs to '<undef>'
sub defang_undef {
    return map { defined $_? "'$_'" : '<undef>' } @_;
} 


foreach my $case (@cases) {
    # Create a new release instance (so we may set options in each
    # case)
    my $release = Module::Release->new;

#    $release->load_mixin($class); Don't do this more than once

    # Set remote_file if one is supplied
    $release->{remote_file} = $case->{remote_file}
        if defined $case->{remote_file};

    # Set options, if any
    if (my $options = $case->{options}) {
        foreach my $option (keys %$options) {
            $release->config->set($option, $options->{$option});
        }
    }

    # Clear run_output
    undef $main::run_output;

    my $expect = $case->{expect};
    my $tag = $case->{tag};
    if (ref $expect eq 'Regexp') {
        # Expect an error
        
        my $result = eval {
            $release->$method( $tag );
            1;
        };
        my $err = $@;

        if ($result) {
            fail sprintf(
                "$case->{desc}: ->%s(%s) unexpectedly succeeded",
                $method, defang_undef $tag
            );
        }
        else {
            like $err, $expect, sprintf(
                "$case->{desc}: ->%s(%s) failed  as expected",
                $method, defang_undef $tag,
            );
        }
    }
    else {
        ok( $release->$method( $tag ),
            sprintf(
                "$case->{desc}: ->%s(%s) returns true with %s",
                $method,
                defang_undef @$case{qw(tag remote_file)},
            ),
        );
        
        my $expected_cmd = "git tag $expect";
        is( $main::run_output,
            $expected_cmd,
            sprintf(
                "  ...and run output sees '%s'",
                $expected_cmd,
            ),
        );
    }
}
