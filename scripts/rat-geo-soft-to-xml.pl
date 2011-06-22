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
my ($model_file, $input_directory, $output, $series_flag);
#flags
my ($help, $vf);

GetOptions( 'model=s' => \$model_file,
			'input=s' => \$input_directory,
			'output=s' => \$output,
			'series' => \$series_flag,
			'help' => \$help,
			'verbose' => \$vf);

if($help or !$model)
{
	printHelp();
}
my $model = new InterMine::Model(file => $model_file);
my $item_doc = new InterMine::Item::Document(model => $model, output => $output, auto_write => 1);

#global hashes to track unique
my $database_item;
my %dataset_items;
my %pub_items;
my %platform_items;
my %series_items;

my $organism_item = $item_doc->add_item('Organism', taxonId => '10116');

my @files;

if($series_flag)
{	@files = <$input_directory/*_series.soft>;	}
else
{	@files = <$input_directory/*.soft>;	}

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
			case "PLATFORM"	{ createPlatformItems($$hashed_data{$class}); }
			case "SERIES"	{ createSeriesItems($$hashed_data{$class}); }
			else			{}
		} #switch
	} #foreach my $class
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

sub processFile
{
	my ($soft) = shift;
	
	open(my $IN, '<', $soft);
	my %info;
	my ($class, $name);
	while(<$IN>)
	{
		s/[\n\r]//g;
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
			
			if($info{$class}->{$name}->{$point})
			{
				if(ref($info{$class}->{$name}->{$point}) eq "ARRAY")
				{
					push(@{$info{$class}->{$name}->{$point}}, $value);
				}
				else
				{
					$info{$class}->{$name}->{$point} = [$info{$class}->{$name}->{$point}, $value];
				}
			}
			else
			{
				$info{$class}->{$name}->{$point} = "$value";
			}
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
		next if($database_item);
		
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
		my $platform_item = getPlatformItem($hashed_info->{$key}->{dataset_platform});
		
		if($pub_item and ref($pub_item) eq "ARRAY")
		{	$item_attr{publications} = $pub_item;	}
		elsif($pub_item)
		{	$item_attr{publications} = [$pub_item];	}
		
		if($platform_item and ref($platform_item) eq "ARRAY")
		{	$item_attr{platforms} = $platform_item;	}
		elsif($platform_item)
		{	$item_attr{platforms} = [$platform_item];	}
		
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

sub createPlatformItems
{
	my $hashed_info = shift;
	my (%item_attr, $item);
	
	foreach my $key (keys(%$hashed_info))
	{
		next if(exists $platform_items{$key});
		
		$item_attr{name} = $hashed_info->{$key}->{Platform_title};
		$item_attr{primaryIdentifier} = $hashed_info->{$key}->{Platform_geo_accession};
		$item_attr{vendor} = $hashed_info->{$key}->{Platform_manufacturer} if $hashed_info->{$key}->{Platform_manufacturer};
		$item = $item_doc->add_item(Array => %item_attr);
		
		$platform_items{$key} = $item;
		
	}
}

sub createSeriesItems
{
	my $hashed_info = shift;
	my (%item_attr, $item);
	
	foreach my $key (keys(%$hashed_info))
	{
		next if(exists $series_items{$key});
		
		$item_attr{title} = $hashed_info->{$key}->{Series_title};
		$item_attr{geoAccession} = $key;

		my $pub_item = getPublicationItem($hashed_info->{$key}->{Series_pubmed_id});
		my $platform_item = getPlatformItem($hashed_info->{$key}->{Series_platform_id});
		
		if($pub_item and ref($pub_item) eq "ARRAY")
		{	$item_attr{publications} = $pub_item;	}
		elsif($pub_item)
		{	$item_attr{publications} = [$pub_item];	}
		
		if($platform_item and ref($platform_item) eq "ARRAY")
		{	$item_attr{platforms} = $platform_item;	}
		elsif($platform_item)
		{	$item_attr{platforms} = [$platform_item];	}
		
		$item = $item_doc->add_item(GEOSeries => %item_attr);
		
		$platform_items{$key} = $item;
		
	}
}

sub getPublicationItem
{
	my $pubMedId = shift;	
	return undef unless $pubMedId;
	
	if(ref($pubMedId) eq 'ARRAY') 
	{	
		my @pubItems;
		foreach my $p (@$pubMedId)
		{
			my $pi = getPublicationItem($p);
			push(@pubItems, $pi);
		}
		return \@pubItems;
	}
	else
	{
		unless(exists $pub_items{$pubMedId})
		{
			my $item = $item_doc->add_item('Publication', pubMedId => $pubMedId);
			$pub_items{$pubMedId} = $item;
		}
		return $pub_items{$pubMedId};	
	}
}

sub getPlatformItem
{
	my $geoAcc = shift;
	
	return undef unless $geoAcc;
	
	if(ref($geoAcc) eq 'ARRAY')
	{
		my @platforms;
		foreach my $p (@$geoAcc)
		{
			my $pi = getPlatformItem($p);
			push(@platforms, $pi);
		}
		return \@platforms;
	}
	else
	{
		unless(exists $platform_items{$geoAcc})
		{
			my $item = $item_doc->add_item('Array', primaryIdentifier => $geoAcc);
			$platform_items{$geoAcc} = $item;
		}
		return $platform_items{$geoAcc};
	}
}