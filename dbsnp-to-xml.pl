#!/usr/bin/perl
# dbsnp-to-xml.pl
# purpose: to create a target items xml file for intermine from dbSNP Chromosome Report file
# the script dumps the XML to STDOUT, as per the example on the InterMine wiki
# However, the script also creates a gff3 file to the location specified

use warnings;
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
use XML::Xpath;
use Cwd;

my ($model_file, $input_directory, $output_directory) = @ARGV;

unless ( $model_file ne '' and -e $model_file)
{
	print "\ndbsnp-to-xml.pl\n";
	print "Convert the dbSNP XML file into InterMine XML\n";
	print "dbsnp-to-xml.pl model_file input_xml_file output_xml_file\n\n";
	exit(0);
}

my @files = <${input_directory}*.xml>;

my $count = 0;
while(my $file1 = pop(@files))
{
	my $file2 = pop(@files);
	my @pids;
	foreach my $x ($file1, $file2)
	{
		my $pid = fork();
		if($pid)
		{
			push(@pids, $pid); #track children
		}#endif
		elsif($pid == 0) #child process
		{
			my $data_source = 'dbSNP';
			my $taxon_id = 10116;
			my $outfile = $1 if $x =~ m|(\w+\.xml)$|;
			my $output = new IO::File(">${output_directory}intermine_$outfile") or die "cannot open IO::Steam >${output_directory}intermine_$outfile";
			my $writer = new XML::Writer(DATA_MODE => 1, DATA_INDENT => 3, OUTPUT => $output);


			# The item factory needs the model so that it can check that new objects have
			# valid classnames and fields
			my $model = new InterMine::Model(file => $model_file);
			my $item_factory = new InterMine::ItemFactory(model => $model);
			$writer->startTag("items");

			my $org_item = $item_factory->make_item('Organism');
			$org_item->set('taxonId', $taxon_id);
			$org_item->as_xml($writer);

			# read the genes file
			open SNP, $x;
			my %index;
			my %chromosomes;
			my $count = 0;
			my $entry = '';
			print "processing $x\n";
			while(<SNP>)
			{
				chomp;
				$entry .= $_;
	
				#find one SNP at a time
				if( $entry =~ m|<Rs[\d\D]+?</Rs>|) #parses header line
				{
					#print "$entry\n"; exit (0);
					#once found load into XPATH object to parse out data
					my $xp = XML::XPath->new(xml => $&);
					my $snp_item = $item_factory->make_item('rsSNP');
					#find Rs Id
					my $id = $xp->find('//Rs/@rsId')->string_value;
					$snp_item->set('primaryIdentifier', "rs$id");
		
					#find chromosome
					my $chrom = $xp->find('//Assembly[@groupLabel="RGSC_v3.4"]/Component/@chromosome')->string_value;
					my $chromosome_item;
					if($chromosomes{$chrom})
					{
						$chromosome_item = $chromosomes{$chrom}
					}
					else
					{
						$chromosome_item = $item_factory->make_item('Chromosome');
						$chromosome_item->set('primaryIdentifier', $chrom);
						$chromosomes{$chrom} = $chromosome_item;
						$chromosome_item->as_xml($writer);
					}
		
					#set chromosome and location
					my $pos = $xp->find('//Assembly[@groupLabel="RGSC_v3.4"]/Component/MapLoc/@physMapInt')->string_value;
					my $orient = $xp->find('//Assembly[@groupLabel="RGSC_v3.4"]/Component/MapLoc/@orient')->string_value;
					if($orient eq 'forward')
					{	$pos++; }
					elsif($orient eq 'reverse')
					{	$pos--; }
					my $loc_item = $item_factory->make_item('Location');
					$loc_item->set('object', $chromosome_item);
					$loc_item->set('start', $pos);
					$loc_item->set('end', $pos);
					$loc_item->set('subject', $snp_item);
					$loc_item->as_xml($writer);
					$snp_item->set('chromosome', $chromosome_item);
					$snp_item->set('chromosomeLocation', $loc_item);
		
					#create ssSNPs
					my %ssSNPs;
					my $ssSet = $xp->find('/Rs/Ss');
					foreach my $node ($ssSet->get_nodelist)
					{
						my $ss_item = $item_factory->make_item('ssSNP');
						my $ssId = $node->find('@ssId')->string_value;
						$ss_item->set('primaryIdentifier', "ss$ssId");
						my $five = $node->find('Sequence/Seq5')->string_value;
						my $three = $node->find('Sequence/Seq3')->string_value;
						my $allele = $node->find('Sequence/Observed')->string_value;
						$ss_item->set('fivePrimeSequence', $five);
						$ss_item->set('threePrimeSequence', $three);
						$ss_item->set('allele', $allele);
						$ss_item->set('rsSNP', $snp_item);
						$ss_item->as_xml($writer);
						$ssSNPs{$ssId} = $ss_item;
					}
		
					#relate ssSNPs to rsSNP
					$snp_item->set('ssSNPs', [values(%ssSNPs)]);
					my $exSNP = $xp->find('//Rs/Sequence/@exemplarSs')->string_value;
					$snp_item->set('exemplarSNP', $ssSNPs{$exSNP});
		
					$snp_item->as_xml($writer);
					$entry = ''; #empty $entry
				}

			}#end while
			close SNP;

			$writer->endTag("items");
			exit(0);
		}#end elsif child process
	}#end foreach my $x
	foreach(@pids) {waitpid($_, 0);} #wait for children - no zombies
}#end while