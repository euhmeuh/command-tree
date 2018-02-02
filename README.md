# command-tree
A Racket package to handle tree-style (à la git) command line arguments

## Examples

This package allows you to write command line applications that behaves like this:

`$ git stash pop`  

`$ pimp my ride "green neons"`  

`$ ipod list all albums from 1969`  

`$ hello world --help`

# Usage

```racket
#lang racket/base

(require command-tree)

;; ... define procedures git-clone, git-init, git-stash-apply...

;; write your available commands in a tree
(define git-commands
  `([clone ,git-clone]
    [init ,git-init]
    [push ,git-push]
    [remote (add ,git-remote-add)
            (rename ,git-remote-rename)
            (remove ,git-remote-remove)]
    [stash (list ,git-stash-list)
           (show ,git-stash-show)
           (drop ,git-stash-drop)
           (pop ,git-stash-pop)
           (apply ,git-stash-apply)]))

;; use the tree to parse the command line
(command-tree git-commands (current-command-line-arguments))
```

See the test submodule in main.rkt for a complete usage example.
