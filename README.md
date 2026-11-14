# Unity Orb

[![CircleCI Build Status](https://circleci.com/gh/game-ci/unity-orb.svg?style=shield "CircleCI Build Status")](https://circleci.com/gh/game-ci/unity-orb) [![CircleCI Orb Version](https://badges.circleci.com/orbs/game-ci/unity.svg)](https://circleci.com/orbs/registry/orb/game-ci/unity) [![GitHub License](https://img.shields.io/badge/license-MIT-lightgrey.svg)](https://raw.githubusercontent.com/game-ci/unity-orb/master/LICENSE) [![CircleCI Community](https://img.shields.io/badge/community-CircleCI%20Discuss-343434.svg)](https://discuss.circleci.com/c/ecosystem/orbs)

Easily build and test your Unity project.

---

## Resources

[CircleCI Orb Registry Page](https://circleci.com/orbs/registry/orb/game-ci/unity) - The official registry page of this orb for all versions, executors, commands, and jobs described.

[CircleCI Orb Docs](https://circleci.com/docs/2.0/orb-intro/#section=configuration) - Docs for using, creating, and publishing CircleCI Orbs.

### How to Contribute

We welcome [issues](https://github.com/game-ci/unity-orb/issues) and [pull requests](https://github.com/game-ci/unity-orb/pulls) against this repository! For detailed guidelines, see [CONTRIBUTING.md](./CONTRIBUTING.md).

### How to Publish An Update (for maintainers)

1. Merge pull requests with desired changes to the main branch.
    - For the best experience, squash-and-merge and use [Conventional Commit Messages](https://conventionalcommits.org/).
2. Find the current version of the orb.
    - You can run `circleci orb info game-ci/unity | grep "Latest"` to see the current version.
3. Create a [new Release](https://github.com/game-ci/unity-orb/releases/new) on GitHub.
    - Click "Choose a tag" and _create_ a new [semantically versioned](http://semver.org/) tag. (ex: v1.0.0)
      - We will have an opportunity to change this before we publish if needed after the next step.
4.  Click _"+ Auto-generate release notes"_.
    - This will create a summary of all of the merged pull requests since the previous release.
    - If you have used _[Conventional Commit Messages](https://conventionalcommits.org/)_ it will be easy to determine what types of changes were made, allowing you to ensure the correct version tag is being published.
5. Now ensure the version tag selected is semantically accurate based on the changes included.
6. Click _"Publish Release"_.
    - This will push a new tag and trigger your publishing pipeline on CircleCI.

### Manual Deploy

If you want a private orb for your build env. The following steps allow you to do so. These are adapted from the CircleCI
[Manual Orb Authoring Process](https://circleci.com/docs/orb-author-validate-publish/#publish-your-orb)

```bash
# Define variables
REPO_URL="git@github.com:game-ci/unity-orb.git" # Change to your fork if needed
BRANCH_NAME="main" # Use desired branch for testing PRs
NAMESPACE="your-username" # Typically your GitHub username; Note: you can only have one namespace per CircleCI org
ORG_ID="00000000-0000-0000-0000-000000000000" # Found in CircleCI Organization Settings > Overview page
ORB_NAME="unity-orb-private" # Private Orbs can't become public, so using `-private` allows your_username/unity-orb to be public later

# You should not have to change these variables
SRC_DIR="src"
OUTPUT_FILE="unity-orb.yml"
DEV_VERSION="dev:first"
RELEASE_TYPE="patch"

# Clone the repository
git clone $REPO_URL unity-orb
cd unity-orb || exit

# Checkout the desired branch
git checkout $BRANCH_NAME

# Authenticate with CircleCI
# You will need a token from https://app.circleci.com/settings/user/tokens to continue
circleci setup

# Create a CircleCI namespace
circleci namespace create $NAMESPACE --org-id $ORG_ID

# Create a private Orb under the namespace
# Note: Error: To create private orbs, your organization must enable the 'Allow private orbs' feature in Org Settings > Security.
circleci orb create $NAMESPACE/$ORB_NAME --private

# Pack and validate the Orb, publish it to a development version, then promote it to a stable release.
# Each step runs only if the previous one succeeded.
circleci orb pack $SRC_DIR > $OUTPUT_FILE &&
  circleci orb validate $OUTPUT_FILE &&
  circleci orb publish $OUTPUT_FILE $NAMESPACE/$ORB_NAME@$DEV_VERSION &&
  circleci orb publish promote $NAMESPACE/$ORB_NAME@$DEV_VERSION $RELEASE_TYPE &&
  echo "Orb published successfully. You can now use it in your CircleCI configuration."

# Retrieve information about the Orb
circleci orb info $NAMESPACE/$ORB_NAME
```
