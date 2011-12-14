#!/usr/bin/perl
###################
# omim-to-xml.pl
#
# written by Andrew Vallejos
#
###################

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
use List::MoreUtils qw/zip/;


my ($model_file, $gene_map, $output_xml, $help);

GetOptions(
	'model=s' => \$model_file,
	'gene_map=s' => \$gene_map,
	'omim_xml=s' => \$output_xml,
	'help' => \$help);
	
if($help or !$model_file)
{
	printHelp();
	exit(0);
}

# The item factory needs the model so that it can check that new objects have
# valid classnames and fields
my $model = new InterMine::Model(file => $model_file);
my $item_doc = new InterMine::Item::Document(model => $model, output => $output_xml, auto_write => 0);
my %methods;
my %phenotype_items;
my %omim_items;

open(my $IN, '<', $gene_map);

while(<$IN>)
{
	my @info = split /\|/;
	
	my $id = $info[9];
	unless($omim_items{$id})
	{	
		$omim_items{$id} = $item_doc->add_item('OMIM', primaryIdentifier => $id);
	}
#	$omim_attr{title} = $info[7] . $info[8];
	my $status = getStatus($info[6]);
	$omim_items{$id}->set(cytogenticLocation => $info[4]);
	$omim_items{$id}->set(status => $status) if $status;
	$omim_items{$id}->set(methods => getMethods($info[10]));
	$omim_items{$id}->set(dateEntered => "$info[1]-$info[2]-$info[3]");
	$omim_items{$id}->set(associatedPhenotypes => getPhenotypes("$info[13]$info[14]$info[15]", $id));

} #end while
close $IN;
$item_doc->write;
$item_doc->close;

### subroutines ###

sub getPhenotypes
{
	my ($phenotypes, $parent_id) = @_;
	
	my @phenotype_items;
#	print $phenotypes . "\n";
	foreach my $do (split(/;/, $phenotypes))
	{
		if($do =~ /(?:, ?(\d{6}))? \((\d)\)/)
		{
			my $id;
			$1 and $id = $1 or $id = $parent_id;
			my $title = $`;
			my $method = $2;
			
			my $phMethod_item = getPhenotypicMethodItem($method);			


			unless($omim_items{$id})
			{	$omim_items{$id} = $item_doc->add_item('OMIM', primaryIdentifier => $id) if $id;	}
			
			unless($phenotype_items{$title})
			{	$phenotype_items{$title} = $item_doc->add_item('OMIMPhenotype', title => $title, 
																			method => $phMethod_item, 
																			omimRecord => $omim_items{$id})}
			push @phenotype_items, $phenotype_items{$title} if $title;			
		}
	}
	return \@phenotype_items;
} #getDisorders

sub getPhenotypicMethod
{
	my $code = shift;
	
	for($code)
	{
		/1/ && return('the disorder is placed on the map based on its association witha gene, but the underlying defect is not known.');
		/2/ && return('the disorder has been placed on the map by linkage; no mutation has been found.');
		/3/ && return('the molecular basis for the disorder is known; a mutation has been found in the gene.');
		/4/ && return('a contiguous gene deletion or duplication syndrome, multiple genes are deleted or duplicated causing the phenotype.');
		return undef;
	}
} #getPhenotypicMethod

sub getPhenotypicMethodItem
{
	my $code = shift;
	
	unless($methods{$code})
	{
		my $text = getPhenotypicMethod($code);
		$methods{$code} = $item_doc->add_item('OMIMMethod', code => $code, description => $text) if $text;
	}
	return $methods{$code};
}

sub getStatus
{
	my $code = shift;
	
	for($code)
	{
		/C/ && return('confirmed - observed in at least two laboratories or in several families.');
		/P/ && return('provisional - based on evidence from one laboratory or one family.');
		/I/ && return('inconsistent - results of different laboratories disagree.');
		/L/ && return('limbo - evidence not as strong as that provisional, but included for heuristic reasons. (Same as tentative.)');
		return undef;
	}#for
} #getStatus

sub getMethods
{	
	my $codes = shift;
	my @m;
	foreach my $code (split(/, /, $codes))
	{
		unless($methods{$code})
		{
			my $text = getMethodText($code);
			$methods{$code} = $item_doc->add_item('OMIMMethod', code => $code, description => $text) if $text;
		}
		push @m, $methods{$code} if $methods{$code};
	} #foreach
	return \@m;
} #getMethods

sub getMethodText
{
	my $code = shift;
	
	for($code)
	{
		/^A$/ && return('in situ DNA-RNA or DNA-DNA annealing (hybridization); e.g., ribosomal RNA genes to acrocentric chromosomes; ' .
						' kappa light chain genes to chromosome 2.');
		/^AAS$/ && return('deductions from the amino acid sequence of proteins; e.g., linkage of ' .
						'delta and beta hemoglobin loci from study of hemoglobin Lepore. ' .
						'(Includes deductions of hybrid protein  ' .
						'structure by monoclonal antibodies; e.g., close linkage of MN and SS from ' .
						'study of Lepore-like MNSs blood group antigen.) ' .
						'Also includes examples of hybrid genes as in one form of hypertrophic ' .
						'cardiomyopathy and in apolipoprotein (Detroit).');
		/^C$/ && return('chromosome mediated gene transfer (CMGT); e.g., cotransfer of galactokinase ' .
						'and thymidine kinase. ' .
						'(In conjunction with this approach fluorescence-activated flow sorting ' .
						'can be used for transfer of specific chromosomes.)');
		/^Ch$/ && return('chromosomal change associated with particular phenotype and not proved to ' .
						'represent linkage (Fc), deletion (D), or virus effect (V);  e.g., loss of ' .
						'13q14 band in some cases of retinoblastoma. ' .
						'(Fragile sites, observed in cultured cells with or without	' .
						'folate-deficient medium or BrdU treatment, fall into this class of method; ' .
						'e.g., fragile site at Xq27.3 in one form of X-linked mental retardation. ' .
						'Fragile sites have been used as markers in family linkage studies; e.g., ' .
						'FS16q22 and haptoglobin.)');
		/^D$/ && return('deletion or dosage mapping (concurrence of chromosomal deletion and ' .
					'phenotypic evidence of hemizygosity), trisomy mapping (presence of three ' .
					'alleles in the case of a highly ' .
					'polymorphic locus), or gene dosage effects (correlation of trisomic state of ' .
					'part or all of a chromosome with 50% more gene product). ' .
					'Includes "loss of heterozygosity" (loss of alleles) in malignancies. ' .
					'Examples:  glutathione reductase to chromosome 8. ' .
					'Includes DNA dosage; e.g., fibrinogen loci to 4q2. ' .
					'Dosage mapping also includes coamplification in tumor cells.');
		/^EM$/ && return('exclusion mapping, i.e., narrowing the possible location of loci by ' .
						'exclusion of parts of the map by deletion mapping, extended to include ' .
						'negative lod scores from families with marker chromosomes and negative lod ' .
						'scores with other assigned loci; e.g., support for assignment of MNSs to 4q.');
		/^F/ && return('linkage study in families; e.g., linkage of ABO blood group and ' .
						'nail-patella syndrome. ' .
						'(When a chromosomal heteromorphism or rearrangement is one trait, Fc ' .
						'is used; e.g., Duffy blood group locus on chromosome 1. ' .
						'When 1 or both of the linked loci are identified by a DNA polymorphism, ' .
						'Fd is used; e.g., Huntington disease on chromosome 4.  F = L in ' .
						'the HGM workshops.)');
		/^H$/ && return('based on presumed homology; e.g., proposed assignment of TF to 3q. ' .
					'Includes Ohno\'s law of evolutionary conservatism of X chromosome in mammals. ' .
					'Mainly heuristic or confirmatory.');
		/^HS$/ && return('DNA/cDNA molecular hybridization in solution (Cot analysis); e.g., ' . 
						'assignment of Hb beta to chromosome 11 in derivative hybrid cells.');
		/^L$/ && return('lyonization; e.g., OTC to X chromosome.  (L = family linkage study in the HGM workshops.)');
		/^LD$/ && return('linkage disequilibrium; e.g., beta and delta globin genes (HBB, HBD).');
		/^M$/ && return('Microcell mediated gene transfer (MMGT); e.g., a collagen gene (COL1A1) to chromosome l7.');
		/^OT$/ && return('ovarian teratoma (centromere mapping); e.g., PGM3 and centromere of chromosome 6.');
		/^Pcm$/ && return('PCR of microdissected chromosome segments (see REl).');
		/^Psh$/ && return('PCR of somatic cell hybrid DNA.');
		/^R$/ && return('irradiation of cells followed by rescue through fusion with ' .
						'nonirradiated (nonhuman) cells (Goss-Harris method of radiation-induced gene ' .
						'segregation); e.g., order of genes on  Xq. ' .
						'(Also called cotransference. The complement of cotransference = recombination.)');
		/^RE$/ && return('Restriction endonuclease techniques; e.g., fine structure map of the ' .
						'beta-globin cluster (HBBC) on 11p; physical linkage of 3 fibrinogen genes ' .
						'(on 4q) and APOA1 and APOC3 (on 11p).');
		/^REa$/ && return('combined with somatic cell hybridization; e.g., NAG (HBBC) to 11p.');
		/^REb$/ && return('combined with chromosome sorting; e.g., insulin to 11p. ' .
						'Includes Lebo\'s adaptation (dual laser chromosome sorting and spot blot DNA ' .
						'analysis); e.g., MGP to 11q.  (For this method, using flow sorted ' .
						'chromosomes, W is the symbol adopted by the HGM workshops.)');
		/^REc$/ && return('hybridization of cDNA to genomic fragment (by YAC, PFGE, microdissection, etc.), e.g., A11 on Xq.');
		/^REf$/ && return('isolation of gene from genomic DNA; includes "exon trapping"');
		/^REl$/ && return('isolation of gene from chromosome-specific genomic library (see Pcm).');
		/^REn$/ && return('neighbor analysis in restriction fragments, e.g., in PFGE.');

		/^S$/ && return('segregation (cosegregation) of human cellular traits and human ' .
						'chromosomes (or segments of chromosomes) in particular clones from interspecies ' .
						'somatic cell hybrids; e.g., thymidine kinase to chromosome 17. ' .
						'When with restriction enzyme, REa; with hybridization in solution, HS.');

		/^T$/ && return('TACT = telomere-associated chromosome fragmentation; e.g., interferon-inducible protein 6-16.');

		/^V$/ && return('induction of microscopically evident chromosomal change by a virus; ' . 
							'e.g., adenovirus 12 changes on chromosomes 1 and 17.');

		/^X\/A$/ && return('X-autosome translocation in female with X-linked recessive disorder; '.
							' e.g., assignment of Duchenne muscular dystrophy to Xp21.');
		return undef;
	}
} #createMethod

