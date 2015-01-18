![pit](pit_logo.png?raw=true)
##A (single file) archive wrapper around git
###Introduction:
Sometimes you want have a version control system for a single (script) file. Though this is possible with git by creating a new folder and initializing a git repository inside it, this is definitely inconvenient and limits your workflow.
Let's say for example that you want to have several of these files in the same folder, each having its own version control. You normally cannot do this with git. You could use another git directory than the default `.git` for each file, but then you will have to either use `--git-dir=<path>` on each call or set the environment variable `GIT_DIR` each time you change the file.

This is where pit comes in. pit archives the `.git` folder (and the file itself) for the file `myscript.sh` into a tar repository called `.myscript.sh.pit` - the pit archive. It is easily portable. You can have as many of these files in a folder as you want, since each has a different name.
Now if you want to call git on a specific file, you first have to specify the name of the file using pit like this:

`pit myscript.sh git commit -am "It is working" `

pit will

- unpack the pit archive into a temporary directory
- copy your modified files into it (**also deletes** deletedfiles in your archive)
- perform the git command
- repack the archive
- update your archive and files if necessary

Scroll down to the usage section for an overview of the syntax.
###Examples
####Initializing with an existing file
Let's say you have a script file `myscript.sh` lying somewhere around. You want to start making version control on this particular file. Then you have to issue:

`pit myscript.sh init`

That's it. If your file was not empty and you want to file a commit you type:

`pit myscript.sh git commit -am "The commit message comes here."`

You can of course ommit the -m option and editor will show up, just as you are used to from git, because what is called really is git.
####Cloning from a remote git source into a pit archive
Sometimes you want to host your single file repository on a external server like github. Locally you want to still work with pit. This works as follows:

`pit myproject clone https://github.com/me/myproject`

For uploading changes to the original repository, issue the git command you would use for this preceeded by `pit myproject`:

`pit myproject git push origin master`
####Restoring the files from a pit archive only
If someone sent you a pit archive and you want to get all the files of the latest commit, just issue:

`pit name git reset --hard`

This is just a `git reset` which takes the `.git` folder from the pit archive, nothing special here.
The files from the archive will appear in the same directory as the pit archive resides in.
###Multiple File Compatibility
While the main goal of pit is to provide a git interface for single files, it can also be used to control several files and folders. This comes in handy if you have a configuration file which you want to track along with your script. pit is written in a way that the name parameter does not actually have to be an exisiting file. It can therefore serve as an alias for your project.
 
If you want to add a file to an existing pit archive you have to call `pit name add filename` and eventually `pit name git add filename`. You can `pit name pack` or `pit name clone` an existing git repository into a pit archive `.name.pit`. If you later want to convert it back into a git repository, you can simply `pit name unpack [path]` or just untar the pit archive (it is really just a tar archive).

**Important**: The multiple file compatibility of pit allows it in principal to be used on any git repository. Though keep in mind that the repository is stored in a temporary folder every time you issue a pit command. This is not only slow, you could also end up producing a huge amount of temporary files if you happen to abort the pit call before it finished.

*Note:* It would be possible to implement pit using loop device files to get rid of the packing/unpacking procedure.
###Naming
The name of pit was chosen to closely reassemble the name git. Since the `.git` folder is thrown into an archive like you throw s.th. into a pit, the choice is obvious. It can also be seen as acronym "put (it) in tar".
###Usage

`pit name git [gitargv]`

execute 'git gitargv' on pit archive with name 'name'

`pit name init`

create a pit archive with name 'name' (optionally based on a file with same name)

`pit name unpack [path]`

unpack pit archive to location at 'path' or if not specified the current directory

`pit name pack [path]`

pack git folder at 'path' (or current directory if not specified) into pit archive with name 'name'

`pit name clone gitlocation`

generates a pit archive from sources at gitlocation

`pit name add file`

add file named 'file' to pit archive 'name'

`pit name gitadd file`

like `pit name add file && pit name git add` but in one step (faster)
