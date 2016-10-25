package C4::UALCustom;

use strict;
use warnings;
require Exporter;
use C4::Context;
use vars qw(@ISA @EXPORT);
use Data::Dumper;

@ISA    = qw(Exporter);
@EXPORT = qw(
  &CleanSearches
  &CleanSearchString
  &GetIndexLabels
  &GetCCodeLabels
  &GetBranchLabels
  &GetiTypeLabels
);

sub CleanSearches {
	my @searcharray = @_;
	my @csearches=();
	for my $search (@searcharray) {
	#for my $entry(@{ $outer_hash->{backupsize} }){
	#while (my ($i, $el) = each @searcharray) {
		#print Dumper($search);
		$search->{'clean_query_desc'} = CleanSearchString($search->{'query_desc'});
		#$search->{'counter'} = $i;
		push @csearches,$search;
	}
	return @csearches;
}

sub CleanSearchString {
	my $string = shift;
	my $labels = GetIndexLabels();
	my $ccode = GetCCodeLabels();
	my $branches = GetBranchLabels();
	my $itypes = GetiTypeLabels();
	my $label;
	while(my($k, $v) = each $labels) {
		$string =~ s/$k/$v/g;
	}
	while(my($k, $v) = each $ccode) {
		$string =~ s/$k/$v/g;
	}
	while(my($k, $v) = each $branches) {
		$string =~ s/$k/$v/g;
	}
	while(my($k, $v) = each $itypes) {
		$string =~ s/$k/$v/g;
	}
	return $string;
}

sub GetIndexLabels {
	my %labels = (
		'kw,wrdl:'				=>	'keyword(s):',
		'su,wrdl:'				=>	'topic:',
		'ti,wrdl:'				=>	'title:',
		'ti:'					=>	'title:',
		'homebranch:'			=>	'branch:',
		'su,phr:'				=>	'subject phrase:',
		'su-br,wrdl:'			=>	'subject and broader terms:',
		'su-na:'				=>	'subject and narrower terms:',
		'su-rl:'				=>	'subject and related terms:',
		'su:'					=>	'subject:',
		'ti,phr:'				=>	'title phrase:',
		'se,wrdl:'				=>	'series title:',
		'callnum,wrdl:'			=>	'shelved at:',
		'location,wrdl:'		=>	'shelving location:',
		'au,wrdl:'				=>	'author:',
		'au,phr:'				=>	'author phrase:',
		'cpn,wrdl:'				=>	'corporate name:',
		'cfn,wrdl:'				=>	'conference name:',
		'cfn,phr:'				=>	'conference name phrase:',
		'pn,wrdl:'				=>	'personal name:',
		'pn,phr:'				=>	'personal name phrase:',
		'nt,wrdl:'				=>	'notes/comments:',
		'sn,wrdl:'				=>	'standard number:',
		'pb,wrdl:'				=>	'publisher:',
		'nb:'					=>	'isbn:',
		'ns:'					=>	'issn:',
		'bc,wrdl:'				=>	'barcode:',
		'ccode:'				=>	'material type:',
		'mc-ccode:'				=>	'material type:',
		'mc-material type:'		=>	'material type:',
		'au:'					=>	'author:',
		'an:'					=>	'authority number:',
		'mc-itype,phr:'			=>	'loan period:',
		'itype:'				=>	'loan period:',
		'su-geo:'				=>	'place:',
		'su-to:'				=>	'topic:',
		'yr,st-numeric,ge'		=>	'from year',
		'yr,st-numeric,le'		=>	'to year',
		'mc-loc'				=>	'collection',
	);
	return \%labels;
}

sub GetCCodeLabels {
	my $item;
	my %hash;
    my $dbh = C4::Context->dbh;
	my $sth = $dbh->prepare("SELECT authorised_value, lib FROM authorised_values where category='CCODE'");
    $sth->execute;
    my $data = $sth->fetchall_arrayref( {} );
    foreach $item (@$data) {
	$hash{$item->{'authorised_value'}} = $item->{'lib'};
    }
    return \%hash;
}

sub GetBranchLabels {
	my $item;
	my %hash;
    my $dbh = C4::Context->dbh;
	my $sth = $dbh->prepare("SELECT branchcode, branchname FROM branches");
    $sth->execute;
    my $data = $sth->fetchall_arrayref( {} );
    foreach $item (@$data) {
	$hash{$item->{'branchcode'}} = $item->{'branchname'};
    }
    return \%hash;
}

sub GetiTypeLabels {
	my $item;
	my %hash;
    my $dbh = C4::Context->dbh;
	my $sth = $dbh->prepare("SELECT itemtype, description FROM itemtypes");
    $sth->execute;
    my $data = $sth->fetchall_arrayref( {} );
    foreach $item (@$data) {
	$hash{$item->{'itemtype'}} = $item->{'description'};
    }
    return \%hash;
}

#need to account for homelocation and get branchcodes/branches

1;
