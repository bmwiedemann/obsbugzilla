#!/bin/sh
# assumes ~/.netrc has credentials
j=data/jiraproject.json
mkdir -p data
curl -s -n https://jira.suse.com/rest/api/2/project > $j.new
grep -q '"ENGINFRA"' $j.new && mv $j.new $j
