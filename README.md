# Pod::Render
This module provides functionality to take a precompiled pod and generate
output based on templates. To the extent possible, all rendering specific (eg. html)
code is moved to templates.

Pod file names are assumed to have no spaces in them.

## Install
This module is in the [Perl 6 ecosystem](https://modules.perl6.org), so you install it in the usual way:
```
    zef install PodCache::Module
```

# SYNOPSIS
```perl6
use PodCache::Render;

my PodCache::Render $renderer .= new(
    :path<path-to-pod-cache>,
    :templates<path-to-templates>,
    :output<path-to-output>,
    :rendering<html>,
    :assets<path-to-assets-folder>,
    :config<path-to-config-folder>
    );
my $ok = $renderer.update-cache; # identify new or changed pod sources
exit note('The following sources failed to compile', $renderer.list-files('Failed').join("/n/t"))
    unless $ok;

# if the collection needs to be recreated
$renderer.create-collection;

# to update an existing Collection where render date < source date
$renderer.update-collection;

# to process known files
$renderer.process-cache('language/5to6-nutshell', 'language/intro');

# Utility  functions

$renderer.verbose = True; # presume output is required for testing
$renderer.templates-changed;
$renderer.gen-templates;
$renderer.generate-config-files;
$renderer.test-config;

# After `create-collection` or `update-collection`
$renderer.links-test; # expensive test of all links
say $renderer.report;
```

## new
    - instantiates object and verifies cache is present
    - creates or empties the output directory
    -  sets up templates from default or over-riding directory

## :path
    - location of perl6 compunit cache, as generated by Pod::To::Cached
    - defaults to '.pod-cache'

## :templates
    - location of templates root directory
    - defaults to 'resources/templates', which is where a complete set of templates exists

## :rendering
    - the type of rendering chosen
    - default is html, and refers to templates/html in which a complete set of templates exists
    - any other valid directory name can be used, eg md, so long as templates/md contains
    a complete set of templates

>It is possible to specify the template/rendering options with only those templates that
    need to be over-ridden.

## :output
    - the path where output is sent
    - if `output` does not exist, then it will be created.

## :assets
    - path to a directory which may have subdirectories, eg.  `js`, `css`, `images`
    - the subdirectories/files are copied to the `output` directory, so that `assets/js/file.js` is copied to
    `html/assets/js/file.js` assuming that `output` = `html`.
    - An exception is the `B<asset`/root> subdirectory. All items in `root` are copied to the `output` directory.
    For example, if `PodCache::Render $renderer .=new(:assets<assets`, :output<html>)> and `$?CWD/assets/root/favicon.ico`,
    then after rendering `$?CWD/html/` will contain `favicon.ico`

## :config
    -  path to a directory containing configuration files (see below)
    - configuration files are rendered into a html files with links to the pod files.

## :collection-unique
    - boolean default False
    - if true href links in <a> tags must all be relative to collection (podfile appended to local link)
    - if false, then links internal to the source need only be unique relative to the source

## :highlighter
    - code default undefined
    - if defined, then the code is expected to receive a String containing perl6 code
    and return a String of the same code highlighted in a form consistent with the rendering.

## create-collection
    - Creates a collection from scratch.
    - Erases all previous rendering files, rewrites the rendering database file
    - If the file ｢<config directory>/rendering.json｣ is absent, then update-collection will do the same
    - Generates the index files

## update-collection
    - Compares timestamp of sources in cache with timestamp of rendered files
    - Regenerates rendered files when source in cache is newer.
    - Regenerates the index files based on new files.

## report( :errors,  :links , :cache, :rendered )
    - Returns an array of strings containing information
    - no adverbs:  all link responses, all cache statuses, all files when rendered.
    - :errors (default = False):  Failed link responses, files with cache status Valid, Failed, Old; no rendering info
    - :links-only  (default = False): Supply link responses only.
    - :cache-only (default = False): ditto for cache reponses.
    - :just-rendered (default = False): the sources added by the most recent call to update-collection
    - :when-rendered (default = True ):  source and time rendered
    - If no adverbs are given, then it is assumed all are True

# Usage

To render a document cache to HTML:
    - place pod sources in `doc`,
    - create a writable directory `html/`
    - instantiate a Render object, (`$renderer`)
    - run create-collection (`$render.create-collection`)
    - verify whether there are problems to solve (`$renderer.report`)

## Customisation

### Sources

The cache and sources are managed using `Pod::To::Cache` module, and the source and repository names can be changed,
as documented in that module.

The source directory may contain subdirectories. The 'name' of a source is the `subdirectory/basename` of the source without an
extension, which are by default `pod | pod6`.

### Rendering

All of the rendering is done via mustache templates.

Each template can be over-ridden individually by setting the `:templates` option to a directory and placing the mustache file there.

Typically, the template `source-wrap.mustache` will be over-ridden in order to provide links to custom css, js, and image files.

The source-wrap template is called with the following elements:
-    :title generated from the pod file's V<=TITLE>
-    :subtitle generated from the pod file's V<=SUBTITLE>
-    :metadata generated from the pod file's V<=AUTHOR, =SUMMARY, etc >
-    :toc generated from the pod file's V<=HEAD>
-    :index generated from the pod file's V< X<> elements>
-    :footnotes generated from the pod file's V<N<> elements>
-    :body generated from the pod file
-    :path a string containing the original path of the POD6 file (if the doc-cache retains the information)

In order to see all the templates, instantiate a Render object pointing to a template directory, and run the `gen-templates` method.
The templates `toc` and `index` may need tweaking for custom Table of Contents and Index (local index to the source) rendering.

### CSS, JS, Images

All the contents (files and recursively subdirectories) in a directory provided to the `:assets` option upon instantiation
will be copied to the subdirectory `B<output`/assets/>, where B<output> is the directory for the rendered files.

# Configuration

By default - that is without any configuration file(s) - a "landing page" index file, called `index.B<ext`>, is generated
from the source cache with the documents
in the top directory of the cache listed by
TITLE, followed by the SUBTITLE, followed by the Table of Content for the cache file.
If the cache has subdirectories, then the name of the directory is made into a title, and the files under it are listed as above.

A separate file called `global-index.B<ext`> is also generated by default containing
the indexed elements from all the pod-files in the cache.

These two files are rendered into html (by default), but if a different rendering has been specified, they will follow those rendering
templates.

If a `config` directory is provided, Render will look for `*.yaml` files and consider them customised index files.

The structure of the index file is documented in the default files (see below for generating default files). However, if B<a customised rendered file>
is required, eg., a customised `index.html`, then the `index.yaml` file (where B<index> could be any name) should contain the
single line `source: R<filename.ext`>.

The R<filename.ext> should be the name of the file relative to the `Configuration` directory and it will be copied to the `Output`
directory.

Each configuration file will be converted from `name.yaml` to `name.B<ext`> where B<ext> is `html` by default, but could, eg,
be `md` if the rendering is to Markdown and templates are provided.

If there are sources in the document cache that are not included in customised `*.yaml` index files, then a `missing-sources.yaml`
configuration file will be generated and used to create an index file.

The indexation files are rendered using the templates `indexation-file` and `global-indexation-file`, respectively.
These templates can be over-ridden as required.

For more information, generate the default configuration files into the `config` directory (see below).

# Work Flow

    The work flow to create a document collection might be:
    - create the collection (which will generate default configuration files)
    - remove creation errors (in pod sources)
    - edit configuration files into more content oriented forms
    - edit templates to customise content
    - run <test-indices> method to ensure that config files contain all source names and no typos create an invalid source
    - add customised css, js, and images
    - when source files are edited run `update-collection` and check for errors using the `report`method
    - eg `die 'errors found: ' ~ $renderer.report(:all).join("\n") if +$renderer.report(:errors);`

# Utilities

## templates-changed
    - Generates a list of template names that have been over-ridden.
## gen-templates
    - 'templates/rendering' is interpreted as a directory, which must exist. All the mustache templates will be copied into it.
    - Only the templates required may be kept. Some templates, such as `zero` do not need to be over-ridden as there is no rendering data.
## generate-config-files
    - `:config` is a writable directory that must exist, defaults to `output`
    -
        the two index files `index.yaml` and `global-index.yaml` are generated in that directory. The intent is to provide templates for
        customised config files. For more information generate a template.

    - Care should be taken as any custom `index.yaml` or `global-index.yaml` files will be over-written by this method
    - The index files themselves are generated using the `indexation-file`/`global-indexation-file` templates
    - the extension of the final index files will be the same as `rendering`
    - the filename of the index file will be same as the +.yaml files in the config directory

## test-config-files
    - `config` is a directory that should contain the config files.
    - if no .yaml files are in the config directory, the method will throw a Fatal Exception.
    - each pod6 file will be read and the filenames from V<=item> lines will be compared to the files in the doc-cache
    - any file present in I<the doc-cache>, but B<not> included in I<a config file> will be output into a config file called `missing-sources.yaml`
    - any filename included in I<a config file>, but B<not> in I<the doc-cache>, will be listed in a file called `error.txt`

## LICENSE

You can use and distribute this module under the terms of the The Artistic License 2.0. See the LICENSE file included in this distribution for complete details.

The META6.json file of this distribution may be distributed and modified without restrictions or attribution.
