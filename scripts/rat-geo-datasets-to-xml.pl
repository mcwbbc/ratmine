#!/usr/bin/perl
# rat-geo-to-xml.pl
# purpose: to create a target items xml file for intermine from dbSNP Chromosome Report file
# the script dumps the XML to STDOUT, as per the example on the InterMine wiki
# However, the script also creates a gff3 file to the location specified

use Switch;
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


#arguments
my ($model_file, $input_directory, $output);
#flags
my ($help, $vf);

GetOptions( 'model=s' => \$model_file,
			'input=s' => \$input_directory,
			'output=s' => \$output,
			'help' => \$help,
			'verbose' => \$vf);

=cut

#URL for initial UIDs
my $dataseturl = 'http://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=gds&term=rattus[organism]&retmax=4';

my $geoXML = downloadData($dataseturl, $vf);

my $geoIds = parseIds($geoXML);
print "@$geoIds";

=cut

my $model = new InterMine::Model(file => $model_file);
my $item_doc = new InterMine::Item::Document(model => $model, output => $output, auto_write => 1);

#global hashes to track unique
my $database_item;
my %dataset_items;
my %pub_items;

my $organism_item = $item_doc->add_item('Organism', taxonId => '10116');

my @files = <$input_directory/*.soft>;
foreach my $file (@files)
{
	my $hashed_data = processFile($file);
	foreach my $class (keys(%$hashed_data))
	{
		switch($class)
		{
			case "DATABASE"	{ createDatabaseItems($$hashed_data{$class}); }
			case "DATASET"	{ createDatasetItems($$hashed_data{$class}); }
			case "SUBSET"	{ createSubsetItems($$hashed_data{$class}); } #TODO
			else			{}
		} #switch
	} #foreach my $class
} #foreach my $file

$item_doc->close;
exit(0);

###subroutintes

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
	return $res->content;
}

sub parseIds
{
	my $xml = shift;
	
	my $xp = XML::XPath->new(xml => $xml);
	my $nodeset = $xp->find('/eSearchResult/IdList/Id');
	
	my @ids;
	foreach my $node ($nodeset->get_nodelist)
	{
		push(@ids, $node->string_value)
	}
	return \@ids;
}

sub processFile
{
	my ($soft) = shift;
	
	open(my $IN, '<', $soft);
	my %info;
	my ($class, $name);
	while(<$IN>)
	{
		chomp;
		if(/^\^/)
		{
			s/.//;
			($class, $name) = split(' = '); 
		}
		elsif(/^!/)
		{
			die('malformed SOFT file') unless ($class and $name);
			s/.//;
			my ($point, $value) = split(' = ');
			$info{$class}->{$name}->{$point} = "$value";
		}	
	}
	return \%info;
}

sub createDatabaseItems
{
	my ($hashed_info) = shift;
	
	my (%item_attr, $item);
	foreach my $key (keys(%$hashed_info))
	{
		next if(exists $dataset_items{$key});
		
		$item_attr{name} = $key;
		$item_attr{description} = $hashed_info->{$key}->{Database_name};
		$item_attr{url} = $hashed_info->{$key}->{Database_web_link};
		$item = $item_doc->add_item(DataSource => %item_attr);
		$database_item = $item;
	}
}

sub createDatasetItems
{
	my ($hashed_info) = shift;
	
	my (%item_attr, $item);
	foreach my $key (keys(%$hashed_info))
	{
		next if(exists $dataset_items{$key});
		
		$item_attr{name} = $key;
		$item_attr{description} = $hashed_info->{$key}->{dataset_description};
		$item_attr{title} = $hashed_info->{$key}->{dataset_title};
		$item_attr{type} = $hashed_info->{$key}->{dataset_type};
		$item_attr{valueType} = $hashed_info->{$key}->{dataset_value_type};
		#$item_attr{publicReleaseDate} = $hashed_info->{$key}->{dataset_update_date};
		
		my $pub_item = getPublicationItem($hashed_info->{$key}->{dataset_pubmed_id});
		
		$item_attr{publication} = $pub_item if $pub_item;
		$item_attr{dataSource} = $database_item;
		$item_attr{organism} = $organism_item;
		$item = $item_doc->add_item(GEODataSet => %item_attr);
		$dataset_items{$key} = $item;
	}
}

sub createSubsetItems
{
	#print "create subset item\n";
}

sub getPublicationItem
{
	my $pubMedId = shift;
	
	return undef unless $pubMedId;
	
	unless(exists $pub_items{$pubMedId})
	{
		my $item = $item_doc->add_item('Publication', pubMedId => $pubMedId);
		$pub_items{$pubMedId} = $item;
	}
	return $pub_items{$pubMedId};
}