# GenServer Architecture Example

This is a simple repo to demonstrate why I advocate for GenServers being thin wrappers around a `struct`-providing module, rather than implementing complex logic themselves.

The commits in this repo over time show feature additions (such as they are), test additions, and refactorings on the extremely simple `user_counter.ex` module.

There's [a post on my blog explaining the code](https://tylerayoung.com/2021/06/24/architecting-genservers-for-testability/)—you probably want to reference that to make sense of this.

