#!/usr/bin/perl

#--------------------------------------------

use strict;
use warnings;
use Text::Template;
use File::Basename;
use URI;
use Sub::Delete;

#--------------------------------------------

sub backupApp {

	my $dir = shift;
	my $domain = shift;
	my $script = "$dir/$domain/private";
	my $action = &promptUser('Please choose to backup :', 'database and site', 'database', 'files', 'return', 'quit');

	if($action eq 'database and site') {
		printAction($action);
		system "$script/backup/backup.pl";
	}
	elsif($action eq 'database') {
		printAction($action);
		system "$script/db.backup/backup.pl";
	}
	elsif($action eq 'files') {
		printAction($action);
		system "$script/files.backup/backup.pl";
	}
	elsif($action eq 'return') {
		actionDomain($dir, $domain);
	}
	elsif($action eq 'quit') {
		quit();
	}
	
	backupApp($dir, $domain);
}

sub management {

	my $dir = shift;
	my $domain = shift;

	my $action = &promptUser('Please choose an action :', 'info', 'drop', 'delete', 'return', 'quit');

	if($action eq 'info') {
		printAction($action);
		infoSite($dir, $domain);
	}
	elsif($action eq 'drop') {
		printAction($action);
		dropDb($dir, $domain);
	}
	elsif($action eq 'delete') {
		printAction($action);
		deleteSite($dir, $domain);
	}
	elsif($action eq 'return') {
		actionDomain($dir, $domain);
	}
	elsif($action eq 'quit') {
		quit();
	}
	
	management($dir, $domain);
}

sub drush {

	my $dir = shift;
	my $domain = shift;
	
	my $modulesPath = 'sites/all/modules';
	my $themesPath = 'sites/all/themes';
	
        no warnings('once');
        my $app = $main::config->{'app'};
	my $user = $main::username;
	
	my $defaultName = $domain;

    if($defaultName =~ m/^(.+)\.(.+)$/) {
    	$defaultName = $1;
    }

	my $action = &promptUser('Please choose an action :', 'drush', 'download modules', 'download themes', 'update modules', 'return', 'quit');
	
	if($action eq 'drush') {
		$app = &promptUser("Enter application name", 'app') unless($app);
		system "cd $dir/$domain/httpdocs/$app && drush";
		my $command = &promptUser("Enter command to run", "status");
		system "cd $dir/$domain/httpdocs/$app && drush $command";
	}
	elsif($action eq 'download modules') {
		$app = &promptUser("Enter application name", 'app') unless($app);
        $user = &promptUser("Enter user for $domain", $defaultName) unless($user);
		$modulesPath = &promptUser("Enter path to modules", "sites/all/modules") unless($modulesPath);
		
		my $modules = &promptUser("Enter modules to download separated by space", "views cck admin_menu");
		
		system "cd $dir/$domain/httpdocs/$app/$modulesPath && drush dl $modules";

		foreach (split(/ /, $modules)) {
		
			my @mm = split(/-/, $_);
			my $mm = shift(@mm);
		
			#move it to drupal folder
			if(-d "$dir/$domain/httpdocs/$app/$modulesPath/drupal") {
			    system "cd $dir/$domain/httpdocs/$app/$modulesPath && chown -R $user:www-data $mm && mv -f $mm drupal";
            }
            else {
            	system "cd $dir/$domain/httpdocs/$app/$modulesPath && chown -R $user:www-data $mm";
            }
		}
	}
	elsif($action eq 'download themes') {
		$app = &promptUser("Enter application name", 'app') unless($app);
        $user = &promptUser("Enter user for $domain", $defaultName) unless($user);
		$themesPath = &promptUser("Enter path to themes", "sites/all/themes") unless($themesPath);
		
		my $themes = &promptUser("Enter themes to download separated by space", "zen blueprint blueprint-7.x-2.x-dev");
		
		system "cd $dir/$domain/httpdocs/$app/$themesPath && drush dl $themes";

		foreach (split(/ /, $themes)) {
		
			my @mm = split(/-/, $_);
			my $mm = shift(@mm);
		
			#move it to drupal folder
			if(-d "$dir/$domain/httpdocs/$app/$themesPath/drupal") {
			    system "cd $dir/$domain/httpdocs/$app/$themesPath && chown -R $user:www-data $mm && mv -f $mm drupal";
            }
            else {
            	system "cd $dir/$domain/httpdocs/$app/$themesPath && chown -R $user:www-data $mm";
            }
		}
	}
	elsif($action eq 'update modules') {
		$app = &promptUser("Enter application name", 'app') unless($app);
		$user = &promptUser("Enter user for $domain", $defaultName) unless($user);
		$modulesPath = &promptUser("Enter path to modules", "sites/all/modules") unless($modulesPath);
		$themesPath = &promptUser("Enter path to themes", "sites/all/themes") unless($themesPath);

		system "cd $dir/$domain/httpdocs/$app && drush up";

		system "chown -R $user:www-data $dir/$domain/httpdocs/$app/$modulesPath" if(-d "$dir/$domain/httpdocs/$app/$modulesPath");
		system "chown -R $user:www-data $dir/$domain/httpdocs/$app/$themesPath" if(-d "$dir/$domain/httpdocs/$app/$themesPath");

		#ensure correct ownership for backup
        system "cd $dir/$domain/httpdocs/$app && chown -R $user:www-data backup";
	}
	elsif($action eq 'return') {
		actionDomain($dir, $domain);
	}
	elsif($action eq 'quit') {
		quit();
	}
	
	drush($dir, $domain);
}

sub actionVHost {
	
	my $action = &promptUserWithLabel('Vhost menu', 'Please choose an action :', 'create vhost', 'enable vhost', 'disable vhost', 'delete vhost/host', 'set production mode', 'set development mode', 'reload nginx configuration', 'generate htpasswd', 'return', 'quit');
	
	my $available = "/etc/nginx/sites-available";
	my $enabled = "/etc/nginx/sites-enabled";
	
	if($action eq 'create vhost') {
		printLabel('create vhost');
		my $vhost = listVHost($available, $enabled, "list");
		createVHost($vhost, $available, $enabled);
	}
	elsif($action eq 'enable vhost') {
		printAction($action);
		my $vhost = listVHost($available, $enabled, 'enable');
		enableVHost($vhost, $available, $enabled);
	}
	elsif($action eq 'disable vhost') {
		printAction($action);
		my $vhost = listVHost($available, $enabled, 'disable');
		disableVHost($vhost, $available, $enabled);
	}
	elsif($action eq 'delete vhost/host') {
		printAction($action);
		my $vhost = listVHost($available, $enabled, 'delete');
		deleteVHost($vhost, $available, $enabled);
	}
	elsif($action eq 'set production mode') {
		printAction($action);
		my $vhost = listVHost($available, $enabled, 'select');
		enableProVHost($vhost, $available, $enabled);
	}
	elsif($action eq 'set development mode') {
		printAction($action);
		my $vhost = listVHost($available, $enabled, 'select');
		enableDevVHost($vhost, $available, $enabled);
	}
	elsif($action eq 'reload nginx configuration') {
		printAction($action);
		reloadNginx();
	}
	elsif($action eq 'generate htpasswd') {
		printAction($action);
		
		my $username = &promptUser('username', $main::username);
		my $password = &promptUser('password', '');
		my $filename = &promptUser('filename (will be saved under /etc/nginx/password/)', 'htpasswd');
		
		if($username && $password && $filename) {
			htpasswd($username, $password, $filename);
			printNotice('Saved', "/etc/nginx/password/$filename");
		}
	}
	elsif($action eq 'return') {
		mainAction();
	}
	elsif($action eq 'quit') {
		quit();
	}
	
	actionVHost();
}

sub actionDomain {
	
	my $dir = shift;
	my $domain = shift;
	
	my $action = &promptUserWithLabel('host menu', 'Please choose an action :', 'site initialization', 'fork or install application', 'create cron file for drupal cron.php', 'rollback application', 'backup application', 'push', 'pull', 'site management', 'drush', 'return', 'quit');
	
	if($action eq 'site initialization') {
		printAction($action);
		initApp($dir, $domain);
	}
	elsif($action eq 'fork or install application') {
		printAction($action);
		forkApp($dir, $domain, "");
	}
	elsif($action eq 'create cron file for drupal cron.php') {
		printAction($action);
		drupalCron($dir, $domain);
	}
	elsif($action eq 'rollback application') {
		printAction($action);
		rollbackApp($dir, $domain);
	}
	elsif($action eq 'backup application') {
		backupApp($dir, $domain);
	}
	elsif($action eq 'push') {
		printAction($action);
		pushApp($dir, $domain);
	}
	elsif($action eq 'pull') {
		printAction($action);
		pullApp($dir, $domain);
	}
	elsif($action eq 'site management') {
		management($dir, $domain);
	}
	elsif($action eq 'drush') {
		drush($dir, $domain);
	}
	elsif($action eq 'return') {
		mainAction();
	}
	elsif($action eq 'quit') {
		quit();
	}
	
	actionDomain($dir, $domain);
}

sub actionServer {
	
	my $action = &promptUserWithLabel('Server menu', 'Please choose an action :', 'disk usage', 'check stack', 'wizard', 'return', 'quit');
	
	if($action eq 'disk usage') {
		diskUsage();
	}
	elsif($action eq 'check stack') {
		checkStack();
	}
	elsif($action eq 'wizard') {
		createConfiguration();
	}
	elsif($action eq 'return') {
		mainAction();
	}
	elsif($action eq 'quit') {
		quit();
	}
	
	actionServer();
}

sub mainAction {
	
	my $action =  &promptUserWithLabel('Main menu', 'Please choose an action :', 'vhosts configuration', 'domains', 'server', 'quit');

	if($action eq 'vhosts configuration') {
		actionVHost();
	}
	elsif($action eq 'domains') {
		my $dir = "/var/www/vhosts";
		my $domain = listDomain($dir);

		if($domain eq '') {
			printComment('No host defined!');
			mainAction();
		}
		else {
			printNotice('Selected', "$dir/$domain");
			tweetInit($domain, 'Working on {$tweet}') if(functionExists('tweetInit'));
			actionDomain($dir, $domain);
		}
	}
	elsif($action eq 'server') {
		actionServer();
	}
	elsif($action eq 'quit') {
		quit();
	}
	
	mainAction();
}

sub checkUser {
	my $login = (getpwuid($>));
	die "\nYou cannot run this Perl script as user \"$login\", you must be root!\n\n" unless ($login eq 'root');
}

sub quit {
	printAction('bye bye');
	print "\n";
	exit;
}

#--------------------------------------------

sub init {

	checkUser();

	my $scriptPath = dirname(__FILE__);
	
	package main; {
		our $username = getlogin();
		our $scriptPath = $scriptPath;
	}

	require("$scriptPath/s66c/screen.pm");
	require("$scriptPath/s66c/util.pm");
	require("$scriptPath/s66c/server.pm");

	if(not -f "$scriptPath/s66c/config.cfg") {
		createConfiguration();
	}

	readConfigurationFile("$scriptPath/s66c/config.cfg");
	
	require("$scriptPath/s66c/db.pm");
	require("$scriptPath/s66c/vhost.pm");
	require("$scriptPath/s66c/domain.pm");
	require("$scriptPath/s66c/disk.pm");

	require("$scriptPath/s66c/welcome.pm") if (-f "$scriptPath/s66c/welcome.pm");
	require("$scriptPath/s66c/tweet.pm") if (-f "$scriptPath/s66c/tweet.pm");

	welcome() if(functionExists('welcome'));
	diskUsage();
	setTweet() if(functionExists('setTweet'));
	mainAction();
}

#--------------------------------------------

init();
