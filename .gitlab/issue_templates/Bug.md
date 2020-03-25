<!--
Prerequisites

ANSWER THE FOLLOWING QUESTIONS FOR YOURSELF BEFORE SUBMITTING A BUG REPORT.

- This is a bug (not in the CI nor is it a new feature request).
- I am running the latest version.
- I checked the documentation and found no answer.
- I checked to make sure that this issue has not already been filed.
- I'm reporting the issue to the correct repository.

-->

## Expected Behaviour
<!-- EXPLAIN WHAT YOU WOULD EXPECT TO HAPPEN -->

I expect ...

## Current Behaviour
<!-- EXPLAIN WHAT IS HAPPENING NOW -->

It currently ...

## Context (Environment)
<!-- LIST THE STATE OF OTHER REPOSITORIES. EXTEND OR REMOVE THE LIST ACCORDINGLY. -->

The following projects need to be checked out in this state to reproduce:

LASP modules:

<!-- REPLACE THE MODULE NAME AND PUT THE CORRECT LINK -->
1. [THEMODULE](https://gitlab.cern.ch/atlas-lar-be-firmware/LASP/<COMPLETE HERE THE URL TO THE TAG, COMMIT OR BRANCH>)

<!-- REMOVE MODULES IF THEY ARE NOT CHANGED. -->
Shared modules:

<!-- PUT THE CORRECT LINK -->
1. [env](https://gitlab.cern.ch/atlas-lar-be-firmware/shared/hdl_env/<COMPLETE HERE THE URL TO THE TAG, COMMIT OR BRANCH>)
1. [altera](https://gitlab.cern.ch/atlas-lar-be-firmware/shared/altera/<COMPLETE HERE THE URL TO THE TAG, COMMIT OR BRANCH>)
1. [common](https://gitlab.cern.ch/atlas-lar-be-firmware/shared/common/<COMPLETE HERE THE URL TO THE TAG, COMMIT OR BRANCH>)
1. [PoC](https://gitlab.cern.ch/atlas-lar-be-firmware/shared/PoC/<COMPLETE HERE THE URL TO THE TAG, COMMIT OR BRANCH>)
1. [testbench](https://gitlab.cern.ch/atlas-lar-be-firmware/shared/testbench/<COMPLETE HERE THE URL TO THE TAG, COMMIT OR BRANCH>)

<!-- RUN 'git describe --abbrev=0' IN THE LASP MAIN REPO TO GIVE THE TAG THAT THE LASP PROJECT NEEDS TO BE CHECKED OUT. -->
All other projects are checked out in their version corresponding to tag **LASP-Sargon-vX.X**

<!-- NOTE: IN FUTURE THERE SHOULD JUST BE A TAG THAT YOU CREATE (VIA A SCRIPT) AND PUSH AND LINK HERE -->

## Steps to Reproduce
<!-- EXPLAIN WHAT YOU HAVE TO DO TO TRIGGER THE BUG -->

1) ...
1) ...
1) ...

## Failure Logs
<!-- INCLUDE ANY RELEVANT LOG SNIPPETS HERE. IF APPLICABLE, ATTACH FILES IN THIS SECTION. -->

```bash
terminal output
```

## Possible Cause
<!-- EXPLAIN IF THERE WAS ANY CHANGE YOU THINK TRIGGERED THIS BUG -->

No clue.
<!-- OR -->
It's possibly due to ...

## Possible Solution
<!-- IF APPLICABLE, INDICATE A POSSIBLE SOLUTION -->

Needs to be investigated.
<!-- OR -->
Fixing ... should help.

/label ~Bug
/weight 1
/due in 2 weeks
