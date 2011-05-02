use strict;
use warnings;
use Redis;

sub setTweet {

	my $dir = "/etc/octobot/twitter";
	my @list;
	my $file;
	
	$main::tweet = '';
	
	if(-d $dir) {
		opendir(DIR, $dir);
	
		foreach $file (readdir(DIR)) {
			next unless (-f "$dir/$file");
			next unless ($file =~ m/\.properties/);
			push(@list, substr($file, 0, -11));
		}
		
		closedir(DIR);
		
		if(@list==0) {
			return;
		}
		
		push(@list, 'none');
		
		$main::tweet = &promptUserQuestions('Twitter', 'choose an account :', @list);
		
		$main::tweet = '' if($main::tweet eq 'none');
	}
}

sub parseURI {

	my $domain = shift;
	my $uri = URI->new(getSiteURL($domain));
	
	my $host = fileparse($uri->host(), qr/\.[^.]*/);
	my $path = fileparse($uri->path(), qr/\.[^.]*/);
	my $full = ($path) ? $path.'.'.$uri->host() : $uri->host();
	
	my $tweet = '';
	
	if($tweet eq '') {
		my $count = 0;
		my $gcount = 0;
		
		for (my $key = 0; $key < length($full); $key++) {
	   		my $c1 = substr ($full, $key, 1);
	   		my $c2 = substr ($full, $key+1, 1);
	   		
	   		if($gcount==2) {
	   			$tweet .= $c1;
	   		}
	   		elsif($c2 eq '') {
	   			$tweet .= $c1;
	   		}
	   		elsif($c1 eq '.') {
				$tweet .= $c1;
				$count = -1;
				$gcount++;
			}
			elsif($c2 eq '.') {
				$tweet .= $c1;
			}
			elsif($count==0) {
				$tweet .= $c1;
			}
			else {
				$tweet .= '_';
			}
			
			$count++;
		}
	}
	
		
	my $user = $host; #some user name may need some adjustement
	
	return (host => $host, path => $path, full => $full, user => $user, tweet => $tweet);
}

sub tweetInit { #domain, #msg

	if($main::tweet eq '') {
		return;
	}

	my $domain = shift;
	my $msg = shift;
	
	my %d = parseURI($domain);
	
	my $host = $d{'host'};
	
	my $tweet = $d{'tweet'};
	my $template = Text::Template->new(TYPE => 'STRING', SOURCE => $msg );
	tweet($template->fill_in(HASH => { tweet => $tweet } )); # Replaces '{$tweet}' in template...
}

sub tweet {

	if($main::tweet eq '') {
		return;
	}

	my $msg = shift;
	my $id = $main::tweet;

	my $redis = Redis->new;
    $redis->publish('twitter', '{"task": "me.l1k3.octobot.twitter.OctoTwitter", "message": "'.$msg.'", "id": "'.$id.'"}');
}

package main; {
	our $tweet = '';
}

1;