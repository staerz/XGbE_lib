# Wavedrom

Repository to contain wavedrom specific mini scripts, allowing to convert `json` files into `pdf`s (via `svg`s)

The script `json2pdf` uses `wavedrom.js` (created by [Aliaksei Chapyzhenka](https://github.com/wavedrom/wavedrom)) to generate `svg` files from `json` files.
These are then converted to `pdf`s using `rsvg-convert`.

## Table of Contents

* [Contact](#contact)
  + [Issue reporting](#issue-reporting)
* [Requirements](#requirements)
  + [node-js](#node-js)
  + [rsvg-convert](#rsvg-convert)
* [Usage](#usage)
  + [Cleanup](#cleanup)
* [Makefile](#makefile)

## Contact

This repository is maintained by Sam de Jong (<srdejong@uvic.ca>) and Steffen Stärz (<steffen.staerz@cern.ch>).

### Issue reporting
Use the [gitlab issue tracker](/../issues/new) for reporting any bug or other issue.

Make use of the available templates:
- [Bugs](/../issues?label_name[]=Bug)
- [Feature](/../issues?label_name[]=Feature)
- [Documentation](/../issues?label_name[]=Documentation)

## Requirements

These scripts require `nodejs` and `rsvg-convert`.
If these are not on the system, the scripts will copy dummy images (from `dummy.svg` and `dummy.pdf`) for each `json` file, rather than converting.

### node-js

For the conversion from `json` to `svg`, `nodejs` version v12.0.0 or greater is required.
To install this on Ubuntu, see [here](https://computingforgeeks.com/how-to-install-nodejs-on-ubuntu-debian-linux-mint/)

Then use `node -v` to ensure that the correct version is installed.

### rsvg-convert

For the conversion from `svg` to `pdf`, `rsvg-convert` is required.
To install this on Ubuntu, use
```
apt-get install librsvg2-bin
```

## Usage

To convert wavedrom files to `pdfs`, run

```
json2pdf path_to_json_files
```

This will convert all json files located in `path_to_json_files` to `svg` files, then to pdf files.
If `path_to_json_files` is not specified, the current repository's root path is used.

The script uses node to install the wavedrom-cli executable if it not already installed.
It creates a file `package-lock.json` and directory `node_modules` where the wavedrom-cli is installed.
Deleting these will force `json2pdf` to reinstall wavedrom-cli the next time it is run.

### Cleanup

The scipt `cleanupWavedrom` will remove the `svg` and `pdf` files generated by `json2pdf`:

```
cleanupWavedrom path_to_json_files
```
This will remove any `svg` files located in `path_to_json_files`, as long as they are not referenced by `md`-files contained in the same repository as `path_to_json_files`.
If `path_to_json_files` is not specified, the current repository's root path is used.

## Makefile

These scripts can be incorporated into makefiles to automatically generate `pdf` files for inclusion in documentation.
