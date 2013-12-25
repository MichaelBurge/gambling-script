my $chance_to_win = .6;

use Carp qw/ confess /;
$SIG{__DIE__} = \&confess;

sub burge_strategy {
    my ($current_balance) = @_;
    return 0 if $current_balance > 1000;
    return $current_balance / 2;
}

sub author_strategy {
    my ($current_balance) = @_;
    return $current_balance * 0.2;
}

sub make_burgelike_strategy {
    my ($stop_after_winning, $percent_to_gamble) = @_;
    my $strategy = sub {
	my ($current_balance) = @_;
	return 0 if $stop_after_winning && $current_balance > 1000;
	return $current_balance * $percent_to_gamble;
    };
    return (
	"Burgelike strategy - stop on win = `$stop_after_winning`; percent = $percent_to_gamble" =>
	    $strategy
    );
}

sub gamble {
    my ($amount_to_gamble_sub, $current_balance) = @_;
    my $amount_to_gamble = $amount_to_gamble_sub->($current_balance);

    if (rand() < $chance_to_win) {
	$current_balance += $amount_to_gamble;
    } else {
	$current_balance -= $amount_to_gamble;
    }

    return $current_balance;
}

sub gamble_with_strategy {
    my ($strategy) = @_;
    my $current_balance = 1000;
    my $num_turns = 40;
    do { $current_balance = gamble($strategy, $current_balance) } while $num_turns--;
    return $current_balance;
}

sub say { print @_; print "\n" }

sub test_strategy {
    my ($strategy) = @_;

    my $num_tries = 10000;
    my $balance_accum = 0;
    my $num_losses = 0;

    for my $try (0..$num_tries) {
	my $difference = gamble_with_strategy($strategy) - 1000;
	$balance_accum += $difference;
	$num_losses++ if $difference <= 0;
    }

    return {
	expected_value => ($balance_accum / $num_tries),
	num_losses => $num_losses,
	loss_percentage => ($num_losses / $num_tries),
    }

}

sub print_test_results {
    my ($name, $results) = @_;
    say("Strategy: $name");
    say("EV: $results->{expected_value}");
    say("Losses: $results->{num_losses}");
    say("Loss %: " . ($results->{loss_percentage} * 100) );
    say('------');
}

sub find_best_strategy {
    my ($compare_sub, %strategies_by_name) = @_;
    my %results_by_name =
      map {$_ => test_strategy($strategies_by_name{$_})}
        keys %strategies_by_name
    ;
    my ($best_name) = sort {
      $compare_sub->(
        $results_by_name{$a},
        $results_by_name{$b})
      } keys %results_by_name
    ;
    print_test_results($best_name, $results_by_name{$best_name});
}

sub compare_ev {
    my ($a, $b) = @_;
    return $b->{expected_value} <=> $a->{expected_value};
}

sub compare_losses {
    my ($a, $b) = @_;
    return $a->{num_losses} <=> $b->{num_losses};
}


#print_test_results("Burge's strategy", test_strategy(\&burge_strategy));
#print_test_results("Author's strategy", test_strategy(\&author_strategy));

my %strategies_by_name =
  map {
      make_burgelike_strategy(0, $_),
      make_burgelike_strategy(1, $_)
  } map { $_ / 100 } ( 0..100)
;

say("Best strategy for EV");
find_best_strategy(\&compare_ev, %strategies_by_name);
say("Best strategy for winning");
find_best_strategy(\&compare_losses, %strategies_by_name);
