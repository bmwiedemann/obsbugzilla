#!/usr/bin/perl -w
use strict;

use lib ".";
use config;
use common;
use obssupport;


print obssupport::bugjson(obssupport::getbug(1160948));
#print obssupport::bugjson(obssupport::getbug(1161867)); # public bug for comparison
