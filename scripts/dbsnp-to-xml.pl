#!/usr/bin/perl
# dbsnp-to-xml.pl
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
use XML::XPath;


#arguments
my ($model_file, $input_directory, $output, $taxon_id, $assembly, $vf);
#flags
my ($dlFlag, $assemblyFlag, $help);

GetOptions( 'model=s' => \$model_file,
			'input=s' => \$input_directory,
			'output=s' => \$output,
			'taxon=s' => \$taxon_id,
			'assembly=s' => \$assembly,
			'download' => \$dlFlag,
			'assemblies' => \$assemblyFlag,
			'help' => \$help,
			'verbose' => \$vf);

unless ( !$help and $model_file ne '' and -e $model_file)
{
	printHelp();	
	exit(0);
}

downloadFiles($input_directory) if $dlFlag;

my @files = <${input_directory}*.xml>;
my $model = new InterMine::Model(file => $model_file);
my $item_doc = new InterMine::Item::Document(model => $model, output => $output, auto_write => 0);

my $org_item = $item_doc->add_item('Organism', taxonId => $taxon_id);

my %consequences;
my $df = 0; #datset flag
my $dataset_item;

my $chr_items = RCM::addChromosomes($item_doc);

my $count = 0;
while(my $file = pop(@files))
{
	processDbSNPFile($file);
}#end while
$item_doc->close;

exit(0);

###Subroutines###

sub processDbSNPFile
{
	my $file = shift;
	my $data_source = 'dbSNP';
	
	my $outfile = $1 if $file =~ /(\w+\.xml)$/;

	# The item factory needs the model so that it can check that new objects have
	# valid classnames and fields

	# read the genes file
	open( my $SNP, '<', $file);
	my %index;
	my %chromosomes;
	my $count = 0;
	my $entry = '';
	print "processing $file\n";
	while(<$SNP>)
	{
		chomp;
		$entry .= $_;

		#create the dataset and datasource objects
		#grabs the data from the top of the XML file before throwing it away
		if(!$df and $entry =~ /dbSnpBuild="(\d+)"\s+generated="([\d\D]+?)"/) 
		{

			my ($build, $date) = ($1, $2);
			$dataset_item = $item_doc->add_item('DataSet', name => "dbSNP build:$build, $date");
			$df = 1;
		}
	
		#find one SNP record at a time
		if( $entry =~ m|<Rs [\d\D]+?</Rs>|) #grabs an Rs item
		{
			
			#print "$entry\n"; exit (0);
			#once found load into XPATH object to parse out data
			my $xp = XML::XPath->new(xml => $&);
			
			listAssemblies($xp) if $assemblyFlag;

			my %snp_attr;
			
			$snp_attr{dataSets} = [$dataset_item];
			#find Rs Id
			my $id = $xp->find('//Rs/@rsId')->string_value;
			$snp_attr{primaryIdentifier} = "rs$id";
			$snp_attr{organism} = $org_item;
			
			#find consequence/function
			#sets multiple functional classes
			my $fxnSet = $xp->find('//Assembly[@groupLabel="'.$assembly.'"]/Component/MapLoc/FxnSet');
			my @consequences;
			print "Loading Consequences...\n" if $vf;
			foreach my $fxnNode ($fxnSet->get_nodelist)
			{
				my $fxnClass = $fxnNode->find('@fxnClass')->string_value;
				unless($consequences{$fxnClass})
				{	$consequences{$fxnClass} = $item_doc->add_item('ConsequenceType', type => $fxnClass); }
				push(@consequences, $consequences{$fxnClass});
			}
			$snp_attr{consequenceTypes} = \@consequences if $#consequences > -1; #ignore empty array
			
	
			#find chromosome
			print "Loading chromosomes...\n" if $vf;
			my $chrom = $xp->find('//Assembly[@groupLabel="'.$assembly.'"]/Component/@chromosome')->string_value;
			$snp_attr{chromosome} = $chr_items->{$chrom};

			#set chromosome and location
			my $pos = $xp->find('//Assembly[@groupLabel="'.$assembly.'"]/Component/MapLoc/@physMapInt')->string_value;
			my $orient = $xp->find('//Assembly[@groupLabel="'.$assembly.'"]/Component/MapLoc/@orient')->string_value;
			if($orient eq 'forward')
			{	$pos++; }
			elsif($orient eq 'reverse')
			{	$pos--; }
			
			print "Loading location...\n" if $vf;
			print "$pos: $chrom\n" if $vf;
			my %loc_attr = (start => $pos,
							end => $pos,
							locatedOn => $chr_items->{$chrom});
			my $loc_item = $item_doc->add_item(Location => %loc_attr);
			$snp_attr{locations} = ([$loc_item]);
			
			#set rsSequence
			my $rs5 = $xp->find('/Rs/Sequence/Seq5')->string_value;
			my $rsAllele = $xp->find('/Rs/Sequence/Observed')->string_value;
			my $rs3 = $xp->find('/Rs/Sequence/Seq3')->string_value;

			$snp_attr{fivePrimeSequence} = $rs5;
			$snp_attr{allele} = $rsAllele;
			$snp_attr{threePrimeSequence} = $rs3;
		
			print "Loading rsSNP...\n" if $vf;
			my $snp_item = $item_doc->add_item(rsSNP => %snp_attr);
			#create ssSNPs
			my %ssSNPs;
			my $ssSet = $xp->find('/Rs/Ss');
			foreach my $node ($ssSet->get_nodelist)
			{
				my $ssId = $node->find('@ssId')->string_value;
				my %ss_attr = (primaryIdentifier => "ss$ssId");
				$ss_attr{organism} = $org_item;
				$ss_attr{fivePrimeSequence} = $node->find('Sequence/Seq5')->string_value;
				$ss_attr{threePrimeSequence} = $node->find('Sequence/Seq3')->string_value;
				$ss_attr{allele} = $node->find('Sequence/Observed')->string_value;
				$ss_attr{rsSNP} = $snp_item;
				$ss_attr{chromosome} = $chr_items->{$chrom};
				$ss_attr{locations} = [$item_doc->add_item(Location => %loc_attr)];
				$ss_attr{submittedId} = $node->find('@locSnpId')->string_value;
				
				print "Loading ssSNP...\n" if $vf;
				my $ss_item = $item_doc->add_item(ssSNP => %ss_attr);
				
				$ssSNPs{$ssId} = $ss_item;
			}
		
			#relate ssSNPs to rsSNP
			print "Setting Examplar SS...\n" if $vf;
			my $exSNP = $xp->find('//Rs/Sequence/@exemplarSs')->string_value;
			$snp_item->set('exemplarSNP', $ssSNPs{$exSNP});
	
			print "Write...\n" if $vf;
			$item_doc->write();
			$loc_item = $loc_item->destroy;
			$snp_item = $snp_item->destroy;
			foreach my $ssSnp (values %ssSNPs) {
				$ssSnp->destroy;
			}
			$entry = ''; #empty $entry
		}

	}#end while
	close $SNP;
}

sub downloadFiles
{
	my $input_directory = shift;
	
	#Specific to Rat
	my @chromes = (1..20, 'X');
	
	my $url = 'ftp://ftp.ncbi.nih.gov/snp/organisms/rat_10116/XML/';
	foreach my $chrom (@chromes)
	{
		my $file = "ds_ch${chrom}.xml.gz";
		print "curl --create-dirs $url/$file -o $input_directory/$file\n";
		`curl --create-dirs $url/$file -o $input_directory/$file`;
		print "gzip -d -f $input_directory/$file\n";
		`gzip -d -f $input_directory/$file`;
	}
}#end downloadFiles

sub listAssemblies
{
	my $node = shift;
	
	my $set = $node->find('//Assembly');
	foreach $a ($set->get_nodelist)
	{
		print $a->find('@groupLabel')->string_value;
		print "\n";
	}
	exit(0);
}

sub printHelp
{
	print<<HELP

Converts the dbSNP XML file into InterMine XML dbsnp-to-xml.pl
	
perl dbsnp-to-xml.pl
--model 	Path to InterMine model file
--input		Path to directory of dbSNP files
--output	Path to directory of InterMine XML files
--taxon		Taxon id
--assembly	Assembly to use for position and functional data (limit 1)

[OPTIONAL FLAGS]
--download		Download files from NCBI (Rat only / Unix based OS)
--assemblies 	Lists the assemblies available for the dataset
--help			Displays this message

[EXAMPLE]
dbsnp-to-xml.pl --model ../dbmodel/build/model/genomic_model.xml \
--input data/dbSNP --output data/intermineXML --taxon 10116 --assembly RGSCv3.4
HELP
}
