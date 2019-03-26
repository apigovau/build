#!/usr/bin/env bash

# Exit immediately if there is an error
set -e

# Cause a pipeline (for example, curl -s http://sipb.mit.edu/ | grep foo) to produce a failure return code if any command errors not just the last command of the pipeline.
set -o pipefail

echo "${CIRCLE_BRANCH}"

# Print shell input lines as they are read.
set -v

# Include build env vars
source "$(dirname "$0")/buildrc"

# get the cloud foundry cli
curl -v -L -o cf-cli_amd64.deb 'https://cli.run.pivotal.io/stable?release=debian64&source=github'
sudo dpkg -i cf-cli_amd64.deb
cf -v

# login to cloud foundry if env vars are present
login() {
  if [[ -z "$CF_ORG" ]]; then
    echo "CF env vars not found, assuming you are already logged in to cf"
    return
  fi

  if [[ "${CIRCLE_BRANCH}" = "staging" ]]; then
    cf api $CF_PROD_API
    cf auth "$CF_USER" "$CF_PASSWORD_PROD"
  elif [[ "${CIRCLE_BRANCH}" = "prod" ]]; then
    cf api $CF_PROD_API
    cf auth "$CF_USER" "$CF_PASSWORD_PROD"
  else
    cf api $CF_STAGING_API
    cf auth "$CF_USER" "$CF_PASSWORD_STAGING"
  fi

  cf target -o $CF_ORG
  cf target -s $CF_SPACE
}

# main script function
#
main() {
  login
  if [[ "${CIRCLE_BRANCH}" = "staging" ]]; then
    cf push "staging-${APPNAME}" -f manifest-staging.yml
  elif [[ "${CIRCLE_BRANCH}" = "prod" ]]; then
    cf push "${APPNAME}" -f manifest-prod.yml
  fi
}

main $@
