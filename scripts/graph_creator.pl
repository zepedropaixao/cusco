#!/usr/bin/perl -w
    
###############################################################################
#
# CUSCO PROJECT
#
###############################################################################

use strict;
use warnings;
use LWP::Simple;
use JSON;
use Data::Dumper::Simple;
use DBI;
use utf8;

binmode(STDOUT, "utf8");

#my $start_name_nr = shift;
#my $end_name_nr = shift;

#if(!$start_name_nr || !$end_name_nr) {print "ERROR: no inputs!\n"; exit;}

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
  ##warn("Preparing '$q'\n");
  
  #$q =~ /FROM ([^\s]+)/i;
  #print "TABLE: " . $1 . "\n" if $1;
  
  
  
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




sub SaveRelationship {
	my $name1 = shift || "";
	my $name2 = shift || "";
	if($name1 eq "" || $name2 eq "") {
		print "Name1 or Name2 invalid!! Not Saved!\n";
		return 0;
	}

	my $q = "SELECT * FROM relationships WHERE (name1 = \"$name1\" AND name2 = \"$name2\") OR (name1 = \"$name2\" AND name2 = \"$name1\")";
	my $results = ExecuteSQL($q);
	if(scalar(@{$results}) >= 1) {
		print "Entry already exists! Moving on...\n";
		return 1;
	} else {
		# No entry found: inserting into database
		$q = "INSERT INTO relationships	VALUE(\"$name1\", \"$name2\")";
		ExecuteSQL($q);
		return 1;
	}
}


# Get all personalities
print "===> Fetching all personalities names on Verbetes...\n";
my $all_personalities_json = get("http://services.sapo.pt/InformationRetrieval/Verbetes/GetPersonalities?min=5");
die "Couldn't get all personalities!" unless defined $all_personalities_json;

# Decode JSON input
my $all_personalities_ref = decode_json $all_personalities_json;
my %all_personalities = %{$all_personalities_ref->{listPersonalities}};

# Get array of personalities ordered by number of appearances
my @personalities = (sort {$all_personalities{$b} <=> $all_personalities{$a}} (keys %all_personalities));

print "<=== Done!\n";

print "Nr of persons: " . scalar(@personalities) . "\n";


# For each personality obtain co-occurences map
print "===> Fetching all personalities co-occurences...\n";
#my $begin = 0;
my $counter = 1;
#my $end = 0;

#create hash of names
my %accepted_names = ();
for (@personalities) {
	$accepted_names{$_}++;
}


for (@personalities) {
	# Get personality co-occurences
	my $name1 = $_;
	$counter++;
	#if ($counter == $start_name_nr) {$begin = 1;}
	#if ($counter == $end_name_nr) {$end = 1;}
	#if(!$begin) { next; }
	#if($end) {last;}
	print " - Fetching \"$name1\" co-occurences... Personality nr: $counter!\n";
	my $personality_coocurrences_json = get("http://services.sapo.pt/InformationRetrieval/Verbetes/GetCoOccurrences?name=$name1&begin_date=2011-10-11&end_date=2011-11-11&limit=5");
	if(!$personality_coocurrences_json) {
		print "Couldn't get $name1 co-occurences! passing to next name!\n";
		next;
	}

	# Decode JSON input
	my $personality_coocurrences_ref = decode_json $personality_coocurrences_json;
	my @personality_coocurrences = @{$personality_coocurrences_ref};
	for(@personality_coocurrences) {
		my %relation_hash = %{$_};
		my @relation_name_array = (keys %relation_hash);
		my $name2 = $relation_name_array[0];
		if($accepted_names{$name2}){
			my $output = SaveRelationship($name1, $name2);
			if($output) {
				print "Successfully saved relationship: $name1 - $name2!\n";
			} else {
				print "Failed to create relationship: $name1 - $name2!\n";
			}
		}	
	}
}







$dbh->disconnect();
#warn Dumper $all_personalities_ref;


