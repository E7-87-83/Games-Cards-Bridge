use Object::Pad 0.51;
use Object::Pad::SlotAttr::Isa;
use Games::Cards::Bridge::Objects;
use Carp;
use v5.10.0;
package Games::Cards::Bridge::Scoring;

# a port using Object::Pad of Games::Cards::Bridge::Contract
# originally written by David Westbrook
# Only dulipcate_score is ported (rubber_score is NOT ported).

# You may check against : http://www.rpbridge.net/2y66.htm

# The program is release under Artistic License 2.0 .
# See https://www.perlfoundation.org/artistic-license-20.html for details.




class Outcome {
    has $_contract :reader :param :Isa(Contract);
    has $contract_made :reader :param = undef;      # undef or 1
    has $tricks_winned :reader :param; 
    has $overtricks :reader :param = undef;
    has $undertricks :reader :param = undef;

    method is_contract_made {
        return $contract_made = 
          ($tricks_winned >= (6+$_contract->get_bid) ? 1 : undef); 
    }


    
    BUILD {
        $self->is_contract_made();
        if ($contract_made) {
            $overtricks = $tricks_winned - 6 - $_contract->get_bid;
        } 
        else {
            $overtricks = 0;
        }

        if (!$contract_made) {
            $undertricks = 6 + $_contract->get_bid - $tricks_winned;
        }
        else {
            $undertricks = 0;
        }
    
    }
}



class Scoring {
    has $_outcome :param :Isa(Outcome);
    has $_contract :param :Isa(Contract) = undef;

    method duplicate_score {
        my $score_gained = undef;           
        my $penalty_points = undef;
        if ($_outcome->contract_made) {
            $score_gained = 0;
            # below: contract points
            my $cntrct_pt = 0;
            $cntrct_pt += 40 if $_contract->trumpsuit->notrump;
            $cntrct_pt += 30 if $_contract->trumpsuit->major;
            $cntrct_pt += 20 if $_contract->trumpsuit->minor;
            my $each_cntrct_pt = 0;
            if ($_contract->get_bid > 1) {
                if ($_contract->trumpsuit->minor) {
                    $each_cntrct_pt = 20;
                }
                else {
                    $each_cntrct_pt = 30;
                }
                $cntrct_pt += $each_cntrct_pt*($_contract->get_bid - 1);
            }
            $cntrct_pt *= (2**($_contract->dbl)); #dbl
            $score_gained += $cntrct_pt;
            # below: overtrick points
            my $each_over_tk_pt = $_contract->trumpsuit->minor ? 20 : 30;
            if ($_contract->dbl > 0) {
                $each_over_tk_pt = 100;
                $each_over_tk_pt *= 2 if $_contract->dbl == 2;
                $each_over_tk_pt *= 2 if $_contract->vul == 1;
            }
            $score_gained +=
              $each_over_tk_pt * $_outcome->overtricks;
            # below: small slam bonus
            if ($_contract->small_slam) {
                $score_gained +=
                  $_contract->vul ? 750 : 500;
            }
            # below: grand slam bonus
            if ($_contract->grand_slam) {
                $score_gained +=
                  $_contract->vul ? 1500 : 1000;
            }
            # below: double or redoubled bonus in game
            if ($_contract->game) {
                $score_gained += 50*$_contract->dbl;
            }
            # game score
            if ($_contract->game) {
                $score_gained +=
                  $_contract->vul ? 500 : 300;
            }
            # below: partial score
            if (!$_contract->game) {
                my $partial_score = 50;

                if ($_contract->get_bid <= 2 && $_contract->dbl == 1) {
                    if ($_contract->trumpsuit->minor) {
                      $partial_score = 100;
                    }
                    else {
                      $partial_score = $_contract->vul ? 550 : 350 if $_contract->get_bid == 2;
                      $partial_score = 100 if $_contract->get_bid == 1;
                    }
                }

                $partial_score = $_contract->vul ? 550 : 350 
                  if $_contract->dbl == 1 && $_contract->get_bid > 2;

                if ($_contract->dbl == 2) {
                    $partial_score = 150
                      if $_contract->trumpsuit->minor && $_contract->get_bid < 2; 

                    $partial_score = $_contract->vul ? 600 : 400
                      if $_contract->trumpsuit->minor && $_contract->get_bid >= 2;

                    $partial_score = $_contract->vul ? 600 : 400
                      if (!$_contract->trumpsuit->minor); 
                }
                $score_gained += $partial_score;

            }

            $penalty_points = 0;
            return $score_gained;
        }
        else {
            if ($_contract->dbl == 0) {  # undoubled
                $penalty_points += 50*$_outcome->undertricks;
                $penalty_points *= 2 if $_contract->vul;
                $score_gained = 0;
            }
            else {             # doubled or redoubled
              if ($_contract->vul == 1) {  # vulnerable
                $penalty_points = 200;
                $penalty_points += 300*($_outcome->undertricks-1)
                     if $_outcome->undertricks >= 2;
                
              }
              else {           # non-vulnerable
                $penalty_points = 100;
                $penalty_points += 200 if $_outcome->undertricks >= 2;
                $penalty_points += 200 if $_outcome->undertricks >= 3;
                $penalty_points += 300*($_outcome->undertricks - 3)
                     if $_outcome->undertricks >= 4;
              }
              $penalty_points *= 2 if $_contract->dbl == 2; # if redoubled
            }
            return -$penalty_points
        }
    }


    BUILD {
        $_contract = $_outcome->contract;
    }


}



__END__
