use strict;
use warnings;
use Switch;

sub forkApp {

	my $dir = shift;
	my $domain = shift;
	my $filter = shift;

	if(not -d "$dir/$domain/httpdocs") {
		initApp($dir, $domain);
	}

	my $target = "$dir/$domain/httpdocs";
	my $source = "$dir/$domain/httpdocs";
	my $filesparent;
	my $files;
	my $user = $main::username;
	my $app = $main::config->{'app'};
	my $subname;

	my $defaultName = $domain;

    if($defaultName =~ m/^(.+)\.(.+)$/) {
    	$defaultName = $1;
    }

	$user = &promptUser("Enter user for $domain", $defaultName) unless ($user);
	$app = &promptUser("Enter application name", "app") unless ($app);

	if(!$subname) {
		#$subname = &promptUser("Enter subname", "app");
		$subname = $app;
	}

	#create some nice name...
	(my $Second,my $Minute, my $Hour, my $Day, my $Month, my $Year, my $WeekDay, my $DayOfYear, my $IsDST) = localtime(time) ;
	my @months = qw( jan feb mar apr may jun jul aug sep oct nov dec );
	my @days = qw( mon tue wed thu fri sat sun );

	my $dt = sprintf($subname."_%02d_%s_%4d_%02d.%02d.%02d", $Day+1, $months[$Month], $Year+1900, $Hour, $Minute, $Second);

	#--------------------------------------------
	
	my $drupal = 1;
	my $new_install = 1;
	my $action = 0;
	
	if(not $filter) {
		
		my @appList = qw( Drupal Acquia-1.x-6.x Pressflow Wordpress-stable Atrium );
		my $listString = "\n";
	
		for(my $i=0;$i<@appList;++$i) {
	  		$listString .= "($i) $appList[$i]\n";
		}
	
		$action = &promptUser("Application to install  : $listString");
		
		while (not ($action =~ /^[0-9]+$/) || $action<0 || $action>=@appList) {
			$action = &promptUser("Application to install  : $listString");
		}
	}

	switch($action) {
		case 0
		{
			$filter = &promptUser("Drupal version (4,5,6,7,8,9)", "7") unless ($filter);

			#use mirror...
			if(not -d "/var/git/mirror") {
				system "mkdir -p /var/git/mirror";
			}
			
			#init mirror...
			if(not -d "/var/git/mirror/drupal.reference") {
				system "git clone --mirror git://git.drupal.org/project/drupal.git /var/git/mirror/drupal.reference";
			}

			if(!$filter) {
				system "cd $target && git clone --reference /var/git/mirror/drupal.reference git://git.drupal.org/project/drupal.git $dt";
				system "cd $target/$dt && git tag"
			}
			else {
				system "cd $target && git clone --reference /var/git/mirror/drupal.reference --branch $filter.x git://git.drupal.org/project/drupal.git $dt";
				system "cd $target/$dt && git tag -l $filter.*";
			}
			
			my $version = &promptUser("Enter Drupal version", "7.0");
			
			system "cd $target/$dt && git checkout $version";
		}
		case 1
		{
			#Acquia 1.x-6.x
			system "cd $target && bzr branch lp:~acquia/drupal/1.x-6.x $dt";
		}
		case 2
		{
			#Pressflow
			system "cd $target && bzr branch lp:pressflow $dt";
		}
		case 3
		{
			#wordpress stable
			system "cd $target && bzr branch lp:~robotparade/wordpress/stable $dt";
			$drupal = 0;
		}
		case 4
		{
			#Atrium
			system "cd $target && bzr branch lp:openatrium $dt";
		}
	}

	if($drupal) {

		$source = &promptUser("Enter source path", $target) unless ($source);
		$filesparent = &promptUser("Enter drupal files parent path", "sites/default") unless ($filesparent);

		if(!$files) {
			my $f = &promptUser("Enter drupal files name", "files");
			$files = "$filesparent/$f";
		}

		#move some old file...
		if(-d "$source/$app") {
		    system "cp $source/$app/.htaccess $target/$dt" if(-f "$source/$app/.htaccess");
		    system "cp $source/$app/sites/default/settings.php $target/$dt/sites/default" if(-f "$source/$app/sites/default/settings.php");
		    system "cp -r $source/$app/$files $target/$dt/$filesparent" if(-d "$source/$app/$files");
		    
		    #libraries
		    system "cp -r $source/$app/sites/all/libraries $target/$dt/sites/all" if(-d "$source/$app/sites/all/libraries");
		    
		    #boost module
		    system "cp -r $source/$app/cache $target/$dt" if(-d "$source/$app/cache");
		    
		    system "cp $source/$app/logo.png $target/$dt/logo.png" if(-f "$source/$app/logo.png");
            system "cp $source/$app/misc/logo.png $target/$dt/misc/logo.png" if(-f "$source/$app/misc/logo.png");
		    system "cp $source/$app/misc/druplicon.png $target/$dt/misc/druplicon.png" if(-f "$source/$app/misc/druplicon.png");
            system "cp $source/$app/favicon.ico $target/$dt/favicon.ico" if(-f "$source/$app/favicon.ico");
            system "cp $source/$app/misc/favicon.ico $target/$dt/misc/favicon.ico" if(-f "$source/$app/misc/favicon.ico");
		    system "cp $source/$app/robots.txt $target/$dt/robots.txt" if(-f "$source/$app/robots.txt");
			
			$new_install = 0;
		}
		else {
			#setup for first install...
			system "cd $target/$dt/sites/default && cp default.settings.php settings.php" unless(-f "$target/$dt/sites/default/settings.php");
		}
		
		#drupal may complain when it cannot find $files
		system "mkdir $target/$dt/$files" unless(-d "$target/$dt/$files");
		
		if(&promptUser("Clean up drupal installation (yes|no)", 'yes') eq 'yes') {
			system "cd $target/$dt && drush cu";
		}
		
		if(&promptUser("Run cron.php via cron (yes|no)", 'yes') eq 'yes') {
		
			drupalCron($dir, $domain);
		}
	}
	
	#--------------------------------------------
	
	#git
	if (-f "$dir/$domain/private/git.pl") {
		do "$dir/$domain/private/git.pl";
		
		if(functionExists("gitClone")) {
			gitClone("$target/$dt");
			
			printNotice('apply git', "$dir/$domain/private/git.pl");
		}
		
		unsetGit();
	}
	
	#mercurial
	if (-f "$dir/$domain/private/hg.pl") {
		do "$dir/$domain/private/hg.pl";
		
		if(functionExists("hgClone")) {
			hgClone("$target/$dt");
			
			printNotice('apply mercurial', "$dir/$domain/private/hg.pl");
		}
		
		unsetHg();
	}
	
	#extra
	if (-f "$dir/$domain/private/extra.pl") {
		do "$dir/$domain/private/extra.pl";
		
		if(functionExists("extraClone")) {
			extraClone("$target/$dt");
			
			printNotice('apply extra', "$dir/$domain/private/extra.pl");
		}
		
		unsetExtra();
	}
	
	#--------------------------------------------
	
	#roll the new app
	if($drupal) {
		
		$filesparent = &promptUser("Enter drupal files parent path", "sites/default") unless ($filesparent);

		if(!$files) {
			my $f = &promptUser("Enter drupal files name", "files");
			$files = "$filesparent/$f";
		}

		system "cd $target && chown -R $user:www-data $dt";
		
		#set correct ownership for files
		if(-d "$source/$dt/$files") {
			system "cd $target/$dt && chown -R www-data:www-data $files";
		}
		
		#cache boost module
		if(-d "$source/$dt/cache") {
			system "cd $target/$dt && chown -R www-data:www-data cache";
		}
		
		if($new_install) {
			system "cd $target/$dt/sites/default && chown www-data:www-data settings.php";
		}
		
		system "cd $target && ln -s $dt app_tmp && chown -h $user:www-data app_tmp && mv -Tf app_tmp $app";
	}
	else {
		system "cd $target && chown -R $user:www-data $dt && ln -s $dt app_tmp && chown -h $user:www-data app_tmp && mv -Tf app_tmp $app";
	}
	
	#--------------------------------------------
	
	printNotice('Created', "$target/$dt");
}

1;