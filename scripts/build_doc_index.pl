#!/usr/bin/env perl
#
# build_doc_index.pl - Build an in-memory index of the isbdmarc2016.txt
# "Examples" Current/Future pairs, keyed by section X.Y, in doc order.
#
# Used by two consumers:
#   - the Phase 2 matcher (pins '#N' onto '# render: [doc §X.Y]' markers)
#   - the Phase 4 t/99 per-section red/green gate (expected per-section
#     doc-example counts, built at TEST TIME so the reference doc stays the
#     single source of truth).
#
# The index is deterministic (canonical, ASCII-safe JSON), so committing it
# would be harmless -- but the gate deliberately re-runs this at test time so
# a change to isbdmarc2016.txt is caught automatically rather than silently
# drifting from a committed copy.
#
# Usage:
#   perl scripts/build_doc_index.pl [DOCFILE] [OUTFILE]
#     DOCFILE  path to isbdmarc2016.txt (default ../isbdmarc2016.txt, i.e.
#              the project root next to this repo)
#     OUTFILE  JSON output path (default tmp/doc_index.json, created under
#              the repo dir)
# Output: writes the deterministic JSON index; prints a one-line summary.
use strict;
use warnings;
use JSON;

my $doc      = shift || $ENV{ISBD_REF_DOC} || '../isbdmarc2016.txt';
my $outfile  = shift || 'tmp/doc_index.json';
open my $fh, '<', $doc or die "cannot open $doc: $!";
my @lines = <$fh>;
close $fh;

# Section heading pattern: "3.1 – Bibliographic Field 015 ..."
# Capture the "X.Y" leading number.
my $section;    # current section key, e.g. "4.12"
my %sections;   # section_key => [ { current => [...], future => [...] }, ... ] in order

# We only care about the "Examples" region. A Current/Future pair begins with
# a line starting "Current:" (possibly on the same line, possibly after
# whitespace). The Future line follows; both may wrap across physical lines.
my $idx = undef;      # { current => bool } for the pair currently being collected
my @cur_buf;          # physical lines of the current Current: value
my @fut_buf;          # physical lines of the current Future: value

sub flush_pair {
    return unless defined $section;
    my $cur = join( ' ', map { _tidy($_) } @cur_buf );
    my $fut = join( ' ', map { _tidy($_) } @fut_buf );
    return if $cur eq '' && $fut eq '';
    push @{ $sections{$section} }, { current => $cur, future => $fut };
}

sub _tidy {
    my ($s) = @_;
    $s =~ s/^\s+|\s+$//g;
    $s =~ s/\s+/ /g;
    return $s;
}

for my $raw (@lines) {
    my $line = $raw;
    $line =~ s/\r?\n$//;

    # Strip a leading form-feed (page break). Many section headings are
    # preceded by a \f byte; if we classify BEFORE stripping it, the heading
    # regex misses them and the heading is folded into the previous section's
    # Future buffer, dragging the whole next rules-table in as noise.
    $line =~ s/^\f//;

    # Stop at the first Appendix heading. The Appendices (A-D) are out of
    # scope here (our markers are all numeric sections 3.x-5.7), and after
    # the last numeric section no X.Y heading exists to bound the parse, so
    # the appendix/summary prose would otherwise bleed into the final
    # example. The front-matter TOC 'Appendix A ...' line is ignored because
    # $section is undefined there.
    last if defined $section && $line =~ /^Appendix\s+[A-D]\b/;

    # Section heading? (X.Y)
    if ( $line =~ /^(\d+\.\d+)\s+/ ) {
        flush_pair();
        $section = $1;
        @cur_buf = ();
        @fut_buf = ();
        $idx = undef;
        next;
    }

    # Bare standalone page-number line (whitespace + small integer), e.g.
    # "     12". Not example content; skip so it can't leak into a value.
    next if $line =~ /^\s*\d{1,3}\s*$/ && $section && $idx;

    next unless defined $section;

    if ( $line =~ /^\s*Current:\s?(.*)$/ ) {
        flush_pair();
        @cur_buf = ( $1 );
        @fut_buf = ();
        $idx = { cur => 1 };
        next;
    }
    if ( $line =~ /^\s*Future:\s?(.*)$/ ) {
        @fut_buf = ( $1 );
        $idx = { cur => 0 };
        next;
    }
    # Continuation lines: a bare line (non-blank) that isn't a new keyword,
    # heading, or blank. Fold it into the current Current/Future value.
    # The doc wraps values across physical lines at COLUMN 0 (no leading
    # whitespace), e.g. 255's `...1/16" = approximately` + `1000'.`. The
    # keyword/heading/blank cases above have already `next`ed out, so any
    # line reaching here while `$idx` is set is a value continuation and is
    # folded regardless of leading whitespace (BUG 3 fix - col-0 wraps were
    # previously dropped, truncating the indexed values).
    if ( $idx ) {
        if ( $idx->{cur} ) {
            push @cur_buf, $line;
        }
        else {
            push @fut_buf, $line;
        }
    }
}
flush_pair();

# Emit deterministic JSON.
my $json = JSON->new->canonical->pretty;
my $out  = $json->encode( \%sections );
open my $ofh, '>', $outfile or die "cannot write $outfile: $!";
print $ofh $out;
close $ofh;

# Brief report
my $sec_count  = scalar keys %sections;
my $pair_count = 0;
$pair_count += scalar @{$_} for values %sections;
print "Sections: $sec_count, Current/Future pairs: $pair_count\n";
print "Wrote $outfile\n";
