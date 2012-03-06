#!/usr/bin/perl
# rat-geo-to-xml.pl
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
use Data::Dumper;

#arguments
my ($model_file, $input_directory, $output);
#flags
my ($help, $vf, $series_flag, $samples_flag);

GetOptions( 'model=s' => \$model_file,
			'input=s' => \$input_directory,
			'output=s' => \$output,
			'series' => \$series_flag,
			'samples' => \$samples_flag,
			'help' => \$help,
			'verbose' => \$vf);

if($help or !$model_file or ($series_flag and $samples_flag))
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
my %sample_items;
my %probe_items;

my $organism_item = $item_doc->add_item('Organism', taxonId => '10116');

my @files;

if($series_flag)
{	@files = <$input_directory/*_series.soft>;	}
elsif($samples_flag)
{	@files = <$input_directory/*_sample.soft>;	}
else
{	@files = <$input_directory/*.soft>;	}

foreach my $file (@files)
{
	my $hashed_data = processFile($file);
	#print Dumper($hashed_data);
	#exit(0);
	foreach my $class (keys(%$hashed_data))
	{
		#emulating Switch, since its not working
		for($class)
		{
			/DATABASE/ && do{ createDatabaseItems($$hashed_data{$class}); last;};
			/DATASET/ && do{ createDatasetItems($$hashed_data{$class}); last;};
			/SUBSET/ &&	do{ createSubsetItems($$hashed_data{$class}); last;}; #TODO
			/PLATFORM/ && do{ createPlatformItems($$hashed_data{$class}); last;};
			/SERIES/ &&	 do{ createSeriesItems($$hashed_data{$class}); last;};
			/SAMPLE/ &&	do{ createSampleItems($$hashed_data{$class}); last;};
			warn "Class $class not matched\n";
		} #for
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
	
	my $table_flag = 0;

	open(my $IN, '<', $soft);
	my %info;
	my ($class, $name);
	while(<$IN>)
	{
		s/[\n\r]//g;
		if($table_flag)
		{
			if(/^!sample_table_end/)
			{ $table_flag = 0 and next;	}

			/^([\w_]+).*?([AP])$/;
			my($probe, $call) = ($1, $2);
			$info{$class}->{table}->{$probe} = $call if $probe;
		}
		elsif(/^\^/)
		{
			s/.//;
			($class, $name) = split(' = ', $_, 2); 
		}
		elsif(/^!sample_table_begin/)
		{
			$table_flag = 1;
		}
		elsif(/^!/)
		{
			die('malformed SOFT file') unless ($class and $name);
			s/.//;
			my ($point, $value) = split(' = ', $_, 2);
			
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

		if($hashed_info->{$key}->{dataset_platform_organism} =~ /rattus norvegicus/i)
		{
			$item_attr{organism} = $organism_item;
		}
		else
		{
			next;
		}
		
		$item_attr{geoAccession} = $key;
		$item_attr{description} = $hashed_info->{$key}->{dataset_description};
		$item_attr{title} = $hashed_info->{$key}->{dataset_title};
		$item_attr{type} = $hashed_info->{$key}->{dataset_type};
		$item_attr{valueType} = $hashed_info->{$key}->{dataset_value_type};
		#$item_attr{publicReleaseDate} = $hashed_info->{$key}->{dataset_update_date};
		
		my $data_series_item = getSeriesItem($hashed_info->{$key}->{dataset_reference_series});

		if ($data_series_item) {
			$item_attr{geoSeries} = $data_series_item;
		}

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
		if($hashed_info->{$key}->{Platform_taxid} == 10116 or $hashed_info->{$key}->{Platform_organism} =~ /rattus norvegicus/i)
		{
			$item_attr{organism} = $organism_item;
		}
		else
		{
			next;
		}
		
		$item_attr{name} = $hashed_info->{$key}->{Platform_title};
		$item_attr{geoAccession} = $hashed_info->{$key}->{Platform_geo_accession};
		$item_attr{vendor} = $hashed_info->{$key}->{Platform_manufacturer} if $hashed_info->{$key}->{Platform_manufacturer};
		$item = $item_doc->add_item(Array => %item_attr);
		
		$platform_items{$key} = $item;
		
	}
}#end createPlatformItems

sub createSeriesItems
{
	my $hashed_info = shift;
	my (%item_attr, $item);
	
	foreach my $key (keys(%$hashed_info))
	{
		next if(exists $series_items{$key});

=cut
		if($hashed_info->{$key}->{Series_samples_taxid} == 10116 or $hashed_info->{$key}->{Series_samples_organism} =~ /rattus norvegicus/i)
		{
			$item_attr{organism} = $organism_item;
		}
		else
		{
			next;
		}

=cut

		if(ref $hashed_info->{$key}->{Series_summary} eq "ARRAY")
		{ $item_attr{description} = join(' ', @{$hashed_info->{$key}->{Series_summary}}); }
		else
		{ $item_attr{description} = $hashed_info->{$key}->{Series_summary}; }
		
		if(ref $hashed_info->{$key}->{Series_type} eq "ARRAY")
		{ $item_attr{type} = join ' ', @{$hashed_info->{$key}->{Series_type}}; }
		elsif(exists $hashed_info->{$key}->{Series_type})
		{ $item_attr{type} = $hashed_info->{$key}->{Series_type}; }

		#$item_attr{url}
		#$item_attr{version}
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
		
		$series_items{$key} = $item;
		
	}
}#end createSeriesItems

sub createSampleItems
{
	my $hashed_info = shift;
	my (%item_attr, $item);
	
	foreach my $key (keys(%$hashed_info))
	{
		next if(exists $sample_items{$key});
		if($hashed_info->{$key}->{Sample_taxid_ch1} == 10116 or $hashed_info->{$key}->{Sample_organism_ch1} =~ /rattus norvegicus/i)
		{
			$item_attr{organism} = $organism_item;
		}
		else
		{
			next;
		}

		$item_attr{title} = $hashed_info->{$key}->{Sample_title};
		$item_attr{geoAccession} = $key;
		$item_attr{type} = $hashed_info->{$key}->{Sample_type};
		$item_attr{source} = $hashed_info->{$key}->{Sample_source_name_ch1};
		$item_attr{molecule} = $hashed_info->{$key}->{Sample_molecule_ch1};
		$item_attr{status} = $hashed_info->{$key}->{Sample_status};

		my $series_item = getSeriesItem($hashed_info->{$key}->{Sample_series_id});
		my $platform_item = getPlatformItem($hashed_info->{$key}->{Sample_platform_id});
		
		if(ref($hashed_info->{$key}->{Sample_description}) eq "ARRAY")
		{	$item_attr{description} = join(" ", @{$hashed_info->{$key}->{Sample_description}});	}
		elsif(exists($hashed_info->{$key}->{Sample_description}))
		{	$item_attr{description} = $hashed_info->{$key}->{Sample_description};	}
		
		if(ref($series_item) eq "ARRAY")
		{	$item_attr{geoSeries} = $series_item;	}
		elsif($platform_item)
		{	$item_attr{geoSeries} = [$series_item];	}		
		
		if($platform_item and ref($platform_item) eq "ARRAY")
		{	$item_attr{platforms} = $platform_item;	}
		elsif($platform_item)
		{	$item_attr{platforms} = [$platform_item];	}
		
		$item = $item_doc->add_item(GEOSample => %item_attr);
		
		$sample_items{$key} = $item;

		foreach my $key (keys(%{$hashed_info->{table}})) {
			my $probeset = getProbesetItem($key);
			$item_doc->add_item('SampleCall', probeSet => $probeset, call => $hashed_info->{table}->{$key}, geoSample => $item);
		}
		
	}
}#end createSampleItems

sub getProbesetItem
{
	my $probeId = shift;	
	return undef unless $probeId;
	
	unless(exists $probe_items{$probeId})
	{
		my $item = $item_doc->add_item('ProbeSet', primaryIdentifier => $probeId);
		$probe_items{$probeId} = $item;
	}
	return $probe_items{$probeId};
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
			my $item = $item_doc->add_item('Array', geoAccession => $geoAcc);
			$platform_items{$geoAcc} = $item;
		}
		return $platform_items{$geoAcc};
	}
}

sub getSeriesItem
{
	my $geoAcc = shift;
	
	return undef unless $geoAcc;
		
	if(ref($geoAcc) eq 'ARRAY')
	{
		my @series;
		foreach my $s (@$geoAcc)
		{
			my $si = getSeriesItem($s);
			push(@series, $si);
		}
		return \@series;
	}
	else
	{
		unless(exists $series_items{$geoAcc})
		{
			my $item = $item_doc->add_item('GEOSeries', geoAccession => $geoAcc);
			$series_items{$geoAcc} = $item;
		}
		return $series_items{$geoAcc};
	}

}