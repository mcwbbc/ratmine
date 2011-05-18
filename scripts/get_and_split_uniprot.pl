#!/usr/bin/perl
#by Andrew Vallejos

=head1 split_uniprot.pl

=begin text

# perl split_uniprot.pl 
#
# Purpose:
#	Download and Split a UniProt XML file into a Swiss-Prot and
#	a TeEMBL file.
#
#	Options:
#	--taxon=id\tTaxon ID for organism
#	--go\t\tCreate GOA File
#	--help\t\tPrint this message

=cut 

#use Bio::Perl;
#use Bio::SeqIO;
use Getopt::Long;
use LWP::UserAgent;
use strict;

my ($taxon, $goType, $help, $genes, $genesFile, $outputDir);

my $results = GetOptions(
				"taxon=s" => \$taxon,
				"go" => \$goType,
				"help" => \$help,
				"genes=s" => \$genesFile,
				"output_dir=s" => \$outputDir
);

&printHelp if ($help or !$taxon);


my $input = $outputDir . "${taxon}_uniprot_all.xml";
my $swiss = $outputDir . "${taxon}_uniprot_sprot.xml";
my $tremb = $outputDir . "${taxon}_uniprot_trembl.xml";
my $goa = "${taxon}_annotation.txt";
my $genes = "${taxon}_genes.gff3";
my $fasta = "${taxon}_genome.fasta";

&parseSequenceFile($genesFile, $genes, $fasta) if $genesFile;

&getUniProtXML($taxon, $input);
&parseAndPrintXML($input, $swiss, $tremb, $goa, $goType);

exit(0);

###Subroutines###

sub printHelp
{
	print <<HELP;
#
# perl split_uniprot.pl 
#
# Purpose:
#	Download and Split a UniProt XML file into a Swiss-Prot and
#	a TeEMBL file.
#
#	Options:
#	--taxon=id\tTaxon ID for organism
#	--output_dir=location\tOutput directory
#	--go\t\tCreate GOA File
#	--help\t\tPrint this message
HELP
	exit 0;
}

sub getUniProtXML
{
	my ($taxon, $input) = @_;
	my $url = "http://www.uniprot.org/uniprot/?query=taxonomy%3a${taxon}&force=yes&format=xml";

	my $ua = LWP::UserAgent->new;

	my $response;
	unless($response = $ua->get($url, ':content_file' => $input) and
		$response->is_success)
	{
		print "There was a problem fetching $url\n";
		print $response->status_line;
	}

	&validateFile($input);

}#end getUniProtXML

sub parseSequenceFile 
{
	my ($seqFile, $out, $fasta) = @_;
	&printFASTA($seqFile, $fasta);
	my $in = Bio::SeqIO->new(-file => "$seqFile", -format => 'genbank');
	open(GFF, ">$out");
	while( my $seq = $in->next_seq() )
	{
		foreach my $feat ($seq->get_SeqFeatures)
		{
			my $gffFormat = Bio::Tools::GFF->new(-gff_version => 3);
			if($feat->primary_tag eq 'gene')
			{
				my $gff_line = $feat->gff_string($gffFormat) . "\n";
				$gff_line =~ s/db_xref=.*?GeneID:(\d+).*?;/$&ID=$1;/;
				print GFF $gff_line;
			}
				
		}
	}
	close GFF;
}#end parseSequenceFile

sub printFASTA
{
	my ($seqFile, $fasta) = @_;
	my $in = Bio::SeqIO->newFh(-file => "$seqFile", -format => 'genbank');
	my $out = Bio::SeqIO->newFh(-file=> ">$fasta", -format=> 'Fasta');
	print $out $_ while <$in>;
}#end printFASTA

sub parseAndPrintXML
{
	my ($input, $swiss, $tremb, $goa, $goFlag) = @_;

	open(IN, $input);
	open(SWISS, ">$swiss");
	open(TREMB, ">$tremb");
	open(GO, ">$goa") if ($goFlag);
	my $entry = '';
	my $count = 0;
	while(<IN>)
	{
		my $line = $_;
		if($line =~ /<entry/)
		{
			#start new entry
			my $entry = $line;
			while(<IN>)
			{
				$entry .= $_;
				last if $_ =~ m|</entry>|;
			}#end while
			$count++;
			
			#print "$count\n" if !($count%10);
			#print "$entry\n" if $count == 196;

			if ($goType) {
				my @accessions;
				while ($entry =~ m|dbReference type="GeneID" id="(\d+)"|g)
				{	push (@accessions, $1);	}
				
				foreach my $a (@accessions)
				{
					my $accession = $a ;
					my $name = $1 if ($entry =~ m|<name type="primary">(\w+)</name>|m);
					while ($entry =~ m|dbReference type="GO" id="(GO:\d+)"[\d\D]+?</db|gm) {
						my $goEntry = $&;
						my $goId = $1;
						my ($eCode, $assign) = ($1, $2) if $goEntry =~ /type="evidence" value="(\w+):([\d\D]+?)"/;
						my $aspect = $1 if $goEntry =~ /type="term" value="(\w):/;
						print GO "UniProtKB\t$accession\t$name\t.\t$goId\t.\t$eCode\t.\t$aspect\t.\t.\t.\tprotein\ttaxon:$taxon\t20090101\t$assign\n";
					}#while
				}#foreach
				
			}#if
			#print entry to correct file
			if($entry =~ /dataset="Swiss-Prot"/i)
			{	print SWISS $entry;	}
			elsif($entry =~ /dataset="TrEMBL"/i)
			{	print TREMB $entry;	}
			$entry = '';
		}#end if($line =~/<entry/)
		else
		{
			print SWISS $line;
			print TREMB $line;
		}
	}#end while
	close IN;
	close SWISS;
	close TREMB;
	close GO if ($goFlag);
	unlink($input);
}#end parseAndPrintXML

sub validateFile
{
	my $file = shift;
	my $size = -s $file;
	unless($size > 0)
	{
		print "There was a problem downloading the taxon requested.\n";
		print "Please check your taxon id and try again\n";
		unlink($file);
		exit(0);
	}
}
