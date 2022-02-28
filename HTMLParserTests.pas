unit HTMLParserTests;

interface

uses
	TestFramework, DomCore;

type
	THtmlParserTests = class(TTestCase)
	published
		procedure TestCreateHtmlDocument;
		procedure TestParseString;
		procedure TestParseString_Html4Transitional;
		procedure TestParseString_Html5;
		procedure TestParseString_TrailingTextAddedToBody;
		procedure TestParseString_TrailingTextAddedToBodyNewTextNode;
		procedure TestParseString_TrailingText_Fails;
		procedure TestParseString_CanReadAttributeValues;
		procedure TestParseString_AttrValueIsSameAsNodeValue;
		procedure TestParseString_DocTypes;
		procedure TestParseString_DocTypes_LegacyAppCompat;
		procedure TestParseString_FailsToParse;
		procedure TestParseString_NodesAfterHtml;
		procedure TestInvalidFirstCharacterOfTagName;
		procedure TestNewHtmlDocumentHasHeadAndBody;
		procedure TestCustomElement;
	end;

	THtmlFormatterTests = class(TTestCase)
	published
		procedure TestGetHtml;
		procedure TestGetHtml_IncludesDocType;
		procedure TestAmpersandNotAlwaysEscaped;
		procedure TestCrashParser;
	end;

implementation

uses
	Html4Parser, HtmlParser, Formatter;

type
	TObjectHolder = class(TInterfacedObject)
	private
		FValue: TObject;
	public
		constructor Create(AObject: TObject);
		destructor Destroy; override;
	end;

function AutoFree(AObject: TObject): IUnknown;
begin
	if AObject <> nil then
		Result := TObjectHolder.Create(AObject)
	else
		Result := nil;
end;

{ THtmlParserTests }

procedure THtmlParserTests.TestCreateHtmlDocument;
var
	doc: TDocument;
begin
	//The simple DOMImplementation class function to make us a new empty html document
	doc := DOMImplementation.createHtmlDocument('');
	AutoFree(doc);
	CheckTrue(doc <> nil);
end;

procedure THtmlParserTests.TestInvalidFirstCharacterOfTagName;
var
	s: string;
	doc: TDocument;
begin
(*
	https://html.spec.whatwg.org/#parsing

	invalid-first-character-of-tag-name
	This error occurs if the parser encounters a code point that is not an ASCII alpha
	where first code point of a start tag name or an end tag name is expected.
	If a start tag was expected such code point and a preceding U+003C (<) is treated as
	text content, and all content that follows is treated as markup.
	Whereas, if an end tag was expected, such code point and all content that follows up
	to a U+003E (>) code point (if present) or to the end of the input stream is treated
	as a comment.

	For example, consider the following markup:

		<42></42>

	This will be parsed into:

	html
		- head
		- body
			- #text: <42>
			- #comment: 42
*)
	doc := THtmlParser.Parse(s);
end;

procedure THtmlParserTests.TestNewHtmlDocumentHasHeadAndBody;
var
	doc: TDocument;
begin
{
	Spec has a DOMImplementation.CreateHtmlDocument(title?) method,
	and it creates a head a body node automatically.

	In fact, if you parse an empty string as html, you will still still
	a document with HEAD and BODY elements.
}
	doc := DOMImplementation.CreateHtmlDocument;
	AutoFree(doc);

	CheckTrue(doc <> nil);
	CheckTrue(doc.Head <> nil);
	CheckTrue(doc.Body <> nil);
end;

procedure THtmlParserTests.TestParseString;
var
	szHtml: string;
	doc: TDocument;
begin
	szHtml := '<HTML><BODY>Hello, world!</BODY></HTML>';

	doc := THtmlParser.Parse(szHtml);
	CheckTrue(doc <> nil);
	AutoFree(doc);

	Status(DumpDOM(doc));
	{
		HTML
			BODY
				#text: "Hello, world!"
	}
	CheckEquals(1, doc.ChildNodes.Length);
end;

procedure THtmlParserTests.TestParseString_AttrValueIsSameAsNodeValue;
var
	doc: TDocument;
	span: TElement;
	attr: TAttr;
begin
{
	If you have an ATTRIBUTE (TAttr) node, then

		attr.NodeName === attr.Name
		attr.NodeValue === attr.Value

	In other words:

		attr.NodeName is an alias of attr.Name
		attr.NodeValue is an alias of attr.Value

	Which HTMLParser fails.
}
	doc := THtmlParser.Parse('<SPAN id="st">Hello, world!</SPAN');
	CheckTrue(doc <> nil);

	Status(#13#10+'DOM tree'+#13#10+'----------'+DumpDOM(doc));

	span := doc.getElementById('st') as TElement;
	CheckTrue(span <> nil);

	attr := span.Attributes.getNamedItem('id') as TAttr;
	CheckTrue(attr <> nil);

	CheckEquals(attr.name, attr.NodeName);
	CheckEquals(attr.value, attr.NodeValue);
end;

procedure THtmlParserTests.TestParseString_CanReadAttributeValues;
var
	szHtml: string;
	doc: TDocument;
	st: TElement;
begin
	szHtml :=
			'<html>'+#13#10+
			'<body>'+#13#10+
			'<div id="st">'+#13#10+
			'</div>'+#13#10+
			'</body>'+#13#10+
			'</html>';

	doc := THtmlParser.Parse(szHtml);
	CheckTrue(doc <> nil);

	Status(#13#10+'DOM tree'+#13#10+'----------'+DumpDOM(doc));

	st := doc.getElementById('st');
	CheckTrue(st <> nil);

	CheckEquals('st', st.getAttribute('id'));
end;

procedure THtmlParserTests.TestParseString_DocTypes;

	procedure t(const DocType, ExpectedName, ExpectedPublicID, ExpectedSystemID: TDomString);
	var
		doc: TDocument;
	begin
		doc := THtmlParser.Parse(DocType+'<HTML/>');
		CheckTrue(doc <> nil);

		Status(DumpDOM(doc));

		CheckNotNull(doc.DocType, 'doc.DocType');
		if doc.DocType = nil then
			Exit;
		CheckEquals(ExpectedName, doc.DocType.NodeName, DocType);
		CheckEquals(ExpectedPublicID, doc.DocType.PublicID, DocType);
		CheckEquals(ExpectedSystemID, doc.DocType.SystemID, DocType);
	end;

begin
{	Recommended list of Doctype declarations
	https://www.w3.org/QA/2002/04/valid-dtd-list.html
}

//	HTML 5:
	t('<!DOCTYPE html>', 'html', '', '');
	t('<!DOCTYPE HTML>', 'html', '', ''); //doctype names should be converted to lowercase during parsing
	t('<!doctype html>', 'html', '', ''); //doctype keyword is case insensitive
	t('<!dOcTyPe html>', 'html', '', ''); //doctype keyword is case insensitive

//	HTML 4.01
	t('<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">',
			'html',
			'-//W3C//DTD HTML 4.01//EN',
			'http://www.w3.org/TR/html4/strict.dtd');
	t('<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">',
			'html',
			'-//W3C//DTD HTML 4.01 Transitional//EN',
			'http://www.w3.org/TR/html4/loose.dtd');
	t('<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Frameset//EN" "http://www.w3.org/TR/html4/frameset.dtd">',
			'html',
			'-//W3C//DTD HTML 4.01 Frameset//EN',
			'http://www.w3.org/TR/html4/frameset.dtd');

//	XHTML 1.0
	t('<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">',
			'html',
			'-//W3C//DTD XHTML 1.0 Strict//EN',
			'http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd');
	t('<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">',
			'html',
			'-//W3C//DTD XHTML 1.0 Transitional//EN',
			'http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd');
	t('<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Frameset//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-frameset.dtd">',
			'html',
			'-//W3C//DTD XHTML 1.0 Frameset//EN',
			'http://www.w3.org/TR/xhtml1/DTD/xhtml1-frameset.dtd');

//	MathML 2.0
	t('<!DOCTYPE math PUBLIC "-//W3C//DTD MathML 2.0//EN" "http://www.w3.org/Math/DTD/mathml2/mathml2.dtd">',
			'math',
			'-//W3C//DTD MathML 2.0//EN',
			'http://www.w3.org/Math/DTD/mathml2/mathml2.dtd');

//	MathML 1.0
	t('<!DOCTYPE math SYSTEM "http://www.w3.org/Math/DTD/mathml1/mathml.dtd">',
			'math',
			'', //no public - only system
			'http://www.w3.org/Math/DTD/mathml1/mathml.dtd');

//	SVG 1.1 Full
	t('<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">',
			'svg',
			'-//W3C//DTD SVG 1.1//EN',
			'http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd');
end;

procedure THtmlParserTests.TestParseString_DocTypes_LegacyAppCompat;

	procedure t(const DocType, ExpectedName, ExpectedPublicID, ExpectedSystemID: TDomString);
	var
		doc: TDocument;
	begin
		doc := THtmlParser.Parse(DocType+'<HTML/>');
		CheckTrue(doc <> nil);

		Status(DumpDOM(doc));

		CheckNotNull(doc.DocType, 'doc.DocType');
		if doc.DocType = nil then
			Exit;
		CheckEquals(ExpectedName, doc.DocType.NodeName, DocType);
		CheckEquals(ExpectedPublicID, doc.DocType.PublicID, DocType);
		CheckEquals(ExpectedSystemID, doc.DocType.SystemID, DocType);
	end;

begin
{
	HTML 5 legacy appcompat strings
	https://html.spec.whatwg.org/#doctype-legacy-string

	For the purposes of HTML generators that cannot output HTML markup with the
	short DOCTYPE "<!DOCTYPE html>", a DOCTYPE legacy string may be inserted
	into the DOCTYPE.
}

	t('<!DOCTYPE html SYSTEM "about:legacy-compat">',
			'html', '', 'about:legacy-compat');

	//Apostrophe character is also allowed
	t('<!DOCTYPE html SYSTEM ''about:legacy-compat''>',
			'html', '', 'about:legacy-compat');
end;

procedure THtmlParserTests.TestParseString_FailsToParse;
var
	szHtml: string;
	doc: TDocument;
begin
{
	In the past this was a sample HTML page that refused to parse.
}
	szHtml :=
			'<HTML>'+#13#10+
			'<BODY>'+#13#10+
			'<IMG	HREF="\"'+#13#10+
			'		tppabs="default.asp?PR=win2000&FR=0&SD=GN&LN=EN-US&">'+#13#10+
			'	Frequently Asked Questions'+#13#10+
			'</A>'+#13#10+
			'</BODY>'+#13#10+
			'</HTML>';

	Status(szHtml);

	doc := THtmlParser.Parse(szHtml);
	CheckTrue(doc <> nil);

	Status(#13#10+'DOM tree'+#13#10+'----------'+DumpDOM(doc));
end;

procedure THtmlParserTests.TestParseString_Html4Transitional;
var
	szHtml: string;
	doc: TDocument;
begin
	szHtml :=
			'<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">'+#13#10+
			'<HTML>'+#13#10+
			'<BODY>'+#13#10+
			'Hello, world!'+#13#10+
			'</BODY>'+#13#10+
			'</HTML>';

	Status(szHtml);

	doc := THtmlParser.Parse(szHtml);
	CheckTrue(doc <> nil);
	Status(DumpDOM(doc));
{
	#doctype HTML
	HTML
		BODY
			#text "Hello, world!"

}
	CheckEquals(2, doc.ChildNodes.Length, 'Document should have only two top level elements: doctype and html. Known bug that HTML Parser does not eliminate whitespace'); //doctype and html
end;

procedure THtmlParserTests.TestParseString_Html5;
var
	szHtml: string;
	doc: TDocument;
begin
{
	HTML5 doctype breaks processing
	https://sourceforge.net/p/htmlp/support-requests/2/

	> The unit nicely precesses HTML4 doctype, like
	>
	>     <!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
	>
	> But simple HTML5:
	>
	>     <!doctype html>
	>
	> breaks whole processing, because quote not found.
	>
	> My quick fix in function THtmlReader.ReadDocumentType:
	>
	>     if (FHtmlStr[FPosition]='"') or (FHtmlStr[FPosition]='''') then // <-- added
	>        if not ReadQuotedValue(FPublicID) then
	>           Exit;
}
	szHtml :=
			'<!doctype html>'+#13#10+
			'<HTML>'+#13#10+
			'<BODY>'+#13#10+
			'Hello, world!'+#13#10+
			'</BODY>'+#13#10+
			'</HTML>';

	doc := THtmlParser.Parse(szHtml);
	CheckTrue(doc <> nil);

	Status(DumpDOM(doc));

{
	#doctype HTML
	HTML
		BODY
			#text "Hello, world!"
}
	CheckEquals(2, doc.ChildNodes.Length, 'Document should have only two top level elements: doctype and html. Known bug that HTML Parser does not eliminate whitespace'); //doctype and html
end;

procedure THtmlParserTests.TestParseString_NodesAfterHtml;
var
	szHtml: string;
	doc: TDocument;
begin
	szHtml := '<html><body>Hello, world!</body></html><IMG>';

	Status(szHtml);

	doc := THtmlParser.Parse(szHtml);
	CheckTrue(doc <> nil);

	Status(#13#10+'DOM tree'+#13#10+'----------'+DumpDOM(doc));
{
	DOM tree should be:

	HTML
		BODY
			#text: "Hello, world!"
			BR
			#comment: "Comment"
			#text: "More text."
			IMG
}
	CheckEquals(1, doc.ChildNodes.Length);
end;

procedure THtmlParserTests.TestParseString_TrailingTextAddedToBody;
var
	szHtml: string;
	doc: TDocument;
begin
{
	Text added after the body needs to be retroactively added to the end of the body node.
	If the last child node of the body is a #text node, then the text is appended to that node's text
}
	szHtml :=
			'<HTML>'+#13#10+
			'<BODY>'+#13#10+
			'Hello, world!'+#13#10+
			'</BODY>'+#13#10+
			'</HTML>'+#13#10+#13#10+

			'http://sourceforge.net/projects/htmlp?arg=0';

	Status(szHtml);

	doc := THtmlParser.Parse(szHtml);
	CheckTrue(doc <> nil);

	Status(#13#10+
			'DOM tree'+#13#10+
			'----------'+#13#10+
			DumpDOM(doc));
{
	HTML
		BODY
			#text: "Hello, world! http://sourceforge.net/projects/htmlp?arg=0&arg2=0"
}
	CheckEquals(1, doc.ChildNodes.Length, 'Document should have only one top level element: html. Known bug that HTML Parser does not move nodes after body to be a child of body');
end;

procedure THtmlParserTests.TestParseString_TrailingTextAddedToBodyNewTextNode;
var
	szHtml: string;
	doc: TDocument;
begin
{
	Text added after the body needs to be retroactively added to the end of the body node.
	If the last child node of the body is a #text node, then the text is appended to that node's text
}
	szHtml :=
			'<HTML>'+#13#10+
			'<BODY>'+#13#10+
			'Hello, world!<BR>'+#13#10+
			'</BODY>'+#13#10+
			'</HTML>'+#13#10+#13#10+

			'http://sourceforge.net/projects/htmlp?arg=0';

	Status(szHtml);

	doc := THtmlParser.Parse(szHtml);
	CheckTrue(doc <> nil);

	Status(#13#10+'DOM tree'+#13#10+'----------'+DumpDOM(doc));
{
	HTML
		BODY
			#text: "Hello, world!"
			BR
			#text: "http://sourceforge.net/projects/htmlp?arg=0&arg2=0"
}
	CheckEquals(1, doc.ChildNodes.Length, 'Document should have only one top level element: html. Known bug that HTML Parser does not add elements after body to the end of body (nor does it consolidate text nodes');
end;

procedure THtmlParserTests.TestParseString_TrailingText_Fails;
var
	szHtml: string;
	doc: TDocument;
begin
{
	From: https://sourceforge.net/p/htmlp/bugs/5/

	If a document has plaintext outside html markup,
	and that plaintext is a url with args passed to it,
	then the doc isn't parsed.

	For example, if the plaintext part is sometyhing like this:

		http://sourceforge.net/projects/htmlp?arg=0

	it works fine. But if it's like this:

		http://sourceforge.net/projects/htmlp?arg=0&arg2=0

	then it doesn't parse at all.
}
	szHtml :=
			'<HTML>'+#13#10+
			'<BODY>'+#13#10+
			'Hello, world!'+#13#10+
			'</BODY>'+#13#10+
			'</HTML>'+#13#10+#13#10+

			'http://sourceforge.net/projects/htmlp?arg=0';

	Status(szHtml);

	doc := THtmlParser.Parse(szHtml);
	CheckTrue(doc <> nil);

	Status(#13#10+'DOM tree'+#13#10+'----------'+DumpDOM(doc));
{
	HTML
		BODY
			#text: "Hello, world! http://sourceforge.net/projects/htmlp?arg=0'
}
	CheckEquals(1, doc.ChildNodes.Length, 'Document should have only one top level elements: html. Known bug that HTML Parser does not move nodes after body to the end of body');
end;

{ THtmlFormatterTests }

procedure THtmlFormatterTests.TestAmpersandNotAlwaysEscaped;
var
	szHtml: string;
	doc: TDocument;
const
	ExpectedHTML =
		'<html>'+#13#10+
		'<head></head>'+#13#10+
		'<body>'+#13#10+
		'	<a href="?bill&amp;ted">Bill and Ted</a>'+#13#10+
		'</body>'+#13#10+
		'</html>';
begin
{
	Start: <A href="?bill&ted">Bill and Ted</A>

	It is not an error to leave the & unescaped, because &ted; is not a named character reference.
	If we parse it, the value of the href attribute is "?bill&ted".

	If we get the HTML back, then it should also realize that it doesn't need to escape it:

	Bad:  <a href="?bill&amp;ted">Bill and Ted</a>
	Good: <a href="?bill&ted">Bill and Ted</a>

	Correct HTML5
	=============

	#document
	- HTML
		- HEAD
		- BODY
		 - A href="?bill&ted"
			- #text: "Bill and Ted"
}
	szHtml := '<A href="?bill&ted">Bill and Ted</A>';
	Status(
			'Original HTML'+#13#10+
			'-------------'+#13#10+
			szHtml);

	doc := THtmlParser.Parse(szHtml);
	CheckTrue(doc <> nil);

	Status(#13#10+
			'DOM'+#13#10+
			'----------------'+#13#10+
			DumpDOM(doc));

	//doc/body/a.href
	CheckEquals('?bill&ted', TElement(doc.Body.ChildNodes[0]).getAttribute('href'));

	CheckEquals('Bill and Ted', doc.Body.ChildNodes[0].ChildNodes[0].NodeValue);
end;

procedure THtmlFormatterTests.TestCrashParser;
var
	s: string;
	doc: TDocument;
begin
	s := '<D';
	Status('Original HTML'+#13#10+
			 '=============');

{
	The correct DOM tree for '<D' is:

		#document
			head
			body

	And that's it.

	Except this exposes a bug in our parser. At the time of parsing the <D, is before
		the HTML element.

		Line 1: <D

	So omit invalid tags if they're before HTML?
	Except them if hte 2nd line is <html>:

		Line 1: <D
		Line 2: <HTML>

	then the DOM retroactively does add it to body:

		#document
			- HEAD
			- BODY
				- D <html=""




}
	doc := THtmlParser.Parse(s);
	CheckTrue(doc <> nil);
	doc.Free;
end;

procedure THtmlFormatterTests.TestGetHtml;
var
	s: string;
	doc: TDocument;
begin
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
	try
		s := THtmlFormatter.GetHtml(doc);
	finally
		doc.Free;
	end;

	Status('Recovered HTML: '+#13#10+s);

	CheckTrue(s <> '');
end;

procedure THtmlFormatterTests.TestGetHtml_IncludesDocType;
var
	s: string;
	doc: TDocument;
begin
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
	try
		s := THtmlFormatter.GetHtml(doc);
	finally
		doc.Free;
	end;

	Status('Recovered HTML: '+#13#10+s);

	CheckTrue(s <> '');

	CheckEquals('<!DOCTYPE', Copy(s, 1, 9));
end;

procedure THtmlParserTests.TestCustomElement;
var
	html: string;
	doc: TDocument;
begin
	html := '<oofy>adsfadf</oofy>';

	doc := THtmlParser.Parse(html);
	CheckTrue(doc <> nil);
	AutoFree(doc);
end;


{ TObjectHolder }

constructor TObjectHolder.Create(AObject: TObject);
begin
	inherited Create;

	FValue := AObject;
end;

destructor TObjectHolder.Destroy;
begin
	FValue.Free;
	FValue := nil;

	inherited;
end;

initialization
	TestFramework.RegisterTest('HTMLParser\THtmlParser', THtmlParserTests.Suite);
	TestFramework.RegisterTest('HTMLParser\THtmlFormatter', THtmlFormatterTests.Suite);

end.
