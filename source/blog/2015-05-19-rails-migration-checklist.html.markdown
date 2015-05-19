---
title: Rails Migration Checklist
date: 2015-05-19 15:51 UTC
tags: rails
---

Rails migrations are nice, but remembering the whole DSL can be hard.

Checklists are used by [airplane pilots and doctors](http://www.newyorker.com/magazine/2007/12/10/the-checklist) to avoid fatal errors with great success.

Forgetting to add an index to a column in your migration is hardly a fatal error, but why shouldn't we use the same method to remember important steps in software development tasks?

Use the following checklist when writing Rails migrations to make sure you don't forget something important.

# Rails Migration Checklist

## General

- Have you read the [Rails guide on migrations](http://guides.rubyonrails.org/active_record_migrations.html)?

  There is a lot of important stuff there so you should probably read it first if you haven't.

- Is your migration is fully reversible?

  You should be able to run it up (`rake db:migrate`) and then down (`rake db:rollback`) without getting any errors and without changing the schema dump.

  If your migration cannot be reversible, use the `up`/`down` methods (instead of `change`) and raise a `ActiveRecord::IrreversibleMigration` error inside the `down` method to reveal your intent for it to be irreversible:

  ~~~ruby
  # BAD - running `rake db:migrate` and then `rake db:rollback` will fail
  class DropUsers < ActiveRecord::Migration
    def change
      drop_table :users
    end
  end

  # GOOD - reveals intent that migration should not be reversible
  class DropUsers < ActiveRecord::Migration
    def up
      drop_table :users
    end

    def down
      fail ActiveRecord::IrreversibleMigration
    end
  end

  # BETTER - is actually reversible
  class DropUsers < ActiveRecord::Migration
    def change
      drop_table :users do |t|
        t.string :email, null: false
        t.timestamps null: false
      end
    end
  end
  ~~~

- Do you need to change the schema format to SQL?

  If you are adding database-specific features that won't get captured in the Ruby schema format (e.g. database views, triggers, stored procedures), edit your `config/application.rb` file and switch your `config.active_record.schema_format` setting from `:ruby` to `:sql` so that your schema dumps will include the features you've added in plain SQL.


## Method specific


### `add_column`

- Adding a foreign key?

  Use `add_reference` (or the alias `add_belongs_to`) instead of `add_column` for a shorter, more intention-revealing syntax:

  ~~~ruby
  # BAD - overly verbose
  add_column :articles, :author_id, :integer
  add_index :articles, :author_id
  add_foreign_key :articles, :authors

  # GOOD
  add_reference :articles, :author, index: true, foreign_key: true

  # ALSO GOOD
  add_belongs_to :articles, :author, index: true, foreign_key: true
  ~~~

- Did you add null constraints on required columns?

  ActiveRecord presence validations won't stop someone from inserting null values via `update_attribute` or raw SQL.

  Add a database constraint to be sure that bad data never makes it into your tables:

  ~~~ruby
  # BAD - can still insert null values
  add_column :users, :email, :string

  # GOOD
  add_column :users, :email, :string, null: false
  ~~~

- Did you add unique constraints where you need to guarantee uniqueness?

  Remember: an ActiveRecord uniqueness validation [does not guarantee uniqueness](https://robots.thoughtbot.com/the-perils-of-uniqueness-validations).

  ~~~ruby
  # BAD - does not ensure uniqueness
  add_column :users, :email, :string

  # GOOD
  add_column :users, :email, :string
  add_index :users, :email, unique: true
  ~~~

- Did you add a corresponding ActiveRecord validation for any database constraints so you get nicer validation errors?

  ~~~ruby
  # BAD - ugly ActiveRecord::StatementInvalid error when saving user with no email
  add_column :users, :email, :string, null: false
  # ...
  class User < ActiveRecord::Base
  end

  # GOOD - fails validation before Rails tries to do the insert
  add_column :users, :email, :string, null: false
  # ...
  class User < ActiveRecord::Base
    validates :email, presence: true
  end
  ~~~

- Did you add a string column without specifying a default/null constraint?

  Avoid having both empty strings and null values in string columns since they don't always get put in the same position when ordering.

  Instead, use a null constraint and if the field is not required, set the default to an empty string:

  ~~~ruby
  # BAD - allows for empty strings and null values
  add_column :users, :name, :string

  # GOOD (if name is not required)
  add_column :users, :name, :string, null: false, default: ''

  # GOOD (if name is required)
  add_column :users, :name, :string, null: false
  ~~~

- Did you remember to add indices?

  Add an index to columns that you know you will use to query by, but conservatively since they take up space and make inserts/updates slower:

  ~~~ruby
  # BAD (if you are going to look up users by email)
  add_column :users, :email, :string

  # BAD - unlikely to look up users by password digest so this just takes up unnecessary space
  add_column :users, :password_digest, :string
  add_index :users, :password_digest

  # GOOD (if you are going to look up users by email)
  add_column :users, :email, :string
  add_index :users, :email
  ~~~

- Choosing between `decimal` and `float` types?

  - **Floats** cannot represent all base 10 numbers exactly, so comparing values for equality can lead to unexpected behavior (0.1 + 0.2 will not equal 0.3)
  - **Decimals** can represent all base 10 numbers exactly
  - Math with decimals is slower
  - tl;dr: **when in doubt, use decimals** (especially for money) unless you are ok with inexact values and need to do a lot of operations quickly


- Did you specify `precision` and `scale` when adding decimal columns?

  - **Precision** is the total number of significant digits (the precision of 23.5141 is 6)
  - **Scale** is the number of digits to the right of the decimal (the scale of 23.5141 is 4)
  - The default and maximum allowed precision/scale [varies by database](http://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/TableDefinition.html#method-i-column)

  ~~~ruby
  # BAD - the actual precision and scale this will use will be different depending on your database
  add_column :products, :price, :decimal

  # GOOD - explicit precision and scale
  add_column :products, :price, :decimal, precision: 38, scale: 2
  ~~~

### `change_column`

- Are you adding a `null: false` option to a column that already has null values?

  Use [`change_column_null`](http://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/SchemaStatements.html#method-i-change_column_null) to set the null constraint and replace all the null values in one go:

  ~~~ruby
  # BAD - this will fail if the column already has null values
  change_column :users, :favorite_color, :string, null: false

  # GOOD - this will change all of the null values to "blue" and then add the constraint
  change_column_null :users, :favorite_color, true, 'blue'
  ~~~

### `remove_column`

- Did you provide the optional arguments to make `remove_column` reversible?

  ~~~ruby
  # BAD - this will fail if you try to run `rake db:rollback` after running `rake db:migrate`
  def change
    remove_column :posts, :slug
  end

  # GOOD
  def change
    remove_column :posts, :slug, :string, null: false, default: ''
  end
  ~~~

### `create_table`

- Did you remember to add timestamps?

  ~~~ruby
  # BAD - no timestamp
  create_table :users  do |t|
    t.string :email, null: false
  end

  # GOOD
  create_table :users  do |t|
    t.string :email, null: false
    t.timestamps null: false
  end
  ~~~

## Data migrations

- Should you really be changing data inside your migrations?

  Some people are vehemently opposed to doing any kind of data manipulation inside their Rails migrations as they consider them only for changing the database schema.

  You should talk to the people you're working with about how to handle data migrations and be aware of the pitfalls (see below) that can occur if you decide to do them inside your migrations.

  One alternative is to write separate rake tasks that perform the data migrations alone so that you can then run them at a known point and review the changes to make sure they worked.

  However you decide to handle data migrations, consider writing them in a way that minimizes the chance of losing data as much as possible.

  For example, if you're splitting out a column into two new columns, first write a migration to add the new columns (and maybe also populate them or do this in a separate rake task). Then, only after you're confident the data has been moved over successfully, write a migration to remove the old column.

  Ideally, each migration should still be fully reversible without losing data.

- Did you call a model class from inside your migration?

  Since your models can change independently of your migration code, if you use your models inside your migrations you can end up writing a migration that works when you run it originally, but that causes errors after someone else changes the model later.

  For example, you could write a migration like:

  ~~~ruby
  class SplitUserNames < ActiveRecord::Migration
    def up
      add_column :users, :first_name, :string
      add_column :users, :last_name, :string

      User.find_each do |user|
        user.first_name = user.name.split(' ').first
        user.last_name = user.name.split(' ').last
        user.save!
      end

      remove_column :users, :name
    end

    def down
      add_column :users, :name, :string
      remove_column :users, :first_name
      remove_column :users, :last_name
    end
  end
  ~~~

  For now, let's ignore the various [bad assumptions](http://www.kalzumeus.com/2010/06/17/falsehoods-programmers-believe-about-names/) this migration relies on and assume that all the names in the user table are indeed like "Jane Smith".

  And let's say when you wrote this, your user model was empty:

  ~~~ruby
  class User < ActiveRecord::Base
  end
  ~~~

  You run the migration and it works! You push your code and have a coffee break.

  Well, someone could come along later and add a validation requiring that all last names be in all caps (again, this is a bad example; don't actually do this):

  ~~~ruby
  class User < ActiveRecord::Base
    validates :last_name, format: { with: /\A[A-Z]+\z/ }
  end
  ~~~

  They add a corresponding migration:

  ~~~ruby
  class UpcaseUserLastNames < ActiveRecord::Migration
    def up
      User.find_each do |u|
        u.last_name = u.last_name.upcase
        u.save!
      end
    end

    def down
      fail ActiveRecord::IrreversibleMigration
    end
  end
  ~~~

  Again, let's ignore that this incorrectly assumes `String#upcase` will always produce something that satisfies the regular expression `/\A[A-Z]+\z/`.

  They run this migration and it works fine.

  Once you've pulled in their changes, you run their migration which works fine as well.

  But when you deploy to production, your migration will run first and your call to `User#save!` will fail because the `User` class contains a validation on the `last_name` field that isn't satisfied until the second migration is run.

  One way to get around this is to redefine the model at its current state inside the migration:

  ~~~ruby
  class SplitUserNames < ActiveRecord::Migration
    class User < ActiveRecord::Base
    end

    def up
      add_column :users, :first_name, :string
      add_column :users, :last_name, :string

      User.find_each do |user|
        user.first_name = user.name.split(' ').first
        user.last_name = user.name.split(' ').last
        user.save!
      end
    end

    def down
      remove_column :users, :first_name
      remove_column :users, :last_name
    end
  end
  ~~~

  Now the constant `User` inside the migration will resolve to the empty class you've defined without validations.

  However, redefining model classes like this can cause problems with polymorphic relations since the `User` class in this case is actually defined as `SplitUserNames::User`.

- Are you iterating over a big table with `each`?

  Calling `.all.each` on a model will try to instantiate all the objects at once, which can be really slow if you have lots of them.

  Instead, use [`find_each`](http://api.rubyonrails.org/classes/ActiveRecord/Batches.html#method-i-find_each) to find them in batches of 1000. Be aware that `find_each` will ignore any limits or orders you pass in (since it orders by id and limits by the batch size to find them in batches).

  If you know you don't have to worry about validations (which as you can see from above can be hard to know), use [`update_all`](http://api.rubyonrails.org/classes/ActiveRecord/Relation.html#method-i-update_all) to issue a single `UPDATE` statement without the costs of instantiating any model objects.

  ~~~ruby
  # BAD (if you have lots of users) - instantiates all users at once
  User.all.each do |user|
    # ...
  end

  # GOOD - finds in batches of 1000
  User.find_each do |user|
    # ...
  end

  # BAD - find_each ignores limit and order options
  User.order(:name).limit(25).find_each do |user|
    # ...
  end
  ~~~

----

## Did I miss anything?

This blog post is [hosted on GitHub](https://github.com/mxhold/maxwellholder.com/blob/master/source/blog/2015-05-19-rails-migration-checklist.html.markdown) so feel free to file an issue or make a pull request!
