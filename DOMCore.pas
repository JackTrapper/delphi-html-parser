unit DomCore;

{
	This unit represents in implementation of the core DOM classes.
	https://www.w3.org/TR/DOM-Level-3-Core/core.html

	History
	=======

	1/7/2021
			- Removed TEntityReference (per HTML5)

	12/22/2021
			- Removed TDocumentType.Entities, Notations, and InternalSubset (per HTML5)
			- Removed TNode.IsSupported (per HTML5)

	12/20/2021
			- fixed TNode.NodeValue was not calling GetNodeValue getter
			- fixed attribute lookups to be case insensitive (like everything else in html)
			- fixed tag name normalization to UPPERCASE, the canonical form in the spec
				(https://www.w3.org/TR/DOM-Level-3-Core/core.html#ID-104682815)
				(https://dom.spec.whatwg.org/#dom-element-tagname)
			- added doctype node to the tree. DocType is now the convenience getter that returns that node
			- fixed InsertNode to allow DOCTYPE nodes to be inserted to the document
			- node.InsertBefore should only fail the WRONG_DOCUMENT_ERR check if the node has an ownerDocument assigned.
			- added TNodeType type
			- InsertBefore will no longer reject a node if its OwnerDocument is nil
			- AcceptNode is now case insensitive to node local names
			- NamedNodeMap.GetNamedItem and GetNamedItemNS are no longer case sensitive
			- TElement constructor now canonically UPPERCASEs the tag name
			- Documents no longer take a doctype in their constructor. You add doctype node as a child of the document node
			- Added CreateHtmlDocument to DOMImplementation, following the html5 spec of what it should contain
			- DOMImplemenation.createDocument doctype parameter is now optional
			- Changed DOMImplementation.HasFeature to always return true, per HTML5 spec
}

interface

uses
	Classes, SysUtils;

const
	TAB = 9;
	LF = 10;
	CR = 13;
	SP = 32;

	WhiteSpace = [TAB, LF, CR, SP];

type
	TNodeType = type Word;
const
	NONE                           =  0;	//extension
	ELEMENT_NODE                   =  1;	//An Element node like <p> or <div>.
	ATTRIBUTE_NODE                 =  2;	//An Attribute of an Element. Attributes no longer implement the Node interface as of DOM4.
	TEXT_NODE                      =  3;	//The actual Text inside an Element or Attr.
	CDATA_SECTION_NODE             =  4;	//A CDATASection, such as <!CDATA[[ … ]]>.
//	ENTITY_REFERENCE_NODE          =  5;	//An XML Entity Reference node, such as &foo;. Removed in DOM4.
//	ENTITY_NODE                    =  6;	//An XML <!ENTITY …> node. Removed in DOM4.
	PROCESSING_INSTRUCTION_NODE    =  7;	//A ProcessingInstruction of an XML document, such as <?xml-stylesheet … ?>.
	COMMENT_NODE                   =  8;	//A Comment node, such as <!-- … -->.
	DOCUMENT_NODE                  =  9;	//A Document node.
	DOCUMENT_TYPE_NODE             = 10;	//A DocumentType node, such as <!DOCTYPE html>.
	DOCUMENT_FRAGMENT_NODE         = 11;	//A DocumentFragment node.
//	NOTATION_NODE                  = 12;	//An XML <!NOTATION ...> node. Removed in DOM4.

	END_ELEMENT_NODE               = 255; // extension

	//DomException error codes
	INDEX_SIZE_ERR                 = 1;
	DOMSTRING_SIZE_ERR             = 2;
	HIERARCHY_REQUEST_ERR          = 3;
	WRONG_DOCUMENT_ERR             = 4;
	INVALID_CHARACTER_ERR          = 5;
	NO_DATA_ALLOWED_ERR            = 6;
	NO_MODIFICATION_ALLOWED_ERR    = 7;
	NOT_FOUND_ERR                  = 8;
	NOT_SUPPORTED_ERR              = 9;
	INUSE_ATTRIBUTE_ERR            = 10;
	INVALID_STATE_ERR              = 11; //DOM Level 2
	SYNTAX_ERR                     = 12; //DOM Level 2
	INVALID_MODIFICATION_ERR       = 13; //DOM Level 2
	NAMESPACE_ERR                  = 14; //DOM Level 2
	INVALID_ACCESS_ERR             = 15; //DOM Level 2
	VALIDATION_ERR                 = 16; //DOM Level 3
	TYPE_MISMATCH_ERR              = 17; //DOM Level 3

	{HTML DTDs}
	DTD_HTML_STRICT    = 1;
	DTD_HTML_LOOSE     = 2;
	DTD_HTML_FRAMESET  = 3;
	DTD_XHTML_STRICT   = 4;
	DTD_XHTML_LOOSE    = 5;
	DTD_XHTML_FRAMESET = 6;

type
	//TODO: Change this to just UnicodeString. Yes old DOM interfaces created a
	//type called DomString. But that was meant to define a set of concepts of what
	//their strings require. Those requirements are met by UnicodeString (and WideString).
	//So we just define UnicodeString as a modernizer for Delphi 5.
	TDomString = {$IFDEF UNICODE}UnicodeString{$ELSE}WideString{$ENDIF};

	DomException = class(Exception)
	private
		FCode: Integer;
	public
		constructor Create(ErrorCode: Integer); overload;
		constructor Create(ErrorCode: Integer; AdditionalMessage: string); overload;
		property code: Integer read FCode;
	end;

{
	The DOMStringList interface provides the abstraction of an ordered collection of DOMString values,
	without defining or constraining how this collection is implemented.
	The items in the DOMStringList are accessible via an integral index, starting from 0.

	Added in DOM level 3
}
	IDOMStringList = interface
		['{789034BD-ABC7-451B-AB27-8C976874364A}']
		function getLength: Integer;
		function Item(Index: Integer): TDomString;
		function Contains(const str: TDomString): Boolean;
		property Length: Integer read getLength;
	end;

	TNamespaceURIList = class
	private
		FList: array of TDomString; //removed need for WStrings unit
		function GetItem(I: Integer): TDomString;
	public
		constructor Create;
		destructor Destroy; override;
		procedure Clear;
		function Add(const NamespaceURI: TDomString): Integer;
		property Item[I: Integer]: TDomString read GetItem; default;
	end;

	TDocument = class;
	TNodeList = class;
	TNamedNodeMap = class;
	TElement = class;

	TNode = class
	private
		FOwnerDocument: TDocument;
		FParentNode: TNode;
		FNamespaceURI: Integer;
		FPrefix: TDomString;
		FNodeName: TDomString;
		FNodeValue: TDomString;
		FAttributes: TNamedNodeMap;
		function GetFirstChild: TNode;
		function GetLastChild: TNode;
		function GetPreviousSibling: TNode;
		function GetNextSibling: TNode;
		function GetLocalName: TDomString;
		function GetNamespaceURI: TDomString;
		function InsertSingleNode(newChild, refChild: TNode): TNode;
		procedure SetOwnerDocument(const Value: TDocument);
		function GetTextContent: TDomString; virtual;
	protected
		FChildNodes: TNodeList;
		function GetNodeName: TDomString; virtual;
		function GetNodeValue: TDomString; virtual;
		function GetNodeType: TNodeType; virtual; abstract;
		function GetParentNode: TNode; virtual;
		function CanInsert(Node: TNode): Boolean; virtual;
		function ExportNode(otherDocument: TDocument; deep: Boolean): TNode; virtual;
		procedure SetNodeValue(const value: TDomString); virtual;
		procedure SetNamespaceURI(const value: TDomString);
		procedure SetPrefix(const value: TDomString);
		procedure SetLocalName(const value: TDomString);
		procedure CloneChildNodesFrom(Node: TNode);
		constructor Create(ownerDocument: TDocument; const namespaceURI, qualifiedName: TDomString; withNS: Boolean);
	public
		destructor Destroy; override;

		function InsertBefore(newChild, refChild: TNode): TNode;
		function ReplaceChild(newChild, oldChild: TNode): TNode;
		function RemoveChild(oldChild: TNode): TNode;
		function AppendChild(newChild: TNode): TNode;
		function hasChildNodes: Boolean;
		function cloneNode(deep: Boolean): TNode; virtual; abstract;
		//function isSupported(const feature, version: TDomString): Boolean; deprecated 'Removed in HTML5';
		function HasAttributes: Boolean; //DOM Level 2

		function ancestorOf(node: TNode): Boolean; //extension
		function getElementsByTagName(const name: TDomString): TNodeList;
		function getElementsByTagNameNS(const namespaceURI, localName: TDomString): TNodeList;
		function GetElementByID(const ElementID: TDomString): TElement;
		procedure normalize;

		property NodeType: TNodeType read GetNodeType;
		property NodeName: TDomString read GetNodeName;
		property NodeValue: TDomString read GetNodeValue write SetNodeValue;
		property TextContent: TDomString read GetTextContent; //TODO: SetTextContent (https://dom.spec.whatwg.org/#dom-node-textcontent)
		property ParentNode: TNode read GetParentNode;
		property ChildNodes: TNodeList read FChildNodes;
		property FirstChild: TNode read GetFirstChild;
		property LastChild: TNode read GetLastChild;
		property PreviousSibling: TNode read GetPreviousSibling;
		property NextSibling: TNode read GetNextSibling;
		property Attributes: TNamedNodeMap read FAttributes;
		property OwnerDocument: TDocument read FOwnerDocument write SetOwnerDocument;
		property NamespaceURI: TDomString read GetNamespaceURI; //DOM Level 2
		property Prefix: TDomString read FPrefix write SetPrefix;  //DOM Level 2
		property LocalName: TDomString read GetLocalName; //DOM Level 2
	end;

	TNodeList = class
	private
		FOwnerNode: TNode;
		FList: TList;
	protected
		function GetLength: Integer; virtual;
		function IndexOf(node: TNode): Integer;
		procedure Add(node: TNode);
		procedure Delete(I: Integer);
		procedure Insert(I: Integer; node: TNode);
		procedure Remove(node: TNode);
		procedure Clear(WithItems: Boolean);
		property ownerNode: TNode read FOwnerNode;
		constructor Create(AOwnerNode: TNode);
	public
		destructor Destroy; override;
		function Item(Index: Integer): TNode; virtual;
		property Items[Index: Integer]: TNode read Item; default; //extension
		property Length: Integer read GetLength;
	end;

	TNamedNodeMap = class(TNodeList)
	public
		function getNamedItem(const name: TDomString): TNode;
		function setNamedItem(arg: TNode): TNode;
		function removeNamedItem(const name: TDomString): TNode;
		function getNamedItemNS(const namespaceURI, localName: TDomString): TNode;
		function setNamedItemNS(arg: TNode): TNode;
		function removeNamedItemNS(const namespaceURI, localName: TDomString): TNode;
	end;

	TCharacterData = class(TNode)
	private
		function GetLength: Integer;
	protected
		procedure SetNodeValue(const value: TDomString); override;
		function GetTextContent: TDomString; override;
		constructor Create(ownerDocument: TDocument; const data: TDomString);
	public
		function substringData(offset, count: Integer): TDomString;
		procedure appendData(const arg: TDomString);
		procedure deleteData(offset, count: Integer);
		procedure insertData(offset: Integer; arg: TDomString);
		procedure replaceData(offset, count: Integer; const arg: TDomString);
		property data: TDomString read GetNodeValue write SetNodeValue;
		property length: Integer read GetLength;
	end;

	TComment = class(TCharacterData)
	protected
		function GetNodeName: TDomString; override;
		function GetNodeType: TNodeType; override;
		function ExportNode(otherDocument: TDocument; deep: Boolean): TNode; override;
	public
		function cloneNode(deep: Boolean): TNode; override;
	end;

	TTextNode = class(TCharacterData)
	protected
		function GetNodeName: TDomString; override;
		function GetNodeType: TNodeType; override;
		function ExportNode(otherDocument: TDocument; deep: Boolean): TNode; override;
	public
		function cloneNode(deep: Boolean): TNode; override;
		function splitText(offset: Integer): TTextNode;
	end;

	TCDATASection = class(TTextNode)
	protected
		function GetNodeName: TDomString; override;
		function GetNodeType: TNodeType; override;
		function ExportNode(otherDocument: TDocument; deep: Boolean): TNode; override;
	public
		function cloneNode(deep: Boolean): TNode; override;
	end;

	TAttr = class(TNode)
	private
		function GetOwnerElement: TElement;
		function GetSpecified: Boolean;
	protected
		function GetNodeValue: TDomString; override;
		function GetNodeType: TNodeType; override;
		function GetParentNode: TNode; override;
		function CanInsert(node: TNode): Boolean; override;
		function ExportNode(ownerDocument: TDocument; deep: Boolean): TNode; override;
		procedure SetNodeValue(const Value: TDomString); override;
		function GetTextContent: TDomString; override;
	public
		function cloneNode(deep: Boolean): TNode; override;
		property name: TDomString read GetNodeName;
		property specified: Boolean read GetSpecified;
		property Value: TDomString read GetNodeValue write SetNodeValue;
		property ownerElement: TElement read GetOwnerElement; //DOM Level2
	end;

	TElement = class(TNode)
	private
		FIsEmpty: Boolean;
	protected
		function GetNodeType: TNodeType; override;
		function CanInsert(node: TNode): Boolean; override;
		function ExportNode(otherDocument: TDocument; deep: Boolean): TNode; override;
		function GetTextContent: TDomString; override;
		constructor Create(ownerDocument: TDocument; const namespaceURI, qualifiedName: TDomString; withNS: Boolean);
	public
		function cloneNode(deep: Boolean): TNode; override;
		function getAttribute(const name: TDomString): TDomString;
		function getAttributeNode(const name: TDomString): TAttr;
		function setAttributeNode(newAttr: TAttr): TAttr;
		function removeAttributeNode(oldAttr: TAttr): TAttr;
		function getAttributeNS(const namespaceURI, localName: TDomString): TDomString;
		function getAttributeNodeNS(const namespaceURI, localName: TDomString): TAttr;
		function setAttributeNodeNS(newAttr: TAttr): TAttr;
		function hasAttribute(const name: TDomString): Boolean;
		function hasAttributeNS(const namespaceURI, localName: TDomString): Boolean;
		procedure setAttribute(const name, value: TDomString);
		procedure removeAttribute(const name: TDomString);
		procedure setAttributeNS(const namespaceURI, qualifiedName, value: TDomString);
		procedure removeAttributeNS(const namespaceURI, localName: TDomString);
		property tagName: TDomString read GetNodeName;
		property isEmpty: Boolean read FIsEmpty write FIsEmpty;
	end;

	TProcessingInstruction = class(TNode)
	private
		function GetTarget: TDomString;
		function GetData: TDomString;
		procedure SetData(const value: TDomString);
	protected
		function GetNodeType: TNodeType; override;
		function ExportNode(otherDocument: TDocument; deep: Boolean): TNode; override;
		constructor Create(ownerDocument: TDocument; const target, data: TDomString);
	public
		function cloneNode(deep: Boolean): TNode; override;
		property target: TDomString read GetTarget;
		property data: TDomString read GetData write SetData;
	end;

	TDocumentFragment = class(TNode)
	protected
		function CanInsert(node: TNode): Boolean; override;
		function GetNodeType: TNodeType; override;
		function GetNodeName: TDomString; override;
		function ExportNode(otherDocument: TDocument; deep: Boolean): TNode; override;
		function GetTextContent: TDomString; override;
		constructor Create(ownerDocument: TDocument);
	public
		function cloneNode(deep: Boolean): TNode; override;
	end;

	TDocumentType = class(TNode)
	private
		FPublicID: TDomString;
		FSystemID: TDomString;
		//FEntities: TNamedNodeMap; deprecated 'Removed in HTML5';
		//FNotations: TNamedNodeMap; deprecated 'Removed in HTML5';
		//FInternalSubset: TDomString; deprecated 'Removed in HTML5';
	protected
		function GetNodeType: TNodeType; override;
		constructor Create(ownerDocument: TDocument; const name, publicId, systemId: TDomString);
	public
		function cloneNode(deep: Boolean): TNode; override;
		property name: TDomString read GetNodeName;
		property publicId: TDomString read FPublicID;
		property systemId: TDomString read FSystemID;
		//property entities: TNamedNodeMap read FEntities; deprecated 'Removed in HTML5';
		//property notations: TNamedNodeMap read FNotations; deprecated 'Removed in HTML5';
		//property internalSubset: TDomString read FInternalSubset; deprecated 'Removed in HTML5';
	end;

	TDocument = class(TNode)
	private
		//FDocType: TDocumentType; is now a child of the document node as the DOM intended
		FNamespaceURIList: TNamespaceURIList;
		FSearchNodeLists: TList;
		FQuirksMode: Boolean;
		function GetDocumentElement: TElement;
		function GetDocType: TDocumentType;
		function GetHead: TElement;
		function GetBody: TElement;
	protected
		function GetNodeName: TDomString; override;
		function GetNodeType: TNodeType; override;
		function CanInsert(Node: TNode): Boolean; override;
		function createDocType(const name, publicId, systemId: TDomString): TDocumentType;
		procedure AddSearchNodeList(NodeList: TNodeList);
		procedure RemoveSearchNodeList(NodeList: TNodeList);
		procedure InvalidateSearchNodeLists;
	public
		constructor Create;
		destructor Destroy; override;

		procedure Clear;
		function cloneNode(deep: Boolean): TNode; override;
		function createElement(const tagName: TDomString): TElement;
		function createDocumentFragment: TDocumentFragment;
		function createTextNode(const data: TDomString): TTextNode;
		function CreateComment(const data: TDomString): TComment;
		function createCDATASection(const data: TDomString): TCDATASection;
		function createProcessingInstruction(const target, data: TDomString): TProcessingInstruction;
		function createAttribute(const name: TDomString): TAttr;
		//function createEntityReference(const name: TDomString): TEntityReference; removed in HTML 5
		function importNode(importedNode: TNode; deep: Boolean): TNode;
		function createElementNS(const namespaceURI, qualifiedName: TDomString): TElement;
		function createAttributeNS(const namespaceURI, qualifiedName: TDomString): TAttr;

		property Doctype: TDocumentType read GetDocType; //DONE: BUGBUG Should be readonly
		property NamespaceURIList: TNamespaceURIList read FNamespaceURIList;
		property DocumentElement: TElement read GetDocumentElement;

		property QuirksMode: Boolean read FQuirksMode write FQuirksMode;

		// DOM Tree Accessors - https://html.spec.whatwg.org/#dom-tree-accessors
		property Head: TElement read GetHead; //Returns the head element.
		property Body: TElement read GetBody;	//Returns the body element.
	end;

{
	The DOMImplementation interface provides a number of methods for performing operations
	that are independent of any particular instance of the document object model.
}
	DomImplementation = class
	public
		class function createDocumentType(const QualifiedName, PublicId, SystemId: TDomString): TDocumentType;
		class function createDocument(const NamespaceURI, QualifiedName: TDomString; Doctype: TDocumentType=nil): TDocument;
		class function createHtmlDocument(const Title: TDomString=''): TDocument;

		class function hasFeature(const feature, version: TDomString): Boolean; deprecated 'Useless; always returns true';

		class function createEmptyDocument(doctype: TDocumentType): TDocument; // extension
		class function createHtmlDocumentType(htmlDocType: Integer): TDocumentType; //extension
	end;

implementation

uses
	Entities, System.UITypes, System.Types;

const
	ExceptionMsg: array[INDEX_SIZE_ERR..TYPE_MISMATCH_ERR] of string = (
		'Index or size is negative, or greater than the allowed value',
		'The specified range of text does not fit into a DOMString',
		'Node is inserted somewhere it doesn''t belong ',
		'Node is used in a different document than the one that created it',
		'Invalid or illegal character is specified, such as in a name',
		'Data is specified for a node which does not support data',
		'An attempt is made to modify an object where modifications are not allowed',
		'An attempt is made to reference a node in a context where it does not exist',
		'Implementation does not support the requested type of object or operation',
		'An attempt is made to add an attribute that is already in use elsewhere',
		'An attempt is made to use an object that is not, or is no longer, usable',
		'An invalid or illegal string is specified',
		'An attempt is made to modify the type of the underlying object',
		'An attempt is made to create or change an object in a way which is incorrect with regard to namespaces',
		'A parameter or an operation is not supported by the underlying object',
		'The method would make the Node invalid with respect to "partial validity', //VALIDATION_ERR
		'The type of the object is incompatible with the expected type of the parameter associated to the object' //TYPE_MISMATCH_ERR
	);

	ID_NAME = 'id';

type
	TDTDParams = record
		PublicId: TDomString;
		SystemId: TDomString;
	end;

	TDTDList = array[DTD_HTML_STRICT..DTD_XHTML_FRAMESET] of TDTDParams;

const
	DTDList: TDTDList = (
		(publicId: '-//W3C//DTD HTML 4.01//EN';              systemId: 'http://www.w3.org/TR/html4/strict.dtd'),
		(publicId: '-//W3C//DTD HTML 4.01 Transitional//EN'; systemId: 'http://www.w3.org/TR/1999/REC-html401-19991224/loose.dtd'),
		(publicId: '-//W3C//DTD HTML 4.01 Frameset//EN';     systemId: 'http://www.w3.org/TR/1999/REC-html401-19991224/frameset.dtd'),
		(publicId: '-//W3C//DTD XHTML 1.0 Strict//EN';       systemId: 'http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd'),
		(publicId: '-//W3C//DTD XHTML 1.0 Transitional//EN'; systemId: 'http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd'),
		(publicId: '-//W3C//DTD XHTML 1.0 Frameset//EN';     systemId: 'http://www.w3.org/TR/xhtml1/DTD/xhtml1-frameset.dtd')
	);

	HTML_TAG_NAME = 'html';

type
	TSearchNodeList = class(TNodeList)
	private
		FNamespaceParam : TDomString;
		FNameParam : TDomString;
		FSynchronized: Boolean;
		function GetLength: Integer; override;
		function acceptNode(node: TNode): Boolean;
		procedure TraverseTree(rootNode: TNode);
		procedure Rebuild;
	public
		constructor Create(AOwnerNode: TNode; const namespaceURI, name: TDomString);
		destructor Destroy; override;
		procedure Invalidate;
		function Item(index: Integer): TNode; override;
	end;
{
function Concat(const S1, S2: TDomString): TDomString;
begin
	SetLength(Result, Length(S1) + Length(S2));
	Move(S1[1], Result[1], 2 * Length(S1));
	Move(S2[1], Result[Length(S1) + 1], 2 * Length(S2))
end;
}
function IsNCName(const Value: TDomString): Boolean;
begin
	//TODO
	Result := true
end;

constructor TNamespaceURIList.Create;
begin
	inherited Create;
end;

destructor TNamespaceURIList.Destroy;
begin
	inherited Destroy
end;

procedure TNamespaceURIList.Clear;
begin
	SetLength(FList, 0);
end;

function TNamespaceURIList.GetItem(I: Integer): TDomString;
begin
	Result := FList[I]
end;

function TNamespaceURIList.Add(const NamespaceURI: TDomString): Integer;
var
	I: Integer;
begin
	for I := 0 to High(FList) do
	begin
		if FList[I] = NamespaceURI then
		begin
			Result := I;
			Exit
		end;
	end;

	I := Length(FList);
	SetLength(FList, I+1);
	FList[I] := NamespaceURI;
	Result := I;
end;

constructor DomException.Create(ErrorCode: Integer);
begin
	inherited Create(ExceptionMsg[ErrorCode]);
	FCode := ErrorCode
end;

constructor TNode.Create(ownerDocument: TDocument; const namespaceURI, qualifiedName: TDomString; withNS: Boolean);
var
	I: Integer;
begin
	inherited Create;
	FOwnerDocument := ownerDocument;
	SetNamespaceURI(namespaceURI);
	if withNS then
	begin
		I := Pos(':', qualifiedName);
		if I <> 0 then
		begin
			SetPrefix(Copy(qualifiedName, 1, I - 1));
			SetLocalName(Copy(qualifiedName, I + 1, Length(qualifiedName) - I))
		end
		else
			SetLocalName(qualifiedName)
	end
	else
			SetLocalName(qualifiedName);
	FChildNodes := TNodeList.Create(Self)
end;

destructor TNode.Destroy;
begin
	if Assigned(FChildNodes) then
	begin
		FChildNodes.Clear(true);
		FChildNodes.Free
	end;
	if Assigned(FAttributes) then
	begin
		FAttributes.Clear(true);
		FAttributes.Free
	end;
	inherited Destroy
end;

function TNode.GetFirstChild: TNode;
begin
	if ChildNodes.length <> 0 then
		Result := ChildNodes.item(0)
	else
		Result := nil
end;

function TNode.GetLastChild: TNode;
begin
	if ChildNodes.length <> 0 then
		Result := ChildNodes.item(ChildNodes.length - 1)
	else
		Result := nil
end;

function TNode.GetPreviousSibling: TNode;
var
	I: Integer;
begin
	Result := nil;
	if Assigned(ParentNode) then
	begin
		I := ParentNode.ChildNodes.IndexOf(Self);
		if I > 0 then
			Result := ParentNode.ChildNodes.item(I - 1)
	end
end;

function TNode.GetTextContent: TDomString;
begin
	Result := '';
end;

function TNode.GetNextSibling: TNode;
var
	I: Integer;
begin
	Result := nil;
	if Assigned(ParentNode) then
	begin
		I := ParentNode.ChildNodes.IndexOf(Self);
		if (I >= 0) and (I < ParentNode.ChildNodes.length - 1) then
			Result := ParentNode.ChildNodes.item(I + 1)
	end
end;

function TNode.GetNodeName: TDomString;
begin
{
	The tagName getter steps are to return this’s HTML-uppercased qualified name.
	But this isn't a tag name; this could be an attribute name - which should be lowercase
}
	if FPrefix <> '' then
		Result := FPrefix + ':' + FNodeName
	else
		Result := FNodeName;
end;

function TNode.GetNodeValue: TDomString;
begin
	Result := FNodeValue
end;

function TNode.GetParentNode: TNode;
begin
	Result := FParentNode
end;

function TNode.GetLocalName: TDomString;
begin
	Result := FNodeName
end;

function TNode.CanInsert(Node: TNode): Boolean;
begin
	Result := false;
end;

function TNode.ExportNode(otherDocument: TDocument; deep: Boolean): TNode;
begin
	raise DomException.Create(NOT_SUPPORTED_ERR)
end;

function TNode.getElementsByTagName(const name: TDomString): TNodeList;
begin
	Result := TSearchNodeList.Create(Self, '*', name)
end;

function TNode.getElementsByTagNameNS(const namespaceURI, localName: TDomString): TNodeList;
begin
	Result := TSearchNodeList.Create(Self, namespaceURI, localName)
end;

function TNode.GetElementByID(const ElementID: TDomString): TElement;
var
	element: TElement;
	i: Integer;
	attr: TAttr;
begin
{
	Returns the Element that has an ID attribute with the given value.
	If no such element exists, this returns null.
	If more than one element has an ID attribute with that value,
	what is returned is undefined.

	The DOM implementation is expected to use the attribute Attr.isId to
	determine if an attribute is of type ID.

	Note: Attributes with the name "ID" or "id" are not of type ID unless so defined.

	Parameters
	- elementId of type DOMString
		The unique id value for an element.

	Return Value
	- Element
		The matching element or null if there is none.
}
	Result := nil;

	if NodeType = ELEMENT_NODE then
	begin
		element := Self as TElement;
		attr := element.getAttributeNode('id');
		if attr <> nil then
		begin
			Result := element;
			Exit;
		end;
	end;

	for i := 0 to ChildNodes.Length-1 do
	begin
		Result := ChildNodes.Item(i).GetElementByID(ElementID);
		if Result <> nil then
			Exit;
	end;
end;

procedure TNode.SetNodeValue(const value: TDomString);
begin
	raise DomException.Create(NO_MODIFICATION_ALLOWED_ERR)
end;

procedure TNode.SetOwnerDocument(const Value: TDocument);
begin
	FOwnerDocument := Value;
end;

procedure TNode.SetNamespaceURI(const value: TDomString);
begin
	if value <> '' then
		//TODO validate
		FNamespaceURI := OwnerDocument.namespaceURIList.Add(value)
end;

function TNode.GetNamespaceURI: TDomString;
begin
	Result := OwnerDocument.namespaceURIList[FNamespaceURI]
end;

procedure TNode.SetPrefix(const value: TDomString);
begin
	if not IsNCName(value) then
		raise DomException.Create(INVALID_CHARACTER_ERR);
	FPrefix := value
end;

procedure TNode.SetLocalName(const value: TDomString);
begin
	if not IsNCName(value) then
		raise DomException.Create(INVALID_CHARACTER_ERR);
	FNodeName := value
end;

procedure TNode.CloneChildNodesFrom(Node: TNode);
var
	childNode: TNode;
	I: Integer;
begin
	for I := 0 to Node.ChildNodes.length - 1 do
	begin
		childNode := Node.ChildNodes.item(I);
		AppendChild(childNode.cloneNode(true))
	end
end;

function TNode.InsertSingleNode(newChild, refChild: TNode): TNode;
var
	I: Integer;
begin
	if not CanInsert(newChild) or newChild.ancestorOf(Self) then
		raise DomException.Create(HIERARCHY_REQUEST_ERR,
				'NewChild: '+newChild.NodeName+'='+newChild.NodeValue);
	if newChild <> refChild then
	begin
		if Assigned(refChild) then
		begin
			I := FChildNodes.IndexOf(refChild);
			if I < 0 then
				raise DomException.Create(NOT_FOUND_ERR);
			FChildNodes.Insert(I, newChild)
		end
		else
			FChildNodes.Add(newChild);
		if Assigned(newChild.ParentNode) then
			newChild.ParentNode.RemoveChild(newChild);
		newChild.FParentNode := Self
	end;
	Result := newChild
end;

function TNode.InsertBefore(newChild, refChild: TNode): TNode;
begin
	if (newChild.OwnerDocument <> nil) and (newChild.OwnerDocument <> OwnerDocument) then
		raise DomException.Create(WRONG_DOCUMENT_ERR);

	if newChild.NodeType = DOCUMENT_FRAGMENT_NODE then
	begin
		while Assigned(newChild.FirstChild) do
			InsertSingleNode(newChild.FirstChild, refChild);
		Result := newChild;
	end
	else
		Result := InsertSingleNode(newChild, refChild);

	if Assigned(OwnerDocument) then
		OwnerDocument.InvalidateSearchNodeLists
end;

function TNode.ReplaceChild(newChild, oldChild: TNode): TNode;
begin
	//1. If parent is not a Document, DocumentFragment, or Element node, then throw a "HierarchyRequestError" DOMException.
	if not (Self.NodeType in [DOCUMENT_NODE, DOCUMENT_FRAGMENT_NODE, ELEMENT_NODE]) then
		raise DomException.Create(HIERARCHY_REQUEST_ERR);

	//3. If child’s parent is not parent, then throw a "NotFoundError" DOMException.
	if oldChild.ParentNode <> Self then
		raise DomException.Create(NOT_FOUND_ERR);

	//4. If node is not a DocumentFragment, DocumentType, Element, or CharacterData node, then throw a "HierarchyRequestError" DOMException.
	if not (newChild is TDocumentFragment) and not (newChild is TDocumentType) and not (newChild is TElement) and not (newChild is TCharacterData) then
		raise DomException.Create(HIERARCHY_REQUEST_ERR);

	//5. If either node is a Text node and parent is a document, or node is a doctype and parent is not a document, then throw a "HierarchyRequestError" DOMException.
	if ((newChild is TTextNode) and (Self is TDocument)) or ((newChild is TDocumentType) and (not (Self is TDocument))) then
		raise DomException.Create(HIERARCHY_REQUEST_ERR);

	if newChild <> oldChild then
	begin
		insertBefore(newChild, oldChild);
		RemoveChild(oldChild)
	end;
	Result := oldChild;
	if Assigned(OwnerDocument) then
		OwnerDocument.InvalidateSearchNodeLists
end;

function TNode.AppendChild(newChild: TNode): TNode;
begin
	Result := insertBefore(newChild, nil);
	if Assigned(OwnerDocument) then
		OwnerDocument.InvalidateSearchNodeLists
end;

function TNode.RemoveChild(oldChild: TNode): TNode;
var
	I: Integer;
begin
	I := FChildNodes.IndexOf(oldChild);
	if I < 0 then
		raise DomException.Create(NOT_FOUND_ERR);
	FChildNodes.Delete(I);
	oldChild.FParentNode := nil;
	Result := oldChild;
	if Assigned(OwnerDocument) then
		OwnerDocument.InvalidateSearchNodeLists
end;

function TNode.hasChildNodes: Boolean;
begin
	Result := FChildNodes.length <> 0
end;

//function TNode.isSupported(const feature, version: TDomString): Boolean;
//begin
//	Result := DOMImplementation.hasFeature(feature, version)
//end;

function TNode.HasAttributes: Boolean;
begin
	Result := Assigned(FAttributes) and (FAttributes.length <> 0)
end;

function TNode.ancestorOf(node: TNode): Boolean;
begin
	while Assigned(node) do
	begin
		if node = self then
		begin
			Result := true;
			Exit
		end;
		node := node.ParentNode
	end;
	Result := false
end;

procedure TNode.normalize;
var
	childNode: TNode;
	textNode: TTextNode;
	I: Integer;
begin
	I := 0;
	while I < ChildNodes.length do
	begin
		childNode := ChildNodes.item(I);
		if childNode.NodeType = ELEMENT_NODE then
		begin
			(childNode as TElement).normalize;
			Inc(I)
		end
		else
		if childNode.NodeType = TEXT_NODE then
		begin
			textNode := childNode as TTextNode;
			Inc(I);
			childNode := ChildNodes.item(I);
			while childNode.NodeType = TEXT_NODE do
			begin
				textNode.appendData((childNode as TTextNode).Data);
				Inc(I);
				childNode := ChildNodes.item(I)
			end
		end
		else
			Inc(I)
	end
end;

constructor TNodeList.Create(AOwnerNode: TNode);
begin
	inherited Create;
	FOwnerNode := AOwnerNode;
	FList := TList.Create
end;

destructor TNodeList.Destroy;
begin
	FList.Free;
	inherited Destroy
end;

function TNodeList.IndexOf(node: TNode): Integer;
begin
	Result := FList.IndexOf(node)
end;

function TNodeList.GetLength: Integer;
begin
	Result := FList.Count
end;

procedure TNodeList.Insert(I: Integer; Node: TNode);
begin
	FList.Insert(I, Node)
end;

procedure TNodeList.Delete(I: Integer);
begin
	FList.Delete(I)
end;

procedure TNodeList.Add(node: TNode);
begin
	FList.Add(node)
end;

procedure TNodeList.Remove(node: TNode);
begin
	FList.Remove(node)
end;

function TNodeList.item(index: Integer): TNode;
begin
	if (index >= 0) and (index < length) then
		Result := FList[index]
	else
		Result := nil
end;

procedure TNodeList.Clear(WithItems: Boolean);
var
	I: Integer;
begin
	if WithItems then
	begin
		for I := 0 to length - 1 do
			item(I).Free
	end;
	FList.Clear
end;

constructor TSearchNodeList.Create(AOwnerNode: TNode; const namespaceURI, name: TDomString);
begin
	inherited Create(AOwnerNode);
	FNamespaceParam := namespaceURI;
	FNameParam := name;
	Rebuild
end;

destructor TSearchNodeList.Destroy;
begin
	if Assigned(ownerNode) and Assigned(ownerNode.OwnerDocument) then
		ownerNode.OwnerDocument.RemoveSearchNodeList(Self);
	inherited Destroy
end;

function TSearchNodeList.GetLength: Integer;
begin
	if not FSynchronized then
		Rebuild;
	Result := inherited GetLength
end;

function TSearchNodeList.acceptNode(node: TNode): Boolean;
begin
	//12/14/2021  Html tag names and attribute names are not case sensitive
	Result :=
			(Node.NodeType = ELEMENT_NODE)
			and ((FNamespaceParam = '*') or (FNamespaceParam = node.NamespaceURI))
			and ((FNameParam      = '*') or SameText(FNameParam, node.LocalName))
end;

procedure TSearchNodeList.TraverseTree(rootNode: TNode);
var
	I: Integer;
begin
	if (rootNode <> ownerNode) and acceptNode(rootNode) then
		Add(rootNode);
	for I := 0 to rootNode.ChildNodes.length - 1 do
		TraverseTree(rootNode.ChildNodes.item(I))
end;

procedure TSearchNodeList.Rebuild;
begin
	Clear(false);
	if Assigned(ownerNode) and Assigned(ownerNode.OwnerDocument) then
	begin
		TraverseTree(ownerNode);
		ownerNode.OwnerDocument.AddSearchNodeList(Self)
	end;
	Fsynchronized := true
end;

procedure TSearchNodeList.Invalidate;
begin
	FSynchronized := false
end;

 function TSearchNodeList.item(index: Integer): TNode;
begin
	if not FSynchronized then
		Rebuild;
	Result := inherited item(index)
end;

function TNamedNodeMap.getNamedItem(const name: TDomString): TNode;
var
	I: Integer;
begin
{
	tl;dr: HTML is not case sensitive

	https://www.w3.org/TR/DOM-Level-3-Core/core.html#ID-5DFED1F0

	> 1.3 General Considerations
	> 1.3.1 String Comparisons in the DOM
	>
	> The DOM has many interfaces that imply string matching.
	> For XML, string comparisons are case-sensitive and performed with a binary
	> comparison of the 16-bit units of the DOMStrings.
	>
	> However, for case-insensitive markup languages, such as HTML 4.01 or earlier,
	> these comparisons are ***case-insensitive where appropriate.***
}
	for I := 0 to length - 1 do
	begin
		Result := item(I);
		if SameText(Result.NodeName, name) then
			Exit
	end;
	Result := nil
end;

function TNamedNodeMap.setNamedItem(arg: TNode): TNode;
var
	attr: TAttr;
begin
	if arg.OwnerDocument <> Self.ownerNode.OwnerDocument then
		raise DomException(WRONG_DOCUMENT_ERR);

	if arg.NodeType = ATTRIBUTE_NODE then
	begin
		attr := arg as TAttr;
		if Assigned(attr.ownerElement) and (attr.ownerElement <> ownerNode) then
			raise DomException(INUSE_ATTRIBUTE_ERR)
	end;
	Result := getNamedItem(arg.NodeName);
	if Assigned(Result) then
		Remove(Result);
	Add(arg)
end;

function TNamedNodeMap.removeNamedItem(const name: TDomString): TNode;
var
	node: TNode;
begin
	node := getNamedItem(name);
	if node = nil then
		raise DomException.Create(NOT_FOUND_ERR);
	Remove(node);
	Result := node
end;

function TNamedNodeMap.getNamedItemNS(const namespaceURI, localName: TDomString): TNode;
var
	I: Integer;
begin
	for I := 0 to length - 1 do
	begin
		Result := item(I);
		if SameText(Result.LocalName, localName) and SameText(Result.NamespaceURI, namespaceURI) then
			Exit
	end;
	Result := nil
end;

function TNamedNodeMap.setNamedItemNS(arg: TNode): TNode;
var
	attr: TAttr;
begin
	if arg.OwnerDocument <> Self.ownerNode.OwnerDocument then
		raise DomException(WRONG_DOCUMENT_ERR);
	if arg.NodeType = ATTRIBUTE_NODE then
	begin
		attr := arg as TAttr;
		if Assigned(attr.ownerElement) and (attr.ownerElement <> ownerNode) then
			raise DomException(INUSE_ATTRIBUTE_ERR)
	end;
	Result := getNamedItemNS(arg.NamespaceURI, arg.LocalName);
	if Assigned(Result) then
		Remove(Result);
	Add(arg)
end;

function TNamedNodeMap.removeNamedItemNS(const namespaceURI, localName: TDomString): TNode;
var
	node: TNode;
begin
	node := getNamedItemNS(namespaceURI, localName);
	if node = nil then
		raise DomException.Create(NOT_FOUND_ERR);
	Remove(node);
	Result := node
end;

constructor TCharacterData.Create(ownerDocument: TDocument; const data: TDomString);
begin
	inherited Create(OwnerDocument, '', '', False);
	SetNodeValue(data)
end;

procedure TCharacterData.SetNodeValue(const value: TDomString);
begin
	FNodeValue := value
end;

function TCharacterData.GetLength: Integer;
begin
	Result := System.Length(FNodeValue)
end;

function TCharacterData.GetTextContent: TDomString;
begin
	Result := Self.data;
end;

function TCharacterData.substringData(offset, count: Integer): TDomString;
begin
	if (offset < 0) or (offset >= length) or (count < 0) then
		raise DomException(INDEX_SIZE_ERR);
	Result := Copy(FNodeValue, offset + 1, count)
end;

procedure TCharacterData.appendData(const arg: TDomString);
begin
	FNodeValue := FNodeValue + arg
end;

procedure TCharacterData.insertData(offset: Integer; arg: TDomString);
begin
	replaceData(offset, 0, arg)
end;

procedure TCharacterData.deleteData(offset, count: Integer);
begin
	replaceData(offset, count, '')
end;

procedure TCharacterData.replaceData(offset, count: Integer; const arg: TDomString);
begin
	if (offset < 0) or (offset >= length) or (count < 0) then
		raise DomException(INDEX_SIZE_ERR);
	FNodeValue := substringData(0, offset) + arg + substringData(offset + count, length - (offset + count))
end;

function TCDATASection.GetNodeName: TDomString;
begin
	Result := '#cdata-section'
end;

function TCDATASection.GetNodeType: TNodeType;
begin
	Result := CDATA_SECTION_NODE
end;

function TCDATASection.ExportNode(otherDocument: TDocument; deep: Boolean): TNode;
begin
	Result := otherDocument.createCDATASection(data)
end;

function TCDATASection.cloneNode(deep: Boolean): TNode;
begin
	Result := OwnerDocument.createCDATASection(data)
end;

function TComment.GetNodeName: TDomString;
begin
	Result := '#comment';
end;

function TComment.GetNodeType: TNodeType;
begin
	Result := COMMENT_NODE;
end;

function TComment.ExportNode(otherDocument: TDocument; deep: Boolean): TNode;
begin
	Result := otherDocument.CreateComment(data)
end;

function TComment.cloneNode(deep: Boolean): TNode;
begin
	Result := OwnerDocument.CreateComment(data)
end;

function TTextNode.GetNodeName: TDomString;
begin
	Result := '#text';
end;

function TTextNode.GetNodeType: TNodeType;
begin
	Result := TEXT_NODE
end;

function TTextNode.ExportNode(otherDocument: TDocument; deep: Boolean): TNode;
begin
	Result := otherDocument.CreateTextNode(data)
end;

function TTextNode.cloneNode(deep: Boolean): TNode;
begin
	Result := OwnerDocument.CreateTextNode(data)
end;

function TTextNode.splitText(offset: Integer): TTextNode;
begin
	Result := OwnerDocument.CreateTextNode(substringData(offset, length - offset));
	deleteData(offset, length - offset);
	if Assigned(ParentNode) then
		insertBefore(Result, NextSibling)
end;

function TAttr.GetOwnerElement: TElement;
begin
	Result := FParentNode as TElement
end;

function TAttr.GetNodeValue: TDomString;
begin
	Result := FNodeValue;
end;

function TAttr.GetNodeType: TNodeType;
begin
	Result := ATTRIBUTE_NODE
end;

procedure TAttr.SetNodeValue(const Value: TDomString);
begin
	FNodeValue := Value;
end;

function TAttr.GetParentNode: TNode;
begin
	Result := nil
end;

function TAttr.GetSpecified: Boolean;
begin
	// useless; always returns true
	Result := True;
end;

function TAttr.GetTextContent: TDomString;
begin
	Result := Self.value;
end;

function TAttr.CanInsert(node: TNode): Boolean;
begin
	Result := False; //Attribute value is the value. There is no more child nodes. (You're thinking of XML, which is something else)
end;

function TAttr.ExportNode(ownerDocument: TDocument; deep: Boolean): TNode;
begin
	Result := ownerDocument.createAttribute(name);
	Result.CloneChildNodesFrom(Self)
end;

function TAttr.cloneNode(deep: Boolean): TNode;
begin
	Result := OwnerDocument.createAttribute(name);
	Result.CloneChildNodesFrom(Self)
end;

constructor TElement.Create(ownerDocument: TDocument; const namespaceURI, qualifiedName: TDomString; withNS: Boolean);
begin
	inherited Create(OwnerDocument, NamespaceURI, UpperCase(qualifiedName), withNS);
	FAttributes := TNamedNodeMap.Create(Self);
end;

function TElement.GetNodeType: TNodeType;
begin
	Result := ELEMENT_NODE
end;

function TElement.GetTextContent: TDomString;
var
	i: Integer;
begin
	Result := '';
	for i := 0 to Self.ChildNodes.Length-1 do
		Result := Result+Self.ChildNodes.Item(i).TextContent;
end;

function TElement.CanInsert(node: TNode): Boolean;
begin
	Result := not (node.NodeType in [DOCUMENT_NODE, DOCUMENT_TYPE_NODE]);
end;

function TElement.ExportNode(otherDocument: TDocument; deep: Boolean): TNode;
begin
	Result := otherDocument.createElement(tagName);
	if deep then
		Result.CloneChildNodesFrom(Self)
end;

function TElement.cloneNode(deep: Boolean): TNode;
begin
	Result := OwnerDocument.createElement(tagName);
	if deep then
		Result.CloneChildNodesFrom(Self)
end;

function TElement.getAttributeNode(const name: TDomString): TAttr;
begin
	Result := Attributes.getNamedItem(name) as TAttr
end;

function TElement.getAttribute(const name: TDomString): TDomString;
var
	attr: TAttr;
begin
	attr := getAttributeNode(name);
	if Assigned(attr) then
	Result := attr.value
	else
		Result := ''
end;

procedure TElement.setAttribute(const name, value: TDomString);
var
	newAttr: TAttr;
begin
	newAttr := OwnerDocument.createAttribute(name);
	newAttr.value := value;
	setAttributeNode(newAttr)
end;

function TElement.setAttributeNode(newAttr: TAttr): TAttr;
begin
	if Assigned(newAttr.ownerElement) then
		raise DomException.Create(INUSE_ATTRIBUTE_ERR);
	Result := Attributes.setNamedItem(newAttr) as TAttr;
	if Assigned(Result) then
		Result.FParentNode := nil;
	newAttr.FParentNode := Self
end;

function TElement.removeAttributeNode(oldAttr: TAttr): TAttr;
begin
	if Attributes.IndexOf(oldAttr) < 0 then
		raise DomException.Create(NOT_FOUND_ERR);
	Attributes.Remove(oldAttr);
	oldAttr.FParentNode := nil;
	Result := oldAttr
end;

procedure TElement.removeAttribute(const name: TDomString);
begin
	Attributes.removeNamedItem(name).Free
end;

function TElement.getAttributeNS(const namespaceURI, localName: TDomString): TDomString;
var
	Attr: TAttr;
begin
	Attr := getAttributeNodeNS(namespaceURI, localName);
	if Assigned(Attr) then
		Result := Attr.value
	else
		Result := ''
end;

procedure TElement.setAttributeNS(const namespaceURI, qualifiedName, value: TDomString);
var
	newAttr: TAttr;
begin
	newAttr := OwnerDocument.createAttributeNS(namespaceURI, qualifiedName);
	newAttr.value := value;
	setAttributeNodeNS(newAttr)
end;

procedure TElement.removeAttributeNS(const namespaceURI, localName: TDomString);
begin
	Attributes.removeNamedItemNS(namespaceURI, localName).Free
end;

function TElement.getAttributeNodeNS(const namespaceURI, localName: TDomString): TAttr;
begin
	Result := Attributes.getNamedItemNS(namespaceURI, localName) as TAttr
end;

function TElement.setAttributeNodeNS(newAttr: TAttr): TAttr;
begin
	if Assigned(newAttr.ownerElement) then
		raise DomException.Create(INUSE_ATTRIBUTE_ERR);
	Result := Attributes.setNamedItemNS(newAttr) as TAttr;
	if Assigned(Result) then
		Result.FParentNode := nil;
	newAttr.FParentNode := Self
end;

function TElement.hasAttribute(const name: TDomString): Boolean;
begin
	Result := Assigned(getAttributeNode(name))
end;

function TElement.hasAttributeNS(const namespaceURI, localName: TDomString): Boolean;
begin
	Result := Assigned(getAttributeNodeNS(namespaceURI, localName))
end;

constructor TDocumentType.Create(ownerDocument: TDocument; const name, publicId, systemId: TDomString);
begin
	inherited Create(OwnerDocument, '', name, false);
	FPublicID := publicId;
	FSystemID := systemId
end;

function TDocumentType.GetNodeType: TNodeType;
begin
	Result := DOCUMENT_TYPE_NODE
end;

function TDocumentType.cloneNode(deep: Boolean): TNode;
begin
	Result := TDocumentType.Create(OwnerDocument, name, publicId, systemId)
end;

constructor TDocumentFragment.Create(ownerDocument: TDocument);
begin
	inherited Create(OwnerDocument, '', '', False);
	FNodeName := '#document-fragment';
end;

function TDocumentFragment.GetNodeType: TNodeType;
begin
	Result := DOCUMENT_FRAGMENT_NODE
end;

function TDocumentFragment.GetTextContent: TDomString;
var
	i: Integer;
begin
	Result := '';
	for i := 0 to Self.ChildNodes.Length-1 do
		Result := Result+Self.ChildNodes.Item(i).TextContent;
end;

function TDocumentFragment.GetNodeName: TDomString;
begin
	Result := '#document-fragment'
end;

function TDocumentFragment.CanInsert(node: TNode): Boolean;
begin
	Result := not (node.NodeType in [DOCUMENT_NODE, DOCUMENT_TYPE_NODE]);
end;

function TDocumentFragment.ExportNode(otherDocument: TDocument; deep: Boolean): TNode;
begin
	Result := otherDocument.createDocumentFragment;
	if deep then
		Result.CloneChildNodesFrom(Self)
end;

function TDocumentFragment.cloneNode(deep: Boolean): TNode;
begin
	Result := OwnerDocument.createDocumentFragment;
	if deep then
		Result.CloneChildNodesFrom(Self)
end;

constructor TDocument.Create;
begin
	inherited Create(Self, '', '', False);

	FNamespaceURIList := TNamespaceURIList.Create;
	FSearchNodeLists := TList.Create;

	FNodeName := '#document';
end;

destructor TDocument.Destroy;
begin
	FreeAndNil(FNamespaceURIList);
	FreeAndNil(FSearchNodeLists);
	inherited Destroy
end;

function TDocument.GetBody: TElement;
var
	i: Integer;
	html: TElement;
	node: TNode;
begin
{
	Returns the body element.

	The body element of a document is the first of the html element's children that is
	either a body element or a frameset element, or null if there is no such element.

	The body attribute, on getting, must return the body element of the document (either a body element, a frameset element, or null).
}
	Result := nil;

	html := Self.DocumentElement;
	if html = nil then
		Exit;

	for i := 0 to html.ChildNodes.Length-1 do
	begin
		node := html.ChildNodes.Item(i);
		if node.NodeType <> ELEMENT_NODE then
			Continue;
		if not SameText(node.NodeName, 'BODY') then
			Continue;
		Result := node as TElement;
		Exit;
	end;
end;

function TDocument.GetDocType: TDocumentType;
var
	child: TNode;
	i: Integer;
begin
{
	This is a convenience attribute that allows direct access to the doctype child node.

	Returns nil if no doctype is present.
}
	for i := 0 to ChildNodes.length - 1 do
	begin
		child := ChildNodes.item(i);
		if child.NodeType = DOCUMENT_TYPE_NODE then
		begin
			Result := child as TDocumentType;
			Exit
		end
	end;
	Result := nil
end;

function TDocument.GetDocumentElement: TElement;
var
	child: TNode;
	i: Integer;
begin
{
	This is a convenience attribute that allows direct access to the child node
	that is the document element of the document.

	The document element of a document is the element whose parent is that document,
	if it exists; otherwise null.
}
	for i := 0 to ChildNodes.length - 1 do
	begin
		child := ChildNodes.item(i);
		if child.NodeType = ELEMENT_NODE then
		begin
			Result := child as TElement;
			Exit
		end
	end;
	Result := nil
end;

function TDocument.GetHead: TElement;
var
	i: Integer;
	html: TElement;
	node: TNode;
begin
{
	Returns the head element.

	The head element of a document is the first head element that is a child of the html element, if there is one, or null otherwise.

	The head attribute, on getting, must return the head element of the document (a head element or null).
}
	Result := nil;

	html := Self.DocumentElement;
	if html = nil then
		Exit;

	for i := 0 to html.ChildNodes.Length-1 do
	begin
		node := html.ChildNodes.Item(i);
		if node.NodeType <> ELEMENT_NODE then
			Continue;
		if not SameText(node.NodeName, 'HEAD') then
			Continue;
		Result := node as TElement;
		Exit;
	end;
end;

function TDocument.GetNodeName: TDomString;
begin
	Result := '#document'
end;

function TDocument.GetNodeType: TNodeType;
begin
	Result := DOCUMENT_NODE
end;

procedure TDocument.Clear;
begin
	FNamespaceURIList.Clear;
	FSearchNodeLists.Clear;
	FChildNodes.Clear(False)
end;

procedure TDocument.AddSearchNodeList(NodeList: TNodeList);
begin
	if FSearchNodeLists.IndexOf(NodeList) < 0 then
		FSearchNodeLists.Add(Nodelist)
end;

procedure TDocument.RemoveSearchNodeList(NodeList: TNodeList);
begin
	FSearchNodeLists.Remove(NodeList)
end;

procedure TDocument.InvalidateSearchNodeLists;
var
	I: Integer;
begin
	for I := 0 to FSearchNodeLists.Count - 1 do
		TSearchNodeList(FSearchNodeLists[I]).Invalidate
end;

function TDocument.createDocType(const name, publicId, systemId: TDomString): TDocumentType;
begin
	Result := TDocumentType.Create(Self, name, publicId, systemId)
end;

function TDocument.CanInsert(Node: TNode): Boolean;
begin
	Result :=
		(node.nodeType in [TEXT_NODE, COMMENT_NODE, PROCESSING_INSTRUCTION_NODE, DOCUMENT_TYPE_NODE])
		or
		(node.nodeType = ELEMENT_NODE) and (documentElement = nil)
end;

function TDocument.cloneNode(deep: Boolean): TNode;
begin
	Result := DOMImplementation.createDocument(NamespaceURI, documentElement.NodeName, doctype.cloneNode(false) as TDocumentType)
end;

function TDocument.createElement(const tagName: TDomString): TElement;
begin
	Result := TElement.Create(Self, '', tagName, False)
end;

function TDocument.createDocumentFragment: TDocumentFragment;
begin
	Result := TDocumentFragment.Create(Self)
end;

function TDocument.createTextNode(const data: TDomString): TTextNode;
begin
	Result := TTextNode.Create(Self, data)
end;

function TDocument.CreateComment(const data: TDomString): TComment;
begin
	Result := TComment.Create(Self, data)
end;

function TDocument.createCDATASection(const data: TDomString): TCDATASection;
begin
	Result := TCDATASection.Create(Self, data)
end;

function TDocument.createProcessingInstruction(const target, data: TDomString): TProcessingInstruction;
begin
	Result := TProcessingInstruction.Create(Self, target, data)
end;

function TDocument.createAttribute(const name: TDomString): TAttr;
begin
	Result := TAttr.Create(Self, '', LowerCase(name), False);
	//TODO: Lowercasing the attribute name maybe should be done in the TAttr constructor,
	//and depend on whether a namespace is present.
	//Namespaced attributes may have special semantics, and maybe you can't just lowercase
	//an attribute named "Contoso:ID" into "contoso:id".
end;

//function TDocument.createEntityReference(const name: TDomString): TEntityReference;
//begin
//	//Removed in HTML 5
//	Result := TEntityReference.Create(Self, name)
//end;

function TDocument.importNode(importedNode: TNode; deep: Boolean): TNode;
begin
	Result := importedNode.ExportNode(Self, deep)
end;

function TDocument.createElementNS(const namespaceURI, qualifiedName: TDomString): TElement;
begin
	Result := TElement.Create(Self, namespaceURI, qualifiedName, true)
end;

function TDocument.createAttributeNS(const namespaceURI, qualifiedName: TDomString): TAttr;
begin
	Result := TAttr.Create(Self, namespaceURI, qualifiedName, true)
end;

constructor TProcessingInstruction.Create(ownerDocument: TDocument; const target, data: TDomString);
begin
	inherited Create(OwnerDocument, '', '', False);
	FNodeName := target;
	FNodeValue := data
end;

function TProcessingInstruction.GetTarget: TDomString;
begin
	Result := FNodeName
end;

function TProcessingInstruction.GetData: TDomString;
begin
	Result := FNodeValue
end;

procedure TProcessingInstruction.SetData(const value: TDomString);
begin
	FNodeValue := value
end;

function TProcessingInstruction.GetNodeType: TNodeType;
begin
	Result := PROCESSING_INSTRUCTION_NODE
end;

function TProcessingInstruction.ExportNode(otherDocument: TDocument; deep: Boolean): TNode;
begin
	Result := otherDocument.createProcessingInstruction(target, data)
end;

function TProcessingInstruction.cloneNode(deep: Boolean): TNode;
begin
	Result := OwnerDocument.createProcessingInstruction(target, data)
end;

class function DOMImplementation.hasFeature(const feature, version: TDomString): Boolean;
begin
{
	HTML 5: https://dom.spec.whatwg.org/#dom-domimplementation-hasfeature

	hasFeature() originally would report whether the user agent claimed to support a given DOM feature,
	but experience proved it was not nearly as reliable or granular as simply checking whether the desired objects,
	attributes, or methods existed. As such, it is no longer to be used, but continues to exist (and simply returns true)
	so that old pages don’t stop working.
}
	Result := True;
end;

class function DOMImplementation.createDocumentType(const qualifiedName, publicId, systemId: TDomString): TDocumentType;
begin
	Result := TDocumentType.Create(nil, qualifiedName, publicId, systemId)
end;

class function DomImplementation.createHtmlDocumentType(htmlDocType: Integer): TDocumentType;
begin
	if htmlDocType in [DTD_HTML_STRICT..DTD_XHTML_FRAMESET] then
		with DTDList[htmlDocType] do
			Result := createDocumentType(HTML_TAG_NAME, publicId, systemId)
	else
		Result := nil
end;

class function DOMImplementation.createEmptyDocument(doctype: TDocumentType): TDocument;
begin
	if Assigned(doctype) and Assigned(doctype.ownerDocument) then
		raise DomException.Create(WRONG_DOCUMENT_ERR);

	Result := TDocument.Create;

	if Assigned(docType) then
	begin
		docType.OwnerDocument := Result;
		Result.AppendChild(docType);
	end;
end;

class function DOMImplementation.CreateHtmlDocument(const Title: TDomString=''): TDocument;
var
	doc: TDocument;
	html: TElement;
	head: TElement;
	titleNode: TElement;
begin
{
	https://dom.spec.whatwg.org/#dom-domimplementation-createhtmldocument
}

	doc := TDocument.Create;

	// DOCTYPE html
	doc.AppendChild(doc.createDocType('html', '', ''));

	// Add HTML
	html := doc.AppendChild(doc.CreateElement('HTML')) as TElement;

	// Add HEAD
	head := html.AppendChild(doc.CreateElement('HEAD')) as TElement;
	if Title <> '' then
	begin
		titleNode := head.AppendChild(doc.CreateElement('TITLE')) as TElement;
		titleNode.AppendChild(doc.createTextNode(Title));
	end;

	// Add BODY
	html.AppendChild(doc.createElement('BODY'));

	Result := doc;
end;

class function DOMImplementation.createDocument(const namespaceURI, qualifiedName: TDomString; doctype: TDocumentType=nil): TDocument;
begin
	Result := createEmptyDocument(doctype);
	Result.AppendChild(Result.createElementNS(namespaceURI, qualifiedName))
end;

constructor DomException.Create(ErrorCode: Integer; AdditionalMessage: string);
begin
	inherited Create(ExceptionMsg[ErrorCode]+#13#10+AdditionalMessage);
	FCode := ErrorCode
end;

end.
