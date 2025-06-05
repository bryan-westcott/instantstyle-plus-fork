#!/bin/bash

# create symlinks with better structure and replace all "from src" 

set -euo pipefail

# === CONFIG ===

project="instantstyle_plus"
src_dir="src"
dest_root="src_fixed/${project?}"

echo "Building symlinked package under: ${dest_root?}"
mkdir -p "${dest_root?}"


# === SYM LINKING ===

find "${src_dir?}" -type f -name '*.py' | while read -r file; do
    # Note: we will map anything in <projectroot> or src_dir to dest_root
    relpath="${file#"${src_dir?}"/}"  # strip 'src/' prefix, if exists
    dest="${dest_root?}/${relpath?}"
    
    # create directories and parents in dest_root with same structure
    mkdir -p "$(dirname ${dest})"

    # compute relative symlink target
    symlink_target=$(realpath --relative-to="$(dirname "$dest")" "$file")

    ln -sf "${symlink_target?}" "${dest?}"
done


# === ADD INIT IN EACH DIR ===

find ${dest_root?} -type d -exec touch {}/__init__.py \;


# === REWRITING IMPORTS IN *ORIGINAL* FILES ===

echo "Rewriting 'from src.' -> 'from ${project?}.' in source files..."
find "${src_dir?}" -type f -name '*.py' | while read -r file; do
    # in-place, safe sed: modify import
    sed -i \
        -e "s|\bfrom src\\.|from ${project}.|g" \
        -e "s|\bimport src\\.|import ${project}.|g" \
        "${file?}"
done

echo "Symlinks created and imports rewritten to use '${project?}' namespace."
