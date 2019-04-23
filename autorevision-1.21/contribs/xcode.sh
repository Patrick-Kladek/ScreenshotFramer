#!/bin/sh

# This script drives autorevision so that you end up with two
# `autorevision.h` files; one for including in the program and one for
# populating values in the `info.plist` file (some of which are user
# visible).
# The cache file is generated in a repo and is read from
# unconditionally when building from a tarball.
# This script is meant to called from within Xcode, some of the
# variables are defined in the environment there.

# Config
export PATH=${PATH}:/sw/bin:/usr/local/bin:/usr/local/git/bin
: "${DERIVED_FILE_DIR:="./der"}"
: "${SRCROOT:="./src"}"
: "${OBJROOT:="./obj"}"

# This header file uses a slightly different format and a customized
# cache suitable for use with an info.plist file.
infoPlistOutput="${DERIVED_FILE_DIR}/autorevision.h"
customCacheOutput="${OBJROOT}/autorevision.tmp"

# This is a header suitable for including is your code.
# The one that actually gets included is only updated when something
# changes to prevent needless rebuilding.
cHeaderOutput="${SRCROOT}/autorevision.h"
cHeaderTempOutput="${OBJROOT}/autorevision.h"

# This is what needs to be in a tarball to make things work.
cacheOutput="${SRCROOT}/autorevision.cache"



# Output the autorevision cache.
if ! autorevision -o "${cacheOutput}" -t sh; then
	exit ${?}
fi

###
# This section does some manipulations to make the output pretty for
# use in the info.plist

# Source the cache to allow for value manipulation.
. "${cacheOutput}"

if [ ! "${VCS_TICK}" = "0" ]; then
	# If we are not exactly on a tag make the branch look better and use the value for the tag too.
	N_VCS_BRANCH="$(echo "${VCS_BRANCH}" | sed -e 's:remotes/:remote/:' -e 's:master:Master:')"
	sed -e "s:${VCS_BRANCH}:${N_VCS_BRANCH}:" -e "s:${VCS_TAG}:${N_VCS_BRANCH}:" "${cacheOutput}" > "${customCacheOutput}"
else
	# When exactly on a tag make the value suitable for users.
	# The following tag prefix formats are recognized and striped:
	# v1.0 | v/1.0 = 1.0
	# The following tag suffix formats are transformed:
	# 1.0_beta6 = 1.0 Beta 6 || 1.0_rc6 = 1.0 RC 6
	N_VCS_TAG="$(echo "${VCS_TAG}" | sed -e 's:^v/::' -e 's:^v::' -e 's:_beta: Beta :' -e 's:_rc: RC :')"
	sed -e "s:${VCS_TAG}:${N_VCS_TAG}:" "${cacheOutput}" > "${customCacheOutput}"
fi

###

# Output for src/autorevision.h.
autorevision -f -o "${cacheOutput}" -t h > "${cHeaderTempOutput}"
if [ ! -f "${cHeaderOutput}" ] || ! cmp -s "${cHeaderTempOutput}" "${cHeaderOutput}"; then
	# Only copy `src/autorevision.h` in if there have been changes.
	cp -a "${cHeaderTempOutput}" "${cHeaderOutput}"
fi

# Output for info.plist prepossessing.
autorevision -f -o "${customCacheOutput}" -t xcode > "${infoPlistOutput}"

exit ${?}
