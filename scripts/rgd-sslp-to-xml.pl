#!/usr/bin/perl
# rgd-sslp-to-xml.pl
# purpose: to create a target items xml file for intermine from dbSNP Chromosome Report file
# the script dumps the XML to STDOUT, as per the example on the InterMine wiki
# However, the script also creates a gff3 file to the location specified

use strict;

BEGIN {
  push (@INC, ($0 =~ m:(.*)/.*:)[0] . '../intermine/perl/lib');
}

use XML::Writer;
use InterMine::Item;
use InterMine::ItemFactory;
use InterMine::Model;
use InterMine::Util qw(get_property_value);
use IO qw(Handle File);
use XML::XPath;
use Getopt::Long;
use Cwd;

my ($model_file, $help, $input_file, $output_file);

GetOptions( 'model=s' => \$model_file,
			'input=s' => \$input_file,
			'output=s' => \$output_file,
			'help' => \$help);
			
if($help or !$model_file or !$input_file)
{
	&printHelp;
}

my $model = new InterMine::Model(file => $model_file);
my $item_factory = new InterMine::ItemFactory(model => $model);

my $org_item = $item_factory->make_item('Organism');
$org_item->set('taxonId', '10116');


my $output = new IO::File(">$output_file");
my $writer = new XML::Writer(DATA_MODE => 1, DATA_INDENT => 3, OUTPUT => $output);

$writer->startTag("items");
$org_item->as_xml($writer);

open(IN, $input_file) or die "cannot open $input_file\n";
#process Header
my $line = <IN>;
my %index = parseHeader($line);

my %pubs;
my %chromosomes;

print "Processing Data...\n";
while(<IN>)
{
	chomp;
	my @data = split("\t", $_);
#	print ".";	
	my $sslp_item = $item_factory->make_item("SSLP");
	$sslp_item->set('organism', $org_item);
	$sslp_item->set('primaryIdentifier', $data[$index{SSLP_RGD_ID}]);
	
	my $syn_item = $item_factory->make_item("Synonym");
	$syn_item->set('value', $data[$index{SSLP_RGD_ID}]);
	$syn_item->set('type', "identifier");
	$syn_item->set('subject', $sslp_item);
	$syn_item->as_xml($writer);
	
	$sslp_item->set('symbol', $data[$index{SSLP_SYMBOL}]);
	
	my $syn2_item = $item_factory->make_item("Synonym");
	$syn2_item->set('value', $data[$index{SSLP_SYMBOL}]);
	$syn2_item->set('type', 'symbol');
	$syn2_item->set('subject', $sslp_item);
	$syn2_item->as_xml($writer);
	
	$sslp_item->set('expectedSize', $data[$index{EXPECTED_SIZE}]) unless $data[$index{EXPECTED_SIZE}] eq '';
	
	unless($data[$index{CURATED_REF_PUBMED_ID}] eq '')
	{
		my @curPubs;
		foreach my $pId (split(",", $data[$index{CURATED_REF_PUBMED_ID}]))
		{
			unless(exists $pubs{$pId})
			{
				my $pub = $item_factory->make_item('Publication');
				$pub->set('pubMedId', $pId);
				$pub->as_xml($writer);
				$pubs{$pId} = $pub;
			}
			push(@curPubs, $pubs{$pId});
		}
		$sslp_item->set('publications', \@curPubs);
	}
	
	unless($data[$index{CHROMOSOME}] eq '')
	{
		unless(exists $chromosomes{$data[$index{CHROMOSOME}]})
		{
			my $chrom_item = $item_factory->make_item('Chromosome');
			$chrom_item->set('primaryIdentifier', $data[$index{CHROMOSOME}]);
			$chrom_item->as_xml($writer);
			$chromosomes{$data[$index{CHROMOSOME}]} = $chrom_item;
		}
		
		$sslp_item->set('chromosome', $chromosomes{$data[$index{CHROMOSOME}]});
		
		unless($data[$index{RGSC_genome_assembly_v3_4}] eq '')
		{
			#print "\n$data[$index{'RGSC_genome_assembly_v3_4'}]\n";
			my($start, $end) = split('-', $data[$index{RGSC_genome_assembly_v3_4}]);
			my $loc = $item_factory->make_item('Location');
			#print "$start\t$end\n";
			$loc->set('start', $start);
			$loc->set('end', $end);
			$loc->set('object', $chromosomes{$data[$index{CHROMOSOME}]});
			$loc->set('subject', $sslp_item);
			$loc->as_xml($writer);
			$sslp_item->set('chromosomeLocation', $loc);
		}
	}
	$sslp_item->as_xml($writer);
}#end while(<IN>)
close IN;
$writer->endTag("items");

exit(0);

### Subroutines ###

sub parseHeader #parses header line
{
	print "Processing Header...\n";
	my $h = shift;
	chomp $h;
	my %i;
	my @header = split(/\t/, $h);
	for(my $x = 0; $x < @header; $x++)
	{	
		$header[$x] =~ s/[\s\.]/_/g; #make thinks unix friendly
		$i{$header[$x]} = $x;	
	}
	return %i;
}

sub printHelp
{
print<<HELP;
Help!
HELP
}