#!/usr/bin/env perl

use warnings;
use strict;

# splits a diff (patch) at all hunk boundaries, for use in automatic binary search
# uses much more disk than the incremental version but is less complex.

my $diff = '';
my $chunks = 0;

qx/rm -v .tmp_split_patch_cumulative .tmp_spc_*/;

while (<>) {
	if (/^\d+(?:,\d+)?c\d+(?:,\d+)?$/) {
		open(my $FILE, ">>.tmp_spc_$chunks");
		print $FILE $diff;
		close($FILE);
		$chunks++;
	}
	$diff .= $_;
}

open(my $FILE, ">>.tmp_split_patch_cumulative");
print $FILE $diff;
close($FILE);