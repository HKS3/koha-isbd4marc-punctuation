#
# Phase 1 doc-coverage guard (DOC-COVERAGE AUDIT, approved 2026-09-09).
#
# Proves that the generated coverage table (docs/doc_coverage.yaml) is
# byte-for-byte in sync with the "# render:" markers that are the single
# source of truth in the t/*.t files, and that it reflects full in-scope
# field coverage.
#
# Phase 1 is deliberately a "trivially green" skeleton: it asserts the
# generator is deterministic and the table is complete at the C0UNT level
# only. The strict per-example red/green gate (every in-scope doc example is
# covered/derived/not_handled) arrives in Phase 4 of the audit.
#
# Two failure modes this catches:
#   - a test's "# render:" marker changed but the YAML was not regenerated;
#   - a field was added/removed but the YAML summary/field list drifted.
#
# Implementation notes:
#   - Byte-compare (NOT git diff): the test regenerates the YAML into a temp
#     file and compares bytes to the committed docs/doc_coverage.yaml. This
#     keeps the check self-contained (works outside a git checkout) and
#     independent of shell/git quoting.
#   - The generator (scripts/doc_coverage.pl) is the single source of truth;
#     we reuse it rather than re-implementing marker parsing.

use strict;
use warnings;
use FindBin qw($RealBin);
use File::Spec;
use File::Temp  qw(tempfile);
use File::Slurp qw(read_file write_file);

use lib 't/lib';
use Koha::RecordProcessor::Base;
use Koha::Filter::MARC::ISBD4MARCPunctuation;

use Test::More;
use JSON;

my $ROOT       = File::Spec->catdir( $RealBin, '..' );
my $script     = File::Spec->catfile( $ROOT, 'scripts', 'doc_coverage.pl' );
my $yaml       = File::Spec->catfile( $ROOT, 'docs',    'doc_coverage.yaml' );
my $idx_script = File::Spec->catfile( $ROOT, 'scripts', 'build_doc_index.pl' );
my $fetch_script =
  File::Spec->catfile( $ROOT, 'scripts', 'fetch_reference_doc.pl' );
my $doctxt =
  $ENV{ISBD_REF_DOC} || File::Spec->catfile( $ROOT, '..', 'isbdmarc2016.txt' );

# The rule set this test targets (for the in-scope tag set).
my $SET = 'LoC/PCC';
note("Rule set under test: $SET");
my $rules     = Koha::Filter::MARC::ISBD4MARCPunctuation::rules_for($SET);
my @rule_tags = sort { $a <=> $b } keys %$rules;

ok( -f $script, "generator script found at $script" )
  or BAIL_OUT("scripts/doc_coverage.pl not found next to the repo root");
ok( -f $yaml, "coverage table found at $yaml" )
  or BAIL_OUT("docs/doc_coverage.yaml not found next to the repo root");

# --- 1. Regenerate the YAML into a temp file and byte-compare. ------------
# The committed YAML derives from the markers; regenerating must be a no-op.
my ( $tmpfh, $tmpfile ) =
  tempfile( 'doc_coverage.XXXX', SUFFIX => '.yaml', UNLINK => 1 );
close $tmpfh;

# Run the generator with the SAME default test glob it uses (t/*.t), writing
# to the temp file so the committed YAML is left untouched for comparison.
my $regen_cmd = "$^X " . quote($script) . " " . quote($tmpfile);
my $out       = `$regen_cmd 2>&1`;
my $rc        = $? >> 8;

ok( $rc == 0, "generator exits 0 (it ran: $out)" );

my $before = read_file($yaml);
my $after  = read_file($tmpfile);

is( $after, $before,
"docs/doc_coverage.yaml is byte-identical after regeneration (table in sync with t/*.t markers)"
);

# --- 2. Summary count assertions (Phase-1 "counts only" scope). -----------
open my $fh, '<', $yaml or die "open $yaml: $!";
my $cur_tag;
my $total = 0;
my %kind_total;
my %tags_in_yaml;
while ( my $line = <$fh> ) {
    if ( $line =~ /^\s*-\s*tag:\s*"(\d+)"/ ) {
        $cur_tag = $1;
        $tags_in_yaml{$cur_tag} = 1;
    }
    elsif ( $line =~ /^\s+kind:\s*(\w+)/ && defined $cur_tag ) {
        my $kind = $1;
        $kind_total{$kind}++;
        $total++;
    }
}
close $fh;

is( $total, 462,
"summary.total_examples == 462 (after the 260 LoC regressions + t/not-automated.t + §4.13 264 pins + §4.35 embedded NOT-HANDLED + §4.21 500 #3/#4 pins + §5.2 #3/#4/#5/#6/#8 pins + §4.6 #6 alt-title \$o + §5.7 #2/#5 pins + §5.6 #3/#6 pins + §3.2 #5/#6 pins + §4.18 #5 DECISION + §3.14 #3 pin + §3.17 #3 pin + §3.20 #2 pin + §3.22 #2 pin + §3.23 #3 pin + §4.22 #3 pin + §4.25 #2 pin + §4.26 #3 pin + §3.24 #2/#3 pins)"
  )
  or note(
    "If new markers were added intentionally, regenerate + update this literal."
  );

my $exp_kinds = {
    doc         => 255,
    loc         => 31,
    constructed => 159,
    not_handled => 13,
    decision    => 4,
};
for my $k ( sort keys %$exp_kinds ) {
    is( $kind_total{$k} // 0,
        $exp_kinds->{$k}, "kind '$k' count == $exp_kinds->{$k}" );
}

# --- 3. In-scope tag coverage: every rule-set tag appears in the YAML. ----
my @missing = grep { !$tags_in_yaml{$_} } @rule_tags;
is( scalar(@missing), 0,
    "every $SET rule-set tag appears in the coverage table"
      . ( @missing ? " (missing: @missing)" : "" ) );

# --- 4. Phase-4 per-section red/green gate. -------------------------------
# For every section in the reference doc that is IN SCOPE, every documented
# "Current/Future" example must be accounted for in the t/*.t markers as
# either a pinned #N, a '- derived', a NOT-HANDLED, or a DECISION. A section
# with fewer accounted markers than index pairs fails.
#
# The index is built AT TEST TIME (scripts/build_doc_index.pl against the
# reference doc text) so the reference doc stays the single source of truth
# and doc edits are caught rather than silently drifting from a committed
# copy. The doc path defaults to ../isbdmarc2016.txt (outside the git repo,
# for copyright reasons) and can be overridden via $ENV{ISBD_REF_DOC}.
# Section keys are the plain X.Y form (e.g. 3.24, 4.1).

# Declared exclusions.
#
# 4.1 is out of scope: Leader/18 is a leader byte, not a MARC field, so the
# 3-digit-field render gate does not apply. Its Current/Future examples
# describe the punctuation-omission trigger (c / blank / n) that the plugin
# keys off, NOT a field render - so they can never be represented as a
# NOT-HANDLED marker in t/not-automated.t (that mechanism is for MARC fields
# only). The leader/18 logic is already exercised directly in t/22-filter.t.
# This exclusion is PERMANENT: do not add a bogus marker for it.
#
# No other section is excluded: every in-scope field section is pinned or
# classified, so the gate runs strictly over all remaining sections.
my %exclude =
  ( '4.1' =>
'Leader/18 - out of scope (leader byte, not a MARC field; punctuation-trigger semantics, not a field render)',
  );

ok( -f $idx_script, "indexer script found at $idx_script" )
  or BAIL_OUT("scripts/build_doc_index.pl not found next to the repo root");
ok( -f $doctxt, "reference doc found at $doctxt" )
  or BAIL_OUT( "reference doc not found at $doctxt; run `perl "
      . quote($fetch_script)
      . "` to fetch+preprocess it (needs network + pdftotext), "
      . "or set ISBD_REF_DOC to its location" );

# Build the index into a temp JSON file (the script writes the file itself;
# its stdout is only a one-line summary, which we ignore).
my ( $idxtmpfh, $idxtmp ) =
  tempfile( 'doc_index.XXXX', SUFFIX => '.json', UNLINK => 1 );
close $idxtmpfh;
my $idx_cmd =
  "$^X " . quote($idx_script) . " " . quote($doctxt) . " " . quote($idxtmp);
my $idx_out = `$idx_cmd 2>&1`;
my $idx_rc  = $? >> 8;
ok( $idx_rc == 0, "reference-doc index builds (it said: $idx_out)" )
  or BAIL_OUT("build_doc_index.pl failed to build the index");

my $idx_json = read_file($idxtmp);
my $index    = eval { JSON->new->decode($idx_json) };
ok(
    $@ eq '' && ref $index eq 'HASH' && scalar( keys %$index ),
    "reference-doc index parsed (" . scalar( keys %$index ) . " sections)"
) or BAIL_OUT("index JSON did not parse");

# Per-section marker coverage: scan the t/*.t files and count, per section
# key (plain X.Y), how many # render: [doc ...]/[LoC ...] markers carry that
# section. Each pinned #N, '- derived', NOT-HANDLED, or DECISION marker that
# names a section counts as one accounted example. This mirrors the marker
# as the single source of truth (like scripts/doc_coverage.pl), independent
# of the YAML representation (which leaves section empty on skip rows).
my %cov;
for my $file ( glob( File::Spec->catfile( $ROOT, 't', '*.t' ) ) ) {
    open my $fh, '<', $file or die "open $file: $!";
    while ( my $line = <$fh> ) {
        next unless $line =~ /render:/;

        # Extract the section X.Y from ANY [doc ...]/[LoC ...] bracket
        # content: e.g. '3.24 #1', 'section 4.14 - NOT HANDLED: ...'.
        while ( $line =~ /\[(?:doc|LoC)\b([^\]]*)\]/gi ) {
            my $inner = $1;
            $cov{$1}++ if $inner =~ /([0-9]+\.[0-9]+)/;
        }
    }
    close $fh;
}

# Strict red/green per in-scope section.
my @gate_short;
for my $sec ( sort { $a <=> $b } keys %$index ) {
    next if exists $exclude{$sec};
    my $pairs = scalar @{ $index->{$sec} };
    my $have  = $cov{$sec} // 0;
    if ( $have < $pairs ) {
        push @gate_short,
          sprintf( '%s (idx %d, covered %d)', $sec, $pairs, $have );
    }
}
is( scalar(@gate_short), 0,
    "Phase 4: every in-scope doc section fully covered (pinned+derived+skip)"
      . ( @gate_short ? " -- SHORT: " . join( ', ', @gate_short ) : "" ) );

# Bonus diagnostic for humans: report every excluded section so the gate's
# blind spots are explicit in the output.
note( "Excluded sections: "
      . join( ', ', map { "$_ ($exclude{$_})" } sort keys %exclude ) );

done_testing();

# --- helpers ---------------------------------------------------------------
sub quote {
    my ($s) = @_;
    $s =~ s/'/'"'"'/g;    # shell single-quote escaping
    return "'$s'";
}
