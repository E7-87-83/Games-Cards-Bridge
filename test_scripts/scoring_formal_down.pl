use strict;
use warnings;
use Test::More tests => 78;
use Games::Cards::Bridge::Scoring;
use Games::Cards::Bridge::Objects;

# port from Games-Cards-Bridge-Contract-0.02/t/scoring-defeated.t, 
# originally written by David Westbrook


while(<DATA>){
  s/^\s+//g;
  s/\s+$//sg;
  s/^#.+//;
  my $trump_chr = "H";
  next unless length;
  my ($down, @scores) = split ' ', $_;
  foreach my $i ( 0..$#scores ){
    my $expected = $scores[$i];
    my $bid_val = 1;
    my $vul_val = $i >= 3;
    my $dbl_val = $i % 3;
    my $my_contract = Contract->new(
            declarer => Player->new(char=>"N"), 
            trumpsuit=> Suit->new(char=>$trump_chr), 
            bid_finalized=>$bid_val, 
            vul=>$vul_val, 
            dbl=>$dbl_val,
        );
    my $my_outcome = Outcome->new(
            contract=>$my_contract, 
            tricks_winned => 6 + $bid_val - $down,
        );
    my $score = Scoring->new(outcome=>$my_outcome)->duplicate_score;
    is(-$score, $expected, sprintf("%d%s/%d vul=%d dbl=%d ==> %d", $bid_val, $trump_chr, $down, $vul_val, $dbl_val, $expected) );
  }
}

__DATA__
#		DEFEATED CONTRACTS
#	Non-Vulnerable		Vulnerable
#Down	Undbl	Dbl	Redbl	Undbl	Dbl	Redbl
1	50	100	200	100	200	400
2	100	300	600	200	500	1000
3	150	500	1000	300	800	1600
4	200	800	1600	400	1100	2200
5	250	1100	2200	500	1400	2800
6	300	1400	2800	600	1700	3400
7	350	1700	3400	700	2000	4000
8	400	2000	4000	800	2300	4600
9	450	2300	4600	900	2600	5200
10	500	2600	5200	1000	2900	5800
11	550	2900	5800	1100	3200	6400
12	600	3200	6400	1200	3500	7000
13	650	3500	7000	1300	3800	7600

