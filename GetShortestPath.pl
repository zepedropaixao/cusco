#!/usr/bin/perl -w
    
###############################################################################
#
# CUSCO PROJECT - CGI that returns the entity shortest path
#
###############################################################################
use strict;
use warnings;
use CGI;
use DBI;
use JSON;

my $cgi = new CGI;

my $name1 = $cgi->param('name1');
my $name2 = $cgi->param('name2');

#print " ===> Connecting to Cusco's DB...\n";
my $db = "cusco";
my $db_server = "localhost";
my $user = "cusco_admin";
my $pass = "cusco_admin_pass";
my $dbh = DBI->connect("DBI:mysql:database=$db;$db_server;timeout=240",
			$user, 
			$pass, 
			{mysql_enable_utf8=>1}) || die "Could not connect to database: $DBI::errstr";


# executes a query
sub ExecuteSQL($) {
  my $q = shift;  
  ## Trim, prepare and execute a query
  while ($q=~s/^\s//g) {}
  $q =~ s/\s+/ /g;
  $q =~ s/\n+/ /g;
  
  my $sth = $dbh->prepare($q);
  if (defined($sth)) { 
  	warn "$q\n";
    $sth->execute(); 
  } else { 
    warn ("Problems with: ". $q ."\n"); 
  }

  ## Fetch results in case of a select into an array and return
  if ($q!~/^SELECT/i) {
    return;
  }
  my @tuples = ();
  	while (my $hashRef = $sth->fetchrow_hashref()) { 
  	  push (@tuples, $hashRef);
  }
  return \@tuples;
}

my $q = "SELECT * FROM paths WHERE name1 = \"$name1\" AND name2 = \"$name2\"";
my $results = ExecuteSQL($q);

my %output = ();
$output{startName} = $name1;
$output{endName} = $name2;

my $nodes_string = $results->[0]->{path};
my @nodes = split("_", $nodes_string);
my @final_nodes = ();
#GET PHOTOS
my $q2 = "SELECT * FROM people WHERE ";
for(@nodes){
	my $name = $_;
	$q2 .= "name = \"$name\" OR ";
	push(@final_nodes, {name => $name });
}
$q2 =~ s/ OR $//;
my $results2 = ExecuteSQL($q2);
for (@nodes) {
	


}
for (@{$results2}) {
	my %tuple = %{$_};
	my %name_hash = ();
	$name_hash{name} = $tuple{name};
	$name_hash{photo} = "";
	$name_hash{photo} = "http://62.28.240.159/cusco/images/$tuple{photo_name}" if $tuple{photo_name};
	my $q3 = "SELECT * FROM relationships WHERE name1 = \"$tuple{name}\" OR name2 = \"$tuple{name}\"";
	my $results3 = ExecuteSQL($q3);
	my @neighbours = ();
	for (@{$results3}) {
		my %tuple2 = %{$_};
		my %neighbour_hash = ();
		my $neighbour = "";
		$neighbour = $tuple2{name1} if ($tuple{name} ne $tuple2{name1});
		$neighbour = $tuple2{name2} if ($tuple{name} ne $tuple2{name2});
		$neighbour_hash{name} = $neighbour;
		$neighbour_hash{photo} = "";
		my $q4 = "SELECT * FROM people WHERE name = \"$neighbour\"";
		my $results4 = ExecuteSQL($q4);
		$neighbour_hash{photo} = "http://62.28.240.159/cusco/images/$results4->[0]->{photo_name}" if $results4->[0]->{photo_name};
		push(@neighbours, \%neighbour_hash);
	}
	$name_hash{neighbours} = \@neighbours;
	my $index = 0;
	for(@final_nodes) {
		$final_nodes[$index] = \%name_hash if ($final_nodes[$index]->{name} eq $name_hash{name});
		$index++;
	}	
	
}
$output{path} = \@final_nodes;
$output{distance} = $results->[0]->{distance};

my $output_string = encode_json \%output;


# PRINT OUTPUT

print($cgi->header(-type => "application/json; charset=utf-8"));

print $output_string;

=end
