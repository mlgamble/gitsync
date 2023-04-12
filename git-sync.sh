#!/bin/bash
set -ue

GIT_ROOT="`git rev-parse --show-toplevel`"
cd "$GIT_ROOT"

SYNC_ID="$RANDOM"
SYNC_FILES="/tmp/git-sync-$SYNC_ID"
mkdir -p "$SYNC_FILES"
POST_SYNC_SCRIPT_SCRIPT="$SYNC_FILES/post-sync.sh"
echo 'set -x' > "$POST_SYNC_SCRIPT_SCRIPT"
chmod +x "$POST_SYNC_SCRIPT_SCRIPT"

find . -type f -name '.gitsync' | awk -F/ '{print NF, $0}' | sort -nr | cut -f2 -d' ' | \
while read conf ; do
    (
        echo "INFO - Reading ${conf}"
        source "$conf"

        LOCAL_FILES="$(cd "`pwd`/${conf%.gitsync}" && pwd)"

        CHECKOUT_PATH="$RANDOM"
        mkdir -p "${SYNC_FILES}/${CHECKOUT_PATH}"
        
        echo "INFO - Cloning ${REMOTE} - ${BRANCH}" >&2
        git clone "${REMOTE}" --branch "${BRANCH}" --depth 1 "${SYNC_FILES}/${CHECKOUT_PATH}"
        REMOTE_FILES="$(cd "${SYNC_FILES}/${CHECKOUT_PATH}/${REMOTE_PATH:-.}" && pwd)"

        cd "$LOCAL_FILES"
        echo "INFO - Applying filters to remote repo"
        find "${REMOTE_FILES}" -type f -name '.rsync-filter' -delete
        rsync -vvR $(find . -type f -name '.rsync-filter' | tr '\n' ' ') "${REMOTE_FILES}"

        echo "INFO - Syncing files"
        # Some files may not exist in the remote files. Need to always filter these
        # Exclude any .git / .gitsync files
        STATIC_FILTERS="--exclude .git --exclude .gitsync"
        # Find all nested .gitsync files and exclude their entire directory
        STATIC_FILTERS="${STATIC_FILTERS} $(find . -mindepth 2 -type f -name '.gitsync' | sed 's|^\./||' | sed 's/.gitsync//g' | awk '{printf "--exclude \""$0"\" "}')"
        cd "${REMOTE_FILES}"
        eval rsync -vva $STATIC_FILTERS -FF --delete-after "." "${LOCAL_FILES}" "$@"


        if [ -n "${POST_SYNC_SCRIPT:-}" ]; then
            echo "pushd '$LOCAL_FILES'" >> "$POST_SYNC_SCRIPT_SCRIPT"
            echo "$POST_SYNC_SCRIPT" >> "$POST_SYNC_SCRIPT_SCRIPT"
            echo "popd"
        fi
    )
done

"$POST_SYNC_SCRIPT_SCRIPT"

rm -rf "${SYNC_FILES:-NOTFOUND}"
