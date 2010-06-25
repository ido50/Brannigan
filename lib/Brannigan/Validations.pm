package Brannigan::Validations;

use strict;
use warnings;
use DateTime::Format::ISO8601;

sub required {
	my ($class, $value, $boolean) = @_;

	if ($boolean && !$value) {
		return undef;
	}

	return 1;
}

sub forbidden {
	my ($class, $value) = @_;

	return defined $value ? undef : 1;
}

sub length_between {
	my ($class, $value, $min, $max) = @_;

	return undef if length($value) < $min || length($value) > $max;

	return 1;
}

sub min_length {
	my ($class, $value, $min) = @_;

	return 1 unless defined $min && $min >= 0;

	return undef if !$value && $min || length($value) < $min;

	return 1;
}

sub max_length {
	my ($class, $value, $max) = @_;

	return undef if length($value) > $max;

	return 1;
}

sub exact_length {
	my ($class, $value, $length) = @_;

	return undef unless $value;

	return undef if length($value) != $length;
	
	return 1;
}

sub integer {
	my ($class, $value, $boolean) = @_;

	if ($boolean && $value !~ m/^\d+$/) {
		return undef;
	}

	return 1;
}

sub value_between {
	my ($class, $value, $min, $max) = @_;

	return undef if !defined($value) || $value < $min || $value > $max;

	return 1;
}

sub min_value {
	my ($class, $value, $min) = @_;

	return undef if $value < $min;

	return 1;
}

sub max_value {
	my ($class, $value, $max) = @_;

	return undef if $value > $max;

	return 1;
}

sub datetime {
	my ($class, $value) = @_;

	return undef unless $value;

	return DateTime::Format::ISO8601->parse_datetime($value) ? 1 : undef;
}

1;
