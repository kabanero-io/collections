#!/bin/bash
set -e

base_dir=$1
stack_dir=$2
stack_version=$3
repo_name=$4
index_file=$5
assets_dir=$base_dir/ci/assets
stack_id=$(basename $stack_dir)
release_url="https://github.com/$TRAVIS_REPO_SLUG/releases/download"
collection=$stack_dir/collection.yaml

if [ -z $ASSET_LIST ]; then
    asset_list="pipelines dashboards deploys"
else 
    asset_list=$ASSET_LIST
fi

process_assets () {
    asset_types=$1
    asset_type="${asset_types%?}"
    
    if [ -d $stack_dir/$asset_types ]
    then
        echo "$asset_types:" >> $index_file
        for asset_dir in $stack_dir/$asset_types/*/
        do
            if [ -d $asset_dir ]
            then
                asset_id=$(basename $asset_dir)
                asset_archive=$repo_name.$stack_id.$asset_type.$asset_id.tar.gz

                if [ $build = true ]
                then
                    asset_build=$assets_dir/asset_temp
                    mkdir -p $asset_build
                
                    asset_manifest=$asset_build/manifest.yaml
                    echo "contents:" > $asset_manifest
                
                    cp -r $asset_dir/* $asset_build
                
                    for asset in "$asset_build"/*
                    do
                        if [ -f $asset ] && [ "$(basename -- $asset)" != "manifest.yaml" ]
                        then
                            sha256=$(cat $asset | $sha256cmd | awk '{print $1}')
                            filename=$(basename -- $asset) 
                            echo "- file: $filename" >> $asset_manifest
                            echo "  sha256: $sha256" >> $asset_manifest
                        fi
                    done
                    # build template archives
                    tar -czf $assets_dir/$asset_archive -C $asset_build .
                    echo -e "--- Created $asset_type archive: $asset_archive"
                    rm -fr $asset_build
                fi

                echo "- id: $asset_id" >> $index_file
                echo "  url: $release_url/$release_name/$asset_archive" >> $index_file
                if [ -f $assets_dir/$asset_archive ]
                then
                    sha256=$(cat $assets_dir/$asset_archive | $sha256cmd | awk '{print $1}')
                fi
                echo "  sha256: $sha256" >> $index_file

                #if [ $i -eq 0 ]
                #then
                #    echo "- $release_url/$release_name/$asset_archive" >> $index_file_temp
                #    echo "- file://$assets_dir/$asset_archive" >> $index_file_test_temp
                #    ((i+=1))
                #fi
            fi
        done
    fi
}

if [[ "$OSTYPE" == "darwin"* ]]; then
    sha256cmd="shasum --algorithm 256"    # Mac OSX
else
    sha256cmd="sha256sum "  # other OSs
fi

if [ -z $BUILD_ALL ]
then
   release_name=$stack_id-v$stack_version
else
   release_name=$BUILD_ALL
fi

if [ -f $collection ]
then
    yq d -i $index_file stacks.[0].maintainers
    yq m -x -i $index_file $collection

    default_imageId=$(yq r $index_file default-image) 
    imagesCount=$(yq r $index_file images | awk '$1 == "-" { count++ } END { print count }')
    count=0
    while [ $count -lt $imagesCount ]
    do
        imageId=$(yq r $index_file images.[$count].id)
        if [ $default_imageId == $imageId ]
        then
            default_image=$(yq r $index_file images.[$count].image)
        fi
        count=$(( $count + 1 ))
    done
    #echo "Default image name is $default_image"

    for template_dir in $stack_dir/templates/*/
    do
        if [ -d $template_dir ]
        then
            template_id=$(basename $template_dir)
            template_archive=$repo_name.$stack_id.templates.$template_id.tar.gz
            template_temp=$assets_dir/tar_temp
            
            mkdir -p $template_temp

            if [ $build = true ]
            then
                # Update template archives
                tar -xzf $assets_dir/$template_archive -C $template_temp
                if [ -f $template_temp/.appsody-config.yaml ]
                then 
                    yq w -i $template_temp/.appsody-config.yaml stack $default_image 
                else
                    echo "stack: $default_image" > $template_temp/.appsody-config.yaml
                fi
                tar -czf $assets_dir/$template_archive -C $template_temp .
                echo -e "--- Updated template archive: $template_archive"
            fi
        
            rm -fr $template_temp
        fi
    done
fi

#process the assets
for asset in $asset_list
do
    process_assets $asset
done