unit DOMTraversal;

interface

uses
  DOMCore;

const
  FILTER_ACCEPT = 1;
  FILTER_REJECT = 2;
  FILTER_SKIP   = 3;

  SHOW_ALL                    = $FFFFFFFF;
  SHOW_ELEMENT                = $00000001;
  SHOW_ATTRIBUTE              = $00000002;
  SHOW_TEXT                   = $00000004;
  SHOW_CDATA_SECTION          = $00000008;
  SHOW_ENTITY_REFERENCE       = $00000010;
  SHOW_ENTITY                 = $00000020;
  SHOW_PROCESSING_INSTRUCTION = $00000040;
  SHOW_COMMENT                = $00000080;
  SHOW_DOCUMENT               = $00000100;
  SHOW_DOCUMENT_TYPE          = $00000200;
  SHOW_DOCUMENT_FRAGMENT      = $00000400;
  SHOW_NOTATION               = $00000800;
  
type
  TNodeFilter = class
  public
    function acceptNode(node: TNode): Integer; virtual;
  end;

  TTraversalObject = class
  protected
    FRootNode: TNode;
    FCurrentNode: TNode;
    FWhatToShow: Integer;
    FNodeFilter: TNodeFilter;
    FExpandEntityReferences: Boolean;
    function acceptNode(node: TNode): Integer;
    constructor Create(ownerDocument: TDocument; root: TNode; whatToShow: Integer;
      filter: TNodeFilter; entityReferenceExpansion: Boolean);
  public
    function nextNode: TNode; virtual;
    function previousNode: TNode; virtual;
    property root: TNode read FRootNode;
    property whatToShow: Integer read FWhatToShow;
    property filter: TNodeFilter read FNodeFilter;
    property expandEntityReferences: Boolean read FExpandEntityReferences;
  end;

  TNodeIterator = class(TTraversalObject)
  private
    FAfterNode: Boolean;
  public
    procedure detach;
  end;

  TTreeWalker = class(TTraversalObject)
  private
    function parentNodeOf(node: TNode): TNode;
    function firstChildOf(node: TNode): TNode;
    function lastChildOf(node: TNode): TNode;       
    function nextSiblingFor(node: TNode): TNode;
    function previousSiblingFor(node: TNode): TNode;
    function nextSiblingOf(node: TNode): TNode;
    function previousSiblingOf(node: TNode): TNode;
  protected
    constructor Create(ownerDocument: TDocument; root: TNode; whatToShow: Integer;
      filter: TNodeFilter; entityReferenceExpansion: Boolean);
  public
    function parentNode: TNode;
    function firstChild: TNode;
    function lastChild: TNode;
    function nextSibbling: TNode;
    function previousSibbling: TNode;
    function nextNode: TNode; override;
    function previousNode: TNode; override;
    property currentNode: TNode read FCurrentNode write FCurrentNode;
  end;

  TDocumentTraversal = class(TDocument)
  public
    function createNodeIterator(root: TNode; whatToShow: Integer; filter: TNodeFilter; entityReferenceExpansion: Boolean): TNodeIterator;
    function createTreeWalker(root: TNode; whatToShow: Integer; filter: TNodeFilter; entityReferenceExpansion: Boolean): TTreeWalker;
  end;

implementation


function TNodeFilter.acceptNode(node: TNode): Integer;
begin
  Result := FILTER_ACCEPT
end;

constructor TTraversalObject.Create(ownerDocument: TDocument; root: TNode; whatToShow: Integer;
  filter: TNodeFilter; entityReferenceExpansion: Boolean);
begin
  inherited Create;
  FRootNode := root;
  FCurrentNode := root;
  FWhatToShow := whatToShow;
  FNodeFilter := filter;
  FExpandEntityReferences := entityReferenceExpansion
end;

function TTraversalObject.acceptNode(node: TNode): Integer;
begin
  if whatToShow = SHOW_ALL then
    Result := FILTER_ACCEPT
  else
  begin
    Result := FILTER_SKIP;
    case node.nodeType of
      ELEMENT_NODE:
        if (whatToShow and SHOW_ELEMENT) <> 0 then
          Result := FILTER_ACCEPT;
      ATTRIBUTE_NODE:
        if (whatToShow and SHOW_ATTRIBUTE) <> 0 then
          Result := FILTER_ACCEPT;
      TEXT_NODE:
        if (whatToShow and SHOW_TEXT) <> 0 then
          Result := FILTER_ACCEPT;   
      CDATA_SECTION_NODE:
        if (whatToShow and SHOW_CDATA_SECTION) <> 0 then
          Result := FILTER_ACCEPT;
      ENTITY_REFERENCE_NODE:
        if (whatToShow and SHOW_ENTITY_REFERENCE) <> 0 then
          Result := FILTER_ACCEPT;
      ENTITY_NODE:
        if (whatToShow and SHOW_ENTITY) <> 0 then
          Result := FILTER_ACCEPT;
      PROCESSING_INSTRUCTION_NODE:
        if (whatToShow and SHOW_PROCESSING_INSTRUCTION) <> 0 then
          Result := FILTER_ACCEPT;
      COMMENT_NODE:
        if (whatToShow and SHOW_COMMENT) <> 0 then
          Result := FILTER_ACCEPT;
      DOCUMENT_NODE:
        if (whatToShow and SHOW_DOCUMENT) <> 0 then
          Result := FILTER_ACCEPT;
      DOCUMENT_TYPE_NODE:
        if (whatToShow and SHOW_DOCUMENT_TYPE) <> 0 then
          Result := FILTER_ACCEPT;
      DOCUMENT_FRAGMENT_NODE:
        if (whatToShow and SHOW_DOCUMENT_FRAGMENT) <> 0 then
          Result := FILTER_ACCEPT;
      NOTATION_NODE:
        if (whatToShow and SHOW_NOTATION) <> 0 then
          Result := FILTER_ACCEPT
      end
    end;
  if (Result = FILTER_ACCEPT) and Assigned(filter) then
    Result := filter.AcceptNode(node)
end;

function TTraversalObject.nextNode: TNode;
begin
end;

function TTraversalObject.previousNode: TNode;
begin
end;

procedure TNodeIterator.detach;
begin
end;

constructor TTreeWalker.Create(ownerDocument: TDocument; root: TNode; whatToShow: Integer;
  filter: TNodeFilter; entityReferenceExpansion: Boolean);
begin
  inherited Create(ownerDocument, root, whatToShow, filter, entityReferenceExpansion);
  currentNode := root
end;

function TTreeWalker.parentNodeOf(node: TNode): TNode;
begin
  Result := node;
  while Result <> root do
  begin
    Result := Result.parentNode;
    if acceptNode(Result) = FILTER_ACCEPT then
      Exit
  end;
  Result := nil
end;

function TTreeWalker.firstChildOf(node: TNode): TNode;
var
  I: Integer;
begin
  for I := 0 to node.childNodes.length - 1 do
  begin
    Result := node.childNodes.item(I);
    case acceptNode(Result) of
      FILTER_ACCEPT:
        Exit;
      FILTER_SKIP:
      begin
        Result := firstChildOf(Result);
        if Result <> nil then
          Exit
      end
    end
  end;
  Result := nil
end;

function TTreeWalker.lastChildOf(node: TNode): TNode;
var
  I: Integer;
begin
  for I := node.childNodes.length - 1 downto 0 do
  begin
    Result := node.childNodes.item(I);
    case acceptNode(Result) of
      FILTER_ACCEPT:
        Exit;
      FILTER_SKIP:
      begin
        Result := lastChildOf(Result);
        if Result <> nil then
          Exit
      end
    end
  end;
  Result := nil
end;

function TTreeWalker.nextSiblingFor(node: TNode): TNode;
var
  child: TNode;
begin
  Result := node.nextSibling;
  while Result <> nil do
  begin
    case acceptNode(Result) of
      FILTER_ACCEPT:
        Exit;
      FILTER_SKIP:
      begin
        child := firstChildOf(Result);
        if child <> nil then
        begin
          Result := child;
          Exit
        end
      end
    end;
    Result := Result.nextSibling
  end
end;

function TTreeWalker.previousSiblingFor(node: TNode): TNode;
var
  child: TNode;
begin
  Result := node.previousSibling;
  while Result <> nil do
  begin
    case acceptNode(Result) of
      FILTER_ACCEPT:
        Exit;
      FILTER_SKIP:
      begin
        child := lastChildOf(Result);
        if child <> nil then
        begin
          Result := child;
          Exit
        end
      end
    end;
    Result := Result.previousSibling
  end
end;

function TTreeWalker.nextSiblingOf(node: TNode): TNode;
var
  currentParent: TNode;
begin
  if currentNode <> root then
  begin
    Result := nextSiblingFor(currentNode);
    if Result <> nil then
      Exit;
    currentParent := currentNode.parentNode;
    while (currentParent <> nil) and (currentParent <> root) and (acceptNode(currentParent) <> FILTER_ACCEPT) do
    begin
      Result := nextSiblingFor(currentNode);
      if Result <> nil then
        Exit
    end
  end;
  Result := nil
end;

function TTreeWalker.previousSiblingOf(node: TNode): TNode;
var
  currentParent: TNode;
begin
  if currentNode <> root then
  begin
    Result := previousSiblingFor(currentNode);
    if Result <> nil then
      Exit;
    currentParent := currentNode.parentNode;
    while (currentParent <> nil) and (currentParent <> root) and (acceptNode(currentParent) <> FILTER_ACCEPT) do
    begin
      Result := previousSiblingFor(currentNode);
      if Result <> nil then
        Exit
    end
  end;
  Result := nil
end;

function TTreeWalker.parentNode: TNode;
begin
  Result := parentNodeOf(currentNode);
  if Result <> nil then
    currentNode := Result
end;

function TTreeWalker.firstChild: TNode;
begin
  Result := firstChildOf(currentNode);
  if Result <> nil then
    currentNode := Result
end;

function TTreeWalker.lastChild: TNode;
begin
  Result := lastChildOf(currentNode);
  if Result <> nil then
    currentNode := Result
end;

function TTreeWalker.nextSibbling: TNode;
begin
  Result := nextSiblingOf(currentNode);
  if Result <> nil then
    currentNode := Result
end;

function TTreeWalker.previousSibbling: TNode;
begin
  Result := previousSiblingOf(currentNode);
  if Result <> nil then
    currentNode := Result
end;

function TTreeWalker.nextNode: TNode;
begin
end;

function TTreeWalker.previousNode: TNode;
begin
end;

function TDocumentTraversal.createNodeIterator(root: TNode; whatToShow: Integer; filter: TNodeFilter; entityReferenceExpansion: Boolean): TNodeIterator;
begin
  Result := TNodeIterator.Create(Self, root, whatToShow, filter, entityReferenceExpansion)
end;

function TDocumentTraversal.createTreeWalker(root: TNode; whatToShow: Integer; filter: TNodeFilter; entityReferenceExpansion: Boolean): TTreeWalker;
begin
  Result := TTreeWalker.Create(Self, root, whatToShow, filter, entityReferenceExpansion)
end;

end.
