use Object::Pad 0.51;
use Object::Pad::SlotAttr::Isa;
use experimental 'signatures', 'switch';
use Carp;
use v5.10.0;
use Games::Cards::Bridge::Objects;
package Games::Cards::Bridge::Bidding;

class Auction {
    has $dealer :reader :param :Isa(Player);
    has $player_N :reader :param :Isa(Player);
    has $player_S :reader :param :Isa(Player);
    has $player_E :reader :param :Isa(Player);
    has $player_W :reader :param :Isa(Player);
    has $vul_NS :reader :param;
    has $vul_EW :reader :param;
    has $num_of_calls :reader :param = undef;
    has $process :reader :param = undef;
    has $contract :reader :param :Isa(Contract) = undef;
    has $contract_temp :reader :param = undef;

    method is_legitimate {
    }

    method is_completed {
        if (   $process->is_legitimate() 
            && $process->[-3] eq "P"
            && $process->[-2] eq "P"
            && $process->[-1] eq "P") 
        {
            set_contract_obj();
            return 1
        }
        else {
            return 0;
        }
    }

    method which_char_to_call_next {
    }

    method _is_valid_contract {
    }

    method _cmp_contract {
        my $new_call = $_[0];
        my $pre_call = $_[1];
        return 0 if $new_call !~ /^[1-7](NT|[SHDCN])$/;
        my %suit_weight = ('N' => 5, 'S' => 4, 'H' => 3, 'D' => 2, 'C' => 1 );
        if (substr($new_call,0,1) > substr($pre_call,0,1)) {
            return 1;
        }
        else {
            if ( 
                   substr($new_call,0,1) == substr($pre_call,0,1) 
                 &&   $suit_weight{substr($new_call,1,1)} 
                    > $suit_weight{substr($pre_call,1,1)}
               )
            {
                return 1;
            }
        }
        return 0;
    }

    method call {
        my $c = $_[0];
        given($c) {
            when ("P") {
                push $process->@*, $c;
                $num_of_calls++;
                is_completed();
            }
            when (/^[1-7](NT|[SHDCN])$/) {
                if ( _cmp_contract($c , $contract_temp) ) {
                    $contract_temp = $c;
                    push $process->@*, $c;
                    $num_of_calls++;
                }
                else {
                    carp("$c: Weaker than the previous bid\n");
                }
            }
            when ("X") {
                if  (
                       defined($contract_temp)
                     &&  (    $contract_temp eq $process->[-1]
                           || ($process->$#* >= 2 && $contract_temp eq $process->[-3])  
                         )
                     && substr($contract_temp, -1, 1) ne "x"
                    )
                {
                    $contract_temp .= "x";
                    push $process->@*, $c;
                    $num_of_calls++;
                }
                else {
                    carp("Invalid Double request\n");
                }
            }
            when ("XX") {
                if ( 
                         ( defined($contract_temp) )
                      && ( substr($contract_temp,-1,1) eq "x" )
                      && ("X" eq $process->[-1] || "X" eq $process->[-3])  
                   ) 
                {
                    $contract_temp .= "x";
                    push $process->@*, $c;
                    $num_of_calls++;
                }
                else {
                    carp("Invalid Redouble request\n");
                }
            }
            default {
                carp("Unidentified call: $c\n");
            }
        }
    }

    method set_contract_obj {
        if (!$self->completed) {
            carp("Haven't completed bidding\n");
            return 0;
        }
        my $dbl = 0;
        $dbl = 1 if $contract_temp =~ m/x$/;
        $dbl = 2 if $contract_temp =~ m/xx$/;
     #  completed  return $contract = Contract->new(declarer=>, dbl=>$dbl, blah blah blah) ;   TO BE WRITTEN
    }

    BUILD {
        $num_of_calls = scalar $process->@*;
        #similar to call , but process $process    TO BE WRITTEN
    } 

}
