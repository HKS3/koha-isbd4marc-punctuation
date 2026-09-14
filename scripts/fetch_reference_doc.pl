#!/usr/bin/env perl
#
# fetch_reference_doc.pl - Fetch the PCC ISBD + MARC Task Group reference
# document and preprocess it into the plain-text form the tooling reads.
#
# The PDF is copyrighted, so it (and its text form) are NOT committed to
# the repository. The text file lives OUTSIDE the git repo (default: the
# project root, i.e. ../isbdmarc2016.txt relative to this script's dir),
# where scripts/build_doc_index.pl and t/99-doc-coverage.t expect it.
#
# Usage:
#   perl scripts/fetch_reference_doc.pl [OUTFILE]
#     OUTFILE  where to write the text (default: $ISBD_REF_DOC or
#              ../isbdmarc2016.txt)
#
# If the target file already exists (non-empty), the fetch is skipped.
# Requires an HTTP client (curl or wget) and poppler-utils' `pdftotext`.
#
# NOTE: this environment has no outbound network access, so this script is
# written but cannot be exercised here. It is meant to be run on a machine
# that can reach https://www.loc.gov.
use strict;
use warnings;
use File::Basename qw(dirname);
use File::Spec;
use File::Temp qw(tempfile);

my $URL = 'https://www.loc.gov/aba/pcc/documents/isbdmarc2016.pdf';

my $here = dirname( File::Spec->rel2abs($0) );
my $out  = shift
  || $ENV{ISBD_REF_DOC}
  || File::Spec->catfile( $here, '..', 'isbdmarc2016.txt' );

if ( -s $out ) {
    print "Reference doc already present: $out (skipping fetch)\n";
    exit 0;
}

# Locate an HTTP client.
my $dl;
for my $cand (qw(curl wget)) {
    $dl = $cand if _have($cand);
}
die "No downloader found (need curl or wget)\n" unless $dl;

_have('pdftotext')
  or die "pdftotext not found (needs poppler-utils) - cannot preprocess PDF\n";

# Download to a temp PDF, then convert to text atomically so a half-written
# target is never left behind.
my ( $tmpfh, $pdftmp ) = tempfile( 'isbdmarc2016.XXXX', SUFFIX => '.pdf', UNLINK => 1 );
close $tmpfh;
unlink $pdftmp;    # let curl/wget create it

my $rc;
if ( $dl eq 'curl' ) {
    $rc = system( 'curl', '-fsSL', '--retry', '3', '-o', $pdftmp, $URL );
}
else {
    $rc = system( 'wget', '-q', '-O', $pdftmp, $URL );
}
die "download failed (exit " . ( $rc & 127 ? $rc : $rc >> 8 ) . ")\n" if $rc;

# Convert. pdftotext writes to the target; use a temp text then rename.
my $txttmp = "$pdftmp.txt";
system( 'pdftotext', $pdftmp, $txttmp ) == 0
  or die "pdftotext failed\n";

rename $txttmp, $out
  or die "cannot move $txttmp to $out: $!\n";
unlink $pdftmp;

print "Wrote $out\n";

sub _have {
    my ($cmd) = @_;
    return system( 'command', '-v', $cmd ) == 0;
}
