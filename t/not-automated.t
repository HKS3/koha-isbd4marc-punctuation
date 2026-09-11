#!/usr/bin/perl
#
# Tests documenting the doc-coverage audit's NOT-HANDLED / DECISION cases
# (DOC-COVERAGE Phase 3, 2026-09-10).
#
# Purpose: pin the CURRENT (unhandled) behaviour of the plugin for each
# documented gap, so that:
#   - the `is()` assert regresses the exact output we produce today
#     (fails on ANY unintended change), and
#   - the `isnot()` assert acts as a "gap-gate": it assumes our output is
#     NOT the ISBD ideal, and FAILS if the gap ever gets implemented (and an
#     implementer forgets to update this test), pointing them at the docs.
#
# Each block mirrors the reference-document convention:
#   # Doc: Current:  - the doc's punctuated IDEAL (Current) form
#   # render: [...]  - the Future (un-punctuated INPUT) form fed into the plugin
#
# Marker provenance:
#   [doc §X.Y - NOT HANDLED: reason]  - genuine gap, we don't try (or can't)
#   [doc §X.Y - DECISION: reason]     - a kept decision (our output is already
#                                       ISBD-acceptable; the . vs , context is
#                                       not MARC-decodable)
#
# Per the audit design, user intentionally supplies the '#N' pin later; the
# marker here carries NO '#N' (generator keeps num:null for these).

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

# Helper: decorate in postfix + prefix modes and return the listrefs.
sub decorate_pair {
    my ( $tag, $i1, $i2, $rules, @sfs ) = @_;
    my $field = make_field( $tag, $i1, $i2, @sfs );
    my @post  = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field(
        $field, $rules, 'postfix' );
    my @pre = Koha::Filter::MARC::ISBD4MARCPunctuation::_decorate_field(
        $field, $rules, 'prefix' );
    return ( \@post, \@pre );
}

# --- Case 1: 245 $o conjunction (NOT HANDLED) ---
# Same-author vs alternative titles cannot be distinguished from MARC.
{
    # Doc: Current: 245 00 $a Lord Macaulay's essays ; $b and, Lays of ancient Rome.
    # render: [doc section 4.6 - NOT HANDLED: $o conjunction (same-author vs alt title not decodable)] 245 00 $a Lord Macaulay's essays $o and $a Lays of ancient Rome
    my $rules = Koha::Filter::MARC::ISBD4MARCPunctuation::rules_for($SET)->{245};
    ok( defined $rules, '245 rules loaded' );

    my ( $post, $pre ) = decorate_pair( '245', '0', '0', $rules,
        a => "Lord Macaulay's essays", o => 'and', a => 'Lays of ancient Rome' );

    # is(): regression-pin - we currently pass $o through unchanged.
    is( $post->[1], "Lord Macaulay's essays", '245 $o: $a unchanged (pass-through)' );
    is( $post->[3], 'and',                    '245 $o: $o unchanged (not punctuated)' );
    is( $post->[5], 'Lays of ancient Rome',   '245 $o: second $a unchanged' );

    # isnot(): gap-gate - our output is NOT the ISBD ideal (missing ' ; and,').
    isnt(
        combined_string(@$post),
        "Lord Macaulay's essays ; and, Lays of ancient Rome.",
        '245 $o: still NOT the ideal (gap open)'
    );
    check_combined( $post, $pre, '245 $o: combined string identical' );
}

# --- Case 2: 242 $o conjunction (NOT HANDLED) ---
{
    # Doc: Current: 245 10 $a Under the hill, or, The story of Venus and Tannhauser.
    # render: [doc section 4.4 - NOT HANDLED: $o conjunction (alt title)] 242 10 $a Under the hill $o or $q The story of Venus and Tannhauser
    my $rules = Koha::Filter::MARC::ISBD4MARCPunctuation::rules_for($SET)->{242};
    ok( defined $rules, '242 rules loaded' );

    my ( $post, $pre ) = decorate_pair( '242', '1', '0', $rules,
        a => 'Under the hill', o => 'or', q => 'The story of Venus and Tannhauser' );

    # is(): regression-pin - partial: $o gets "or, " but $a misses the comma.
    is( $post->[1], 'Under the hill',   '242 $o: $a unchanged' );
    is( $post->[3], 'or, ',             '242 $o: $o gets ", " from $q' );
    is( $post->[5], 'The story of Venus and Tannhauser',
        '242 $o: $q unchanged (last sf)' );

    # isnot(): gap-gate - ideal has "hill, or," (comma after the title).
    isnt(
        combined_string(@$post),
        'Under the hill, or, The story of Venus and Tannhauser.',
        '242 $o: still NOT the ideal (gap open)'
    );
    check_combined( $post, $pre, '242 $o: combined string identical' );
}

# --- Case 3: 242 $a same-author (NOT HANDLED) ---
{
    # Doc: Current: 242 10 $a The first title ; $a A second title.
    # render: [doc section 4.4 - NOT HANDLED: $a same-author shares the title statement; ; not decodable] 242 10 $a The first title $a A second title
    my $rules = Koha::Filter::MARC::ISBD4MARCPunctuation::rules_for($SET)->{242};
    ok( defined $rules, '242 rules loaded (case 3)' );

    my ( $post, $pre ) = decorate_pair( '242', '1', '0', $rules,
        a => 'The first title', a => 'A second title' );

    # is(): regression-pin - repeated $a passes through with no ' ; '.
    is( $post->[1], 'The first title', '242 $a: first $a unchanged' );
    is( $post->[3], 'A second title',  '242 $a: second $a unchanged (no ; )' );

    # isnot(): gap-gate - ideal uses ' ; ' for same-author continuation.
    isnt(
        combined_string(@$post),
        'The first title ; A second title',
        '242 $a: still NOT the ideal (gap open)'
    );
    check_combined( $post, $pre, '242 $a: combined string identical' );
}

# --- Case 4: 240 $p part name (DECISION) ---
# We keep ', ' consistently; the doc allows ', ' or '. '. The choice is a
# kept decision, so our output is already ISBD-acceptable - but the '. ' form
# is a documented alternative we do NOT produce.
{
    # Doc: Current: 240 10 $a Bible. $p N.T.
    # render: [doc section 5.5 - DECISION: $p part context (we keep ', '; the . variant is not produced)] 240 10 $a Bible $p N.T.
    my $rules = Koha::Filter::MARC::ISBD4MARCPunctuation::rules_for($SET)->{240};
    ok( defined $rules, '240 rules loaded' );

    my ( $post, $pre ) = decorate_pair( '240', '1', '0', $rules,
        a => 'Bible', p => 'N.T.' );

    # is(): regression-pin - we keep ', ' (the decided form).
    is( $post->[1], 'Bible, ', '240 $p: $a gets ", " (kept decision)' );
    is( $post->[3], 'N.T.',    '240 $p: $p unchanged (last sf)' );

    # isnot(): gap-gate - we do NOT produce the '. ' alternative.
    isnt(
        combined_string(@$post),
        'Bible. N.T.',
        '240 $p: keeps ", " (the . variant is not produced)'
    );
    check_combined( $post, $pre, '240 $p: combined string identical' );
}

# --- Case 5: 242 $p part name (DECISION) ---
{
    # Doc: Current: 242 10 $a Some work. $p Part one.
    # render: [doc section 4.4 - DECISION: $p part context (we keep ', ')] 242 10 $a Some work $p Part one
    my $rules = Koha::Filter::MARC::ISBD4MARCPunctuation::rules_for($SET)->{242};
    ok( defined $rules, '242 rules loaded (case 5)' );

    my ( $post, $pre ) = decorate_pair( '242', '1', '0', $rules,
        a => 'Some work', p => 'Part one' );

    is( $post->[1], 'Some work, ', '242 $p: $a gets ", " (kept decision)' );
    is( $post->[3], 'Part one',    '242 $p: $p unchanged (last sf)' );

    isnt(
        combined_string(@$post),
        'Some work. Part one',
        '242 $p: keeps ", " (the . variant is not produced)'
    );
    check_combined( $post, $pre, '242 $p: combined string identical' );
}

# --- Case 6: 490 $p part name (DECISION) ---
{
    # Doc: Current: 490 1# $a Series title. $p Part one ; $v 3.
    # render: [doc section 4.2 - DECISION: $p part context (we keep ', ')] 490 10 $a Series title $p Part one $v 3
    my $rules = Koha::Filter::MARC::ISBD4MARCPunctuation::rules_for($SET)->{490};
    ok( defined $rules, '490 rules loaded' );

    my ( $post, $pre ) = decorate_pair( '490', '1', '0', $rules,
        a => 'Series title', p => 'Part one', v => '3' );

    is( $post->[1], 'Series title, ', '490 $p: $a gets ", " (kept decision)' );
    is( $post->[3], 'Part one ; ',    '490 $p: $p gets "; " before $v' );
    is( $post->[5], '3',              '490 $p: $v unchanged (last sf)' );

    isnt(
        combined_string(@$post),
        'Series title. Part one ; 3',
        '490 $p: keeps ", " (the . variant is not produced)'
    );
    check_combined( $post, $pre, '490 $p: combined string identical' );
}

# --- Case 7: 240 $d date of treaty signing (NOT HANDLED) ---
# The rule is unclear - '( )' or ', '. We currently add no punctuation.
{
    # Doc: Current: 240 10 $a Treaty of London (1913).
    # render: [doc section 5.5 - NOT HANDLED: $d date of treaty signing; rule unclear (( ) or , )] 240 10 $a Treaty of London $d 1913
    my $rules = Koha::Filter::MARC::ISBD4MARCPunctuation::rules_for($SET)->{240};
    ok( defined $rules, '240 rules loaded (case 7)' );

    my ( $post, $pre ) = decorate_pair( '240', '1', '0', $rules,
        a => 'Treaty of London', d => '1913' );

    # is(): regression-pin - $d currently passes through with no punct.
    is( $post->[1], 'Treaty of London', '240 $d: $a unchanged' );
    is( $post->[3], '1913',             '240 $d: $d unchanged (no punct)' );

    # isnot(): gap-gate - a possible ideal would parenthesize the date.
    isnt(
        combined_string(@$post),
        'Treaty of London (1913)',
        '240 $d: still NOT parenthesized (gap open)'
    );
    check_combined( $post, $pre, '240 $d: combined string identical' );
}

# --- Case 8: 300 lone $i/$j (no $h) (NOT HANDLED) ---
# Accompanying-material details without a leading $h are not parenthesized.
{
    # Doc: Current: 300 ## $a volumes $b illustrations : $c maps.
    # render: [doc section 4.14 - NOT HANDLED: lone $i/$j (no $h) - no parens, bare ' ; ' may leak] 300 ## $a volumes $i illustrations $j maps
    my $rules = Koha::Filter::MARC::ISBD4MARCPunctuation::rules_for($SET)->{300};
    ok( defined $rules, '300 rules loaded' );

    my ( $post, $pre ) = decorate_pair( '300', ' ', ' ', $rules,
        a => 'volumes', i => 'illustrations', j => 'maps' );

    # is(): regression-pin - bare ' ; ' leaks (no parens without $h).
    is( $post->[1], 'volumes',          '300 lone: $a unchanged' );
    is( $post->[3], 'illustrations ; ', '300 lone: $i gets bare " ; " (no paren)' );
    is( $post->[5], 'maps',             '300 lone: $j unchanged (last sf)' );

    # isnot(): gap-gate - ideal would parenthesize (illustrations : maps).
    isnt(
        combined_string(@$post),
        'volumes (illustrations : maps)',
        '300 lone: still NOT parenthesized (gap open)'
    );
    check_combined( $post, $pre, '300 lone: combined string identical' );
}

# --- Case 9: 700 $i relationship info (NOT HANDLED) ---
{
    # Doc: Current: 700 1# $a Smith, John : $i editor.
    # render: [doc section 5.2 - NOT HANDLED: 700 $i relationship info (colon-space not added)] 700 1  $a Smith, John $i editor
    my $rules = Koha::Filter::MARC::ISBD4MARCPunctuation::rules_for($SET)->{700};
    ok( defined $rules, '700 rules loaded' );

    my ( $post, $pre ) = decorate_pair( '700', '1', ' ', $rules,
        a => 'Smith, John', i => 'editor' );

    # is(): regression-pin - $i passes through with no relationship colon.
    is( $post->[1], 'Smith, John', '700 $i: $a unchanged' );
    is( $post->[3], 'editor',      '700 $i: $i unchanged (no relationship punct)' );

    # isnot(): gap-gate - ISBD wants a colon-space before relationship info.
    isnt(
        combined_string(@$post),
        'Smith, John : editor',
        '700 $i: still NOT colon-spaced (gap open)'
    );
    check_combined( $post, $pre, '700 $i: combined string identical' );
}

# --- Case 10: 580 $i comma before a later $i (NOT HANDLED) ---
# The comma before a later "$i to form" is not reproduced (following K10plus).
{
    # Doc: Current: 580 ## $a Merged with: Index chemicus (Philadelphia, Pa. : 1977), to form: Current abstracts of chemistry.
    # render: [doc 4.34 - NOT HANDLED: comma before a later $i ("... , to form") not reproduced] 580 ## $i Merged with $a Index chemicus (Philadelphia, Pa. : 1977) $i to form $a Current abstracts of chemistry
    my $rules = Koha::Filter::MARC::ISBD4MARCPunctuation::rules_for($SET)->{580};
    ok( defined $rules, '580 rules loaded' );

    my ( $post, $pre ) = decorate_pair( '580', ' ', ' ', $rules,
        i => 'Merged with',
        a => 'Index chemicus (Philadelphia, Pa. : 1977)',
        i => 'to form',
        a => 'Current abstracts of chemistry' );

    # is(): regression-pin - the comma before the later $i is omitted.
    is( $post->[1], 'Merged with: ', '580: first $i gets ": "' );
    is( $post->[3], 'Index chemicus (Philadelphia, Pa. : 1977)',
        '580: $a unchanged' );
    is( $post->[5], 'to form: ',    '580: later $i gets ": " but NO preceding comma' );
    is( $post->[7], 'Current abstracts of chemistry',
        '580: final $a unchanged (last sf)' );

    # isnot(): gap-gate - ideal has "... : 1977), to form:" (comma before $i).
    isnt(
        combined_string(@$post),
        'Merged with: Index chemicus (Philadelphia, Pa. : 1977), to form: Current abstracts of chemistry',
        '580: still NOT comma-before-later-$i (gap open)'
    );
    check_combined( $post, $pre, '580: combined string identical' );
}

# --- Case 11: 880 alternate script (NOT HANDLED) ---
# No $6 dispatch to apply the referenced tag's punctuation; pass-through.
{
    # Doc: Current: 880 ## $6 260-12/(N $a Moskva : $b Izd-vo "Nauka", $c 1982.
    # render: [doc 3.26 - NOT HANDLED: 880 alternate script (no $6 dispatch; pass-through)] 880 ## $a Moskva $b Izd-vo "Nauka" $c 1982
    my $rules = Koha::Filter::MARC::ISBD4MARCPunctuation::rules_for($SET)->{880};

    # 880 has no rules block -> pass-through unchanged.
    my ( $post, $pre ) = decorate_pair( '880', ' ', ' ', $rules,
        a => 'Moskva', b => 'Izd-vo "Nauka"', c => '1982' );

    # is(): regression-pin - input unchanged.
    is( $post->[1], 'Moskva',            '880: $a unchanged (pass-through)' );
    is( $post->[3], 'Izd-vo "Nauka"',    '880: $b unchanged' );
    is( $post->[5], '1982',              '880: $c unchanged' );

    # isnot(): gap-gate - ideal would apply the target tag's punct (": ", ", ").
    isnt(
        combined_string(@$post),
        'Moskva : Izd-vo "Nauka", 1982',
        '880: still NOT punctuated (pass-through, gap open)'
    );
    check_combined( $post, $pre, '880: combined string identical' );
}

# --- Case 12: 110 $g-combined manual cases (NOT HANDLED) ---
# $g combined with $n/$c/$d in a single parenthetical is not automatable.
{
    # Doc: Current: 111 2# $a National Conference on Physical Measurement of the Disabled, $n 2nd, $c Mayo Clinic, $d 1981, $g Projected, not held.
    # render: [doc section 5.4 - NOT HANDLED: $g combined with $n/$c/$d in one paren; manual] 110 2  $a National Conference on Physical Measurement of the Disabled $n 2nd $c Mayo Clinic $d 1981 $g Projected, not held
    my $rules = Koha::Filter::MARC::ISBD4MARCPunctuation::rules_for($SET)->{110};
    ok( defined $rules, '110 rules loaded' );

    my ( $post, $pre ) = decorate_pair( '110', '2', ' ', $rules,
        a => 'National Conference on Physical Measurement of the Disabled',
        n => '2nd', c => 'Mayo Clinic', d => '1981', g => 'Projected, not held' );

    # is(): regression-pin - the n/c/d run groups as (2nd Mayo Clinic 1981)
    # and $g as a separate (Projected, not held).
    is( $post->[1], 'National Conference on Physical Measurement of the Disabled',
        '110 $g: $a unchanged' );
    is( $post->[3], ' (2nd',       '110 $g: $n opens the n/d/c meeting run' );
    is( $post->[5], 'Mayo Clinic', '110 $g: $c continues the run' );
    is( $post->[7], '1981)',       '110 $g: $d closes the run' );
    is( $post->[9], ' (Projected, not held)',
        '110 $g: $g gets its own separate paren group' );

    # isnot(): gap-gate - ideal joins $g into the SAME paren as n/c/d with
    # comma separators (manual, not produced automatically).
    isnt(
        combined_string(@$post),
        'National Conference on Physical Measurement of the Disabled, 2nd, Mayo Clinic, 1981, Projected, not held.',
        '110 $g: $g not merged into the n/c/d paren (manual, gap open)'
    );
    check_combined( $post, $pre, '110 $g: combined string identical' );
}

done_testing();
