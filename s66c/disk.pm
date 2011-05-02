use strict;
use warnings;

sub diskUsage {

	#copied from: http://www.perlmonks.org/?node_id=125823
	my @lines;
	my $df = "df";
	
	## Point to a Berkely-esque df if needed
	if ($^O =~ /solaris/) {
	  $df = "/usr/ucb/df";
	}
	
	## Open a pipe from df
	open( DF, "$df -h |" ) or die "Can't open pipe from df: $!"; 
	
	## skip first line
	scalar <DF>; 
	
	printLabel('Disk usage');
	
	## Print header
	print "\n",
	      "                                           1\n",
	      "       1   2   3   4   5   6   7   8   9   0\n",
	      "       0   0   0   0   0   0   0   0   0   0  Filesystem\n",
	      "    ---|---|---|---|---|---|---|---|---|---|  ------------------\n"; 
	
	## Parse output from df
	while(<DF>) { 
	  chomp; 
	  my @F = split;
	  $_ .= <DF>, @F = split if @F == 1;
	
	  my( $av, $c, $fs ) = @F[3, 4,-1]; 
	  $c =~ s/(\d+)%/$1/;
	
	  push @lines, [ $c, sprintf "%3d %-40s  %s (%s)", $c, "=" x int($c / 2.5), $fs, $av ]; 
	} 
	
	close(DF);
	
	## Print sorted reverse by capacity
	for( sort { $b->[0] <=> $a->[0] } @lines ) {
	  my $color = '';
	  if ( $_->[0] >= 85 ) {
	    $color = color( 'bold red' );
	  } elsif ( $_->[0] >= 70 ) {
	    $color = color( 'bold yellow' );
	  }
	
	  print $color, $_->[1], color('reset'), "\n";
	}
}

1;