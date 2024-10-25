#!/bin/bash
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# summary
source $SCRIPTDIR/common.sh


function appstudio-summary() {
	echo "Running $TASK_NAME:appstudio-summary"
	#!/usr/bin/env bash
	echo
	echo "Build Summary:"
	echo
	echo "Build repository: $GIT_URL"
	BUILD_TASK_STATUS=$(cat $BASE_RESULTS/buildah-rhtap/STATUS)
	if [ "$BUILD_TASK_STATUS" == "Succeeded" ]; then
	  echo "Generated Image is in : $IMAGE_URL"
	fi
	if [ -e "$SOURCE_BUILD_RESULT_FILE" ]; then
	  url=$(jq -r ".image_url" <"$SOURCE_BUILD_RESULT_FILE")
	  echo "Generated Source Image is in : $url"
	fi
	echo
	echo End Summary

}

# Task Steps
appstudio-summary
tree $BASE_RESULTS
cosign tree $IMAGE_URL
exit_with_success_result