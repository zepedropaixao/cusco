#!/usr/bin/perl

use strict;
use warnings;
use Encode;
use POSIX;

sub ParseLineAbstractNTLine($) {
	my $line = shift;
	
	# ex: <http://dbpedia.org/resource/Albergaria-a-Velha> <http://www.w3.org/2000/01/rdf-schema#comment> "Albergaria-a-Velha
	$line =~/resource\/(.*)\> <http\:\/\/xmlns(.*)\> \<(http\:(.*))\>/;
	my $url = $3;
	my $title = $1;
	$title =~ s/\%([A-Fa-f0-9]{2})/pack('C', hex($1))/seg;
	$title =~ s/_/ /g;
	$title =~ s/\s{0,1}\(.+?\)//i;
	Encode::from_to($title, "iso-8859-1", "utf8");  

	## Let's extract the title
	
	## And now for the abstract 
	$url =~ s/\%([A-Fa-f0-9]{2})/pack('C', hex($1))/seg;
	#$url =~ s/\\u00(..)/pack('C', hex($1))/seg;
	$url =~ s/\s{0,1}\(.+?\)//i;
	Encode::from_to($url, "iso-8859-1", "utf8");         
	
	## Output
	my %out = ();
	$out{title} = $title;
	$out{url} = $url;
	return %out;
}

sub ParseDBpedia {
open (WIKIPEDIA, 'images_pt.nt');
my $count = 0;
while (<WIKIPEDIA>) {
	my $line = $_;
	#if($line eq ""){next;}
	#if($line =~ /^<http\:\/\/upload/){next;}
	#if($line =~ /commons\/thumb/){next;}
	#if($line !~ /^<http\:/){next;}
	if($line =~/resource\/(.*)\> <http\:\/\/xmlns(.*)\> \<(http\:(.*))\>/){
		my %line_hash = ParseLineAbstractNTLine($line);
		print "$line_hash{title} <=!=> $line_hash{url}\n";	
	} else {next;}
}
close (WIKIPEDIA);
}

sub start {
open (STDOUT, '>>resultados_maluco2.nt');
ParseDBpedia();
close (STDOUT);
}

start();
