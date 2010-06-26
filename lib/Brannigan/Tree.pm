package Brannigan::Tree;

use strict;
use warnings;
use Brannigan::Validations;

=head1 NAME

Brannigan::Tree - A Brannigan validation/parsing scheme tree, possibly built from a series of inherited schemes.

=head1 DESCRIPTION

This module is used internally by L<Brannigan>. Basically, a tree is a
validation/parsing scheme in its "final", workable structure, taking
any inherited schemes into account. The actual validation and parsing
of input is done in this module.

=head1 MODULES

=head2 new( $tree )

Creates a new Brannigan::Tree instance.

=cut

sub new {
	bless pop, shift;
}

=head2 process( \%params )

Validates and parses the hash-ref of input parameters. Returns a hash-ref
of the parsed input, possibly containing a '_rejects' hash-ref with a list
of failed validations for each failed parameter.

=cut

sub process {
	my ($self, $params) = @_;

	# validate the data
	my $data = {};
	my $rejects = $self->validate($params);
	$data->{_rejects} = $rejects if $rejects;

	# parse the data
	foreach (keys %$params) {
		# is there a reference to this parameter in the scheme?
		next if !exists $self->{params}->{$_} && $self->{ignore_missing};

		unless (exists $self->{params}->{$_} && $self->{ignore_missing}) {
			# pass the parameter as is
			$data->{$_} = $params->{$_};
			next;
		}

		# is there a parsing method?
		if ($self->{params}->{$_}->{parse}) {
			my $parsed = $self->{params}->{$_}->{parse}->($params->{$_});
			foreach my $k (keys %$parsed) {
				$data->{$k} = $parsed->{$k};
			}
		} else {
			# just pass as-is
			$data->{$_} = $params->{$_};
		}
	}

	# parse group data
	foreach (keys %{$self->{groups}}) {
		my @data;
		foreach my $p (@{$self->{groups}->{$_}->{params}}) {
			push(@data, $params->{$p});
		}
		
		my $parsed = $self->{groups}->{$_}->{parse}->(@data);
		foreach my $k (keys %$parsed) {
			$data->{$k} = $parsed->{$k};
		}
	}

	return $data;
}

=head2 validate( \%params, [\%validations] )

Validates the hash-ref of input parameters and returns a hash-ref of rejects
(i.e. failed validation methods) for each parameter. Optionally receives
a hash-ref of custom validation methods (incomplete feature, to be completed
in the next release).

There is no need to call this method specifically, as it automatically
called by the C<process()> method.

=cut

sub validate {
	my ($self, $params, $validations) = @_;

	my $rejects;

	# go over all parameters
	foreach (keys %$params) {
		# is this parameter required? if not, and it has no value
		# (either under or empty string), then don't bother checking
		# any validations. if the parameter is forbidden and isn't provided,
		# do the same
		next unless exists $self->{params}->{$_};
		next if !$self->{params}->{$_}->{required} && (!defined $params->{$_} || $params->{$_} eq '');
		next if $self->{params}->{$_}->{forbidden} && (!defined $params->{$_} || $params->{$_} eq '');
		
		# get all validations we need to perform
		foreach my $v (keys %{$self->{params}->{$_}}) {
			next if $v eq 'parse';
			
			my @data = ref $self->{params}->{$_}->{$v} eq 'ARRAY' ? @{$self->{params}->{$_}->{$v}} : ($self->{params}->{$_}->{$v});
			
			# which validation method are we gonna use?
			# custom ones have preference
			if ($v eq 'validate' && ref $self->{params}->{$_}->{$v} eq 'CODE') {
				# this is an "inline" validation method, invoke it
				push(@{$rejects->{$_}}, $v) unless $self->{params}->{$_}->{$v}->($params->{$_}, @data);
			} elsif ($validations && $validations->{$v} && ref $validations->{$v} eq 'CODE') {
				# we're using a custom validation method defined in the
				# Brannigan object
				push(@{$rejects->{$_}}, $v.'('.join(', ', @data).')') unless $validations->{$v}->($params->{$_}, @data);
			} else {
				# we're using a built-in validation method
				push(@{$rejects->{$_}}, $v.'('.join(', ', @data).')') unless Brannigan::Validations->$v($params->{$_}, @data);
			}
		}
	}

	return $rejects;
}

=head1 SEE ALSO

L<Brannigan>, L<Brannigan::Validations>.

=head1 AUTHOR

Ido Perlmuter, C<< <ido at ido50.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-brannigan at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Brannigan>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc Brannigan::Tree

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

Brannigan is inspired by L<Oogly> (Al Newkirk) and the "Ketchup" jQuery
validation plugin (L<http://demos.usejquery.com/ketchup-plugin/>).

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Ido Perlmuter.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
