# PROVENANCE:
#   [doc §3.5] / [doc §3.6] / [doc §3.7] -> drawn verbatim from the reference doc
#   [LoC - derived]               -> split from a real LoC Current record
#   (no token)                    -> constructed
#
# This file covers 307 (Hours, §3.5), 343 (Planar Coordinate Data, §3.6) and
# 351 (Organization and Arrangement of Materials, §3.7). All three are
# simple '; ' single-key separator fields on their content subfields.
#
# FIELD CHEAT-SHEET (LoC/PCC):
#   307: $b '; ', $a N/A
#   343: $b-$i each '; ', $a N/A
#   351: $a/$b '; ', $c N/A (the separator also fires after a N/A $c)

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

# --- all three fields are defined ---
for my $t ( qw(307 343 351) ) {
    ok( defined $R->{$t}, "$t rules defined" );
}
is( $R->{'307'}->{pchrs}->{b}, '; ', '307 $b pchrs is "; "' );
is( $R->{'343'}->{pchrs}->{i}, '; ', '343 $i pchrs is "; "' );
is( $R->{'351'}->{pchrs}->{a}, '; ', '351 $a pchrs is "; "' );
is( $R->{'351'}->{pchrs}->{b}, '; ', '351 $b pchrs is "; "' );

# =====================================================================
# 307 – Hours, etc. (spec §3.5)
# $b '; '. $a N/A (its internal ';' separators are data, not split).
# =====================================================================

# --- 307 ex 1 (doc §3.5) ---
# Doc: Current: 307 ## $a M, 8:30-6:00; Tu, 8:30-7:00; W-F, 8:30-6:00; $b not available on weekends.
{
    # render: [doc §3.5] 307 ## $a M, 8:30-6:00; Tu, 8:30-7:00; W-F, 8:30-6:00 $b not available on weekends
    my $field = make_field( '307', ' ', ' ', a => 'M, 8:30-6:00; Tu, 8:30-7:00; W-F, 8:30-6:00', b => 'not available on weekends' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'307'}, 'postfix' );
    is( $result[1], 'M, 8:30-6:00; Tu, 8:30-7:00; W-F, 8:30-6:00; ',
        '307 ex1 postfix: $a kept (internal ";" as data) and gets "; " for $b' );
    is( $result[3], 'not available on weekends', '307 ex1 postfix: $b unchanged (last sf)' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'307'}, 'prefix' );
    is( $result_pr[1], 'M, 8:30-6:00; Tu, 8:30-7:00; W-F, 8:30-6:00',
        '307 ex1 prefix: $a unchanged' );
    is( $result_pr[3], '; not available on weekends',
        '307 ex1 prefix: $b gets "; " prepended' );

    check_combined( \@result, \@result_pr, '307 ex1: combined string identical' );
}

# --- 307 ex 2 (doc §3.5) ---
# Doc: Current: 307 ## $a M-F, 6:30am-9:00pm (EST); $b with brief interruptions for periodic update/backup of data.
{
    # render: [doc §3.5] 307 ## $a M-F, 6:30am-9:00pm (EST) $b with brief interruptions for periodic update/backup of data
    my $field = make_field( '307', ' ', ' ', a => 'M-F, 6:30am-9:00pm (EST)', b => 'with brief interruptions for periodic update/backup of data' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'307'}, 'postfix' );
    is( $result[1], 'M-F, 6:30am-9:00pm (EST); ',
        '307 ex2 postfix: $a kept and gets "; " for $b' );
    is( $result[3], 'with brief interruptions for periodic update/backup of data',
        '307 ex2 postfix: $b unchanged (last sf)' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'307'}, 'prefix' );
    is( $result_pr[1], 'M-F, 6:30am-9:00pm (EST)', '307 ex2 prefix: $a unchanged' );
    is( $result_pr[3], '; with brief interruptions for periodic update/backup of data',
        '307 ex2 prefix: $b gets "; " prepended' );

    check_combined( \@result, \@result_pr, '307 ex2: combined string identical' );
}

# --- 307 ex 3 (doc §3.5) ---
# Doc: Current: 307 ## $a Daily, 7am-7pm; $b text files only.
{
    # render: [doc §3.5] 307 ## $a Daily, 7am-7pm $b text files only
    my $field = make_field( '307', ' ', ' ', a => 'Daily, 7am-7pm', b => 'text files only' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'307'}, 'postfix' );
    is( $result[1], 'Daily, 7am-7pm; ', '307 ex3 postfix: $a gets "; " (for $b)' );
    is( $result[3], 'text files only', '307 ex3 postfix: $b unchanged (last sf)' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'307'}, 'prefix' );
    is( $result_pr[1], 'Daily, 7am-7pm', '307 ex3 prefix: $a unchanged' );
    is( $result_pr[3], '; text files only', '307 ex3 prefix: $b gets "; " prepended' );

    check_combined( \@result, \@result_pr, '307 ex3: combined string identical' );
}

# --- 307 LoC-derived: $a-only with internal ";" (negative boundary) ---
# LoC Current: 307 ## $a Tu-F, 10-6; Sa, 1-5, USA PST.
{
    # render: [LoC - derived] 307 ## $a Tu-F, 10-6; Sa, 1-5, USA PST
    my $field = make_field( '307', ' ', ' ', a => 'Tu-F, 10-6; Sa, 1-5, USA PST' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'307'}, 'postfix' );
    is( $result[1], 'Tu-F, 10-6; Sa, 1-5, USA PST',
        '307 LoC $a-only postfix: internal ";" is data, NOT split (no $b)' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'307'}, 'prefix' );
    is( $result_pr[1], 'Tu-F, 10-6; Sa, 1-5, USA PST',
        '307 LoC $a-only prefix: unchanged' );

    check_combined( \@result, \@result_pr, '307 LoC $a-only: combined string identical' );
}

# --- 307 LoC-derived: real $a $b with heavy internal commas + literal ( ) ---
# LoC Current: 307 ## $a M-F, 6:30 AM to 9:30 PM, Sa, 8:00 AM to 5:00 PM, Su, 1:00 PM to 5:00 PM ; $b closed on national holidays (all times are EST or ESDT).
{
    # render: [LoC - derived] 307 ## $a M-F, 6:30 AM to 9:30 PM, Sa, 8:00 AM to 5:00 PM, Su, 1:00 PM to 5:00 PM $b closed on national holidays (all times are EST or ESDT)
    my $field = make_field( '307', ' ', ' ',
        a => 'M-F, 6:30 AM to 9:30 PM, Sa, 8:00 AM to 5:00 PM, Su, 1:00 PM to 5:00 PM',
        b => 'closed on national holidays (all times are EST or ESDT)' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'307'}, 'postfix' );
    is( $result[1], 'M-F, 6:30 AM to 9:30 PM, Sa, 8:00 AM to 5:00 PM, Su, 1:00 PM to 5:00 PM; ',
        '307 LoC real postfix: $a kept (internal commas as data) and gets "; " for $b' );
    is( $result[3], 'closed on national holidays (all times are EST or ESDT)',
        '307 LoC real postfix: $b unchanged, literal ( ) intact' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'307'}, 'prefix' );
    is( $result_pr[1], 'M-F, 6:30 AM to 9:30 PM, Sa, 8:00 AM to 5:00 PM, Su, 1:00 PM to 5:00 PM',
        '307 LoC real prefix: $a unchanged' );
    is( $result_pr[3], '; closed on national holidays (all times are EST or ESDT)',
        '307 LoC real prefix: $b gets "; " prepended, literal ( ) intact' );

    check_combined( \@result, \@result_pr, '307 LoC real: combined string identical' );
}

# =====================================================================
# 343 – Planar Coordinate Data (spec §3.6)
# $b-$i each '; '. $a N/A.
# =====================================================================

# --- 343 ex 1 (doc §3.6) ---
# Doc: Current: 343 ## $a Coordinate pair; $b meters; $c 22; $d 22.
{
    # render: [doc §3.6] 343 ## $a Coordinate pair $b meters $c 22 $d 22
    my $field = make_field( '343', ' ', ' ', a => 'Coordinate pair', b => 'meters', c => '22', d => '22' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'343'}, 'postfix' );
    is( $result[1], 'Coordinate pair; ', '343 ex1 postfix: $a gets "; " (for $b)' );
    is( $result[3], 'meters; ', '343 ex1 postfix: $b gets "; " (for $c)' );
    is( $result[5], '22; ', '343 ex1 postfix: $c gets "; " (for $d)' );
    is( $result[7], '22', '343 ex1 postfix: $d unchanged (last sf)' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'343'}, 'prefix' );
    is( $result_pr[1], 'Coordinate pair', '343 ex1 prefix: $a unchanged' );
    is( $result_pr[3], '; meters', '343 ex1 prefix: $b gets "; " prepended' );
    is( $result_pr[5], '; 22', '343 ex1 prefix: $c gets "; " prepended' );
    is( $result_pr[7], '; 22', '343 ex1 prefix: $d gets "; " prepended' );

    check_combined( \@result, \@result_pr, '343 ex1: combined string identical' );
}

# --- 343 ex 2 (doc §3.6) ---
# Doc: Current: 343 ## $a Coordinate pair; $e 30.0; $f 0.0001; $g Degrees, minutes and decimal seconds; $h North; $b U.S. feet.
{
    # render: [doc §3.6] 343 ## $a Coordinate pair $e 30.0 $f 0.0001 $g Degrees, minutes and decimal seconds $h North $b U.S. feet
    my $field = make_field( '343', ' ', ' ', a => 'Coordinate pair', e => '30.0', f => '0.0001', g => 'Degrees, minutes and decimal seconds', h => 'North', b => 'U.S. feet' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'343'}, 'postfix' );
    is( $result[1], 'Coordinate pair; ', '343 ex2 postfix: $a gets "; " (for $e)' );
    is( $result[3], '30.0; ', '343 ex2 postfix: $e gets "; " (for $f)' );
    is( $result[5], '0.0001; ', '343 ex2 postfix: $f gets "; " (for $g)' );
    is( $result[7], 'Degrees, minutes and decimal seconds; ',
        '343 ex2 postfix: $g gets "; " (for $h), internal commas as data' );
    is( $result[9], 'North; ', '343 ex2 postfix: $h gets "; " (for $b)' );
    is( $result[11], 'U.S. feet', '343 ex2 postfix: $b unchanged (last sf)' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'343'}, 'prefix' );
    is( $result_pr[1], 'Coordinate pair', '343 ex2 prefix: $a unchanged' );
    is( $result_pr[3], '; 30.0', '343 ex2 prefix: $e gets "; " prepended' );
    is( $result_pr[5], '; 0.0001', '343 ex2 prefix: $f gets "; " prepended' );
    is( $result_pr[7], '; Degrees, minutes and decimal seconds',
        '343 ex2 prefix: $g gets "; " prepended, internal commas intact' );
    is( $result_pr[9], '; North', '343 ex2 prefix: $h gets "; " prepended' );
    is( $result_pr[11], '; U.S. feet', '343 ex2 prefix: $b gets "; " prepended' );

    check_combined( \@result, \@result_pr, '343 ex2: combined string identical' );
}

# --- 343 ex 3 (doc §3.6) ---
# Doc: Current: 343 ## $a Coordinate pair; $c 3.224549805355; $d 3.224549805355; $f 0.0001; $b meters.
{
    # render: [doc §3.6] 343 ## $a Coordinate pair $c 3.224549805355 $d 3.224549805355 $f 0.0001 $b meters
    my $field = make_field( '343', ' ', ' ', a => 'Coordinate pair', c => '3.224549805355', d => '3.224549805355', f => '0.0001', b => 'meters' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'343'}, 'postfix' );
    is( $result[1], 'Coordinate pair; ', '343 ex3 postfix: $a gets "; " (for $c)' );
    is( $result[3], '3.224549805355; ', '343 ex3 postfix: $c gets "; " (for $d)' );
    is( $result[5], '3.224549805355; ', '343 ex3 postfix: $d gets "; " (for $f)' );
    is( $result[7], '0.0001; ', '343 ex3 postfix: $f gets "; " (for $b)' );
    is( $result[9], 'meters', '343 ex3 postfix: $b unchanged (last sf)' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'343'}, 'prefix' );
    is( $result_pr[1], 'Coordinate pair', '343 ex3 prefix: $a unchanged' );
    is( $result_pr[3], '; 3.224549805355', '343 ex3 prefix: $c gets "; " prepended' );
    is( $result_pr[5], '; 3.224549805355', '343 ex3 prefix: $d gets "; " prepended' );
    is( $result_pr[7], '; 0.0001', '343 ex3 prefix: $f gets "; " prepended' );
    is( $result_pr[9], '; meters', '343 ex3 prefix: $b gets "; " prepended' );

    check_combined( \@result, \@result_pr, '343 ex3: combined string identical' );
}

# --- 343 LoC-derived: lone $i (the $i grounding) ---
# LoC Current: 343 ## $i Magnetic.
{
    # render: [LoC - derived] 343 ## $i Magnetic
    my $field = make_field( '343', ' ', ' ', i => 'Magnetic' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'343'}, 'postfix' );
    is( $result[1], 'Magnetic', '343 LoC $i-alone postfix: no punct (lone keyed sf)' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'343'}, 'prefix' );
    is( $result_pr[1], 'Magnetic', '343 LoC $i-alone prefix: no punct' );

    check_combined( \@result, \@result_pr, '343 LoC $i-alone: combined string identical' );
}

# --- 343 LoC-derived: $a $e $f $g $b (no $h, $b at end) ---
# LoC Current: 343 ## $a Coordinate pair; $e 80.0; $f 0.0001; $g Degrees, minutes and decimal seconds; $b meters.
{
    # render: [LoC - derived] 343 ## $a Coordinate pair $e 80.0 $f 0.0001 $g Degrees, minutes and decimal seconds $b meters
    my $field = make_field( '343', ' ', ' ', a => 'Coordinate pair', e => '80.0', f => '0.0001', g => 'Degrees, minutes and decimal seconds', b => 'meters' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'343'}, 'postfix' );
    is( $result[1], 'Coordinate pair; ', '343 LoC no-$h postfix: $a gets "; " (for $e)' );
    is( $result[3], '80.0; ', '343 LoC no-$h postfix: $e gets "; " (for $f)' );
    is( $result[5], '0.0001; ', '343 LoC no-$h postfix: $f gets "; " (for $g)' );
    is( $result[7], 'Degrees, minutes and decimal seconds; ',
        '343 LoC no-$h postfix: $g gets "; " (for $b)' );
    is( $result[9], 'meters', '343 LoC no-$h postfix: $b unchanged (last sf)' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'343'}, 'prefix' );
    is( $result_pr[1], 'Coordinate pair', '343 LoC no-$h prefix: $a unchanged' );
    is( $result_pr[3], '; 80.0', '343 LoC no-$h prefix: $e gets "; " prepended' );
    is( $result_pr[5], '; 0.0001', '343 LoC no-$h prefix: $f gets "; " prepended' );
    is( $result_pr[7], '; Degrees, minutes and decimal seconds',
        '343 LoC no-$h prefix: $g gets "; " prepended' );
    is( $result_pr[9], '; meters', '343 LoC no-$h prefix: $b gets "; " prepended' );

    check_combined( \@result, \@result_pr, '343 LoC no-$h: combined string identical' );
}

# --- 343 LoC-derived: $a $c $d $h $b ($h without $e/$f/$g) ---
# LoC Current: 343 ## $a Coordinate pair; $c 0.001024; $d 0.001024; $h North; $b survey feet.
{
    # render: [LoC - derived] 343 ## $a Coordinate pair $c 0.001024 $d 0.001024 $h North $b survey feet
    my $field = make_field( '343', ' ', ' ', a => 'Coordinate pair', c => '0.001024', d => '0.001024', h => 'North', b => 'survey feet' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'343'}, 'postfix' );
    is( $result[1], 'Coordinate pair; ', '343 LoC $h-no-e/f/g postfix: $a gets "; " (for $c)' );
    is( $result[3], '0.001024; ', '343 LoC $h-no-e/f/g postfix: $c gets "; " (for $d)' );
    is( $result[5], '0.001024; ', '343 LoC $h-no-e/f/g postfix: $d gets "; " (for $h)' );
    is( $result[7], 'North; ', '343 LoC $h-no-e/f/g postfix: $h gets "; " (for $b)' );
    is( $result[9], 'survey feet', '343 LoC $h-no-e/f/g postfix: $b unchanged (last sf)' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'343'}, 'prefix' );
    is( $result_pr[1], 'Coordinate pair', '343 LoC $h-no-e/f/g prefix: $a unchanged' );
    is( $result_pr[3], '; 0.001024', '343 LoC $h-no-e/f/g prefix: $c gets "; " prepended' );
    is( $result_pr[5], '; 0.001024', '343 LoC $h-no-e/f/g prefix: $d gets "; " prepended' );
    is( $result_pr[7], '; North', '343 LoC $h-no-e/f/g prefix: $h gets "; " prepended' );
    is( $result_pr[9], '; survey feet', '343 LoC $h-no-e/f/g prefix: $b gets "; " prepended' );

    check_combined( \@result, \@result_pr, '343 LoC $h-no-e/f/g: combined string identical' );
}

# --- 343 LoC-derived: $a $c $d $b (lowercase $a, $c-$d-$b ordering) ---
# LoC Current: 343 ## $a coordinate pair; $c 0.01; $d 0.01; $b U.S. feet.
{
    # render: [LoC - derived] 343 ## $a coordinate pair $c 0.01 $d 0.01 $b U.S. feet
    my $field = make_field( '343', ' ', ' ', a => 'coordinate pair', c => '0.01', d => '0.01', b => 'U.S. feet' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'343'}, 'postfix' );
    is( $result[1], 'coordinate pair; ', '343 LoC $c-$d-$b postfix: $a gets "; " (for $c)' );
    is( $result[3], '0.01; ', '343 LoC $c-$d-$b postfix: $c gets "; " (for $d)' );
    is( $result[5], '0.01; ', '343 LoC $c-$d-$b postfix: $d gets "; " (for $b)' );
    is( $result[7], 'U.S. feet', '343 LoC $c-$d-$b postfix: $b unchanged (last sf)' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'343'}, 'prefix' );
    is( $result_pr[1], 'coordinate pair', '343 LoC $c-$d-$b prefix: $a unchanged' );
    is( $result_pr[3], '; 0.01', '343 LoC $c-$d-$b prefix: $c gets "; " prepended' );
    is( $result_pr[5], '; 0.01', '343 LoC $c-$d-$b prefix: $d gets "; " prepended' );
    is( $result_pr[7], '; U.S. feet', '343 LoC $c-$d-$b prefix: $b gets "; " prepended' );

    check_combined( \@result, \@result_pr, '343 LoC $c-$d-$b: combined string identical' );
}

# --- 343 edge: $a alone ---
{
    # render: 343 ## $a Coordinate pair
    my $field = make_field( '343', ' ', ' ', a => 'Coordinate pair' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'343'}, 'postfix' );
    is( $result[1], 'Coordinate pair', '343: $a alone unchanged' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'343'}, 'prefix' );
    is( $result_pr[1], 'Coordinate pair', '343 prefix: $a alone unchanged' );

    check_combined( \@result, \@result_pr, '343: combined string identical (just $a)' );
}

# =====================================================================
# 351 – Organization and Arrangement of Materials (spec §3.7)
# $a/$b '; '. $c N/A (separator still fires after a N/A $c).
# =====================================================================

# --- 351 ex 1 (doc §3.7) ---
# Doc: Current: 351 ## $a Hierarchical; $b Geographic area or cruise number.
{
    # render: [doc §3.7] 351 ## $a Hierarchical $b Geographic area or cruise number
    my $field = make_field( '351', ' ', ' ', a => 'Hierarchical', b => 'Geographic area or cruise number' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'351'}, 'postfix' );
    is( $result[1], 'Hierarchical; ', '351 ex1 postfix: $a gets "; " (for $b)' );
    is( $result[3], 'Geographic area or cruise number', '351 ex1 postfix: $b unchanged (last sf)' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'351'}, 'prefix' );
    is( $result_pr[1], 'Hierarchical', '351 ex1 prefix: $a unchanged' );
    is( $result_pr[3], '; Geographic area or cruise number', '351 ex1 prefix: $b gets "; " prepended' );

    check_combined( \@result, \@result_pr, '351 ex1: combined string identical' );
}

# --- 351 ex 2 (doc §3.7) ---
# Doc: Current: 351 ## $c Series; $b Alphabetical by sitter.
{
    # render: [doc §3.7] 351 ## $c Series $b Alphabetical by sitter
    my $field = make_field( '351', ' ', ' ', c => 'Series', b => 'Alphabetical by sitter' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'351'}, 'postfix' );
    is( $result[1], 'Series; ', '351 ex2 postfix: N/A $c gets "; " (from following keyed $b)' );
    is( $result[3], 'Alphabetical by sitter', '351 ex2 postfix: $b unchanged (last sf)' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'351'}, 'prefix' );
    is( $result_pr[1], 'Series', '351 ex2 prefix: $c unchanged (N/A)' );
    is( $result_pr[3], '; Alphabetical by sitter', '351 ex2 prefix: $b gets "; " prepended' );

    check_combined( \@result, \@result_pr, '351 ex2: combined string identical' );
}

# --- 351 ex 3 (doc §3.7) ---
# Doc: Current: 351 ## $c Series; $a Organized into five subseries; $b Arranged by form of material.
{
    # render: [doc §3.7] 351 ## $c Series $a Organized into five subseries $b Arranged by form of material
    my $field = make_field( '351', ' ', ' ', c => 'Series', a => 'Organized into five subseries', b => 'Arranged by form of material' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'351'}, 'postfix' );
    is( $result[1], 'Series; ', '351 ex3 postfix: N/A $c gets "; " (from following $a)' );
    is( $result[3], 'Organized into five subseries; ', '351 ex3 postfix: $a gets "; " (for $b)' );
    is( $result[5], 'Arranged by form of material', '351 ex3 postfix: $b unchanged (last sf)' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'351'}, 'prefix' );
    is( $result_pr[1], 'Series', '351 ex3 prefix: $c unchanged (N/A)' );
    is( $result_pr[3], '; Organized into five subseries', '351 ex3 prefix: $a gets "; " prepended' );
    is( $result_pr[5], '; Arranged by form of material', '351 ex3 prefix: $b gets "; " prepended' );

    check_combined( \@result, \@result_pr, '351 ex3: combined string identical' );
}

# --- 351 edge: $a alone ---
{
    # render: 351 ## $a Hierarchical
    my $field = make_field( '351', ' ', ' ', a => 'Hierarchical' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'351'}, 'postfix' );
    is( $result[1], 'Hierarchical', '351: $a alone unchanged' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'351'}, 'prefix' );
    is( $result_pr[1], 'Hierarchical', '351 prefix: $a alone unchanged' );

    check_combined( \@result, \@result_pr, '351: combined string identical (just $a)' );
}

done_testing();
