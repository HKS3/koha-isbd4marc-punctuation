# PROVENANCE:
#   [doc §3.1] / [doc §3.3]       -> drawn verbatim from the reference doc
#   [LoC - derived]               -> split from a real LoC Current record
#   (no token)                    -> constructed
#
# This file covers 015 (National Bibliography Number, §3.1) and 024 (Other
# Standard Identifier, §3.3). Both share the 020 shape for $q: a repeatable
# qualifying-information subfield wrapped in ONE paren pair with ' ; '
# separators (shared _decorate_qualifier_group_pre). 024 additionally has
# $c -> ' : ' (terms of availability).
#
# FIELD CHEAT-SHEET (LoC/PCC):
#   015: $q group ( ; ) via cb_pre, $a/$z N/A (no $c)
#   024: $c ' : ', $q group ( ; ) via cb_pre, $a/$d/$z N/A
#
# NOTE: rule-key subscripts must QUOTE numeric tags with a leading zero
# ('015'/'024') — a bare {015}/{024} is parsed as octal by Perl.

use strict;
use warnings;
use lib 't/lib';
use Koha::RecordProcessor::Base;
use t::lib::TestHelper qw(make_field combined_string check_combined);

use Test::More;
use Koha::Filter::MARC::ISBD4MARCPunctuation;

# The rule set this test targets.
my $SET = 'LoC/PCC';
note( "Rule set under test: $SET" );

my $R = Koha::Filter::MARC::ISBD4MARCPunctuation::rules_for($SET);

# --- both fields are defined ---
for my $t ( qw(015 024) ) {
    ok( defined $R->{$t}, "$t rules defined" );
}
ok( exists $R->{'024'}->{pchrs}->{c}, '024 defines $c -> " : "' );
is( $R->{'024'}->{pchrs}->{c}, ' : ', '024 $c pchrs is " : "' );
ok( exists $R->{'015'}->{cb_pre}, '015 defines a $q group cb_pre' );
ok( exists $R->{'024'}->{cb_pre}, '024 defines a $q group cb_pre' );

# =====================================================================
# 015 – National Bibliography Number (spec §3.1)
# $q wrapped in ONE paren pair, multiple $q separated by ' ; '. $a/$z N/A.
# =====================================================================

# --- 015 ex 1 (doc §3.1), $q single + $2 source ---
# Doc: Current: 015 ## $a GB6720988 $q (pbk.) $2 bnb
{
    # render: [doc §3.1] 015 ## $a GB6720988 $q pbk. $2 bnb
    my $field = make_field( '015', ' ', ' ', a => 'GB6720988', q => 'pbk.', b => '' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'015'}, 'postfix' );
    is( $result[1], 'GB6720988', '015 ex1 postfix: $a unchanged' );
    is( $result[3], '(pbk.)', '015 ex1 postfix: $q wrapped in ()' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'015'}, 'prefix' );
    is( $result_pr[1], 'GB6720988', '015 ex1 prefix: $a unchanged' );
    is( $result_pr[3], '(pbk.)', '015 ex1 prefix: $q wrapped in ()' );

    check_combined( \@result, \@result_pr, '015 ex1: combined string identical' );
}

# --- 015 ex 2 (doc §3.1) ---
# Doc: Current: 015 ## $a 06709455 $q (v. 2) $2 bnf
{
    # render: [doc §3.1] 015 ## $a 06709455 $q v. 2
    my $field = make_field( '015', ' ', ' ', a => '06709455', q => 'v. 2' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'015'}, 'postfix' );
    is( $result[1], '06709455', '015 ex2 postfix: $a unchanged' );
    is( $result[3], '(v. 2)', '015 ex2 postfix: $q wrapped in ()' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'015'}, 'prefix' );
    is( $result_pr[1], '06709455', '015 ex2 prefix: $a unchanged' );
    is( $result_pr[3], '(v. 2)', '015 ex2 prefix: $q wrapped in ()' );

    check_combined( \@result, \@result_pr, '015 ex2: combined string identical' );
}

# --- 015 edge: $a alone ---
{
    # render: 015 ## $a GB6720988
    my $field = make_field( '015', ' ', ' ', a => 'GB6720988' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'015'}, 'postfix' );
    is( $result[1], 'GB6720988', '015: $a alone unchanged' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'015'}, 'prefix' );
    is( $result_pr[1], 'GB6720988', '015 prefix: $a alone unchanged' );

    check_combined( \@result, \@result_pr, '015: combined string identical (just $a)' );
}

# --- 015 edge: two $q in one group ---
{
    # render: 015 ## $a 06709455 $q v. 2 $q pbk.
    my $field = make_field( '015', ' ', ' ', a => '06709455', q => 'v. 2', q => 'pbk.' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'015'}, 'postfix' );
    is( $result[1], '06709455', '015 multi-$q postfix: $a unchanged' );
    is( $result[3], '(v. 2', '015 multi-$q postfix: first $q opens paren' );
    is( $result[5], ' ; pbk.)', '015 multi-$q postfix: second $q gets " ; " + close paren' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'015'}, 'prefix' );
    is( $result_pr[1], '06709455', '015 multi-$q prefix: $a unchanged' );
    is( $result_pr[3], '(v. 2', '015 multi-$q prefix: first $q opens paren' );
    is( $result_pr[5], ' ; pbk.)', '015 multi-$q prefix: second $q gets " ; " + close paren' );

    check_combined( \@result, \@result_pr, '015 multi-$q: combined string identical' );
}

# --- 015 edge: $z (canceled/invalid) N/A pass-through ---
{
    # render: 015 ## $a 06709455 $z 9999999
    my $field = make_field( '015', ' ', ' ', a => '06709455', z => '9999999' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'015'}, 'postfix' );
    is( $result[1], '06709455', '015 $z postfix: $a unchanged' );
    is( $result[3], '9999999', '015 $z postfix: $z (N/A) passes through' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'015'}, 'prefix' );
    is( $result_pr[1], '06709455', '015 $z prefix: $a unchanged' );
    is( $result_pr[3], '9999999', '015 $z prefix: $z (N/A) passes through' );

    check_combined( \@result, \@result_pr, '015 $z: combined string identical' );
}

# =====================================================================
# 024 – Other Standard Identifier (spec §3.3)
# $c ' : '; $q wrapped in ONE paren pair (multiple $q separated by ' ; ');
# $a/$d/$z N/A.
# =====================================================================

# --- 024 ex 1 (doc §3.3) ---
# Doc: Current: 024 1# $a 090266842629 $q (v. 4)
{
    # render: [doc §3.3] 024 1# $a 090266842629 $q v. 4
    my $field = make_field( '024', '1', '#', a => '090266842629', q => 'v. 4' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'024'}, 'postfix' );
    is( $result[1], '090266842629', '024 ex1 postfix: $a unchanged' );
    is( $result[3], '(v. 4)', '024 ex1 postfix: $q wrapped in ()' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'024'}, 'prefix' );
    is( $result_pr[1], '090266842629', '024 ex1 prefix: $a unchanged' );
    is( $result_pr[3], '(v. 4)', '024 ex1 prefix: $q wrapped in ()' );

    check_combined( \@result, \@result_pr, '024 ex1: combined string identical' );
}

# --- 024 LoC-derived: $a + $q + $q + $c (multi-$q group + terms) ---
# LoC Current: 024 2# $a M570406203 $q (score ; sewn) : $c EUR28.50
{
    # render: [LoC - derived] 024 2# $a M570406203 $q score $q sewn $c EUR28.50
    my $field = make_field( '024', '2', '#', a => 'M570406203', q => 'score', q => 'sewn', c => 'EUR28.50' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'024'}, 'postfix' );
    is( $result[1], 'M570406203', '024 LoC multi-$q+$c postfix: $a unchanged' );
    is( $result[3], '(score', '024 LoC multi-$q+$c postfix: first $q opens paren' );
    is( $result[5], ' ; sewn) : ',
        '024 LoC multi-$q+$c postfix: second $q gets " ; " + close paren + " : " for $c' );
    is( $result[7], 'EUR28.50', '024 LoC multi-$q+$c postfix: $c unchanged (last sf)' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'024'}, 'prefix' );
    is( $result_pr[1], 'M570406203', '024 LoC multi-$q+$c prefix: $a unchanged' );
    is( $result_pr[3], '(score', '024 LoC multi-$q+$c prefix: first $q opens paren' );
    is( $result_pr[5], ' ; sewn)',
        '024 LoC multi-$q+$c prefix: second $q gets " ; " + close paren' );
    is( $result_pr[7], ' : EUR28.50',
        '024 LoC multi-$q+$c prefix: $c gets " : " prepended' );

    check_combined( \@result, \@result_pr, '024 LoC multi-$q+$c: combined string identical' );
}

# --- 024 LoC-derived: $a + $q + $q (multi-$q group, no $c) ---
# LoC Current: 024 2# $a M570406210 $q (parts ; sewn)
{
    # render: [LoC - derived] 024 2# $a M570406210 $q parts $q sewn
    my $field = make_field( '024', '2', '#', a => 'M570406210', q => 'parts', q => 'sewn' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'024'}, 'postfix' );
    is( $result[1], 'M570406210', '024 LoC multi-$q postfix: $a unchanged' );
    is( $result[3], '(parts', '024 LoC multi-$q postfix: first $q opens paren' );
    is( $result[5], ' ; sewn)', '024 LoC multi-$q postfix: second $q gets " ; " + close paren' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'024'}, 'prefix' );
    is( $result_pr[1], 'M570406210', '024 LoC multi-$q prefix: $a unchanged' );
    is( $result_pr[3], '(parts', '024 LoC multi-$q prefix: first $q opens paren' );
    is( $result_pr[5], ' ; sewn)', '024 LoC multi-$q prefix: second $q gets " ; " + close paren' );

    check_combined( \@result, \@result_pr, '024 LoC multi-$q: combined string identical' );
}

# --- 024 LoC-derived: $a + $c only (terms, no $q) ---
# LoC Current: 024 2# $a M571100511 : $c $20.00
{
    # render: [LoC - derived] 024 2# $a M571100511 $c \$20.00
    my $field = make_field( '024', '2', '#', a => 'M571100511', c => '$20.00' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'024'}, 'postfix' );
    is( $result[1], 'M571100511 : ', '024 LoC $c-only postfix: $a gets " : " (for following $c)' );
    is( $result[3], '$20.00', '024 LoC $c-only postfix: $c unchanged (last sf)' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'024'}, 'prefix' );
    is( $result_pr[1], 'M571100511', '024 LoC $c-only prefix: $a unchanged' );
    is( $result_pr[3], ' : $20.00', '024 LoC $c-only prefix: $c gets " : " prepended' );

    check_combined( \@result, \@result_pr, '024 LoC $c-only: combined string identical' );
}

# --- 024 edge: $a alone ---
{
    # render: 024 1# $a 090266842629
    my $field = make_field( '024', '1', '#', a => '090266842629' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'024'}, 'postfix' );
    is( $result[1], '090266842629', '024: $a alone unchanged' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'024'}, 'prefix' );
    is( $result_pr[1], '090266842629', '024 prefix: $a alone unchanged' );

    check_combined( \@result, \@result_pr, '024: combined string identical (just $a)' );
}

# --- 024 edge: $z (canceled/invalid) N/A pass-through ---
{
    # render: 024 1# $a 6428759268 $z 5539143515
    my $field = make_field( '024', '1', '#', a => '6428759268', z => '5539143515' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'024'}, 'postfix' );
    is( $result[1], '6428759268', '024 $z postfix: $a unchanged' );
    is( $result[3], '5539143515', '024 $z postfix: $z (N/A) passes through' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'024'}, 'prefix' );
    is( $result_pr[1], '6428759268', '024 $z prefix: $a unchanged' );
    is( $result_pr[3], '5539143515', '024 $z prefix: $z (N/A) passes through' );

    check_combined( \@result, \@result_pr, '024 $z: combined string identical' );
}

done_testing();
