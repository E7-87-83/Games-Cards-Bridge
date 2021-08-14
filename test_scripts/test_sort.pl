use Games::Cards::Bridge::Objects;
use strict;
use warnings;
use v5.10.0;

my $hand = Pile->new(
    set_of_cards=>
      [qw/4S 7S AS 2S 3H TS 9S 4H AH 5C TH 6D 6C/ ] ,
    trumpsuit => Suit->new(char=>"C")
);

say $hand->sort_trump_first();
say $hand->sort_regular();
say $hand->sort_trump_first_singlecolour;

# 6C5CAHTH4H3HASTS9S7S4S2S6D
# ASTS9S7S4S2SAHTH4H3H6C5C6D
# 6C5CASTS9S7S4S2SAHTH4H3H6D

