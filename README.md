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

- Core.pas - core DOM implementation
- Entities.pas - HTML character definitions
- HmlParser.pas - HTML parser
