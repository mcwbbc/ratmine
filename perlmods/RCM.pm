package RCM;

use lib '.';
use ITEMHOLDER;

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

sub makeChromosomeItems
{
	my ($item_document, $writer) = @_;
	
	my @chromosomes = (1..20, 'M', 'X', 'Y');
	
	$chromosome_items = ITEMHOLDER->new;
	foreach my $chr (@chromosomes)
	{
		$chrom_item = $item_document->add_item('Chromosome', 'primaryIdentifier' => $chr);
		$chrom_item->as_xml($writer) if $writer;
		$chromosome_items->store($chr, $chrom_item);
	}
	
	return $chromosome_items;
}

sub getChromosomes
{
	return (1..20, 'M', 'X', 'Y');
}

sub makeLocationItem
{
	my ($item_document, $feature, $writer, $chrom_item, $start, $end) = @_;
	
	$end = $start unless defined($end);
	my $loc_item = $item_document->make_item('Location');
	$loc_item->set('locatedOn', $chrom_item);
	$loc_item->set('start', $start);
	$loc_item->set('end', $end);
	$loc_item->set('feature', $feature);
	$loc_item->as_xml($writer);
	
	return $loc_item;
}
1;