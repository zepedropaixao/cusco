#!/usr/bin/perl -w
    
###############################################################################
#
# CUSCO PROJECT
#
###############################################################################

use strict;
use warnings;
#use LWP::Simple;
use DBI;
use Image::Grab;

use utf8;

binmode(STDOUT, "utf8");

our %DBpedia_images;



open (IMGS, 'resultados_maluco2.nt');
while (<IMGS>) {
	chomp;
	my $line = $_;
	## Let's extract the title
	$line =~/^(.*) <=!=> (.*)/;
	my $title = $1;
	my $url = $2;   
	
	## Output
	#print "$title ===> $abstract\n";
	if($title && $url){
		$DBpedia_images{$title} = $url;
	}
}
close (IMGS);


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

my $q = "SELECT * FROM people";
my $results = ExecuteSQL($q);

my $counter = 0;
my $total = 0;
for (@{$results}) {
	my %tuple = %{$_};
	my $name = $tuple{name};
	$total++;

	if($DBpedia_images{$name}) {
		# The simplest OO case of a grab
		my $pic = new Image::Grab;
		$pic->url($DBpedia_images{$name});
		$pic->grab;

		# Now to save the image to disk
		if($pic->image){			
			open(IMAGE, ">>./images/$name.jpg") || die"image.jpg: $!";
			#binmode IMAGE;  # for MSDOS derivations.
			print IMAGE $pic->image;
			close IMAGE;
			my $q = "UPDATE people SET photo_name = \"$name.jpg\" WHERE name = \"$name\"";
			ExecuteSQL($q);
			$counter++; print "Found photo for $name: $DBpedia_images{$name}\n";
		} else {
			print "Problems downloading image for $name!\n";
		}

	}
	

}

print "FOUND $counter of $total\n";
