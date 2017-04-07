use strict;
use warnings;
use 5.010;

# Setup the offsets for the ISOM codes
my $common_isom_offset = 2;
my $custom_isom_offset = 0;

# Open the BaseNames.csv file
my $basefile = 'csv/BaseNames.csv';

open(my $basedata, '<', $basefile) or die "Couldn't find $basefile";

# Create common CRT file
my $common_crt_file = 'Common.crt';
open(my $common_crt, '>', $common_crt_file) or die "Couldn't open $common_crt_file";

while (my $line = <$basedata>) {
	chomp $line;

	my @fields = split "," , $line;
	if ($fields[1] eq "NAME" ) {
		print $common_crt $fields[$common_isom_offset] . " " . $fields[0] . "\n";
	}
}
close $common_crt;

# Loop through each file in SHP files directory



close $basedata;
