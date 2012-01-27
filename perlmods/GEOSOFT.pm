package GEOSOFT;
use RCM;


sub new
{
	my $class = shift;
	my $file = shift;
	my $self = {};

	if($file)
	{
		$self = processFile($file);
	}
	bless $self, $class;
	return $self;
} #new

sub processFile
{
	my ($soft) = shift;
	
	my $table_flag = 0;
	my $th_flag = 1;

	open(my $IN, '<', $soft);
	my $info = {};
	my @tableRows;
	my ($class, $name);
	while(<$IN>)
	{
		s/[\n\r]//g;
		if($table_flag)
		{
			if(/^!\w+?_table_end/)
			{	
				$info->{$class}->{table} = \@tableRows;
				$table_flag = 0 and $th_flag = 1;	}
			elsif($th_flag)
			{	
				$index = RCM::parseHeader($_);
				$info->{$class}->{tableHeader} = $index;
				$th_flag = 0;
			}
			else
			{
				my @row = split(/\t/);
				push(@tableRows, \@row);
			}
#			/^([\w_]+).*?([AP])$/;
#			my($probe, $call) = ($1, $2);
#			$info->{$class}->{table}->{$probe} = $call if $probe;
		}
		elsif(/^\^/)
		{
			s/.//;
			($class, $name) = split(' = ', $_, 2);
			$name ? $name : $name = $class;
		}
		elsif(/^!\w+?_table_begin/)
		{
			$table_flag = 1;
		}
		elsif(/^!/)
		{
			die('malformed SOFT file') unless ($class);
			s/.//;
			my ($point, $value) = split(/\s+=\s+/, $_, 2);
			
			if($info->{$class}->{$name}->{$point})
			{
				if(ref($info->{$class}->{$name}->{$point}) eq "ARRAY")
				{
					push(@{$info->{$class}->{$name}->{$point}}, $value);
				}
				else
				{
					$info->{$class}->{$name}->{$point} = [$info->{$class}->{$name}->{$point}, $value];
				}
			}
			else
			{
				$info->{$class}->{$name}->{$point} = "$value";
			}
		} #if-elsif-elsif-elsif
	} #while
	return $info;
} #processFile

1;