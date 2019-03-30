# Rust language support in Atom

[![apm](https://img.shields.io/apm/v/language-rust-redux.svg)](https://atom.io/packages/language-rust-redux) [![Travis CI](https://travis-ci.org/TheEnigmaBlade/atom-language-rust-redux.svg?branch=master)](https://travis-ci.org/TheEnigmaBlade/atom-language-rust-redux)

Adds syntax highlighting and snippets for [Rust](http://www.rust-lang.org/) files in [Atom](http://atom.io/).

## Install

Install the package `language-rust-redux` from within Atom (Preferences->Packages) or through Atom's package manager:

```bash
$ apm install language-rust-redux
```

### JSON grammar

To obtain a JSON version of the grammar for use in other supported editors, run the npm script "cson2json" and `grammars/rust.json` will be generated.

```bash
$ npm install
$ npm run cson2json
```

## Key changes from other grammars

Previews taken with Firewatch syntax.

- The latest syntax, such as the `?` operator
- Format macro syntax highlighting<br>
  ![](http://i.imgur.com/mUlh8P0.png)
- Markdown syntax highlighting in doc comments<br>
  ![](http://i.imgur.com/JDSoPSQ.png)
- Invalid syntax common in similar languages<br>
  ![](http://i.imgur.com/KsS24Di.png)<br>
  ![](http://i.imgur.com/0C3xdPv.png)
- Common mistake recognition<br>
  ![](http://i.imgur.com/kPhbuE7.png)
- Improved keyword context (`where` actually works, `unsafe` allowed in more places)
- Numerous fixes: lifetimes in associated type definitions, `fn` in function arguments, and nested block comments

## Bugs and suggestions

If you notice any bugs or have any suggestions for improvement, please submit an issue with a full description and example code.
