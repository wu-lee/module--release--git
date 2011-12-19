package Module::Release::Git;

use strict;
use warnings;
use base qw(Exporter);

our @EXPORT = qw(check_vcs vcs_tag make_vcs_tag);

use vars qw($VERSION);
$VERSION = '0.14';

=head1 NAME

Module::Release::Git - Use Git with Module::Release

=head1 SYNOPSIS

The release script automatically loads this module if it sees a 
F<.git> directory. The module exports C<check_vcs>, C<vcs_tag>, and 
C<make_vcs_tag>.

=head1 DESCRIPTION

Module::Release::Git subclasses Module::Release, and provides
its own implementations of the C<check_vcs()> and C<vcs_tag()> methods
that are suitable for use with a Git repository.

These methods are B<automatically> exported in to the callers namespace
using Exporter.

This module depends on the external git binary (so far).

=over 4

=item check_vcs()

Check the state of the Git repository.

=cut

sub check_vcs 
	{
	my $self = shift;
	
	$self->_print( "Checking state of Git... " );
	
	my $git_status = $self->run('git status 2>&1');
		
	no warnings 'uninitialized';

	my( $branch ) = $git_status =~ /^# On branch (\w+)/;
	
	my $up_to_date = $git_status =~ /^nothing to commit \(working directory clean\)/m;
	
	$self->_die( "\nERROR: Git is not up-to-date: Can't release files\n\n$git_status\n" )
		unless $up_to_date;
	
	$self->_print( "Git up-to-date on branch $branch\n" );
	
	return 1;
	}

=item vcs_tag(TAG)

Tag the release in local Git.

=cut

sub vcs_tag 
	{
	my( $self, $tag ) = @_;
	
	$tag ||= $self->make_vcs_tag;
	
	$self->_print( "Tagging release with $tag\n" );

	return 0 unless defined $tag;
	
	$self->run( "git tag $tag" );

	return 1;
	}

=item make_vcs_tag

By default, examines the name of the remote file
(i.e. F<Foo-Bar-0.04.tar.gz>) and constructs a tag string like
C<RELEASE_0_04> from it.  Override this method if you want to use a
different tagging scheme, or don't even call it.

For backward compatibility: unless otherwise configured (see
L</CONFIGURATION>), if parsing fails, it prints a warning with ->_warn
and returns an 'RELEASE__', rather than throwing.

=cut

sub make_vcs_tag
	{
	my $self = shift;

	# Parse the version; catch errors.
	my $version = eval { $self->dist_version };
	my $err = $@;

	my $tag = $self->config->get( 'git_default_tag' );
	$tag = 'RELEASE__'
		if !$self->config->exists( 'git_default_tag' );

	if ( defined $version && length $version)
		{
		$tag = "release-$version";
		}
	else
		{
		# If we get here, the version did not parse. In this
		# case, we can be configured to croak or warn
		my $method = $self->config->get( 'git_parse_version_or_die' )?
		    '_die' : '_warn';

		no warnings 'uninitialized';
		$err =~ s/\n at .*//; # strip stack trace
		$self->$method( "Could not parse remote [$self->{remote_file}] to get a version ($err)" );
		}

	# Try to make sure the version is a valid tag - although if
	# the version came via ->dist_version it should normally be a
	# valid Perl version and therefore safe.
	if ( $self->config->get( 'git_allow_non_cvs_tags' ) )
		{
		# Note this isn't backward compatible with earlier
		# behaviour, which enforced a CVS-style tag, with
		# . and - mapped to _
		$tag =~ s/[^\w.-]/-/g;
		}
	else
		{
		$tag = uc $tag;
		$tag =~ s/\W/_/g;
		}

	return $tag;
	}

=back

=head1 CONFIGURATION

By default this module aims to behave in a backward compatible manner.

The following configuration parameters can alter this.  The should be
supplied to C<Module::Release> in the normal way (i.e. typically via
the C<.releaserc> file).

=over 4

=item git_allow_non_cvs_tags

For historical reasons, by default tags are converted to conform to
CVS's rules, i.e. upper case text and underscores, with anything else
converted to underscores.  You can allow more idiomatic Git tags by
setting this to a true value, in which case periods, dashes, and
lowercase text are preserved.

=item git_default_tag

Historically, if a version did not parse, the tag C<RELEASE__> was
what resulted (along with a warning message).  You can set this
configuration value to define it to be to something else.

=item git_parse_version_or_die

Or alternatively, set this to cause an exception to be thrown instead
of a warning when the version parse fails.

=back
	
=head1 TO DO

=over 4

=item Use Gitlib.pm whenever it exists

=item More options for tagging

=back

=head1 SEE ALSO

L<Module::Release::Subversion>, L<Module::Release>

=head1 SOURCE AVAILABILITY

This module is in Github:

	git://github.com/briandfoy/module--release--git.git

=head1 AUTHOR

brian d foy, C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2007-2009, brian d foy, All Rights Reserved.

You may redistribute this under the same terms as Perl itself.

=cut

1;
