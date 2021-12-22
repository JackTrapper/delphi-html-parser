unit HTMLParserTests;

interface

uses
	TestFramework, DomCore;

type
	THtmlParserTests = class(TTestCase)
	published
		procedure TestParseString;
		procedure TestParseString_Html4Transitional;
		procedure TestParseString_Html5;
		procedure TestParseString_TrailingTextAddedToBody;
		procedure TestParseString_TrailingTextAddedToBodyNewTextNode;
		procedure TestParseString_TrailingText_Fails;
		procedure TestParseString_CanReadAttributeValues;
		procedure TestParseString_AttrValueIsSameAsNodeValue;
		procedure TestParseString_DocTypes;
		procedure TestParseString_FailsToParse;
		procedure TestParseString_NodesAfterHtml;
	end;

implementation

uses
	HtmlParser, Formatter;

{ THtmlParserTests }

procedure THtmlParserTests.TestParseString;
var
	szHtml: string;
	doc: TDocument;
begin
	szHtml := '<HTML><BODY>Hello, world!</BODY></HTML>';

	doc := THtmlParser.Parse(szHtml);
	CheckTrue(doc <> nil);

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

	Status(DumpDOM(doc));

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

	Status(DumpDOM(doc));

	st := doc.getElementById('st');
	CheckTrue(st <> nil);

	CheckEquals('st', st.getAttribute('id'));
end;

procedure THtmlParserTests.TestParseString_DocTypes;

	procedure t(const DocType, ExpectedName, ExpectedPublicID, ExpectedSystemID: TDomString);
	var
		actualName, actualPublicID, actualSystemID: TDomString;
		doc: TDocument;
	begin
		doc := THtmlParser.Parse(DocType+'<HTML/>');
		CheckTrue(doc <> nil);

		Status(DumpDOM(doc));

		CheckEquals(ExpectedName, doc.DocType.NodeName);
		CheckEquals(ExpectedPublicID, doc.DocType.PublicID);
		CheckEquals(ExpectedSystemID, doc.DocType.SystemID);
	end;

begin
{	Recommended list of Doctype declarations
	https://www.w3.org/QA/2002/04/valid-dtd-list.html
}

//	HTML 5:
	t('<!DOCTYPE HTML>', 'HTML', '', '');
	t('<!DOCTYPE html>', 'HTML', '', '');
	t('<!doctype html>', 'HTML', '', '');

//	HTML 4.01
	t('<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">',
			'HTML',
			'-//W3C//DTD HTML 4.01//EN',
			'http://www.w3.org/TR/html4/strict.dtd');
	t('<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">',
			'HTML',
			'-//W3C//DTD HTML 4.01 Transitional//EN',
			'http://www.w3.org/TR/html4/loose.dtd');
	t('<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Frameset//EN" "http://www.w3.org/TR/html4/frameset.dtd">',
			'HTML',
			'-//W3C//DTD HTML 4.01 Frameset//EN',
			'http://www.w3.org/TR/html4/frameset.dtd');

//	XHTML 1.0
	t('<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">',
			'HTML', //converted to uppercase - as html should be
			'-//W3C//DTD XHTML 1.0 Strict//EN',
			'http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd');
	t('<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">',
			'HTML', //covnerted to uppercase, as html should be
			'-//W3C//DTD XHTML 1.0 Transitional//EN',
			'http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd');
	t('<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Frameset//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-frameset.dtd">',
			'HTML',
			'-//W3C//DTD XHTML 1.0 Frameset//EN',
			'http://www.w3.org/TR/xhtml1/DTD/xhtml1-frameset.dtd');

//	MathML 2.0
	t('<!DOCTYPE math PUBLIC "-//W3C//DTD MathML 2.0//EN" "http://www.w3.org/Math/DTD/mathml2/mathml2.dtd">',
			'MATH', //converted to uppercase, as html should be
			'-//W3C//DTD MathML 2.0//EN',
			'http://www.w3.org/Math/DTD/mathml2/mathml2.dtd');

//	MathML 1.0
	t('<!DOCTYPE math SYSTEM "http://www.w3.org/Math/DTD/mathml1/mathml.dtd">',
			'MATH', //converted to uppercase as html should be
			'', //no public - only system
			'http://www.w3.org/Math/DTD/mathml1/mathml.dtd');

//	SVG 1.1 Full
	t('<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">',
			'SVG', //converted to uppercase, as html should be
			'-//W3C//DTD SVG 1.1//EN',
			'http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd');
end;

procedure THtmlParserTests.TestParseString_FailsToParse;
var
	szHtml: string;
	doc: TDocument;
begin
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

	Status(DumpDom(doc));
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
	szHtml :=
		'<html>'+#13#10+
		'<body>'+#13#10+
		'	Hello, world!<BR>'+#13#10+
		' </body>'+#13#10+
		'</html>'+#13#10+
		'<!--Comment-->'+#13#10+
		'More text.'+#13#10+
		'<IMG>';

	Status(szHtml);

	doc := THtmlParser.Parse(szHtml);
	CheckTrue(doc <> nil);

	Status(DumpDOM(doc));
{
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

	Status(DumpDOM(doc));
{
	HTML
		BODY
			#text: "Hello, world! http://sourceforge.net/projects/htmlp?arg=0&arg2=0"
}
	CheckEquals(1, doc.ChildNodes.Length);
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

	Status(DumpDOM(doc));
{
	HTML
		BODY
			#text: "Hello, world!"
			BR
			#text: "http://sourceforge.net/projects/htmlp?arg=0&arg2=0"
}
	CheckEquals(1, doc.ChildNodes.Length);
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

	Status(DumpDOM(doc));
{
	HTML
		BODY
			#text: "Hello, world! http://sourceforge.net/projects/htmlp?arg=0'
}
	CheckEquals(1, doc.ChildNodes.Length);
end;

initialization
	TestFramework.RegisterTest('HTMLParser\THtmlParser', THtmlParserTests.Suite);

end.
