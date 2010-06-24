package Brannigan;

use warnings;
use strict;
use Brannigan::Scheme;

=head1 NAME

Brannigan - Easy, flexible system for validating and parsing input.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

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

	my $self = { map { $_->{name} => Brannigan::Scheme->new($_) } @_ };

	return bless $self, $class;
}

=head2 process( $scheme, \%params )

Receives the name of a scheme and a hash-ref of inupt parameters, and
validates and parses these paremeters according to the scheme (see
L<Brannigan::Schema> for detailed information about this process).

Returns a hash-ref of parsed parameters according to the parsing scheme.

=cut

sub process {
	my ($self, $scheme, $params);

	return undef unless $scheme && $params && ref $params eq 'HASH' && $self->{$scheme};

	return $self->{$scheme}->process($params);
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
