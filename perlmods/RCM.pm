package RCM;

sub parseHeader #parses header line
{
	print "Processing Header...\n";
	my $h = shift;
	chomp $h;
	my %i;
	my @header = split(/\t/, $h);
	for(my $x = 0; $x < @header; $x++)
	{	
		$header[$x] =~ s/[\s\.]/_/g; #make things unix friendly
		print $header[$x] . "\n";
		$i{$header[$x]} = $x;	
	}
	return %i;
}


1;