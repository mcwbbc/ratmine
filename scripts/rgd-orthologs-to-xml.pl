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
	printHelp();
	exit(0);
}

my $model = new InterMine::Model(file => $model_file);
my $item_doc = new InterMine::Item::Document(model => $model, output => $output_file, auto_write => 1);

my $rat_tax = '10116';
my $mouse_tax = '10090';
my $human_tax = '9606';

my $rat_item = $item_doc->add_item('Organism', taxonId => $rat_tax);
my $mouse_item = $item_doc->add_item('Organism', taxonId => $mouse_tax);
my $human_item = $item_doc->add_item('Organism', taxonId => $human_tax);

#process Header

print "Processing Data...\n";
open(my $IN, '<', $input_file) or die "cannot open $input_file\n";

my $index;
my %mouse_genes;
my %human_genes;
my %rat_genes;
my %sources;
my $header_flag = 0;
while(<$IN>)
{
	next if /^#/; #ignore comment lines
	chomp;
	unless($header_flag) #parses header line
	{
		$index = RCM::parseHeader($_);
		$header_flag = 1;
		next
	}
  
	my @fields = split(/\t/);
   	my %data = zip(@$index, @fields);

        # Check to see if a Rat Gene exists before creating a new record
	if(!exists($rat_genes{$data{RAT_GENE_RGD_ID}})){
		#print $data{RAT_GENE_RGD_ID} . "\n";
		$rat_genes{$data{RAT_GENE_RGD_ID}} = $item_doc->add_item('Gene', primaryIdentifier => 'RGD:' . $data{RAT_GENE_RGD_ID}, organism => $rat_item);
	}
	my $rat_gene = $rat_genes{$data{RAT_GENE_RGD_ID}};

	my @mouse_ids = split(/\|/, $data{MOUSE_ORTHOLOG_RGD});
	my @mgi_ids = split(/\|/, $data{MOUSE_ORTHOLOG_MGI});
	my @mouse_source = split(/\|/, $data{MOUSE_ORTHOLOG_SOURCE});
	foreach my $mouse_id (@mouse_ids) {
		unless(exists $mouse_genes{$mouse_id})
		{
			my $s_id = shift(@mgi_ids);
			if($s_id) { $mouse_genes{$mouse_id} = $item_doc->add_item('Gene', 
										primaryIdentifier => 'RGD:' . $mouse_id,
										secondaryIdentifier => $s_id, 
										organism => $mouse_item); }
			
			else { $mouse_genes{$mouse_id} = $item_doc->add_item('Gene', 
										primaryIdentifier => 'RGD:' . $mouse_id,
										organism => $mouse_item); }
			

		}
		my $source = shift(@mouse_source);

		unless (exists $sources{$source}) {
			$sources{$source} = $item_doc->add_item('DataSet', name => $source);
		}

		$item_doc->add_item('Homologue', gene => $rat_gene, 
										homologue => $mouse_genes{$mouse_id}, 
										type => 'orthologue',
										dataSets => [$sources{$source}]);
		$item_doc->add_item('Homologue', gene => $mouse_genes{$mouse_id}, 
										homologue => $rat_gene, 
										type => 'orthologue',
										dataSets => [$sources{$source}]);

	} #end foreach $mouse_id

	my @human_ids = split(/\|/, $data{HUMAN_ORTHOLOG_RGD});
	my @hgnc_ids = split(/\|/, $data{HUMAN_ORTHOLOG_HGNC_ID});
	my @human_source = split(/\|/, $data{HUMAN_ORTHOLOG_SOURCE});
	foreach my $human_id (@human_ids) {
		unless(exists $human_genes{$human_id})
		{
			my $s_id = shift(@hgnc_ids);
			if($s_id) { $human_genes{$human_id} = $item_doc->add_item('Gene', 
										primaryIdentifier => 'RGD:' . $human_id, 
										secondaryIdentifier => $s_id,
										organism => $human_item); }

			else { $human_genes{$human_id} = $item_doc->add_item('Gene', 
										primaryIdentifier => 'RGD:' . $human_id, 
										organism => $human_item); }

		}
		my $source = shift(@human_source);

		unless (exists $sources{$source}) {
			$sources{$source} = $item_doc->add_item('DataSet', name => $source);
		}

		$item_doc->add_item('Homologue', gene => $rat_gene, 
										homologue => $human_genes{$human_id}, 
										type => 'orthologue',
										dataSets => [$sources{$source}]);
		$item_doc->add_item('Homologue', gene => $human_genes{$human_id}, 
										homologue => $rat_gene, 
										type => 'orthologue',
										dataSets => [$sources{$source}]);
	} #end foreach $human_id


	

}#end while(<IN>)
close $IN;
$item_doc->close();

exit(0);

### Subroutines ###

sub printHelp
{
print<<HELP;
perl rgd-orthologs-to-xml.pl

arguments:
model	model file
input	RGD flat file
output	XML output file
help	prints this message
			
HELP
}
