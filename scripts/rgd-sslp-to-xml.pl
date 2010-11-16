#!/usr/bin/perl
# rgd-sslp-to-xml.pl
# purpose: to create a target items xml file for intermine from dbSNP Chromosome Report file
# the script dumps the XML to STDOUT, as per the example on the InterMine wiki
# However, the script also creates a gff3 file to the location specified

use strict;

BEGIN {
  push (@INC, ($0 =~ m:(.*)/.*:)[0] . '../../intermine/perl/InterMine-Util/lib');
}

use InterMine::Item::Document;
use InterMine::Model;
use InterMine::Util qw(get_property_value);
use IO qw(Handle File);
use Getopt::Long;
use lib '../perlmods';
use RCM;
use List::MoreUtils qw/zip/;

my ($model_file, $help, $input_file, $output_file);

GetOptions( 'model=s' => \$model_file,
			'input=s' => \$input_file,
			'output=s' => \$output_file,
			'help' => \$help);
			
if($help or !($model_file and $input_file))
{
	&printHelp;
	exit(0);
}

my $model = new InterMine::Model(file => $model_file);
my $item_doc = new InterMine::Item::Document(model => $model, output => $output_file, auto_write => 1);

my $taxon_id = '10116';

my $org_item = $item_doc->add_item('Organism', taxonId => $taxon_id);

#process Header

my $chrom_items;
$chrom_items = RCM::addChromosomes($item_doc, $org_item);

my %pubs;
print "Processing Data...\n";
open(my $IN, '<', $input_file) or die "cannot open $input_file\n";

my $index;
while(<$IN>)
{
	chomp;
	if(/^\D/) #parses header line
	{
		$index = &RCM::parseHeader($_);
		next
	}
  
	my @fields = split(/\t/);
   	my %data = zip(@$index, @fields);

	my %sslp_attr = ('organism' => $org_item,
						'primaryIdentifier' => $data{SSLP_RGD_ID},
						'symbol' => $data{SSLP_SYMBOL});
						
	$sslp_attr{expectedSize} = $data{EXPECTED_SIZE} if $data{EXPECTED_SIZE};
	
	if (my $ids = $data{CURATED_REF_PUBMED_ID}) 
	{
      	for my $id (split(/,/, $ids))
		{
			$pubs{$id} = $item_doc->add_item('Publication', pubMedId => $id) unless ($pubs{$id});
			push @{$sslp_attr{publications}}, $pubs{$id};
		}
	}

	my $chrom = $chrom_items->{$data{CHROMOSOME}};
	$sslp_attr{chromosome} = $chrom if $chrom;
		
	if($data{CHROMOSOME} and $data{RGSC_genome_assembly_v3_4})
	{
		#print "\n$data[$index{'RGSC_genome_assembly_v3_4'}]\n";
		my($start, $end) = split('-', $data{RGSC_genome_assembly_v3_4});
		$sslp_attr{locations} = [ $item_doc->add_item( 'Location',
												locatedOn => $chrom,
												start => $start,
												end => $end
												)];

	}
	
	my $sslp_item = $item_doc->add_item(SimpleSequenceLengthVariation => %sslp_attr);
	$item_doc->add_item('Synonym', value => $data{SSLP_SYMBOL}, subject => $sslp_item);
	$item_doc->add_item('Synonym', value => $data{SSLP_RGD_ID}, subject => $sslp_item);
	
}#end while(<IN>)
close $IN;
$item_doc->close();

exit(0);

### Subroutines ###

sub printHelp
{
print<<HELP;
perl rgd-sslp-to-xml.pl

arguments:
model	model file
input	RGD flat file
output	XML output file
help	prints this message
			
HELP
}