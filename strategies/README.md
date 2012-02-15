Deliver will use the ruby strategy by default. If you want to use a different
one, define it in your `.deliver` file. Alternatively, pass it as the first
argument:

    $ deliver gh-pages

As a note, the `STRATEGY` value in the `.deliver` file will overwrite any
argument specified on the command line.

If you want to implement your own strategy, fork away. Currently, deliver only
works with strategies defined in the local `strategies` directory, but with
very little effort it can support any strategy specific to your setup.

Ideally, there will be core strategies which will reside with the project, then
custom ones which will stay within your app's repository. This is not
revolutionary, Capistrano is using the same concept for SCMs.



## 1 ruby _(default strategy)_

**rvm and foreman exporting to upstart**

These are all good conventions which have been bread over the years from
orchestrating many different infrastructure setups. You can disregard
everything here and go back to your existing deployment process. Alternatively,
you can fork, add your improvements and contribute towards a modern and
efficient deployment tool that just works.

### 1.1 Ubuntu

Your server is running Ubuntu, preferably 10.04 LTS.

Ubuntu + upstart are by no means the holy grail, but they work very well. Feel
free to share your love for other distros & service managers via pull requests.

### 1.2 Remote logins and privileges

Your local username can gain sudo privileges on the server without being
prompted for a password.

**Don't login with root. Don't use password logins.**

If you're using chef to manage your servers
[sudo-cookbook](https://github.com/opscode/cookbooks/tree/master/sudo) &
[ssh-cookbook](https://github.com/gchef/ssh-cookbook) will work right out of
the box.

### 1.3 Every app gets its own system user

A system user has been created for the app that you'll be delivering. I
personally prefer the same name as the app itself. You should be able to log in
as this user, without any password.

If you're already using chef,
[bootstrap-cookbook](https://github.com/gchef/bootstrap-cookbook) with the
`ruby_apps` recipe will set everything up for you. It handles the entire rvm
integration, even down to configuring the user's bash environment. This is
ruby-only for the time being, but there are plans to make it language agnostic.

### 1.4 [RVM](http://beginrescueend.com/)

You have rvm installed on the server that you'll be delivering your code to. I
prefer system-wide setups in production. Yes, you've guessed it, use chef's
[rvm-cookbook](https://github.com/gchef/rvm-cookbook) for the best experience.

ps: rbenv support is on the roadmap. If you want it right now, fork away.

### 1.5 [Foreman](https://github.com/ddollar/foreman)

Every Ruby app should have this. It allows you to painlessly scale your app
components, [just as if you were running on
Heroku](http://devcenter.heroku.com/articles/procfile). A server-side foreman
would be even nicer, something that will take care of node.js, or any other
type of app. Already on the roadmap.



## 2 gh-pages

**generates content into a local gh-pages directory, then commits and pushes to gh-pages branch**

Use this when you have a static site or documentation for your project (rocco,
docco etc.) which you host on [github:pages](http://pages.github.com/).

You can handle the generation via your own custom `bin/generate` command,
otherwise it will default to `rake generate`.

As an example, here is a rake task that handles rocco generation for a ruby
gem:

    require 'rdiscount'
    require 'rocco/tasks'
    Rocco::make 'gh-pages/'

    desc 'Build rocco gh-pages'
    task :docs => :rocco do
      %x{
        cd gh-pages;
        mv lib/* .;
        rm -fr lib;
        cp chef-extensions.html index.html
      }
    end
    # Alias for docs task
    task :generate => :docs

With this strategy, whenever I want to update this gem's documentation, I just
run `deliver`.
