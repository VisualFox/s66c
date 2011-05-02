use strict;
use warnings;
use Data::Dumper;

sub getSitedomain {
	my $domain = shift;
	my $addWWW = shift;
	
	my @hosts = split(/\//, $domain);
	
	if(@hosts==1) {
		my @vhosts = split(/\./, $domain);
	
		if(@vhosts==2) {
			return "www.$domain" if($addWWW);
			
			return $domain;
		}
		else {
			return $domain;
		}
	}
	elsif(@hosts==3) {
		my $d = shift(@hosts);
		my $t = shift(@hosts);
		my $s = shift(@hosts);
		
		return "$s.$d" if($t eq "subdomains");
		
		return $domain;
	}
	
	return $domain;
}

sub getSiteURL {
	my $domain = shift;
	return "http://".getSitedomain($domain, 1);
}

sub functionExists {    
    
    no strict 'refs';
    my $funcname = shift;
    return \&{$funcname} if defined &{$funcname};
    return;
}

sub findAndReplace {

	my $dir = shift;
	my $file = shift;
	my $find = shift;
	my $replace = shift;
	
	open(FILE,"$dir/$file") or die("Cannot Open File");
	my(@fcont) = <FILE>;
	close FILE;

	my $line;

	open(FOUT,">$dir/__$file.tmp") or die("Cannot Open File");
	foreach $line (@fcont) {
    	$line =~ s/$find/$replace/g;
    	print FOUT $line;
	}
	close FOUT;
	
	system "mv -f $dir/__$file.tmp $dir/$file";
}

#--------------------------------------------

sub listVHost {

	my $available = shift;
	my $enabled = shift;
	my $action = shift;
	my @listAvailable;
	my @list;
	my $listString = "\n";
	my $file;

	system "mkdir -p $available && chown root:root $available" unless(-d $available);
	system "mkdir -p $enabled && chown root:root $enabled" unless(-d $enabled);

	#$available
	opendir(DIR, $available);

	foreach $file (readdir(DIR)) {
		next unless (-f "$available/$file");
		push(@listAvailable, $file);
	}
	
	closedir(DIR);
	
	if($action eq "enable") {
		for(my $i=0;$i<@listAvailable;++$i) {
			
			my $file = $listAvailable[$i];
			
			if(not -f "$enabled/$file") {
				push(@list, $file);
			}
		}
	}
	elsif($action eq "disable") {
		for(my $i=0;$i<@listAvailable;++$i) {
			
			my $file = $listAvailable[$i];
			
			if(-f "$enabled/$file") {
				push(@list, $file);
			}
		}
	}
	elsif($action eq 'list') {
		
		my $listString = "\n";
		
		for(my $i=0;$i<@listAvailable;++$i) {
			
			my $file = $listAvailable[$i];
			$listString .= (-f "$enabled/$file")? "[+] $file\n" : "[-] $file\n"; 
		}
		
		return &promptUser("Enter a new domain name : $listString");
	}
	else {
		@list = @listAvailable;
	}

	return '' if(@list==0);
	
	return &promptUserQuestions('Please choose a vhost file :', @list) if($action eq "select");

	return &promptUserQuestions("Please choose a vhost file to $action :", @list);
}

sub listDomain {
	
	my $dir = shift;
	my @list;
	my $file;

	unless(-d $dir) {
    	system "mkdir -p $dir && chown root:root $dir";
	}
	
	opendir(DIR, $dir);

	foreach $file (readdir(DIR)) {
		next unless (-d "$dir/$file");
		next if ($file =~ m/^\./);
		next unless ($file =~ m/\./);
		push(@list, $file);
	}
	
	closedir(DIR);
	
	if(@list==0) {
		return '';
	}
	
	my $domain = &promptUserQuestions('domain to manage', 'Please choose a domain :', @list);

	my $subdomains = "$dir/$domain/subdomains";	

	unless(-d $subdomains) {
		return $domain;
	}

	@list = ($domain);

	opendir(DIR, $subdomains);

    foreach $file (readdir(DIR)) {
        next unless (-d "$subdomains/$file");
        next if ($file =~ m/^\./);
        push(@list, $file);
    }

    closedir(DIR);
    
    if(@list>1) {
		
		my $subdomain = &promptUserQuestions('', 'Please choose a subdomains or confirm domain :', @list);
		
		return $domain if($subdomain eq $domain); 
		
		return "$domain/subdomains/".$subdomain;
    }
    
    return $domain;
}

#--------------------------------------------

sub htpasswd {
	my $username = shift;
	my $password = shift;
	my $filename = shift;
	
	my @saltsource = ('a'..'z', 'A'..'Z', '0'..'9');
	my $salt = $saltsource[int(rand(scalar @saltsource))] . $saltsource[int(rand(scalar @saltsource))];

	system "mkdir -p /etc/nginx/password";
	
	if (-f "/etc/nginx/password/$filename") {
		if(&promptUser("Overwrite $filename? (yes|no)", 'yes') eq 'yes') {
			open (FILE, ">/etc/nginx/password/$filename");
		}
		else {
    		open (FILE, ">>/etc/nginx/password/$filename");
    	}
	} else {
    	open (FILE, ">/etc/nginx/password/$filename");
	}

	print FILE $username.":".crypt($password,$salt)."\n";
	close (FILE);
}

sub isInteger{

  my $val = shift;
  return ($val =~ m/^\d+$/);
}

#read and write function from: http://www.perlmonks.org/?node_id=464358

# Read a configuration file
#   The arg can be a relative or full path, or
#   it can be a file located somewhere in @INC.
sub readConfigurationFile {

	my $file = shift;

    {   # Put config data into a separate namespace
        package main;

        # Process the contents of the config file
        my $rc = do($file);

        # Check for errors
        if ($@) {
            printError("ERROR: Failure compiling '$file' - $@");
        } elsif (! defined($rc)) {
            printError("ERROR: Failure reading '$file' - $!");
        } elsif (! $rc) {
            printError("ERROR: Failure processing '$file'");
        }
    }
}


# Save configuration data
#   Use the same arg as used with readConfigurationFile()
#   so that file can be found in the %INC.
sub writeConfigurationFile {

    my $file = shift;

    if (! open(FILE, "> $file")) {
        printError("ERROR: Failure opening '$file' - $!");
    }

    print FILE <<_MARKER_;
#####
#
# SCC6 configuration file !do no edit manually
#
#####

use strict;
use warnings;

# The configuration data
@{[Data::Dumper->Dump([$main::config], ['main::config'])]}
@{[Data::Dumper->Dump([$main::database], ['main::database'])]}
1;
# EOF
_MARKER_

    close(FILE);
}

1;