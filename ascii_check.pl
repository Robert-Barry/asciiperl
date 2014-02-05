#!/usr/bin/perl

use CGI;

$query = CGI->new;

print $query->header;

@names = $query->param;
foreach (@names) {
	print $_."<br>";
}

print $query->param('art');
print $query->param('recaptcha_challenge_field');