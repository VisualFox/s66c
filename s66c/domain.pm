use strict;
use warnings;

my $scriptPath = $main::scriptPath;

require("$scriptPath/s66c/domain/init.pm");
require("$scriptPath/s66c/domain/fork.pm");

sub deleteSite {

	my $path = shift;
	my $dir = shift;
	
	#delete git
	if (-f "$path/$dir/private/git.pl") {
		if(&promptUser("Delete git? (yes|no)", 'no') eq 'yes') {
			system "rm -rf /var/git/$dir/httpdocs" if(confirm());
		}
	}
		
	#delete hg
	if (-f "$path/$dir/private/hg.pl") {
		if(&promptUser("Delete mercurial? (yes|no)", 'no') eq 'yes') {
			system "rm -rf /var/hg/$dir/httpdocs" if(confirm());
		}
	}
	
	#delete db
	if (-f "$path/$dir/private/db.pl") {
		if(&promptUser('Delete db? (yes|no)', 'no') eq 'yes') {
			if(confirm()) {
			
				do "$path/$dir/private/db.pl";
			
				dbDelete() if(functionExists("dbDelete"));
				unsetDb();
				
				#delete cron
				my $cron = getSitedomain($dir);
				$cron =~ s/\//_/g;
				$cron =~ s/\./_/g;
			
				if(-f "/etc/cron.d/$cron") {
					system "rm -f /etc/cron.d/$cron";
				}
			}
		}
	}
	
	if (-d "$path/$dir/httpdocs") {	
		if(&promptUser("Delete httpdocs? (yes|no)", 'no') eq 'yes') {
			system "rm -rf $path/$dir/httpdocs" if(confirm());
			
			#delete cron
			my $cron = "drupal_".getSitedomain($dir);
			$cron =~ s/\//_/g;
			$cron =~ s/\./_/g;
			
			if(-f "/etc/cron.d/$cron") {
				system "rm -f /etc/cron.d/$cron";
			}
		}
	}
	
	if (-d "$path/$dir/private") {
		if(&promptUser("Delete private? (yes|no)", 'no') eq 'yes') {
			system "rm -rf $path/$dir/private" if(confirm());
		}
	}
	
	#final clean up
	if(-d "$path/$dir") {
		opendir(DIR, "$path/$dir");
	
		my $file;
		my $count = 0;
	
		foreach $file (readdir(DIR)) {
			$count++;
		}
		
		closedir(DIR);
		
		if($count==2) {
			system "rm -rf $path/$dir";
		}
	}
}

sub pushApp {

	my $dir = shift;
	my $domain = shift;
	my $app = $main::config->{'app'};

	$app = &promptUser("Enter application name",  'app') unless($app);

	my $script = "$dir/$domain/private";
	my $target = "$dir/$domain/httpdocs";

	#git
	if (-f "$script/git.pl") {
		do "$script/git.pl";
		
		if(functionExists("gitPush")) {
			gitPush("$target/$app");
		}
		
		unsetGit();
	}
	
	#mercurial
	if (-f "$script/hg.pl") {
		do "$script/hg.pl";
		
		if(functionExists("hgPush")) {
			hgPush("$target/$app");
		}
		
		unsetHg();
	}
	
	#extra
	if (-f "$script/extra.pl") {
		do "$script/extra.pl";
		
		if(functionExists("extraPush")) {
			extraPush("$target/$app");
		}
		
		unsetExtra();
	}
	
}

sub pullApp {

	my $dir = shift;
	my $domain = shift;
	my $app = $main::config->{'app'};
	
	$app = &promptUser("Enter application name",  'app') unless($app);

	my $script = "$dir/$domain/private";
	my $target = "$dir/$domain/httpdocs";

	#git
	if (-f "$script/git.pl") {
		do "$script/git.pl";
		
		if(functionExists("gitPull")) {
			gitPull("$target/$app");
		}
		
		unsetGit();
	}
	
	#mercurial
	if (-f "$script/hg.pl") {
		do "$script/hg.pl";
		
		if(functionExists("hgPull")) {
			hgPull("$target/$app");
		}
		
		unsetHg();
	}
	
	#extra
	if (-f "$script/extra.pl") {
		do "$script/extra.pl";
		
		if(functionExists("extraPull")) {
			extraPull("$target/$app");
		}
		
		unsetExtra();
	}
}

sub infoSite {

	my $dir = shift;
	my $domain = shift;
	
	printNotice('root', "$dir/$domain");
	
	print "\n";
	system "ls -l --color=always $dir/$domain/httpdocs";

	if (-f "$dir/$domain/private/db.pl") {
		do "$dir/$domain/private/db.pl";
		
		dbInfo() if(functionExists("dbInfo"));
		unsetDb();
	}
}

sub rollbackApp {
	
	my $dir = shift;
	my $domain = shift;
	my $target = "$dir/$domain/httpdocs";
	my $subname = $main::config->{'app'}; 

	my $defaultName = $domain;

    if($defaultName =~ m/^(.+)\.(.+)$/) {
    	$defaultName = $1;
    }

	$subname = &promptUser("Enter subname", $main::config->{'app'}) unless($subname);
	
	my @list;

	opendir(DIR, $target);

	foreach my $file (readdir(DIR)) {
		next unless (-d "$target/$file");
		next unless ($file =~ m/^$subname\_/);
		push(@list, $file);
	}
	
	closedir(DIR);
	
	if(@list == 0) {
		printComment('No existing archive to rollback');
		return;
	}
	
	my $dt = &promptUserQuestions('', 'Please choose an archive :', @list);
	
	my $user = $main::username;
	my $app = $main::config->{'app'};

	$user = &promptUser("Enter user for $domain", $defaultName) unless($user);
	$app = &promptUser("Enter application name", $main::config->{'app'}) unless($app);

	#rollback
	system "cd $target && ln -s $dt app_tmp && chown -h $user:www-data app_tmp && mv -Tf app_tmp $app";

	#--------------------------------------------

	printNotice('rolled back', "$target/$dt");
}

sub dropDb {

	my $path = shift;
	my $dir = shift;
	
	#delete db
	if (-f "$path/$dir/private/db.pl") {
		if(&promptUser("Drop db? (yes|no)", 'no') eq 'yes') {
			if(confirm()) {
			
				do "$path/$dir/private/db.pl";
			
				dbDropAll() if(functionExists("dbDropAll"));
				unsetDb();
			}
		}
	}
}

sub drupalCron {
	
	my $dir = shift;
	my $domain = shift;
	
	my $target = "$dir/$domain/httpdocs";
	my $app = $main::config->{'app'};
	my $scriptPath = $main::scriptPath;

	#create cron job...
	my $cron = "drupal_".getSitedomain($domain);
	$cron =~ s/\//_/g;
	$cron =~ s/\./_/g;
	
	if(not -f "/etc/cron.d/$cron") {
	
		my $drush = which('drush');
			
		if($drush) {
		
			$app = &promptUser("Enter application name",  'app') unless ($app);
		
			my $m = int(rand(60));
			$m = ($m < 10)? '0'.$m : $m;
			
			my %vars = (
							'drush', $drush,
							'envShell', which('bash'),
							'envHome', $ENV{HOME},
							'envMail', $ENV{MAIL},
							'envPath', $ENV{PATH},
							'envUser', $ENV{USER},
							'path', "$target/$app", 
							'm', $m
				       );
					       
			my $template = Text::Template->new(SOURCE => "$scriptPath/s66c/tmpl/drupal.cron.tmpl") or die "Couldn't construct template: $Text::Template::ERROR";
	        my $result = $template->fill_in(HASH => \%vars);
	
	        if (defined $result) {
	
				open (FILE, ">/etc/cron.d/$cron");
				print FILE $result;
				close (FILE);
				
				printNotice('Cron created', "/etc/cron.d/$cron");
			}
		}
		else {
			printError('Drush is not installed');
		}
	}
	else {
		printComment("/etc/cron.d/$cron file already exists");
	}
}

#--------------------------------------------

sub unsetDb {
	delete_sub("dbCreate") if(functionExists("dbCreate"));
	delete_sub("dbDelete") if(functionExists("dbDelete"));
	delete_sub("dbDropAll") if(functionExists("dbDropAll"));
	delete_sub("dbRollback") if(functionExists("dbRollback"));
	delete_sub("dbInfo") if(functionExists("dbInfo"));
	
	delete_sub("dbGetHost") if(functionExists("dbGetHost"));
	delete_sub("dbGetDb") if(functionExists("dbGetDb"));
	delete_sub("dbGetUser") if(functionExists("dbGetUser"));
	delete_sub("dbGetPass") if(functionExists("dbGetPass"));
}

sub unsetGit {
	delete_sub("gitClone") if(functionExists("gitClone"));
	delete_sub("gitPush") if(functionExists("gitPush"));
	delete_sub("gitPull") if(functionExists("gitPull"));
}

sub unsetHg {
	delete_sub("hgClone") if(functionExists("hgClone"));
	delete_sub("hgPush") if(functionExists("hgPush"));
	delete_sub("hgPull") if(functionExists("hgPull"));
}

sub unsetExtra {
	delete_sub("extraClone") if(functionExists("extraClone"));
	delete_sub("extraPush") if(functionExists("extraPush"));
	delete_sub("extraPull") if(functionExists("extraPull"));
}

#--------------------------------------------

1;