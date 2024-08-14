#!/usr/bin/env bash

# Azure Keyvault Env File Sync

# This script allows keyvault secrets to be synced to local .env files.
# - Enables local development and secret synchronization amongst multiple team members and devices.
# - Keep development secrets centralised in Azure Keyvaults and out of git or floating around other platforms
# - Protect sensitive information with Azures keyvault IAM (local dev secrets should be completely different from other environment keyvaults)

# ## Usage
# ```sh
# ./azure-keyvault-env-file-sync.sh -k keyvault-name
# ```

# Takes an argument -k <keyvaultName> for the name of an Azure Keyvault you want to sync environment variables from
# - If the user is not already logged into azure using 'az login', they will be directed to login via their default browser
# - The logged in user must have permission to list and pull the relevant secrets from the keyvault
# - Each secret in the specified keyvault must have tags named EnvVariableName and EnvFilePath with the appropriate values otherwise it will be ignored
# - The EnvFilePath tag value represents the relative file path from current working directory to the .env file without a leading /. e.g. tmp/test/.env

# ### Keyvault Secret Tags
# Below is an example of two tags that would be added to a keyvault secret
# ```
# EnvVariableName = ENV_VAR_NAME
# EnvFilePath = apps/api/.env
# ```

# ...will result in a file `apps/api/.env` with the contents
# ```env
# ENV_VAR_NAME=<SECRET_VALUE>
# ```

# Multiple comma delimited variable names and file paths can be provided for a single keyvault secret where both names and values will be synced to both files
# ```
# EnvVariableName = ENV_VAR_NAME,ENV_VAR_NAME_ALT
# EnvFilePath = apps/api/.env,apps/app/.env
# ```

# ### File Templates
# File Format templates can be created in the same directory as destination filepaths with `.template` suffix. These template files are safe to track with git if you don't mind having variable names tracked.
# ```
# apps/api/.env
# apps/api/.env.template
# ```

while getopts k: flag; do
  case "${flag}" in
  k) keyvaultName=${OPTARG} ;;
  esac
done

if [ -z $keyvaultName ]; then
  echo "No keyvault name was provided using flag: -k"
  echo "Usage: $0 -k <keyvault-name>" >&2
  continue
fi
echo "Syncing keyvault secrets to .env files from keyvault named: $keyvaultName"

# Device codes can also be used to remove need for human input
az account show || az login
# az login --use-device-code

# Get list of secret ids from key vault.
secrets=$(az keyvault secret list --vault-name $keyvaultName --query "[?tags.EnvVariableName] && [?tags.EnvFilePath] | [].{id: id, name: name, value: value, envVariableName: tags.EnvVariableName, envFilePath: tags.EnvFilePath}" -o tsv)

while read -r secret; do
  # Parse the secret information.
  secretId=$(awk '{print $1}' <<<"$secret")
  secretName=$(awk '{print $2}' <<<"$secret")
  secretValue=$(az keyvault secret show --id $secretId --output tsv --query 'value')
  envVariableName=$(awk '{print $4}' <<<"$secret")
  envFilePath=$(awk '{print $5}' <<<"$secret")

  if [[ -z $envFilePath ]]; then
    echo "$secretName does not have tag EnvFilePath set"
    continue
  fi
  if [[ -z $envVariableName ]]; then
    echo "$secretName does not have tag EnvVariableName set"
    continue
  fi

  export IFS=","
  FILE_PATHS="$envFilePath"
  ENV_VARIABLE_NAMES="$envVariableName"
  for FILE_PATH in $FILE_PATHS; do

    # Check if destination file already exists. If it doesn't then attempt to use a template.
    if [ ! -f "$FILE_PATH" ]; then
      # Check if .env.template exists in the same folder as FILE_PATH
      if [ -f "$(dirname "$FILE_PATH")/.env.template" ]; then
        # Copy .env.template to FILE_PATH
        echo "Destination file $FILE_PATH doesn't already exist, using .env.template file"
        cp "$(dirname "$FILE_PATH")/.env.template" "$FILE_PATH"
      else
        echo "Destination file $FILE_PATH and .env.template doesn't exist. Creating new destintation file from scratch"
      fi
    fi

    for ENV_VARIABLE_NAME in $ENV_VARIABLE_NAMES; do
      echo "Importing $secretName as $ENV_VARIABLE_NAME into file $FILE_PATH ..."
      OLD_LINE_PATTERN="^${ENV_VARIABLE_NAME}="
      NEW_LINE="${ENV_VARIABLE_NAME}=${secretValue}"
      FILE="$FILE_PATH"
      NEW=$(echo "${NEW_LINE}" | sed 's/\//\\\//g')
      touch "${FILE}"
      sed -i '/'"${OLD_LINE_PATTERN}"'/{s/.*/'"${NEW}"'/;h};${x;/./{x;q100};x}' "${FILE}"
      if [[ $? -ne 100 ]] && [[ ${NEW_LINE} != '' ]]; then
        echo "${NEW_LINE}" >>"${FILE}"
      fi
    done
  done

  # Do something with the secret information.
done <<<"$secrets"
