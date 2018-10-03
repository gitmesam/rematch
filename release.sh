#!/bin/sh

REMOTE="origin"
BRANCH="master"
#TODO: remove next line
BRANCH="nirizr/zestreleaser"

echo "Performing pre-release checks"
branch_name="$(git rev-parse --abbrev-ref HEAD)" || branch_name="(unnamed branch)" ;
if [ "$branch_name" != "$BRANCH" ] ; then
    echo "Branch name is '$branch_name but $BRANCH is expected" ;
    exit -1 ;
fi ;

if [ "$(git status -uno | grep "nothing to commit" | wc -l)" -eq "0" ] ; then
    echo "local branch is dirty, can only release in clean workspaces"
    exit -2 ;
fi ;

if [ "$(git rev-parse $BRANCH)" != "$(git ls-remote $REMOTE -h refs/heads/$BRANCH | cut -f 1 )" ] ; then
    echo "local and remote branches are out of sync, releases are only possible on up-to-date branch"
    exit -3 ;
fi ;


echo "Building the IDAPLUGIN package"
REMATCH_SETUP_PACKAGE=idaplugin ./setup.py sdist --dist-dir=./dist/idaplugin --formats=zip,gztar bdist_wheel --dist-dir=./dist/idaplugin

echo "Building the SERVER package"
REMATCH_SETUP_PACKAGE=server ./setup.py sdist --dist-dir=./dist/server --formats=zip,gztar bdist_wheel --dist-dir=./dist/server


echo "Generating changelog"
latest_tag=$(git describe --tags $(git rev-list --tags --max-count=1) 2>/dev/null ) ;

changelog="**Changes for version $new_version ($changes changes):**\n" ;
if [ "$latest_tag" == "" ]; then
    changelog+="First release"
else
    changelog+=$(git log "$latest_tag..HEAD" --oneline --no-merges) ;
fi ;

echo "Commiting changelog and creating release tag"

echo $changelog >> CHANGELOG.rst

git commit -am "Release $release_version"
git tag "release_$release_version" -m "$release_annotation"
git push origin "release_$release_version"


# git-release "$(REPO)" "$(new_version)" "$(branch_name)" "$(changelog)" 'dist/*/*'
