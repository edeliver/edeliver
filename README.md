Born out of frustration with the current Ruby deployment practices.

Capistrano is a workhorse, but if you combine it with rvm and bundler, you're
in for a treat.

git-deploy works pretty well, but it's still not seamless and you end up having
to work around it too often for my taste.

heroku solves the deployment process bang on.

This gem brings the same heroku-style deploys convenience to a regular VPS,
{cloud-provider} instance or even bare metal (if you're that hard core).

At [GoSquared](http://www.gosquared.com/), we use this gem to deploy Ruby, PHP
and node.js applications. Here's a Ruby app being deployed:

<img src="http://c2990942.r42.cf0.rackcdn.com/deliver.png" />



## 1 ASSUMPTIONS

These are all good assumptions which have been bread over the years from
administrating many different infrastructure setups. You can disregard
everything here and go back to your existing deployment process. If you can't
be bothered to submit a pull request with a better solution, I will show an
equal interest in your opinions.

### 1.1 Ubuntu

Your server is running Ubuntu, preferably 10.04 LTS. Ubuntu + upstart are by no
means the holy grail, but they work very well for me. Feel free to share your
love for other distros & service managers via pull requests.

### 1.2 SSH logins

Your local username can gain sudo privileges on the server without being
prompted for a password. Don't login with root. Don't use password logins.

If you're using chef to manage your servers
[sudo-cookbook](https://github.com/opscode/cookbooks/tree/master/sudo) &
[ssh-cookbook](https://github.com/gchef/ssh-cookbook) will work right out of
the box, you won't even have to think about it.

### 1.3 App user

A system user has been created for the app that you'll be delivering. I
personally prefer the same name as the app itself. You should be able to log in
as this user, without any password.

If you've been inspired enough to choose chef,
[bootstrap-cookbook](https://github.com/gchef/bootstrap-cookbook) with the
`ruby_apps` recipe will just work. It handles the entire rvm integration, even
down to configuring the user's bash environment.

### 1.4 [RVM](http://beginrescueend.com/)

You have rvm installed on the server that you'll be delivering your code to. I
use only system-wide setups in productioon. Yes, you've guessed it, use
[rvm-cookbook](https://github.com/gchef/rvm-cookbook) for the best experience.

ps: rbenv support is on the roadmap. If you want it right now, fork away.

### 1.5 [Foreman](https://github.com/ddollar/foreman)

You can painlessly scale your services from your app, [just as if you were
running on Heroku](http://devcenter.heroku.com/articles/procfile).



## 2 INSTALLATION

### 2.1 Check out deliver into `~/.deliver`.

    $ cd
    $ git clone git://github.com/gerhard/deliver.git .deliver

### 2.2 Add `~/.deliver/bin` to your `$PATH` for access to the `deliver` command-line utility

    $ echo 'export PATH="$HOME/.deliver/bin:$PATH"' >> ~/.bash_profile
    $ echo 'export PATH="$HOME/.deliver/bin:$PATH"' >> ~/.zshrc # if using zsh

### 2.3 Source your shell profile

    $ . ~/.bash_profile
    $ . ~/.zshrc # if using zsh

### 2.4 .deliver app config

There are no fancy generators, you will need to create a `.deliver` file
manually in the root folder of the app that you want delivering. For those of
you that didn't notice it yet, there's no `Deliverfile` *faux pas* going on
either.

Here's a `.deliver` example:

    APP="squirrel"          # You know, the shipit one

    USER="$APP"             # Can be anything really, but it would be nice if you stuck to this convetion

    PORT=7000               # The TCP port on which your app will be listening on (think reverse-proxies)
                            # Not at all scalable, will be revised not before long

    DEPLOY_TO="~$USER/app"  # The location where the app will be 'git pushed' to

    SERVER="shipit"         # The hostname or IP where the app will be delivered

    REMOTE="$USER@$SERVER"  # You will be performing most remote tasks as this user,
                            # e.g. git pushing, bundling etc.
                            # Tasks requiring sudo privileges will be performed as
                            # your local user. See 1. from ASSUMPTIONS.



## 3 USAGE

From the root of your project which has been configured via the `.deliver`
file, run:

    $ deliver

If you want a more verbose output:

    $ deliver -v
    $ deliver --verbose # same as above

For full debugging mode:

    $ deliver -d
    $ deliver --debug # same as above



## 4 ROADMAP

The gem is pretty much bare bones as it stands. It's just enough to solve our
deployment woes. It's bash only (even if it was released as a Ruby gem). I can
imagine Ruby being added with the post-deploy hooks feature, but until we cross
that bridge, bash gets the job done.

* revise the `PORT` option with something more scalable
* multi-server deploys
* don't run the full deploy if nothing has changed
* Post deploy hooks:
  * Campfire
  * Graphite
* rbenv integration (not a priority for me personally)
* better error handling (particularly when remote tasks fail)



## 5 LICENSE

(The MIT license)

Copyright (c) 2012 Gerhard Lazu

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
