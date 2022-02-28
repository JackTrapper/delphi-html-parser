unit Html4Parser;

interface

uses
	DomCore, HtmlReader, HtmlTags;

{
	Parses an HTML string, and generates a new TDocument object.

	This class uses THTMLReader, and its SAX-like eventing system,
	to build a TDocument from the supplied HTML string.


	Sample usage
	------------

	var
		doc: TDocument;

		doc := THtml4Parser.Parse('<HTML><BODY>Hello, world!</BODY></HTML>');


	TODO
	----
		- Add a ParseStream static method (requires THTMLReader to support streams)
		- Nodes added after the final BODY are appended as a child of the BODY
		- If the final node of the BODY is a #text node, and we're appending a #text
		  node, consolidate the text nodes
		- nodes added before the body are appended to the body

Version History
===============

12/30/2021
	- If we've already processed a doctype node, ignore any subsequent ones
	- Drop any whitespace we encounter before the HEAD element
	- if a text node appears before the BODY element, then switch immediately to the BODY
}

type
	THtml4Parser = class
	private
		FHtmlReader: THtmlReader;
		FHtmlDocument: TDocument;
//			FHead: TElement;
			FBody: TElement;
		FInBody: Boolean;
		FCurrentNode: TNode;
		FCurrentTag: THtmlTag;

		function RequireHtmlElement: TElement;
		function RequireHeadElement: TElement;
		function RequireBodyElement: TElement;

		function FindParent(TagNumber: TTagID): TElement;
		function FindParentElement(tagList: THtmlTagSet): TElement;
		function GetDefaultParent(TagNumber: TTagID): TNode;
		function FindTableParent: TElement;
		function FindThisElement(FindTagName: TDomString): TElement;

		procedure LogFmt(const Fmt: string; const Args: array of const);

		//HtmlReader SAX callback handlers
		procedure ProcessDocType(Sender: TObject);			// <!doctype html PUBLIC "[publicID]" "[systemID]">
		procedure ProcessElementStart(Sender: TObject);		// <DIV  - the start tag of an element
		procedure ProcessElementEnd(Sender: TObject);		// <DIV> - the end of the start tag of an element
		procedure ProcessEndElement(Sender: TObject);		// </DIV> - the end tag of an element
		procedure ProcessAttributeStart(Sender: TObject);	// [nodeName]="..."
		procedure ProcessAttributeValue(Sender: TObject);	// id=[NodeValue]
		procedure ProcessAttributeEnd(Sender: TObject);
		procedure ProcessTextNode(Sender: TObject);
		procedure ProcessComment(Sender: TObject);
		//procedure ProcessEntityReference(Sender: TObject); removed in HTML5
		//procedure ProcessCDataSection(Sender: TObject);
	protected
		function ParseString(const htmlStr: TDomString): TDocument;
		property HtmlDocument: TDocument read FHtmlDocument;
	public
		constructor Create;
		destructor Destroy; override;

		class function Parse(const HtmlStr: TDomString): TDocument;
	end;

implementation

uses
	{IFDEF UnitTests}HtmlParserTests,{ENDIF} SysUtils, Windows;

const
	htmlTagName = 'html';
	headTagName = 'head';
	bodyTagName = 'body';

	SBoolean: array[Boolean] of string = ('False', 'True');

constructor THtml4Parser.Create;
begin
	inherited Create;

	FHtmlReader := THtmlReader.Create;
	with FHtmlReader do
	begin
		OnDocType := 						ProcessDocType; 					//"<!DOCTYPE ..."
		OnElementEnd := 					ProcessElementEnd;   			//"<P ...
		OnElementStart := 				ProcessElementStart;				//"<P>
		OnEndElement := 					ProcessEndElement;				//"</P>"
		OnAttributeStart := 				ProcessAttributeStart;
		OnAttributeValue :=				ProcessAttributeValue;
		OnAttributeEnd := 				ProcessAttributeEnd;
		OnTextNode := 						ProcessTextNode;
		OnComment := 						ProcessComment;
//		OnEntityReference := 			ProcessEntityReference;			//Removed in HTML5
//		OnCDataSection := 				ProcessCDataSection;				//CDATA doesn't happen in HTML, only XML (i.e. SVG and MathML). HTML treats <![CDATA[...]]> sections as comments
	end
end;

destructor THtml4Parser.Destroy;
begin
	FreeAndNil(FHtmlReader);
	inherited Destroy
end;

function THtml4Parser.GetDefaultParent(TagNumber: TTagID): TNode;
begin
{
	Get the default fallback position a node should go under:

	HEAD, BODY ==> HTML
	HeadTags ==> HEAD (if we've not yet reached the BODY)
	(else)   ==> BODY

	TODO: Once we have left the HEAD element, we never return.
	At that point every element is added to BODY, even if it's TITLE, LINK, META, etc.
}
	if TagNumber in [HTML_TAG] then
	begin
		//HTML go under the document
		Result := FHtmlDocument; //document isn't an Element, it descends from Node
	end
	else if TagNumber in [HEAD_TAG, BODY_TAG] then
	begin
		//HEAD and BODY go under the HTML documentElement.
		Result := RequireHtmlElement;
	end
	else if (TagNumber in HeadTags) and (FHtmlDocument.Body = nil) then
	begin
		//If it's something that can go in the HEAD, and we've not yet moved onto the BODY, add it to the HEAD.
		RequireHeadElement;

		if TagNumber in NeedFindParentTags + BlockTags then
			Result := FindParent(TagNumber)
		else
			Result := nil;

		if Result = nil then
			Result := HtmlDocument.Head;
	end
	else
	begin
		//It's going into the BODY somewhere.
		RequireBodyElement;

		if TagNumber in NeedFindParentTags + BlockTags then
			Result := Self.FindParent(TagNumber)
		else
			Result := FCurrentNode;

		if Result = nil then
			Result := FHtmlDocument.Body;
	end
end;

function THtml4Parser.FindParent(TagNumber: TTagID): TElement;
begin
	if (TagNumber = P_TAG) or (TagNumber in BlockTags) then
		Result := FindParentElement(BlockParentTags)
	else if TagNumber = LI_TAG then
		Result := FindParentElement(ListItemParentTags)
	else if TagNumber in [DD_TAG, DT_TAG] then
		Result := FindParentElement(DefItemParentTags)
	else if TagNumber in [TD_TAG, TH_TAG] then
		Result := FindParentElement(CellParentTags)
	else if TagNumber = TR_TAG then
		Result := FindParentElement(RowParentTags)
	else if TagNumber = COL_TAG then
		Result := FindParentElement(ColParentTags)
	else if TagNumber in [COLGROUP_TAG, THEAD_TAG, TFOOT_TAG, TBODY_TAG] then
		Result := FindParentElement(TableSectionParentTags)
	else if TagNumber = TABLE_TAG then
		Result := FindTableParent
	else if TagNumber = OPTION_TAG then
		Result := FindParentElement(OptionParentTags)
	else if TagNumber in [HEAD_TAG, BODY_TAG] then
		Result := FHtmlDocument.documentElement as TElement
	else
		Result := nil;
end;

function THtml4Parser.FindParentElement(tagList: THtmlTagSet): TElement;
var
	node: TNode;
	htmlTag: THtmlTag;
begin
	node := FCurrentNode;
	while node.NodeType = ELEMENT_NODE do
	begin
		htmlTag := HtmlTagList.GetTagByName(node.NodeName);

		if htmlTag.Number in tagList then
		begin
			Result := node as TElement;
			Exit
		end;

		//Don't go higher than the body (if we're already in the body)
		if htmlTag.Number = BODY_TAG then
		begin
			Result := node as TElement;
			Exit;
		end;

		node := node.ParentNode
	end;
	Result := nil
end;

function THtml4Parser.FindTableParent: TElement;
var
	node: TNode;
	htmlTag: THtmlTag;
begin
	node := FCurrentNode;
	while node.NodeType = ELEMENT_NODE do
	begin
		htmlTag := HtmlTagList.GetTagByName(node.NodeName);
		if (htmlTag.Number = TD_TAG) or (htmlTag.Number in BlockTags) then
		begin
			Result := node as TElement;
			Exit
		end;
		node := node.ParentNode
	end;

	Result := FHtmlDocument.Body;
end;

function THtml4Parser.FindThisElement(FindTagName: TDomString): TElement;
var
	node: TNode;
begin
{
	Starting from CurrentNode, walk up the tree looking for an Element with a tagName of FindTagName.
}
	node := FCurrentNode;
	while node.NodeType = ELEMENT_NODE do
	begin
		Result := node as TElement;
		if SameText(Result.tagName, FindTagName) then
			Exit;
		node := node.ParentNode
	end;
	Result := nil
end;

procedure THtml4Parser.LogFmt(const Fmt: string; const Args: array of const);
//var
//	s: string;
begin
	if IsDebuggerPresent then
	begin
//		s := Format(Fmt, Args);
//		OutputDebugString(PChar('[THtml4Parser] '+s));
	end;
end;

procedure THtml4Parser.ProcessAttributeEnd(Sender: TObject);
begin
	LogFmt('ProcessAttributeEnd', []);

	FCurrentNode := (FCurrentNode as TAttr).ownerElement
end;

procedure THtml4Parser.ProcessAttributeStart(Sender: TObject);
var
	attr: TAttr;
begin
	LogFmt('ProcessAttributeStart (%s=...)', [FHtmlReader.NodeName]);

	attr := FHtmlDocument.createAttribute(FHtmlReader.nodeName);
	(FCurrentNode as TElement).setAttributeNode(attr);
	FCurrentNode := attr
end;

procedure THtml4Parser.ProcessAttributeValue(Sender: TObject);
var
	parent: TNode;
begin
	LogFmt('ProcessAttributeValue value="%s"', [FHtmlReader.nodeValue]);

	parent := FCurrentNode;
	if parent = nil then
		raise Exception.Create('Attempt to add attribute value when current node is nil');
	if parent.NodeType <> ATTRIBUTE_NODE then
		raise Exception.Create('Attempt to add attribute value when current node is not an ATTRIBUTE node');

	parent.NodeValue := FHtmlReader.nodeValue;
end;

(*procedure THtml4Parser.ProcessCDataSection(Sender: TObject);
var
	CDataSection: TCDataSection;
begin
	LogFmt('ProcessCDataSection (%s)', [FHtmlReader.nodeValue]);

	CDataSection := FHtmlDocument.createCDATASection(FHtmlReader.nodeValue);
	FCurrentNode.AppendChild(CDataSection)
end;*)

procedure THtml4Parser.ProcessComment(Sender: TObject);
var
	comment: TComment;
begin
	LogFmt('ProcessComment (%s)', [FHtmlReader.nodeValue]);

	comment := FHtmlDocument.CreateComment(FHtmlReader.nodeValue);
	FCurrentNode.AppendChild(comment)
end;

procedure THtml4Parser.ProcessDocType(Sender: TObject);
var
	docType: TDocumentType;
	oldDocType: TDocumentType;
begin
	LogFmt('ProcessDocType: %s', [FHtmlReader.nodeName]);

	//If the tree already has a doctype, then ignore any subsequent ones
	if FHtmlDocument.Doctype <> nil then
		Exit;

	//If we're at the DocumentElement (i.e. html) node, then its too late for doctypes
	if FHtmlDocument.DocumentElement <> nil then
		Exit;

	docType := DomImplementation.createDocumentType(
				FHtmlReader.nodeName,
				FHtmlReader.publicID,
				FHtmlReader.systemID);

	oldDocType := FHtmlDocument.DocType;
	if oldDocType <> nil then
		FHtmlDocument.ReplaceChild(docType, oldDocType)
	else
		FHtmlDocument.InsertBefore(docType, nil);


{
	The way to set a document's type is not through the (readonly) .DocType property,
	but by adding the DocType node in the tree in its appropriate spot.

	DONE: What is the correct spot in the DOM tree for a doctype node?

	Answer: the first child node of the document:

		- Document
			- doctype
			- html
				- head
				- body

}
end;

procedure THtml4Parser.ProcessElementEnd(Sender: TObject);
begin
{
	Event occurs at the end of a starting tag:

		<DIV></DIV>
			 ^

		<DIV/>
			  ^

	Valid reader properties:
		- reader.NodeType
		- reader.IsEmptyElement
}
	LogFmt('ProcessElementEnd(IsEmptyElement=%s)', [SBoolean[FHtmlReader.isEmptyElement]]);

	if FHtmlReader.IsEmptyElement or (FCurrentTag.Number in EmptyTags) then
	begin
		if (FCurrentNode <> FHtmlDocument.DocumentElement) and (FCurrentNode <> FHtmlDocument.Head) and (FCurrentNode <> FHtmlDocument.Body) then
			FCurrentNode := FCurrentNode.ParentNode;
	end;
	FCurrentTag := nil
end;

procedure THtml4Parser.ProcessElementStart(Sender: TObject);
var
	element: TElement;
	parent: TNode;
begin
	LogFmt('ProcessElementStart <%s>', [FHtmlReader.NodeName]);

	FCurrentTag := HtmlTagList.GetTagByName(FHtmlReader.nodeName);

	parent := GetDefaultParent(FCurrentTag.Number);
	if parent <> nil then
		FCurrentNode := parent;

	element := FHtmlDocument.createElement(FHtmlReader.nodeName);
	FCurrentNode.AppendChild(element);
	FCurrentNode := element
end;

procedure THtml4Parser.ProcessEndElement(Sender: TObject);
var
	element: TElement;
begin
	LogFmt('ProcessEndElement </%s>', [FHtmlReader.nodeName]);

	element := FindThisElement(FHtmlReader.nodeName);

	if Assigned(element) then
	begin
		//Now that we're closing an element, go to its parent.
		//Unless we're closing the HEAD or BODY elements, in which case stay in their context.
		if (element <> FHtmlDocument.DocumentElement) and (element <> FHtmlDocument.Head) and (element <> FHtmlDocument.Body) then
			FCurrentNode := element.ParentNode;
	end;
{	else
	if IsBlockTagName(FHtmlReader.nodeName) then
		raise DomException.Create(HIERARCHY_REQUEST_ERR)}
end;

//procedure THtml4Parser.ProcessEntityReference(Sender: TObject);
//var
//	entityReference: TEntityReference;
//begin
//	Removed in HTML5
//	LogFmt('ProcessEntityReference (%s)', [FHtmlReader.nodeName]);
//
//	entityReference := FHtmlDocument.createEntityReference(FHtmlReader.nodeName);
//	FCurrentNode.AppendChild(entityReference)
//end;

procedure THtml4Parser.ProcessTextNode(Sender: TObject);
var
	textNode: TTextNode;
	s: TDomString;
	parent: TNode;
begin
//	LogFmt('ProcessTextNode #text="%s"', [FHtmlReader.nodeValue]);
	LogFmt('ProcessTextNode', []);

	s := FHtmlReader.NodeValue;

	//parent := nil;

	if FHtmlDocument.Body <> nil then
	begin
		//If we're in the body, add it to current node.
		//Note: we can't just add it to the current node.
		//We have to use the rules of FindParent to walk up the tree to find the A tag
		//that this text is going under
		parent := FCurrentNode;
		if parent = nil then
			raise Exception.Create('In body, but no current node assigned');
	end
	else if FHtmlDocument.Head <> nil then
	begin
		//If we're in the HEAD, add it to the current node.
		//This can even be whitespace after </HEAD> but before <BODY>.
		//The whitespace is added into the (now closed) HEAD.
		parent := FCurrentNode;
		if parent = nil then
			raise Exception.Create('In head, but no current node assigned');
	end
	else if FHtmlDocument.Head = nil then
	begin
		//If we're before the head, then add it to head.
		//Before the HEAD any leading whitespace on text nodes is trimmed.
		//Before the HEAD any empty text nodes are ignored.
		s := TrimLeft(s);
		if s = '' then
			Exit;

		parent := RequireHeadElement;
	end
	else
		raise Exception.Create('Got a text node with no place to put it');

	if parent = nil then
		raise Exception.Create('Text node parent is nil');

	//Check if the existing node is a #text. If so then append our text to that one
	if (parent.ChildNodes.Length > 0) and (parent.LastChild.NodeType = TEXT_NODE) then
	begin
		textNode := parent.LastChild as TTextNode;
		textNode.NodeValue := textNode.NodeValue + s;
		Exit;
	end;

	textNode := FHtmlDocument.createTextNode(s);
	parent.AppendChild(textNode);
end;

function THtml4Parser.RequireBodyElement: TElement;
var
	body: TElement;
	html: TElement;
begin
	body := FHtmlDocument.Body;
	if body = nil then
	begin
		//html := RequireHtmlElement;
		RequireHeadElement;
		body := FHtmlDocument.DocumentElement.AppendChild(FHtmlDocument.createElement(bodyTagName)) as TElement;
		FCurrentNode := body;
	end;

	Result := body;
end;

function THtml4Parser.RequireHeadElement: TElement;
var
	head: TElement;
	html: TElement;
begin
	head := FHtmlDocument.Head;
	if head = nil then
	begin
		html := RequireHtmlElement;
		head := html.AppendChild(FHtmlDocument.createElement(headTagName)) as TElement;
		FCurrentNode := head;
	end;

	Result := head;
end;

function THtml4Parser.RequireHtmlElement: TElement;
var
	html: TElement;
begin
	html := FHtmlDocument.DocumentElement;
	if html = nil then
		html := FHtmlDocument.AppendChild(FHtmlDocument.createElement(htmlTagName)) as TElement;

	Result := html;
end;

class function THtml4Parser.Parse(const HtmlStr: TDomString): TDocument;
var
	parser: THtml4Parser;
begin
	parser := THtml4Parser.Create;
	try
		Result := parser.ParseString(HtmlStr);
	finally
		parser.Free;
	end;
end;

function THtml4Parser.parseString(const htmlStr: TDomString): TDocument;
begin
	FHtmlReader.htmlStr := htmlStr;

//	FHtmlDocument := DomImplementation.createHtmlDocument(''); //we can't use CreateHtmlDocument because that also creates a doctype.
	FHtmlDocument := DomImplementation.createEmptyDocument(nil);
//	FHead := nil; //whether we've gotten to a head yet
	FBody := nil; //whether we've gotten to a body yet
	FInBody := False;

	FCurrentNode := FHtmlDocument;
	try
		while FHtmlReader.Read do;
	except
		begin
			// TODO: Add event ?
			raise;
		end;
	end;

	Result := FHtmlDocument;
end;

end.

