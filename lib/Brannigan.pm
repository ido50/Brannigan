package Brannigan;

use warnings;
use strict;
use Brannigan::Tree;

=head1 NAME

Brannigan - Easy, flexible system for validating and parsing input.

=head1 SYNOPSIS

    use Brannigan;

    my $foo = Brannigan->new();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 METHODS

=head2 new( $scheme | @schemes )

Creates a new instance of Brannigan, with the provided scheme(s) (see
L<Brannigan::Scheme> for complete description of schemes).

=cut

sub new {
	my $class = shift;

	my $self = { map { $_->{name} => $_ } @_ };

	return bless $self, $class;
}

=head2 process( $scheme, \%params )

Receives the name of a scheme and a hash-ref of inupt parameters, and
validates and parses these paremeters according to the scheme (see
L<Brannigan::Schema> for detailed information about this process).

Returns a hash-ref of parsed parameters according to the parsing scheme.

=cut

sub process {
	my ($self, $scheme, $params) = @_;

	return undef unless $scheme && $params && ref $params eq 'HASH' && $self->{$scheme};

	my $tree = $self->_build_tree($scheme);

	return $tree->process($params);
}

=head1 INTERNAL METHODS

=head2 _build_tree( $scheme )

Builds the final "tree" of validations and parsing methods to be performed
on the parameters hash during processing.

=cut

sub _build_tree {
	my ($self, $scheme) = @_;

	my @trees;

	# get a list of all schemes to inherit from
	my @schemes = $self->{$scheme}->{inherits_from} && ref $self->{$scheme}->{inherits_from} eq 'ARRAY' ? @{$self->{$scheme}->{inherits_from}} : $self->{$scheme}->{inherits_from} ? ($self->{$scheme}->{inherits_from}) : ();

	foreach (@schemes) {
		next unless $self->{$_};
		
		push(@trees, $self->_build_tree($_));
	}

	return Brannigan::Tree->new($self->_merge_trees(@trees, $self->{$scheme}));
}

=head2 _merge_trees( @trees )

Merges two or more hash-ref of validation/parsing trees and returns the
resulting tree. The merge is performed in order, so trees later in the
array (i.e. on the right) "tramp" the trees on the left.

=cut

sub _merge_trees {
	my $self = shift;

	return undef unless scalar @_ && (ref $_[0] eq 'HASH' || ref $_[0] eq 'Brannigan::Tree');

	# the leftmost tree is the starting tree
	my $tree = shift;
	my %tree = %$tree;

	# now for the merging business
	foreach (@_) {
		next unless ref $_ eq 'HASH';

		foreach my $k (keys %$_) {
			if (ref $_->{$k} eq 'HASH') {
				unless (exists $tree{$k}) {
					$tree{$k} = $_->{$k};
				} else {
					$tree{$k} = $self->_merge_trees($tree{$k}, $_->{$k});
				}
			} else {
				$tree{$k} = $_->{$k};
			}
		}
	}

	return \%tree;
}

=head1 AUTHOR

Ido Perlmuter, C<< <ido at ido50.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-brannigan at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Brannigan>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Brannigan

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Brannigan>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Brannigan>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Brannigan>

=item * Search CPAN

L<http://search.cpan.org/dist/Brannigan/>

=back

=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2010 Ido Perlmuter.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
