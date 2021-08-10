# ================== THIS IS A DRAFT ==================
# ================== 2021-08-11 06:48 HKT ==================

{
use Object::Pad 0.51;
use Object::Pad::SlotAttr::Isa;
package Scoring;
class Scoring;

# a port using Object::Pad from Games::Cards::Bridge::Contract
# Only dulipcate_score is ported (rubber_score is NOT ported).

class Contract {
    has $declarer :param;   # N,E,S,W
    has $trump :reader :param;      # C,D,H,S,N,P
    has $bid_finalized :param = undef; # 1..7
    has $vul :reader :param = undef ;      # 0 or 1
    has $dbl :reader :param = undef; # 0->none 1->X  2->XX
    has $minor :param = undef;     # 0 or 1
    has $major :param = undef;     # 0 or 1
    has $notrump :param = undef;     # 0 or 1
    has $small_slam :param = undef;     # 0 or 1
    has $grand_slam :param = undef;     # 0 or 1
    has $game :param = undef;           # 0 or 1

    method is_minor {
        return $minor = ($trump =~ m/^[CD]$/);
    }

    method is_major {
        return $major = ($trump =~ m/^[HS]$/);
    }

    method is_notrump {
        return $notrump = ($trump eq "N");
    }

    method is_small_slam {
        return $small_slam = ($bid_finalized == 6);
    }

    method is_grand_slam {
        return $grand_slam = ($bid_finalized == 7);
    }

    method is_game {
        return $game = 
          ($trump eq "N" && $bid_finalized >= 3) ||
          ($trump eq "C" && $bid_finalized >= 5) ||
          ($trump eq "D" && $bid_finalized >= 5) ||
          ($trump eq "H" && $bid_finalized >= 4) ||
          ($trump eq "S" && $bid_finalized >= 4);
    }

    method get_bid {
        return $bid_finalized;
    }

    BUILD {
        $self->is_minor();
        $self->is_major();
        $self->is_notrump();
        $self->is_small_slam();
        $self->is_grand_slam();
        $self->is_game();
    }
}

class Outcome {
    has $_contract :param :Isa(Contract);
    has $contract_made :param = undef;      # undef or 1
    has $tricks_winned :param; 
    has $overtricks :param = undef;
    has $undertricks :param = undef;

    method is_contract_made {
        return $contract_made = 
          ($tricks_winned >= (6+$_contract->get_bid) ? 1 : undef); 
    }

    method set_overtricks {
        if ($contract_made) {
            $overtricks = $tricks_winned - 6 - $_contract->get_bid;
        } 
        else {
            $overtricks = 0;
        }
    }
    
    method set_undertricks {
        if (!$contract_made) {
            $undertricks = $_contract->get_bid - $tricks_winned;
        }
        else {
            $undertricks = 0;
        }
    }


    method get_overtricks {return $overtricks;}
    method get_undertricks {return $undertricks;}

    
    BUILD {
        $self->is_contract_made();
        $self->set_overtricks();
        $self->set_undertricks();
    }
}

class Scoring {
    has $_contract :param :Isa(Contract);
    has $_outcome :param Isa(Outcome);
    has $score_gained :param = undef;           
    has $penalty_points :param = undef;

    method duplicate_score {
        if ($_outcome->is_contract_made) {
            $score_gained = 0;
            # below: contract points
            my $cntrct_pt = 0;
            $cntrct_pt += 40 if $_contract->trump eq "N";
            $cntrct_pt += 30 if $_contract->is_major == 1;
            $cntrct_pt += 20 if $_contract->is_minor == 1;
            my $each_cntrct_pt = 0;
            if ($_contract->get_bid > 1) {
                if ($_contract->trump =~ m/^[NSH]$/ ) {
                    $each_cntrct_pt = 30;
                }
                else {
                    $each_cntrct_pt = 20;
                }
                $cntrct_pt += $each_cntrct_pt*($_contract->get_bid-1);
            }
            $cntrct_pt *= 2**($_contract->dbl); #dbl
            $score_gained += $cntrct_pt;
            # below: game or partial score
            if ($_contract->is_game) {
                $score_gained +=
                  $_contract->vul ? 500 : 300;
            }
            else {
                $score_gained += 50;
            }
            # below: overtrick points
            my $each_over_tk_pt = $_contract->is_minor ? 20 : 30;
            if ($_contract->dbl > 0) {
                $each_over_tk_pt = 100;
                $each_over_tk_pt *= 2 if $_contract->dbl == 2;
            }
            $score_gained +=
              $each_over_tk_pt * $_outcome->get_overtricks;
            # below: small slam bonus
            if ($_contract->is_small_slam) {
                $score_gained +=
                  $_contract->vul ? 750 : 500;
            }
            # below: grand slam bonus
            if ($_contract->is_grand_slam) {
                $score_gained +=
                  $_contract->vul ? 1500 : 1000;
            }
            # below: double or redoubled bonus
            $score_gained += 50*$_contract->dbl;
            # ---
            $penalty_points = 0;
            return $score_gained;
        }
        else {
            if ($_contract->dbl == 0) {  # undoubled
                $penalty_points += 50*$_outcome->get_undertricks;
                $penalty_points *= 2 if $_contract->vul;
                $score_gained = 0;
            }
            else {             # doubled or redoubled
              if ($_contract->vul == 1) {  # vulnerable
                $penalty_points = 200;
                $penalty_points += 300*($_outcome->get_undertricks-1)
                     if $_outcome->get_undertricks >= 2;
                
              }
              else {           # non-vulnerable
                $penalty_points = 100;
                $penalty_points += 200 if $_outcome->get_undertricks >= 2;
                $penalty_points += 200 if $_outcome->get_undertricks >= 3;
                $penalty_points += 300*($_outcome->get_undertricks - 3)
                     if $_outcome->get_undertricks >= 4;
              }
              $penalty_points *= 2 if $_contract->dbl == 2; # if redoubled
            }
            return -$penalty_points
        }
    }

}

1;

}

# Test Script

use strict;
use warnings;
use v5.10.0;

use Games::Cards::Bridge::Contract;

my ($bid_val, $trump_chr) = split "", $ARGV[0];
my $tricks_winned = $ARGV[1];
my $pen_val = $ARGV[2] || 0;
my $vul_val = $ARGV[3] || 0;

my $dw_score;
my $my_score;

if ($tricks_winned < ($bid_val + 6)) {

    my $contract = Games::Cards::Bridge::Contract->new( declarer=>'N', trump=>$trump_chr, bid=>$bid_val, down=> (6 + $bid_val - $tricks_winned), vul=>$vul_val, penalty=>$pen_val);
    $dw_score = $contract->duplicate_score;

    say $dw_score;


    my $good = Contract->new( declarer => "N", trump=>$trump_chr, bid_finalized=>$bid_val, vul=>$vul_val, dbl=>$pen_val);

    my $end_board = Outcome->new(contract=>$good, tricks_winned => $tricks_winned);

    my $score = Scoring->new(contract=>$good, outcome=>$end_board);
    $my_score = $score->duplicate_score;
    say $my_score;


} else {

    my $contract = Games::Cards::Bridge::Contract->new( declarer=>'N', trump=>$trump_chr, bid=>$bid_val, made=> ($tricks_winned - 6), vul=>$vul_val, penalty=>$pen_val);
    $dw_score = $contract->duplicate_score;

    say $dw_score;

    my $good = Contract->new( declarer => "N", trump=>$trump_chr, bid_finalized=>$bid_val, vul=>$vul_val, dbl=>$pen_val);

    my $end_board = Outcome->new(contract=>$good, tricks_winned => $tricks_winned);

    my $score = Scoring->new(contract=>$good, outcome=>$end_board);
    $my_score = $score->duplicate_score;
    say $my_score;

}


if ($my_score == $dw_score) {say "okay"} else {say "BAD"}
