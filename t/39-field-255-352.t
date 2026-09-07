# PROVENANCE:
#   [doc §4.11] / [doc §3.8]      -> drawn verbatim from the reference doc
#   [LoC - derived]               -> split from a real LoC Current record
#   (no token)                    -> constructed
#
# This file covers 255 (Cartographic Mathematical Data, §4.11) and 352
# (Digital Graphic Representation, §3.8). Both use the shared
# _decorate_paren_group_pre run-grouper for a paren run-group; 352 adds an
# INDIVIDUAL $c wrap (separate from the d/e/f group).
#
# FIELD CHEAT-SHEET (LoC/PCC):
#   255: $a N/A; $b ' ; '; $c/$d/$e = one paren run-group
#        (internal ' ; ' via COMPOUND cd/de); $s/$v '. '; $f/$g N/A
#   352: $a N/A; $b ' : ' (first) / ', ' (repeated after $c) via COMPOUND
#        ab/cb; $g ', '; $i ' : '; $q ' ; '; $c = INDIVIDUAL paren wrap;
#        $d/$e/$f = one paren run-group (' x ' via COMPOUND de/ef)

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
for my $t ( qw(255 352) ) {
    ok( defined $R->{$t}, "$t rules defined" );
}
is( $R->{'255'}->{pchrs}->{b},  ' ; ', '255 $b pchrs is " ; "' );
is( $R->{'255'}->{pchrs}->{cd}, ' ; ', '255 cd pchrs is " ; "' );
is( $R->{'255'}->{pchrs}->{de}, ' ; ', '255 de pchrs is " ; "' );
is( $R->{'352'}->{pchrs}->{ab}, ' : ', '352 ab pchrs is " : "' );
is( $R->{'352'}->{pchrs}->{cb}, ', ', '352 cb pchrs is ", "' );
is( $R->{'352'}->{pchrs}->{de}, ' x ', '352 de pchrs is " x "' );
is( $R->{'352'}->{wrap}->{c}[0], '(', '352 $c wrap opens with (' );
is( $R->{'352'}->{wrap}->{c}[1], ')', '352 $c wrap closes with )' );

# =====================================================================
# 255 – Cartographic Mathematical Data (spec §4.11)
# $a N/A; $b ' ; '; $s/$v '. '; $c/$d/$e = one paren run-group
# (internal ' ; ' via COMPOUND cd/de). $f/$g N/A.
# =====================================================================

# --- 255 ex 1 (doc §4.11) ---
# Doc: Current: 255 ## $a Scale approximately 1:90,000.
{
    # render: [doc §4.11] 255 ## $a Scale approximately 1:90,000
    my $field = make_field( '255', ' ', ' ', a => 'Scale approximately 1:90,000' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'255'}, 'postfix' );
    is( $result[1], 'Scale approximately 1:90,000', '255 ex1 postfix: $a alone unchanged' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'255'}, 'prefix' );
    is( $result_pr[1], 'Scale approximately 1:90,000', '255 ex1 prefix: $a alone unchanged' );

    check_combined( \@result, \@result_pr, '255 ex1: combined string identical' );
}

# --- 255 ex 2 (doc §4.11) ---
# Doc: Current: 255 ## $a Scale 1:6,336,000. 1" = 100 miles. Vertical scale
#                 1:192,000. 1/16" = approximately 1000'.
{
    # render: [doc §4.11] 255 ## $a Scale 1:6,336,000 $s 1" = 100 miles $v Vertical scale 1:192,000 $s 1/16" = approximately 1000'
    my $field = make_field( '255', ' ', ' ',
        a => 'Scale 1:6,336,000',
        s => '1" = 100 miles',
        v => 'Vertical scale 1:192,000',
        s => '1/16" = approximately 1000\'' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'255'}, 'postfix' );
    is( $result[1], 'Scale 1:6,336,000. ', '255 ex2 postfix: $a gets ". " (for $s)' );
    is( $result[3], '1" = 100 miles. ', '255 ex2 postfix: first $s gets ". " (for $v)' );
    is( $result[5], 'Vertical scale 1:192,000. ', '255 ex2 postfix: $v gets ". " (for $s)' );
    is( $result[7], q{1/16" = approximately 1000'}, '255 ex2 postfix: last $s unchanged' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'255'}, 'prefix' );
    is( $result_pr[1], 'Scale 1:6,336,000', '255 ex2 prefix: $a unchanged' );
    is( $result_pr[3], '. 1" = 100 miles', '255 ex2 prefix: first $s gets ". " prepended' );
    is( $result_pr[5], '. Vertical scale 1:192,000', '255 ex2 prefix: $v gets ". " prepended' );
    is( $result_pr[7], q{. 1/16" = approximately 1000'}, '255 ex2 prefix: last $s gets ". " prepended' );

    check_combined( \@result, \@result_pr, '255 ex2: combined string identical' );
}

# --- 255 ex 3 (doc §4.11) ---
# Doc: Current: 255 ## $a Scale [ca. 1:13,835,000]. 1 cm = 138 km. 1 in. = 218
#                 miles ; $b Chamberlin trimetric proj.
{
    # render: [doc §4.11] 255 ## $a Scale [ca. 1:13,835,000] $s 1 cm = 138 km $s 1 in. = 218 miles $b Chamberlin trimetric proj.
    my $field = make_field( '255', ' ', ' ',
        a => 'Scale [ca. 1:13,835,000]',
        s => '1 cm = 138 km',
        s => '1 in. = 218 miles',
        b => 'Chamberlin trimetric proj.' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'255'}, 'postfix' );
    is( $result[1], 'Scale [ca. 1:13,835,000]. ', '255 ex3 postfix: $a gets ". " (for $s)' );
    is( $result[3], '1 cm = 138 km. ', '255 ex3 postfix: first $s gets ". " (for $s)' );
    is( $result[5], '1 in. = 218 miles ; ', '255 ex3 postfix: second $s gets " ; " (for $b)' );
    is( $result[7], 'Chamberlin trimetric proj.', '255 ex3 postfix: $b unchanged (last sf)' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'255'}, 'prefix' );
    is( $result_pr[1], 'Scale [ca. 1:13,835,000]', '255 ex3 prefix: $a unchanged' );
    is( $result_pr[3], '. 1 cm = 138 km', '255 ex3 prefix: first $s gets ". " prepended' );
    is( $result_pr[5], '. 1 in. = 218 miles', '255 ex3 prefix: second $s gets ". " prepended' );
    is( $result_pr[7], ' ; Chamberlin trimetric proj.', '255 ex3 prefix: $b gets " ; " prepended' );

    check_combined( \@result, \@result_pr, '255 ex3: combined string identical' );
}

# --- 255 ex 4 (doc §4.11) ---
# Doc: Current: 255 ## $a Scale 1:22,000,000 ; $b Conic proj. $c (E 72°--E
#                 148°/N 13°--N 18°).
{
    # render: [doc §4.11] 255 ## $a Scale 1:22,000,000 $b Conic proj. $c E 72°--E 148°/N 13°--N 18°
    my $field = make_field( '255', ' ', ' ',
        a => 'Scale 1:22,000,000',
        b => 'Conic proj.',
        c => 'E 72°--E 148°/N 13°--N 18°' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'255'}, 'postfix' );
    is( $result[1], 'Scale 1:22,000,000 ; ', '255 ex4 postfix: $a gets " ; " (for $b)' );
    is( $result[3], 'Conic proj.', '255 ex4 postfix: $b unchanged (last before group)' );
    is( $result[5], ' (E 72°--E 148°/N 13°--N 18°)',
        '255 ex4 postfix: $c wrapped in one paren pair (leading space before group)' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'255'}, 'prefix' );
    is( $result_pr[1], 'Scale 1:22,000,000', '255 ex4 prefix: $a unchanged' );
    is( $result_pr[3], ' ; Conic proj.', '255 ex4 prefix: $b gets " ; " prepended' );
    is( $result_pr[5], ' (E 72°--E 148°/N 13°--N 18°)',
        '255 ex4 prefix: $c wrapped in one paren pair (leading space before group)' );

    check_combined( \@result, \@result_pr, '255 ex4: combined string identical' );
}

# --- 255 ex 5 (doc §4.11) ---
# Doc: Current: 255 ## $a Scale not given $d (RA 0 hr. to 24 hr./Decl. +90° to
#                 -90° ; $e eq. 1980).
{
    # render: [doc §4.11] 255 ## $a Scale not given $d RA 0 hr. to 24 hr./Decl. +90° to -90° $e eq. 1980
    my $field = make_field( '255', ' ', ' ',
        a => 'Scale not given',
        d => 'RA 0 hr. to 24 hr./Decl. +90° to -90°',
        e => 'eq. 1980' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'255'}, 'postfix' );
    is( $result[1], 'Scale not given', '255 ex5 postfix: $a unchanged (group starts)' );
    is( $result[3], ' (RA 0 hr. to 24 hr./Decl. +90° to -90° ; ',
        '255 ex5 postfix: $d opens group (leading space) and gets " ; " (for $e)' );
    is( $result[5], 'eq. 1980)', '255 ex5 postfix: $e closes group' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'255'}, 'prefix' );
    is( $result_pr[1], 'Scale not given', '255 ex5 prefix: $a unchanged' );
    is( $result_pr[3], ' (RA 0 hr. to 24 hr./Decl. +90° to -90°',
        '255 ex5 prefix: $d opens group (leading space; separator held as pending)' );
    is( $result_pr[5], ' ; eq. 1980)', '255 ex5 prefix: $e gets " ; " prepended and closes group' );

    check_combined( \@result, \@result_pr, '255 ex5: combined string identical' );
}

# --- 255 edge: $a alone ---
{
    # render: 255 ## $a Scale not given
    my $field = make_field( '255', ' ', ' ', a => 'Scale not given' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'255'}, 'postfix' );
    is( $result[1], 'Scale not given', '255: $a alone unchanged' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'255'}, 'prefix' );
    is( $result_pr[1], 'Scale not given', '255 prefix: $a alone unchanged' );

    check_combined( \@result, \@result_pr, '255: combined string identical (just $a)' );
}

# --- 255 edge: full $c $d $e run (constructed) ---
{
    # render: 255 ## $a Scale from pos 1 $c C1 $d D1 $e E1
    my $field = make_field( '255', ' ', ' ',
        a => 'Scale from pos 1',
        c => 'C1',
        d => 'D1',
        e => 'E1' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'255'}, 'postfix' );
    is( $result[3], ' (C1 ; ', '255 cde-run postfix: $c opens group (leading space) and gets " ; " (for $d)' );
    is( $result[5], 'D1 ; ', '255 cde-run postfix: $d gets " ; " (for $e)' );
    is( $result[7], 'E1)', '255 cde-run postfix: $e closes group' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'255'}, 'prefix' );
    is( $result_pr[3], ' (C1', '255 cde-run prefix: $c opens group (leading space)' );
    is( $result_pr[5], ' ; D1', '255 cde-run prefix: $d gets " ; " prepended' );
    is( $result_pr[7], ' ; E1)', '255 cde-run prefix: $e gets " ; " prepended and closes group' );

    check_combined( \@result, \@result_pr, '255 cde-run: combined string identical' );
}

# =====================================================================
# 352 – Digital Graphic Representation (spec §3.8)
# $a N/A; $b ' : ' (first) / ', ' (repeated after $c) via COMPOUND ab/cb;
# $g ', '; $i ' : '; $q ' ; '; $c = INDIVIDUAL paren wrap;
# $d/$e/$f = one paren run-group (' x ' via COMPOUND de/ef).
# =====================================================================

# --- 352 ex 1 (doc §3.8) ---
# Doc: Current: 352 ## $a Vector : $b GT-polygon composed of chains $c (70).
{
    # render: [doc §3.8] 352 ## $a Vector $b GT-polygon composed of chains $c 70
    my $field = make_field( '352', ' ', ' ',
        a => 'Vector',
        b => 'GT-polygon composed of chains',
        c => '70' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'352'}, 'postfix' );
    is( $result[1], 'Vector : ', '352 ex1 postfix: $a gets " : " (for $b)' );
    is( $result[3], 'GT-polygon composed of chains', '352 ex1 postfix: $b unchanged (before $c)' );
    is( $result[5], '(70)', '352 ex1 postfix: $c individually wrapped' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'352'}, 'prefix' );
    is( $result_pr[1], 'Vector', '352 ex1 prefix: $a unchanged' );
    is( $result_pr[3], ' : GT-polygon composed of chains', '352 ex1 prefix: $b gets " : " prepended' );
    is( $result_pr[5], '(70)', '352 ex1 prefix: $c individually wrapped' );

    check_combined( \@result, \@result_pr, '352 ex1: combined string identical' );
}

# --- 352 ex 2 (doc §3.8) ---
# Doc: Current: 352 ## $a Vector : $b Point $c (13671), $b string $c (20171),
#                 $b GT-polygon composed of chains $c (13672) ; $q ARC/INFO export.
{
    # render: [doc §3.8] 352 ## $a Vector $b Point $c 13671 $b string $c 20171 $b GT-polygon composed of chains $c 13672 $q ARC/INFO export
    my $field = make_field( '352', ' ', ' ',
        a => 'Vector',
        b => 'Point',
        c => '13671',
        b => 'string',
        c => '20171',
        b => 'GT-polygon composed of chains',
        c => '13672',
        q => 'ARC/INFO export' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'352'}, 'postfix' );
    is( $result[1],  'Vector : ',       '352 ex2 postfix: $a gets " : " (for $b)' );
    is( $result[3],  'Point',           '352 ex2 postfix: first $b unchanged (before $c)' );
    is( $result[5],  '(13671), ',       '352 ex2 postfix: $c (13671) wrapped + gets ", " (for $b)' );
    is( $result[7],  'string',          '352 ex2 postfix: second $b unchanged' );
    is( $result[9],  '(20171), ',       '352 ex2 postfix: $c (20171) wrapped + gets ", " (for $b)' );
    is( $result[11], 'GT-polygon composed of chains', '352 ex2 postfix: third $b unchanged' );
    is( $result[13], '(13672) ; ',      '352 ex2 postfix: $c (13672) wrapped + gets " ; " (for $q)' );
    is( $result[15], 'ARC/INFO export', '352 ex2 postfix: $q unchanged (last sf)' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'352'}, 'prefix' );
    is( $result_pr[1],  'Vector',
        '352 ex2 prefix: $a unchanged' );
    is( $result_pr[3],  ' : Point',
        '352 ex2 prefix: first $b gets " : " prepended' );
    is( $result_pr[5],  '(13671)',
        '352 ex2 prefix: $c (13671) wrapped (no leading punct)' );
    is( $result_pr[7],  ', string',
        '352 ex2 prefix: second $b gets ", " prepended' );
    is( $result_pr[9],  '(20171)',
        '352 ex2 prefix: $c (20171) wrapped' );
    is( $result_pr[11], ', GT-polygon composed of chains',
        '352 ex2 prefix: third $b gets ", " prepended' );
    is( $result_pr[13], '(13672)',
        '352 ex2 prefix: $c (13672) wrapped (no leading punct)' );
    is( $result_pr[15], ' ; ARC/INFO export',
        '352 ex2 prefix: $q gets " ; " prepended' );

    check_combined( \@result, \@result_pr, '352 ex2: combined string identical' );
}

# --- 352 ex 3 (doc §3.8) ---
# Doc: Current: 352 ## $a Raster : $b pixel $d (5,000 x $e 5,000) ; $q TIFF.
{
    # render: [doc §3.8] 352 ## $a Raster $b pixel $d 5,000 $e 5,000 $q TIFF
    my $field = make_field( '352', ' ', ' ',
        a => 'Raster',
        b => 'pixel',
        d => '5,000',
        e => '5,000',
        q => 'TIFF' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'352'}, 'postfix' );
    is( $result[1], 'Raster : ', '352 ex3 postfix: $a gets " : " (for $b)' );
    is( $result[3], 'pixel', '352 ex3 postfix: $b unchanged (before group)' );
    is( $result[5], ' (5,000 x ', '352 ex3 postfix: $d opens group (leading space) + gets " x " (for $e)' );
    is( $result[7], '5,000) ; ', '352 ex3 postfix: $e closes group + gets " ; " (for $q)' );
    is( $result[9], 'TIFF', '352 ex3 postfix: $q unchanged (last sf)' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'352'}, 'prefix' );
    is( $result_pr[1], 'Raster', '352 ex3 prefix: $a unchanged' );
    is( $result_pr[3], ' : pixel', '352 ex3 prefix: $b gets " : " prepended' );
    is( $result_pr[5], ' (5,000', '352 ex3 prefix: $d opens group (leading space; no separator)' );
    is( $result_pr[7], ' x 5,000)', '352 ex3 prefix: $e gets " x " prepended and closes group' );
    is( $result_pr[9], ' ; TIFF', '352 ex3 prefix: $q gets " ; " prepended' );

    check_combined( \@result, \@result_pr, '352 ex3: combined string identical' );
}

# --- 352 edge: $a alone ---
{
    # render: 352 ## $a Vector
    my $field = make_field( '352', ' ', ' ', a => 'Vector' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'352'}, 'postfix' );
    is( $result[1], 'Vector', '352: $a alone unchanged' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'352'}, 'prefix' );
    is( $result_pr[1], 'Vector', '352 prefix: $a alone unchanged' );

    check_combined( \@result, \@result_pr, '352: combined string identical (just $a)' );
}

# --- 352 edge: individual $c only (no $b), constructed ---
{
    # render: 352 ## $a Vector $c 70
    my $field = make_field( '352', ' ', ' ', a => 'Vector', c => '70' );

    my @result = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'352'}, 'postfix' );
    is( $result[1], 'Vector', '352 $c-only postfix: $a unchanged (no $c pchrs key)' );
    is( $result[3], '(70)', '352 $c-only postfix: $c individually wrapped' );

    my @result_pr = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field, $R->{'352'}, 'prefix' );
    is( $result_pr[1], 'Vector', '352 $c-only prefix: $a unchanged' );
    is( $result_pr[3], '(70)', '352 $c-only prefix: $c individually wrapped' );

    check_combined( \@result, \@result_pr, '352 $c-only: combined string identical' );
}

done_testing();
