# maxwellholder.com

This is deployed at [maxwellholder.com](http://maxwellholder.com).

Run `bin/server` to serve site locally for preview. It will live-reload any
changes made in `source/`.

Run `bin/build` to build static pages from `source/` files.

Run `bin/deploy` to deploy. This assumes you have `maxwellholder` set up in your
SSH config to point to a server that will serve
`/var/www/maxwellholder.com/current`. This also does not deploy anything for the
`/vocal_tract_length` page, which must be deployed separately as it is not a
static page.
