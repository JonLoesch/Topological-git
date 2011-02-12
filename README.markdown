Topological git
===============

This tool is a quick-and-dirty visualizer script I wrote over the weekend to help me understand branch structure quickly.  My previous method was akin to using something like: 'git log --graph --oneline --decorate --all'.  However, the number of local (unpushed) topic branches became too high for me to handle.  It occurred to me that the problem was really that I have to scroll through pages and pages of output to see where branches connect up.  I don't really care too much about the actual commit data (in this use case, anyway), I just care about the branch names and connectivity.  In other words, I wanted something to compress as much as possible and show a git branch structure, while retaining its topological integrity

Status
------

This is my first time coding in ruby.  It's also my first time using git "plumbing" commands.  It's also a project that I threw together in a weekend.  Therefore, it's VERY rickety and probably not very good quality.  However, it does seem to work on my system.  I figure if I put it out there and anyone wants it, they can deal with any porting issues themselves

Usage
-----

Usage is pretty simple:
    ./gittop.rb
Note that this is a ruby tool, so you need to have ruby installed

Internals
---------

Because I didn't want to code an ascii tree generator myself, I hacked git to do it.  What this program actually does is parses through your branch structure, then creates a compressed structure AS IF you had written every seperate branch in a single commit.  (It's essentially a squash)  It then saves these commits to the git repo (but doesn't assign any branches to them).  Then it calls the regular 'git log --graph' functionality, and exits.
There are a few problems with this approach:
 - Messages are not too verbose at the moment (meaning author, original commit messages, etc...).  With a sufficient amount of hackery, this can be remedied by encoding this information and shoving it into the new messages.
 - This generates alot of orphaned git commits.  I don't see any easy way around this.  I personally don't care about it too much, and have never run into an issue caused by too many orphans.  If worst comes to worst, you can just run 'git gc' to clean them all up.

Known bugs
----------

Merge commits don't behave properly.  I'm working on it.
