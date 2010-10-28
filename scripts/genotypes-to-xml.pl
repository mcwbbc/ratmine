#!/usr/bin/perl
# genotypes-to-xml.pl
# purpose is to map snps to strains


no warnings;
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

my ($genotype_file, $ensembl2rs, $model_file, $out_file, $help);
my $t = 0;

GetOptions( 'model=s' => \$model_file,
			'genotype=s' => \$genotype_file,
			'output_file=s' => \$out_file,
			'ensembl_map=s' => \$ensembl2rs,
			'help' => \$help);
			
# Begin with setting up the environment
my $model = new InterMine::Model(file => $model_file);
my $item_doc = new InterMine::Item::Document(model => $model, output => $out_file, auto_write => 1);

my $taxon_id = '10116';
my $org_item = $item_doc->add_item('Organism', taxonId => $taxon_id);

#build rs to ensembl mapping
my $rsEnsemblMap = buildRs2Ensembl($ensembl2rs);

#Start processing main file

open(my $IN, '<', $genotype_file) or die("cannot open $genotype_file\n");

my $header = <$IN>; #get rid of header line

my %strainItems;
my %snpItems;
while(<$IN>)
{
	chomp;
	my @data = split('\t', $_);

	my $snpId = $$rsEnsemblMap{$data[0]};
	if($snpId)
	{	
		unless($snpItems{$snpId})
		{
			my $snp_item = $item_doc->add_item('rsSNP', primaryIdentifier => $snpId);
			$snpItems{$snpId} = $snp_item;
		}

		unless($strainItems{$data[2]})
		{
			my $strain_item = $item_doc->add_item('Strain', primaryIdentifier => $data[2]);
			$strainItems{$data[2]} = $strain_item;
		}#unless
		
		$item_doc->add_item('Genotype', strain => $strainItems{$data[2]},
										snp => $snpItems{$snpId},
										allele => $data[1]);
	}#if

}#while IN

close $IN;
$item_doc->close;
exit(0);

### Subroutines ###

sub buildRs2Ensembl
{
	my $file = shift;
	open(my $IN, '<', $file) or die "cannot open $file";
	my %map;
	while(<$IN>)
	{
		chomp;
		my($rs, $ensembl) = split("\t", $_);
		$map{$ensembl} = $rs if $ensembl =~ /^EN/;
	}
	close $IN;
	return \%map;
}

sub buildStar2Ensembl
{
	my $file = shift;
	open(my $IN, '<', $file);
	my %map;
	while(<$IN>)
	{
		chomp;
		my($star, $ensembl) = split(",", $_);
		$map{$star} = $ensembl;
	}
	close $IN;
	return \%map;
}

sub buildStrainMap
{
	my $file = shift;
	open(my $IN, '<', $file);
	my %map;
	while(<$IN>)
	{
		#print "$_";
		chomp;
		my @entry = split(",", $_);
		$map{$entry[2]} = $entry[1];
	}
	close $IN;
	return \%map;
}