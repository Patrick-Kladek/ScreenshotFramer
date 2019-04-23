Things to Keep in Mind
======================


Support For New Repo Types
--------------------------

When supporting new types of repos you should set all of the currently used symbols and document how they are populated.

Support for new repos should include a function named in the form `<repo_type>Repo` and a two part test: the first part should try to detect the presence of a repo without using any of the native repository commands, the second test should test for the presence the native repository commands, ideally by determining the full path to the top level of the repo.

Generally you *should* assume that you are executing from the top of the repo.

The first thing that any repo function should do is `cd` to the root level of the repository, if possible.

As a rule of thumb, try to use commands to gather the data to populate the symbols in such a way as to require the least amount of post processing by things like `sed` or `grep`.


Support For New Output Types
----------------------------

When supporting new types of outputs you *should* use all of the currently set symbols; if you do not, that needs to be explicitly documented.

Support for new outputs should include a function named in the form `<output_type>Output`; find one that's similar to your target language, clone it, and modify it.

Make sure that you commit an example of the output into the `example` directory.

Other Conventions
-----------------

* Signed commits are preferred and signed tags are required.
* Tabs are preferred to spaces.
* Do not forget to update the documentation.
* You generally should *not* assume that any extras, extensions or otherwise non-default commands are available.
* Again, remember this is not `bash` but POSIX shell.
* Any use of `sed` *should* use `:` as a delimiter whenever feasible.
* All variables should be written in the form `"${<variable>}"`.
* All error messages should be prefixed with `error: `.
* All warning messages should be prefixed with `warning: `.
* Try to avoid stderr output from any subcommand leaking through.
* Test using [https://www.shellcheck.net/](https://www.shellcheck.net/).
