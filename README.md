Delphi DOM HTML parser and converter
====================================

- Example 1 - [Parsing HTML string into a TDocument](#example1)
- Example 2 - [Get HTML text from a **TDocument**](#example2)
- Example 3 - [Get a string reprentation of the DOM tree](#example3)


Initialization
--------------

Today we see more and more email messages formatted as HTML. For me the email is plain text medium (with attachments) and I don't use WebBrowser or Mozilla object as a message browser in my [email client](http://dlg.krakow.pl/tabmail/). So I'm write quick and dirty HTML parser instead. It seems enough to parse email messages but some work is needed to shift them to more general purpose HTML parser.


Interface
---------

TDocument, TNode, TElement, TAttr etc. implement [DOM2](http://www.w3.org/DOM/DOMTR) Core.

THtmlParser produces TDocument from HTML string.

    class function Parse(const HtmlStr: TDomString): TDocument;

THtmlParser uses THtmlReader - an event-driven SAX-like interface that performs the actual processing of the html string.

To convert DOM tree to plain text or HTML use **TTextFormatter** or **THtmlFormatter** respectively.

Implementation
--------------

Parser is implemented as several modules:

- `DomCore.pas` - core DOM implementation
- `HmlParser.pas` - Parses HTML into a Document
- `HtmlReader.pas` - lexical analyzer for parsing HTML
- `Entities.pas` - HTML character definitions
- `HtmlTags.pas` - HTML tags attributes
- `Formatter.pas` - HTML DOM tree converters

Programming Guide
=================

<A name="example1"></A>**Example 1** &mdash; Parse HTML into **TDocument** object

To convert a string containing HTML, into a DOM **TDocument** object, use the **THTMLParser.Parse**:

```
var
   doc: TDocument;

   doc := THTMLParser.Parse('<!DOCTYPE html><HTML><BODY>Hello, world!</BODY></HTML>');
```

---------

<A name="example2"></A>**Example 2** &mdash; Get full HTML text from a **TDocument**


To convert a **TDocument** into an HTML string, use **THtmlFormatter.GetHTML** class in `Formatter.pas`:

```
var
   html: string;
   
html := THtmlFormatter.GetHTML(document);
```

returns:

```
<HTML>
  <BODY>Hello, world!</BODY>
</HTML>
```

------------

<A href="example3"></A>**Example 3** &mdash; Get a string reprentation of the DOM tree

Use the function **Formatter.DumpDOM** to get a representation of the DOM tree of a **Node**:

```
var
	s: string;
	doc: TDocument;

	//Get a sample html document
	s := 
			'<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">'+#13#10+
			'<html lang="en">'+#13#10+
			' <head>'+#13#10+
			'  <title>Sample page</title>'+#13#10+
			' </head>'+#13#10+
			' <body>'+#13#10+
			'  <h1>Sample page</h1>'+#13#10+
			'  <p>This is a <a href="demo.html">simple</a> sample.</p>'+#13#10+
			'  <!-- this is a comment -->'+#13#10+
			' </body>'+#13#10+
			'</html>';

	doc := THtmlParser.Parse(s);

	s := DumpDOM(doc);
```

The returned DOM string will be:

```
#document
├── DOCTYPE: html
╰── HTML lang="en"
    ├── HEAD
    │   ├── #text: "⏎␣␣"
    │   ├── TITLE
    │   │   ╰── #text: "Sample␣page"
    │   ╰── #text: "⏎␣"
    ├── #text: "⏎␣"
    ╰── BODY
        ├── #text: "⏎␣␣"
        ├── H1
        │   ╰── #text: "Sample␣page"
        ├── #text: "⏎␣␣"
        ├── P
        │   ├── #text: "This␣is␣a␣"
        │   ├── A href="demo.html"
        │   │   ╰── #text: "simple"
        │   ╰── #text: "␣sample."
        ├── #text: "⏎␣␣"
        ├── #comment:  this is a comment 
        ╰── #text: "⏎␣⏎"
```


Version History
---------------

**12/22/2021**

- Formatter.pas: Added DumpDOM function, which dumps a text-based tree of the document tree
- TBaseFormatter: Fixed node iteration so starts with the Document child nodes - including doctype
- TBaseFormatter: Added support to dump doctype nodes
- THtmlParser: Added static Parse(html) class function
- THtmlParser: GetMainElement now compares element tag names case insensitively
- THtmlParser: FindThisElement now compares element tag names case insensitively
- THtmlParser: ProcessDocType: DocType nodes are now correctly adds to the DOM tree itself,
               rather than just being a special attribute of the Document object
- THtmlParser: Removed ProcessNotation, since the event was removed from THtmlReader
- THtmlReader: Fixed ReadDocumentType method to correctly handle:
               - doctypes without either a publicId or systemID (e.g. HTML 5)
               - doctypes where only the SystemID is specified
- THtmlReader: Changed ReadDocumentType to LowerCase the doctype name
- THtmlReader: Changed ReadDocumentType so Doctype publicid and systemid can also be enclosed in APOSTROPHE (in addition to QUOTATION MARK)
- THtmlReader: Fixed ReadQuotedValue to not return the closing '"' character. (only used by doctype reading)
- THtmlReader: Removed OnNotation event; since it's never called and nobody seems to know what could possibly be
- THtmlTagList: CompareName now does a case insensitive comparison
- TURLSchemes: Schemes are now populated in the constructor (like THtmlTagList)
- DOMCore:
  - TDocumentType: removed Entities, Notations, and InternalSubsets (per HTML5)
  - TDocument: Removed DocType as an attribute, and is now correctly added to the DOM tree.
  - TNode: Fixed getElementById to still recursively ask child nodes even if Self node is not an Element (e.g. a Document)
  - TNode: Removed IsSupported (per HTML5)
  - TNamedNodeMap: GetNamedItem now compares node names case insensitively
  - TNamedNodeMap: getNamedItemNS now compares node names case insensitively
  - TDocument: CanInsert will now accept DOCUMENT_TYPE_NODE as a node that can be inserted
  - TDocument: GetDocType is now a convenience method (like GetDocumentElement) that finds the doctype child node for you
  - TDocument: CreateAttribute now lowercases the attribute name
  - TNode: Added TextContent property

**12/20/2021**

- Fixed TNode: NodeValue was not calling GetNodeValue getter
- fixed attribute lookups to be case insensitive (like everything else in html)
- fixed tag name normalization to UPPERCASE, the canonical form in the spec
        (https://www.w3.org/TR/DOM-Level-3-Core/core.html#ID-104682815)
        (https://dom.spec.whatwg.org/#dom-element-tagname)
- TNode: InsertBefore should only fail the WRONG_DOCUMENT_ERR check if the node actually has an ownerDocument assigned.
- DOMCore: Added TNodeType type
- InsertBefore will no longer reject a node if its OwnerDocument is nil
- TSearchNodeList: AcceptNode is now case insensitive to node local names
- TNamedNodeMap.GetNamedItem and GetNamedItemNS are no longer case sensitive
- TElement: constructor now canonically UPPERCASEs the element tag name
- TDocument: No longer takes a doctype in its constructor. DocType node is just another node added as a child of the Document
- DOMImplementation: Added CreateHtmlDocument; following the spec of what it should contain
- DOMImplementation: CreateDocument doctype parameter is now optional
- DOMImplementation: Changed HasFeature to return dummy True (per HTML5)
- Removed TDocumentType.Entities, Notations, and InternalSubset (per HTML5)


----------

**Original Homepage**: `http://htmlp.sourceforge.net/`
