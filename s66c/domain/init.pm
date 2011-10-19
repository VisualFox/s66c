use strict;
use warnings;
use File::Which;
use String::Random;

sub initApp {

	my $dir = shift;
	my $domain = shift;

	my $confirm = 'yes';

	my $user = $main::username;
	my $scriptPath = $main::scriptPath;
	my $app = $main::config->{'app'};
	
	my $dbuser;
	my $dbpass;
	my $db;
	my $filesparent;
	my $filesname;
	
	my $filter;
	
    my $defaultName = $domain;
	
	if($defaultName =~ m/^(.+)\.(.+)$/) {
    	$defaultName = $1;
	}
	
	my $template;
    my %vars;
    my $result;

	#create some system folder...
	unless(-d "$dir/$domain/httpdocs") {
	
		$user = &promptUser("Enter user for $domain", $defaultName) unless ($user);
		system "mkdir -p $dir/$domain/httpdocs && chown $user:$user $dir/$domain/httpdocs";
		printNotice('httpdocs folder created', "$dir/$domain/httpdocs");
	}
	
	#create the private folder...
	unless(-d "$dir/$domain/private") {
	
		$user = &promptUser("Enter user for $domain", $defaultName) unless ($user);
		system "mkdir -p $dir/$domain/private && chown $user:root $dir/$domain/private";
		printNotice('private folder created', "$dir/$domain/private");
	}
	else {
		printComment('private folder already exists');
	}
	
	#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	
	#Use version control system and install drupal module?
	if(&promptUser("Use version control and install some Drupal modules for $domain? (yes|no)", 'yes') eq 'yes') {
	
		my $gitPath = which('git');
		my $mercurialPath = which('hg');
	
		if($gitPath && &promptUser("Use git for $domain? (yes|no)", 'no') eq 'no') {
			$gitPath = undef;
		}
		
		if($mercurialPath && &promptUser("Use mercurial for $domain? (yes|no)", 'yes') eq 'no') {
			$mercurialPath = undef;
		}
	
		if($gitPath || $mercurialPath) {
		
			my $appPath = "httpdocs/app";
		
			$filter = &promptUser("Drupal version (4,5,6,7,8,9)", "7") unless ($filter);
		
			#ask for modules and themes to install...
			$user = &promptUser("Enter user for $domain", $defaultName) unless ($user);
			
			my $modulesPath = &promptUser("Enter modules path", "sites/all/modules");
			my $themesPath = &promptUser("Enter themes path", "sites/all/themes");
			
			my $modules = &promptUser("Enter modules namespace separated by space", "$defaultName");
			my $develModulesToInstall = "";
			my $modulesToInstall = "";
	
			if(&promptUser("Create devel namespace? (yes|no)", 'yes') eq 'yes') {
				if($modules eq "") {
					$modules = "devel";
				}
				else {
					$modules .= " devel";
				}
				
				if(&promptUser("Use devel module? (yes|no)", 'yes') eq 'yes') {
					if($develModulesToInstall eq "") {
						$develModulesToInstall = "devel-$filter.x";
					}
					else {
						$develModulesToInstall .= " devel-$filter.x";
					}
				}
			}
		
			if(&promptUser("Create drupal namespace? (yes|no)", 'yes') eq 'yes') {
				if($modules eq "") {
					$modules = "drupal";
				}
				else {
					$modules .= " drupal";
				}
				
				if(&promptUser("Use boost module? (yes|no)", 'yes') eq 'yes') {
					if($modulesToInstall eq "") {
						$modulesToInstall = "boost-$filter.x";
					}
					else {
						$modulesToInstall .= " boost-$filter.x";
					}
				}
			}
		
			my $themes = &promptUser("Enter themes namespace separated by space", "$defaultName"); 
			my $themesToInstall = "";
			
			if(&promptUser("Create drupal themes namespace? (yes|no)", 'yes') eq 'yes') {
				if($themes eq "") {
					$themes = "drupal";
				}
				else {
					$themes .= " drupal";
				}
				
	 			if(&promptUser("Use blueprint theme? (yes|no)", 'yes') eq 'yes') {
	 				#for 7 we use https://github.com/urbanlink/drupal_blueprint_7
	 				if($filter==7) {
	 					my $blueprintGit = "https://github.com/urbanlink/drupal_blueprint_7.git";
	 					
	 					if($gitPath) {
	 						system "mkdir -p /var/git/$domain/$appPath/$themesPath/drupal";
	 						system "git clone $blueprintGit /var/git/$domain/$appPath/$themesPath/drupal/blueprint";
	 					}
	 					elsif($mercurialPath) {
	 						system "mkdir -p /var/hg/$domain/$appPath/$themesPath/drupal";
	 						system "git clone $blueprintGit /var/hg/$domain/$appPath/$themesPath/drupal/blueprint";
	 					}
	 				}
	 				else {
						if($themesToInstall eq "") {
							$themesToInstall = "blueprint-$filter.x";
						}
						else {
							$themesToInstall .= " blueprint-$filter.x";
						}
					}
				}
			
				if(&promptUser("Use zen theme? (yes|no)", 'no') eq 'yes') {
					if($themesToInstall eq "") {
						$themesToInstall = "zen-$filter.x";
					}
					else {
						$themesToInstall .= " zen-$filter.x";
					}
				}
			}
	
			#create git.pl
			unless(-f "$dir/$domain/private/git.pl") {
				if($gitPath) {
					
					unless(-d "/var/git") {
		    			system "mkdir /var/git && chown root:root /var/git";
					}
					
					my $clone = "\t".'system "mkdir -p $path/$modulesPath" unless(-d "$path/$modulesPath");'."\n\t".'system "mkdir -p $path/$themesPath" unless(-d "$path/$themesPath");'."\n\n";
					my $push  = "";
					my $pull  = "";
	
					#modules...
					foreach (split(/ /, $modules)) {
		
						unless(-d "/var/git/$domain/$appPath/$modulesPath/$_") {
							
							system "mkdir -p /var/git/$domain/$appPath/$modulesPath/$_";
							system "cd /var/git/$domain/$appPath/$modulesPath/$_ && drush dl $develModulesToInstall" if($develModulesToInstall and $_ eq "devel");
							system "cd /var/git/$domain/$appPath/$modulesPath/$_ && drush dl $modulesToInstall" if($modulesToInstall and $_ eq "drupal");
	
							#commit
							system "cd /var/git/$domain/$appPath/$modulesPath/$_ && chown -R root:root /var/git/$domain/$appPath/$modulesPath/$_ && git init && git add . && git commit -m \"Initial commit\"";
					
						}
						else {
							printComment("/var/git/$domain/$appPath/$modulesPath/$_ already exists");
						}
					
						$clone .= "\t".'system "git clone /var/git/$domain/$appPath/$modulesPath/'.$_.' $path/$modulesPath/'.$_.'";'."\n";
		 				$push  .= "\t".'system "cd $path/$modulesPath/'.$_.' && git add . && git commit -m \"automatic commit\" && git push";'."\n";
		 				$pull  .= "\t".'system "cd $path/$modulesPath/'.$_.' && git pull";'."\n";
		 			}
		 			
		 			#themes...
		 			foreach (split(/ /, $themes)) {
		
						unless(-d "/var/git/$domain/$appPath/$themesPath/$_") {
							
							system "mkdir -p /var/git/$domain/$appPath/$themesPath/$_";
							system "cd /var/git/$domain/$appPath/$themesPath/$_ && drush dl $themesToInstall" if($themesToInstall and $_ eq "drupal");

							#commit
							system "cd /var/git/$domain/$appPath/$themesPath/$_ && chown -R root:root /var/git/$domain/$appPath/$modulesPath/$_ && git init && git add . && git commit -m \"Initial commit\"";
					
						}
						else {
							printComment("/var/git/$domain/$appPath/$themesPath/$_ already exists");
						}
						
						$clone .= "\t".'system "git clone /var/git/$domain/$appPath/$themesPath/'.$_.' $path/$themesPath/'.$_.'";'."\n";
		 				$push  .= "\t".'system "cd $path/$themesPath/'.$_.' && git add . && git commit -m \"automatic commit\" && git push";'."\n";
		 				$pull  .= "\t".'system "cd $path/$themesPath/'.$_.' && git pull";'."\n";
		 			}
					
					$template = Text::Template->new(SOURCE => "$scriptPath/s66c/tmpl/git.tmpl") or die "Couldn't construct template: $Text::Template::ERROR";
		        	%vars = (domain => $domain, appPath => $appPath, modulesPath => $modulesPath, themesPath => $themesPath, clone => $clone, push => $push, pull => $pull);
		       		$result = $template->fill_in(HASH => \%vars);
		
		        	if (defined $result) {
						open (FILE, ">$dir/$domain/private/git.pl");
						print FILE $result;
						close (FILE);
						system "chown $user:$user $dir/$domain/private/git.pl";
						
						printNotice('script created', "$dir/$domain/private/git.pl");
					}
				}
			}
			else {
				printComment('git.pl already exists');
			}
		
			#create hg.pl (mercurial)
			unless(-f "$dir/$domain/private/hg.pl") {
				if($mercurialPath) {
					
					unless(-d "/var/hg") {
		    			system "mkdir /var/hg && chown root:root /var/hg";
		    		}
		
					my $clone = "\t".'system "mkdir -p $path/$modulesPath" unless(-d "$path/$modulesPath");'."\n\t".'system "mkdir -p $path/$themesPath" unless(-d "$path/$themesPath");'."\n\n";
					my $push  = "";
					my $pull  = "";
		
					#modules...
					foreach (split(/ /, $modules)) {
		
						unless(-d "/var/hg/$domain/$appPath/$modulesPath/$_") {
							
							system "mkdir -p /var/hg/$domain/$appPath/$modulesPath/$_";
							
							system "cd /var/hg/$domain/$appPath/$modulesPath/$_ && drush dl $develModulesToInstall" if($develModulesToInstall and $_ eq "devel");
							system "cd /var/hg/$domain/$appPath/$modulesPath/$_ && drush dl $modulesToInstall" if($modulesToInstall and $_ eq "drupal");
	
							#commit
							system "cd /var/hg/$domain/$appPath/$modulesPath/$_ && chown -R root:root /var/hg/$domain/$appPath/$modulesPath/$_ && hg -q init && hg -q add && hg -q commit -m \"initial commit\"";
						}
						else {
							printComment("/var/hg/$domain/$appPath/$modulesPath/$_ already exists");
						}
					
		 				$clone .= "\t".'system "hg clone /var/hg/$domain/$appPath/$modulesPath/'.$_.' $path/$modulesPath/'.$_.'";'."\n";
		 				$push  .= "\t".'system "cd $path/$modulesPath/'.$_.' && hg addremove && hg commit -m \"automatic commit\" && hg push && cd /var/hg/$domain/$appPath/$modulesPath/'.$_.' && hg update";'."\n";
		 				$pull  .= "\t".'system "cd $path/$modulesPath/'.$_.' && hg pull && hg update";'."\n";
		 			}
		 			
		 			#themes...
		 			foreach (split(/ /, $themes)) {
		
						unless(-d "/var/hg/$domain/$appPath/$themesPath/$_") {
							
							system "mkdir -p /var/hg/$domain/$appPath/$themesPath/$_";
							
							system "cd /var/hg/$domain/$appPath/$themesPath/$_ && drush dl $themesToInstall" if($themesToInstall and $_ eq "drupal");
							
							#commit
							system "cd /var/hg/$domain/$appPath/$themesPath/$_ && chown -R root:root /var/hg/$domain/$appPath/$modulesPath/$_ && hg -q init && hg -q add && hg -q commit -m \"initial commit\"";
						}
						else {
							printComment("/var/hg/$domain/$appPath/$themesPath/$_ already exists");
						}
					
		 				$clone .= "\t".'system "hg clone /var/hg/$domain/$appPath/$themesPath/'.$_.' $path/$themesPath/'.$_.'";'."\n";
		 				$push  .= "\t".'system "cd $path/$themesPath/'.$_.' && hg add && hg commit -m \"automatic commit\" && hg push && cd /var/hg/$domain/$appPath/$themesPath/'.$_.' && hg update";'."\n";
		 				$pull  .= "\t".'system "cd $path/$themesPath/'.$_.' && hg pull && hg update";'."\n";
		 			}
					
					$template = Text::Template->new(SOURCE => "$scriptPath/s66c/tmpl/hg.tmpl") or die "Couldn't construct template: $Text::Template::ERROR";
		        	%vars = (domain => $domain, appPath => $appPath, modulesPath => $modulesPath, themesPath => $themesPath, clone => $clone, push => $push, pull => $pull);
		       		$result = $template->fill_in(HASH => \%vars);
		
		        	if (defined $result) {
						open (FILE, ">$dir/$domain/private/hg.pl");
						print FILE $result;
						close (FILE);
						system "chown $user:$user $dir/$domain/private/hg.pl";
						
						printNotice('script created', "$dir/$domain/private/hg.pl");
					}
				}
			}
			else {
				printComment('hg.pl already exists');
			}
			
			#create extra.pl
			unless(-f "$dir/$domain/private/extra.pl") {
				
				my $clone = "";
				my $push  = "";
				my $pull  = "";
				
				#develModulesToInstall...
				if($develModulesToInstall) {
					foreach (split(/ /, $develModulesToInstall)) {
						
						my @mm = split(/-/, $_);
						my $mm = shift(@mm);
					}
				}
				
				#modulesToInstall...
				if($modulesToInstall) {
					foreach (split(/ /, $modulesToInstall)) {
						
						my @mm = split(/-/, $_);
						my $mm = shift(@mm);
						
						$clone .= "\t".'system "mkdir -p $path/cache && chown -R www-data:www-data $path/cache"'."\n" if($mm eq "boost");
					}
				}
				
				#themesToInstall...
				if($themesToInstall) {
					foreach (split(/ /, $themesToInstall)) {
						
						my @mm = split(/-/, $_);
						my $mm = shift(@mm);
					}
				}
				
				if($clone or $push or $pull) {
					$template = Text::Template->new(SOURCE => "$scriptPath/s66c/tmpl/extra.tmpl") or die "Couldn't construct template: $Text::Template::ERROR";
		        	%vars = (domain => $domain, appPath => $appPath, modulesPath => $modulesPath, themesPath => $themesPath, clone => $clone, push => $push, pull => $pull);
		       		$result = $template->fill_in(HASH => \%vars);
		
		        	if (defined $result) {
						open (FILE, ">$dir/$domain/private/extra.pl");
						print FILE $result;
						close (FILE);
						system "chown $user:$user $dir/$domain/private/extra.pl";
						
						printNotice('script created', "$dir/$domain/private/extra.pl");
					}
				}
			}
			else {
				printComment('extra.pl already exists');
			}
		}
		else {
			printError('Cannot find git or mercurial');
		}
	}
	
	#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	
	tweetInit($domain, 'Initialising {$tweet}') if(functionExists('tweetInit'));
	
	#install application script
	if(&promptUser("Install application (drupal, wordpress)? (yes|no)", 'yes') eq 'yes') {
		forkApp($dir, $domain, $filter);
	}
	
	#create db...
	if(&promptUser("Create a new db? (yes|no)", 'yes') eq 'yes') {
		
		if (not -f "$dir/$domain/private/db.pl") {
			my $random = new String::Random;
		
			$random->{'A'} = ['A'..'Z', 'a'..'z', 0..9];
		
			my $host = "localhost";
		
			#save db file...
			$template = Text::Template->new(SOURCE => "$scriptPath/s66c/tmpl/db.tmpl") or die "Couldn't construct template: $Text::Template::ERROR";
	    	%vars = (host => $host, db => $random->randpattern('AAAAAAAAAAAAAAAA'), user => $random->randpattern('AAAAAAAAAAAAAAAA'), pass => $random->randpattern('AAAAAAAAAAAAAAAA'));
	   		$result = $template->fill_in(HASH => \%vars);
	
	    	if (defined $result) {
				open (FILE, ">$dir/$domain/private/db.pl");
				print FILE $result;
				close (FILE);
				system "chown root:root $dir/$domain/private/db.pl";
				
				printNotice('script created', "$dir/$domain/private/db.pl");
			}		
		}
		else {
			printComment('db.pl already exists');
		}
	}
	
	#load db
	if (-f "$dir/$domain/private/db.pl") {
		do "$dir/$domain/private/db.pl";
	
		dbCreate() if(functionExists("dbCreate"));
		dbInfo() if(functionExists("dbInfo"));
		
		$db = dbGetDb() if(functionExists("dbGetDb"));
		$dbuser = dbGetUser() if(functionExists("dbGetUser"));
		$dbpass = dbGetPass() if(functionExists("dbGetPass"));
		
		#unset function...
		unsetDb();
	}
	
	#create db backup script
	if(&promptUser("Setup basic Drupal backup? (yes|no)", 'yes') eq 'yes') {
	
		#- - -
	
		unless(-d "$dir/$domain/private/db.backup") {
			
			$user = &promptUser("Enter user for $domain", $defaultName) unless ($user);
			system "mkdir $dir/$domain/private/db.backup && chown $user:$user $dir/$domain/private/db.backup";
		}
		
		unless(-f "$dir/$domain/private/db.backup/backup.pl") {
			
			$user = &promptUser("Enter user for $domain", $defaultName) unless ($user);
			$app = &promptUser("Enter application name", "app") unless ($app);
			
			$db = &promptUser("Enter database's name") unless ($db);
			$dbuser = &promptUser("Enter database's user") unless ($dbuser);
			$dbpass = &promptUser("Enter database's password") unless ($dbpass);
	
			$template = Text::Template->new(SOURCE => "$scriptPath/s66c/tmpl/db.backup.tmpl") or die "Couldn't construct template: $Text::Template::ERROR";
	        %vars = (dir => $dir, domain => $domain, app => $app, user => $dbuser, pass => $dbpass, db => $db);
	        $result = $template->fill_in(HASH => \%vars);
	
	        if (defined $result) {
				open (FILE, ">$dir/$domain/private/db.backup/backup.pl");
				print FILE $result;
				close (FILE);
				system "chmod +x $dir/$domain/private/db.backup/backup.pl && chown $user:$user $dir/$domain/private/db.backup/backup.pl";
			
				printNotice('script created', "$dir/$domain/private/db.backup/backup.pl");
			}
		}
		else {
			printComment('db.backup/backup.pl file already exists');
		}
	
		#- - -
		
		unless(-d "$dir/$domain/private/db.auto.backup") {
			
			$user = &promptUser("Enter user for $domain", $defaultName) unless ($user);
			system "mkdir $dir/$domain/private/db.auto.backup && chown $user:$user $dir/$domain/private/db.auto.backup";
		}
		
		unless(-f "$dir/$domain/private/db.auto.backup/backup.pl") {
			
			$user = &promptUser("Enter user for $domain", $defaultName) unless ($user);
			$app = &promptUser("Enter application name", "app") unless ($app);
			
			$db = &promptUser("Enter database's name") unless ($db);
			$dbuser = &promptUser("Enter database's user") unless ($dbuser);
			$dbpass = &promptUser("Enter database's password") unless ($dbpass);
	
			$template = Text::Template->new(SOURCE => "$scriptPath/s66c/tmpl/db.auto.backup.tmpl") or die "Couldn't construct template: $Text::Template::ERROR";
	        %vars = (dir => $dir, domain => $domain, app => $app, user => $dbuser, pass => $dbpass, db => $db);
	        $result = $template->fill_in(HASH => \%vars);
	
	        if (defined $result) {
				open (FILE, ">$dir/$domain/private/db.auto.backup/backup.pl");
				print FILE $result;
				close (FILE);
				system "chmod +x $dir/$domain/private/db.auto.backup/backup.pl && chown $user:$user $dir/$domain/private/db.auto.backup/backup.pl";
			
				printNotice('script created', "$dir/$domain/private/db.auto.backup/backup.pl");
			}
		}
		else {
			printComment('db.auto.backup/backup.pl file already exists');
		}
		
		#create files backup scripts
		unless(-d "$dir/$domain/private/files.backup") {
			
			$user = &promptUser("Enter user for $domain", $defaultName) unless ($user);
			system "mkdir $dir/$domain/private/files.backup && chown $user:$user $dir/$domain/private/files.backup";
		}
	
		unless(-f "$dir/$domain/private/files.backup/backup.pl") {
	
			$user = &promptUser("Enter user for $domain", $defaultName) unless ($user);
			$app = &promptUser("Enter application name", "app") unless ($app);
			$filesparent = &promptUser("Enter drupal files parent path", "sites/default") unless ($filesparent);
			$filesname = &promptUser("Enter drupal files name", "files") unless ($filesname);
	
			$template = Text::Template->new(SOURCE => "$scriptPath/s66c/tmpl/files.backup.tmpl") or die "Couldn't construct template: $Text::Template::ERROR";
	        %vars = (dir => $dir, domain => $domain, user => $user, app => $app, filesparent => $filesparent, filesname => $filesname);
	        $result = $template->fill_in(HASH => \%vars);
	
	        if (defined $result) {
				open (FILE, ">$dir/$domain/private/files.backup/backup.pl");
				print FILE $result;
				close (FILE);
				system "chmod +x $dir/$domain/private/files.backup/backup.pl && chown $user:$user $dir/$domain/private/files.backup/backup.pl";
			
				printNotice('script created', "$dir/$domain/private/files.backup/backup.pl");
			}
		}
		else {
			printComment('files.backup/backup.pl file already exists');
		}

		#- - -

		unless(-d "$dir/$domain/private/files.auto.backup") {
	
			$user = &promptUser("Enter user for $domain", $defaultName) unless ($user);
			system "mkdir $dir/$domain/private/files.auto.backup && chown $user:$user $dir/$domain/private/files.auto.backup";
		}
	
		unless(-f "$dir/$domain/private/files.auto.backup/backup.pl") {
	
			$user = &promptUser("Enter user for $domain", $defaultName) unless ($user);
			$app = &promptUser("Enter application name", "app") unless ($app);
			$filesparent = &promptUser("Enter drupal files parent path", "sites/default") unless ($filesparent);
			$filesname = &promptUser("Enter drupal files name", "files") unless ($filesname);
	
			$template = Text::Template->new(SOURCE => "$scriptPath/s66c/tmpl/files.auto.backup.tmpl") or die "Couldn't construct template: $Text::Template::ERROR";
	        %vars = (dir => $dir, domain => $domain, user => $user, app => $app, filesparent => $filesparent, filesname => $filesname);
	        $result = $template->fill_in(HASH => \%vars);
	
	        if (defined $result) {
				open (FILE, ">$dir/$domain/private/files.auto.backup/backup.pl");
				print FILE $result;
				close (FILE);
				system "chmod +x $dir/$domain/private/files.auto.backup/backup.pl && chown $user:$user $dir/$domain/private/files.auto.backup/backup.pl";
			
				printNotice('script created', "$dir/$domain/private/files.auto.backup/backup.pl");
			}
		}
		else {
			printComment('files.auto.backup/backup.pl file already exists');
		}
	
		#create full site backup
	
		unless(-d "$dir/$domain/private/backup") {
	
			$user = &promptUser("Enter user for $domain", $defaultName) unless ($user);
			system "mkdir $dir/$domain/private/backup && chown $user:$user $dir/$domain/private/backup";
		}
	
		unless(-f "$dir/$domain/private/backup/backup.pl") {
	
			$user = &promptUser("Enter user for $domain", $defaultName) unless ($user);
			$app = &promptUser("Enter application name", "app") unless ($app);
			
			$db = &promptUser("Enter database's name") unless ($db);
			$dbuser = &promptUser("Enter database's user") unless ($dbuser);
			$dbpass = &promptUser("Enter database's password") unless ($dbpass);
	
			$template = Text::Template->new(SOURCE => "$scriptPath/s66c/tmpl/backup.tmpl") or die "Couldn't construct template: $Text::Template::ERROR";
	        %vars = (dir => $dir, domain => $domain, user => $user, app => $app, user => $dbuser, pass => $dbpass, db => $db);
	        $result = $template->fill_in(HASH => \%vars);
	
	        if (defined $result) {
				open (FILE, ">$dir/$domain/private/backup/backup.pl");
				print FILE $result;
				close (FILE);
				system "chmod +x $dir/$domain/private/backup/backup.pl && chown $user:$user $dir/$domain/private/backup/backup.pl";
			
				printNotice('script created', "$dir/$domain/private/backup/backup.pl");
			}
		}
		else {
			printComment('backup/backup.pl file already exists');
		}
	
		#- - -
	
		if(&promptUser("Run auto backup with cron? (yes|no)", 'yes') eq 'yes') {
		
			#create cron job...
			my $cron = getSitedomain($domain);
			$cron =~ s/\//_/g;
			$cron =~ s/\./_/g;
			
			if(not -f "/etc/cron.d/$cron") {
				
				my $mdb = int(rand(60));
				$mdb = ($mdb < 10)? '0'.$mdb : $mdb;
				
				my $hdb = int(rand(24));
				$hdb = ($hdb < 10)? '0'.$hdb : $hdb;
				
				my $mfile = int(rand(60));
				$mfile = ($mfile < 10)? '0'.$mfile : $mfile;
				
				my $hfile = int(rand(24));
				$hfile = ($hfile < 10)? '0'.$hfile : $hfile;
				
				my $dfile = int(rand(7));
				$dfile = ($dfile < 10)? '0'.$dfile : $dfile;
				
				%vars = (
							'perl', which('perl'),
							'envShell', which('bash'),
							'envHome', $ENV{HOME},
							'envMail', $ENV{MAIL},
							'envPath', $ENV{PATH},
							'envUser', $ENV{USER},
							'path', "$dir/$domain/private", 
							'mdb', $mdb, 
							'hdb', $hdb, 
							'mfile', $mfile, 
							'hfile', $hfile, 
							'dfile', $dfile
						);

				$template = Text::Template->new(SOURCE => "$scriptPath/s66c/tmpl/cron.tmpl") or die "Couldn't construct template: $Text::Template::ERROR";
		        $result = $template->fill_in(HASH => \%vars);
		
		        if (defined $result) {
		
					open (FILE, ">/etc/cron.d/$cron");
					print FILE $result;
					close (FILE);
					
					printNotice('Cron created', "/etc/cron.d/$cron");
				}
			}
			else {
				printComment("/etc/cron.d/$cron file already exists");
			}
		}
	}
}

1;