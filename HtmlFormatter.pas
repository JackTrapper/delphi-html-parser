unit HtmlFormatter;

interface

uses
  DomCore, HtmlDom, DomTraversal;

type
  TBaseFormatter = class(TCustomFormatter)
  protected
    FTextStr: TDomString;
    FTreeWalker: TTreeWalker;
    function GetWhatToShow: Integer; virtual; abstract;
    function GetNodeFilter: TNodeFilter; virtual; abstract;
    procedure AppendText(const TextStr: TDomString); virtual;
    procedure AppendNewLine;
    procedure AppendParagraphSeparator;
    procedure ProcessChildNodes; virtual;
    procedure ProcessTextNode;
    procedure ProcessEntityReferenceNode;
    procedure ProcessNode; virtual; abstract;
  public
    function getText: TDomString; override;
  end;

  TTextFormatter = class(TBaseFormatter)
  private
    FInsideAnchor: Boolean;
    function GetAnchorText(Node: THtmlElement): TDomString;
    function GetImageText(Node: THtmlElement): TDomString;
    function acceptNode(node: TNode): Integer; override;
    procedure ProcessElement;
  protected
    function GetWhatToShow: Integer; override;
    function GetNodeFilter: TNodeFilter; override;
    procedure ProcessNode; override;
  end;

  THtmlFormatter = class(TBaseFormatter)
  private
    FDepth: Integer;
    procedure ProcessAttributes;
    procedure ProcessElement;
  protected
    function GetWhatToShow: Integer; override;
    function GetNodeFilter: TNodeFilter; override;
    procedure AppendText(const TextStr: TDomString); override;
    procedure ProcessChildNodes; override;
    procedure ProcessNode; override;
  public
    function getText: TDomString; override;
  end;

implementation

uses
  SysUtils, Entities, HtmlTags, HtmlParser;

const
  CRLF: TDomString = #13#10;
  PARAGRAPH_SEPARATOR: TDomString = #13#10#13#10;

  INDENT = #09;

  NodeTypeDelimiterStr: array[ELEMENT_NODE..NOTATION_NODE, 1..2] of string = (
    ('<', 	  '>'),   //ELEMENT_NODE
    ('', 	  ''), 	  //ATTRIBUTE_NODE
    ('', 	  ''), 	  //TEXT_NODE
    ('[CDATA[',   ']]>'), //CDATA_SECTION_NODE
    ('&',	  ';'),   //ENTITY_REFERENCE_NODE
    ('',	  ''),    //ENTITY_NODE
    ('',	  ''),    //PROCESSING_INSTRUCTION_NODE
    ('<!--',	  '-->'), //COMMENT_NODE
    ('',	  ''), 	  //DOCUMENT_NODE
    ('<!DOCTYPE', '>'),	  //DOCUMENT_TYPE_NODE
    ('', 	  ''), 	  //DOCUMENT_FRAGMENT_NODE
    ('',	  '')	  //NOTATION_NODE
  );

  ViewAsBlockTags: THtmlTagSet = [
    ADDRESS_TAG, BLOCKQUOTE_TAG, CAPTION_TAG, CENTER_TAG, DD_TAG, DIV_TAG,
    DL_TAG, DT_TAG, FIELDSET_TAG, FORM_TAG, FRAME_TAG, H1_TAG, H2_TAG, H3_TAG,
    H4_TAG, H5_TAG, H6_TAG, HR_TAG, IFRAME_TAG, LI_TAG, NOFRAMES_TAG, NOSCRIPT_TAG,
    OL_TAG, P_TAG, PRE_TAG, TABLE_TAG, TD_TAG, TH_TAG, TITLE_TAG, UL_TAG
  ];
  HiddenTags: THtmlTagSet = [APPLET_TAG, OBJECT_TAG, SCRIPT_TAG, SELECT_TAG, STYLE_TAG];

function Spaces(Count: Integer): TDomString;
var
  I: Integer;
begin
  SetLength(Result, Count);
  for I := 1 to Count do
    Result[I] := ' '
end;

function GetEntityText(Entity: TEntityReference): TDomString;
begin
  if Entity.nodeName = 'nbsp' then
    Result := ' '
  else
    Result := GetEntValue(Entity.nodeName)
end;

function ViewAsBlockTag(Element: THtmlElement): Boolean;
begin
  Result := Element.HtmlTag.Number in ViewAsBlockTags
end;

function MatchAt(const Signature, HtmlStr: TDomString; Position: Integer; IgnoreCase: Boolean): Boolean;
var
  I, J: Integer;
  W1, W2: WideChar;
begin
  Result := false;
  for I := 1 to Length(Signature) do
  begin
    J := Position + I - 1;
    if (J < 1) or (J > Length(HtmlStr)) then
      Exit;
    W1 := Signature[I];
    W2 := HtmlStr[J];
    if (W1 <> W2) and (not IgnoreCase or (UpperCase(W1) <> UpperCase(W2))) then
      Exit
  end;
  Result := true
end;

function LeftMatch(const Signature, HtmlStr: TDomString): Boolean;
begin
  Result := MatchAt(Signature, HtmlStr, 1, false)
end;

function RightMatch(const Signature, HtmlStr: TDomString): Boolean;
begin
  Result := MatchAt(Signature, HtmlStr, Length(HtmlStr) - Length(Signature) + 1, false)
end;

function TrimLeftSpaces(const S: TDomString): TDomString;
var
  I: Integer;
begin
  I := 1;
  while (I <= Length(S)) and (Ord(S[I]) = SP) do
    Inc(I);
  Result := Copy(S, I, Length(S) - I + 1)
end;

function AppendText(const S1, S2: TDomString): TDomString;
begin
  if RightMatch(CRLF, S1) then
  begin
    Result := S1;
    Result := Result + TrimLeft(S2)
  end
  else
  if LeftMatch(CRLF, S2) then
  begin
    Result := TrimRight(S1);
    Result := Result + S2
  end
  else
  if (S1 = '') or IsWhiteSpace(S1[Length(S1)]) then
  begin
    Result := S1;
    Result := Result + TrimLeftSpaces(S2)
  end
  else
  begin
    Result := S1;
    Result := Result + S2
  end
end;

procedure TBaseFormatter.AppendText(const TextStr: TDomString);
begin
  if (FTextStr = '') or IsWhiteSpace(FTextStr[Length(FTextStr)]) then
    FTextStr := FTextStr + TrimLeftSpaces(TextStr)
  else
    FTextStr := FTextStr + TextStr
end;

procedure TBaseFormatter.AppendNewLine;
begin
  if FTextStr <> '' then
  begin
    if not RightMatch(CRLF, FTextStr) then
      FTextStr := FTextStr + CRLF
  end
end;

procedure TBaseFormatter.AppendParagraphSeparator;
begin
  if FTextStr <> '' then
  begin
    if not RightMatch(CRLF, FTextStr) then
      FTextStr := FTextStr + PARAGRAPH_SEPARATOR
    else
    if not RightMatch(PARAGRAPH_SEPARATOR, FTextStr) then
      FTextStr := FTextStr + CRLF
  end
end;

procedure TBaseFormatter.ProcessChildNodes;
var
  node: TNode;
begin
  node := FTreeWalker.firstChild;
  if node <> nil then
  begin
    repeat
      ProcessNode;
      node := FTreeWalker.nextSibbling
    until node = nil;
    FTreeWalker.parentNode
  end
end;

procedure TBaseFormatter.ProcessTextNode;
begin
  AppendText((FTreeWalker.currentNode as TTextNode).data)
end;

procedure TBaseFormatter.ProcessEntityReferenceNode;
begin
  AppendText(GetEntityText(FTreeWalker.currentNode as TEntityReference))
end;

function TBaseFormatter.getText: TDomString;
begin
  FTextStr := '';
  if htmlDocument.documentElement <> nil then
  begin
    FTreeWalker := htmlDocument.createTreeWalker(htmlDocument.documentElement,
      GetWhatToShow, GetNodeFilter, true);
    try
      ProcessNode
    finally
      FTreeWalker.Free
    end
  end;
  Result := FTextStr
end;

function TTextFormatter.GetAnchorText(Node: THtmlElement): TDomString;
var
  Attr: TAttr;
begin
  Result := '';
  if Node.hasAttribute('href') then
  begin
    Attr := Node.getAttributeNode('href');
    Result := ' ';
    if UrlSchemes.GetScheme(Attr.value) = '' then
      Result := Result + 'http://';
    Result := Result + Attr.value
  end
end;

function TTextFormatter.GetImageText(Node: THtmlElement): TDomString;
begin
  if Node.hasAttribute('alt') then
    Result := Node.getAttributeNode('alt').value
  else
    Result := ''
end;

function TTextFormatter.acceptNode(node: TNode): Integer;
begin
  if (node.nodeType = ELEMENT_NODE) and ((node as THtmlElement).htmlTag.Number in HiddenTags) then
    Result := FILTER_REJECT
  else
    Result := FILTER_ACCEPT
end;

procedure TTextFormatter.ProcessElement;
var
  node: THtmlElement;
begin
  node := FTreeWalker.currentNode as THtmlElement;
  if ViewAsBlockTag(node) then
    AppendParagraphSeparator;
  case node.htmlTag.number of
    A_TAG : FInsideAnchor := true;
    LI_TAG: AppendText('* ')
  end;
  ProcessChildNodes;
  case node.htmlTag.number of
    BR_TAG:
      AppendNewLine;
    A_TAG:
      begin
        AppendText(GetAnchorText(node));
        FInsideAnchor := false
      end;
    IMG_TAG:
      begin
        if FInsideAnchor then
          AppendText(GetImageText(node))
      end
  end;
  if ViewAsBlockTag(Node) then
    AppendParagraphSeparator
end;

function TTextFormatter.GetWhatToShow: Integer;
begin
  Result := SHOW_ELEMENT or SHOW_TEXT
end;

function TTextFormatter.GetNodeFilter: TNodeFilter;
begin
  Result := Self
end;

procedure TTextFormatter.ProcessNode;
begin
  case FTreeWalker.currentNode.nodeType of
    ELEMENT_NODE:          ProcessElement;
    TEXT_NODE:             ProcessTextNode;
    ENTITY_REFERENCE_NODE: ProcessEntityReferenceNode
  end
end;

(*
function THtmlFormatter.GetNodeHtml(Node: TNode): TDomString;
var
  I: Integer;
  nAttribute: integer;
  Element: THtmlElement;
  Attribute: TAttr;
  DocumentType: TDocumentType;
begin
  {Add some future logic to selectivly start a node on a new line}
  case Node.nodeType of
    DOCUMENT_FRAGMENT_NODE,
    DOCUMENT_TYPE_NODE,
    PROCESSING_INSTRUCTION_NODE,
    COMMENT_NODE:
      Result := #13#10;
    ELEMENT_NODE:
    begin
      Result := #13#10 + StringOfChar(INDENT, FDepth);
      Inc(FDepth)
    end
    else
      Result := ''
  end;

  {Open the node i.e. <, <!--, <!DOCTYPE, etc}
  Result := Result + NodeTypeDelimiterStr[Node.nodeType, 1];

  {Put in the contents of the node}
  case Node.nodeType of
    ELEMENT_NODE:
    begin
      Element := Node as THtmlElement;
      Result := Result + Element.tagName;
      {Add any possible attributes to the element}
      if Assigned(Element.attributes) then
      begin
        for nAttribute := 0 to Element.attributes.Length - 1 do
        begin
	  Attribute := (Element.Attributes.item(nAttribute) as TAttr);
	  Result := Result + ' ' + Attribute.name + '="' + Attribute.value + '"'
        end
      end;
      {If the element can't have an end-tag, then add the end-tag here}
      if Element.IsEmpty then
      	Result := Result + '/';
      end;
    TEXT_NODE:
      if Node.nodeValue <> ' ' then
        Result := Result + Node.nodeValue;
    CDATA_SECTION_NODE:
      Result := Result + Node.nodeValue;
    ENTITY_REFERENCE_NODE:
      Result := Result + Node.nodeName; //i.e. the "nbsp" in "&nbsp;"
    ENTITY_NODE:
      { TODO : What is the format of an "Entity"?
      	i don't know what it is.
      	DOM spec says that nodeName is the "entity name"}
      Result := Result + Node.nodeName;
    PROCESSING_INSTRUCTION_NODE:
      { TODO : What is the format of a processing instruction?
        i don't know what it is.
        DOM Spec says nodeName is "target" and nodeValue is "entire content excluding the target"}
      Result := Result + Node.nodeName+'="'+Node.nodeValue+'"';
    COMMENT_NODE:
      Result := Result + Node.nodeValue;
    DOCUMENT_NODE:
      Result := Result + '';
    DOCUMENT_TYPE_NODE:
    begin
      DocumentType := Node as TDocumentType;
      Result := Result+' '+DocumentType.name+' PUBLIC "'+DocumentType.publicID+'"'+#13#10+
      		'"'+DocumentType.systemID+'"';
    end;
    DOCUMENT_FRAGMENT_NODE:
      Result := Result + '';
    NOTATION_NODE:
      Result := Result + '';
    end;

  {Close the node i.e. >, -->, ]]>, etc}
  Result := Result + NodeTypeDelimiterStr[Node.nodeType, 2];

  {Process this Node's children}
  case Node.nodeType of
    {These node types are allowed to have children}
    ELEMENT_NODE,
    ENTITY_REFERENCE_NODE,
    ENTITY_NODE,
    DOCUMENT_NODE,
    DOCUMENT_FRAGMENT_NODE:
      if Node.hasChildNodes then
        for I := 0 to Node.childNodes.length - 1 do
	  Result := Result + GetNodeHtml(Node.childNodes.item(I))
  end;

  {Add an End-Tag if the element is allowed to have one}
  if Node.nodeType = ELEMENT_NODE then
  begin
    Element := Node as THtmlElement;
    Dec(FDepth);
    if not Element.IsEmpty then
    begin
      if Element.hasChildNodes then
      begin
        if Element.childNodes.length >= 2 then
          Result := Result + #13#10 + StringOfChar(INDENT, FDepth)
      end;
      Result := Result + '</' + (Node as THtmlElement).tagName + '>'
    end
  end
(*
begin
  if Node is THtmlElement then
  begin
    Inc(FDepth);
    Result := #13#10'<' + (Node as THtmlElement).tagName;
    if (Node as THtmlElement).IsEmpty then
      Result := Result + '/';
    Result := Result + '>';
    for I := 0 to Node.childNodes.length - 1 do
      Result := Result + GetNodeHtml(Node.childNodes.item(I));
    if not (Node as THtmlElement).IsEmpty then
    begin
      Result := Result + '</' + (Node as THtmlElement).tagName;
      Result := Result + '>'
    end
  end
  else
  if Node.nodeValue <> ' ' then
    Result := Node.nodeValue
  else
    Result := ''

end;
*)
procedure THtmlFormatter.ProcessAttributes;
var
  node: TNode;
  attr: TAttr;
  I: Integer;
begin
  node := FTreeWalker.currentNode;
  for I := 0 to node.attributes.length - 1 do
  begin
    attr := node.attributes.item(I) as TAttr;
    AppendText(' ' + attr.name + '="' + attr.value + '"')
  end
end;

procedure THtmlFormatter.ProcessElement;
var
  node: THtmlElement;
begin
  node := FTreeWalker.currentNode as THtmlElement;
  //if ViewAsBlockTag(node) then
    AppendNewLine;
    AppendText(Spaces(2 * FDepth));
  AppendText('<' + node.tagName);
  ProcessAttributes;
  if node.hasChildNodes then
  begin
    AppendText('>');
    ProcessChildNodes;
    AppendText('</' + node.tagName + '>')
  end
  else
    AppendText(' />');
  //if ViewAsBlockTag(node) then
    AppendNewLine;
    AppendText(Spaces(2 * FDepth))
end;

function THtmlFormatter.GetWhatToShow: Integer;
begin
  Result := SHOW_ALL
end;

function THtmlFormatter.GetNodeFilter: TNodeFilter;
begin
  Result := nil
end;

procedure THtmlFormatter.AppendText(const TextStr: TDomString);
begin
  FTextStr := FTextStr + TextStr
end;

procedure THtmlFormatter.ProcessChildNodes;
begin
  Inc(FDepth);
  inherited ProcessChildnodes;
  Dec(FDepth)
end;

procedure THtmlFormatter.ProcessNode;
begin
  case FTreeWalker.currentNode.nodeType of
    ELEMENT_NODE:          ProcessElement;
    TEXT_NODE:             ProcessTextNode;
    ENTITY_REFERENCE_NODE: ProcessEntityReferenceNode
  end
end;

function THtmlFormatter.getText: TDomString;
begin
  FDepth := 0;
  Result := inherited getText
end;

end.
