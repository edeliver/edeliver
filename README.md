Deliver is a pure bash deployment tool with virtually no dependencies.
It only cares about having enough info in the shell environment to do
its job. Why add Ruby or Python wrappers on top of system commands when
bash was built for this?

Capistrano was just infuriating when you added rvm and bundler into the
mix, git-deploy is great for single server, but what if you're running a
bunch of auto-scaled clusters (Ruby, node.js etc.)?

Delivering a nodejs service to multiple hosts:

![deliver nodejs service to multiple hosts][2]

Delivering deliver to [github:pages][8] (very inception-esque):

![deliver deliver to github:pages][7]

Strategies is what sets this utility apart from everything else. By
default, it comes with strategies for:

  * [ruby][3]

  * [nodejs][4]

  * [gh-pages][5]

  * [generated][10]

  * [s3][11]

You can also add your own, project-specific strategies, or customise
existing ones. [Read more about deliver strategies.][6]


## 1 INSTALLATION

### 1.1 Check out deliver into `~/.deliver`.

```bash
$ git clone git://github.com/gerhard/deliver.git ~/.deliver
```

### 1.2 Add `~/.deliver/bin` to your `$PATH` for access to the `deliver` command-line utility

```bash
$ echo 'export PATH="$HOME/.deliver/bin:$PATH"' >> ~/.bash_profile
# if using zsh
$ echo 'export PATH="$HOME/.deliver/bin:$PATH"' >> ~/.zshrc 
```

### 1.3 Source your shell profile

```bash
$ . ~/.bash_profile
# if using zsh
$ . ~/.zshrc 
```

### 1.4 Personalize

There are no generators or initializers, you will need to manually create a
`.deliver/config` file in the app's root folder that you want to deliver.

This is a good example:

```bash
#!/usr/bin/env bash

APP="events"
HOSTS="ruby-1,ruby-2"
PORT="5000"
```



## 2 USAGE

From the root of your project, run:

```bash
$ deliver check
```

![deliver check][9]

This will print the most important config settings and ensure that
deliver has everything that it needs for a successful run. 

Deliver will use the ruby strategy by default. If you want to use a different
one, specify it in your `.deliver/config` file.

To see a list of available strategies:

```bash
$ deliver strategies
```

[Read more about deliver strategies][6]

To see all supported options and actions:

```bash
$ deliver -h|--help
```



## 3 LICENSE

(The MIT license)

Copyright (c) Gerhard Lazu

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



## 4 CREDITS

Deliver started at [GoSquared][1]. It was a place where each of us was
free to use their own programming language. As long as the service
exposed an API and had decent test coverage, anything went. Yes,
**even** PHP.



## INSPIRATION

"Rather than fitting a large number of complex primitives, choose a small
number of simple primitives that can be combined in an infinite way to
produce complex results. What was left out is more important than what
was put in." [AT&T - the UNIX operating system][att_unix]



[1]: http://www.gosquared.com/
[2]: http://c2990942.r42.cf0.rackcdn.com/deliver-nodejs.png
[3]: strategies/ruby
[4]: strategies/nodejs
[5]: strategies/gh-pages
[6]: strategies
[7]: http://c2990942.r42.cf0.rackcdn.com/deliver-deliver.png
[8]: http://gerhard.github.com/deliver
[9]: http://c2990942.r42.cf0.rackcdn.com/deliver-check.png
[10]: strategies/generated
[11]: strategies/s3
[att_unix]: http://www.youtube.com/watch?v=tc4ROCJYbm0
