use lib 'lib';
use Test;
use PodCache::Render;
use PodCache::Processed;
use File::Directory::Tree;
use Data::Dump;

plan 10;
my $fn = 'format-code-index-test-pod-file_0';
diag 'Format Code X';

constant REP = 't/tmp/rep';
constant DOC = 't/tmp/doc';
constant OUTPUT = 't/tmp/html';

mktree OUTPUT unless OUTPUT.IO ~~ :d;
my PodCache::Processed $pr;

sub cache_test(Str $fn is copy, Str $to-cache --> PodCache::Processed ) {
    (DOC ~ "/$fn.pod6").IO.spurt: $to-cache;
    my PodCache::Render $ren .= new(:path( REP ), :output( OUTPUT ) );
    $ren.update-cache;
    $ren.processed-instance( :name($fn) );
}

$pr = cache_test(++$fn, q:to/PODEND/);
    =begin pod
    X<|behavior> L<http://www.doesnt.get.rendered.com>
    =end pod
    PODEND

#--MARKER-- Test 1
like $pr.pod-body.subst(/\s+/,' ',:g).trim, /
    'href="http://www.doesnt.get.rendered.com"'
    /, 'zero width with index passed';

$pr = cache_test(++$fn, q:to/PODEND/);
    =begin pod

    When indexing X<an item> the X<X format> is used.

    It is possible to index X<an item> in repeated places.
    =end pod
    PODEND

my $rv = $pr.pod-body.subst(/\s+/,' ',:g).trim;

#--MARKER-- Test 2
like $rv, /
    '<section name="___top">'
    \s* '<p>'
    \s* 'When indexing '
    \s* '<a name="an_item"></a>'
    \s* '<span class="index-entry">an item</span>'
    \s* 'the'
    \s* '<a name="x_format"></a>'
    \s* '<span class="index-entry">X format</span> is used.'
    .+ 'to index'
    \s* '<a name="an_item' .+ '></a>'
    \s* '<span class="index-entry">an item</span>'
    \s* 'in repeated places.'
    /, 'X format in text';

$rv = $pr.render-index.subst(/\s+/,' ',:g).trim;
#--MARKER-- Test 3
like $rv, /
    '<div id="index">'
    \s* '<h2 class="source-index">Index</h2>'
    \s* '<dl class="index">'
    \s*     '<dt>X format</dt>'
    \s*         '<dd><a href="#x_format">' .+ '</a></dd>'
    \s*     '<dt>an item</dt>'
    \s*         '<dd><a href="#an_item">' .+ '</a></dd>'
    \s*         '<dd><a href="#an_item_0">' .+ '</a></dd>'
    \s* '</dl>'
    \s* '</div>'
    /, 'index rendered later';

$pr = cache_test(++$fn, q:to/PODEND/);
    =begin pod

    When indexing X<an item|Define an item> another text can be used for the index.

    It is possible to index X<hierarchical items|defining,a term>with hierarchical levels.

    And then index the X<same place|Same,almost;Place> with different index entries.

    But X<|an entry can exist> without the text being marked.

    An empty X<> is ignored.
    =end pod
    PODEND

$rv = $pr.pod-body.subst(/\s+/,' ',:g).trim;

#--MARKER-- Test 4
like $rv, /
    'When indexing'
    \s* '<a name="define_an_item"></a>'
    \s * '<span class="index-entry">an item</span>'
    .+ 'to index'
    \s* '<a name="' .+ '></a>'
    \s * '<span class="index-entry">hierarchical items</span>'
    .+ 'index the'
    \s* '<a name="same' .+ '></a>'
    \s * '<span class="index-entry">same place</span>'
    .+ 'But' \s* '<a name' .+ '</a>' \s* 'without the text being marked.'
    .+ 'An empty' \s+ 'is ignored.'
    /,  'Text with indexed items correct';

$rv = $pr.render-index.subst(/\s+/,' ',:g).trim;
#--MARKER-- Test 5
like $rv, /
    '<dt>Define an item</dt>'
    /, 'index contains the right entry text';
#--MARKER-- Test 6
like $rv, /
    '<dt>defining</dt>' .* '<dd>' .+? 'a term' .+? '</dd>'
    /, 'index contains hierarchy';
#--MARKER-- Test 7
like $rv, /
    '<dt>Same</dt>'
    /, 'index contains Same';
#--MARKER-- Test 8
like $rv, /
    '<dt>Place</dt>'
    /, 'index contains Place';
#--MARKER-- Test 9
like $rv, /
    '<dt>an entry can exist</dt>'
    /, 'index contains entry of zero text marker';
$rv ~~ /  [ '<dt>' ~ '</dt>'  $<es> =(.+?)  .*? ]* $ /;
#--MARKER-- Test 10
is-deeply $<es>>>.Str, ['Define an item','Place','Same','an entry can exist','defining'], 'Entries match, nothing for the X<>';