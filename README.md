# Unity Orb

[![CircleCI Build Status](https://circleci.com/gh/game-ci/unity-orb.svg?style=shield "CircleCI Build Status")](https://circleci.com/gh/game-ci/unity-orb) [![CircleCI Orb Version](https://badges.circleci.com/orbs/game-ci/unity.svg)](https://circleci.com/orbs/registry/orb/game-ci/unity) [![GitHub License](https://img.shields.io/badge/license-MIT-lightgrey.svg)](https://raw.githubusercontent.com/game-ci/unity-orb/main/LICENSE) [![CircleCI Community](https://img.shields.io/badge/community-CircleCI%20Discuss-343434.svg)](https://discuss.circleci.com/c/ecosystem/orbs)

Easily build and test your Unity project.

---

## Resources

[CircleCI Orb Registry Page](https://circleci.com/orbs/registry/orb/game-ci/unity) - The official registry page of this orb for all versions, executors, commands, and jobs described.

[CircleCI Orb Docs](https://circleci.com/docs/orbs/use/orb-intro/) - Docs for using, creating, and publishing CircleCI Orbs.

### How to Contribute

We welcome [issues](https://github.com/game-ci/unity-orb/issues) and [pull requests](https://github.com/game-ci/unity-orb/pulls) against this repository! For detailed guidelines, see [CONTRIBUTING.md](./CONTRIBUTING.md).

### How to Publish An Update (for maintainers)

1. Merge pull requests with desired changes to the main branch.
    - For the best experience, squash-and-merge and use [Conventional Commit Messages](https://conventionalcommits.org/).
2. Find the current version of the orb.
    - You can run `circleci orb get game-ci/unity --json --jq .latest_version` to see the current version.
3. Create a [new Release](https://github.com/game-ci/unity-orb/releases/new) on GitHub.
    - Click "Choose a tag" and _create_ a new [semantically versioned](http://semver.org/) tag. (ex: v1.0.0)
      - We will have an opportunity to change this before we publish if needed after the next step.
4.  Click _"+ Auto-generate release notes"_.
    - This will create a summary of all of the merged pull requests since the previous release.
    - If you have used _[Conventional Commit Messages](https://conventionalcommits.org/)_ it will be easy to determine what types of changes were made, allowing you to ensure the correct version tag is being published.
5. Now ensure the version tag selected is semantically accurate based on the changes included.
6. Click _"Publish Release"_.
    - This will push a new tag and trigger your publishing pipeline on CircleCI.

### Publish a private copy (manual)

Official releases of `game-ci/unity` go through the GitHub Release flow above. The steps below publish a **private copy** of this orb under your own CircleCI namespace, for example to try a branch or a pull request in your own pipelines. They are adapted from CircleCI's [manual orb authoring process](https://circleci.com/docs/orbs/author/manual-orb-authoring-process/#publish-your-orb).

The commands are written for CircleCI CLI v1 (check with `circleci version`). The older 0.1.x CLI, and parts of CircleCI's docs, use `--org-id`, a positional `patch`, `orb info` and an interactive `circleci setup` instead.

```bash
# Define variables
REPO_URL="https://github.com/game-ci/unity-orb.git" # Change to your fork if needed
BRANCH_NAME="main" # Use the branch you want to test, e.g. a pull request's branch
NAMESPACE="your-username" # Your CircleCI namespace; each organization can own only one
ORG="gh/your-username" # Your organization: a slug like gh/<name>, or the ID from Organization Settings > Overview
ORB_NAME="unity-orb-private" # Private orbs can't become public, so `-private` keeps <namespace>/unity-orb free for later

# You should not have to change these variables
SRC_DIR="src"
OUTPUT_FILE="unity-orb.yml"
DEV_VERSION="dev:first"
RELEASE_TYPE="patch"

# Clone the repository (skip this if you are already in a checkout)
git clone "$REPO_URL" unity-orb
cd unity-orb
git checkout "$BRANCH_NAME"

# Authenticate with CircleCI (or export CIRCLE_TOKEN with a token from https://app.circleci.com/settings/user/tokens)
circleci auth login

# One-time steps: skip them if your organization already has a namespace or the orb already exists
circleci namespace create "$NAMESPACE" --org "$ORG"
circleci orb create "$NAMESPACE/$ORB_NAME" --private

# Pack and validate the orb, publish it to a development version, then promote it to a stable release.
# Each step runs only if the previous one succeeded.
circleci orb pack "$SRC_DIR" > "$OUTPUT_FILE" &&
  circleci orb validate "$OUTPUT_FILE" &&
  circleci orb publish "$OUTPUT_FILE" "$NAMESPACE/$ORB_NAME@$DEV_VERSION" &&
  circleci orb publish promote "$NAMESPACE/$ORB_NAME@$DEV_VERSION" --bump "$RELEASE_TYPE" &&
  echo "Orb published successfully."

# Show the orb and its latest version
circleci orb get "$NAMESPACE/$ORB_NAME"
```

Then reference it from a pipeline in the same organization (private orbs are only visible there), using the version the promotion printed, for example:

```yaml
orbs:
  unity: your-username/unity-orb-private@0.0.1
```
