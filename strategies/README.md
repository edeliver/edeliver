Deliver will use the ruby strategy by default. If you want to use a different
one, define it in your `.deliver/config` file. Alternatively, pass it as at runtime:

    $ STRATEGY=nodejs deliver

If you want to implement your own strategy, fork away. Currently,
deliver only works with strategies defined in the local `strategies`
directory, but with very little effort it can support any strategy
specific to your setup.  All strategies in your local
`.deliver/strategies` directory are automatically available.



## Conventions

**foreman exporting to upstart**

These are all good conventions which have been bread over the years from
orchestrating many different infrastructure setups. You can disregard
everything here and go back to your existing deployment process. Alternatively,
you can fork, add your improvements and contribute towards a modern and
efficient deployment tool that just works.

### 1.1 Ubuntu

Your server is running Ubuntu, preferably 10.04 LTS.

Ubuntu + upstart are by no means the holy grail, but they work very
well. By leveraging foreman, deliver supports all foreman supervisors.

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
`apps` recipe will set everything up for you.

### 1.4 [RVM](http://beginrescueend.com/)

You might want to install rvm on the server that you'll be delivering your code to. I
prefer system-wide setups in production. Yes, you've guessed it, use chef's
[rvm-cookbook](https://github.com/gchef/rvm-cookbook) for the best experience.

### 1.5 [rbenv](https://github.com/sstephenson/rbenv)

For those that prefer rbenv in production (I do), use
[rbenv-cookbook](https://github.com/gchef/rbenv-cookbook).

### 1.6 [Foreman](https://github.com/ddollar/foreman)

Every app should have this. It allows you to painlessly scale your app
components, [just as if you were running on
Heroku](http://devcenter.heroku.com/articles/procfile). Deliver now
supports a global foreman. As long as it's installed on the remote host
and accessible to the system user running the app, it will just work.
