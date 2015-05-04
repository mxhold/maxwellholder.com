---
title: test
title: "Contributing to Open Source using Copy and Paste"
date: 2014-09-29 16:44:20 -0400
tags: [OSS, Open Source, Arel]
---

As someone new(ish) to professional programming, it is nice to work in a field
where your formal qualifications are pretty much irrelevant if you can prove
that you can do the job.

This is frequently done by contributing to open-source software. Your GitHub
profile can be more important than your résumé when it comes to landing a job.

But it can be hard to know where to start.

### Gardening

There is a lot of advice out there on how to approach contributing to OSS.

Steve Klabnik offers some good advice about [how to be an open source
gardener](http://words.steveklabnik.com/how-to-be-an-open-source-gardener).

He says large open-source projects are like gardens that have weeds (issues)
that need to be tended regularly.
He took up tending to the [Rails](https://github.com/rails/rails) garden by
triaging a massive number of issues.

Steve gets all the kudos I can offer.

I've tried my hand at looking through some Rails issues because, of course, I
want to be cool like Steve Klabnik.
I'll just say a lot of those issues are posted by people who seem to know what
they're doing.

I don't know what I'm doing.

So in order to be cool and contribute to OSS, I channelled my earliest days as a
developer (about a year ago) and I did what I did then:

I found a problem and tried to solve it by copying code written by someone who
knew what they were doing.

### Arel is Awesome

A few weeks ago, I was looking into [Arel](https://github.com/rails/arel) (which
has totally changed the way I use Rails by the way, def would recommend).

Arel makes it easier to write complex SQL queries without having to build big
strings of raw SQL.
Instead you can just use Ruby.

Something like:

~~~sql
SELECT snacks.* FROM snacks
INNER JOIN maxs_favorite_snacks
ON snacks.id = maxs_favorite_snacks.snack_id
WHERE snacks.vegetarian = 1 AND snacks.deep_fried = 1;
~~~

becomes:

~~~ruby
snacks = Arel::Table.new(:snacks)
maxs_favorite_snacks = Arel::Table.new(:maxs_favorite_snacks)

snacks.project(snacks[Arel.star])
  .join(maxs_favorite_snacks)
    .on(snacks[:id].eq(maxs_favorite_snacks[:snack_id]))
  .where(snacks[:vegetarian].eq(1).and(snacks[:deep_fried].eq(1)))
  .to_sql
~~~

What it lacks in readability it makes up for in composability.

For example, the above methods (`project`, `join`, `where`) could have been
called in any order since the SQL is only generated once at the end.

### Visitors and Nodes

Anyway, I was looking around the repo to try to figure out where all the magic
happened because that seems like quite a feat.

I figured this thing is generating SQL so there must be a bunch of strings
somewhere like "INNER JOIN" and "SELECT".

I clicked around a bit and found a `nodes` directory with a bunch of classes
including `inner_join.rb` and `select_statement.rb`.
Woo! That must be it.

But they seemed pretty abstract when I looked at them:

~~~ruby
# arel/lib/arel/nodes/inner_join.rb
module Arel
  module Nodes
    class InnerJoin < Arel::Nodes::Join
    end
  end
end
~~~

Hmm... my strings must be in another castle.

Soon enough I discovered the `visitors` directory and a file called `to_sql.rb`
which starts with a bunch of constants:

~~~ruby
WHERE    = ' WHERE '
SPACE    = ' '
COMMA    = ', '
GROUP_BY = ' GROUP BY '
ORDER_BY = ' ORDER BY '
WINDOW   = ' WINDOW '
AND      = ' AND '
~~~

Jackpot!

It turns out Arel uses the [visitor design
pattern](https://en.wikipedia.org/wiki/Visitor_pattern), which is pretty neat if
you aren't familiar with it (I wasn't).

My (pretty basic) understanding of it is that it means you can use Arel to build
up a tree of Arel::Nodes that represent the SQL thing you're trying to do and
then a visitor visits each node and figures out what to do for each node.

Looking at the other files in the `visitors` directory makes that make a little
more sense as there are database-specific visitors that implement things that
only exist for that database, like `ILIKE` for Postgres.

There is even a visitor for generating a [DOT
file](https://en.wikipedia.org/wiki/DOT_(graph_description_language\)) instead
of SQL!
I imagine that would be crazy gross to add if they didn't use this pattern.

Anyway, I took a peek at the `postgres.rb` visitor:

~~~ruby
module Arel
  module Visitors
    class PostgreSQL < Arel::Visitors::ToSql
      private

      def visit_Arel_Nodes_Matches o, collector
        infix_value o, collector, ' ILIKE '
      end

      def visit_Arel_Nodes_DoesNotMatch o, collector
        infix_value o, collector, ' NOT ILIKE '
      end

      def visit_Arel_Nodes_Regexp o, collector
        infix_value o, collector, ' ~ '
      end

      def visit_Arel_Nodes_NotRegexp o, collector
        infix_value o, collector, ' !~ '
      end

      def visit_Arel_Nodes_DistinctOn o, collector
        collector << "DISTINCT ON ( "
        visit(o.expr, collector) << " )"
      end
    end
  end
end
~~~

Then I thought: "Oh cool! I didn't know I could use Arel to generate a `DISTINCT
ON` query."

And that's where I left it until a week later I was writing a query for a Rails
app using Arel, and thought I needed to use a `DISTINCT ON`.

### Is This a Bug or Am I Just Dumb?

I checked the README to see if it mentioned how to use it... no dice.

You can tack a `distinct` on the end but that just gives you a normal distinct:

~~~ruby
snacks.project(snacks[Arel.star]).distinct.to_sql
# => "SELECT DISTINCT \"snacks\".* FROM \"snacks\""
~~~

Well, I thought, the `DISTINCT ON` is just another kind of node... maybe I can
just stick it in the select and Arel would figure it out and everything would be
ok:

~~~ruby
Country.select(
  Arel::Nodes::DistinctOn.new(
    Country.arel_table[:id]
  )
).select(Arel.star).to_sql
# => "SELECT DISTINCT ON ( \"countries\".\"id\" ), * FROM \"countries\""
~~~

Hmm looks kinda reasonable... but then I ran it:

~~~
PG::Error: ERROR:  syntax error at or near ","
LINE 1: SELECT DISTINCT ON ( "countries"."id" ), * FROM "countries"
                                               ^
~~~

Womp womp.
Either this is a bug or I didn't know how to use `Arel::Nodes::DistinctOn`.

I filed [an issue](https://github.com/rails/arel/issues/302) and went on my way.

It turns out I didn't need a `DISTINCT ON` in my query anyway so I kinda forgot
about it.

But I came back to it a couple weeks later... no one had responded to the issue
so I thought I'd take a crack at it.
I mean, how hard could it be to just make that comma not happen?

### Making that Comma Not Happen

I tracked down [the part of the code that was adding the
comma](https://github.com/rails/arel/blob/fef9ce493ec3eab3cf120550abd0257f89eaddf7/lib/arel/visitors/to_sql.rb#L247)
and realized it was basically treating the `DISTINCT ON` node like another
column, rather than as a modification of the entire select.

So yeah... I was doing it wrong.

Well there must be *some* way to do it, otherwise why would the node exist??

I checked [the
commit](https://github.com/rails/arel/commit/0b9af9762a5f3431f83a9bba6919fef9346e310a)
that introduced the `visit_Arel_Nodes_DistinctOn` method to the Postgres
visitor.

Hmm... well there was a test so it must work... but it requires you to create
the `Arel::Nodes::SelectCore` yourself, which seemed gross to me.

It should be just as easy as using `distinct`!

You should be able to just do:

~~~ruby
table = Arel::Table.new(:users)
table.project(Arel.star).distinct_on(table[:id]).to_sql
# => "SELECT DISTINCT ON ( \"users\".\"id\" ) * FROM \"users\""
~~~

It was up to me to fix this and restore balance to the universe and ~contribute
to OSS~!

I looked at how `distinct` worked, copied the tests for `distinct`, replaced
`Arel::Nodes::Distinct` with `Arel::Nodes::DistinctOn`, and added some stuff so
you could give it an argument (since we have to `DISTINCT ON` something).

I made the tests pass by copying the `distinct` method and adding some stuff to
give it an argument.

Then I made [my first pull request](https://github.com/rails/arel/pull/306)(!)
and waited.

Some days later and it got merged!

### Success!

Finally all the copy-pasting practice I've gained from StackOverflow over the
years has paid off.

I think this is a good example of how new developers can benefit a lot from
well-written, existing code in a project.

My super basic contribution to open source software also showed me that the
libraries I use day-to-day that seem super magical can actually be pretty
accessible if you dig into them.

Now I feel less like I don't know what I'm doing.



