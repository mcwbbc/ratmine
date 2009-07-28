#!/usr/bin/perl
# rgd-genes-to-xml.pl
# purpose: to create a target items xml file for intermine from RGD FTP file

use warnings;
use strict;

BEGIN {
  push (@INC, ($0 =~ m:(.*)/.*:)[0] . '../intermine/perl/lib');
}

use XML::Writer;
use InterMine::Item;
use InterMine::ItemFactory;
use InterMine::Model;

my ($model_file, $genes_file) = @ARGV;

die "Must point to valid InterMine Model" unless (-e $model_file);
my $data_source = 'RGD';
my $taxon_id = 10116;


my @items = ();
my %pubs = ();



# The item factory needs the model so that it can check that new objects have
# valid classnames and fields
my $model = new InterMine::Model(file => $model_file);
my $item_factory = new InterMine::ItemFactory(model => $model);

####
#User Additions
my $org_item = $item_factory->make_item('Organism');
$org_item->set('taxonId', $taxon_id);
push(@items, $org_item); #add organism to items list


# read the genes file
open GENES, $genes_file;
my %index;
my $count = 0;
while(<GENES>)
{
	chomp;
	if( $_ !~ /^\d/) #parses header line
	{
		my @header = split(/\t/, $_);
		for(my $i = 0; $i < @header; $i++)
		{	$index{$header[$i]} = $i;	}
	
	}
	else
	{
    #    print "\n   ------------ Line: ".$count."  --------------  \n";
		$_ =~ s/\026/ /g; #replaces 'Syncronous Idle' (Octal 026) character with space
		my @gene_info = split(/\t/, $_);
		my $gene_item = $item_factory->make_item('Gene');
		$gene_item->set('organism', $org_item);
		$gene_item->set('primaryIdentifier', $gene_info[$index{GENE_RGD_ID}]);
		#$gene_item->set('secondaryIdentifier', $gene_info[$index{GENE_RGD_ID}]);
		$gene_item->set('symbol', $gene_info[$index{SYMBOL}]);
		$gene_item->set('name', $gene_info[$index{NAME}]) unless ($gene_info[$index{NAME}] eq '');	
		$gene_item->set('description', $gene_info[$index{GENE_DESC}]) unless ($gene_info[$index{GENE_DESC}] eq '') ;
		$gene_item->set('ncbiGeneNumber', $gene_info[$index{ENTREZ_GENE}]) unless ($gene_info[$index{ENTREZ_GENE}] eq '' or $gene_info[$index{GENE_TYPE}] =~ /splice|allele/i);
		$gene_item->set('geneType', $gene_info[$index{GENE_TYPE}]) unless ($gene_info[$index{GENE_TYPE}]) eq '';
    	
		#process the publications:
    	if ($gene_info[$index{CURATED_REF_PUBMED_ID}] ne '') {
      		#print "Got some pubmed ids: (".$gene_info[$index{CURATED_REF_PUBMED_ID}].")\n";
	      	my @publication_info = split(/,/, $gene_info[$index{CURATED_REF_PUBMED_ID}]);
	      	my @currentPubs = ();
	      	foreach (@publication_info) {
	        #reuse publication object if we already have it in the $pubs array
	        	if (exists $pubs{$_}) {
	          		push(@currentPubs, $pubs{$_});
	        	}
	        	#otherwise, create a new one via the item factory and add it to the $pubs array
	        	else {
	          		my $pub1 = $item_factory->make_item("Publication");
	          		$pub1->set("pubMedId", $_);
	          		$pubs{$_} = $pub1;
	          		push(@currentPubs, $pub1);
	        	}#end if-else
	      	}#end foreach
	      	#print " current pubs on this gene: ".join(", ", @currentPubs)."\n";
	      	$gene_item->set("publications", \@currentPubs);
	      	#print " accumulated pubs:  ".join(", ", %pubs)."\n";
    	}#end if
    	$count++;
    # kick out early for testing:
#    if ($count > 80) {
#      last;
#    }
		push(@items, $gene_item);
	} #end if-else	

}#end while
close GENES;

# write everything out as xml:
my $writer = new XML::Writer(DATA_MODE => 1, DATA_INDENT => 3);
$writer->startTag("items");
#write the organism and the genes
for my $item (@items) {
  $item->as_xml($writer);
}
#write the pubs
for my $item (values(%pubs)) {
  $item->as_xml($writer);
}
$writer->endTag("items");
