# maxwellholder.com

This is deployed at [maxwellholder.com](http://maxwellholder.com).

Run `bin/server` to serve site locally for preview. It will live-reload any
changes made in `source/`.

Run `bin/build` to build static pages from `source/` files.


## Deploying

To setup push to deploy, on the server you're deploying to run:

```
git clone https://github.com/mxhold/maxwellholder.com.git
cd maxwellholder.com
git config receive.denyCurrentBranch updateInstead
ln -s ./git_hooks/push-to-checkout ./.git/hooks/push-to-checkout
```

The assumes you have Ruby and Bundler already installed on the server.

Then (on your local machine) add the server as a remote and push:

```
git remote add deploy git@server.com:/path/to/repo
git push deploy
```

