#!/usr/bin/perl
# rat-carpenovo-to-xml.pl
# purpose: to create a target items xml file for intermine from RGD FTP file

#use warnings;
use strict;

BEGIN {
  push (@INC, ($0 =~ m:(.*)/.*:)[0] . '../../intermine/perl/InterMine-Util/lib');
}

#use XML::Writer;
use InterMine::Item::Document;
use InterMine::Model;
use InterMine::Util qw(get_property_value);
use IO qw(Handle File);
use Getopt::Long;
use lib '../perlmods';
use RCM;
use List::MoreUtils qw/zip/;


my ($model_file, $snp_file, $pf_file, $output_xml, $help, $taxon_id);
GetOptions( 'model=s' => \$model_file,
			'snp_file=s' => \$snp_file,
			'polyphen_file=s' => \$pf_file,
			'output_file=s' => \$output_xml,
			'taxon_id=s' => \$taxon_id,
			'help' => \$help);

if($help or !($model_file and $snp_file and $pf_file))
{
	printHelp();
	exit(0);
}

my $data_source = 'Rat Genome Database';

# The item factory needs the model so that it can check that new objects have
# valid classnames and fields
my $model = new InterMine::Model(file => $model_file);
my $item_doc = new InterMine::Item::Document(model => $model, output => $output_xml, auto_write => 1);

####
#User Additions
my $org_item = $item_doc->add_item('Organism', taxonId => $taxon_id);
my $dataset_item = $item_doc->add_item('DataSet', name => $data_source);

my $chrom_items = RCM::addChromosomes($item_doc, $org_item);

# read the genes file
open(my $INPUT, '<', $snp_file) or die ("cannot open $snp_file");
my $index;
my %vt_items;
my %snp_items;
my %experiment_items;

while(<$INPUT>)
{
	chomp;
	if(/^\D/) #parses header line
	{
		$index = RCM::parseHeader($_);
		next
	}
	my @fields = split(/\t/);
   	my %info = zip(@$index, @fields);
	my $chr_item = $chrom_items->{$info{CHROMOSOME}};

	unless ($experiment_items{$info{DESCRIPTION}}) {
		my $item = $item_doc->add_item('Experiment', name => $info{DESCRIPTION});
		$experiment_items{$info{DESCRIPTION}} = $item;
	}
	
	my $snp_item = $item_doc->add_item('SNP', primaryIdentifier => $info{VARIANT_ID},
								chromosome => $chr_item,
								allele => $info{VAR_NUC},
								sample => $experiment_items{$info{DESCRIPTION}},
								organism => $org_item);
	$snp_items{$info{VARIANT_ID}} = $snp_item;
	
	$item_doc->add_item('Location', start => $info{START_POS},
									end => $info{END_POS},
									locatedOn => $chr_item,
									feature => $snp_item);
}
close $INPUT;

$index = undef;
my %proteins;
open(my $PFIN, '<', $pf_file);
while(<$PFIN>)
{
	chomp;
	if(/^\D/) #parses header line
	{
		$index = RCM::parseHeader($_);
		next
	}
	my @fields = split(/\t/);
   	my %info = zip(@$index, @fields);
	
	if($info{PROTEIN_ID} and !exists($proteins{$info{PROTEIN_ID}}))
	{ 
		my $p = $item_doc->add_item('Protein', primaryAccession => $info{PROTEIN_ID});
		$proteins{$info{PROTEIN_ID}} = $p;
	}
	my $protein = $proteins{$info{PROTEIN_ID}};

	if($info{TRANSCRIPT_RGD_ID} and !$vt_items{$info{TRANSCRIPT_RGD_ID}})
	{
		my $var_item = $item_doc->add_item('Transcript', primaryIdentifier => $info{TRANSCRIPT_RGD_ID});
		$vt_items{$info{TRANSCRIPT_RGD_ID}} = $var_item;
	}
	my $vt = $vt_items{$info{TRANSCRIPT_RGD_ID}};

	my %pfattr = (primaryIdentifier => $info{POLYPHEN_ID},
					prediction => $info{PREDICTION});

	if($info{VARIANT_ID}){
		$pfattr{snp} = $snp_items{$info{VARIANT_ID}};
	}

	$pfattr{basis} = $info{BASIS} if $info{BASIS};
	$pfattr{variantTranscript} = $vt if $vt;
	$pfattr{alleleOne} = $info{AA1} if $info{AA1};
	$pfattr{alleleTwo} = $info{AA2} if $info{AA2};
	$pfattr{aminoAcidPosition} = $info{POSITION} if $info{POSITION};
	$pfattr{protein} = $protein if $protein;

	$item_doc->add_item('PolyPhen', %pfattr); 
}
close $PFIN;

$item_doc->close;

### Subroutines ###

sub printHelp
{
	print <<HELP
	
	HELP!
	
HELP
}