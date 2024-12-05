# Purpose
This directory is going to hold the JSON files for SigNoz dashboards that we are running
in our instance. As of 12/4/2024 there is no known way to automatically ingest or
migrate dashboards between instances or environments.


## Migration/Creation strategy
As changes are made to the various dashboards that we use we should do the following:

1. Make the changes to the dashboard in an environment that has data such as dev or staging
2. Have another engineer review the dashboard reviewing any functionality you've changed or added
3. Export the dashboard as JSON and either create a new `.json` file in this directory, or update the existing file
4. Commit the changes to source control and create a pull request with the changes following our standard flow
5. Have an engineer with access to all SigNoz environments copy the changes to each environment

