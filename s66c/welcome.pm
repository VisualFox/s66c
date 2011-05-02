use strict;
use warnings;
use Term::ANSIColor qw(:constants);

sub welcome {

	 printLabel('Welcome');
	 print WHITE;
	 print"                                        \n",
	      "                                        \n",
	      "   ######   #######   #######   ######  \n",
	      "  ##    ## ##     ## ##     ## ##    ## \n",
	      "  ##       ##        ##        ##       \n",
	      "   ######  ########  ########  ##       \n",
	      "        ## ##     ## ##     ## ##       \n",
	      "  ##    ## ##     ## ##     ## ##    ## \n",
	      "   ######   #######   #######   ######  \n",
	      "                                        \n";
	 print RESET;
}

1;