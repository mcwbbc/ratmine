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
my @header = split(/\t/, $line);

my %strains;
print "Processing Data...\n";
while(<IN>)
{
	chomp;
	my @data = split("\t", $_);
	
	my $sslp_item = $item_factory->make_item('SSLP');
	for(my $x = 0; $x < @data; $x++)
	{
		if($x == 0)
		{
			#print "Set SSLP $data[$x]...\n";
			$sslp_item->set('primaryIdentifier', $data[$x]);
			$sslp_item->as_xml($writer);
		}
		elsif($x > 1 and $data[$x] =~ /^\d+$/)
		{
			unless($strains{$header[$x]})
			{
				print "Set Strain...\n";
				my $strain_item = $item_factory->make_item('Strain');
				$strain_item->set('symbol', $header[$x]);
				$strain_item->as_xml($writer);
				$strains{$header[$x]} = $strain_item;
			}
			#print "Create Allele...\n";
			#print "$strains{$header[$x]}\t$sslp_item\t$data[$x]\n";
			my $allele_item = $item_factory->make_item('SSLPAllele');
			$allele_item->set('strain', $strains{$header[$x]});
			$allele_item->set('sslp', $sslp_item);
			$allele_item->set('length', $data[$x]);
			$allele_item->as_xml($writer);	
		}
	} #end for
}#end while

close IN;
$writer->endTag("items");

### Subroutines ###