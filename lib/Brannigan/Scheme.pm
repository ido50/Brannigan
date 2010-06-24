package Brannigan::Scheme;

use strict;
use warnings;
use Brannigan::Validations;

sub new {
	bless pop, shift;
}

sub validate {
	my ($self, $params. $validations) = @_;

	my $rejects;

	# go over all parameters
	foreach (keys %$params) {
		# get all validations we need to perform
		my %todo = %{$self->{params}->{$_}};
		if ($self->{inherits_from}) {
			my @other_schemes = ref $self->{inherits_from} eq 'ARRAY' ? @{$self->{inherits_from}} : ($self->{inherits_from});
			foreach my $s (@other_schemes) {
				foreach my $k (%{$s->{params}->{$_}}) {
					$todo{$k} = $s->{params}->{$_}->{$k};
				}
			}
		}

		foreach my $v (keys %todo) {
			next if $v eq 'parse';
			
			my @data = ref $todo{$v} eq 'ARRAY' ? @{$todo{$v}} : ($todo{$v});
			
			# which validation method are we gonna use?
			# custom ones have preference
			if ($v eq 'validate' && ref $todo{$v} eq 'CODE') {
				# this is an "inline" validation method, invoke it
				push(@{$rejects->{$_}}, $v) unless $todo{$v}->(@data);
			} elsif ($validations && $validations->{$v} && ref $validations->{$v} eq 'CODE') {
				# we're using a custom validation method defined in the
				# Brannigan object
				push(@{$rejects->{$_}}, $v) unless $validations->{$v}->(@data);
			} else {
				# we're using a built-in validation method
				push(@{$rejects->{$_}}, $v) unless Brannigan::Validations->$v(@data);
			}
		}
	}

	return $rejects;
}

sub process {
	my ($self, $params) = @_;

	# validate the data
	my $data = { _rejects => $self->validate($params) };

	# parse the data
	foreach (keys %$params) {
		# is there a reference to this parameter in the scheme?
		unless ($self->{params}->{$_} && $self->{ignore_missing}) {
			# pass the parameter as is
			$data->{$_} = $params->{$_};
			next;
		}

		# is there a parsing method?
		if ($self->{params}->{$_}->{parse}) {
			my $parsed = $self->{params}->{$_}->{parse}->($_);
			foreach my $k (keys %$parsed) {
				$data->{$k} = $parsed->{$k};
			}
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

1;
