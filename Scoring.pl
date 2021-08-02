# ================== THIS IS A DRAFT ==================
# ================== 2021-08-02 15:52 HKT ==================

{ package Scoring;
use strict;
use warnings;
use Object::Pad;

# a port using Object::Pad from Games::Cards::Bridge::Contract
# Only dulipcate_score is ported.

class Contract {
    has $declarer :param;   # N,E,S,W
    has $trump :param;      # C,D,H,S,N,P
    has $bid_finalized :param = undef; # 1..7
    has $vul :param = undef ;      # 0 or 1
    has $dbl :param = undef; # 0->none 1->X  2->XX
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

    method get_dbl {
        return $dbl;
    }

    method get_vul {
        return $vul;
    }

    method get_trump {
        return $trump;
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
    has $_contract :param;
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
    has $_contract :param;
    has $_outcome :param;
    has $score_gained :param = undef;           
    has $penalty_points :param = undef;

    method duplicate_score {
        if ($_outcome->is_contract_made) {
            $score_gained = 0;
            # below: contract points
            my $cntrct_pt = 0;
            $cntrct_pt += 40 if $_contract->get_trump eq "N";
            $cntrct_pt += 30 if $_contract->is_major == 1;
            $cntrct_pt += 20 if $_contract->is_minor == 1;
            my $each_cntrct_pt = 0;
            if ($_contract->get_bid > 1) {
                if ($_contract->get_trump =~ m/^[NSH]$/ ) {
                    $each_cntrct_pt = 30;
                }
                else {
                    $each_cntrct_pt = 20;
                }
                $cntrct_pt += $each_cntrct_pt*($_contract->get_bid-1);
            }
            $cntrct_pt *= 2**($_contract->get_dbl); #dbl
            $score_gained += $cntrct_pt;
            # below: game or partial score
            if ($_contract->is_game) {
                $score_gained +=
                  $_contract->get_vul ? 500 : 300;
            }
            else {
                $score_gained += 50;
            }
            # below: overtrick points
            my $each_over_tk_pt = $_contract->is_minor ? 20 : 30;
            if ($_contract->get_dbl > 0) {
                $each_over_tk_pt = 100;
                $each_over_tk_pt *= 2 if $_contract->get_dbl == 2;
            }
            $score_gained +=
              $each_over_tk_pt * $_outcome->get_overtricks;
            # below: small slam bonus
            if ($_contract->is_small_slam) {
                $score_gained +=
                  $_contract->get_vul ? 750 : 500;
            }
            # below: grand slam bonus
            if ($_contract->is_grand_slam) {
                $score_gained +=
                  $_contract->get_vul ? 1500 : 1000;
            }
            # below: double or redoubled bonus
            $score_gained += 50*$_contract->get_dbl;
            # ---
            $penalty_points = 0;
            return $score_gained;
        }
        else {
            if ($_contract->get_dbl == 0) {  # undoubled
                $penalty_points += 50*$_outcome->get_undertricks;
                $penalty_points *= 2 if $_contract->get_vul;
                $score_gained = 0;
            }
            else {             # doubled or redoubled
              if ($_contract->get_vul == 1) {  # vulnerable
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
              $penalty_points *= 2 if $_contract->get_dbl == 2; # if redoubled
            }
            return -$penalty_points
        }
    }

}

1;

}

use strict;
use warnings;
use v5.10.0;


my $good = Contract->new( declarer => "N", trump=>"S", bid_finalized=>4, vul=>0, dbl=>2);

my $end_board = Outcome->new(contract=>$good, tricks_winned => 11);

my $score = Scoring->new(contract=>$good, outcome=>$end_board);
print $score->duplicate_score;
print "\n";

