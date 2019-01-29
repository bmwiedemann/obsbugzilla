#!/bin/sh
# assumes ~/.netrc has credentials
mkdir -p data
exec curl -s -n https://jira.suse.de/rest/api/2/project > data/jiraproject.json
