#!/usr/bin/perl
#
# Tests for _decorate_field with 260 rules.
#
# ISBD punctuation for 260 (Imprint):
#   $a ; $a : $b , $c ( $e : $f , $g ) (q)

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

my $rules = Koha::Filter::MARC::ISBD4MARCPunctuation::rules_for($SET)->{260};
ok( defined $rules, '260 rules loaded' );

# --- Test 1: $a alone ---
{
    my $field = make_field( '260', ' ', ' ', a => 'New York' );

    my @result =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules, 'postfix' );
    is( $result[1], 'New York', '260: $a alone is unchanged' );

    my @result_pr =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules, 'prefix' );
    is( $result_pr[1], 'New York', '260 prefix: $a alone unchanged' );

    check_combined( \@result, \@result_pr, '260: combined string identical' );
}

# --- Test 2: $a followed by $b followed by $c ---
{
    # render: 260 ## $a New York $b Penguin $c 2005
    my $field = make_field(
        '260', ' ', ' ',
        a => 'New York',
        b => 'Penguin',
        c => '2005',
    );

    my @result =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules, 'postfix' );
    is( $result[1], 'New York : ', '260: $a gets " : " when $b follows' );
    is( $result[3], 'Penguin, ',   '260: $b gets ", " when $c follows' );
    is( $result[5], '2005',        '260: $c unchanged (last sf)' );

    my @result_pr =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules, 'prefix' );
    is( $result_pr[1], 'New York',   '260 prefix: $a unchanged' );
    is( $result_pr[3], ' : Penguin', '260 prefix: $b gets " : " prepended' );
    is( $result_pr[5], ', 2005',     '260 prefix: $c gets ", " prepended' );

    check_combined( \@result, \@result_pr, '260: combined string identical' );
}

# --- Test 3: Multiple $a (e.g. New York ; London) ---
# " ; " is attached via the COMPOUND pchrs key aa, so ownership swaps
# between modes (postfix: appended to first $a; prefix: prepended to second).
{
    # render: 260 ## $a New York $a London
    my $field = make_field(
        '260', ' ', ' ',
        a => 'New York',
        a => 'London',
    );

    my @result =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules, 'postfix' );
    is( $result[1], 'New York ; ',
        '260: first $a gets " ; " (compound aa)' );
    is( $result[3], 'London', '260: second $a (last) unchanged' );

    my @result_pr =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules, 'prefix' );
    is( $result_pr[1], 'New York', '260 prefix: first $a unchanged' );
    is( $result_pr[3], ' ; London',
        '260 prefix: second $a gets " ; " prepended (pending from aa)' );

    check_combined( \@result, \@result_pr, '260: combined string identical' );
}

# --- Test 4: $q wrapped in parentheses ---
# $q is handled via wrap (not pchrs), so same in both modes.
{
    # render: 260 ## $a New York $q some qualifier
    my $field = make_field(
        '260', ' ', ' ',
        a => 'New York',
        q => 'some qualifier',
    );

    my @result =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules, 'postfix' );
    is( $result[1], 'New York',         '260: $a unchanged' );
    is( $result[3], '(some qualifier)', '260: $q wrapped in parentheses' );

    my @result_pr =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules, 'prefix' );
    is( $result_pr[1], 'New York', '260 prefix: $a unchanged' );
    is(
        $result_pr[3],
        '(some qualifier)',
        '260 prefix: $q wrapped in parentheses'
    );

    check_combined( \@result, \@result_pr, '260: combined string identical' );
}

# --- Test 5: $e/$f/$g grouping ---
# $e opens a paren: " ($value "
# $f continues: " : $value"
# $g closes: ", $value)"
# This is entirely handled by cb_pre, so same in both modes.
{
    # render: 260 ## $a New York $e a manufacturer $f a place $g 2005
    my $field = make_field(
        '260', ' ', ' ',
        a => 'New York',
        e => 'a manufacturer',
        f => 'a place',
        g => '2005',
    );

    my @result =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules, 'postfix' );
    is( $result[1], 'New York', '260: $a unchanged' );
    is(
        $result[3],
        ' (a manufacturer ',
        '260: $e opens paren with trailing space'
    );
    is( $result[5], ' : a place',
        '260: $f gets " : " prefix when $e precedes' );
    is( $result[7], ', 2005)', '260: $g closes paren' );

    my @result_pr =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules, 'prefix' );
    is( $result_pr[1], 'New York', '260 prefix: $a unchanged' );
    is(
        $result_pr[3],
        ' (a manufacturer ',
        '260 prefix: $e opens paren with trailing space'
    );
    is( $result_pr[5], ' : a place',
        '260 prefix: $f gets " : " prefix when $e precedes' );
    is( $result_pr[7], ', 2005)', '260 prefix: $g closes paren' );

    check_combined( \@result, \@result_pr, '260: combined string identical' );
}

# --- Test 5b: lone $g (no $e/$f) opens its own clean paren ---
# Doc Current: 260 ## $a Harmondsworth : $b Penguin, $c 1949 $g (1963 printing)
# A lone $g is a self-contained (value) group; it must NOT get a leading
# comma (the old bug produced ', (1963 printing)').
{
    # render: [doc §4.12 #6] 260 ## $a Harmondsworth $b Penguin $c 1949 $g 1963 printing
    my $field = make_field(
        '260', ' ', ' ',
        a => 'Harmondsworth',
        b => 'Penguin',
        c => '1949',
        g => '1963 printing',
    );

    my @result =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules, 'postfix' );
    is( $result[1], 'Harmondsworth : ', '260: $a gets " : " for $b' );
    is( $result[3], 'Penguin, ',        '260: $b gets ", " for $c' );
    is( $result[5], '1949',             '260: $c unchanged (g not in pchrs)' );
    is( $result[7], '(1963 printing)',  '260: lone $g wrapped cleanly, no leading comma' );

    my @result_pr =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules, 'prefix' );
    is( $result_pr[1], 'Harmondsworth',   '260 prefix: $a unchanged' );
    is( $result_pr[3], ' : Penguin',      '260 prefix: $b gets " : " prepended' );
    is( $result_pr[5], ', 1949',          '260 prefix: $c gets ", " prepended' );
    is( $result_pr[7], '(1963 printing)', '260 prefix: lone $g wrapped cleanly' );

    check_combined( \@result, \@result_pr, '260: lone $g combined string identical' );
}

# --- Test 5c: LoC regressions - $e/$f without a trailing $g must close the paren ---
# Real LoC records expose the bug where a terminating $e/$f left the
# parenthetical OPEN (only $g previously emitted the closing ')').
# Fixed 2026-09-10 in _decorate_260_pre (look-ahead for a following e/f/g).
{
    # LoC Current: 260 ## $a[Pennsylvania : $bs.n.], $c1878-[1927?] $e(Gettysburg : $fJ.E. Wible, Printer)
    # render: [LoC - derived] 260 ## $a [Pennsylvania $b s.n.] $c 1878-[1927?] $e Gettysburg $f J.E. Wible, Printer
    # $e + $f with no $g -> the group must close on the terminating $f.
    my $field = make_field(
        '260', ' ', ' ',
        a => '[Pennsylvania',
        b => 's.n.]',
        c => '1878-[1927?]',
        e => 'Gettysburg',
        f => 'J.E. Wible, Printer',
    );

    my @result =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules, 'postfix' );
    is( $result[1], '[Pennsylvania : ', '260 LoC ex1: $a gets " : " for $b' );
    is( $result[3], 's.n.], ',           '260 LoC ex1: $b gets ", " for $c' );
    is( $result[5], '1878-[1927?]',      '260 LoC ex1: $c unchanged (last-1)' );
    is( $result[7], ' (Gettysburg ',     '260 LoC ex1: $e opens paren' );
    is( $result[9], ' : J.E. Wible, Printer)',
        '260 LoC ex1: terminating $f closes the paren (no $g)' );

    my @result_pr =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules, 'prefix' );
    is( $result_pr[9], ' : J.E. Wible, Printer)',
        '260 LoC ex1 prefix: terminating $f closes the paren' );

    check_combined( \@result, \@result_pr, '260 LoC ex1: combined string identical' );
}

{
    # LoC Current: 260 ## $aNew York : $bPublished by W. Schaus, $cc1860 $e(Boston : $fPrinted at J.H. Bufford's)
    # render: [LoC - derived] 260 ## $a New York $b Published by W. Schaus $c c1860 $e Boston $f Printed at J.H. Bufford's
    # $e + $f with no $g -> close on the terminating $f.
    my $field = make_field(
        '260', ' ', ' ',
        a => 'New York',
        b => 'Published by W. Schaus',
        c => 'c1860',
        e => 'Boston',
        f => 'Printed at J.H. Bufford\'s',
    );

    my @result =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules, 'postfix' );
    is( $result[1], 'New York : ',                  '260 LoC ex2: $a gets " : " for $b' );
    is( $result[3], 'Published by W. Schaus, ',     '260 LoC ex2: $b gets ", " for $c' );
    is( $result[5], 'c1860',                         '260 LoC ex2: $c unchanged' );
    is( $result[7], ' (Boston ',                     '260 LoC ex2: $e opens paren' );
    is( $result[9], " : Printed at J.H. Bufford's)",
        '260 LoC ex2: terminating $f closes the paren (no $g)' );

    my @result_pr =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules, 'prefix' );
    is( $result_pr[9], " : Printed at J.H. Bufford's)",
        '260 LoC ex2 prefix: terminating $f closes the paren' );

    check_combined( \@result, \@result_pr, '260 LoC ex2: combined string identical' );
}

{
    # LoC Current: 260 ## $aLondon : $bArts Council of Great Britain, $c1976 $e(Twickenham : $fCTD Printers, $g1974)
    # render: [LoC - derived] 260 ## $a London $b Arts Council of Great Britain $c 1976 $e Twickenham $f CTD Printers $g 1974
    # Full (e : f, g) group: $f does NOT close here (a $g follows), $g closes.
    # (Data cleaned: $f carries no trailing comma in the un-punctuated form.)
    my $field = make_field(
        '260', ' ', ' ',
        a => 'London',
        b => 'Arts Council of Great Britain',
        c => '1976',
        e => 'Twickenham',
        f => 'CTD Printers',
        g => '1974',
    );

    my @result =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules, 'postfix' );
    is( $result[1], 'London : ',                        '260 LoC ex3: $a gets " : " for $b' );
    is( $result[3], 'Arts Council of Great Britain, ', '260 LoC ex3: $b gets ", " for $c' );
    is( $result[5], '1976',                             '260 LoC ex3: $c unchanged' );
    is( $result[7], ' (Twickenham ',                    '260 LoC ex3: $e opens paren' );
    is( $result[9], ' : CTD Printers',                  '260 LoC ex3: $f continues (g follows)' );
    is( $result[11], ', 1974)',                         '260 LoC ex3: $g closes the paren' );

    my @result_pr =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules, 'prefix' );
    is( $result_pr[11], ', 1974)', '260 LoC ex3 prefix: $g closes the paren' );

    check_combined( \@result, \@result_pr, '260 LoC ex3: combined string identical' );
}

{
    # LoC Current: 260 ## $aBethesda, Md. : $bToxicology Information Program ... ; $aSpringfield, Va. : $bNational Technical Information Service [distributor], $c1974- $e(Oak Ridge, Tenn. : $fOak Ridge National Laboratory [generator])
    # render: [LoC - derived] 260 ## $a Bethesda, Md. $b Toxicology Information Program, National Library of Medicine [producer] $a Springfield, Va. $b National Technical Information Service [distributor] $c 1974- $e Oak Ridge, Tenn. $f Oak Ridge National Laboratory [generator]
    # Repeated $a/$b (parallel imprints, ; ) then $e + $f with no $g -> close on $f.
    my $field = make_field(
        '260', ' ', ' ',
        a => 'Bethesda, Md.',
        b => 'Toxicology Information Program, National Library of Medicine [producer]',
        a => 'Springfield, Va.',
        b => 'National Technical Information Service [distributor]',
        c => '1974-',
        e => 'Oak Ridge, Tenn.',
        f => 'Oak Ridge National Laboratory [generator]',
    );

    my @result =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules, 'postfix' );
    is( $result[1], 'Bethesda, Md. : ', '260 LoC ex4: first $a gets " : " for first $b' );
    is( $result[3], 'Toxicology Information Program, National Library of Medicine [producer] ; ',
        '260 LoC ex4: first $b gets " ; " for second $a' );
    is( $result[5], 'Springfield, Va. : ', '260 LoC ex4: second $a gets " : " for second $b' );
    is( $result[7], 'National Technical Information Service [distributor], ',
        '260 LoC ex4: second $b gets ", " for $c' );
    is( $result[9], '1974-',        '260 LoC ex4: $c unchanged' );
    is( $result[11], ' (Oak Ridge, Tenn. ', '260 LoC ex4: $e opens paren' );
    is( $result[13], ' : Oak Ridge National Laboratory [generator])',
        '260 LoC ex4: terminating $f closes the paren (no $g)' );

    my @result_pr =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules, 'prefix' );
    is( $result_pr[13], ' : Oak Ridge National Laboratory [generator])',
        '260 LoC ex4 prefix: terminating $f closes the paren' );

    check_combined( \@result, \@result_pr, '260 LoC ex4: combined string identical' );
}

# --- Test 6: $3 always gets ": " appended ---
# $3 uses "post" (always-appended suffix), not pchrs, so same in both modes.
{
    # render: 260 ## $3 1990 $a New York
    my $field = make_field(
        '260', ' ', ' ',
        '3' => '1990',
        a   => 'New York',
    );

    my @result =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules, 'postfix' );
    is( $result[1], '1990: ',   '260: $3 gets ": " appended via post' );
    is( $result[3], 'New York', '260: $a unchanged' );

    my @result_pr =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules, 'prefix' );
    is( $result_pr[1], '1990: ',   '260 prefix: $3 still gets ": " via post' );
    is( $result_pr[3], 'New York', '260 prefix: $a unchanged' );

    check_combined( \@result, \@result_pr, '260: combined string identical' );
}

# --- 260 $r (parallel data, §4.5) ---
# Constructed: $r fires ' = ' on the preceding $b (no doc example for 260 $r;
# §4.12 defines it, §4.5 gives the pattern).
{
    # render: 260 ## $a London $b Arts Council $r London Arts Council
    my $field = make_field(
        '260', ' ', ' ',
        a => 'London',
        b => 'Arts Council',
        r => 'London Arts Council',
    );

    my @result =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules, 'postfix' );
    is( $result[1], 'London : ',          '260: $a gets " : " for $b' );
    is( $result[3], 'Arts Council = ',    '260: $b gets " = " for $r' );
    is( $result[5], 'London Arts Council', '260: $r unchanged (last sf)' );

    my @result_pr =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules, 'prefix' );
    is( $result_pr[1], 'London',          '260 prefix: $a unchanged' );
    is( $result_pr[3], ' : Arts Council', '260 prefix: $b gets " : " prepended' );
    is( $result_pr[5], ' = London Arts Council', '260 prefix: $r gets " = " prepended' );

    check_combined( \@result, \@result_pr, '260: combined string identical ($r)' );
}

# --- 260 $t (other parallel data, §4.5) ---
# Constructed: $t fires ' = ' on the preceding $b (no doc example for 260 $t).
{
    # render: 260 ## $a London $b Arts Council $t Parallel publisher
    my $field = make_field(
        '260', ' ', ' ',
        a => 'London',
        b => 'Arts Council',
        t => 'Parallel publisher',
    );

    my @result =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules, 'postfix' );
    is( $result[1], 'London : ',          '260: $a gets " : " for $b' );
    is( $result[3], 'Arts Council = ',    '260: $b gets " = " for $t' );
    is( $result[5], 'Parallel publisher', '260: $t unchanged (last sf)' );

    my @result_pr =
      Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field( $field,
        $rules, 'prefix' );
    is( $result_pr[1], 'London',          '260 prefix: $a unchanged' );
    is( $result_pr[3], ' : Arts Council', '260 prefix: $b gets " : " prepended' );
    is( $result_pr[5], ' = Parallel publisher', '260 prefix: $t gets " = " prepended' );

    check_combined( \@result, \@result_pr, '260: combined string identical ($t)' );
}

done_testing();
