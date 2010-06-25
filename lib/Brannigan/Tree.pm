package Brannigan::Tree;

use strict;
use warnings;
use Brannigan::Validations;

sub new {
	bless pop, shift;
}

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

1;
