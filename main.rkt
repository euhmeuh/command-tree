#lang racket/base

(provide
  ;; parse arguments and run the corresponding command/subcommand
  ;; according to a given command tree
  command-tree)

(require
  racket/list
  racket/match
  racket/function)

(define (get-command tree arg)
  (match (assq (string->symbol arg) tree)
    [(list name proc) #:when (procedure? proc) proc]
    [(cons name tree) tree]
    [_ #f]))

(define (error-and-display-available-commands title tree)
  (raise-user-error
    title
    "Available commands are: ~a" (map car tree)))

(define (normalize-arguments x)
  (cond
    [(list? x) x]
    [(vector? x) (vector->list x)]
    [else (list x)]))

(define (command-tree tree arguments)
  (define args (normalize-arguments arguments))
  (when (empty? args)
    (error-and-display-available-commands 'missing-sub-command tree))
  (define command (get-command tree (car args)))
  (cond
    [(procedure? command)
     (apply command (cdr args))]
    [(list? command)
     (command-tree command (cdr args))]
    [else
     (error-and-display-available-commands 'unknown-command tree)]))

(module+ test
  (require
    rackunit
    racket/string
    racket/format
    racket/function
    racket/contract)

  ;; sample list of commands you can write:

  (define (git-clone url)
    (format "git clone ~a" url))

  (define (git-init)
    "git init")

  (define (git-push . options)
    (string-join (append '("git push") (map ~a options))))

  (define (git-remote-add name url)
    (format "git remote add ~a ~a" name url))

  (define (git-remote-rename old new)
    (format "git remote rename ~a ~a" old new))

  (define (git-remote-remove name)
    (format "git remote remove ~a" name))

  (define (git-stash-list)
    "git stash list")

  (define (git-stash-show)
    "git stash show")

  (define (git-stash-drop name)
    (format "git stash drop ~a" name))

  (define (git-stash-pop name)
    (format "git stash pop ~a" name))

  (define (git-stash-apply name)
    (format "git stash apply ~a" name))

  ;; The tree defines available commands and subcommands.
  ;; It can be deeply nested, as long as leaves end with a procedure to call
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

  ;; command-tree returns the result of the first found command
  ;; with further arguments applied,
  ;; or it raises a user error displaying available commands.
  (check-equal? (command-tree git-commands '("clone" "https://my/git/url"))
                "git clone https://my/git/url")

  (check-equal? (command-tree git-commands '("init"))
                "git init")

  (check-equal? (command-tree git-commands "init")
                "git init")

  (check-equal? (command-tree git-commands '("push" "origin" "master"))
                "git push origin master")

  (check-equal? (command-tree git-commands (vector "push" "origin" "master"))
                "git push origin master")

  (check-equal? (command-tree git-commands '("remote" "add" "prod" "https://my/prod/repo"))
                "git remote add prod https://my/prod/repo")

  (check-equal? (command-tree git-commands '("stash" "pop" "0"))
                "git stash pop 0")

  (define (exn-unknown-command? exn)
    (and/c exn:fail:user?
           (string-prefix? (exn-message exn) "unknown-command:")))

  (define (exn-missing-sub-command? exn)
    (and/c exn:fail:user?
           (string-prefix? (exn-message exn) "missing-sub-command:")))

  (check-exn exn-missing-sub-command?
             (thunk (command-tree git-commands '("stash"))))

  (check-exn exn-unknown-command?
             (thunk (command-tree git-commands '("stash" "pup")))))
