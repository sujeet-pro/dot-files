#!/bin/bash
# ==============================================================================
# AWS Profile Switcher
# ==============================================================================
# This script switches the [default] AWS profile to use credentials and config
# from one of your named profiles (dev, integ, or prod).
#
# It updates two files:
#   1. ~/.aws/config      - Contains region and output format settings
#   2. ~/.aws/credentials - Contains access keys and session tokens
#
# Usage: ./switch-aws-profile.sh [dev|integ|prod]
#
# Example:
#   ./switch-aws-profile.sh prod    # Switch default to use prod credentials
#   ./switch-aws-profile.sh         # Defaults to 'dev' if no argument given
# ==============================================================================

# Exit immediately if any command fails (prevents partial updates)
set -e

# ==============================================================================
# CONFIGURATION
# ==============================================================================

# Get the profile name from command line argument, default to 'dev' if not provided
PROFILE=${1:-dev}

# Path to AWS configuration directory
AWS_DIR="$HOME/.aws"

# ==============================================================================
# INPUT VALIDATION
# ==============================================================================

# Validate that the profile is one of the allowed values: dev, integ, or prod
# The regex ^(dev|integ|prod)$ means:
#   ^ = start of string
#   (dev|integ|prod) = must be exactly one of these three words
#   $ = end of string
if [[ ! "$PROFILE" =~ ^(dev|integ|prod)$ ]]; then
    echo "Invalid profile: $PROFILE"
    echo "Usage: $0 [dev|integ|prod]"
    exit 1
fi

# ==============================================================================
# HELPER FUNCTIONS
# ==============================================================================

# ------------------------------------------------------------------------------
# ini_get: Extract a value from an INI file section
# ------------------------------------------------------------------------------
# Arguments:
#   $1 - File path (e.g., ~/.aws/credentials)
#   $2 - Section name with brackets (e.g., "[dev]" or "[profile dev]")
#   $3 - Key name to find (e.g., "aws_access_key_id")
#
# Returns:
#   The value associated with the key (everything after the '=' sign)
#
# Example:
#   ini_get "$AWS_DIR/credentials" "[dev]" "aws_access_key_id"
#   # Returns: AKIAIOSFODNN7EXAMPLE
#
# How the awk script works:
#   1. When we find a line matching the section name, set found=1
#   2. When we find any other section header (line starting with '['), set found=0
#   3. While found=1, if line starts with our key:
#      - Find position of '=' and extract everything after it (trimming spaces)
#      - Print the remaining value and exit
# ------------------------------------------------------------------------------
ini_get() {
    awk -v section="$2" -v key="$3" '
        # When current line exactly matches the section we want, start capturing
        $0 == section { found=1; next }

        # When we hit a new section (any line starting with [), stop capturing
        /^\[/ { found=0 }

        # If we are in the right section and line starts with our key:
        # - Use index() to find the "=" position (safer than regex for special chars)
        # - Extract substring after "=" and trim leading spaces
        # - Print the value and exit
        found && index($0, key) == 1 {
            pos = index($0, "=")
            if (pos > 0) {
                val = substr($0, pos + 1)
                gsub(/^[ \t]+/, "", val)  # Trim leading whitespace only
                print val
            }
            exit
        }
    ' "$1"
}

# ==============================================================================
# UPDATE CONFIG FILE (~/.aws/config)
# ==============================================================================
# The config file has this structure:
#   [default]
#   region = us-east-1
#   output = json
#
#   [profile dev]
#   region = ap-south-1
#   output = json
#
# We need to:
#   1. Read region and output from [profile <PROFILE>] section
#   2. Update those values in the [default] section
#   3. Update the comment showing which profile is active
# ==============================================================================

if [ -f "$AWS_DIR/config" ]; then
    # Step 1: Extract the region and output values from the source profile
    # Note: In config file, named profiles use "[profile name]" format
    region=$(ini_get "$AWS_DIR/config" "[profile $PROFILE]" "region")
    output=$(ini_get "$AWS_DIR/config" "[profile $PROFILE]" "output")

    # Step 2: Process the config file with awk to update [default] section
    # The awk script processes line by line and:
    #   - Updates comment lines to show the new active profile
    #   - Tracks when we enter/exit the [default] section
    #   - Replaces region and output values only within [default] section
    #   - Passes all other lines through unchanged
    awk -v profile="$PROFILE" -v region="$region" -v output="$output" '
        # Update the "Currently pointing to" comment with new profile name
        /^# Currently pointing to:/ {
            print "# Currently pointing to: " profile
            next  # Skip to next line (dont print original)
        }

        # Update the "Default is aliased to" comment with new profile name
        /^# Default is aliased to:/ {
            print "# Default is aliased to: " profile " (change to integ|prod as needed)"
            next
        }

        # When we see [default], set flag and print the line as-is
        /^\[default\]/ {
            in_default=1
            print
            next
        }

        # When we see any other section header, clear the flag
        /^\[/ { in_default=0 }

        # If inside [default] section and line starts with "region", replace it
        in_default && /^region/ {
            print "region = " region
            next
        }

        # If inside [default] section and line starts with "output", replace it
        in_default && /^output/ {
            print "output = " output
            next
        }

        # For all other lines, print them unchanged
        { print }
    ' "$AWS_DIR/config" > "$AWS_DIR/config.tmp" && mv "$AWS_DIR/config.tmp" "$AWS_DIR/config"
    # Note: We write to a temp file then move it (atomic operation)
    # This prevents corruption if the script is interrupted mid-write
fi

# ==============================================================================
# UPDATE CREDENTIALS FILE (~/.aws/credentials)
# ==============================================================================
# The credentials file has this structure:
#   [default]
#   aws_access_key_id = AKIA...
#   aws_secret_access_key = wJalr...
#   aws_session_token = FwoGZX...
#
#   [dev]
#   aws_access_key_id = AKIA...
#   ...
#
# We need to:
#   1. Read all credential values from [<PROFILE>] section
#   2. Update those values in the [default] section
#   3. Update the comment showing which profile is active
# ==============================================================================

if [ -f "$AWS_DIR/credentials" ]; then
    # Step 1: Extract credentials from the source profile
    # Note: In credentials file, profiles use "[name]" format (no "profile" prefix)
    access_key=$(ini_get "$AWS_DIR/credentials" "[$PROFILE]" "aws_access_key_id")
    secret_key=$(ini_get "$AWS_DIR/credentials" "[$PROFILE]" "aws_secret_access_key")
    session_token=$(ini_get "$AWS_DIR/credentials" "[$PROFILE]" "aws_session_token")

    # Step 2: Process the credentials file with awk to update [default] section
    # Same pattern as config file, but with different keys to replace
    awk -v profile="$PROFILE" \
        -v access_key="$access_key" \
        -v secret_key="$secret_key" \
        -v session_token="$session_token" '
        # Update comment lines
        /^# Currently pointing to:/ {
            print "# Currently pointing to: " profile
            next
        }
        /^# Default is aliased to:/ {
            print "# Default is aliased to: " profile " (change to integ|prod as needed)"
            next
        }

        # Track when we are inside the [default] section
        /^\[default\]/ {
            in_default=1
            print
            next
        }
        /^\[/ { in_default=0 }

        # Replace credential values when inside [default] section
        in_default && /^aws_access_key_id/ {
            print "aws_access_key_id = " access_key
            next
        }
        in_default && /^aws_secret_access_key/ {
            print "aws_secret_access_key = " secret_key
            next
        }
        in_default && /^aws_session_token/ {
            print "aws_session_token = " session_token
            next
        }

        # Pass through all other lines unchanged
        { print }
    ' "$AWS_DIR/credentials" > "$AWS_DIR/credentials.tmp" && mv "$AWS_DIR/credentials.tmp" "$AWS_DIR/credentials"
fi

# ==============================================================================
# SUCCESS MESSAGE
# ==============================================================================
echo "Default AWS profile switched to: $PROFILE"
