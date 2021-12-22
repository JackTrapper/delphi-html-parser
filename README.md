Delphi DOM HTML parser and converter
====================================

Initialization
--------------

Today we see more and more email messages formatted as HTML. For me the email is plain text medium (with attachments) and I don't use WebBrowser or Mozilla object as a message browser in my [email client](http://dlg.krakow.pl/tabmail/). So I'm write quick and dirty HTML parser instead. It seems enough to parse email messages but some work is needed to shift them to more general purpose HTML parser.

To-Do list:

- less restrictive when parsing poorly formatted HTML
- increase speed
- smarter conversion to plain text

Interface
---------

TDocument, TNode, TElement, TAttr etc. implements [DOM2](http://www.w3.org/DOM/DOMTR) Core.

THtmlParser produces TDocument from HTML string.

    function parseString(const HtmlStr: TDomString): TDocument;

THtmlParser uses THtmlReader a event driven SAX-like interface.

To convert DOM tree to plain text or HTML use TTextFormatter or THtmlFormatter respectively.

Implementation
--------------

Parser is implemented as several modules:

- `DomCore.pas` - core DOM implementation
- `Entities.pas` - HTML character definitions
- `HtmlTags.pas` - HTML tags atributes
- `HtmlReader.pas` - lexical analyzer
- `HmlParser.pas` - HTML parser
- `Formatter.pas` - HTML DOM tree converters

Sample Usage
============

1. Parse string into **TDocument**
 
To convert a string containing HTML text, into a **TDocument** object, use the **THTMLParser** object. 

```
var
   doc: TDocument;
   
doc := THTMLParser.Parse('<HTML><BODY>Hello, world!</BODY></HTML');
```

2. Get full HTML text from a **TDocument**

To convert a **TDocument** into an HTML string, use the **THtmlFormatter** class in `Formatter.pas`:

```
var
   html: string;
   
html := THtmlFormatter.OuterHtml(doc);
```


Version History
===============

12/22/2021
----------

- Formatter.pas: Added DumpDOM function, which dumps a text-based tree of the document tree
- THtmlParser: Added static Parse(html) class function
- THtmlParser: GetMainElement now compares element tag names case insensitively
- THtmlParser: FindThisElement now compares element tag names case insensitively
- THtmlParser: ProcessDocType: DocType nodes are now correctly adds to the DOM tree itself,
               rather than just being a special attribute of the Document object
- THtmlParser: Removed ProcessNotation, since the event was removed from THtmlReader
- THtmlReader: Fixed ReadDocumentType method to correctly handle:
               - doctypes without either a publicId or systemID (e.g. HTML 5)
               - doctypes where only the SystemID is specified
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

12/20/2021
----------

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
