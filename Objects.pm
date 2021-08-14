use Object::Pad 0.51;
use Object::Pad::SlotAttr::Isa;
use experimental 'signatures', 'switch';
use Carp;
use v5.10.0;
package Games::Cards::Bridge::Objects;

# For the contract part,
# a port using Object::Pad of Games::Cards::Bridge::Contract
# originally written by David Westbrook

# get inspired by Games::Cards::Card (written by Amir Karger) as well

#sub legal_card_name {
#}

sub legal_contract_name ($c){
    return 1 
      if     $c =~ /^[1-7][SHDCN][x]{0,2}$/ 
          || $c =~ /^[1-7]NT[x]{0,2}$/     ;
    carp("Cannot identify this contract: $c\n");
}


sub _get_suit_char ($c) {
    my $char = substr($c, -1, 1);
    return $char if $char =~ /^[SHDC]$/;
    carp("Cannot get the suit of $c\n");
}


sub _get_num ($c) {
    return substr($c, 0, 1) 
      if $c =~ /^[2-9][SHDC]$/ || $c =~ /^[AKQJT][SHDC]$/;
    return "T" if $c =~ /^10[SHDC]$/;
    carp("Cannot get the card number of $c\n");
}


# ========== BEGIN: card actions =================
sub trick_winner {
}

sub is_trumpsuit {
}


# ========== END: card actions ===================

class Pile {
    has $set_of_cards :reader :param;
    has $trumpsuit :reader :param :Isa(Suit);
    has $suit_order :param = undef;

    method _suit_sort {
        given($trumpsuit->char) {
            when ("S") {
                 $suit_order = {"S" => 0, "H" => 1,
                                "D" => 2, "C" => 3};
            }
            when ("H") {
                 $suit_order = {"H" => 0, "S" => 1,
                                "D" => 2, "C" => 3};
            }
            when ("D") {
                 $suit_order = {"D" => 0, "S" => 1,
                                "H" => 2, "C" => 3};
            }
            when ("C") {
                 $suit_order = {"C" => 0, "H" => 1,
                                "S" => 2, "D" => 3};
            }
            default {
                 $suit_order = {"S" => 0, "H" => 1,
                                "C" => 2, "D" => 3}; 
            }
        }
    }

    method sort_trump_first {
        my %ord_suit = $suit_order->%*;
        my $card_order = [ "A" , "K", "Q", "J", "T", reverse 2..9];
        my %ord_num;
        $ord_num{ $card_order->[$_] } = $_ for (0..$card_order->$#*);

        $set_of_cards->@* = (sort {
          $ord_suit{_get_suit($a)} <=> $ord_suit{_get_suit($b)}
                                  ||
          $ord_num{_get_num($a)} <=> $ord_num{_get_num($b)};
        } $set_of_cards->@*);
        return @{$set_of_cards};
    }

    method sort_regular {
        my %ord_suit = ("S" => 0, "H" => 1,
                        "C" => 2, "D" => 3); 
        my $card_order = [ "A" , "K", "Q", "J", "T", reverse 2..9];
        my %ord_num;
        $ord_num{ $card_order->[$_] } = $_ for (0..$card_order->$#*);

        $set_of_cards->@* = (sort{
          $ord_suit{_get_suit($a)} <=> $ord_suit{_get_suit($b)}
                              ||
          $ord_num{_get_num($a)} <=> $ord_num{_get_num($b)};
         } $set_of_cards->@*);
        return @{$set_of_cards};
    }

    method sort_trump_first_singlecolour {
        my @normal_suits = qw/S H D C/;
        my %ord_suit;
        my @ord_suit_helper;
        my $card_order = [ "A" , "K", "Q", "J", "T", reverse 2..9];
        my %ord_num;
        $ord_num{ $card_order->[$_] } = $_ for (0..$card_order->$#*);

        if ($trumpsuit->char ne "N") {
            @ord_suit_helper = (
                $trumpsuit->char, 
                grep { $_ ne $trumpsuit->char} qw/S H D C/
            );
        }
        else {
            @ord_suit_helper = [qw/S H D C/];
        }
        $ord_suit{ $ord_suit_helper[$_] } = $_ for (0..$#ord_suit_helper);
        $set_of_cards->@* = (sort{
          $ord_suit{_get_suit($a)} <=> $ord_suit{_get_suit($b)}
                                  ||
          $ord_num{_get_num($a)} <=> $ord_num{_get_num($b)};
        } $set_of_cards->@*);
        return @{$set_of_cards}
    }

    method card_leave_pile {
        my $card;
        return $card;
    }

    BUILD {
        $self->_suit_sort();
    }
}

class Player {
    has $char :reader :param = undef;
    has $fullname :reader :param = undef;
    has $side_name :reader :param = undef;
    has $custom_name :reader :param = undef;
    has $partner_fullname :reader :param = undef;
    has $partner_char :reader :param = undef;
    has $next_char :reader :param = undef;

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

        $next_char = "E" if $char eq "N";
        $next_char = "S"  if $char eq "E";
        $next_char = "W" if $char eq "S";
        $next_char = "N"  if $char eq "W";

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
        return 1;            #to be written
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


__END__
