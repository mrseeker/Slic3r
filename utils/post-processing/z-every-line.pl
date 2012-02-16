#!/usr/bin/perl

use strict;

my $z = 0;

while ($ARGV[0] =~ '^--') {
	shift; shift;
}

# read stdin and any/all files passed as parameters one line at a time
for (<>) {
	# if we find a Z word, save it
	$z = $1 if /Z(\d+(\.\d+)?)/;

	# if we don't have Z, but we do have X and Y
	if (!/Z/ && /X/ && /Y/ && $z > 0) {
		# chop off the end of the line (incl. comments), saving chopped section in $1
		s/\s*([\r\n\;\(].*)//s;
		# print start of line, insert our Z value then re-add the chopped end of line
		print "$_ Z$z $1";
	}
	else {
		# nothing interesting, print line as-is
		print;
	}
}
