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
use File::Temp qw(tempfile);
use File::Slurp qw(read_file write_file);

use lib 't/lib';
use Koha::RecordProcessor::Base;
use Koha::Filter::MARC::ISBD4MARCPunctuation;

use Test::More;

my $ROOT   = File::Spec->catdir( $RealBin, '..' );
my $script = File::Spec->catfile( $ROOT, 'scripts', 'doc_coverage.pl' );
my $yaml   = File::Spec->catfile( $ROOT, 'docs',    'doc_coverage.yaml' );

# The rule set this test targets (for the in-scope tag set).
my $SET = 'LoC/PCC';
note( "Rule set under test: $SET" );
my $rules = Koha::Filter::MARC::ISBD4MARCPunctuation::rules_for($SET);
my @rule_tags = sort { $a <=> $b } keys %$rules;

ok( -f $script, "generator script found at $script" )
    or BAIL_OUT( "scripts/doc_coverage.pl not found next to the repo root" );
ok( -f $yaml, "coverage table found at $yaml" )
    or BAIL_OUT( "docs/doc_coverage.yaml not found next to the repo root" );

# --- 1. Regenerate the YAML into a temp file and byte-compare. ------------
# The committed YAML derives from the markers; regenerating must be a no-op.
my ( $tmpfh, $tmpfile ) = tempfile( 'doc_coverage.XXXX', SUFFIX => '.yaml', UNLINK => 1 );
close $tmpfh;

# Run the generator with the SAME default test glob it uses (t/*.t), writing
# to the temp file so the committed YAML is left untouched for comparison.
my $regen_cmd = "$^X " . quote($script) . " " . quote($tmpfile);
my $out = `$regen_cmd 2>&1`;
my $rc  = $? >> 8;

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

is( $total, 423, "summary.total_examples == 423 (the count after the 260 LoC regressions)" )
    or note( "If new markers were added intentionally, regenerate + update this literal." );

my $exp_kinds = {
    doc          => 226,
    loc          => 32,
    constructed  => 165,
    not_handled  => 0,
};
for my $k ( sort keys %$exp_kinds ) {
    is( $kind_total{$k} // 0, $exp_kinds->{$k},
        "kind '$k' count == $exp_kinds->{$k}" );
}

# --- 3. In-scope tag coverage: every rule-set tag appears in the YAML. ----
my @missing = grep { !$tags_in_yaml{$_} } @rule_tags;
is( scalar(@missing), 0,
        "every $SET rule-set tag appears in the coverage table"
        . ( @missing ? " (missing: @missing)" : "" ) );

done_testing();

# --- helpers ---------------------------------------------------------------
sub quote {
    my ( $s ) = @_;
    $s =~ s/'/'"'"'/g;    # shell single-quote escaping
    return "'$s'";
}
