no warnings;
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
use Cwd;
use Getopt::Long;
use strict;

my ($genotype_file, $ensembl2rs, $model_file, $out_file, $help);
my $t = 0;

GetOptions( 'model=s' => \$model_file,
			'genotype=s' => \$genotype_file,
			'output_file=s' => \$out_file,
			'ensembl_map=s' => \$ensembl2rs,
			'help' => \$help);
			
# Begin with setting up the environment
my $output = new IO::File(">$out_file");
my $writer = new XML::Writer(DATA_MODE => 1, DATA_INDENT => 3, OUTPUT => $output);

my $model = new InterMine::Model(file => $model_file);
my $item_factory = new InterMine::ItemFactory(model => $model);

my $taxon = '10116';
my $org_item = $item_factory->make_item('Organism');
$org_item->set('taxonId', $taxon);

#build rs to ensembl mapping
my $rsEnsemblMap = &buildRs2Ensembl($ensembl2rs);

#Start processing main file

open(IN, $genotype_file);

my $header = <IN>; #get rid of header line

$writer->startTag("items");
$org_item->as_xml($writer);

my %strainItems;
my %snpItems;
while(<IN>)
{
	chomp;
	my @data = split('\t', $_);

	my $snpId = $$rsEnsemblMap{$data[0]};
	if($snpId ne '')
	{	
		my $genotype_item = $item_factory->make_item('Genotype');

		unless($snpItems{$snpId})
		{
			my $snp_item = $item_factory->make_item('rsSNP');
			$snp_item->set('primaryIdentifier', $snpId);
			$snpItems{$snpId} = $snp_item;
		}

		unless($strainItems{$data[2]})
		{
			my $strain_item = $item_factory->make_item('Strain');
			$strain_item->set('primaryIdentifier', $data[2]);
			$strain_item->as_xml($writer);
			$strainItems{$data[2]} = $strain_item;
		}#unless
		
		$genotype_item->set('strain', $strainItems{$data[2]});
		$genotype_item->set('snp', $snpItems{$snpId});
		$genotype_item->set('allele', $data[1]);
		$genotype_item->as_xml($writer);
		
		my $genotypes = $snpItems{$snpId}->get("genotypes");
		push(@$genotypes, $genotype_item);

		$snpItems{$snpId}->set('genotypes', $genotypes);	

	}#if

}#while IN

close IN;
foreach my $s (values %snpItems)
{
	$s->as_xml($writer);
}
$writer->endTag("items");

### Subroutines ###

sub buildRs2Ensembl
{
	my $file = shift;
	open(IN, $file) or die "cannot open $file";
	my %map;
	while(<IN>)
	{
		chomp;
		my($rs, $ensembl) = split("\t", $_);
		$map{$ensembl} = $rs if $ensembl =~ /^EN/;
	}
	close IN;
	return \%map;
}

sub buildStar2Ensembl
{
	my $file = shift;
	open(IN, $file);
	my %map;
	while(<IN>)
	{
		chomp;
		my($star, $ensembl) = split(",", $_);
		$map{$star} = $ensembl;
	}
	close IN;
	return \%map;
}

sub buildStrainMap
{
	my $file = shift;
	open(IN, $file);
	my %map;
	while(<IN>)
	{
		#print "$_";
		chomp;
		my @entry = split(",", $_);
		$map{$entry[2]} = $entry[1];
	}
	close IN;
	return \%map;
}