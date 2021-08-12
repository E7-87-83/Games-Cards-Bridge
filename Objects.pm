use Object::Pad 0.51;
use Object::Pad::SlotAttr::Isa;

package Games::Cards::Bridge::Objects;

# For the contract part,
# a port using Object::Pad of Games::Cards::Bridge::Contract
# originally written by David Westbrook

class Contract {
    has $declarer :param;   # N,E,S,W
    has $trump :reader :param;      # C,D,H,S,N,P
    has $bid_finalized :param = undef; # 1..7
    has $vul :reader :param = undef ;      # 0 or 1
    has $dbl :reader :param = undef; # 0->none 1->X  2->XX
    has $minor :reader :param = undef;     # 0 or 1
    has $major :reader :param = undef;     # 0 or 1
    has $notrump :reader :param = undef;     # 0 or 1
    has $small_slam :reader :param = undef;     # 0 or 1
    has $grand_slam :reader :param = undef;     # 0 or 1
    has $game :reader :param = undef;           # 0 or 1

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
             ($trump eq "N" && $bid_finalized >= 3)
          || ($trump eq "C" && $bid_finalized >= 5)
          || ($trump eq "D" && $bid_finalized >= 5)
          || ($trump eq "H" && $bid_finalized >= 4)
          || ($trump eq "S" && $bid_finalized >= 4);
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
