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


if [ -d $stack_dir/pipelines ]
then
    echo "pipelines:" >> $index_file
    for pipeline_dir in $stack_dir/pipelines/*/
    do
        if [ -d $pipelines_dir ]
        then
            pipeline_id=$(basename $pipeline_dir)
            pipeline_archive=$repo_name.$stack_id.pipeline.$pipeline_id.tar.gz

            if [ $build = true ]
            then
                pipeline_build=$assets_dir/pipeline_temp
                mkdir -p $pipeline_build
                
                pipeline_manifest=$pipeline_build/manifest.yaml
                echo "contents:" > $pipeline_manifest
                
                cp -r $pipeline_dir/* $pipeline_build
                
                for pipeline in "$pipeline_build"/*
                do
                    if [ -f $pipeline ] && [ "$(basename -- $pipeline)" != "manifest.yaml" ]
                    then
                        sha256=$(cat $pipeline | $sha256cmd | awk '{print $1}')
                        filename=$(basename -- $pipeline) 
                        echo "- file: $filename" >> $pipeline_manifest
                        echo "  sha256: $sha256" >> $pipeline_manifest
                    fi
                done
                # build template archives
                tar -czf $assets_dir/$pipeline_archive -C $pipeline_build .
                echo -e "--- Created pipeline archive: $pipeline_archive"
                rm -fr $pipeline_build
            fi

            echo "- id: $pipeline_id" >> $index_file
            echo "  url: $release_url/$release_name/$pipeline_archive" >> $index_file
            if [ -f $assets_dir/$pipeline_archive ]
            then
                sha256=$(cat $assets_dir/$pipeline_archive | $sha256cmd | awk '{print $1}')
            fi
            echo "  sha256: $sha256" >> $index_file

            #if [ $i -eq 0 ]
            #then
            #    echo "- $release_url/$release_name/$pipeline_archive" >> $index_file_temp
            #    echo "- file://$assets_dir/$pipeline_archive" >> $index_file_test_temp
            #    ((i+=1))
            #fi
        fi
    done
fi
if [ -d $stack_dir/dashboards ]
then
    echo "dashboards:" >> $index_file
    for dashboard_dir in $stack_dir/dashboards/*/
    do
        if [ -d $dashboards_dir ]
        then
            dashboard_id=$(basename $dashboard_dir)
            dashboard_archive=$repo_name.$stack_id.dashboard.$dashboard_id.tar.gz

            if [ $build = true ]
            then
                dashboard_build=$assets_dir/dashboard_build
                mkdir -p $dashboard_build
                
                dashboard_manifest=$dashboard_build/manifest.yaml
                echo "contents:" > $dashboard_manifest
                
                cp -r $dashboard_dir $dashboard_build
                
                for dashboard in "$dashboard_build"/*
                do
                    if [ -f $dashboard ] && [ "$(basename -- $dashboard)" != "manifest.yaml" ]
                    then
                        sha256=$(cat $dashboard | $sha256cmd | | awk '{print $1}')
                        filename=$(basename -- $dashboard) 
                        echo "- file: $filename" >> $dashboard_manifest
                        echo "  sha256: $sha256" >> $dashboard_manifest
                    fi
                done
                # build template archives
                tar -czf $assets_dir/$dashboard_archive -C $dashboard_build .
                echo -e "--- Created dashboard archive: $dashboard_archive"
                rm -fr $dashboard_build
            fi

            echo "- id: $dashboard_id" >> $index_file
            echo "  url: $release_url/$release_name/$dashboard_archive" >> $index_file
            if [ -f $assets_dir/$dashboard_archive ]
            then
                sha256=$(cat $assets_dir/$dashboard_archive | $sha256cmd | | awk '{print $1}')
            fi
            echo "  sha256: $sha256" >> $index_file

            #if [ $i -eq 0 ]
            #then
            #    echo "- $release_url/$release_name/$dashboard_archive" >> $index_file_temp
            #    echo "- file://$assets_dir/$dashboard_archive" >> $index_file_test_temp
            #    ((i+=1))
            #fi
        fi
    done
fi
