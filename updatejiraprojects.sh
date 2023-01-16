#!/bin/sh
# fetch the list of known projects from Jira's API
# to know which jsc# values are valid
# assumes ~/.netrc has credentials
j=data/jiraproject.json
mkdir -p data
curl -s -n https://jira.suse.com/rest/api/2/project > $j.new
grep -q '"ENGINFRA"' $j.new && mv $j.new $j
