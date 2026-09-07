# PROVENANCE:
#   [doc §4.10] / [doc §3.4]      -> drawn verbatim from the reference doc
#   [LoC - derived]               -> split from a real LoC Current record
#   (no token)                    -> constructed
#
# This file covers 254 (Musical Presentation Statement, §4.10) and 258
# (Philatelic Issue Data, §3.4). Both are simple single-key fields: $a N/A
# with one content subfield taking a separator.
#
# FIELD CHEAT-SHEET (LoC/PCC):
#   254: $r ' = ' (parallel musical presentation), $a N/A
#   258: $b ' : ' (denomination), $a N/A

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
for my $t ( qw(254 258) ) {
    ok( defined $R->{$t}, "$t rules defined" );
}
is( $R->{'254'}->{pchrs}->{r}, ' = ', '254 $r pchrs is " = "' );
is( $R->{'258'}->{pchrs}->{b}, ' : ', '258 $b pchrs is " : "' );

# =====================================================================
# 254 – Musical Presentation Statement (spec §4.10)
# $r ' = '. $a N/A.
# =====================================================================

# --- 254 ex 1 (doc §4.10) ---
# Doc: Current: 254 ## Jatszopartitura = Playing score.
{
    # render: [doc §4.10] 254 ## $a Jatszopartitura $r Playing score
    my $field = make_field( '254', ' ', ' ', a => 'Jatszopartitura', r => 'Playing score' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'254'}, 'postfix' );
    is( $result[1], 'Jatszopartitura = ', '254 ex1 postfix: $a gets " = " (for $r)' );
    is( $result[3], 'Playing score', '254 ex1 postfix: $r unchanged (last sf)' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'254'}, 'prefix' );
    is( $result_pr[1], 'Jatszopartitura', '254 ex1 prefix: $a unchanged' );
    is( $result_pr[3], ' = Playing score', '254 ex1 prefix: $r gets " = " prepended' );

    check_combined( \@result, \@result_pr, '254 ex1: combined string identical' );
}

# --- 254 edge: $a alone ---
{
    # render: 254 ## $a Full score
    my $field = make_field( '254', ' ', ' ', a => 'Full score' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'254'}, 'postfix' );
    is( $result[1], 'Full score', '254: $a alone unchanged' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'254'}, 'prefix' );
    is( $result_pr[1], 'Full score', '254 prefix: $a alone unchanged' );

    check_combined( \@result, \@result_pr, '254: combined string identical (just $a)' );
}

# --- 254 edge: two $r (parallel statements) ---
{
    # render: 254 ## $a Partitur $r Playing score $r Full score
    my $field = make_field( '254', ' ', ' ', a => 'Partitur', r => 'Playing score', r => 'Full score' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'254'}, 'postfix' );
    is( $result[1], 'Partitur = ', '254 two-$r postfix: $a gets " = " (for first $r)' );
    is( $result[3], 'Playing score = ', '254 two-$r postfix: first $r gets " = " (for second $r)' );
    is( $result[5], 'Full score', '254 two-$r postfix: second $r unchanged (last sf)' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'254'}, 'prefix' );
    is( $result_pr[1], 'Partitur', '254 two-$r prefix: $a unchanged' );
    is( $result_pr[3], ' = Playing score', '254 two-$r prefix: first $r gets " = " prepended' );
    is( $result_pr[5], ' = Full score', '254 two-$r prefix: second $r gets " = " prepended' );

    check_combined( \@result, \@result_pr, '254 two-$r: combined string identical' );
}

# =====================================================================
# 258 – Philatelic Issue Data (spec §3.4)
# $b ' : '. $a N/A.
# =====================================================================

# --- 258 ex 1 (doc §3.4) ---
# Doc: Current: 258 ## $a Newfoundland : $b 5 pence.
{
    # render: [doc §3.4] 258 ## $a Newfoundland $b 5 pence
    my $field = make_field( '258', ' ', ' ', a => 'Newfoundland', b => '5 pence' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'258'}, 'postfix' );
    is( $result[1], 'Newfoundland : ', '258 ex1 postfix: $a gets " : " (for $b)' );
    is( $result[3], '5 pence', '258 ex1 postfix: $b unchanged (last sf)' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'258'}, 'prefix' );
    is( $result_pr[1], 'Newfoundland', '258 ex1 prefix: $a unchanged' );
    is( $result_pr[3], ' : 5 pence', '258 ex1 prefix: $b gets " : " prepended' );

    check_combined( \@result, \@result_pr, '258 ex1: combined string identical' );
}

# --- 258 LoC-derived: $a + $b with internal commas (boundary) ---
# LoC Current: 258 ## $a Canada : $b 1 cent, 5 cents, 10 cents.
{
    # render: [LoC - derived] 258 ## $a Canada $b 1 cent, 5 cents, 10 cents
    my $field = make_field( '258', ' ', ' ', a => 'Canada', b => '1 cent, 5 cents, 10 cents' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'258'}, 'postfix' );
    is( $result[1], 'Canada : ', '258 LoC postfix: $a gets " : " (for $b)' );
    is( $result[3], '1 cent, 5 cents, 10 cents',
        '258 LoC postfix: $b unchanged — internal commas NOT split' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'258'}, 'prefix' );
    is( $result_pr[1], 'Canada', '258 LoC prefix: $a unchanged' );
    is( $result_pr[3], ' : 1 cent, 5 cents, 10 cents',
        '258 LoC prefix: $b gets " : " prepended, internal commas intact' );

    check_combined( \@result, \@result_pr, '258 LoC: combined string identical' );
}

# --- 258 edge: $a alone ---
{
    # render: 258 ## $a Newfoundland
    my $field = make_field( '258', ' ', ' ', a => 'Newfoundland' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'258'}, 'postfix' );
    is( $result[1], 'Newfoundland', '258: $a alone unchanged' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'258'}, 'prefix' );
    is( $result_pr[1], 'Newfoundland', '258 prefix: $a alone unchanged' );

    check_combined( \@result, \@result_pr, '258: combined string identical (just $a)' );
}

# --- 258 edge: numeric $b ---
{
    # render: 258 ## $a Nippon $b 120
    my $field = make_field( '258', ' ', ' ', a => 'Nippon', b => '120' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'258'}, 'postfix' );
    is( $result[1], 'Nippon : ', '258 numeric-$b postfix: $a gets " : " (for $b)' );
    is( $result[3], '120', '258 numeric-$b postfix: $b unchanged (last sf)' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'258'}, 'prefix' );
    is( $result_pr[1], 'Nippon', '258 numeric-$b prefix: $a unchanged' );
    is( $result_pr[3], ' : 120', '258 numeric-$b prefix: $b gets " : " prepended' );

    check_combined( \@result, \@result_pr, '258 numeric-$b: combined string identical' );
}

done_testing();
