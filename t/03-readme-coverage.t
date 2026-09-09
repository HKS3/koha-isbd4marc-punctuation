#
# Ensure the README "Implemented fields" list stays in sync with the
# active LoC/PCC rule set. This guards against the drift that happened
# after C1/C2 (README lagged 11 missing tags).
#
# The README list must contain EXACTLY the same MARC tags as the rule set,
# regardless of which codebase changed first (a new tag added to the rules
# without a README entry, OR a README entry that has no backing rule).

use strict;
use warnings;
use FindBin qw($RealBin);
use File::Spec;

use lib 't/lib';
use Koha::RecordProcessor::Base;

use Test::More;
use Koha::Filter::MARC::ISBD4MARCPunctuation;

# The rule set this test targets.
my $SET = 'LoC/PCC';
note( "Rule set under test: $SET" );

my $rules = Koha::Filter::MARC::ISBD4MARCPunctuation::rules_for($SET);
my @rule_tags = sort { $a <=> $b } keys %$rules;

# Locate the README at the repo root (tests may be run from anywhere).
my $readme = File::Spec->catfile( $RealBin, '..', 'README.md' );
ok( -f $readme, "README.md found at $readme" )
    or BAIL_OUT( 'README.md not found next to the repo root' );

# Extract the MARC tags listed in the "Implemented fields:" section.
# Only lines of the form "  - `NNN`: ..." are collected, so the helper stays
# scoped to that one list regardless of where it sits in the file.
open my $fh, '<', $readme or die "open $readme: $!";
my @readme_tags;
while ( my $line = <$fh> ) {
    push @readme_tags, $1 if $line =~ /^- `(\d{3})`:/;
}
close $fh;
@readme_tags = sort { $a <=> $b } @readme_tags;

# One authoritative check: the README list equals the rule set, tag for tag.
# Catches BOTH a missing README entry (rule without doc) and a stray README
# entry (doc without rule). Human-friendly diagnostic below.
is_deeply( \@readme_tags, \@rule_tags,
    "README Implemented-fields list matches the $SET rule set (" . scalar(@rule_tags) . " tags)" );

done_testing();
