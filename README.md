# Unity Orb

This project has been forked from [game-ci/unity-orb](https://github.com/game-ci/unity-orb) in order to fix the Windows build issue when pulling 
Git private repositories.
This orb is available on the CircleCI Orb Registry at [metatheoryinc/unity-orb](https://circleci.com/developer/orbs/orb/metatheoryinc/unity-orb).

## Updating the Orb

In order to update this orb with latest changes from the original orb, you can use the following steps:
- Download the latest code from [game-ci/unity-orb](https://github.com/game-ci/unity-orb) repository
- Copy the content of the downloaded repository to this repository
- Carefully merge the changes from the following files:
  - `src/scripts/windows/prepare-env.sh`
  - `src/scripts/windows/set-gitcredentials.sh`
  - `src/scripts/windows/return-license.sh`
- Do not remove `set-gitcredentials.sh` files
- Deploy the orb by running the following commands:
```bash
circleci orb pack src > unity-orb.yml
circleci orb validate unity-orb.yml
circleci orb publish unity-orb.yml metatheoryinc/unity-orb@dev:0.0.1 # make sure to update the version number
circleci orb publish promote metatheoryinc/unity-orb@dev:0.0.1 patch --token <CIRCLECI ORB PUBLISH TOKEN>
```
