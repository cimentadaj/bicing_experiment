#! /bin/bash

ssh-add /Users/cimentadaj/.ssh/cimentadaj-GitHub

cd /Users/cimentadaj/Downloads/gitrepo/bicing_experiment

/usr/local/bin/RScript /Users/cimentadaj/Downloads/gitrepo/bicing_experiment/scrape_bicing.R

git add .
git commit -m "Automatic commit for bicing"

git push origin master