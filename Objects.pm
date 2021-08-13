use Object::Pad 0.51;
use Object::Pad::SlotAttr::Isa;

package Games::Cards::Bridge::Objects;

# For the contract part,
# a port using Object::Pad of Games::Cards::Bridge::Contract
# originally written by David Westbrook

# get inspired by Games::Cards::Card (written by Amir Karger) as well

class Player {
    has $char :reader :param = undef;
    has $fullname :reader :param = undef;
    has $side_name :reader :param = undef;
    has $custom_name :reader :param = undef;
    has $partner_fullname :reader :param = undef;
    has $partner_char :reader :param = undef;

    BUILD {
        if ($char) {
            $char = uc $char;
        }
        if ($char && !defined($fullname)) {
            $fullname = "North" if $char eq "N";
            $fullname = "East"  if $char eq "E";
            $fullname = "South" if $char eq "S";
            $fullname = "West"  if $char eq "W";
        }
        if ($fullname && !defined($char)) {
            $char = uc substr($fullname,0,1);
        } 

        warn "Fail to identify the player side\n" if !defined($fullname) || !defined($char); 

#         set side
        $side_name = $char =~ m/^[NS]$/ ? "NS side" : "EW side";

        $partner_fullname = "South" if $char eq "N";
        $partner_fullname = "North" if $char eq "S";
        $partner_fullname = "West"  if $char eq "E";
        $partner_fullname = "East"  if $char eq "W";
        $partner_char = substr($partner_fullname,0,1);

#    The following codes cause infinite loop;
#    return "Segmentation fault (core dumped)"
#        $partner = Player->new(char=>"S") if $char eq "N";
#        $partner = Player->new(char=>"N") if $char eq "S";
#        $partner = Player->new(char=>"E") if $char eq "W";
#        $partner = Player->new(char=>"W") if $char eq "E";
    }
}



class Suit {
    has $char :reader :param = undef;
    has $name :reader :param = undef;
    has $fullname :reader :param = undef;
    has $minor :reader :param = undef;     # 0 or 1
    has $major :reader :param = undef;     # 0 or 1
    has $notrump :reader :param = undef;     # 0 or 1

    method is_minor {
        return $minor = ($char =~ m/^[CD]$/);
    }

    method is_major {
        return $major = ($char =~ m/^[HS]$/);
    }

    method is_notrump {
        return $notrump = ($char eq "N");
    }

    BUILD {
        if ($char) {
            $char = uc $char;
        }
        if ($name) {
            $name = uc $name;
        }
        if ($char && !defined($name)) {
            $name = "NT" if $char eq "N";
            $name = "S"  if $char eq "S";
            $name = "H" if $char eq "H";
            $name = "D"  if $char eq "D";
            $name = "C"  if $char eq "C";
        }
        if ($name && !defined($char)) {
            $char = "N" if $name eq "NT";
            $char = "S" if $name eq "S";
            $char = "H" if $name eq "H";
            $char = "D" if $name eq "D";
            $char = "C" if $name eq "C";
        } 

        warn "Fail to identify the suit.\n" 
          if !defined($char) || !defined($name); 

        $fullname = "No trump" if $name eq "NT";
        $fullname = "Spade"  if $name eq "S";
        $fullname = "Heart" if $name eq "H";
        $fullname = "Diamond"  if $name eq "D";
        $fullname = "Club"  if $name eq "C";

        $self->is_minor();
        $self->is_major();
        $self->is_notrump();
    }
}



class Contract {
    has $declarer :param :Isa(Player) = undef;   # N,E,S,W
    has $trumpsuit :reader :param :Isa(Suit);     # C,D,H,S,N,NT
    has $pass :reader :param = undef;  # 0 or 1
    has $bid_finalized :param = undef; # 1..7
    has $vul :reader :param = undef ;      # 0 or 1
    has $dbl :reader :param = undef; # 0->none 1->X  2->XX
    has $small_slam :reader :param = undef;     # 0 or 1
    has $grand_slam :reader :param = undef;     # 0 or 1
    has $game :reader :param = undef;           # 0 or 1


    method is_small_slam {
        return $small_slam = ($bid_finalized == 6);
    }

    method is_grand_slam {
        return $grand_slam = ($bid_finalized == 7);
    }

    method is_game {
        return $game = 
             ($trumpsuit->notrump && $bid_finalized >= 3)
          || ($trumpsuit->minor && $bid_finalized >= 5)
          || ($trumpsuit->major && $bid_finalized >= 4)
    }

    method get_bid {
        return $bid_finalized;
    }

    method describe {
        if ($pass) {
            return "Pass.";
        }
        my $vulnerable = $vul ? "vulnerable" : "non-vulnerable";
        my $double_str = $dbl == 0 ? "" : ", ";
        $double_str .= "doubled" if $dbl == 1;
        $double_str .= "redoubled" if $dbl == 2;

        return  $declarer->side_name .": "
               .$bid_finalized .$trumpsuit->name .", "
               .$vulnerable .$double_str ."; "
               ."declarer: " .$declarer->fullname ."; "
               ."dummy: " .$declarer->partner_fullname .".";

        # NS side: 3NT, vulnerable; declarer: South; dummy: North.
    }

    method _validate {

    }


    BUILD {
        $self->_validate();
        if (!$pass) {
            $self->is_small_slam();
            $self->is_grand_slam();
            $self->is_game();
        }
    }
}
