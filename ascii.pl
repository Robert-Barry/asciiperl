#!/usr/bin/perl

use warnings;

####################################################################
# ascii.pl
#
# This is a simple web app that allows a user to create a work of
# ascii art and post it to the web page
#
# Author: Robert Barry
# Created: June 1, 2013
# Last changed: December 5, 2013
##################################################################

use CGI;
use HTML::Entities;
use DBI;
use LWP::UserAgent;

# Use the DBI module to access the web site
my $drh = DBI->install_driver("mysql");
my $dsn = "DBI:mysql:database=####;host=####";
my $dbh = DBI->connect($dsn, '####', '####', { RaiseError => 1, AutoCommit => 0 });

# Use the CGI module to access query parameters
$query = CGI->new;

# Retrieve the query parameters using CGI and then
# encode_entities replaces unsafe characters with their entity 
# representation.
my $title = encode_entities( $query->param('title') );
my $art = encode_entities( $query->param('art') );
my $error = "";

# Print the HTTP headers for the page
print $query->header;

# If there is a submit parameter in the query
if ($query->param('submit')) {
	# And if the captcha is successful
	my $ua = LWP::UserAgent->new();
	my $result = $ua->post(
		'http://www.google.com/recaptcha/api/verify',
		{
			privatekey => '####',
			remoteip   => $ENV{'REMOTE_ADDR'},
			challenge  => $query->param('recaptcha_challenge_field'),
			response   => $query->param('recaptcha_response_field'),
		}
	);
	#print $result->is_success, $result->content;
    if ( $result->is_success && $result->content =~ /^true/) {
    		# And if there is a title and art
		if ($title && $art) {
			# SQL to add art and title to the database
			$query = $dbh->prepare("INSERT INTO art (title, art) VALUES(?, ?)");
			$query->execute( $title, $art );
			if ($query->err) {
				$error  = "ERROR: The item was not added.";
			}
			$title = "";
			$art = "";
		} else {
			$error = 'we need both a title and some artwork!';
		}
    } else {
    	$error = 'The Captcha response of the form you submitted did not match the challenge.';
    }
}

my $page = <<ENDHTML;
<!doctype html>
<html lang="en">
	<head>
		<meta charset="utf-8" />
		<title>/asciiperl/</title>
		<link href="ascii.css" rel="stylesheet" type="text/css" />

	</head>
	<body>
		<h1>/asciiperl/</h1>
	
		<form method="post" id="art_work" action="">
			<label>
				<div>title</div>
				<input type="text" id="title" name="title" value="$title">
			</label>
		
			<label>
				<div>art</div>
				<textarea name="art" id="art">$art</textarea>
			</label>
			<div>$error</$div><br />
	    	<br>
	    	<script type="text/javascript" src="http://www.google.com/recaptcha/api/challenge?k=6LeiTukSAAAAABGma_S9XmO4fa-euvRdHdtGGmtP">
  			</script>
	    	<noscript>
     			<iframe src="http://www.google.com/recaptcha/api/noscript?k=6LeiTukSAAAAABGma_S9XmO4fa-euvRdHdtGGmtP"
         height="300" width="500" frameborder="0"></iframe><br>
     			<textarea name="recaptcha_challenge_field" rows="3" cols="40">
     			</textarea>
     			<input type="hidden" name="recaptcha_response_field"
         value="manual_challenge">
  			</noscript><br>
			<input name="submit" type="submit">
		</form>
		<hr><br>
ENDHTML
# Query the database to show all the title and the art
$db_query = $dbh->prepare("SELECT * FROM art ORDER BY created DESC");
$db_query->execute;

# Variable to create the HTML section for the art and titles.
my $middle_page = "";

# While there are rows to fetch in the database
while ( @row =  $db_query->fetchrow_array ) {
	shift @row; # Don't take the key
	$this_title = shift @row; # Take title
	$this_art = shift @row; # Take art
	
	# Create the HTML to show the art
	$middle_page .= "<div class='art'>\n
	    	<div class='art-title'>$this_title</div>\n
	    	<pre class='art-body'>$this_art</pre>\n
			</div>\n\n";
}

# Close the HTML document
$end_page = "</body>\n</html>";			

# Display the page
print ($page, $middle_page, $end_page);


