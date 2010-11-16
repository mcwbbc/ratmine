package RCM;


################
# RatMine Common Module
#
# by Andrew Vallejos
#
# Has the same module requirements as
# the RatMine Perl Scripts
# 
#
################


sub parseHeader #parses header line
{
	print "Processing Header...\n";
	my $h = shift;
	chomp $h;
	my %i;
	my @header = map
	{	
		s/[\s\.]/_/g; #make things unix friendly
		s/_+$//; #remove trailing underscores
		print $_ . "\n";
		$_;	
	} split(/\t/, $h);
	return \@header;
}

=cut
makeChromosomeItems($item_factory, $writer)

returns reference to hash of chromosome items for rat
writes out the chromosome items if $writer is passed

=cut

sub getChromosomes
{
	return (1..20, 'M', 'X', 'Y');
}

sub addChromosomes
{
	my ($item_doc, $org_item) = shift;
	my $chr = {
		map { $_ => $item_doc->add_item('Chromosome', primaryIdentifier => $_, organism => $org_item) } getChromosomes
	};
	return $chr;
}

1;