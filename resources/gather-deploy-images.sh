#!/bin/bash
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
# gather-deploy-images
source $SCRIPTDIR/common.sh

# Top level parameters 

function get-images-per-env() {
	echo "Running $TASK_NAME:get-images-per-env"
	#!/bin/bash
	set -euo pipefail
	
	IMAGE_PATH='.spec.template.spec.containers[0].image'
	IMAGES_FILE=$HOMEDIR/all-images.txt
	component_name=$(yq .metadata.name application.yaml)
	
	for env in development stage prod; do
	  yaml_path=components/${component_name}/overlays/${env}/deployment-patch.yaml
	  image=$(yq "$IMAGE_PATH" "$yaml_path")
	
	  if [ -n "$TARGET_BRANCH" ]; then
	    prev_image=$(git show "origin/$TARGET_BRANCH:$yaml_path" | yq "$IMAGE_PATH")
	    if [ "$prev_image" = "$image" ]; then
	      # don't check images that didn't change between the current revision and the target branch
	      continue
	    fi
	  fi

	  # Workaround for RHTAPBUGS-1284
	  if [[ "$image" =~ "quay.io/redhat-appstudio/dance-bootstrap-app" ]]; then
	    # Don't check the dance-bootstrap-app image
	    continue
	  fi
	
	  printf "%s\n" "$image"
	done | sort -u > "$IMAGES_FILE"
	
	if [ ! -s "$IMAGES_FILE" ]; then
	  echo "No images to verify"
	  touch $RESULTS/IMAGES_TO_VERIFY
	  exit 0
	fi
	
	# TODO: each component needs a {"source": {"git": {"url": "...", "revision": "..."}}}
	#       will that be too large for Tekton results?
	
	jq --compact-output --raw-input --slurp < "$IMAGES_FILE" '
	  # split input file
	  split("\n") |
	  # drop empty lines
	  map(select(length > 0)) |
	  # convert into EC-compatible format
	  {
	    "components": map({"containerImage": .})
	  }
	' | tee $RESULTS/IMAGES_TO_VERIFY

	cat $RESULTS/IMAGES_TO_VERIFY | jq
	
}

# Task Steps 
get-images-per-env
