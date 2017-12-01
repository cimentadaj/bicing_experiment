#! /bin/bash

cd /Users/cimentadaj/Downloads/gitrepo/bicing_experiment

/usr/local/bin/RScript /Users/cimentadaj/Downloads/gitrepo/bicing_experiment/scrape_bicing.R

git add .
git commit -m "Automatic commit for bicing"

git remote set-url origin https://github.com/cimentadaj/bicing_experiment.git

git push origin master