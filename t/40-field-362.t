#   t/40-field-362.t — Field 362 (Dates of Publication and/or Sequential
#   Designation), spec §4.17.
#
#   Provenance tokens:
#     [doc §4.17]              -> drawn verbatim from the reference doc
#     (no token)               -> constructed
#
#   FIELD CHEAT-SHEET (LoC/PCC):
#     362: $a N/A; $z '. '; $b ' ; ' ONLY between two $b (COMPOUND bb, new
#          sequence); $c preceding '- ' only after $b or $d (COMPOUND bc/dc);
#          $e ' = '; $f '- '; $d = paren run-group via
#          _decorate_paren_group_pre (' (date)' with leading space);
#          $i = EMPTY (no colon -- see the rule-block comment).

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

# --- field is defined ---
ok( defined $R->{'362'}, '362 rules defined' );
is( $R->{'362'}->{pchrs}->{bb}, ' ; ', '362 bb pchrs is " ; "' );
is( $R->{'362'}->{pchrs}->{bc}, '- ', '362 bc pchrs is "- "' );
is( $R->{'362'}->{pchrs}->{dc}, '- ', '362 dc pchrs is "- "' );
is( $R->{'362'}->{pchrs}->{e},  ' = ', '362 e pchrs is " = "' );
is( $R->{'362'}->{pchrs}->{f},  '- ', '362 f pchrs is "- "' );
is( $R->{'362'}->{pchrs}->{z},  '. ', '362 z pchrs is ". "' );
is( $R->{'362'}->{pchrs}->{i},  '',   '362 i pchrs is empty (no colon, doc ambiguous)' );

# =====================================================================
# 362 – Dates of Publication and/or Sequential Designation (spec §4.17)
# =====================================================================

# --- 362 ex 1 (doc §4.17) ---
# Doc: Current: 362 0# $a Volume 1, number 1 (April 1981)-
#      Future:  362 0# $b Volume 1, number 1 $d April 1981
{
    # render: [doc §4.17] 362 0# $b Volume 1, number 1 $d April 1981
    my $field = make_field( '362', '0', ' ',
        b => 'Volume 1, number 1',
        d => 'April 1981' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'362'}, 'postfix' );
    is( $result[1], 'Volume 1, number 1', '362 ex1 postfix: $b unchanged (before $d)' );
    is( $result[3], ' (April 1981)', '362 ex1 postfix: $d wrapped with leading space' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'362'}, 'prefix' );
    is( $result_pr[1], 'Volume 1, number 1', '362 ex1 prefix: $b unchanged' );
    is( $result_pr[3], ' (April 1981)', '362 ex1 prefix: $d wrapped with leading space' );

    check_combined( \@result, \@result_pr, '362 ex1: combined string identical' );
}

# --- 362 ex 2 (doc §4.17) ---
# Doc: Current: 362 0# $a 1968-
#      Future:  362 0# $b 1968
{
    # render: [doc §4.17] 362 0# $b 1968
    my $field = make_field( '362', '0', ' ', b => '1968' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'362'}, 'postfix' );
    is( $result[1], '1968', '362 ex2 postfix: lone $b unchanged' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'362'}, 'prefix' );
    is( $result_pr[1], '1968', '362 ex2 prefix: lone $b unchanged' );

    check_combined( \@result, \@result_pr, '362 ex2: combined string identical' );
}

# --- 362 ex 3 (doc §4.17) ---
# Doc: Current: 362 0# $a Vol. 1, no. 1 (Apr. 1983)-v. 1, no. 3 (June 1983).
#      Future:  362 0# $b Vol. 1, no. 1 $d Apr. 1983 $c v. 1, no. 3 $d June 1983
{
    # render: [doc §4.17] 362 0# $b Vol. 1, no. 1 $d Apr. 1983 $c v. 1, no. 3 $d June 1983
    my $field = make_field( '362', '0', ' ',
        b => 'Vol. 1, no. 1',
        d => 'Apr. 1983',
        c => 'v. 1, no. 3',
        d => 'June 1983' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'362'}, 'postfix' );
    is( $result[1], 'Vol. 1, no. 1',       '362 ex3 postfix: $b unchanged' );
    is( $result[3], ' (Apr. 1983)- ',      '362 ex3 postfix: $d wrapped + gets "- " (for $c)' );
    is( $result[5], 'v. 1, no. 3',         '362 ex3 postfix: $c unchanged (before $d)' );
    is( $result[7], ' (June 1983)',        '362 ex3 postfix: last $d wrapped' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'362'}, 'prefix' );
    is( $result_pr[1], 'Vol. 1, no. 1',    '362 ex3 prefix: $b unchanged' );
    is( $result_pr[3], ' (Apr. 1983)',     '362 ex3 prefix: $d wrapped (no trailing punct)' );
    is( $result_pr[5], '- v. 1, no. 3',    '362 ex3 prefix: $c gets "- " prepended' );
    is( $result_pr[7], ' (June 1983)',     '362 ex3 prefix: last $d wrapped' );

    check_combined( \@result, \@result_pr, '362 ex3: combined string identical' );
}

# --- 362 ex 4 (doc §4.17) ---
# Doc: Current: 362 0# $a Vol. 1, no. 1 (May 1981)-v. 3, no. 1 (May 1983)
#                 = no. 1-no. 9.
#      Future:  362 0# $b Vol. 1, no. 1 $d May 1981 $c v. 3, no. 1 $d May 1983
#                 $e no. 1 $f no. 9
{
    # render: [doc §4.17] 362 0# $b Vol. 1, no. 1 $d May 1981 $c v. 3, no. 1 $d May 1983 $e no. 1 $f no. 9
    my $field = make_field( '362', '0', ' ',
        b => 'Vol. 1, no. 1',
        d => 'May 1981',
        c => 'v. 3, no. 1',
        d => 'May 1983',
        e => 'no. 1',
        f => 'no. 9' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'362'}, 'postfix' );
    is( $result[1],  'Vol. 1, no. 1',   '362 ex4 postfix: $b unchanged' );
    is( $result[3],  ' (May 1981)- ',   '362 ex4 postfix: first $d wrapped + "- " (for $c)' );
    is( $result[5],  'v. 3, no. 1',     '362 ex4 postfix: $c unchanged' );
    is( $result[7],  ' (May 1983) = ',  '362 ex4 postfix: second $d wrapped + " = " (for $e)' );
    is( $result[9],  'no. 1- ',         '362 ex4 postfix: $e gets "- " (for $f)' );
    is( $result[11], 'no. 9',           '362 ex4 postfix: $f unchanged (last sf)' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'362'}, 'prefix' );
    is( $result_pr[1],  'Vol. 1, no. 1', '362 ex4 prefix: $b unchanged' );
    is( $result_pr[3],  ' (May 1981)',   '362 ex4 prefix: first $d wrapped (no trailing punct)' );
    is( $result_pr[5],  '- v. 3, no. 1', '362 ex4 prefix: $c gets "- " prepended' );
    is( $result_pr[7],  ' (May 1983)',   '362 ex4 prefix: second $d wrapped (no trailing punct)' );
    is( $result_pr[9],  ' = no. 1',      '362 ex4 prefix: $e gets " = " prepended' );
    is( $result_pr[11], '- no. 9',       '362 ex4 prefix: $f gets "- " prepended' );

    check_combined( \@result, \@result_pr, '362 ex4: combined string identical' );
}

# --- 362 ex 5 (doc §4.17) ---
# Doc: Current: 362 0# $a Oct. 1970-Dec. 1980 ; new ser., v. 1, no. 1 (Jan. 1981)-
#      Future:  362 0# $b Oct. 1970 $c Dec. 1980
{
    # render: [doc §4.17] 362 0# $b Oct. 1970 $c Dec. 1980
    my $field = make_field( '362', '0', ' ',
        b => 'Oct. 1970',
        c => 'Dec. 1980' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'362'}, 'postfix' );
    is( $result[1], 'Oct. 1970- ', '362 ex5 postfix: $b gets "- " (for $c)' );
    is( $result[3], 'Dec. 1980',   '362 ex5 postfix: $c unchanged (last sf)' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'362'}, 'prefix' );
    is( $result_pr[1], 'Oct. 1970',  '362 ex5 prefix: $b unchanged' );
    is( $result_pr[3], '- Dec. 1980', '362 ex5 prefix: $c gets "- " prepended' );

    check_combined( \@result, \@result_pr, '362 ex5: combined string identical' );
}

# --- 362 ex 6 (doc §4.17) ---
# Doc: Current: 362 1# $a Ceased with 2 (1964).
#      Future:  362 1# $i Ceased with $c 2 $d 1964
{
    # render: [doc §4.17] 362 1# $i Ceased with $c 2 $d 1964
    my $field = make_field( '362', '1', ' ',
        i => 'Ceased with',
        c => '2',
        d => '1964' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'362'}, 'postfix' );
    is( $result[1], 'Ceased with', '362 ex6 postfix: $i unchanged (no colon, no punct after $i)' );
    is( $result[3], '2',           '362 ex6 postfix: $c unchanged (no "-" after $i)' );
    is( $result[5], ' (1964)',     '362 ex6 postfix: $d wrapped' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'362'}, 'prefix' );
    is( $result_pr[1], 'Ceased with', '362 ex6 prefix: $i unchanged' );
    is( $result_pr[3], '2',           '362 ex6 prefix: $c unchanged' );
    is( $result_pr[5], ' (1964)',     '362 ex6 prefix: $d wrapped' );

    check_combined( \@result, \@result_pr, '362 ex6: combined string identical' );
}

# --- 362 ex 7 (doc §4.17) ---
# Doc: Current: 362 1# $a Began with v. 4, published in 1947.
#      Future:  362 1# $i Began with $b v. 4, published in 1947
#              [no actual date designation is present]
{
    # render: [doc §4.17] 362 1# $i Began with $b v. 4, published in 1947
    my $field = make_field( '362', '1', ' ',
        i => 'Began with',
        b => 'v. 4, published in 1947' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'362'}, 'postfix' );
    is( $result[1], 'Began with',          '362 ex7 postfix: $i unchanged (no colon)' );
    is( $result[3], 'v. 4, published in 1947', '362 ex7 postfix: $b unchanged (last sf)' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'362'}, 'prefix' );
    is( $result_pr[1], 'Began with',       '362 ex7 prefix: $i unchanged' );
    is( $result_pr[3], 'v. 4, published in 1947', '362 ex7 prefix: $b unchanged' );

    check_combined( \@result, \@result_pr, '362 ex7: combined string identical' );
}

# --- 362 ex 8 (doc §4.17) ---
# Doc: Current: 362 1# $a Began with 1930 issue. $z Cf. Letter from Ak. State
#                 Highway Dept., Aug. 6, 1975.
#      Future:  362 1# $a Began with 1930 issue $z Cf. Letter from Ak. State
#                 Highway Dept., Aug. 6, 1975
{
    # render: [doc §4.17] 362 1# $a Began with 1930 issue $z Cf. Letter from Ak. State Highway Dept., Aug. 6, 1975
    my $field = make_field( '362', '1', ' ',
        a => 'Began with 1930 issue',
        z => 'Cf. Letter from Ak. State Highway Dept., Aug. 6, 1975' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'362'}, 'postfix' );
    is( $result[1], 'Began with 1930 issue. ', '362 ex8 postfix: $a gets ". " (for $z)' );
    is( $result[3], 'Cf. Letter from Ak. State Highway Dept., Aug. 6, 1975',
        '362 ex8 postfix: $z unchanged (last sf)' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'362'}, 'prefix' );
    is( $result_pr[1], 'Began with 1930 issue', '362 ex8 prefix: $a unchanged' );
    is( $result_pr[3], '. Cf. Letter from Ak. State Highway Dept., Aug. 6, 1975',
        '362 ex8 prefix: $z gets ". " prepended' );

    check_combined( \@result, \@result_pr, '362 ex8: combined string identical' );
}

# --- 362 ex 9 (doc §4.17) ---
# Doc: Current: 362 1# $a Ceased in 2007.
#      Future:  362 1# $a Ceased in 2007
{
    # render: [doc §4.17] 362 1# $a Ceased in 2007
    my $field = make_field( '362', '1', ' ', a => 'Ceased in 2007' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'362'}, 'postfix' );
    is( $result[1], 'Ceased in 2007', '362 ex9 postfix: lone $a unchanged' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'362'}, 'prefix' );
    is( $result_pr[1], 'Ceased in 2007', '362 ex9 prefix: lone $a unchanged' );

    check_combined( \@result, \@result_pr, '362 ex9: combined string identical' );
}

# --- 362 edge: two $b (new sequence) -> ' ; ' via COMPOUND bb ---
# constructed
{
    # render: 362 0# $b Series 1 $b Series 2
    my $field = make_field( '362', '0', ' ',
        b => 'Series 1',
        b => 'Series 2' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'362'}, 'postfix' );
    is( $result[1], 'Series 1 ; ', '362 bb postfix: first $b gets " ; " (for second $b)' );
    is( $result[3], 'Series 2',    '362 bb postfix: second $b unchanged (last sf)' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'362'}, 'prefix' );
    is( $result_pr[1], 'Series 1',     '362 bb prefix: first $b unchanged' );
    is( $result_pr[3], ' ; Series 2',  '362 bb prefix: second $b gets " ; " prepended' );

    check_combined( \@result, \@result_pr, '362 bb: combined string identical' );
}

# --- 362 edge: $b $c $e $f (alt begin/end without preceding $d) ---
# constructed
{
    # render: 362 0# $b v. A $c v. B $e no. x $f no. y
    my $field = make_field( '362', '0', ' ',
        b => 'v. A',
        c => 'v. B',
        e => 'no. x',
        f => 'no. y' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'362'}, 'postfix' );
    is( $result[1], 'v. A- ',    '362 ae postfix: $b gets "- " (for $c)' );
    is( $result[3], 'v. B = ',   '362 ae postfix: $c gets " = " (for $e)' );
    is( $result[5], 'no. x- ',   '362 ae postfix: $e gets "- " (for $f)' );
    is( $result[7], 'no. y',     '362 ae postfix: $f unchanged (last sf)' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'362'}, 'prefix' );
    is( $result_pr[1], 'v. A',   '362 ae prefix: $b unchanged' );
    is( $result_pr[3], '- v. B', '362 ae prefix: $c gets "- " prepended' );
    is( $result_pr[5], ' = no. x', '362 ae prefix: $e gets " = " prepended' );
    is( $result_pr[7], '- no. y', '362 ae prefix: $f gets "- " prepended' );

    check_combined( \@result, \@result_pr, '362 ae: combined string identical' );
}

done_testing();
