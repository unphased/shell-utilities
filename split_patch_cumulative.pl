#!/usr/bin/env perl

use warnings;
use strict;

# Splits a diff (patch) at all hunk boundaries, for use in automatic binary search.
# Uses much more disk than the proper incremental diff way but is less complex.
# This splits a single patch into as many versions of the file as there are hunks
# in the patch. It is important to realize that this is only practical in a
# "needle in haystack" situation where the changes are all small & independent. In typical
# situations most of these intermediately generated versions would be completely
# non-functioning code and the binary search bug assumptions are not likely to hold

my $diff = '';
my $chunks = 0;
qx{[[ ! -d ~/.tmp ]] && mkdir ~/.tmp}
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
print "executing dry-run on patch.";
qx{patch --dry-run ~/.tmp/.tmp_spc_sourcefile ~/.tmp/.tmp_split_patch_cumulative};
die if $?;

# Perform binary search over the hunks (as there is no way of knowing which hunks were made at what time chronologically)
my $upper_bound = $chunks
my $lower_bound = 0;
my $cur;
while (1) {
	if ($upper_bound - $lower_bound <= 1) {
		print "Last known good version is $lower_bound";
		last;
	}
	$cur = int(($lower_bound + $upper_bound)/ 2);
	print "Testing $cur now.";
	if (run($cur)) {
		$lower_bound = $cur;
	} else {
		$upper_bound = $cur;
	}
}

sub run {
	my ($index) = @_;
	qx{patch -o $1 ~/.tmp/.tmp_spc_sourcefile ~/.tmp/.tmp_spc_$index}; # obtain and set the $index-th patch

	my $goodbad;
	while (!valid_gb($goodbad)) {
		print '\nTest! good or bad?';
		readline $goodbad;
	}
	if (substr($goodbad,0,1) eq 'g') {
		return 1;
	} else {
		return 0;
	}
}

sub valid_gb {
	return $_ eq 'good' || $_ eq 'bad' || $_ eq 'g' || $_ eq 'b';
}