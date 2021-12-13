unit Core;

interface

uses
  Classes, SysUtils;

const
  TAB = 9;
  LF = 10;
  CR = 13;
  SP = 32;

  WhiteSpace = [TAB, LF, CR, SP];

  ELEMENT_NODE                   = 1;
  ATTRIBUTE_NODE                 = 2;
  TEXT_NODE                      = 3;
  CDATA_SECTION_NODE             = 4;
  ENTITY_REFERENCE_NODE          = 5;
  ENTITY_NODE                    = 6;
  PROCESSING_INSTRUCTION_NODE    = 7;
  COMMENT_NODE                   = 8;
  DOCUMENT_NODE                  = 9;
  DOCUMENT_TYPE_NODE             = 10;
  DOCUMENT_FRAGMENT_NODE         = 11;
  NOTATION_NODE                  = 12;

  XML_DECL_NODE                  = 201;
  END_TAG_NODE                   = 255;

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

  ExceptionMsg: array[INDEX_SIZE_ERR..INUSE_ATTRIBUTE_ERR] of String = (
    'Index or size is negative, or greater than the allowed value',
    'The specified range of text does not fit into a DOMString',
    'Node is inserted somewhere it doesn''t belong ',
    'Node is used in a different document than the one that created it',
    'Invalid or illegal character is specified, such as in a name',
    'Data is specified for a node which does not support data',
    'An attempt is made to modify an object where modifications are not allowed',
    'An attempt is made to reference a node in a context where it does not exist',
    'Implementation does not support the requested type of object or operation',
    'An attempt is made to add an attribute that is already in use elsewhere'
  );
  
type
  DomException = class(Exception)
  private
    FCode: Integer;
  public
    constructor Create(code: Integer);
    property code: Integer read FCode;
  end;
                        
  TDocument = class;
  TNodeList = class;
  TNamedNodeMap = class;

  TNode = class
  private
    FOwnerDocument: TDocument;
    FNodeName: WideString;
    FNodeValue: WideString;
    FParentNode: TNode;
    FChildNodes: TNodeList;
    FAttributes: TNamedNodeMap;
    function GetFirstChild: TNode;
    function GetLastChild: TNode;
    function GetPreviousSibling: TNode;
    function GetNextSibling: TNode;
  protected
    function GetNodeName: WideString; virtual;
    function GetNodeValue: WideString; virtual;
    function GetNodeType: Integer; virtual; abstract;
    function GetParentNode: TNode; virtual;
    procedure SetNodeValue(const value: WideString); virtual;
  public
    constructor Create(ownerDocument: TDocument);
    destructor Destroy; override;
    function insertBefore(newChild, refChild: TNode): TNode; virtual;
    function replaceChild(newChild, oldChild: TNode): TNode;
    function removeChild(oldChild: TNode): TNode;
    function appendChild(newChild: TNode): TNode;
    function hasChildNodes: Boolean;
    function hasAttributes: Boolean;
    property nodeName: WideString read GetNodeName;
    property nodeValue: WideString read FNodeValue write SetNodeValue;
    property nodeType: Integer read GetNodeType;
    property parentNode: TNode read GetParentNode;
    property childNodes: TNodeList read FChildNodes;
    property firstChild: TNode read GetFirstChild;
    property lastChild: TNode read GetLastChild;
    property previousSibling: TNode read GetPreviousSibling;
    property nextSibling: TNode read GetNextSibling;
    property attributes: TNamedNodeMap read FAttributes;
    property ownerDocument: TDocument read FOwnerDocument;
  end;

  TNodeList = class
  private
    FList: TList;
    function GetLength: Integer;
  public
    constructor Create;
    destructor Destroy; override;
    function IndexOf(node: TNode): Integer;
    procedure Insert(I: Integer; node: TNode);
    procedure Delete(I: Integer);
    procedure Add(node: TNode);
    procedure Remove(node: TNode);
    procedure Clear;
    function item(index: Integer): TNode;
    function firstNode: TNode;
    function lastNode: TNode;
    function previousNode(currNode: TNode): TNode;
    function nextNode(currNode: TNode): TNode;
    property length: Integer read GetLength;
  end;

  TNamedNodeMap = class(TNodeList)
  public
    function getNamedItem(const name: WideString): TNode;
    function setNamedItem(arg: TNode): TNode;
    function removeNamedItem(const name: WideString): TNode;
  end;

  TCharacterData = class(TNode)
  private
    function GetLength: Integer;
  protected
    procedure SetNodeValue(const value: WideString); override;
  public
    constructor Create(ownerDocument: TDocument; const data: WideString);
    function insertBefore(newChild, refChild: TNode): TNode; override;
    function substringData(offset, count: Integer): WideString;
    procedure appendData(const arg: WideString);
    procedure deleteData(offset, count: Integer);
    procedure replaceData(offset, count: Integer; const arg: WideString);
    procedure normalizeWhiteSpace;
    property data: WideString read GetNodeValue write SetNodeValue;
    property length: Integer read GetLength;
  end;

  TElement = class;

  TAttr = class(TNode)
  private
    function GetOwnerElement: TElement;
    function GetLength: Integer;
  protected
    function GetNodeValue: WideString; override;
    function GetNodeType: Integer; override;
    function GetParentNode: TNode; override;
    procedure SetNodeValue(const value: WideString); override;
  public
    constructor Create(ownerDocument: TDocument; const name: WideString);
    function insertBefore(newChild, refChild: TNode): TNode; override;
    property name: WideString read GetNodeName;
    property value: WideString read GetNodeValue write SetNodeValue;
    property ownerElement: TElement read GetOwnerElement;
  end;

  TElement = class(TNode)
  private
    FIsEmpty: Boolean;
  protected
    function GetNodeType: Integer; override;
  public
    constructor Create(ownerDocument: TDocument; const tagName: WideString);
    function insertBefore(newChild, refChild: TNode): TNode; override;
    function getAttribute(const name: WideString): WideString;
    procedure setAttribute(const name, value: WideString);
    procedure removeAttribute(name: WideString);
    function getAttributeNode(const name: WideString): TAttr;
    function setAttributeNode(newAttr: TAttr): TAttr;
    function removeAttributeNode(oldAttr: TAttr): TAttr;
    function hasAttribute(const name: WideString): Boolean;
    property tagName: WideString read GetNodeName;
    property IsEmpty: Boolean read FIsEmpty write FIsEmpty;
  end;

  TTextNode = class(TCharacterData)
  protected
    function GetNodeName: WideString; override;
    function GetNodeType: Integer; override;
  end;

  TComment = class(TCharacterData)
  protected
    function GetNodeName: WideString; override;
    function GetNodeType: Integer; override;
  end;

  TCDATASection = class(TTextNode)
  protected
    function GetNodeName: WideString; override;
    function GetNodeType: Integer; override;
  end;

  TDocumentType = class(TNode)
  private
    FPublicID: WideString;
    FSystemID: WideString;
  protected
    function GetNodeType: Integer; override;
  public
    constructor Create(ownerDocument: TDocument; const name, publicID, systemID: WideString);
    property name: WideString read GetNodeName;
    property publicID: WideString read FPublicID;
    property systemID: WideString read FSystemID;
  end;

  TEntityReference = class(TNode)
  protected
    function GetNodeType: Integer; override;
  public
    constructor Create(ownerDocument: TDocument; const name: WideString);
    property name: WideString read FNodeName;
  end;

  TDocument = class(TNode)
  private
    FDocType: TDocumentType;
    function GetDocumentElement: TElement;
    procedure SetDocType(Value: TDocumentType);
  protected
    function GetNodeName: WideString; override;
    function GetNodeType: Integer; override;
    function createDocType(const name, publicID, systemID: WideString): TDocumentType;
  public
    constructor Create;
    procedure Clear;
    function insertBefore(newChild, refChild: TNode): TNode; override;
    function createElement(const tagName: WideString): TElement; virtual;
    function createTextNode(const data: WideString): TTextNode;
    function createComment(const data: WideString): TComment;
    function createCDATASection(const data: WideString): TCDATASection;
    function createAttribute(const name: WideString): TAttr;
    function createEntityReference(const name: WideString): TEntityReference;
    property doctype: TDocumentType read FDocType write SetDocType;
    property documentElement: TElement read GetDocumentElement;
  end;

  TEndTag = class(TElement)
  protected
    function GetNodeType: Integer; override;
  end;

  TXMLDecl = class(TNode)
  protected
    function GetNodeName: WideString; override;
    function GetNodeType: Integer; override;
  end;

function IsWhiteSpace(W: WideChar): Boolean;
function Concat(const S1, S2: WideString): WideString;

implementation

uses
  Entities;

function Concat(const S1, S2: WideString): WideString;
begin
  Setlength(Result, Length(S1) + Length(S2));
  Move(S1[1], Result[1], 2 * Length(S1));
  Move(S2[1], Result[Length(S1) + 1], 2 * Length(S2))
end;

function IsWhiteSpace(W: WideChar): Boolean;
begin
  Result := Ord(W) in WhiteSpace
end;

constructor DomException.Create(code: Integer);
begin
  inherited Create(ExceptionMsg[code]);
  FCode := code
end;

constructor TNode.Create(ownerDocument: TDocument);
begin
  inherited Create;
  FOwnerDocument := ownerDocument;
  FChildNodes := TNodeList.Create
end;
                       
destructor TNode.Destroy;
begin
  FChildNodes.Clear;
  FChildNodes.Free;
  inherited Destroy
end;

function TNode.GetFirstChild: TNode;
begin
  Result := childNodes.firstNode
end;

function TNode.GetLastChild: TNode;
begin
  Result := childNodes.lastNode
end;

function TNode.GetPreviousSibling: TNode;
begin
  if parentNode <> nil then
    Result := parentNode.childNodes.previousNode(Self)
  else
    Result := nil
end;

function TNode.GetNextSibling: TNode;
begin
  if parentNode <> nil then
    Result := parentNode.childNodes.nextNode(Self)
  else
    Result := nil
end;

function TNode.GetNodeName: WideString;
begin
  Result := FNodeName
end;

function TNode.GetNodeValue: WideString;
begin
  Result := FNodeValue
end;
                            
function TNode.GetParentNode: TNode;
begin
  Result := FParentNode
end;

procedure TNode.SetNodeValue(const value: WideString);
begin
  raise DomException.Create(NO_MODIFICATION_ALLOWED_ERR)
end;
    
function TNode.insertBefore(newChild, refChild: TNode): TNode;
var
  I: Integer;
begin
  if newChild <> refChild then
  begin
    if newChild.ownerDocument <> ownerDocument then
      raise DomException.Create(WRONG_DOCUMENT_ERR);
    I := FChildNodes.IndexOf(newChild);
    if I >= 0 then
      FChildNodes.Delete(I);
    if refChild = nil then
      FChildNodes.Add(newChild)
    else
    begin
      I := FChildNodes.IndexOf(refChild);
      if I < 0 then
        raise DomException.Create(NOT_FOUND_ERR);
      FChildNodes.Insert(I, newChild)
    end;
    newChild.FParentNode := Self
  end;
  Result := newChild
end;

function TNode.replaceChild(newChild, oldChild: TNode): TNode;
begin
  if newChild <> oldChild then
  begin
    insertBefore(newChild, oldChild);
    removeChild(oldChild)
  end;
  Result := oldChild
end;

function TNode.appendChild(newChild: TNode): TNode;
begin
  Result := insertBefore(newChild, nil)
end;

function TNode.removeChild(oldChild: TNode): TNode;
var
  I: Integer;
begin
  I := FChildNodes.IndexOf(oldChild);
  if I < 0 then
    raise DomException.Create(NOT_FOUND_ERR);
  FChildNodes.Delete(I);
  oldChild.FParentNode := nil;
  Result := oldChild
end;

function TNode.hasChildNodes: Boolean;
begin
  Result := FChildNodes.length <> 0
end;

function TNode.hasAttributes: Boolean;
begin
  Result := (FAttributes <> nil) and (FAttributes.length <> 0)
end;
{
procedure TNode.normalize;
var
  childNode: TNode;
  textNode: TTextNode;
  S: WideString;
begin
  I := 0;
  while I < childNodes.length do
  begin
    childNode := childNodes.item(I);
    Inc(I);
    if childNode is TTextNode then
    begin
      textNode := childNode as TTextNode;
    S := '';
    while childNode is TTextNode do
    begin

    Inc(I)
  end
end;
}
constructor TNodeList.Create;
begin
  inherited Create;
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

function TNodeList.firstNode: TNode;
begin
  if length <> 0 then
    Result := FList[0]
  else
    Result := nil
end;

function TNodeList.lastNode: TNode;
begin
  if length <> 0 then
    Result := FList[length - 1]
  else
    Result := nil
end;

function TNodeList.previousNode(currNode: TNode): TNode;
var
  I: Integer;
begin
  I := IndexOf(currNode);
  if I > 0 then
    Result := FList[I - 1]
  else
    Result := nil
end;

function TNodeList.nextNode(currNode: TNode): TNode;
var
  I: Integer;
begin
  I := IndexOf(currNode);
  if (I >= 0) and (I < length - 1) then
    Result := FList[I + 1]
  else
    Result := nil
end;

procedure TNodeList.Clear;
var
  I: Integer;
begin
  for I := 0 to length - 1 do
    item(I).Free
end;

function TNamedNodeMap.getNamedItem(const name: WideString): TNode;
var
  I: Integer;
begin
  for I := 0 to length - 1 do
  begin
    Result := FList[I];
    if Result.nodeName = name then
      Exit
  end;
  Result := nil
end;

function TNamedNodeMap.setNamedItem(arg: TNode): TNode;
begin
  Result := getNamedItem(arg.nodeName);
  if Result <> nil then
    Remove(Result);
  Add(arg)
end;

function TNamedNodeMap.removeNamedItem(const name: WideString): TNode;
var
  Node: TNode;
begin
  Node := getNamedItem(name);
  if Node = nil then
    raise DomException.Create(NOT_FOUND_ERR);
  Remove(Node);
  Result := Node
end;

constructor TEntityReference.Create(ownerDocument: TDocument; const name: WideString);
begin
  inherited Create(ownerDocument);
  FNodeName := name
end;

function TEntityReference.GetNodeType: Integer;
begin
  Result := ENTITY_REFERENCE_NODE
end;

constructor TCharacterData.Create(ownerDocument: TDocument; const data: WideString);
begin
  inherited Create(ownerDocument);
  FNodeValue := data
end;

procedure TCharacterData.SetNodeValue(const value: WideString);
begin
  FNodeValue := value
end;

function TCharacterData.GetLength: Integer;
begin
  Result := System.Length(FNodeValue)
end;

function TCharacterData.insertBefore(newChild, refChild: TNode): TNode;
begin
  raise DomException.Create(HIERARCHY_REQUEST_ERR)
end;

function TCharacterData.substringData(offset, count: Integer): WideString;
begin
  Result := Copy(FNodeValue, offset + 1, count)
end;

procedure TCharacterData.appendData(const arg: WideString);
begin
  FNodeValue := FNodeValue + arg
end;

procedure TCharacterData.deleteData(offset, count: Integer);
begin
  FNodeValue := substringData(0, offset) + substringData(offset + count, length - (offset + count))
end;

procedure TCharacterData.replaceData(offset, count: Integer; const arg: WideString);
begin
  FNodeValue := substringData(0, offset) + arg + substringData(offset + count, length - (offset + count))
end;

procedure TCharacterData.normalizeWhiteSpace;
var
  WS: WideString;
  I, J, Count: Integer;
begin
  SetLength(WS, length);
  J := 0;
  Count := 0;
  for I := 1 to length do
  begin
    if IsWhiteSpace(FNodeValue[I]) then
    begin
      Inc(Count);
      Continue
    end;
    if Count <> 0 then
    begin
      Count := 0;
      Inc(J);
      WS[J] := ' '
    end;
    Inc(J);
    WS[J] := FNodeValue[I]
  end;
  if Count <> 0 then
  begin
    Inc(J);
    WS[J] := ' '
  end;
  SetLength(WS, J);
  FNodeValue := WS
end;

function TCDATASection.GetNodeName: WideString;
begin
  Result := '#cdata-section'
end;

function TCDATASection.GetNodeType: Integer;
begin
  Result := CDATA_SECTION_NODE
end;

function TComment.GetNodeName: WideString;
begin
  Result := '#comment'
end;

function TComment.GetNodeType: Integer;
begin
  Result := COMMENT_NODE
end;

function TTextNode.GetNodeName: WideString;
begin
  Result := '#text'
end;

function TTextNode.GetNodeType: Integer;
begin
  Result := TEXT_NODE
end;

constructor TAttr.Create(ownerDocument: TDocument; const name: WideString);
begin
  inherited Create(ownerDocument);
  FNodeName := name
end;

function TAttr.GetOwnerElement: TElement;
begin
  Result := FParentNode as TElement
end;

function TAttr.GetLength: Integer;
var
  Node: TNode;
  I: Integer;
begin
  Result := 0;
  for I := 0 to childNodes.length - 1 do
  begin
    Node := childNodes.item(I);
    if Node.nodeType = TEXT_NODE then
      Inc(Result, (Node as TTextNode).length)
    else
    if Node.nodeType = ENTITY_REFERENCE_NODE then
      Inc(Result)
  end
end;

function TAttr.GetNodeValue: WideString;
var
  Node: TNode;
  Len, Pos, I, J: Integer;
begin
  Len := GetLength;
  SetLength(Result, Len);
  Pos := 0;
  for I := 0 to childNodes.length - 1 do
  begin
    Node := childNodes.item(I);
    if Node.nodeType = TEXT_NODE then
      for J := 1 to (Node as TTextNode).length do
      begin
        Inc(Pos);
        Result[Pos] := Node.FNodeValue[J]
      end
    else
    if Node.nodeType = ENTITY_REFERENCE_NODE then
    begin
      Inc(Pos);
      Result[Pos] := WideChar(GetEntValue(Node.nodeName))
    end
  end
end;

function TAttr.GetNodeType: Integer;
begin
  Result := ATTRIBUTE_NODE
end;

procedure TAttr.SetNodeValue(const value: WideString);
begin
  childNodes.Clear;
  appendChild(ownerDocument.CreateTextNode(value))
end;

function TAttr.GetParentNode: TNode;
begin
  Result := nil
end;

function TAttr.insertBefore(newChild, refChild: TNode): TNode;
begin
  if not (newChild.nodeType in [ENTITY_REFERENCE_NODE, TEXT_NODE]) then
    raise DomException.Create(HIERARCHY_REQUEST_ERR);
  Result := inherited insertBefore(newChild, refChild)
end;

constructor TElement.Create(ownerDocument: TDocument; const tagName: WideString);
begin
  inherited Create(ownerDocument);
  FAttributes := TNamedNodeMap.Create;
  FNodeName := tagName
end;

function TElement.GetNodeType: Integer;
begin
  Result := ELEMENT_NODE
end;
                    
function TElement.insertBefore(newChild, refChild: TNode): TNode;
begin
  if not (newChild.nodeType in [CDATA_SECTION_NODE, COMMENT_NODE, ELEMENT_NODE, ENTITY_REFERENCE_NODE, TEXT_NODE, PROCESSING_INSTRUCTION_NODE]) then
    raise DomException.Create(HIERARCHY_REQUEST_ERR);
  Result := inherited insertBefore(newChild, refChild)
end;

function TElement.getAttributeNode(const name: WideString): TAttr;
begin
  Result := attributes.getNamedItem(name) as TAttr
end;

function TElement.getAttribute(const name: WideString): WideString;
var
  Attr: TAttr;
begin
  Attr := getAttributeNode(name);
  if Attr <> nil then
    Result := Attr.value
  else
    Result := ''
end;

procedure TElement.setAttribute(const name, value: WideString);
var
  newAttr: TAttr;
begin
  newAttr := ownerDocument.createAttribute(name);
  newAttr.value := value;
  setAttributeNode(newAttr)
end;

function TElement.setAttributeNode(newAttr: TAttr): TAttr;
begin
  if newAttr.ownerElement <> nil then
    raise DomException.Create(INUSE_ATTRIBUTE_ERR);
  Result := attributes.setNamedItem(newAttr) as TAttr;
  if Result <> nil then
    Result.FParentNode := nil;
  newAttr.FParentNode := Self
end;

function TElement.removeAttributeNode(oldAttr: TAttr): TAttr;
begin
  if attributes.IndexOf(oldAttr) < 0 then
    raise DomException.Create(NOT_FOUND_ERR);
  attributes.Remove(oldAttr);
  oldAttr.FParentNode := nil;
  Result := oldAttr
end;

procedure TElement.removeAttribute(name: WideString);
begin
  attributes.removeNamedItem(name).Free
end;

function TElement.hasAttribute(const name: WideString): Boolean;
begin
  Result := getAttributeNode(name) <> nil
end;

function TEndTag.GetNodeType: Integer;
begin
  Result := END_TAG_NODE
end;

function TXMLDecl.GetNodeName: WideString;
begin
  Result := '#xml-decl'
end;

function TXMLDecl.GetNodeType: Integer;
begin
  Result := XML_DECL_NODE
end;

constructor TDocumentType.Create(ownerDocument: TDocument; const name, publicID, systemID: WideString);
begin
  inherited Create(ownerDocument);
  FNodeName := name;
  FPublicID := publicID;
  FSystemID := systemID
end;

function TDocumentType.GetNodeType: Integer;
begin
  Result := DOCUMENT_TYPE_NODE
end;
    
constructor TDocument.Create;
begin
  inherited Create(Self)
end;
    
function TDocument.GetDocumentElement: TElement;
var
  Child: TNode;
  I: Integer;
begin
  for I := 0 to childNodes.length - 1 do
  begin
    Child := childNodes.item(I);
    if Child is TElement then
    begin
      Result := Child as TElement;
      Exit
    end
  end;
  Result := nil
end;
                                     
procedure TDocument.SetDocType(Value: TDocumentType);
begin
  FDocType.Free;
  FDocType := Value
end;

function TDocument.GetNodeName: WideString;
begin
  Result := '#document'
end;

function TDocument.GetNodeType: Integer;
begin
  Result := DOCUMENT_NODE
end;

procedure TDocument.Clear;
begin
  FDocType.Free;
  FDocType := nil;
  childNodes.Clear
end;
                                                         
function TDocument.createDocType(const name, publicID, systemID: WideString): TDocumentType;
begin
  Result := TDocumentType.Create(Self, name, publicID, systemID)
end;

function TDocument.insertBefore(newChild, refChild: TNode): TNode;
begin
  if not (newChild.nodeType in [ELEMENT_NODE, COMMENT_NODE, PROCESSING_INSTRUCTION_NODE]) then
    raise DomException.Create(HIERARCHY_REQUEST_ERR);
  if (newChild.nodeType = ELEMENT_NODE) and (documentElement <> nil) then
    raise DomException.Create(HIERARCHY_REQUEST_ERR);
  Result := inherited insertBefore(newChild, refChild)
end;

function TDocument.createElement(const tagName: WideString): TElement;
begin
  Result := TElement.Create(Self, tagName)
end;

function TDocument.createTextNode(const data: WideString): TTextNode; 
begin
  Result := TTextNode.Create(Self, data)
end;

function TDocument.createComment(const data: WideString): TComment;
begin
  Result := TComment.Create(Self, data)
end;

function TDocument.createCDATASection(const data: WideString): TCDATASection;
begin
  Result := TCDATASection.Create(Self, data)
end;

function TDocument.createAttribute(const name: WideString): TAttr;
begin
  Result := TAttr.Create(Self, name)
end;

function TDocument.createEntityReference(const name: WideString): TEntityReference;
begin
  Result := TEntityReference.Create(Self, name)
end;

end.
