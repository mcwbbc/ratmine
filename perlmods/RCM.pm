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

=cut
makeChromosomeItems($item_factory, $writer)

returns reference to hash of chromosome items for rat
writes out the chromosome items if $writer is passed

=cut

sub makeChromosomeItems
{
	my ($item_factory, $writer) = @_;
	
	my @chromosomes = (1..20, 'M', 'X');
	
	%chromosome_items;
	foreach my $chr (@chromosomes)
	{
		$chrom_item = $item_factory->make_item('Chromosome');
		$chrom_item->set('primaryIdentifier', $chr);
		$chrom_item->as_xml($writer) if $writer;
		$chromosome_items{$chr} = $chrom_item;

	}
	
	return \%chromosome_items;
}

sub makeLocationItem
{
	my ($item_factory, $writer, $chrom_item, $start, $end) = @_;
	
	$end = $start unless defined($end);
	my $loc_item = $item_factory->make_item('Location');
	$loc_item->set('object', $chrom_item);
	$loc_item->set('start', $start);
	$loc_item->set('end', $end);
	$loc_item->as_xml($writer);
	
	return $loc_item;
}
1;