#!/usr/bin/env perl

use warnings;
use strict;

# Splits a diff (patch) at all hunk boundaries, for use in automatic binary search.
# Uses much more disk than the incremental version but is less complex.

my $diff = '';
my $chunks = 0;

qx{rm ~/.tmp/.tmp*};

while (<STDIN>) {
	if (/^\d+(?:,\d+)?c\d+(?:,\d+)?$/) {
		open(my $FILE, ">>~/.tmp/.tmp_spc_$chunks");
		print $FILE $diff;
		close($FILE);
		$chunks++;
	}
	$diff .= $_;
}

open(my $FILE, ">>~/.tmp/.tmp_split_patch_cumulative");
print $FILE $diff;
close($FILE);
# Finished generating intermediate patches.

# Back up the source file
qx{cp $1 ~/.tmp/.tmp_spc_sourcefile};

# dry-run with patch on target file.
qx{patch --dry-run ~/.tmp/.tmp_spc_sourcefile ~/.tmp/.tmp_split_patch_cumulative};
die if $?;

# Perform binary search over the hunks (as there is no way of knowing which hunks were made at what time chronologically)
for ()

sub run {
	my ($index) = @_;
	qx{patch };

	my $goodbad;
	while (!valid_gb($goodbad)) {
		print '\nTest! good or bad? ';
		readline $goodbad;
	}
	if (substr($goodbad,0,1) eq 'g') {

	} else {

	}
}

sub valid_gb {
	return $_ eq 'good' || $_ eq 'bad' || $_ eq 'g' || $_ eq 'b';
}