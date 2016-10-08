#!/usr/bin/perl -w
    
###############################################################################
#
# CUSCO PROJECT - shortest path calculator
#
###############################################################################

use strict;
use warnings;
use DBI;
#use Boost::Graph;
#use Data::Dumper::Simple;
use utf8;

binmode(STDOUT, "utf8");

#my $start = shift;
#my $end = shift;

# Create an empty instance of a Graph
#my $graph = new Boost::Graph(directed=>0, net_name=>'Cusco Graph', net_id=>1000); 


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

my $q = "SELECT name1 FROM paths GROUP BY name1";
my $results = ExecuteSQL($q);

#my %names = ();

for (@{$results}) {
	my %tuple = %{$_};
	print "hein?\n";
	#$names{$tuple{name1}}++;
	#$names{$tuple{name2}}++;
	#my $status = $graph->add_edge($tuple{name1},$tuple{name2});
	my $q = "INSERT INTO people VALUE(\"$tuple{name1}\", \"\")";
	ExecuteSQL($q) if $tuple{name1};

}
