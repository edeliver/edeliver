Deliver takes your local code and sets it up in production. A cross
between Capistrano, git-deploy and heroku deploys, but language
agnostic. At [GoSquared] [2], we use this utility
to deploy Ruby and node.js applications. An example:

![deliver] [1]

Strategies is what sets this utility apart from everything else. It
comes with these by default:

  * [ruby] [3]

  * [nodejs] [4]

  * [gh-pages] [5]

You can also add your own, project-specific strategies. [Read more about deliver
strategies.] [6]


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

There are no generators or initializers, you will need to create a
`.deliver` dir in the app's root folder that you want to deliver.

[Config examples] [7], strategy-specific.



## 2 USAGE

From the root of your project, run:

```bash
$ deliver
```

Deliver will use the ruby strategy by default. If you want to use a different
one, define it in your `.deliver/config` file.

To see a list of available strategies:

```bash
$ deliver -s|--strategies
```

[Read more about deliver strategies] [6]

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

[1]: http://c2990942.r42.cf0.rackcdn.com/deliver.png
[2]: http://www.gosquared.com/
[3]: master/strategies/ruby
[4]: master/strategies/nodejs
[5]: master/strategies/gh-pages
[6]: master/strategies
[7]: master/examples
