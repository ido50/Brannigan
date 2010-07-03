package Brannigan;

# ABSTRACT: Comprehensive, flexible system for validating and parsing input, mainly targeted at web applications.

use warnings;
use strict;
use Brannigan::Tree;

=head1 NAME

Brannigan - Comprehensive, flexible system for validating and parsing input, mainly targeted at web applications.

=head1 SYNOPSIS

This example uses L<Catalyst>, but should be pretty self explanatory. It's
fairly complex, since it details pretty much all of the available Brannigan
functionality, so don't be alarmed by the size of this thing.

	package MyApp::Controller::Post;

	use strict;
	use warnings;
	use Brannigan;

	# create a new Brannigan object with two validation/parsing schemes:
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
			qr/^picture_(\d+)$/ => {
				length_between => [3, 100],
				validate => sub {
					my ($value, $num) = @_;

					...
				},
			},
			somearray => {
				array => 1,
				integer => 1,
			},
			somehash => {
				hash => 1,
				params => {
					en => {
						required => 1,
						exact_length => 10,
					},
					he => {
						exact_length => 10,
					},
				},
			},
		},
		groups => {
			date => {
				params => [qw/year mon day/],
				parse => sub {
					my ($year, $mon, $day) = @_;
					return undef unless $year && $mon && $day;
					return { date => $year.'-'.$mon.'-'.$day };
				},
			},
			tags => {
				regex => qr/^tags_(en|he|fr)$/,
				parse => sub {
					my @matches = @_;
					
					# every match is a little hash-ref with
					# a 'value' key containing the value of
					# the matched parameter, and a 'captures'
					# key containing an array-ref of all
					# regex captures
					
					my $hash = {};
					foreach (@matches) {
						my $value = $_->{value};
						my $lang = shift @{$_->{captures}};
						
						$hash->{$lang} = $value;
					}

					return { tags => $hash };
				},
			},
		},
	}, {
		name => 'edit_post',
		inherits_from => 'post',
		params => {
			subject => {
				required => 0, # subject is no longer required
			},
			id => {
				forbidden => 1,
			},
		},
	});

	# post a new blog post
	sub new_post : Local {
		my ($self, $c) = @_;

		# get input parameters hash-ref
		my $params = $c->request->params;

		# process the parameters
		my $parsed_params = $b->process('post', $params);

		if ($parsed_params->{_rejects}) {
			die $c->list_errors($parsed_params);
		} else {
			$c->model('DB::BlogPost')->create($parsed_params);
		}
	}

	# edit a blog post
	sub edit_post : Local {
		my ($self, $c, $id) = @_;

		my $params = $b->process('edit_posts', $c->req->params);

		if ($params->{_rejects}) {
			die $c->list_errors($params);
		} else {
			$c->model('DB::BlogPosts')->find($id)->update($params);
		}
	}

=head1 DESCRIPTION

Brannigan is an attempt to ease the pain of collecting input parameters
in web applications, validating them and finally (if necessary),
parsing them before actually using them. On the "validational" aspect
of this module, it is quite like L<Oogly>. The idea is to define a structure
of parameters ("fields" in Oogly) and their needed validations, and let
the module automatically examine input parameters against this structure.
Unlike Oogly, however, Brannigan does provide validation routines (along
with custom validations), and also allows the ability to parse input (which
probably means turning input parameters into something usable by the app).

Check the synopsis section for an example of such a structure. I call this
structure a validation/parsing scheme. Schemes can inherit all the properties
of other schemes, which allows you to be much more flexible in certain
situations. As per the synopsis example, imagine you have a blogging
application. The base scheme defines all validations and parsing needed
to create a new blog post. When editing a post, however, some parameters
that were required when creating the post might not be required now (so
you can just use older values). Inheritance allows you to do so easily by
creating another scheme which gets all the properties of the base scheme,
only changing whatever it is needs changing (and possibly adding specific
properties that don't exist in the base scheme).

Brannigan works by receiving a hash-ref of input parameters, asserting
all validation methods required for each parameter, and parsing every
parameter (or group of parameters, see below). Brannigan then returns
a hash-ref with all parsed input parameters, and a '_rejects' key with
failed validations (see more info below).

=head1 HOW SCHEMES WORK

A scheme is just a hash-ref with the following keys:

=over

=item * name

Defines the name of the scheme. Required.

=item * ignore_missing

Boolean value indicating whether input parameters that are not referenced
in the scheme should be added to the parsed output or not. Optional,
defaults to false (i.e. parameters missing from the scheme will be added
to the output as-is).

=item * inherits_from

Either a scalar naming a different scheme or an array-ref of scheme names.
The new scheme will inherit all the properties of the scheme(s) defined
by this key. If an array-ref is provided, the scheme will inherit their
properties in the order the are defined. See the CAVEATS section for some
"heads-up" about inheritance.

=item * params

A hash-ref containing the names of input parameters. Every such name (i.e.
key) in itself is also a hash-ref. This hash-ref defines the necessary
validation methods, and optionally a parse method. This is done by naming
the validation method as the key, and passing parameters to that method
with the value. A custom validation method is defined with the 'validate'
key, which expects to receive an anonymous subroutine. The value of the
input parameter is automatically prepended to all validation routines, and
these are expected to return a true value if the parameter passed
the check, or a false value otherwise. A parsing method is defined with
the 'parse' method, which is also an anonymous subroutine which
automatically receives the value of the parameter. This method is expected
to return a hash-ref of key-value pairs. These will be automatically
appended to the output hash-ref. If no C<parse()> method is provided,
the parameter is appended to the output hash-ref as-is (i.e. C<< param => value >>).

For a list of all validation methods provided by Brannigan, check
L<Brannigan::Validations>.

As of version 0.3, parameter names can also be regular expressions in the
form qr/regex/. Sometimes you cannot know the names of all parameters passed
to your app. For example, you might have a dynamic web form which starts with
a single field called 'url_1', but your app allows your visitors to dynamically
add more fields, such as 'url_2', 'url_3', etc. Regular expressions are
handy in such situations. Your parameter key can be qr/^url_(\d+)$/, and
all such fields will be matched. Regex params have a special feature: if
you're regex uses capturing, then captured values will be passed to the
custom C<validate> and C<parse> methods (in their order) after the parameter's
value. For example:

	qr/^url_(\d+)$/ => {
		validate => sub {
			my ($value, $num) = @_;

			return $value =~ m!^http://! ? 1 : undef;
		},
		parse => sub {
			my ($value, $num) = @_;

			return { urls => { $num => $value } };
		},
	}

Note that if a certain parameter was directly referenced in the scheme,
but also matched a regular expression, only the properties of the direct
reference to that parameter will be used.

As of version 0.3, Brannigan can also validate and parse a little more
complex data structures. You can define a parameter as being an array
(check the 'somearray' parameter in the synopsis example), which will cause
Brannigan to check if the appropriate parameter in the input hash-ref is
an array-ref, and if so, check all other validation methods on the values
of this array-ref. If a value inside this array-ref fails any of the
validation methods, it will be added to the '_rejects' hash-ref with the
name of the parameter and the index of the value. For example, in our
synopsis example, if the third value in the 'somearray' parameter failed
the 'exact_length(10)' validation, then the _rejects hash-ref will contain
C<{ somearray[2] => ['exact_length(10'] }>.

Furthermore, you can define a parameter as being a hash (check the 'somehash'
parameter in the synopsis example), which will cause Brannigan to check
if the parameter's value is actually a hash-ref. This kinda makes the
definition of validations on the keys of this hash-ref a mini-scheme.
For example:

	hash_param => {
		hash => 1,
		en => {
			required => 1,
			exact_length => 3,
		},
		he => {
			exact_length => 3,
		},
	}

After validating the 'hash_param' parameter is a hash-ref, Brannigan will
go on the check the validation methods for each parameter of this hash-ref,
such as 'en' and 'he.

Note that Brannigan does not support deeper hash-refs, so a parameter can
be a hash-ref, but none of it's "sub-parameters" can be hash-refs too.

=item * groups

A hash-ref containing the names of groups of input parameters. These are
useful for parsing input parameters that are somehow related together.
As per the synopsis example, suppose your web application receives a date
by using three input fields (day, month and year). A parse method on these
three parameters allows you, for example, to return a string called 'date'
which concatenates these three parameters to the YYYY-MM-DD format. A group
is defined with a 'params' key, which expects an array-ref of parameters
that belong to the group, and a 'parse' key which expects an anonymous
subroutine, just like for individual parameters. This subroutine will
receive the values of the parameters in the order they were defined.

	group_name => {
		params => [qw/one two three/],
		parse => sub {
			my ($one, $two, $three) = @_;
		
			...
		},
	}

Alternatively to the 'params' key, you can define a 'regex' key that takes
a regex. All parameters whose name matches this regex will be parsed as
a group. This is a bit more complex than regexes in the C<params> hash. The
C<parse> method will receive an array of hash-refs. Each of these hash-refs
is a parameter that was matched by the regex, and will contain a 'value'
key with value of the parameter, and a 'captures' key with an array-ref of
all the regex's captures, in their order. In the following example, the regex
captures a number from the name of each parameter (such as 12 in 'param_12').
The C<parse> method will receive an array containing hash-refs such as
C<{ value => 'some value', captures => [12] }>.

	group_name => {
		regex => qr/^param_(\d+)$/,
		parse => sub {
			my @matches = @_;

			...
		},
	}

=back

After validating, if any validation requirements were not met by any of the
input parameters, the resulting hash-ref will also include a '_rejects'
key, whose value is a hash-ref of "misbehaving" parameters and all the
validation methods they failed (in an array-ref). Errors are not raised
and error messages are not created, this will be your job, and I think
it's better this way, 'cause there is no flexibility in automatic error
messages. Suppose a parameter failed the 'min_length' test, which was defined
with a minimum length of 3 characters and a maximum length of 10 characters;
then this test will be appended to the array-ref as 'min_length(3, 10)',
in order to allow you to know exactly why a test failed (this, of course,
does not apply to custom validation methods, which will simply be added
as 'validate'). Note that if a parameter failed validation, it will still
be added to the parsed output.

Suppose the following input parameters were processed with the 'post'
scheme from our synopsis example:

	{
		subject		=> 'su',
		text		=> undef,
		day		=> 13,
		mon		=> 12,
		year		=> 2010,
		section		=> 2,
		thing		=> 3,
		id		=> 300000000,
	}

The resulting hash-ref would be:

	{
		'_rejects' => {
			'text' => [ 'required(1)', 'min_length(10)', 'validate' ],
			'subject' => [ 'length_between(3, 40)' ],
			'id' => [ 'exact_length(10)', 'value_between(1000000000, 2000000000)' ]
		},

		'date' => '2010-12-13',
		'subject' => 'su',
		'section' => 'receips',
		'text' => undef,
		'day' => 13,
		'mon' => 12,
		'id' => 300000000,
		'year' => 2010
	}

Notice the 'thing' key from the input parameters is missing from the
resulting hash-ref, since it is not referenced by the scheme and C<ignore_missing>
is on. Also, notice the 'date' key which was generated by the 'date' group.
The 'day', 'mon' and 'year' parameters are still returned even though
they are part of the 'date' group.

=head2 HOW THE PARSE METHOD WORKS

As stated earlier, you're C<parse> methods are expected to return a hash-ref
of key-value pairs. Brannigan collection all of these key-value pairs
and merges them into one big hash-ref (along with all the non-parsed
parameters).

Brannigan actually allows you to have your C<parse> methods be two-leveled.
This means that a value in a key-value pair in itself can be a hash-ref.
This allows you to use the same key in different places, and Brannigan
will automatically aggregate all of these places, just like in the first
level. So, for example, suppose you're scheme has a regex rule that matches
parameters like 'tag_en' and 'tag_he'. You're parse method might return
something like C<{ tags => { en => 'an english tag' } }> when it matches the
'tag_en' parameter, and something like C<{ tags => { he => 'a hebrew tag' } }>
when it matches the 'tag_he' parameter. The resulting hash-ref from the
process method will thus include C<{ tags => { en => 'an english tag', he => 'a hebrew tag' } }>.

Take note however that only two-levels are supported, and that I'm so
tired right now that I have no idea what I'm writing.

=head1 METHODS

=head2 new( \%scheme | @schemes )

Creates a new instance of Brannigan, with the provided scheme(s) (see
HOW SCHEMES WORK for more info on schemes).

=cut

sub new {
	my $class = shift;

	my $self = { map { $_->{name} => $_ } @_ };

	return bless $self, $class;
}

=head2 process( $scheme, \%params )

Receives the name of a scheme and a hash-ref of inupt parameters, and
validates and parses these paremeters according to the scheme (see
HOW SCHEMES WORK for detailed information about this process).

Returns a hash-ref of parsed parameters according to the parsing scheme,
possibly containing a list of failed validations for each parameter.

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

	return Brannigan::Tree->new(@trees, $self->{$scheme});
}

=head1 CAVEATS

This is an early, "quick" version of Brannigan, so pretty much no
checks are made on created schemes, so if you incorrectly define your
schemes, Brannigan will not croak and processing will probably fail. Also, there
is no support yet for recursive inheritance or any crazy inheritance
situation. While deep inheritance is supported, it hasn't been tested yet.

In the next release, the ability to define custom validation methods to
be available across schemes (even schemes that do not have any inheritance
connections) will be added. Some code for this feature has already been
written, but isn't functional yet.

=head1 SEE ALSO

L<Brannigan::Validations>, L<Brannigan::Tree>, L<Oogly>.

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
