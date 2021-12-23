unit HtmlParser;

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
		parser: THTMLParser;
		doc: TDocument;

		parser := THTMLParser.Create;
		try
			doc := parser.ParseString('<HTML><BODY>Hello, world!</BODY></HTML>');
		finally
			parser.Free;
		end;

	TODO
	----
		- Add a ParseStream static method (requires THTMLReader to support streams)
		- Nodes added after the final BODY are appended as a child of the BODY
		- If the final node of the BODY is a #text node, and we're appending a #text
		  node, consolidate the text nodes
		- nodes added before the body are appended to the body
}

type
	THtmlParser = class
	private
		FHtmlDocument: TDocument;
		FHtmlReader: THtmlReader;
		FCurrentNode: TNode;
		FCurrentTag: THtmlTag;
		function FindDefParent: TElement;
		function FindParent: TElement;
		function FindParentElement(tagList: THtmlTagSet): TElement;
		function FindTableParent: TElement;
		function FindThisElement: TElement;
		function GetMainElement(const tagName: TDomString): TElement;

		procedure Log(const s: string);

		//HtmlReader SAX callback handlers
		procedure ProcessDocType(Sender: TObject);
		procedure ProcessElementStart(Sender: TObject);
		procedure ProcessElementEnd(Sender: TObject);
		procedure ProcessEndElement(Sender: TObject);
		procedure ProcessAttributeStart(Sender: TObject);
		procedure ProcessAttributeEnd(Sender: TObject);
		procedure ProcessCDataSection(Sender: TObject);
		procedure ProcessComment(Sender: TObject);
		procedure ProcessEntityReference(Sender: TObject);
		//procedure ProcessNotation(Sender: TObject);
		procedure ProcessProcessingInstruction(Sender: TObject);
		procedure ProcessTextNode(Sender: TObject);
		procedure LogFmt(const Fmt: string; const Args: array of const);
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

constructor THtmlParser.Create;
begin
	inherited Create;

	FHtmlReader := THtmlReader.Create;
	with FHtmlReader do
	begin
		OnAttributeEnd := 				ProcessAttributeEnd;
		OnAttributeStart := 				ProcessAttributeStart;
		OnCDataSection := 				ProcessCDataSection;
		OnComment := 						ProcessComment;
		OnDocType := 						ProcessDocType;
		OnElementEnd := 					ProcessElementEnd;
		OnElementStart := 				ProcessElementStart;
		OnEndElement := 					ProcessEndElement;
		OnEntityReference := 			ProcessEntityReference;
		//OnNotation := 					ProcessNotation;
		OnProcessingInstruction := 	ProcessProcessingInstruction; // "<@ ...>
		OnTextNode := 						ProcessTextNode;
	end
end;

destructor THtmlParser.Destroy;
begin
	FreeAndNil(FHtmlReader);
	inherited Destroy
end;

function THtmlParser.FindDefParent: TElement;
begin
	if FCurrentTag.Number in [HEAD_TAG, BODY_TAG] then
		Result := FHtmlDocument.AppendChild(FHtmlDocument.createElement(htmlTagName)) as TElement
	else if FCurrentTag.Number in HeadTags then
		Result := GetMainElement(headTagName)
	else
		Result := GetMainElement(bodyTagName)
end;

function THtmlParser.FindParent: TElement;
begin
	if (FCurrentTag.Number = P_TAG) or (FCurrentTag.Number in BlockTags) then
		Result := FindParentElement(BlockParentTags)
	else if FCurrentTag.Number = LI_TAG then
		Result := FindParentElement(ListItemParentTags)
	else if FCurrentTag.Number in [DD_TAG, DT_TAG] then
		Result := FindParentElement(DefItemParentTags)
	else if FCurrentTag.Number in [TD_TAG, TH_TAG] then
		Result := FindParentElement(CellParentTags)
	else if FCurrentTag.Number = TR_TAG then
		Result := FindParentElement(RowParentTags)
	else if FCurrentTag.Number = COL_TAG then
		Result := FindParentElement(ColParentTags)
	else if FCurrentTag.Number in [COLGROUP_TAG, THEAD_TAG, TFOOT_TAG, TBODY_TAG] then
		Result := FindParentElement(TableSectionParentTags)
	else if FCurrentTag.Number = TABLE_TAG then
		Result := FindTableParent
	else if FCurrentTag.Number = OPTION_TAG then
		Result := FindParentElement(OptionParentTags)
	else if FCurrentTag.Number in [HEAD_TAG, BODY_TAG] then
		Result := FHtmlDocument.documentElement as TElement
	else
		Result := nil;

	if Result = nil then
		Result := FindDefParent
end;

function THtmlParser.FindParentElement(tagList: THtmlTagSet): TElement;
var
	Node: TNode;
	HtmlTag: THtmlTag;
begin
	Node := FCurrentNode;
	while Node.NodeType = ELEMENT_NODE do
	begin
		HtmlTag := HtmlTagList.GetTagByName(Node.NodeName);
		if HtmlTag.Number in tagList then
		begin
			Result := Node as TElement;
			Exit
		end;
		Node := Node.ParentNode
	end;
	Result := nil
end;

function THtmlParser.FindTableParent: TElement;
var
	Node: TNode;
	HtmlTag: THtmlTag;
begin
	Node := FCurrentNode;
	while Node.NodeType = ELEMENT_NODE do
	begin
		HtmlTag := HtmlTagList.GetTagByName(Node.NodeName);
		if (HtmlTag.Number = TD_TAG) or (HtmlTag.Number in BlockTags) then
		begin
			Result := Node as TElement;
			Exit
		end;
		Node := Node.ParentNode
	end;
	Result := GetMainElement(bodyTagName)
end;

function THtmlParser.FindThisElement: TElement;
var
	Node: TNode;
begin
	Node := FCurrentNode;
	while Node.NodeType = ELEMENT_NODE do
	begin
		Result := Node as TElement;
		if SameText(Result.tagName, FHtmlReader.nodeName) then
			Exit;
		Node := Node.ParentNode
	end;
	Result := nil
end;

function THtmlParser.GetMainElement(const tagName: TDomString): TElement;
var
	child: TNode;
	I: Integer;
begin
	if FHtmlDocument.documentElement = nil then
		FHtmlDocument.AppendChild(FHtmlDocument.createElement(htmlTagName));
	for I := 0 to FHtmlDocument.documentElement.ChildNodes.length - 1 do
	begin
		child := FHtmlDocument.documentElement.ChildNodes.item(I);
		if (child.NodeType = ELEMENT_NODE) and SameText(child.NodeName, tagName) then
		begin
			Result := child as TElement;
			Exit
		end
	end;
	Result := FHtmlDocument.createElement(tagName);
	FHtmlDocument.documentElement.AppendChild(Result)
end;

procedure THtmlParser.Log(const s: string);
begin
	LogFmt(s, []);
end;

procedure THtmlParser.LogFmt(const Fmt: string; const Args: array of const);
var
	s: string;
begin
	if IsDebuggerPresent then
	begin
//		s := Format(Fmt, Args);
//		OutputDebugString(PChar(s));
	end;
end;

procedure THtmlParser.ProcessAttributeEnd(Sender: TObject);
begin
	Log('ProcessAttributeEnd');

	FCurrentNode := (FCurrentNode as TAttr).ownerElement
end;

procedure THtmlParser.ProcessAttributeStart(Sender: TObject);
var
	attr: TAttr;
begin
	LogFmt('ProcessAttributeStart (%s=...)', [FHtmlReader.NodeName]);

	attr := FHtmlDocument.createAttribute(FHtmlReader.nodeName);
	(FCurrentNode as TElement).setAttributeNode(attr);
	FCurrentNode := attr
end;

procedure THtmlParser.ProcessCDataSection(Sender: TObject);
var
	CDataSection: TCDataSection;
begin
	LogFmt('ProcessCDataSection (%s)', [FHtmlReader.nodeValue]);

	CDataSection := FHtmlDocument.createCDATASection(FHtmlReader.nodeValue);
	FCurrentNode.AppendChild(CDataSection)
end;

procedure THtmlParser.ProcessComment(Sender: TObject);
var
	comment: TComment;
begin
	LogFmt('ProcessComment (%s)', [FHtmlReader.nodeValue]);

	comment := FHtmlDocument.CreateComment(FHtmlReader.nodeValue);
	FCurrentNode.AppendChild(comment)
end;

procedure THtmlParser.ProcessDocType(Sender: TObject);
var
	docType: TDocumentType;
begin
	LogFmt('ProcessDocType: %s', [FHtmlReader.nodeName]);

	docType := DomImplementation.createDocumentType(
				FHtmlReader.nodeName,
				FHtmlReader.publicID,
				FHtmlReader.systemID);

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
	FHtmlDocument.AppendChild(docType);
end;

procedure THtmlParser.ProcessElementEnd(Sender: TObject);
begin
{
	reader.NodeType
}
	LogFmt('ProcessElementEnd', []);

	if FHtmlReader.isEmptyElement or (FCurrentTag.Number in EmptyTags) then
		FCurrentNode := FCurrentNode.ParentNode;
	FCurrentTag := nil
end;

procedure THtmlParser.ProcessElementStart(Sender: TObject);
var
	element: TElement;
	parent: TNode;
begin
	LogFmt('ProcessElementStart <%s>', [FHtmlReader.NodeName]);

	FCurrentTag := HtmlTagList.GetTagByName(FHtmlReader.nodeName);
	if FCurrentTag.Number in NeedFindParentTags + BlockTags then
	begin
		parent := FindParent;
		if not Assigned(parent) then
			raise DomException.Create(HIERARCHY_REQUEST_ERR);
		FCurrentNode := parent
	end;
	element := FHtmlDocument.createElement(FHtmlReader.nodeName);
	FCurrentNode.AppendChild(element);
	FCurrentNode := element
end;

procedure THtmlParser.ProcessEndElement(Sender: TObject);
var
	element: TElement;
begin
	Log('ProcessEndElement');

	element := FindThisElement;
	if Assigned(element) then
		FCurrentNode := element.ParentNode
{  else
	if IsBlockTagName(FHtmlReader.nodeName) then
		raise DomException.Create(HIERARCHY_REQUEST_ERR)}
end;

procedure THtmlParser.ProcessEntityReference(Sender: TObject);
var
	EntityReference: TEntityReference;
begin
	LogFmt('ProcessEntityReference (%s)', [FHtmlReader.nodeName]);

	EntityReference := FHtmlDocument.createEntityReference(FHtmlReader.nodeName);
	FCurrentNode.AppendChild(EntityReference)
end;

//procedure THtmlParser.ProcessNotation(Sender: TObject);
//begin
//	Log('ProcessNotation');
//end;

procedure THtmlParser.ProcessProcessingInstruction(Sender: TObject);
begin
	Log('ProcessProcessingInstruction');
end;

procedure THtmlParser.ProcessTextNode(Sender: TObject);
var
	TextNode: TTextNode;
begin
	LogFmt('ProcessTextNode #text="%s"', [FHtmlReader.nodeValue]);

	TextNode := FHtmlDocument.createTextNode(FHtmlReader.nodeValue);
	FCurrentNode.AppendChild(TextNode)
end;

class function THtmlParser.Parse(const HtmlStr: TDomString): TDocument;
var
	parser: THtmlParser;
begin
	parser := THtmlParser.Create;
	try
		Result := parser.ParseString(HtmlStr);
	finally
		parser.Free;
	end;
end;

function THtmlParser.parseString(const htmlStr: TDomString): TDocument;
begin
	FHtmlReader.htmlStr := htmlStr;
	FHtmlDocument := DomImplementation.createEmptyDocument(nil);
	FCurrentNode := FHtmlDocument;
	try
		while FHtmlReader.Read do;
	except
		raise; // TODO: Add event ?
	end;

	Result := FHtmlDocument
end;

end.
