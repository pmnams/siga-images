#!/bin/sh

set -e

mkdir -p $SIGA_DIR/tmp

check_deploy() {
    file_name="$(basename $1)"
    file_hash=$(sha1sum $1 | cut -d ' ' -f 1)
    hash_file="$SIGA_DIR/tmp/${file_name}.hash"

    if [ $file_hash != "$(cat "$hash_file" 2>/dev/null)" ]; then
        echo "$file_hash" >"$hash_file"
        jboss-cli.sh -c --command="deploy --force --unmanaged $1"
    fi
}

for file in $SIGA_DIR/deployments/*.war; do
    echo $file
    [ -f "$file" ] || break
    check_deploy $file
done

if [ ! -z "$DEBUG_MODE" ]; then
    inotifywait \
        --event close_write \
        --event moved_to \
        --format "%w%f" \
        --include '\w*\.war$' \
        --monitor \
        $SIGA_DIR/deployments 2>/dev/null |
        while read file; do
            echo $file 
            check_deploy $file
        done
fi