---
title: Build a Blog with Phoenix and Ember.js
date: 2015-06-04 12:24 UTC
tags:
---

## Moving beyond Rails

A lot of new frameworks have emerged in the last couple of years aimed at making web applications easier to build.

[Ruby on Rails](http://rubyonrails.org/) emerged in 2005 and has grown incredibly popular as an all-inclusive framework for making web applications.

Rails offered a massive boost in productivity by focusing on convention over configuration with sane defaults.

Since then, a countless number of JavaScript frameworks and libraries have been released, leading to a shared experience by many web developers of [*JavaScript Framework Fatigue*](http://brewhouse.io/blog/2015/05/13/emberjs-an-antidote-to-your-hype-fatigue.html).

Rails continues to be a useful tool for making web apps, but falls short of offering the level of interactivity that others have sought from Single Page Application frameworks like [Ember.js](http://emberjs.com).

Using Rails as the backend API for a Ember.js app is certainly a viable option, but [Phoenix](http://phoenixframework.org) is becoming a more and more worthy competitor every day by offering features like [Channels](http://www.phoenixframework.org/v0.13.1/docs/channels) using WebSockets. Phoenix is not even 1.0 yet, but is already [inspiring](https://www.youtube.com/watch?v=oMlX9i9Icno&t=1h9m) features in Rails.

## The PEEP Stack

More and more applications are sure to be written in the [PEEP stack](https://medium.com/@j_mcnally/the-peep-stack-b7ba5afdd055):

The **Phoenix** framework, written in [**Elixir**](http://elixir-lang.org), can leverage the mature (and fast) Erlang VM to provide fault-tolerant systems while still maintaining the same level of expressiveness (and developer productivity) as a language like Ruby.

**Ember.js** offers stability amidst the ever-changing landscape of JS frontend frameworks. It attempts to establish conventions on the frontend like Rails did before while [happily borrowing](https://github.com/emberjs/ember.js/pull/10501) good ideas from other frameworks, all to make building highly interactive applications much easier.

**PostgreSQL** is an excellent database system and happens to be the most well-supported by [Ecto](https://github.com/elixir-lang/ecto), the Elixir database wrapper used in Phoenix.

## Building a blog app

This blog post will walk you through the steps necessary to create a simple blog application using Phoenix on the backend with Ember.js on the frontend.

It won't use any of the cool stuff like Phoenix Channels, but it should serve as an example of how to make a very basic <abbr title="Create/Read/Update/Destroy">CRUD</abbr> app.

At the end, you should be able to create, view, edit, and delete blog posts.

If you want to see the final product, both apps are available on GitHub ([Phoenix app](https://github.com/mxhold/peep_blog_backend), [Ember app](https://github.com/mxhold/peep-blog-frontend)) and deployed to Heroku ([Phoenix app](https://peep-blog-backend.herokuapp.com/), [Ember app](https://peep-blog-frontend.herokuapp.com/)).

Here's what we'll cover:

- [Installing everything you need for Elixir/Phoenix/Ember.js](#installing-everything)
- [Building a simple JSON API using Phoenix](#building-a-simple-json-api-using-phoenix)
- [Creating a single-page frontend app using Ember.js](#creating-a-single-page-frontend-app-using-emberjs)
- [Deploying both apps to Heroku](#deploying-to-heroku)

## Installing everything

For this section, the commands I include assume you are running on OS X and have [Homebrew](http://brew.sh/) installed, but I will also include links for other operating systems.

For the deployment section, I'll also assume you have [Git](http://git-scm.org) installed and already have a [Heroku](http://heroku.com) account with the [Heroku Toolbelt](https://toolbelt.heroku.com/) installed.

The version numbers I include below are what they were when I wrote this post. They are likely already a little bit behind if you pull in the latest releases. Everything should still work as long as the versions are not too far off.

### Elixir/Erlang

First, let's install the Elixir programming language along with Erlang.

OS X with Homebrew (others see: the Elixir [install guide](http://elixir-lang.org/install.html)):

~~~bash
brew update && brew install elixir
~~~

Verify it worked:

~~~bash
elixir --version
# should output:
Elixir 1.1.1
~~~

### Phoenix

Now we'll install the Phoenix framework.

First, we need to install [Hex](http://hex.pm), the Erlang package manager:

~~~bash
mix local.hex
~~~

Then, we can install Phoenix:

~~~bash
mix archive.install https://github.com/phoenixframework/phoenix/releases/download/v1.0.3/phoenix_new-1.0.3.ez
~~~

Verify it worked:

~~~bash
mix --help | grep phoenix.new
# should output:
mix phoenix.new         # Create a new Phoenix v1.0.3 application
~~~

### PostgreSQL

For OS X, I suggest using [Postgres.app](http://postgresapp.com).

Other operating systems: see the PostgreSQL [download page](http://www.postgresql.org/download/) or the [detailed installation guides](https://wiki.postgresql.org/wiki/Detailed_installation_guides).

Whichever way you end up installing Postgres, make sure:

  - The `psql` binary is in your `$PATH`

    If you installed Postgres.app, you will need to add the following to your `.bashrc` file or similar:

    ~~~bash
    export PATH="/Applications/Postgres.app/Contents/Versions/9.4/bin:$PATH"
    ~~~

  - You have a `postgres` superuser role without a password or with "postgres" as the password

    If you installed Postgres.app, you can create the role with:

    ~~~sql
    psql -c "CREATE ROLE postgres WITH SUPERUSER LOGIN;"
    ~~~

    A `postgres` role isn't required, but if you choose not to do this, be sure to edit your `config/dev.exs` file once you create your Phoenix app to match whatever credentials you do use.

You can verify this all worked by running:

~~~bash
psql -U postgres -c "select 1+1;"
# should output:
 ?column?
----------
        2
(1 row)

~~~

### Node.js/NPM

Now we need to install Node.js so we can install the Ember CLI tool.

On OS X with Homebrew (other OS see: Node.js [download page](https://nodejs.org/download/)):

~~~bash
brew install node
~~~

Verify it worked:

~~~bash
node --version
# should output:
v0.12.4

npm --version
# should output:
2.10.1
~~~

### Watchman

Ember CLI uses Watchman as a more efficient way to watch for changes on the filesystem.

On OS X:

~~~bash
brew install watchman
~~~

Windows: skip this step because Watchman is not supported on Windows.

Other UNIX-like OS: see Watchman [installation docs](https://facebook.github.io/watchman/docs/install.html).

Verify it worked:

~~~bash
watchman --version
# should output:
3.1.0
~~~

### Ember CLI/Ember.js

Now we'll install the Ember CLI tool:

~~~bash
npm install -g ember-cli
~~~

We'll also install Bower to manage the frontend packages:

~~~bash
npm install -g bower
~~~


Verify all this worked:

~~~bash
ember --version
# should output:
version: 0.2.7
node: 0.12.4
npm: 2.11.0

bower --version
# should output:
1.4.1
~~~

You probably also will want to install the [Ember inspector](https://github.com/emberjs/ember-inspector) for your browser as it is extremely helpful for debugging.

## Project setup

There are many ways to organize separate frontend and backend apps.

Since we're not going to share any code between the two, we'll put them in separate directories as separate git repositories nested under one main project directory:

~~~
peep_blog
├── peep-blog-frontend (Ember.js project)
└── peep_blog_backend (Phoenix project)
~~~

Note: Ember.js apps are conventionally named with dashes whereas Phoenix app names should be in snake case.

So let's start by making the main project directory and generating a new Phoenix app:

~~~bash
mkdir peep_blog
cd peep_blog/
mix phoenix.new peep_blog_backend
# When it prompts "Fetch and install dependencies? [Yn]", hit enter.
~~~

We can verify that worked by moving to the Phoenix project directory and starting up the server:

~~~bash
cd peep_blog_backend/
mix phoenix.server
# should output a bunch of lines like:
Compiled blahblahblah
# ...
# and then finally:
[info] Running PeepBlogBackend.Endpoint with Cowboy on port 4000 (http)
~~~

You should then be able to hit <http://localhost:4000> and see the Phoenix welcome page.

Hit `Ctrl-C` twice to stop the server.

## Building a simple JSON API using Phoenix

Our goal here is to make an API that our Ember app can use to manage blog posts.

It should support the following HTTP calls:

| Method  | Path       | Purpose                  |
|---------|------------|--------------------------|
| POST    | /posts     | create a new post        |
| GET     | /posts     | list all posts           |
| GET     | /posts/:id | show a single post       |
| PUT     | /posts/:id | update a post            |
| DELETE  | /posts/:id | remove a post            |
| OPTIONS | /posts*    | provide headers for CORS |

We can do most of this with Phoenix's [JSON generator](https://github.com/phoenixframework/phoenix/blob/v0.13.1/lib/mix/tasks/phoenix.gen.json.ex) by running:

~~~bash
mix phoenix.gen.json Post posts title:string body:text
~~~

This is very similar to the generators for Rails, except you'll notice that Phoenix does not try to guess the plural form for the table name.

Now we need to update the router for our new resource.

Edit `web/router.ex` and replace the contents with:

~~~elixir
defmodule PeepBlogBackend.Router do
  use PeepBlogBackend.Web, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", PeepBlogBackend do
    pipe_through :api

    resources "/posts", PostController
  end
end
~~~

This adds our new resource and removes the HTML stuff we don't need.
Before we can run the migration to create this new table, we'll need to setup our database:

~~~bash
mix ecto.create
# should output:
The database for PeepBlogBackend.Repo has been created.
~~~

Then we can run the migration to create the `posts` table:

~~~bash
mix ecto.migrate
# should output:
[info] == Running PeepBlogBackend.Repo.Migrations.CreatePost.change/0 forward
[info] create table posts
[info] == Migrated in 0.0s
~~~


Now we should be able to test it!

Start the server with `mix phoenix.server` in another terminal tab and then send a request with [cURL](http://curl.haxx.se/):

~~~bash
curl -H "Content-Type: application/json" http://localhost:4000/posts
# should output:
{"data":[]}

curl -X POST -H "Content-Type: application/json" -d '{ "post": { "title": "Test title", "body": "Lorem ipsum" } }' http://localhost:4000/posts
# should output:
{"data":{"id":1}}

curl -H "Content-Type: application/json" http://localhost:4000/posts/1
# should output:
{"data":{"title":"Test title","id":1,"body":"Lorem ipsum"}}
~~~

Woo!

We now have a backend that should be sufficient to get starting making our Ember.js app.

Keep your Phoenix server running in another terminal tab while we work on the Ember app.

## Creating a single-page frontend app using Ember.js

First, we'll generate new Ember app, install the dependencies and start it up:

~~~bash
cd ../
# we should be in the main peep_blog directory now
ember new peep-blog-frontend
cd peep-blog-frontend/
npm install && bower install
ember server
~~~

With that running, we should be able to hit <http://localhost:4200/> and see "Welcome to Ember.js".

You can press `Ctrl-C` to stop the server, but I suggest keeping it running in another terminal.

Now we need to make the frontend pages to do CRUD actions on our Post resource.

### Index page

We'll start with the `/posts` route.

Ember CLI also has generators to make this easier. Run:

~~~bash
ember generate resource posts title:string body:string
~~~

So we should be able to hit <http://localhost:4200/> without any errors, but it will still just show "Welcome to Ember.js".

To get it to show the example post that we created before, we'll need to setup the route.

Change `app/routes/posts.js` to:

~~~javascript
import Ember from 'ember';

export default Ember.Route.extend({
  model: function() {
    return this.store.find('post');
  }
});
~~~

Now when you visit <http://localhost:4200/posts> you'll get several errors (make sure to have your browser's JavaScript console open when you load the page to see them), the first being:

~~~
GET http://localhost:4200/posts 404 (Not Found)
~~~

This is Ember trying to hit our backend API and failing, which is not too surprising because our Phoenix server is not running on `localhost:4200`, it is at `localhost:4000`!

We need to tell Ember to look at `localhost:4000` for all the API calls.

We can do this by creating a new file at `app/adapters/application.js` with these contents:

~~~javascript
import DS from "ember-data";

export default DS.RESTAdapter.extend({
  host: 'http://localhost:4000'
});
~~~

This configures Ember Data to use the [RESTAdapter](http://guides.emberjs.com/v1.12.0/models/the-rest-adapter/) and to hit our Phoenix server at <http://localhost:4000> for loading all our models.

#### Content Security Policy

Now when we load <http://localhost:4200/posts> we get a different error:

~~~
Refused to connect to 'http://localhost:4000/posts' because it violates the following Content Security Policy directive: "connect-src 'self' ws://localhost:35729 ws://0.0.0.0:35729 http://0.0.0.0:4200/csp-report"
~~~

If you're unfamiliar with what "Content Security Policy" means, the Mozilla Development Network provides [a good overview](https://developer.mozilla.org/en-US/docs/Web/Security/CSP).

Basically, this is because Ember CLI, by default, includes [an addon](https://github.com/rwjblue/ember-cli-content-security-policy) that sets a `Content-Security-Policy-Report-Only` header on responses to the development server.

Your browser sees this header and spits out an error when we try to make a request to any origin other than the server's origin (http://localhost:4200).

Since the header is report only, the request still works but displays this error to remind us that we haven't set everything up correctly.

We need to tell Ember that it is ok to load data from our Phoenix app since it is not from the same origin (same host but different port) as the Ember app.

We can do this by editing `config/environment.js` and changing:

~~~javascript
  if (environment === 'development') {
  }
~~~

to:

~~~javascript
if (environment === 'development') {
  ENV.contentSecurityPolicy = {
    'default-src': "'none'",
    'script-src': "'self'",
    'font-src': "'self'",
    'connect-src': "'self' http://localhost:4000",
    'img-src': "'self'",
    'style-src': "'self'",
    'media-src': "'self'"
  };
}
~~~

Note that this is only relevant to the development environment since we won't be using Ember CLI to serve our app on production.

Once we deploy our app, we'll have to configure our server to set its own CSP header. This addon is just to keep us thinking about CSP so we don't forget to set it up.

We want to have it all set up right so that if someone manages to inject some JS on your site, this prevents their script from being able to connect to some random server.

#### Cross-Origin Resource Sharing

Now when we load <http://localhost:4200/posts> we get yet another error:

~~~
XMLHttpRequest cannot load http://localhost:4000/posts. No 'Access-Control-Allow-Origin' header is present on the requested resource. Origin 'http://localhost:4200' is therefore not allowed access.
~~~

This is again because we're attempting to make calls to a server on a different origin, except now it's a problem with how our Phoenix server is setup.

Again, MDN describes in detail how [Cross-Origin Resource Sharing](https://developer.mozilla.org/en-US/docs/Web/HTTP/Access_control_CORS) works.

Your browser is now willing to make the call to the Phoenix server (since we relaxed the CSP headers above), but when it receives the response, it checks the headers for this `Access-Control-Allow-Origin` header, which we are not sending.

As the name implies, this header lets the server specify which origins should be able to load this resource.

We need to send this header from our Phoenix app. Fortunately, there is a library ([PlugCors](https://github.com/bryanjos/plug_cors)) for doing just that.

Switch to your Phoenix project directory, stop the Phoenix server, and edit your `mix.exs` file to add the dependency:

~~~elixir
defp deps do
  [
    # ...
    {:plug_cors, "~> 0.7.3"},
  ]
end
~~~

Then pull in your dependencies:

~~~bash
mix deps.get
# should output:
Running dependency resolution
Dependency resolution completed successfully
  plug_cors: v0.7.3
* Getting plug_cors (Hex package)
Checking package (https://s3.amazonaws.com/s3.hex.pm/tarballs/plug_cors-0.7.3.tar)
Fetched package
Unpacked package tarball (/Users/max/.hex/packages/plug_cors-0.7.3.tar)
~~~

Now edit `web/router.ex` to change:

~~~elixir
pipeline :api do
  plug :accepts, ["json"]
end
~~~

to:

~~~elixir
pipeline :api do
  plug :accepts, ["json"]
  plug PlugCors, [origins: ["localhost:4200"]]
end
~~~

Now start your Phoenix server back up with `mix phoenix.server` and try to hit <http://localhost:4200/posts> again.

Now we get a cryptic error but a helpful warning before it:

~~~
WARNING: Encountered "data" in payload, but no model was found for model name "datum" (resolved model name using peep-blog-frontend@serializer:-rest:.typeForRoot("data"))
~~~

This is Ember's REST serializer complaining that the root of the JSON we're loading is `data`, so it is trying to find a `datum` model, which doesn't exist.

[The documentation](http://guides.emberjs.com/v1.12.0/models/the-rest-adapter/#toc_json-root) tells us the root needs to be `posts` in this case.

Note: I wouldn't be surprised to see this may change in the future as the [JSON API](http://jsonapi.org/) spec that Ember co-creator Yehuda Katz is co-writing uses `data` as the root element.

We can change this easily enough by editing `web/views/post_view.ex` to change:

~~~elixir
def render("index.json", %{posts: posts}) do
  %{data: render_many(posts, "post.json")}
end

def render("show.json", %{post: post}) do
  %{data: render_one(post, "post.json")}
end
~~~

to:

~~~elixir
def render("index.json", %{posts: posts}) do
  %{posts: render_many(posts, "post.json")}
end

def render("show.json", %{post: post}) do
  %{post: render_one(post, "post.json")}
end
~~~

Now we can try <http://localhost:4200/posts> again.

The page will still just say "Welcome to Ember.js" but we shouldn't have any errors anymore. Yay!

If you have the Ember inspector installed, you should be able to navigate to `Data > post (1)` and see the post we created earlier with all its attributes.

Now we need to change the templates to show this data that we are now loading.

Switch back to your Ember project and edit `app/templates/posts.hbs` to be:

~~~handlebars
<h2>Posts</h2>
<ul>
  {{#each post in model}}
  <li>
    {{post.title}}
  </li>
  {{/each}}
</ul>

{{outlet}}
~~~

Now when we hit <http://localhost:4200/posts> we should see our "Test title" post we created earlier.

We've successfully handled the Post index route!

### Show page

Now let's add a route for the individual posts.

First, we need to edit `app/router.js` from:

~~~javascript
Router.map(function() {
  this.route('posts');
});
~~~

to:

~~~javascript
Router.map(function() {
  this.route('posts', function() {
    this.route('post', { path: '/:post_id' });
  });
});
~~~

Then we need to add a new file at `app/routes/posts/post.js` with the contents:

~~~javascript
import Ember from 'ember';

export default Ember.Route.extend({
  model: function(params) {
    return this.store.find('post', params.post_id);
  }
});
~~~

Then we have to add a new template at `app/templates/posts/post.hbs`:

~~~handlebars
<h2>{{model.title}}</h2>

<article>
  {{model.body}}
</article>

{{outlet}}
~~~

Finally, let's add a link to this new route from the Post index page by editing `app/templates/posts.hbs` to be:

~~~handlebars
<h2>Posts</h2>
<ul>
  {{#each post in model}}
  <li>
    {{#link-to 'posts.post' post}}
      {{post.title}}
    {{/link-to}}
  </li>
  {{/each}}
</ul>

{{outlet}}
~~~

Now you should be able to click on "Test title" and go to <http://localhost:4200/posts/1> and see the body of the post we created before.

## New page

Now we'll make a page where you can create new posts.

Like before, first we'll edit the `app/router.js` file to now contain:

~~~javascript
Router.map(function() {
  this.route('posts', function() {
    this.route('new');
    this.route('post', { path: '/:post_id' });
  });
});
~~~

We need to add a new route at `app/routes/posts/new.js`:

~~~javascript
import Ember from 'ember';

export default Ember.Route.extend({
  model: function() {
    return this.store.createRecord('post');
  },
  actions: {
    save: function() {
      var post = this.currentModel;
      post.save().then(() => {
        this.transitionTo('posts');
      });
    }
  }
});
~~~

Then we'll add a new template at `app/templates/posts/new.hbs`:

~~~handlebars
<h2>New Post</h2>

<p>
  <label for="title">Title</label><br>
  {{input value=model.title id="title"}}
</p>

<p>
  <label for="body">Body</label><br>
  {{textarea value=model.body id="body"}}
</p>

<button {{action 'save'}} id="save">Save</button>
~~~

Finally, we'll add a link to our new page by editing `app/templates/posts.hbs`:

~~~handlebars
{{link-to 'New post' 'posts.new'}}

<h2>Posts</h2>
<ul>
  {{#each post in model}}
  <li>
    {{#link-to 'posts.post' post.id}}
      {{post.title}}
    {{/link-to}}
  </li>
  {{/each}}
</ul>

{{outlet}}
~~~

Now we should be able to click "New post" from our `/posts` page and be taken to a form.

Fill in some values (and delight in the two-way data binding we get for free!) and click the "Save" button.

Whomp whomp. A new error!

#### Pre-flight OPTIONS

Our Ember app is attempting to make a request to `http://localhost:4000/posts` with the `OPTIONS` HTTP method but is getting a 404 Not Found error.

This is related to the CORS stuff we did before.

The browser sends this preflight request to make sure the server knows about CORS, checking for the `Access-Control-Allow-Origin` header we set above.

We have the headers set right, but we need to have our Phoenix server respond to OPTIONS requests.

To do this, switch to your Phoenix project and edit `web/router.ex` to be:

~~~elixir
defmodule PeepBlogBackend.Router do
  use PeepBlogBackend.Web, :router

  pipeline :api do
    plug :accepts, ["json"]
    plug PlugCors, [origins: ["localhost:4200"]]
  end

  scope "/", PeepBlogBackend do
    pipe_through :api

    resources "/posts", PostController
    options "/posts*anything", PostController, :options
  end
end
~~~

and edit your `web/controllers/post_controller.ex` to add a new `options` function at the top before the `def index` line:

~~~elixir
def options(conn, _params) do
  conn
  |> put_status(200)
  |> text(nil)
end
~~~

Try to submit the new post form again and this time it should work!

### Edit page

Switching back to the Ember app, now let's make it so you can edit a post after it has been created.

Edit `app/router.js` to include:

~~~javascript
Router.map(function() {
  this.route('posts', function() {
    this.route('new');
    this.route('post', { path: '/:post_id' }, function() {
      this.route('edit');
    });
  });
});
~~~

We need to add a route at `app/routes/posts/post/edit.js`:

~~~javascript
import Ember from 'ember';

export default Ember.Route.extend({
  actions: {
    save: function() {
      var post = this.currentModel;
      post.save().then(() => {
        this.transitionTo('posts.post', post.id);
      });
    }
  }
});
~~~

Note: if you've never seen the above [fat arrow syntax](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Functions/Arrow_functions), it is a part of [ES6](https://people.mozilla.org/~jorendorff/es6-draft.html) that Ember CLI will transpile into ES5 thanks to the [Babel](https://github.com/babel/ember-cli-babel) library. The above would be equivalent to:

~~~javascript
import Ember from 'ember';

export default Ember.Route.extend({
  actions: {
    save: function() {
      var post = this.currentModel;
      var that = this;
      post.save().then(function() {
        that.transitionTo('posts.post', post.id);
      });
    }
  }
});
~~~

We need to add a template. Instead of duplicating what is in the `new` template, we can extract the form into a partial and render it on both pages.

Make a new file at `app/templates/posts/_form.hbs`:

~~~handlebars
<p>
  <label for="title">Title</label><br>
  {{input value=model.title id="title"}}
</p>

<p>
  <label for="body">Body</label><br>
  {{textarea value=model.body id="body"}}
</p>

<button {{action 'save'}} id="save">Save</button>
~~~

Change `app/templates/posts/new.hbs` to:

~~~handlebars
<h2>New Post</h2>

{{partial "posts/form"}}
~~~

And add `app/templates/posts/post/edit.hbs`:

~~~handlebars
<h2>Edit Post</h2>

{{partial "posts/form"}}
~~~

Finally, add a link on the show page for the edit page by editing `app/templates/posts/post.hbs`:

~~~handlebars
<h2>{{model.title}}</h2>

<article>
  {{model.body}}
</article>

{{#link-to 'posts.post.edit' model}}Edit{{/link-to}}

{{outlet}}
~~~

Now try editing a post.

Your changes should be persisted even when you refresh the page.

### Deleting a post

Finally, we need to be able to delete posts.

Edit `app/routes/posts/post.js`:

~~~javascript
import Ember from 'ember';

export default Ember.Route.extend({
  model: function(params) {
    return this.store.find('post', params.post_id);
  },
  actions: {
    delete: function() {
      var post = this.currentModel;
      post.deleteRecord();
      post.save().then(() => {
        this.transitionTo('posts');
      });
    }
  }
});
~~~

Edit `app/templates/posts/post.hbs`:

~~~handlebars
<h2>{{model.title}}</h2>

<article>
  {{model.body}}
</article>

{{#link-to 'posts.post.edit' model}}Edit{{/link-to}}

<button {{action "delete"}}>Delete</button>

{{outlet}}
~~~

### Root route

One last thing: when we go to just <http://localhost:4200> we just see "Welcome to Ember.js" but it would be nice if it took us straight to the `/posts` route.

This is easy enough to change.

Ember will look for an `index` route when you hit `/`, so we just need to add a file at `app/routes/index.js` with:

~~~javascript
import Ember from 'ember';

export default Ember.Route.extend({
  redirect: function() {
    this.transitionTo('posts');
  }
});
~~~

Let's also make the main header "Blog" instead of "Welcome to Ember.js!" by editing `app/templates/application.hbs`:

~~~handlebars
<h2 id="title">Blog</h2>

{{outlet}}
~~~

That should do it for the Ember app!

## Deploying to Heroku

Now let's share our app with the world.

### Deploying the Phoenix app

Create a `Procfile` at the root of your Phoenix project with the following contents:

~~~
web: mix phoenix.server
~~~

Then initialize a git repository and commit your code:

~~~bash
git init
git add -A
git commit -m "Initial commit"
~~~

Create a new Heroku app, specifying the [Heroku buildpack for Elixir](https://github.com/HashNuke/heroku-buildpack-elixir) and enable the Postgres addon:

~~~bash
heroku create --buildpack "https://github.com/HashNuke/heroku-buildpack-elixir.git"
heroku addons:create heroku-postgresql
~~~

Edit your `config/prod.secret.exs` file to move settings into environment variables:

~~~elixir
use Mix.Config

# In this file, we keep production configuration that
# you likely want to automate and keep it away from
# your version control system.
config :peep_blog_backend, PeepBlogBackend.Endpoint,
  secret_key_base: System.get_env("SECRET_KEY_BASE")

# Configure your database
config :peep_blog_backend, PeepBlogBackend.Repo,
  adapter: Ecto.Adapters.Postgres,
  url: System.get_env("DATABASE_URL") || "ecto://postgres:postgres@localhost/blog_backend_prod",
  size: 20 # The amount of database connections in the pool
~~~

Now that this file contains no actual secrets, edit your `.gitignore` and comment the last line:

~~~bash
# /config/prod.secret.exs
~~~

Then generate and set the environment variable for your secret key base:

~~~bash
heroku config:set SECRET_KEY_BASE=$(elixir -e ":crypto.strong_rand_bytes(64) |> Base.encode16(case: :lower) |> IO.puts")
~~~

The `DATABASE_URL` environment variable should already be set from adding the Postgres addon.

We need to add a `elixir_buildpack.config` file at the root of the project with these contents (in order for the `SECRET_KEY_BASE` to get exported):

~~~bash
config_vars_to_export=(DATABASE_URL SECRET_KEY_BASE)
~~~

Commit your changes and deploy:

~~~bash
git add -A
git commit -m "Extract config settings to env variables"
git push heroku
~~~

Once that finishes, try going to the your app's `/posts` path in your browser:

~~~bash
open $(heroku apps:info -s | grep web_url | cut -d"=" -f2)"posts"
~~~

You should see `"Server internal error"`.

Why are we getting an error?

Let's look at the logs by running `heroku logs`.

You should see something like:

~~~
** (Postgrex.Error) ERROR (undefined_table): relation "posts" does not exist
~~~

We need to create the database on production:

~~~bash
heroku run mix ecto.create
~~~

You may see an error like:

~~~
** (Mix) The database for Todobackend.Repo couldn't be created, reason given: Error: You must install at least one postgresql-client-<version> package.
~~~

You can ignore this.

Then run the migrations:

~~~bash
heroku run mix ecto.migrate
# should output something like:
17:12:41.365 [info] == Running PeepBlogBackend.Repo.Migrations.CreatePost.change/0 forward
17:12:41.366 [info] create table posts
17:12:41.399 [info] == Migrated in 0.3s
~~~

Now try to hit your app's `/posts` route again and you should get:

~~~
{"posts":[]}
~~~

That's it for the Phoenix app!

### Deploying the Ember app

Commit your current code:

~~~bash
cd ../peep-blog-frontend/
git add -A
git commit -m "Initial commit"
~~~

Create another Heroku app using the [Ember CLI buildpack](https://github.com/tonycoco/heroku-buildpack-ember-cli):

~~~bash
heroku create --buildpack https://github.com/tonycoco/heroku-buildpack-ember-cli.git
~~~

Edit your `app/adapters/application.js` file to extract the API server URL to an config variable:

~~~javascript
import DS from "ember-data";
import ENV from '../config/environment';

export default DS.RESTAdapter.extend({
  host: ENV.APP.API_URL
});
~~~

Then define that in your `config/environment.js` file:

~~~javascript
if (environment === 'development') {
  ENV.APP.API_URL = 'http://localhost:4000';
  // ...
}

// ...
if (environment === 'production') {
  ENV.APP.API_URL = process.env.API_URL;
}
// ...
~~~

Now set the environment variable on your Heroku app (replacing the URL with the path to your Phoenix app, **without** a trailing slash):

~~~bash
heroku config:set API_URL=https://your-phoenix-app.herokuapp.com
~~~

Now deploy your app:

~~~bash
git add -A
git commit -m "Extract API URL environment variable"
git push heroku
~~~

Go to your `/posts/new` route and try to create a new post:

~~~bash
open $(heroku apps:info -s | grep web_url | cut -d"=" -f2)"posts/new"
~~~

You should see our old friend the CORS error:

~~~
XMLHttpRequest cannot load https://your-phoenix-app.herokuapp.com/posts. No 'Access-Control-Allow-Origin' header is present on the requested resource. Origin 'https://your-ember-app.herokuapp.com' is therefore not allowed access. The response had HTTP status code 403.
~~~

Switch to your Phoenix project directory:

~~~bash
cd ../peep_blog_backend
~~~

We need to change `web/router.ex` to get the frontend URL from an environment variable. Change:

~~~elixir
plug PlugCors, [origins: ["localhost:4200"]]
~~~

to:

~~~elixir
plug PlugCors, [origins: [System.get_env("FRONTEND_URL")]]
~~~

and edit your `elixir_buildpack.config` file:

~~~bash
config_vars_to_export=(DATABASE_URL SECRET_KEY_BASE FRONTEND_URL)
~~~

Set the environment variable to your Ember app URL (without the scheme) and deploy your Phoenix app again:

~~~bash
heroku config:set FRONTEND_URL=your-ember-app.herokuapp.com
git add -A
git commit -m "Extract frontend URL environment variable"
git push heroku
~~~

Now you should be able to use the entire app without any errors!

## One last CSP fix

Everything works but if you inspect the requests from the Ember app, you'll notice the lack of the CSP headers we saw in development.

This is because the Ember buildpack does not set any of these headers in the Nginx config it provides.

The Ember buildback also takes a different approach for getting past CORS by setting up a [proxy_pass](http://oskarhane.com/avoid-cors-with-nginx-proxy_pass/), which we don't need since we've explicitly added our Ember origin to the headers in our Phoenix app.

We can override the buildpack's Nginx configuration by copying it and making some changes:

~~~bash
wget https://raw.githubusercontent.com/tonycoco/heroku-buildpack-ember-cli/master/config/nginx.conf.erb
mv nginx.conf.erb config/
~~~

Then edit `config/nginx.conf.erb` and replace this section:

~~~erb
<% if ENV["API_URL"] %>
  location <%= ENV["API_PREFIX_PATH"] || "/api/" %> {
    proxy_pass <%= ENV["API_URL"] %>;
    proxy_set_header Real-IP $remote_addr;
    proxy_set_header Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header NginX-Proxy true;
    proxy_ssl_session_reuse off;
    proxy_redirect off;
    <% if ENV["NGINX_DEBUG"] %>add_header Ember-Cli-Proxy on;<% end %>
  }
<% end %>
~~~

with:

~~~erb
<% if ENV["API_URL"] %>
  add_header Content-Security-Policy "default-src 'none'; script-src 'self'; font-src 'self'; connect-src 'self' <%= ENV["API_URL"] %>; img-src 'self'; style-src 'self'; media-src 'self'";
<% end %>
~~~

Now deploy your Ember app one last time and it should include the correct CSP headers.

## Done!

Phew, that sure did seem like a lot for something that Rails can do with a single generator command!

I would definitely say if all you need is a simple CRUD app, the PEEP stack is overkill.

But hopefully this post has provided a good starting point for getting to know both Phoenix and Ember.js.

----

## Did I miss anything?

This blog post is [hosted on GitHub](https://github.com/mxhold/maxwellholder.com/blob/master/source/blog/2015-06-04-build-a-blog-with-phoenix-and-ember.html.markdown) so feel free to file an issue or make a pull request!
