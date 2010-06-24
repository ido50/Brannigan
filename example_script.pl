package MyApp::Controller::Blog;

use strict;
use warnings;
use Brannigan;

sub post : Local {
	my ($self, $c) = @_;

	# get input hash-ref from request (Catalyst example)
	my $params = $c->request->params;

	# validate and parse the input
	my $parsed_input = $b->process($params);

	# were there any rejects?
	if (scalar @{$parsed_input->{rejects}}) {
		# handle the problems
		die $c->error("The following errors were encountered: ", join(", ", @{$parsed_input->{rejects}}));
	} else {
		# create the post
		my $post = $c->model('DB::Posts')->create($parsed_input);
	}

	$c->response->redirect('/view_post', $post->id);
}

my $b = Brannigan->new(
	{
		name => 'new_post',
		ignore_missing => 1,
		params => {
			post_subject => {
				required => 1,
				type => 'Str',
				len_range => [3, 40],
			},
			post_text => {
				required => 1,
				type => 'Str',
				min_len => 3,
			},
			post_day => {
				required => 0,
				type => 'Int',
				val_range => [1, 31],
			},
			post_mon => {
				required => 0,
				type => 'Int',
				val_range => [1, 12],
			},
			post_year => {
				required => 0,
				type => 'Int',
				val_range => [1900, 2900],
			},
			post_section => {
				required => 1,
				type => 'Int',
				val_range => [1, 3],
				parse => sub {
					my $val = shift;
					
					my $ret = $val == 1 ? 'reviews' :
						  $val == 2 ? 'receips' :
						  'general';
						  
					return { section => $ret };
				},
			}
		},
		groups => {
			post_date => {
				params => [qw/post_year post_mon post_day/],
				required => 0,
				parse => sub {
					my ($year, $mon, $day) = @_;
					return { date => $year.'-'.$mon.'-'.$day };
				}
			},
		},
	}, {
		name => 'edit_post',
		inherits_from => 'new_post',
		params => {
			post_subject => {
				required => 0,
			},
		},
	});
