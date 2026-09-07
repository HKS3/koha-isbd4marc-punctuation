# PROVENANCE:
#   [doc §4.15] / [doc §4.16]     -> drawn verbatim from the reference doc
#   (no token)                    -> constructed
#
# This file covers 310 (Current Publication Frequency, §4.15) and 321 (Former
# Publication Frequency, §4.16). Both share the same shape: $a N/A, $b
# (date) gets ', ', and $n (qualifying info) is wrapped in a SINGLE paren
# pair (not a repeatable group).
#
# FIELD CHEAT-SHEET (LoC/PCC):
#   310: $b ', ', $n ( ) single wrap, $a N/A
#   321: same as 310

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
for my $t ( qw(310 321) ) {
    ok( defined $R->{$t}, "$t rules defined" );
}
is( $R->{'310'}->{pchrs}->{b}, ', ', '310 $b pchrs is ", "' );
is( $R->{'321'}->{pchrs}->{b}, ', ', '321 $b pchrs is ", "' );
is_deeply( $R->{'310'}->{wrap}->{n}, [ '(', ')' ], '310 $n is wrapped in ()' );
is_deeply( $R->{'321'}->{wrap}->{n}, [ '(', ')' ], '321 $n is wrapped in ()' );

# =====================================================================
# 310 – Current Publication Frequency (spec §4.15)
# $b ', '; $n (qualifying info) wrapped ( ). $a N/A.
# =====================================================================

# --- 310 ex 1 (doc §4.15) ---
# Doc: Current: 310 ## $a Monthly, $b 1958-
{
    # render: [doc §4.15] 310 ## $a Monthly $b 1958-
    my $field = make_field( '310', ' ', ' ', a => 'Monthly', b => '1958-' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'310'}, 'postfix' );
    is( $result[1], 'Monthly, ', '310 ex1 postfix: $a gets ", " (for following $b)' );
    is( $result[3], '1958-', '310 ex1 postfix: $b unchanged (last sf)' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'310'}, 'prefix' );
    is( $result_pr[1], 'Monthly', '310 ex1 prefix: $a unchanged' );
    is( $result_pr[3], ', 1958-', '310 ex1 prefix: $b gets ", " prepended' );

    check_combined( \@result, \@result_pr, '310 ex1: combined string identical' );
}

# --- 310 ex 2 (doc §4.15) ---
# Doc: Current: 310 ## $a Updated quarterly, $b Jan.-Mar. 2001-
{
    # render: [doc §4.15] 310 ## $a Updated quarterly $b Jan.-Mar. 2001-
    my $field = make_field( '310', ' ', ' ', a => 'Updated quarterly', b => 'Jan.-Mar. 2001-' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'310'}, 'postfix' );
    is( $result[1], 'Updated quarterly, ', '310 ex2 postfix: $a gets ", " (for $b)' );
    is( $result[3], 'Jan.-Mar. 2001-', '310 ex2 postfix: $b unchanged (last sf)' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'310'}, 'prefix' );
    is( $result_pr[1], 'Updated quarterly', '310 ex2 prefix: $a unchanged' );
    is( $result_pr[3], ', Jan.-Mar. 2001-', '310 ex2 prefix: $b gets ", " prepended' );

    check_combined( \@result, \@result_pr, '310 ex2: combined string identical' );
}

# --- 310 ex 3 (doc §4.15) ---
# Doc: Current: 310 ## $a Monthly (except July and Aug.)
{
    # render: [doc §4.15] 310 ## $a Monthly $n except July and Aug.
    my $field = make_field( '310', ' ', ' ', a => 'Monthly', n => 'except July and Aug.' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'310'}, 'postfix' );
    is( $result[1], 'Monthly', '310 ex3 postfix: $a unchanged (no keyed sf after)' );
    is( $result[3], '(except July and Aug.)', '310 ex3 postfix: $n wrapped in ()' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'310'}, 'prefix' );
    is( $result_pr[1], 'Monthly', '310 ex3 prefix: $a unchanged' );
    is( $result_pr[3], '(except July and Aug.)', '310 ex3 prefix: $n wrapped in ()' );

    check_combined( \@result, \@result_pr, '310 ex3: combined string identical' );
}

# --- 310 constructed: $a $n $b (paren + date together) ---
{
    # render: 310 ## $a Monthly $n except July $b 1958-
    my $field = make_field( '310', ' ', ' ', a => 'Monthly', n => 'except July', b => '1958-' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'310'}, 'postfix' );
    is( $result[1], 'Monthly', '310 $a-$n-$b postfix: $a unchanged' );
    is( $result[3], '(except July), ', '310 $a-$n-$b postfix: $n wrapped and gets ", " for $b' );
    is( $result[5], '1958-', '310 $a-$n-$b postfix: $b unchanged (last sf)' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'310'}, 'prefix' );
    is( $result_pr[1], 'Monthly', '310 $a-$n-$b prefix: $a unchanged' );
    is( $result_pr[3], '(except July)', '310 $a-$n-$b prefix: $n wrapped in ()' );
    is( $result_pr[5], ', 1958-', '310 $a-$n-$b prefix: $b gets ", " prepended' );

    check_combined( \@result, \@result_pr, '310 $a-$n-$b: combined string identical' );
}

# --- 310 edge: $a alone ---
{
    # render: 310 ## $a Monthly
    my $field = make_field( '310', ' ', ' ', a => 'Monthly' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'310'}, 'postfix' );
    is( $result[1], 'Monthly', '310: $a alone unchanged' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'310'}, 'prefix' );
    is( $result_pr[1], 'Monthly', '310 prefix: $a alone unchanged' );

    check_combined( \@result, \@result_pr, '310: combined string identical (just $a)' );
}

# =====================================================================
# 321 – Former Publication Frequency (spec §4.16)
# Same shape as 310: $b ', '; $n wrapped ( ). $a N/A.
# =====================================================================

# --- 321 ex 1 (doc §4.16) ---
# Doc: Current: 321 ## $a Bimonthly, $b June 1, 1967-July 15, 1976
{
    # render: [doc §4.16] 321 ## $a Bimonthly $b June 1, 1967-July 15, 1976
    my $field = make_field( '321', ' ', ' ', a => 'Bimonthly', b => 'June 1, 1967-July 15, 1976' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'321'}, 'postfix' );
    is( $result[1], 'Bimonthly, ', '321 ex1 postfix: $a gets ", " (for $b)' );
    is( $result[3], 'June 1, 1967-July 15, 1976', '321 ex1 postfix: $b unchanged (last sf)' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'321'}, 'prefix' );
    is( $result_pr[1], 'Bimonthly', '321 ex1 prefix: $a unchanged' );
    is( $result_pr[3], ', June 1, 1967-July 15, 1976', '321 ex1 prefix: $b gets ", " prepended' );

    check_combined( \@result, \@result_pr, '321 ex1: combined string identical' );
}

# --- 321 ex 2 (doc §4.16) ---
# Doc: Current: 321 ## $a Frequency varies, $b 1966-1983
{
    # render: [doc §4.16] 321 ## $a Frequency varies $b 1966-1983
    my $field = make_field( '321', ' ', ' ', a => 'Frequency varies', b => '1966-1983' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'321'}, 'postfix' );
    is( $result[1], 'Frequency varies, ', '321 ex2 postfix: $a gets ", " (for $b)' );
    is( $result[3], '1966-1983', '321 ex2 postfix: $b unchanged (last sf)' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'321'}, 'prefix' );
    is( $result_pr[1], 'Frequency varies', '321 ex2 prefix: $a unchanged' );
    is( $result_pr[3], ', 1966-1983', '321 ex2 prefix: $b gets ", " prepended' );

    check_combined( \@result, \@result_pr, '321 ex2: combined string identical' );
}

# --- 321 ex 3 (doc §4.16) ---
# Doc: Current: 321 ## $a Daily (Monday through Friday), $b <1965>-Jan. 31, 1975
{
    # render: [doc §4.16] 321 ## $a Daily $n Monday through Friday $b <1965>-Jan. 31, 1975
    my $field = make_field( '321', ' ', ' ', a => 'Daily', n => 'Monday through Friday', b => '<1965>-Jan. 31, 1975' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'321'}, 'postfix' );
    is( $result[1], 'Daily', '321 ex3 postfix: $a unchanged' );
    is( $result[3], '(Monday through Friday), ', '321 ex3 postfix: $n wrapped and gets ", " for $b' );
    is( $result[5], '<1965>-Jan. 31, 1975', '321 ex3 postfix: $b unchanged (last sf)' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'321'}, 'prefix' );
    is( $result_pr[1], 'Daily', '321 ex3 prefix: $a unchanged' );
    is( $result_pr[3], '(Monday through Friday)', '321 ex3 prefix: $n wrapped in ()' );
    is( $result_pr[5], ', <1965>-Jan. 31, 1975', '321 ex3 prefix: $b gets ", " prepended' );

    check_combined( \@result, \@result_pr, '321 ex3: combined string identical' );
}

# --- 321 edge: $a alone ---
{
    # render: 321 ## $a Bimonthly
    my $field = make_field( '321', ' ', ' ', a => 'Bimonthly' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'321'}, 'postfix' );
    is( $result[1], 'Bimonthly', '321: $a alone unchanged' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'321'}, 'prefix' );
    is( $result_pr[1], 'Bimonthly', '321 prefix: $a alone unchanged' );

    check_combined( \@result, \@result_pr, '321: combined string identical (just $a)' );
}

# --- 321 edge: $n alone ---
{
    # render: 321 ## $a Daily $n Monday through Friday
    my $field = make_field( '321', ' ', ' ', a => 'Daily', n => 'Monday through Friday' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'321'}, 'postfix' );
    is( $result[1], 'Daily', '321 $n postfix: $a unchanged' );
    is( $result[3], '(Monday through Friday)', '321 $n postfix: $n wrapped in ()' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'321'}, 'prefix' );
    is( $result_pr[1], 'Daily', '321 $n prefix: $a unchanged' );
    is( $result_pr[3], '(Monday through Friday)', '321 $n prefix: $n wrapped in ()' );

    check_combined( \@result, \@result_pr, '321 $n: combined string identical' );
}

done_testing();
