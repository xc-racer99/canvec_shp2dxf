use strict;
use warnings;
use 5.010;

if (!defined $ARGV[1]) {
	die "Usage: shp2dxf dirName EPSGCode\n";
}

use File::Copy qw(copy);

# Setup the offsets for the ISOM codes
my $common_isom_offset = 2;
my $custom_isom_offset = 0;

# Setup projection
my $epsg = "EPSG:$ARGV[1]";

# Create output folder
mkdir "$ARGV[0]-DXF", 0755;

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
my @shpfiles = glob "$ARGV[0]/*.shp";

foreach my $file (@shpfiles) {
	my $dirnamelength = (length $ARGV[0]) + 1;
	my $filename = substr $file, $dirnamelength, ((length $file) - $dirnamelength - 4);

	my $ourindex = -1;

	for (my $i = 0; $i < $#bdarray; $i++) {
		if ($filename eq $bdarray[$i][0]) {
			$ourindex = $i;
			last;
		}
	}

	if ( $ourindex == -1 ) {
		warn "$filename not found in BaseData, ignorning\n";
		next;
	}

	if ($bdarray[$ourindex][1] eq "FALSE") {
		# Don't use this symbol
		next;
	} elsif ($bdarray[$ourindex][1] eq "NAME") {
		# Convert to DXF, use the generic CRT
		system("ogr2ogr -skipfailures -f DXF $ARGV[0]-DXF/$filename.dxf $file -sql 'SELECT map_sel_en AS Layer FROM $filename' -t_srs $epsg -dsco HEADER=header.dxf");
		copy "Common.crt", "$ARGV[0]-DXF/$filename.crt";
	} else {
		# Convert to DXF, use a custom CRT
	}
}

sub createCustomCRT {

}

sub getFilteredEntries {

}
