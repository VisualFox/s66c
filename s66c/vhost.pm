use strict;
use warnings;

sub createVHost {

	my $vhost = shift;
	my $available = shift;
	my $enabled = shift;
	
	while(-f "$available/$vhost") {
		print "\n$vhost is already in use choose another one\n";
		$vhost = listVHost($available, $enabled, "list");
	}
	
	if($vhost) {
	
		my $scriptPath = $main::scriptPath;
	
		my @vhosts = split(/\./, $vhost);
		
		if(@vhosts<3) {
			my $template = Text::Template->new(SOURCE => "$scriptPath/s66c/tmpl/drupal.vhost.tmpl") or die "Couldn't construct template: $Text::Template::ERROR";
        	my $vhostr = $vhost;
        	$vhostr =~ s/\./\\./g;
        	my %vars = (domain => $vhost, domain_regex => $vhostr);
       		my $result = $template->fill_in(HASH => \%vars);

        	if (defined $result) {
				open (FILE, ">$available/$vhost");
				print FILE $result;
				close (FILE);
			}
			
			#run wizard...
			enableVHost($vhost, $available, $enabled);
			
			if(&promptUser("Init $vhost? (yes|no)", 'yes') eq 'yes') {
				initApp("/var/www/vhosts", $vhost);
			}
		}
		else {
			my $subdomain = shift(@vhosts);
			my $domain = join('.', @vhosts);
			
			my $template = Text::Template->new(SOURCE => "$scriptPath/s66c/tmpl/drupal.sub.vhost.tmpl") or die "Couldn't construct template: $Text::Template::ERROR";
        	my %vars = (domain => $domain, subdomain => $subdomain);
       		my $result = $template->fill_in(HASH => \%vars);

        	if (defined $result) {
				open (FILE, ">$available/$vhost");
				print FILE $result;
				close (FILE);
			}
			
			#run wizard...
			enableVHost($vhost, $available, $enabled);
			
			if(&promptUser("Init $vhost? (yes|no)", 'yes') eq 'yes') {
				initApp("/var/www/vhosts", "$domain/subdomains/$subdomain");
			}
		}
	}
}

sub enableVHost {
	my $vhost = shift;
	my $available = shift;
	my $enabled = shift;

	if($vhost) {
		if(&promptUser("Enable $vhost? (yes|no)", 'yes') eq 'yes') {
			
			if(-f "$enabled/$vhost") {
				print "\n";
				return;
			}
			
			if(-f "$available/$vhost") {
				system "ln -s $available/$vhost $enabled/$vhost";
				
				if(&promptUser('Reload nginx? (yes|no)', 'yes') eq 'yes') {
					reloadNginx();
				}
				else {
					print "\n";
				}
			}
		}
	}
	else {
		print "\nNo vhost to enable\n";
	}
}

sub disableVHost {
	my $vhost = shift;
	my $available = shift;
	my $enabled = shift;

	if($vhost) {
		if(&promptUser("Disable $vhost? (yes|no)", 'yes') eq 'yes') {
			
			if(-f "$enabled/$vhost") {
				system "rm -f $enabled/$vhost";
				
				if(&promptUser('Reload nginx? (yes|no)', 'yes') eq 'yes') {
					reloadNginx();
				}
				else {
					print "\n";
				}
			}
		}
	}
	else {
		print "\nNo vhost to disable\n";
	}
}

sub enableProVHost {
	my $vhost = shift;
	my $available = shift;
	my $enabled = shift;

	if($vhost) {
		if(&promptUser("Enable production mode for $vhost? (yes|no)", 'yes') eq 'yes') {
			

			if(-f "$available/$vhost") {
				
				#/etc/nginx/drupal
				findAndReplace($available, $vhost, "drupal_dev;", "drupal;");
				reloadNginx();
			}
		}
	}
	else {
		print "\nNo vhost selected\n";
	}
}

sub enableDevVHost {
	my $vhost = shift;
	my $available = shift;
	my $enabled = shift;

	if($vhost) {
		if(&promptUser("Enable development mode for $vhost? (yes|no)", 'yes') eq 'yes') {
			
			if(-f "$available/$vhost") {
				
				#/etc/nginx/drupal_dev
				findAndReplace($available, $vhost, "drupal;", "drupal_dev;");
				reloadNginx();
			}
		}
	}
	else {
		print "\nNo vhost selected\n";
	}
}

sub deleteVHost {
	my $vhost = shift;
	my $available = shift;
	my $enabled = shift;

	if($vhost) {
		if(&promptUser("Delete $vhost? (yes|no)", 'no') eq 'yes') {
			
			if(-f "$enabled/$vhost") {
				system "rm -f $enabled/$vhost";
			}
			
			if(-f "$available/$vhost") {
				system "rm -f $available/$vhost";
			
				if(&promptUser("Reload nginx? (yes|no)", 'yes') eq 'yes') {
					reloadNginx();
				}
				else {
					print "\n";
				}
				
				my $path = "/var/www/vhosts";
				my $dir = $vhost;
				my @vhosts = split(/\./, $vhost);
				
				if(@vhosts>2) {
					my $subdomain = shift(@vhosts);
					my $domain = join('.', @vhosts);
					
					$dir = "$domain/subdomains/$subdomain";
				}	
				
				deleteSite($path, $dir);
				
				#delete cron
				my $cron = getSitedomain($dir);
				$cron =~ s/\//./g;
				
				if(-f "/etc/cron.d/$cron") {
					system "rm -f /etc/cron.d/$cron";
				}
			}
		}
	}
	else {
		print "\nNo vhost to delete\n";
	}
}

sub reloadNginx {
	system "nginx -t && nginx -s reload";
}

1;