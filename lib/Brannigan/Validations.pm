package Brannigan::Validations;

use strict;
use warnings;

=head1 NAME

Brannigan::Validations - Built-in validation methods for Brannigan.

=head1 DESCRIPTION

This module contains all built-in validation methods provided natively
by the L<Brannigan> input validation/parsing system.

=head1 METHODS

All these methods receive the value of a parameter, and other values
that explicilty define the requirements. They return a true value if the
parameter's value passed the test, or a false value otherwise.

=head2 required( $value, $boolean )

If C<$boolean> is true, makes sure a required parameter was indeed provided,
otherwise simply returns true.

Please note that if a parameter is not required and indeed isn't provided
with the input parameters, any other validation methods defined on the
parameter will not be checked.

=cut

sub required {
	my ($class, $value, $boolean) = @_;

	return undef if $boolean && !$value;

	return 1;
}

=head2 forbidden( $value, $boolean )

If C<$boolean> is true, makes sure a forbidden parameter was indeed NOT
provided. Otherwise, a true value is returned.

=cut

sub forbidden {
	my ($class, $value, $boolean) = @_;

	return defined $value && $boolean ? undef : 1;
}

=head2 length_between( $value, $min_length, $max_length )

Makes sure the value's length (stringwise) is inside the range of
C<$min_length>-C<$max_length>, or, if the value is an array reference,
makes sure it has between C<$min_length> and C<$max_length> items.

=cut

sub length_between {
	my ($class, $value, $min, $max) = @_;

	my $length = ref $value eq 'ARRAY' ? @$value : length($value);
	
	return undef if $length < $min || $length > $max;

	return 1;
}

=head2 min_length( $value, $min_length )

Makes sure the value's length (stringwise) is at least C<$min_length>, or,
if the value is an array reference, makes sure it has at least C<$min_length>
items.

=cut

sub min_length {
	my ($class, $value, $min) = @_;

	my $length = ref $value eq 'ARRAY' ? @$value : length($value);

	return 1 unless defined $min && $min >= 0;

	return undef if !$value && $min || $length < $min;

	return 1;
}

=head2 max_length( $value, $max_length )

Makes sure the value's length (stringwise) is no more than C<$max_length>,
or, if the value is an array reference, makes sure it has no more than
C<$max_length> items.

=cut

sub max_length {
	my ($class, $value, $max) = @_;

	my $length = ref $value eq 'ARRAY' ? @$value : length($value);

	return undef if $length > $max;

	return 1;
}

=head2 exact_length( $value, $length )

Makes sure the value's length (stringwise) is exactly C<$length>, or,
if the value is an array reference, makes sure it has exactly C<$exact_length>
items.

=cut

sub exact_length {
	my ($class, $value, $exlength) = @_;

	return undef unless $value;

	my $length = ref $value eq 'ARRAY' ? @$value : length($value);

	return undef if $length != $exlength;
	
	return 1;
}

=head2 integer( $value, $boolean )

If boolean is true, makes sure the value is an integer.

=cut

sub integer {
	my ($class, $value, $boolean) = @_;

	if ($boolean && $value !~ m/^\d+$/) {
		return undef;
	}

	return 1;
}

=head2 value_between( $value, $min_value, $max_value )

Makes sure the value is between C<$min_value> and C<$max_value>.

=cut

sub value_between {
	my ($class, $value, $min, $max) = @_;

	return undef if !defined($value) || $value < $min || $value > $max;

	return 1;
}

=head2 min_value( $value, $min_value )

Makes sure the value is at least C<$min_value>.

=cut

sub min_value {
	my ($class, $value, $min) = @_;

	return undef if $value < $min;

	return 1;
}

=head2 max_value( $value, $max )

Makes sure the value is no more than C<$max_value>.

=cut

sub max_value {
	my ($class, $value, $max) = @_;

	return undef if $value > $max;

	return 1;
}

=head2 array( $value, $boolean )

If C<$boolean> is true, makes sure the value is actually an array reference.

=cut

sub array {
	my ($class, $value, $boolean) = @_;

	return $boolean ? ref $value eq 'ARRAY' ? 1 : undef : ref $value eq 'ARRAY' ? undef : 1;
}

=head2 hash( $value, $boolean )

If C<$boolean> is true, makes sure the value is actually a hash reference.

=cut

sub hash {
	my ($class, $value, $boolean) = @_;

	return $boolean ? ref $value eq 'HASH' ? 1 : undef : ref $value eq 'HASH' ? undef : 1;
}

=head2 one_of( $value, @values )

Makes sure a parameter's value is one of the provided acceptable values.

=cut

sub one_of {
	my ($class, $value, @values) = @_;

	foreach (@values) {
		return 1 if $value eq $_;
	}

	return undef;
}

=head1 SEE ALSO

L<Brannigan>, L<Brannigan::Tree>.

=head1 AUTHOR

Ido Perlmuter, C<< <ido at ido50 dot net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-brannigan at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Brannigan>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc Brannigan::Validations

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

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Ido Perlmuter.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
