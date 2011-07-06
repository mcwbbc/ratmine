#!/usr/bin/perl
#by Andrew Vallejos

=head1 update-data.pl

=pod

perl update-data.pl

Purpose:
	Download and preprocess, if necessary, data for InterMine build

	Options:
	--conf [file]		configuration xml file
	--project [file]	project.xml file
	--verbose		prints out additional information, may be useful for debugging
	--help			prints this message

See conf/download_conf.xml.example for information on creating a
configuration XML file.

=cut

use XML::XPath;
use Getopt::Long;
use LWP::UserAgent;
use threads;
use strict;

my ($conf, $project, $help, $verbose, $dry);

GetOptions( 'config=s' => \$conf,
			'project=s' => \$project,
			'verbose' => \$verbose,
			'dry-run' => \$dry,
			'help' => \$help );
			
if ($help or !($conf and $project))
{
	&printHelp;
	exit(0);
}

my $projectInfo = getProjectInfo($project);

updateData($conf, $projectInfo);

exit (0);
###Subroutines###

sub printHelp
{
	print<<HELP

 perl update-data.pl

 Purpose:
	Download and preprocess, if necessary, data for InterMine build

	Options:
	--conf [file]\tconfiguration xml file
	--project [file]\tproject.xml file
	--verbose\tprints out additional information, may be useful for debugging
	--help\t\tprints this message

 See conf/download_conf.xml.example for information on creating a
 configuration XML file.
HELP
}

sub getProjectInfo
{
	my $project_file = shift;
	
	my $xp = XML::XPath->new(filename => $project_file);
	my $nodeset = $xp->find('/project/sources/source'); #find all sources
	
	my %project_info;
	foreach my $node ($nodeset->get_nodelist)
	{
		my $type = $node->find('@name')->string_value;
		my $data;
		if($data = $node->find('property[@name="src.data.file"]/@location')->string_value)
		{	$project_info{$type}{file} = $data;	}
		elsif($data = $node->find('property[@name="src.data.dir"]/@location')->string_value)
		{	$project_info{$type}{dir} = $data;	}
	}
	
	return \%project_info;
}

sub updateData
{
	my ($conf, $projectInfo) = @_;
	
	my $xp = XML::XPath->new(filename => $conf);
	my $model = $xp->find('/project-config/model-file')->string_value;
	
	my $nodeset = $xp->find('/project-config/source');
	
	foreach my $node ($nodeset->get_nodelist)
	{
		threads->new(sub{updateNodeSource($node, $projectInfo, $model);});
	}#end foreach $node
	
	while(threads->list(threads::running()))
	{
		foreach my $thr (threads->list(threads::joinable()))
		{
			$thr->join();
		}
		sleep(30);
	}
}#end updateData

sub updateNodeSource
{
	my ($node, $projectInfo, $model) = @_;
	
	my $source = $node->find('@name')->string_value;
	my $remote = $node->find('remote-file')->string_value;
	my $destination = $node->find('destination')->string_value;
	my $localfile = '';
	if ($remote)
	{
		if($$projectInfo{$source}{dir} or !$destination)
		{
			if($$projectInfo{$source}{file})
			{
				$destination = $$projectInfo{$source}{file};
			}
			elsif($$projectInfo{$source}{dir})
			{
				$localfile = $& if $remote =~ m|\/[^\/\\]+?$|;
				$destination = $$projectInfo{$source}{dir} . $localfile if !$destination;
			}
		}#end if(!$destination)
		
		&downloadFile($remote, $destination, $dry);
	}#end if ($remote)
	
	my $scriptset = $node->find('scripts/script');
	foreach my $scriptnode ($scriptset->get_nodelist)
	{
		&runScript($scriptnode, $model, $destination, $source, $localfile, $dry);
	}
}

sub runScript
{
	my($node, $model, $destination, $source, $localfile, $dry) = @_;
	
	my $script = $node->find('@script')->string_value;
	if ($script)
	{
		my $options = '';
		my $optionset = $node->find('option');
		foreach my $opt ($optionset->get_nodelist)
		{
			my $type = $opt->find('@type')->string_value;
			my $arguement = $opt->find('@name')->string_value;
			$options .="--$arguement" if $arguement;
			if ($type eq 'custom')
			{
				my $value = $opt->string_value;
				$options .= " $value ";
			}
			elsif ($type eq 'flag')
			{	$options .= ' ';  	} 
			elsif($type eq 'model')
			{
				$options .= " $model ";
			}
			elsif($type eq 'input')
			{
				$options .= " $destination ";
			}
			elsif($type eq 'output')
			{
				$$projectInfo{$source}{file} ne '' ? 
					$options .= " $$projectInfo{$source}{file} " :
					$options .= " $$projectInfo{$source}{dir}$localfile ";
			}
		}#end foreach
	
		print "$script $options\n" if $verbose;
		return if $dry;

		my $results =  `$script $options`;
		print $results if $verbose;
	}#end if ($script)
}

sub downloadFile
{
	my ($remoteFile, $localFile, $dry) = @_;
	return if $dry;

	my $ua = LWP::UserAgent->new;
	my $req = HTTP::Request->new(GET => $remoteFile);
	my $res = $ua->request($req, $localFile);
	if($verbose)
	{	
		$res->is_success ?
			print "$remoteFile downloaded\n" :
			print $res->status_line . "\n";
	}
}
