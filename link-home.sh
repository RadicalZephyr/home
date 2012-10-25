#!/bin/bash

pushd ~

FILES=$(ls -la .home/ | grep -v '^d' | cut -d '.' -f 2 | tail -n +2 | sed -r 's/(.*)/.\1/g')

for FILE in $FILES
do
    mv $FILE .home/$FILE
    ln -s .home/$FILE $FILE
done

popd
