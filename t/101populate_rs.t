## ----------------------------------------------------------------------------
## Tests for the $resultset->populate method.
##
## GOALS:  We need to test the method for both void and array context for all
## the following relationship types: belongs_to, has_many.  Additionally we
## need to each each of those for both specified PK's and autogenerated PK's
##
## Also need to test some stuff that should generate errors.
## ----------------------------------------------------------------------------

use strict;
use warnings;

use Test::More;
use lib qw(t/lib);
use DBICTest;

plan tests => 98;


## ----------------------------------------------------------------------------
## Get a Schema and some ResultSets we can play with.
## ----------------------------------------------------------------------------

my $schema	= DBICTest->init_schema();
my $art_rs	= $schema->resultset('Artist');
my $cd_rs	= $schema->resultset('CD');

ok( $schema, 'Got a Schema object');
ok( $art_rs, 'Got Good Artist Resultset');
ok( $cd_rs, 'Got Good CD Resultset');


## ----------------------------------------------------------------------------
## Array context tests
## ----------------------------------------------------------------------------

ARRAY_CONTEXT: {

	## These first set of tests are cake because array context just delegates
	## all it's processing to $resultset->create
	
	HAS_MANY_NO_PKS: {
	
		## This first group of tests checks to make sure we can call populate
		## with the parent having many children and let the keys be automatic

		my $artists = [
			{	
				name => 'Angsty-Whiny Girl',
				cds => [
					{ title => 'My First CD', year => 2006 },
					{ title => 'Yet More Tweeny-Pop crap', year => 2007 },
				],					
			},		
			{
				name => 'Manufactured Crap',
			},
			{
				name => 'Like I Give a Damn',
				cds => [
					{ title => 'My parents sold me to a record company' ,year => 2005 },
					{ title => 'Why Am I So Ugly?', year => 2006 },
					{ title => 'I Got Surgery and am now Popular', year => 2007 }				
				],
			},
			{	
				name => 'Formerly Named',
				cds => [
					{ title => 'One Hit Wonder', year => 2006 },
				],					
			},			
		];
		
		## Get the result row objects.
		
		my ($girl, $crap, $damn, $formerly) = $art_rs->populate($artists);
		
		## Do we have the right object?
		
		isa_ok( $crap, 'DBICTest::Artist', "Got 'Artist'");
		isa_ok( $girl, 'DBICTest::Artist', "Got 'Artist'");
		isa_ok( $damn, 'DBICTest::Artist', "Got 'Artist'");	
		isa_ok( $formerly, 'DBICTest::Artist', "Got 'Artist'");	
		
		## Find the expected information?

		ok( $crap->name eq 'Manufactured Crap', "Got Correct name for result object");
		ok( $girl->name eq 'Angsty-Whiny Girl', "Got Correct name for result object");
		ok( $damn->name eq 'Like I Give a Damn', "Got Correct name for result object");	
		ok( $formerly->name eq 'Formerly Named', "Got Correct name for result object");
		
		## Create the expected children sub objects?
		
		ok( $crap->cds->count == 0, "got Expected Number of Cds");
		ok( $girl->cds->count == 2, "got Expected Number of Cds");	
		ok( $damn->cds->count == 3, "got Expected Number of Cds");
		ok( $formerly->cds->count == 1, "got Expected Number of Cds");

		## Did the cds get expected information?
		
		my ($cd1, $cd2) = $girl->cds->search({},{order_by=>'year ASC'});
		
		ok( $cd1->title eq "My First CD", "Got Expected CD Title");
		ok( $cd2->title eq "Yet More Tweeny-Pop crap", "Got Expected CD Title");
	}
	
	HAS_MANY_WITH_PKS: {
	
		## This group tests the ability to specify the PK in the parent and let
		## DBIC transparently pass the PK down to the Child and also let's the
		## child create any other needed PK's for itself.
		
		my $aid		=  $art_rs->get_column('artistid')->max || 0;
		
		my $first_aid = ++$aid;
		
		my $artists = [
			{
				artistid => $first_aid,
				name => 'PK_Angsty-Whiny Girl',
				cds => [
					{ artist => $first_aid, title => 'PK_My First CD', year => 2006 },
					{ artist => $first_aid, title => 'PK_Yet More Tweeny-Pop crap', year => 2007 },
				],					
			},		
			{
				artistid => ++$aid,
				name => 'PK_Manufactured Crap',
			},
			{
				artistid => ++$aid,
				name => 'PK_Like I Give a Damn',
				cds => [
					{ title => 'PK_My parents sold me to a record company' ,year => 2005 },
					{ title => 'PK_Why Am I So Ugly?', year => 2006 },
					{ title => 'PK_I Got Surgery and am now Popular', year => 2007 }				
				],
			},
			{
				artistid => ++$aid,
				name => 'PK_Formerly Named',
				cds => [
					{ title => 'PK_One Hit Wonder', year => 2006 },
				],					
			},			
		];
		
		## Get the result row objects.
		
		my ($girl, $crap, $damn, $formerly) = $art_rs->populate($artists);
		
		## Do we have the right object?
		
		isa_ok( $crap, 'DBICTest::Artist', "Got 'Artist'");
		isa_ok( $girl, 'DBICTest::Artist', "Got 'Artist'");
		isa_ok( $damn, 'DBICTest::Artist', "Got 'Artist'");	
		isa_ok( $formerly, 'DBICTest::Artist', "Got 'Artist'");	
		
		## Find the expected information?

		ok( $crap->name eq 'PK_Manufactured Crap', "Got Correct name for result object");
		ok( $girl->name eq 'PK_Angsty-Whiny Girl', "Got Correct name for result object");
		ok( $girl->artistid == $first_aid, "Got Correct artist PK for result object");		
		ok( $damn->name eq 'PK_Like I Give a Damn', "Got Correct name for result object");	
		ok( $formerly->name eq 'PK_Formerly Named', "Got Correct name for result object");
		
		## Create the expected children sub objects?
		
		ok( $crap->cds->count == 0, "got Expected Number of Cds");
		ok( $girl->cds->count == 2, "got Expected Number of Cds");	
		ok( $damn->cds->count == 3, "got Expected Number of Cds");
		ok( $formerly->cds->count == 1, "got Expected Number of Cds");

		## Did the cds get expected information?
		
		my ($cd1, $cd2) = $girl->cds->search({},{order_by=>'year ASC'});
		
		ok( $cd1->title eq "PK_My First CD", "Got Expected CD Title");
		ok( $cd2->title eq "PK_Yet More Tweeny-Pop crap", "Got Expected CD Title");
	}
	
	BELONGS_TO_NO_PKs: {

		## Test from a belongs_to perspective, should create artist first, 
		## then CD with artistid.  This test we let the system automatically
		## create the PK's.  Chances are good you'll use it this way mostly.
		
		my $cds = [
			{
				title => 'Some CD3',
				year => '1997',
				artist => { name => 'Fred BloggsC'},
			},
			{
				title => 'Some CD4',
				year => '1997',
				artist => { name => 'Fred BloggsD'},
			},		
		];
		
		my ($cdA, $cdB) = $cd_rs->populate($cds);
		

		isa_ok($cdA, 'DBICTest::CD', 'Created CD');
		isa_ok($cdA->artist, 'DBICTest::Artist', 'Set Artist');
		is($cdA->artist->name, 'Fred BloggsC', 'Set Artist to FredC');

		
		isa_ok($cdB, 'DBICTest::CD', 'Created CD');
		isa_ok($cdB->artist, 'DBICTest::Artist', 'Set Artist');
		is($cdB->artist->name, 'Fred BloggsD', 'Set Artist to FredD');
	}

	BELONGS_TO_WITH_PKs: {

		## Test from a belongs_to perspective, should create artist first, 
		## then CD with artistid.  This time we try setting the PK's
		
		my $aid	= $art_rs->get_column('artistid')->max || 0;

		my $cds = [
			{
				title => 'Some CD3',
				year => '1997',
				artist => { artistid=> ++$aid, name => 'Fred BloggsC'},
			},
			{
				title => 'Some CD4',
				year => '1997',
				artist => { artistid=> ++$aid, name => 'Fred BloggsD'},
			},		
		];
		
		my ($cdA, $cdB) = $cd_rs->populate($cds);
		
		isa_ok($cdA, 'DBICTest::CD', 'Created CD');
		isa_ok($cdA->artist, 'DBICTest::Artist', 'Set Artist');
		is($cdA->artist->name, 'Fred BloggsC', 'Set Artist to FredC');
		
		isa_ok($cdB, 'DBICTest::CD', 'Created CD');
		isa_ok($cdB->artist, 'DBICTest::Artist', 'Set Artist');
		is($cdB->artist->name, 'Fred BloggsD', 'Set Artist to FredD');
		ok($cdB->artist->artistid == $aid, "Got Expected Artist ID");
	}
}


## ----------------------------------------------------------------------------
## Void context tests
## ----------------------------------------------------------------------------

VOID_CONTEXT: {

	## All these tests check the ability to use populate without asking for 
	## any returned resultsets.  This uses bulk_insert as much as possible
	## in order to increase speed.
	
	HAS_MANY_WITH_PKS: {
	
		## This first group of tests checks to make sure we can call populate
		## with the parent having many children and the parent PK is set

		my $aid		=  $art_rs->get_column('artistid')->max || 0;
		
		my $first_aid = ++$aid;
		
		my $artists = [
			{
				artistid => $first_aid,
				name => 'VOID_PK_Angsty-Whiny Girl',
				cds => [
					{ artist => $first_aid, title => 'VOID_PK_My First CD', year => 2006 },
					{ artist => $first_aid, title => 'VOID_PK_Yet More Tweeny-Pop crap', year => 2007 },
				],					
			},		
			{
				artistid => ++$aid,
				name => 'VOID_PK_Manufactured Crap',
			},
			{
				artistid => ++$aid,
				name => 'VOID_PK_Like I Give a Damn',
				cds => [
					{ title => 'VOID_PK_My parents sold me to a record company' ,year => 2005 },
					{ title => 'VOID_PK_Why Am I So Ugly?', year => 2006 },
					{ title => 'VOID_PK_I Got Surgery and am now Popular', year => 2007 }				
				],
			},
			{
				artistid => ++$aid,
				name => 'VOID_PK_Formerly Named',
				cds => [
					{ title => 'VOID_PK_One Hit Wonder', year => 2006 },
				],					
			},			
		];
		
		## Get the result row objects.
		
		$art_rs->populate($artists);
		
		my ($girl, $formerly, $damn, $crap) = $art_rs->search(
			{name=>[sort map {$_->{name}} @$artists]},
			{order_by=>'name ASC'},
		);
		
		## Do we have the right object?
		
		isa_ok( $crap, 'DBICTest::Artist', "Got 'Artist'");
		isa_ok( $girl, 'DBICTest::Artist', "Got 'Artist'");
		isa_ok( $damn, 'DBICTest::Artist', "Got 'Artist'");	
		isa_ok( $formerly, 'DBICTest::Artist', "Got 'Artist'");	
		
		## Find the expected information?

		ok( $crap->name eq 'VOID_PK_Manufactured Crap', "Got Correct name for result object");
		ok( $girl->name eq 'VOID_PK_Angsty-Whiny Girl', "Got Correct name for result object");
		ok( $damn->name eq 'VOID_PK_Like I Give a Damn', "Got Correct name for result object");	
		ok( $formerly->name eq 'VOID_PK_Formerly Named', "Got Correct name for result object");
		
		## Create the expected children sub objects?
		ok( $crap->can('cds'), "Has cds relationship");
		ok( $girl->can('cds'), "Has cds relationship");
		ok( $damn->can('cds'), "Has cds relationship");
		ok( $formerly->can('cds'), "Has cds relationship");
		
		ok( $crap->cds->count == 0, "got Expected Number of Cds");
		ok( $girl->cds->count == 2, "got Expected Number of Cds");	
		ok( $damn->cds->count == 3, "got Expected Number of Cds");
		ok( $formerly->cds->count == 1, "got Expected Number of Cds");

		## Did the cds get expected information?
		
		my ($cd1, $cd2) = $girl->cds->search({},{order_by=>'year ASC'});
		
		ok( $cd1->title eq "VOID_PK_My First CD", "Got Expected CD Title");
		ok( $cd2->title eq "VOID_PK_Yet More Tweeny-Pop crap", "Got Expected CD Title");
	}
	
	
	BELONGS_TO_WITH_PKs: {

		## Test from a belongs_to perspective, should create artist first, 
		## then CD with artistid.  This time we try setting the PK's
		
		my $aid	= $art_rs->get_column('artistid')->max || 0;

		my $cds = [
			{
				title => 'Some CD3B',
				year => '1997',
				artist => { artistid=> ++$aid, name => 'Fred BloggsCB'},
			},
			{
				title => 'Some CD4B',
				year => '1997',
				artist => { artistid=> ++$aid, name => 'Fred BloggsDB'},
			},		
		];
		
		$cd_rs->populate($cds);
		
		my ($cdA, $cdB) = $cd_rs->search(
			{title=>[sort map {$_->{title}} @$cds]},
			{order_by=>'title ASC'},
		);
		
		isa_ok($cdA, 'DBICTest::CD', 'Created CD');
		isa_ok($cdA->artist, 'DBICTest::Artist', 'Set Artist');
		is($cdA->artist->name, 'Fred BloggsCB', 'Set Artist to FredCB');
		
		isa_ok($cdB, 'DBICTest::CD', 'Created CD');
		isa_ok($cdB->artist, 'DBICTest::Artist', 'Set Artist');
		is($cdB->artist->name, 'Fred BloggsDB', 'Set Artist to FredDB');
		ok($cdB->artist->artistid == $aid, "Got Expected Artist ID");
	}

	BELONGS_TO_NO_PKs: {

		## Test from a belongs_to perspective, should create artist first, 
		## then CD with artistid.
		
		diag("Starting Void Context BelongsTO with No PKs");
		
		my $cds = [
			{
				title => 'Some CD3BB',
				year => '1997',
				artist => { name => 'Fred BloggsCBB'},
			},
			{
				title => 'Some CD4BB',
				year => '1997',
				artist => { name => 'Fred BloggsDBB'},
			},		
		];
		
		$cd_rs->populate($cds);
		
		my ($cdA, $cdB) = $cd_rs->search(
			{title=>[sort map {$_->{title}} @$cds]},
			{order_by=>'title ASC'},
		);
		
		isa_ok($cdA, 'DBICTest::CD', 'Created CD');
		isa_ok($cdA->artist, 'DBICTest::Artist', 'Set Artist');
		is($cdA->title, 'Some CD3BB', 'Found Expected title');
		is($cdA->artist->name, 'Fred BloggsCBB', 'Set Artist to FredCBB');
		
		isa_ok($cdB, 'DBICTest::CD', 'Created CD');
		isa_ok($cdB->artist, 'DBICTest::Artist', 'Set Artist');
		is($cdB->title, 'Some CD4BB', 'Found Expected title');
		is($cdB->artist->name, 'Fred BloggsDBB', 'Set Artist to FredDBB');
	}
	
	
	HAS_MANY_NO_PKS: {
	
		## This first group of tests checks to make sure we can call populate
		## with the parent having many children and let the keys be automatic
		
		diag("Starting Void Context Has Many with No PKs");

		my $artists = [
			{	
				name => 'VOID_Angsty-Whiny Girl',
				cds => [
					{ title => 'VOID_My First CD', year => 2006 },
					{ title => 'VOID_Yet More Tweeny-Pop crap', year => 2007 },
				],					
			},		
			{
				name => 'VOID_Manufactured Crap',
			},
			{
				name => 'VOID_Like I Give a Damn',
				cds => [
					{ title => 'VOID_My parents sold me to a record company' ,year => 2005 },
					{ title => 'VOID_Why Am I So Ugly?', year => 2006 },
					{ title => 'VOID_I Got Surgery and am now Popular', year => 2007 }				
				],
			},
			{	
				name => 'VOID_Formerly Named',
				cds => [
					{ title => 'VOID_One Hit Wonder', year => 2006 },
				],					
			},			
		];
		
		## Get the result row objects.
		
		$art_rs->populate($artists);
		
		my ($girl, $formerly, $damn, $crap) = $art_rs->search(
			{name=>[sort map {$_->{name}} @$artists]},
			{order_by=>'name ASC'},
		);
		
		## Do we have the right object?
		
		isa_ok( $crap, 'DBICTest::Artist', "Got 'Artist'");
		isa_ok( $girl, 'DBICTest::Artist', "Got 'Artist'");
		isa_ok( $damn, 'DBICTest::Artist', "Got 'Artist'");	
		isa_ok( $formerly, 'DBICTest::Artist', "Got 'Artist'");	
		
		## Find the expected information?

		ok( $crap->name eq 'VOID_Manufactured Crap', "Got Correct name for result object");
		ok( $girl->name eq 'VOID_Angsty-Whiny Girl', "Got Correct name for result object");
		ok( $damn->name eq 'VOID_Like I Give a Damn', "Got Correct name for result object");	
		ok( $formerly->name eq 'VOID_Formerly Named', "Got Correct name for result object");
		
		## Create the expected children sub objects?
		ok( $crap->can('cds'), "Has cds relationship");
		ok( $girl->can('cds'), "Has cds relationship");
		ok( $damn->can('cds'), "Has cds relationship");
		ok( $formerly->can('cds'), "Has cds relationship");
		
		ok( $crap->cds->count == 0, "got Expected Number of Cds");
		ok( $girl->cds->count == 2, "got Expected Number of Cds");	
		ok( $damn->cds->count == 3, "got Expected Number of Cds");
		ok( $formerly->cds->count == 1, "got Expected Number of Cds");

		## Did the cds get expected information?
		
		my ($cd1, $cd2) = $girl->cds->search({},{order_by=>'year ASC'});

		ok($cd1, "Got a got CD");
		ok($cd2, "Got a got CD");
		
		SKIP:{
		
			skip "Can't Test CD because we failed to create it", 1 unless $cd1;
			ok( $cd1->title eq "VOID_My First CD", "Got Expected CD Title");
		}
		
		SKIP:{
		
			skip "Can't Test CD because we failed to create it", 1 unless $cd2;
			ok( $cd2->title eq "VOID_Yet More Tweeny-Pop crap", "Got Expected CD Title");
		}
	}

}

__END__
## ----------------------------------------------------------------------------
## Error cases
## ----------------------------------------------------------------------------

SHOULD_CAUSE_ERRORS: {

	## bad or missing PKs
	## changing columns
	## basically errors for non well formed data
	## check for the first incomplete problem
}






