use strict;
use warnings;
use Term::ANSIColor qw(color);
use Term::ANSIColor qw(:constants);

sub printLabel {
	
	my $label = shift;
	print "\n", WHITE, ON_GREEN, " $label ", RESET if($label);
}

sub printComment {

	my $comment = shift;
	print "\n", WHITE, $comment, RESET, "\n" if($comment);
}

sub printAction {

	my $action = shift;
	print "\n", RESET, " $action ", RESET, "\n" if($action);
}

sub printError {

	my $error = shift;
	print "\n", WHITE, ON_RED, " $error ", RESET, "\n" if($error);
}

sub printWarning {

	my $warning = shift;
	print "\n", WHITE, ON_YELLOW, " $warning ", RESET, "\n" if($warning);
}

sub printNotice {
	
	my $label = shift;
	my $notice = shift;
	print "\n$label : ", WHITE, ON_GREEN, " $notice ", RESET, "\n" if($notice);
}

sub printNoticeOrWarning {
	
	my $label = shift;
	my $notice = shift;
	my $warning = shift;
	
	if($notice) {
		printNotice($label, $notice);
	}
	else {
		printWarning($warning);
	}
}

sub printNoticeOrError {
	
	my $label = shift;
	my $notice = shift;
	my $error = shift;
	
	if($notice) {
		printNotice($label, $notice);
	}
	else {
		printError($error);
	}
}

sub confirm {

	my $message = shift;
	my $default = shift;
	
	if(not $default) {
		$default = 'no';
	}

	return (&promptUser("$message (yes|no)", $default) eq 'yes') if($message);

	return (&promptUser('Are you sure? (yes|no)', $default) eq 'yes');
}

sub promptUser {

	my($prompt, @options) = @_;
	
	return promptUserQuestion('', $prompt) if(@options==0);
	return promptUserQuestion('', $prompt, $options[0]) if(@options==1);
	
	return promptUserQuestions('', $prompt, @options);
}

sub promptUserWithLabel {

	my($label, $prompt, @options) = @_;
	
	return promptUserQuestion($label, $prompt) if(@options==0);
	return promptUserQuestion($label, $prompt, $options[0]) if(@options==1);
	
	return promptUserQuestions($label, $prompt, @options);
}

sub promptUserQuestion {

	my($label, $prompt, $default) = @_;

	printLabel($label);
	print "\n$prompt\n";
	print RED, "[$default]" if($default);
	print BLUE, " > ", RESET;
	
	chomp(my $input = <STDIN>);
	
	if($default) {
		
	}
	
	return (length($input) > 0) ? $input : ($default)? $default : "";
}


sub promptUserQuestions {
	
	my($label, $prompt, @options) = @_;

	printLabel($label);
	print "\n$prompt\n";
	
	my $count = 0;

	foreach (@options) {
		print YELLOW, "[$count]", BLUE, " $_", RESET, "\n";
		$count++;
	}

	print BLUE, " > ", RESET;
	
	chomp(my $input = <STDIN>);

	return $options[$input] if(isInteger($input) && $input>=0 && $input<@options);
	
	promptUserQuestions($label, $prompt, @options);
}

1;