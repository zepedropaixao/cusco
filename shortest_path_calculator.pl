#!/usr/bin/perl -w
    
###############################################################################
#
# CUSCO PROJECT - shortest path calculator
#
###############################################################################

use strict;
use warnings;
use DBI;
use Boost::Graph;
use Data::Dumper::Simple;
use utf8;

binmode(STDOUT, "utf8");

my $start = shift;
my $end = shift;

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

#my $neighbours =  $graph->neighbors("José Eduardo Matos");
#print Dumper $neighbours;

#my $neighbours2 =  $graph->neighbors("Paulo Sá");
#print Dumper $neighbours2;Altino Bessa



#my $dijkstra = $graph->dijkstra_shortest_path("José Eduardo Matos","Paulo Sá");
#print Dumper $dijkstra;


#my %output = ();
print "NUMBER OF NAMES: " . scalar(keys %names) . "\n";
#exit;
#delete($names{"Paulo Sá"});
#delete($names{"Sukhumbhand Paribatra"});
#delete($names{"Roberto Monteiro"});
#delete($names{"Francisco Maduro Dias"});
delete($names{"D. Carlos Azevedo"});
delete($names{"Maria João Koehler"});
delete($names{"Paulo Henrique Ganso"});
delete($names{"José Mota"});
delete($names{"Michelle Larcher de Brito"});
delete($names{"João Semedo"});
delete($names{"Magali de Lattre"});
delete($names{"Michelle Brito"});
delete($names{"Casimiro Calafate"});
delete($names{"Emília Castela"});
delete($names{"Leonardo Meani"});
delete($names{"Frédéric Lefebvre"});
delete($names{"Glória Afonso"});
#delete($names{"Carlos Martins"});
delete($names{"Caroline Wozniacki"});
delete($names{"Maria Sharapova"});
delete($names{"Serena Williams"});
delete($names{"Maria João Frada"});
delete($names{"Claudio Lotito"});
delete($names{"José Carlos Pinto Coelho"});
delete($names{"Taleb Rifai"});
delete($names{"Luciano Moggi"});
my $counter = 0;
my @names_array = sort (keys %names);
for (@names_array) {
	my $name1 = $_;
	if($counter < $start) {$counter++; next;}
        if($counter > $end) { last; }
	$counter++;
	print " - Processing person nr: $counter\tname:$name1\n";
	
	for(keys %names) {
		my $name2 = $_;
		if($name2 eq $name1) {next;}
		#print " calculating for $name1 - $name2 \n";
		
		my $dijkstra = "";
		$dijkstra = $graph->dijkstra_shortest_path($name1,$name2);
		#print Dumper $dijkstra;
		if($dijkstra && $dijkstra ne "") {
			my @path_array = @{$dijkstra->{path}};
			my $path = join("_", @path_array);
			my $q = "INSERT INTO paths VALUE(\"$name1\", \"$name2\", \"$path\", \"$dijkstra->{weight}\")";
			ExecuteSQL($q);
		}
	}
}


#my $neighbours =  $graph->neighbors("Barack Obama");

#print Dumper %output;




#print Dumper $dijkstra;

