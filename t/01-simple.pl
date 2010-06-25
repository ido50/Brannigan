#!/usr/bin/perl -w

use strict;
use warnings;
use lib '../lib';
#use Test::More tests;
use Brannigan;

my $b = Brannigan->new(
	{
		name => 'post',
		ignore_missing => 1,
		params => {
			subject => {
				required => 1,
				length_between => [3, 40],
			},
			text => {
				required => 1,
				min_length => 10,
				validate => sub {
					my $value = shift;

					return undef unless $value;
					
					return $value =~ m/^lorem ipsum/ ? 1 : undef;
				}
			},
			day => {
				required => 0,
				integer => 1,
				value_between => [1, 31],
			},
			mon => {
				required => 0,
				integer => 1,
				value_between => [1, 12],
			},
			year => {
				required => 0,
				integer => 1,
				value_between => [1900, 2900],
			},
			section => {
				required => 1,
				integer => 1,
				value_between => [1, 3],
				parse => sub {
					my $val = shift;
					
					my $ret = $val == 1 ? 'reviews' :
						  $val == 2 ? 'receips' :
						  'general';
						  
					return { section => $ret };
				},
			},
			id => {
				required => 1,
				exact_length => 10,
				value_between => [1000000000, 2000000000],
			},
		},
		groups => {
			date => {
				params => [qw/year mon day/],
				required => 0,
				parse => sub {
					my ($year, $mon, $day) = @_;
					return undef unless $year && $mon && $day;
					return { date => $year.'-'.$mon.'-'.$day };
				},
			},
		},
	}, {
		name => 'edit_post',
		inherits_from => 'post',
		params => {
			subject => {
				required => 0,
			},
			id => {
				forbidden => 1,
			},
		},
	});

#ok($b, 'Got a proper Brannigan object');

my $data = $b->process('post', {
	subject		=> 'su',
	text		=> undef,
	day		=> 13,
	mon		=> 12,
	year		=> 2010,
	section		=> 2,
	thing		=> 3,
	id		=> 300000000,
});

use Data::Dumper;
print Dumper($data);

my $data2 = $b->process('post', {
	subject		=> 'subject',
	text		=> 'lorem ipsum dolor sit amet',
	section		=> 2,
	thing		=> 3,
	id		=> 1515151515,
});

use Data::Dumper;
print Dumper($data2);

my $data3 = $b->process('edit_post', {
	subject		=> 'subject edited',
	section		=> 3,
	id		=> 1515151515,
});

use Data::Dumper;
print Dumper($data3);

my $data4 = $b->process('edit_post', {
	subject		=> undef,
	id		=> undef,
	section		=> 1,
});

use Data::Dumper;
print Dumper($data4);

#done_testing();
