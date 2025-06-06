#!/bin/bash

# create symlinks with better structure and replace all "from src" 

set -euo pipefail

# === CONFIG ===

project_name="instantstyle_plus"
src_dir="src"
fixed_dir="src_fixed/${project_name?}"

project_root=$(git rev-parse --show-toplevel)
src_root="${project_root?}/${src_dir?}"
dest_root="${project_root?}/${fixed_dir?}"

# === PREP ===

cd "${project_root?}"
echo "-- Building symlinked package under: ${dest_root?} --"
mkdir -p "${dest_root?}"


# === LINK ROOT-LEVEL FILES TO DEST_ROOT ===

echo "-- Creating symlinks for files in project root: ${project_root?} --"
find "${project_root?}" -maxdepth 1 -type f -name '*.py' | while read -r file; do
    filename=$(basename "$file")
    dest="${dest_root?}/$filename"
    symlink_target=$(realpath --relative-to="${dest_root?}" "$file")
    echo "    * linking: ${dest#"${project_root?}"} -> $symlink_target"
    ln -sf "$symlink_target" "$dest"
done

# === SYM LINK IN SRC ALSO, PRESERVING STRUCTURE ===

echo "-- Creating symlinks for tree in ${src_root?} --"
find "${src_root?}" -type f -name '*.py' | while read -r file; do
    # Note: we will map anything in <projectroot> or src_dir to dest_root
    relpath="${file#"${src_root?}"/}"  # strip '*/src/' prefix, if exists
    dest="${dest_root?}/${relpath?}"
    
    # create directories and parents in dest_root with same structure
    mkdir -p "$(dirname "${dest}")"

    # compute relative symlink target
    symlink_target=$(realpath --relative-to="$(dirname "$dest")" "$file")
    echo "    * linking: ${dest#"${project_root?}"} -> $symlink_target"
    ln -sf "${symlink_target?}" "${dest?}"
done


# === ADD INIT IN EACH DIR ===

echo "-- Creating __init__.py in each directory of ${dest_root?} --"
find "${dest_root?}" -type d -exec touch {}/__init__.py \;


# === REWRITING IMPORTS IN *ORIGINAL* FILES ===

echo "-- Rewriting 'from src.' -> 'from ${project_name?}.' in source files --"
find "${dest_root?}" -type l -name '*.py' | while read -r file; do
# only follow links (type l), the __init__.py files are not links
    # in-place, safe sed: modify import
    realfile="$(realpath "$file")"
    echo "    * checking ${realfile#"${project_root?}"} for src. imports"
    sed -i \
        -e "s|\bfrom src\\.|from ${project_name?}.|g" \
        -e "s|\bimport src\\.|import ${project_name?}.|g" \
        "${realfile?}"
done

echo "-- Symlinks created and imports rewritten to use '${project_name?}' namespace --"
