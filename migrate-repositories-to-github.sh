#!/bin/bash
if [[ ! -f $1 ]]; then echo "$1 file not found"; exit 99; fi
read -p 'Bitbucket Organisation: ' BB_ORG
read -p 'GitHub Username (not email): ' GH_USERNAME
read -sp 'GitHub Password: ' GH_PASSWORD
(cat "$1" ; echo) | tail -n +2 | tr -d '\r' | while IFS=, read -r old_repo gh_org new_repo description archive private
do
  if [ -z "$old_repo" ]; then continue; fi # skip empty lines
  echo

  echo "###### Processing $old_repo -> $gh_org/$new_repo. Cloning from Bitbucket..."
  git clone --mirror git@bitbucket.org:$BB_ORG/$old_repo.git
  cd $old_repo.git
  echo

  echo "=== $old_repo cloned, now creating $gh_org/$new_repo on GitHub with description [$description]..."
  PRIVATE_FLAG="true"
  if [ "$private" = "no" ]; then 
    echo "PUBLIC!"
    PRIVATE_FLAG="false"
  fi
  curl -u $GH_USERNAME:$GH_PASSWORD https://api.github.com/orgs/$gh_org/repos -d "{\"name\": \"$new_repo\", \"private\": $PRIVATE_FLAG, \"description\": \"$description\"}"
  echo

  echo "=== pushing $gh_org/$new_repo to GitHub..."
  git push --mirror git@github.com:$gh_org/$new_repo.git
  echo

  if [ "$archive" = "yes" ]; then
    echo "=== archiving repository $gh_org/$new_repo on GitHub..."
    curl -X PATCH -u $GH_USERNAME:$GH_PASSWORD https://api.github.com/repos/$gh_org/$new_repo -d "{\"archived\": true}"
  fi

  cd ..  
done
