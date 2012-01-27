#!/usr/bin/perl
# geo-platform-to-xml.pl
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
use LWP::UserAgent;
use GEOSOFT;

#arguments
my ($model_file, $input_directory, $output);
#flags
my ($help, $vf, $df);

GetOptions( 'model=s' => \$model_file,
			'input=s' => \$input_directory,
			'output=s' => \$output,
			'download' => \$df,
			'help' => \$help,
			'verbose' => \$vf);

if($help or !$model_file)
{
	printHelp();
}

if ($df) {
	downloadGEO($input_directory, $vf);
}

my $model = new InterMine::Model(file => $model_file);
my $item_doc = new InterMine::Item::Document(model => $model, output => $output, auto_write => 0);

#global hashes to track items

my $organism_item = $item_doc->add_item('Organism', taxonId => '10116');

my @files;

@files = <$input_directory/*.annot>;

#global hashes

my %gene_items;
my %probeset_items;
foreach my $file (@files)
{
	my $geo = GEOSOFT->new($file);
	my $geoid = $geo->{Annotation}->{Annotation}->{Annotation_platform};
	my $array = $item_doc->add_item('Array', geoAccession => $geoid, organism => $organism_item);

	my $probeset_list = createProbesetItems($geo, $item_doc, $geoid, $array);

	$array->set(probeSets => $probeset_list);

	$item_doc->write;	
} #foreach my $file

$item_doc->close;
exit(0);

###subroutintes

sub printHelp
{
	print <<HELP;
rat-geo-soft-to-xml.pl --model path_to_model_file --input path_to_input_directory --output intermine.xml

Arguments:
model	model file
input	input directory
output	output file

Flags:
series	use if processing GEO series records
help	prints this message

HELP
}

sub downloadGEO
{
	my ($targetDir, $verbose) = @_;
	my $count = getCountFromGEO();
	$count ? my $uids = getUIDs($count) : die 'error getting count';
	$uids ? my $gpls = getGEOids($uids) : die 'error getting uids';
	#print join("\n", @{$gpls});
	downloadRecords($gpls, $targetDir);
}

sub getCountFromGEO
{
	my $q = 'http://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=gds&term=GPL[ETYP]+AND+rattus+norvegicus[ORGN]&rettype=count';
	my $r = downloadData($q);
	my $c = $1 if $r =~ /<count>(\d+)</i;
	return $c;
}

sub getUIDs
{
	my $count = shift;
	my $q = 'http://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=gds&term=GPL[ETYP]+AND+rattus+norvegicus[ORGN]&RetMax=' . $count;
	my $r = downloadData($q);
	my @uids;
	my $xp = XML::XPath->new(xml => $r);
	my $nodeset = $xp->find('//eSearchResult/IdList/Id');
	foreach my $node ($nodeset->get_nodelist) {
		push(@uids, $node->string_value);
	}
	return \@uids;
}

sub getGEOids
{
	my $uids = shift;

	my $q = 'http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=gds&report=brief&id=' . join(',', @$uids);
	my $r = downloadData($q);
	my @GEOids;
	while ($r =~ /\d\:\s(\w+)/g) {
		push @GEOids, $1;
	}
	return \@GEOids;
}

sub downloadRecords
{
	my ($ids, $t_dir) = @_;

	foreach my $id (@$ids) {
		my $file = $id . '.annot.gz';
		my $q = 'ftp://ftp.ncbi.nih.gov/pub/geo/DATA/annotation/platforms/' . $file;
		my $r = downloadData($q);
		if ($r) {
			open(my $OUT, '>', "$t_dir/$file") or die "cannot open $t_dir/$file";
			binmode $OUT;
			print $OUT $r;
			close $OUT;
			`gzip -d "$t_dir/$file"`;
		}
	}
}

sub downloadData
{
	my ($remoteFile, $verbose) = @_;

	my $ua = LWP::UserAgent->new;
	my $res = $ua->get($remoteFile);
	if($verbose)
	{	
		$res->is_success ?
			print "$remoteFile downloaded\n" :
			print $res->status_line . "\n";
	}
	$res->is_success ?
		return $res->content :
		return undef;
}

sub createProbesetItems
{
	my ($gs, $i_doc, $geoid, $array) = @_;
	
	my @probeSets;
	foreach  my $r (@{$gs->{Annotation}->{table}}) {
		my %info = zip(@{$gs->{Annotation}->{tableHeader}}, @$r);
		my $p_id = $info{ID};
		if($p_id =~ /^\d+$/) { $p_id = $geoid . '_' . $p_id; }

		unless($probeset_items{$p_id})
		{
			$probeset_items{$p_id} = $i_doc->add_item('ProbeSet', primaryIdentifier => $p_id);
		}
		
		my $id_list = $info{Gene_ID};
		my @gene_ids = split('///', $id_list); 

		foreach my $gene_id (@gene_ids) 
		{
			unless($gene_items{$gene_id})
			{	$gene_items{$gene_id} = $i_doc->add_item('Gene', ncbiGeneNumber => $gene_id);	}
			my $gene = $gene_items{$gene_id};
			$i_doc->add_item('GEOAnnotation', gene => $gene, array => $array, probeSet => $probeset_items{$p_id});
		}

		push(@probeSets, $probeset_items{$p_id});
	}
	return \@probeSets;
}