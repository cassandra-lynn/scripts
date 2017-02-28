#!/usr/bin/bash
# download the floor plans of all of the bay state brownstones at BU

html=$(wget -qO - "$1")
base_url=$(cut -d "/" -f 1-3 <<< "$1")

output_dir="Bay State Dorms"

mkdir -p "$output_dir"

grep -oE "housing/residences/[a-zA-Z-]+/baystate/[0-9-]+" <<< "$html" | while read url; do
	dorm_html=$(wget -qO - "$base_url/$url")
	dorm_name=$(echo "$url" | grep -oE "baystate/[0-9-]+" | sed "s:baystate/::g")
	grep -oE "housing/files/[0-9a-zA-Z/_-]+\.png|housing/files/[0-9a-zA-Z/_-]+\.jpg" <<< "$dorm_html" | while read pic_url; do
        mkdir -p "$output_dir/$dorm_name"
        name=$(echo "$pic_url" | grep -oE "files/[0-9a-zA-Z/_-]+\.png|files/[0-9a-zA-Z/_-]+\.jpg" | sed "s:files/::g" | sed "s:/:-:g")
        wget -qO "$output_dir/$dorm_name/$name" "$base_url/$pic_url"
	done
done

for dir in $(ls "$output_dir"); do
    rm "$output_dir/$dir/"signature.png
    for f in $(ls "$output_dir/$dir/" | grep -E "[0-9]+x[0-9]+"); do
        rm "$output_dir/$dir/$f"
    done
    f=""
    for f in $(ls "$output_dir/$dir/" | grep "spotlight"); do
        rm "$output_dir/$dir/$f"
    done
done
