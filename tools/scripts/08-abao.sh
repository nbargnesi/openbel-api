#!/usr/bin/env bash

# The next three lines are for the go shell.
export SCRIPT_NAME="abao"
export SCRIPT_HELP="Run the abao RAML testing tool."
[[ "$GOGO_GOSH_SOURCE" -eq 1 ]] && return 0

# Normal script execution starts here.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"/../../
. "$DIR"/env.sh || exit 1

"$SCRIPTS"/abao.sh
