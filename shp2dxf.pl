use strict;
use warnings;
use 5.010;

# Setup the offsets for the ISOM codes
my $common_isom_offset = 2;
my $custom_isom_offset = 0;

# Open the BaseNames.csv file
my $basefile = 'csv/BaseNames.csv';
open(my $basedata, '<', $basefile) or die "Couldn't find $basefile";

# Create an multi-dimensional array, [i][0] = filename, [i][1] = Layer name, [i][2] = ISOM code
my @bdarray = ();
my $i = 0;
while (my $line = <$basedata>) {
	chomp $line;

	my @fields = split "," , $line;
	push @{ $bdarray[$i] }, $fields[0];
	push @{ $bdarray[$i] }, $fields[1];
 	push @{ $bdarray[$i] }, $fields[$common_isom_offset];
	$i++;
}
close $basedata;

# Create common CRT file
my $common_crt_file = 'Common.crt';
open(my $common_crt, '>', $common_crt_file) or die "Couldn't open $common_crt_file";

for (my $i = 0; $i < $#bdarray; $i++) {
	if ($bdarray[$i][1] eq "NAME" ) {
		print $common_crt $bdarray[$i][$common_isom_offset] . " " . $bdarray[$i][0] . "\n";
	}
}
close $common_crt;

# Loop through each of the .shp files




