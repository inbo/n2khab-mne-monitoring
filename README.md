## About this repository

This repo aims at providing operational components of the Monitoring programme for the Natural Environment (MNE) in Flanders.
These can be e.g.:

- source code to generate and update detailed planning based on field activity calendar objects coming either from the n2khab-mne-design [^private] repository or regenerated here (once code has become more portable);
- data unique to this repository, needed to drive field work or coming from the field;
- (source code of) tools to plan, organize and automate data flows in the field and the office;
- data validation scripts and output;
- source code for simple data reporting. 
Whether more elaborate analyses and reporting of the environmental data should be part of this repository, is yet to be seen;
- source code of (markdown) reports, websites and other authored documents associated with above topics.

Some parts of this repo, such as public-facing reporting, may be in Dutch because of the primarily Flemish audience.
At least variables, functions, scripts and code chunks are in English in order to ease internationalization.

[^private]: The n2khab-mne-design repo is a non-public repo used for development and testing.
Only its 'main' (internally accepted) branch is public, through the mirrored [n2khab-mne-design1](https://github.com/inbo/n2khab-mne-design1) repo.

## Repository structure

Explanation of main directory structure:

- _to be updated as needed_
- 

Further, note that general binary/large data sources, either raw data sources or data sources produced by code in the
[n2khab-preprocessing](https://github.com/inbo/n2khab-inputs) repo, should be organised according to data management conventions for N2KHAB projects.
I.e., these N2KHAB data sources must be stored in a (git-ignored) folder `n2khab_data` (with subfolders `10_raw` and `20_processed`).
This folder may also sit outside git repositories, in order to serve multiple projects.
The [n2khab](https://github.com/inbo/n2khab) package provides functions to read these data sources and return them in a standardized way in R.
See `vignette("v020_datastorage", package = "n2khab")` for more information.

Further the [n2khabmon](https://github.com/inbo/n2khabmon) package provides additional functions and resources aimed at N2KHAB monitoring.

For more information on the relation with associated repositories, have a look at the README of repo [n2khab-monitoring](https://github.com/inbo/n2khab-monitoring).


## How to contribute to this repository?

1. Decide to which branch (c.q. pull request) you want to contribute (**reference branch**).
1. In your local repo, make your own new branch after having checked out the reference branch. In this way, the new branch is derived from the reference branch.
    - _Alternatively_, make your changes on the remote repo (at github.com), starting from the reference branch, and commit your changes as a new pull request. This workflow avoids the need of 1) having git installed locally and 2) managing your local repo. However, the possibilities of working with git are more limited.
1. Make the commits that you want to make, **in your branch**.
1. Push your local brach to the remote repo (github.com).
1. In the remote repo, start a pull request for this branch (+ request review, add clarification etc.). _Make sure to correctly set the reference branch for this pull request!_
1. When approved, your branch will be merged with the reference branch in the remote repo (at github.com).
1. Pull the reference branch and clean up your local repo in order to keep up with the remote.

More info on git workflows at INBO: <https://tutorials.inbo.be/tags/git/>


## General information on the MNE

The Flemish monitoring programme for the natural environment (MNE) will fulfill obligations of the Flemish Decree on the conservation of nature and the natural environment.
No long-term monitoring programme yet existed with this focus.
The programme focuses on Natura 2000 habitat types and optionally, the Regionally Important Biotopes.
As environmental pressures severely hinder the achievement of a favourable conservation status for most of these habitat types, monitoring of their environmental characteristics is imperative to guide Flemish nature policy.

MNE aims at drawing conclusions on both state and trend of environmental characteristics of (groups of) habitat types at a regional level.
The programme will allow to prioritize, underpin and evaluate environment-oriented nature policy measures at the Flemish scale by generating representative long-term data of known quality.
Hence, its primary function is to provide quantitative diagnostics of relevant environmental issues.
In addition, the monitoring results will aid in assessing the environmental subcriteria of the conservation status of habitats and provide reliable information for the monitoring reports for the European Commission (Habitats Directive article 17).
To this end, each environmental compartment (groundwater, surface water, inundation water, atmosphere and soil) will be served by a specific MNE monitoring subprogramme aligned with the six-year cycles of the Natura 2000 policy.

MNE will provide solid conclusions for (groups of) habitat types at the Flemish scale, but will be based on a selection of sites in space and time.
Therefore, a statistical approach is needed to achieve the desired (or acceptable) level of precision, significance and power.


