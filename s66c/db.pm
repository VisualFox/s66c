use strict;
use warnings;

sub dbRun {
	my $cmd = shift;
	
	my $host = $main::database->{'host'};
	my $user = $main::database->{'username'};
	my $password = $main::database->{'password'};

	if($host && $user && $password) {
		system "mysql -h$host -u$user -p$password -e \"$cmd\"";
	}
	else {
		printError('No admin user and password set for mysql');
	}
}

1;