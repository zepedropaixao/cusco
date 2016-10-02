#!/usr/bin/perl -w
    
###############################################################################
#
# CUSCO PROJECT - CGI that returns the entity relations graph
#
###############################################################################
use strict;
use warnings;
use CGI;


use DBI;
use Boost::Graph;
use Data::Dumper::Simple;
use utf8;

binmode(STDOUT, "utf8");



# Create an empty instance of a Graph
my $graph = new Boost::Graph(directed=>0, net_name=>'Cusco Graph', net_id=>1000); 


print " ===> Connecting to Cusco's DB...\n";
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
  	#warn "$q\n";
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

my $q = "SELECT * FROM relationships";
my $results = ExecuteSQL($q);

my %names = ();

for (@{$results}) {
	my %tuple = %{$_};
	$names{$tuple{name1}}++;
	$names{$tuple{name2}}++;
	my $status = $graph->add_edge($tuple{name1},$tuple{name2});
	if($status) {
		#print "Success! Added edge $tuple{name1} - $tuple{name2}!\n";
	} else {
		print "Warning: Did not add edge $tuple{name1} - $tuple{name2}! Possibly already exist!\n";
	}

}



my %output = ();
print "NUMBER OF NAMES: " . scalar(keys %names) . "\n";
exit;
delete($names{"Paulo Sá"});
delete($names{"Sukhumbhand Paribatra"});
delete($names{"Roberto Monteiro"});
delete($names{"Francisco Maduro Dias"});
for (keys %names) {
	my $name1 = $_;
	for(keys %names) {
		my $name2 = $_;
		if($name2 eq $name1) {next;}
		print " calculating for $name1 - $name2 \n";
		my $dijkstra = "";
		$dijkstra = $graph->dijkstra_shortest_path($name1,$name2);
		print Dumper $dijkstra;
		if($dijkstra ne "") {
			$dijkstra->{name1} = $name1;
			$dijkstra->{name2} = $name2;
			my %names2 = ();
			%names2 = %{$output{$name1}} if $output{$name1};
			$names2{$name2} = $dijkstra;
			$output{$name1} = \%names2;
		}
	}
}







my $query = new CGI;
print($query->header(-type => "text/html; charset=utf-8"));


my $output = "
<HTML>
       <HEAD>
       <script … protovis/>
       </HEAD>
       ….
</HTML>
";


print $output;

=end
