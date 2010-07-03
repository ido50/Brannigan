#!/usr/bin/perl -w

use strict;
use warnings;
use lib './lib';
use Brannigan;
use Data::Dumper;

my $b = Brannigan->new(
	{
		name => 'complex_scheme',
		ignore_missing => 1,
		params => {
			name => {
				hash => 1,
				keys => {
					'/^(first|last)_name$/' => {
						required => 1,
					},
					middle_name => {
						required => 0,
					},
				},
			},
			'/^(birth|death)_date$/' => {
				hash => 1,
				required => 1,
				keys => {
					_all => {
						required => 1,
						integer => 1,
					},
					day => {
						value_between => [1, 31],
					},
					mon => {
						value_between => [1, 12],
					},
					year => {
						value_between => [1900, 2100],
					},
				},
				parse => sub {
					my ($date, $type) = @_;

					# $type has either 'birth' or 'date',
					# $date has the hash-ref that was provided
					$date->{day} = '0'.$date->{day} if $date->{day} < 0;
					$date->{mon} = '0'.$date->{mon} if $date->{mon} < 0;
					return { "${type}_date" => join('-', $date->{year}, $date->{mon}, $date->{day}) };
				},
			},
			death_date => {
				required => 0,
			},
			id_num => {
				integer => 1,
				exact_length => 9,
				validate => sub {
					my $value = shift;

					return $value =~ m/^0/ ? 1 : undef;
				},
				default => sub {
					# generate a random 9-digit number that begins with zero
					my @digits = (0);
					foreach (2 .. 9) {
						push(@digits, int(rand(10)));
					}
					return join('', @digits);
				},
			},
			phones => {
				hash => 1,
				keys => {
					_all => {
						validate => sub {
							my $value = shift;

							return $value =~ m/^\d{2,3}-\d{7}$/ ? 1 : undef;
						},
					},
					'/^(home|mobile|fax)$/' => {
						parse => sub {
							my ($value, $type) = @_;

							return { $type => $value };
						},
					},
				},
			},
			education => {
				required => 1,
				array => 1,
				length_between => [1, 3],
				values => {
					hash => 1,
					keys => {
						'/^(start_year|end_year)$/' => {
							required => 1,
							value_between => [1900, 2100],
						},
						school => {
							required => 1,
							min_length => 4,
						},
						type => {
							required => 1,
							one_of => ['Elementary', 'High School', 'College/University'],
							parse => sub {
								my $value = shift;

								# returns the first character of the value in lowercase
								my @chars = split(//, $value);
								return { type => lc shift @chars };
							},
						},
					},
				},
			},
			employment => {
				required => 1,
				array => 1,
				length_between => [1, 5],
				values => {
					hash => 1,
					keys => {
						'/^(start|end)_year$/' => {
							required => 1,
							value_between => [1900, 2100],
						},
						employer => {
							required => 1,
							max_length => 20,
						},
						responsibilities => {
							array => 1,
							required => 1,
						},
					},
				},
			},
			other_info => {
				hash => 1,
				keys => {
					bio => {
						hash => 1,
						keys => {
							'/^(en|he|fr)$/' => {
								length_between => [100, 300],
							},
							fr => {
								required => 1,
							},
						},
					},
				},
			},
			'/^picture_(\d+)$/' => {
				max_length => 5,
				validate => sub {
					my ($value, $num) = @_;

					return $value =~ m!^http://! && $value =~ m!\.(png|jpg)$! ? 1 : undef;
				},
			},
			picture_1 => {
				default => 'http://www.example.com/images/default.png',
			},
		},
		groups => {
			generate_url => {
				params => [qw/id_num name/],
				parse => sub {
					my ($id_num, $name) = @_;

					return { url => "http://www.example.com/?id=${id_num}&$name->{last_name}" };
				},
			},
			pictures => {
				regex => '/^picture_(\d+)$/',
				parse => sub {
					return { pictures => \@_ };
				},
			},
		},
	}
);

my $params = {
	name => {
		first_name => 'Some',
		last_name => 'One',
	},
	birth_date => {
		day => 32,
		mon => -5,
		year => 1984,
	},
	death_date => {
		day => 12,
		mon => 12,
		year => 2112,
	},
	phones => {
		home => '123-1234567',
		mobile => 'what?',
	},
	education => [
		{ school => 'First Elementary School of Somewhere', start_year => 1990, end_year => 1996, type => 'Elementary' },
		{ school => 'Sch', start_year => 1996, end_year => 3000, type => 'Fake' },
	],
	other_info => {
		bio => { en => "Born, lives, will die.", he => "Nolad, Chai, Yamut." },
	},
	picture_1 => '',
	picture_2 => 'http://www.example.com/images/mypic.jpg',
	picture_3 => 'http://www.example.com/images/mypic.png',
	picture_4 => 'http://www.example.com/images/mypic.gif',
};

my $output = $b->process('complex_scheme', $params);
print Dumper($output);
