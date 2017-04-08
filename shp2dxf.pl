use strict;
use warnings;
use 5.010;

if (!defined $ARGV[1]) {
	die "Usage: shp2dxf dirName EPSGCode\n";
}

use File::Copy qw(copy);

# Setup the offsets for the ISOM codes - depends on if we want ISOM 2017 or not
my $common_isom_offset = 2;
my $custom_isom_offset = 0;
if (defined $ARGV[2] and $ARGV[2] eq "2017") {
	$common_isom_offset = 3;
	$custom_isom_offset = 1;
}

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
		print $common_crt $bdarray[$i][2] . " " . $bdarray[$i][0] . "\n";
	}
}
close $common_crt;

# Loop through each of the .shp files
my @shpfiles = glob "$ARGV[0]/*.shp";

foreach my $file (@shpfiles) {
	my $dirnamelength = (length $ARGV[0]) + 1;
	my $filename = substr $file, $dirnamelength, ((length $file) - $dirnamelength - 4);

	my $ourindex = -1;

	for (my $i = 0; $i <= $#bdarray; $i++) {
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
		system("ogr2ogr -skipfailures -f DXF $ARGV[0]-DXF/$filename.dxf $file -t_srs $epsg -dsco HEADER=header.dxf");
	#	copy "Common.crt", "$ARGV[0]-DXF/$filename.crt";
		my $crt_file = "$ARGV[0]-DXF/$filename.crt";
		open(my $crtdata, '>', $crt_file) or die "Couldn't open $crt_file for writing";
		print $crtdata "$bdarray[$ourindex][2] 0";
		close $crtdata;
	} else {
		# Convert to DXF, use a custom CRT
		my @wanted_entries = getFilteredEntries($filename);
		my $where_string;

		for my $entries (@wanted_entries) {
			$where_string .= "$bdarray[$ourindex][1] = $entries OR ";
		}

		# Remove the extra "OR " from the end of the where string
		$where_string = substr $where_string, 0, (length $where_string) - 3;

		system("ogr2ogr -skipfailures -f DXF $ARGV[0]-DXF/$filename.dxf $file -sql 'SELECT $bdarray[$ourindex][1] AS Layer FROM $filename WHERE $where_string' -t_srs $epsg -dsco HEADER=header.dxf");
		createCustomCRT($filename);
	}
}

sub createCustomCRT {
	my ($filename) = @_;

	my $csvfile = "csv/$filename.csv";
	open(my $csvdata, '<', $csvfile) or die "Couldn't find $csvfile";

	my $crtfile = "$ARGV[0]-DXF/$filename.crt";
	open(my $crtdata, '>', $crtfile) or die "Couldn't open $crtfile for writing";

	while (my $line = <$csvdata>) {
		chomp $line;

		my @fields = split "," , $line;

		if ($fields[$custom_isom_offset] ne "FALSE" and $fields[$custom_isom_offset] !~ "ISOM") {
			print $crtdata "$fields[$custom_isom_offset] $fields[2]\n";
		}
	}

	close $crtdata;
	close $csvdata;
	return 0;
}

sub getFilteredEntries {
	my ($filename) = @_;
	my @entries = ();

	my $csvfile = "csv/$filename.csv";
	open(my $csvdata, '<', $csvfile) or die "Couldn't find $csvfile";

	while (my $line = <$csvdata>) {
		chomp $line;

		my @fields = split "," , $line;

		if ($fields[$custom_isom_offset] ne "FALSE" and $fields[$custom_isom_offset] !~ "ISOM") {
			push @entries, $fields[2];
		}
	}

	close $csvdata;
	return @entries;
}
