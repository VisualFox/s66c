use strict;
use warnings;
use File::Which;

sub checkStack {
	my $git = which('git');
	my $mercurial = which('hg');
	my $sshd = which('sshd');
	my $postfix = which('postfix');
	my $cron = which('cron');
	my $php = which('php');
	my $php5 = which('php5');
	my $drush = which('drush');
	my $nginx = which('nginx');
	my $monit = which('monit');
	my $mysql = which('mysql');
	my $mongo = which('mongo');
	my $redis = which('redis-server');
	my $octobot = (-d '/etc/octobot')? '/etc/octobot' : '';
	my $ntpd = which('ntpd');
	
	printNoticeOrWarning('git', $git, 'git not installed');
	printNoticeOrWarning('mercurial', $mercurial, 'mercurial not installed');
	
	printNoticeOrError('ssh', $sshd, 'ssh not installed');
	printNoticeOrError('postfix', $postfix, 'postfix not installed');
	printNoticeOrError('cron', $cron, 'cron not installed');
	printNoticeOrError('ntpd', $ntpd, 'ntpd not installed');
	
	printNoticeOrError('php', $php, 'php not installed');
	printNoticeOrError('php5', $php5, 'php5 not installed');
	printNoticeOrError('drush', $drush, 'drush not installed');
	
	printNoticeOrError('nginx', $nginx, 'nginx not installed');
	printNoticeOrError('mysql', $mysql, 'mysql not installed');
	
	printNoticeOrWarning('mongo', $mongo, 'mongo not installed');
	printNoticeOrWarning('octobot', $octobot, 'octobot not installed');
	printNoticeOrWarning('redis', $redis, 'redis not installed');
	
	printNoticeOrWarning('monit', $monit, 'monit not installed');
}

sub createConfiguration {
	
	my $scriptPath = $main::scriptPath;

	my $app = 'app';
	
	my $dbhost;
	my $dbusername;
	my $dbpassword;

	printLabel('Wizard');
	
	if((not -f "$scriptPath/s66c/config.cfg") || confirm('Overwrite config file')) {
		$app = &promptUser("Enter application folder name", 'app') unless ($app);
		
		$dbhost = &promptUser("Enter mysql host", 'localhost') unless ($dbhost);
		$dbusername = &promptUser("Enter mysql root username", 'root') unless ($dbusername);
		$dbpassword = &promptUser("Enter mysql root password") unless ($dbpassword);
	
		if($dbusername eq 'root' && confirm('Set mysql root password')) {
		
			print "\nThis will only work if the previous mysql root password was empty (fresh install)\n";
			system "mysqladmin -h$dbhost -u$dbusername password '$dbpassword'";
		}
		
		if(confirm('Test mysql connection', 'yes')) {
			system "mysqladmin -h$dbhost -u$dbusername -p$dbpassword version";
			
			while(not confirm('Did the connection works?', 'yes')) {
				$dbhost = &promptUser("Enter mysql host", $dbhost);
				$dbusername = &promptUser("Enter mysql root username", 'root');
				$dbpassword = &promptUser("Enter mysql root password", $dbpassword);
				
				system "mysqladmin -h$dbhost -u$dbusername -p$dbpassword version";
			}
		}
	
		package main; {
			our $config = {
						'app' => $app
	                };
	
			our $database = {
						'password' => $dbpassword,
						'username' => $dbusername,
						'host' => $dbhost
	                };
		}
	
		writeConfigurationFile("$scriptPath/s66c/config.cfg");
	}
}

1;