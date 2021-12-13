unit HTMLParser;

interface

uses
  Core;

type
  THTMLDocument = class(TDocument)
  private
    FCurrentNode: TNode;
    FPreserveWhiteSpace: Boolean;
    function GetNode(const HtmlStr: WideString; var Position: Integer): TNode;
    function GetTagNode(const HtmlStr: WideString; var Position: Integer): TNode;
    function GetEndTagNode(const HtmlStr: WideString; var Position: Integer): TNode;
    function GetElementNode(const HtmlStr: WideString; var Position: Integer): TNode;
    function GetAttrNode(const HtmlStr: WideString; var Position: Integer): TAttr;
    function GetSpecialNode(const HtmlStr: WideString; var Position: Integer): TNode;
    function IsStartDocumentType(const HtmlStr: WideString; var Position: Integer): Boolean;
    function IsStartCharacterData(const HtmlStr: WideString; var Position: Integer): Boolean;
    function IsStartComment(const HtmlStr: WideString; var Position: Integer): Boolean;
    function GetDocumentType(const HtmlStr: WideString; var Position: Integer): TNode;
    function GetCharacterData(const HtmlStr: WideString; var Position: Integer): TNode;
    function GetComment(const HtmlStr: WideString; var Position: Integer): TNode;
    function GetEntityNode(const HtmlStr: WideString; var Position: Integer): TNode;
    function GetNumericEntityNode(const HtmlStr: WideString; var Position: Integer): TNode;
    function GetHexEntityNode(const HtmlStr: WideString; var Position: Integer): TNode;
    function GetDecEntityNode(const HtmlStr: WideString; var Position: Integer): TNode;
    function GetNamedEntityNode(const HtmlStr: WideString; var Position: Integer): TNode;
    function GetTextNode(const HtmlStr: WideString; var Position: Integer): TNode;
    function GetAttrTextNode(const HtmlStr: WideString; var Position: Integer): TNode;
    function FindThisElement(const tagName: WideString): TElement;
    function FindParent(const tagName: WideString): TElement;
    function FindBlockParent: TElement;
    function FindTableParent: TElement;
    function FindParentElement(tagList: array of WideString): TElement;
    function IsBlockTag(const tagName: WideString): Boolean;
    function IsEmptyTag(const tagName: WideString): Boolean;
    function IsPreserveWhiteSpacesTag(const tagName: WideString): Boolean;
    function IsViewAsBlockTag(const tagName: WideString): Boolean;
    function IsHiddenTag(const tagName: WideString): Boolean;
    function NeedFindParentTag(const tagName: WideString): Boolean;
    function GetDefElementText(Node: TElement): WideString;
    function GetAnchorText(Node: TElement): WideString;
    function GetElementText(Node: TElement): WideString;
    function GetNodeText(Node: TNode): WideString;
    function GetText: WideString;
    procedure ProcessEndTag(EndTag: TEndTag);
    procedure ProcessElement(Element: TElement);
    procedure ProcessTextNode(TextNode: TTextNode);
    procedure ProcessDocumentType(DocumentType: TDocumentType);
    procedure GetAttrValue(Attr: TAttr; const AttrValueStr: WideString);
    procedure PrintNode(var F: TextFile; Node: TNode);
  protected
  public
    function loadHTML(const HtmlStr: WideString): Boolean;
    property text: WideString read GetText;
  end;

implementation

uses
  SysUtils;
  
const
  BlockTagsCount = 18;
  BlockTags: array[0..BlockTagsCount - 1] of WideString = (
    'address', 'blockquote', 'center', 'div', 'dl', 'fieldset', 'form', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'hr', 'noscript', 'ol', 'pre', 'ul'
  );

  BodyTagsCount = 1;
  BodyTags: array[0..BodyTagsCount - 1] of WideString = (
    'body'
  );

  EmptyTagsCount = 13;
  EmptyTags: array[0..EmptyTagsCount - 1] of WideString = (
    'area', 'base', 'basefont', 'br', 'col', 'frame', 'hr', 'img', 'input', 'isindex', 'link', 'meta', 'param'
  );

  PreserveWhiteSpacesTagsCount = 1;
  PreserveWhiteSpacesTags: array[0..PreserveWhiteSpacesTagsCount - 1] of WideString = (
    'pre'
  );

  NeedFindParentTagsCount = 8;
  NeedFindParentTags: array[0..NeedFindParentTagsCount - 1] of WideString = (
    'col', 'colgroup', 'dd', 'dt', 'li', 'option', 'p', 'table'
  );

  ListItemParentTagsCount = 4;
  ListItemParentTags: array[0..ListItemParentTagsCount - 1] of WideString = (
    'dir', 'menu', 'ol', 'ul'
  );

  DefItemParentTagsCount = 1;
  DefItemParentTags: array[0..DefItemParentTagsCount - 1] of WideString = (
    'dl'
  );

  TableSectionParentTagsCount = 1;
  TableSectionParentTags: array[0..TableSectionParentTagsCount - 1] of WideString = (
    'table'
  );

  ColParentTagsCount = 1;
  ColParentTags: array[0..ColParentTagsCount - 1] of WideString = (
    'colgroup'
  );

  RowParentTagsCount = 4;
  RowParentTags: array[0..RowParentTagsCount - 1] of WideString = (
    'table', 'tbody', 'tfoot', 'thead'
  );

  CellParentTagsCount = 1;
  CellParentTags: array[0..CellParentTagsCount - 1] of WideString = (
    'tr'
  );

  OptionParentTagsCount = 2;
  OptionParentTags: array[0..OptionParentTagsCount - 1] of WideString = (
    'optgroup', 'select'
  );

  ViewAsBlockTagsCount = 11;
  ViewAsBlockTags: array[0..ViewAsBlockTagsCount - 1] of WideString = (
    'caption', 'dd', 'dt', 'frame', 'iframe', 'li', 'noframes', 'p', 'th', 'td', 'title'
  );

  HiddenTagsCount = 4;
  HiddenTags : array[0..HiddenTagsCount - 1] of WideString = (
    'applet', 'object', 'script', 'style'
  );

  startTag = Ord('<');
  endTag = Ord('>');
  specialTag = Ord('!');
  slashChar = Ord('/');
  equalChar = Ord('=');
  quotationChar = [Ord(''''), Ord('"')];
  tagDelimiter = [slashChar, endTag];
  tagNameDelimiter = WhiteSpace + tagDelimiter;
  attrNameDelimiter = tagNameDelimiter + [equalChar];
  startEntity = Ord('&');
  startMarkup = [startTag, startEntity];
  endEntity = Ord(';');
  notEntity = [endEntity] + startMarkup + WhiteSpace;
  numericEntity = Ord('#');
  hexEntity = [Ord('x'), Ord('X')];
  decDigit = [Ord('0')..Ord('9')];
  hexDigit = decDigit + [Ord('a')..Ord('f'), Ord('A')..Ord('F')];

  rootNodeName = 'html';
  
  CRLF: WideString = #13#10#13#10;
  DocTypeStartStr = 'DOCTYPE';
  DocTypeEndStr = '>';
  CDataStartStr = '[CDATA[';
  CDataEndStr = ']]>';
  CommentStartStr = '--';
  CommentEndStr = '-->';
  
type
  TDelimiters = set of Byte;
  
function Search(const tagName: WideString; tagList: array of WideString): Boolean;
var
  I: Integer;
begin
  Result := true;
  for I := 0 to High(tagList) do
    if tagName = tagList[I] then
      Exit;
  Result := false
end;

function IsStartMarkupChar(WC: WideChar): Boolean;
begin
  Result := Ord(WC) in startMarkup
end;

function IsStartTagChar(WC: WideChar): Boolean;
begin
  Result := Ord(WC) = startTag
end;

function IsEndTagChar(WC: WideChar): Boolean;
begin
  Result := Ord(WC) = endTag
end;

function IsSpecialTagChar(WC: WideChar): Boolean;
begin
  Result := Ord(WC) = specialTag
end;

function IsTagDelimiter(WC: WideChar): Boolean;
begin
  Result := Ord(WC) in tagDelimiter
end;

function IsTagNameDelimiter(WC: WideChar): Boolean;
begin
  Result := Ord(WC) in tagNameDelimiter
end;

function IsSlashChar(WC: WideChar): Boolean;
begin
  Result := Ord(WC) = slashChar
end;

function IsEqualChar(WC: WideChar): Boolean;
begin
  Result := Ord(WC) = equalChar
end;

function IsQuotation(WC: WideChar): Boolean;
begin
  Result := Ord(WC) in quotationChar
end;

function IsStartEntityChar(WC: WideChar): Boolean;
begin
  Result := Ord(WC) = startEntity
end;

function IsEndEntityChar(WC: WideChar): Boolean;
begin
  Result := Ord(WC) = endEntity
end;

function IsNumericEntity(WC: WideChar): Boolean;
begin
  Result := Ord(WC) = numericEntity
end;

function IsHexEntity(WC: WideChar): Boolean;
begin
  Result := Ord(WC) in hexEntity
end;

function IsDecDigit(WC: WideChar): Boolean;
begin
  Result := Ord(WC) in decDigit
end;

function IsHexDigit(WC: WideChar): Boolean;
begin
  Result := Ord(WC) in hexDigit
end;

function IsEntityChar(WC: WideChar): Boolean;
begin
  Result := not (Ord(WC) in notEntity)
end;

function DecValue(const Digit: WideChar): Word;
begin
  Result := Ord(Digit) - Ord('0')
end;

function HexValue(const HexDigit: WideChar): Word;
var
  C: Char;
begin
  if IsDecDigit(HexDigit) then
    Result := Ord(HexDigit) - Ord('0')
  else
  begin
    C := Chr(Ord(HexDigit));
    Result := Ord(UpCase(C)) - Ord('A')
  end
end;

function GetToken(const HtmlStr: WideString; var Position: Integer; Delimiters: TDelimiters): WideString;
var
  Start: Integer;
begin
  Start := Position;
  while (Position <= Length(HtmlStr)) and not (Ord(HtmlStr[Position]) in Delimiters) do
    Inc(Position);
  Result := Copy(HtmlStr, Start, Position - Start)
end;

procedure SkipWhiteSpaces(const HtmlStr: WideString; var Position: Integer);
begin
  while (Position <= Length(HtmlStr)) and (Ord(HtmlStr[Position]) in WhiteSpace) do
    Inc(Position)
end;

function MatchAt(const Signature, HtmlStr: WideString; Position: Integer): Boolean;
var
  I, J: Integer;
begin
  Result := false;
  for I := 1 to Length(Signature) do
  begin
    J := Position + I - 1;
    if (J < 1) or (J > Length(HtmlStr)) or (Ord(HtmlStr[J]) <> Ord(Signature[I])) then
      Exit
  end;
  Result := true
end;

function RightMatch(const Signature, HtmlStr: WideString): Boolean;
begin
  Result := MatchAt(Signature, HtmlStr, Length(HtmlStr) - Length(Signature) + 1)
end;

procedure SkipTo(const Signature, HtmlStr: WideString; var Position: Integer);
begin
  while Position <= Length(HtmlStr) do
  begin
    if MatchAt(Signature, HtmlStr, Position) then
    begin
      Inc(Position, Length(Signature));
      Exit
    end;
    Inc(Position)
  end
end;

function GetQuotedValue(const HtmlStr: WideString; var Position: Integer): WideString;
var
  QuotedChar: WideChar;
  Start: Integer;
begin
  QuotedChar := HtmlStr[Position];
  Inc(Position);
  Start := Position;
  SkipTo(QuotedChar, HtmlStr, Position);
  Result := Copy(HtmlStr, Start, Position - Start - 1)
end;

function GetValue(const HtmlStr: WideString; var Position: Integer): WideString;
begin
  SkipWhiteSpaces(HtmlStr, Position);
  if Position <= Length(HtmlStr) then
  begin
    if IsQuotation(HtmlStr[Position]) then
      Result := GetQuotedValue(HtmlStr, Position)
    else
      Result := GetToken(HtmlStr, Position, tagNameDelimiter)
  end
end;

{
procedure TCharacterData.trimLeft;
var
  I: Integer;
begin
  I := 0;
  while (I <= length) and IsWhiteSpace(FNodeValue[I]) do
    Inc(I);
  System.Delete(FNodeValue, 1, I)
end;

procedure TCharacterData.trimRight;
var
  I: Integer;
begin
  I := length;
  while (I > 0) and IsWhiteSpace(FNodeValue[I]) do
    Dec(I);
  SetLength(FNodeValue, I)
end;

procedure TCharacterData.trimBoth;
begin
  trimRight;
  trimLeft
end;
}
function THTMLDocument.GetNode(const HtmlStr: WideString; var Position: Integer): TNode;
begin
  if Position > Length(HtmlStr) then
    Result := nil
  else
  if IsStartTagChar(HtmlStr[Position]) then
    Result := GetTagNode(HtmlStr, Position)
  else
  if IsStartEntityChar(HtmlStr[Position]) then
    Result := GetEntityNode(HtmlStr, Position)
  else
    Result := GetTextNode(HtmlStr, Position)
end;

function THTMLDocument.GetTagNode(const HtmlStr: WideString; var Position: Integer): TNode;
begin
  if Position < Length(HtmlStr) then
  begin
    Inc(Position);
    if IsSlashChar(HtmlStr[Position]) then
      Result := GetEndTagNode(HtmlStr, Position)
    else
    if IsSpecialTagChar(HtmlStr[Position]) then
      Result := GetSpecialNode(HtmlStr, Position)
    else
      Result := GetElementNode(HtmlStr, Position)
  end
  else
    Result := nil
end;

function THTMLDocument.GetEndTagNode(const HtmlStr: WideString; var Position: Integer): TNode;
begin
  Inc(Position);
  if Position < Length(HtmlStr) then
  begin
    Result := TEndTag.Create(Self, LowerCase(GetToken(HtmlStr, Position, tagNameDelimiter)));
    SkipTo('>', HtmlStr, Position)
  end
  else
    Result := nil
end;

function THTMLDocument.GetElementNode(const HtmlStr: WideString; var Position: Integer): TNode;
var
  Attr: TAttr;
begin
  if Position < Length(HtmlStr) then
  begin
    Result := createElement(LowerCase(GetToken(HtmlStr, Position, tagNameDelimiter)));
    with Result as TElement do
    begin
      Attr := GetAttrNode(HtmlStr, Position);
      while Attr <> nil do
      begin
        setAttributeNode(Attr);
        Attr := GetAttrNode(HtmlStr, Position)
      end;
      SkipWhiteSpaces(HtmlStr, Position);
      if (Position <= Length(HtmlStr)) and IsSlashChar(HtmlStr[Position]) then
      begin
        IsEmpty := true;
        Inc(Position)
      end;
      SkipTo('>', HtmlStr, Position)
    end
  end
  else
    Result := nil
end;

function THTMLDocument.GetAttrNode(const HtmlStr: WideString; var Position: Integer): TAttr;
var
  name: WideString;
begin
  SkipWhiteSpaces(HtmlStr, Position);
  name := GetToken(HtmlStr, Position, attrNameDelimiter);
  if name <> '' then
  begin
    Result := createAttribute(name);
    SkipWhiteSpaces(HtmlStr, Position);
    if IsEqualChar(HtmlStr[Position]) then
    begin
      Inc(Position);
      GetAttrValue(Result, GetValue(HtmlStr, Position))
    end
    else
      Result.value := name 
  end
  else
    Result := nil
end;

procedure THTMLDocument.GetAttrValue(Attr: TAttr; const AttrValueStr: WideString);
var
  Position: Integer;
begin
  Position := 1;
  while Position <= Length(AttrValueStr) do
  begin
    if IsStartEntityChar(AttrValueStr[Position]) then
      Attr.appendChild(GetEntityNode(AttrValueStr, Position))
    else
      Attr.appendChild(GetAttrTextNode(AttrValueStr, Position))
  end
end;

function THTMLDocument.GetSpecialNode(const HtmlStr: WideString; var Position: Integer): TNode;
begin
  if Position < Length(HtmlStr) then
  begin
    Inc(Position);
    if IsStartDocumentType(HtmlStr, Position) then
      Result := GetDocumentType(HtmlStr, Position)
    else
    if IsStartCharacterData(HtmlStr, Position) then
      Result := GetCharacterData(HtmlStr, Position)
    else
    if IsStartComment(HtmlStr, Position) then
      Result := GetComment(HtmlStr, Position)
    else
      Result := nil
  end
  else
    Result := nil
end;

function THTMLDocument.IsStartDocumentType(const HtmlStr: WideString; var Position: Integer): Boolean;
begin
  Result := MatchAt(DocTypeStartStr, HtmlStr, Position)
end;

function THTMLDocument.IsStartCharacterData(const HtmlStr: WideString; var Position: Integer): Boolean;
begin
  Result := MatchAt(CDataStartStr, HtmlStr, Position)
end;

function THTMLDocument.IsStartComment(const HtmlStr: WideString; var Position: Integer): Boolean;
begin
  Result := MatchAt(CommentStartStr, HtmlStr, Position)
end;

function THTMLDocument.GetDocumentType(const HtmlStr: WideString; var Position: Integer): TNode;
var
  name, publicID, systemID: WideString;
begin
  Inc(Position, Length(DocTypeStartStr));
  SkipWhiteSpaces(HtmlStr, Position);
  name := GetToken(HtmlStr, Position, tagNameDelimiter);
  SkipWhiteSpaces(HtmlStr, Position);
  GetToken(HtmlStr, Position, tagNameDelimiter);
  SkipWhiteSpaces(HtmlStr, Position);
  publicID := GetQuotedValue(HtmlStr, Position);
  SkipWhiteSpaces(HtmlStr, Position);
  systemID := GetQuotedValue(HtmlStr, Position);
  Result := createDocType(name, publicID, systemID);
  SkipTo(DocTypeEndStr, HtmlStr, Position)
end;

function THTMLDocument.GetCharacterData(const HtmlStr: WideString; var Position: Integer): TNode;
var
  StartPos: Integer;
begin
  Inc(Position, Length(CDataStartStr));
  StartPos := Position;
  SkipTo(CDataEndStr, HtmlStr, Position);
  Result := createCDATASection(Copy(HtmlStr, StartPos, Position - StartPos - Length(CDataEndStr) + 1))
end;

function THTMLDocument.GetComment(const HtmlStr: WideString; var Position: Integer): TNode;
var
  StartPos: Integer;
begin
  Inc(Position, Length(CommentStartStr));
  StartPos := Position;
  SkipTo(CommentEndStr, HtmlStr, Position);
  Result := createComment(Copy(HtmlStr, StartPos, Position - StartPos - Length(CommentEndStr) + 1))
end;

function THTMLDocument.GetEntityNode(const HtmlStr: WideString; var Position: Integer): TNode;
begin
  if Position < Length(HtmlStr) then
  begin
    Inc(Position);
    if IsNumericEntity(HtmlStr[Position]) then
    begin
      Inc(Position);
      Result := GetNumericEntityNode(HtmlStr, Position)
    end
    else
      Result := GetNamedEntityNode(HtmlStr, Position)
  end
  else
    Result := createTextNode(HtmlStr[Position])
end;

function THTMLDocument.GetTextNode(const HtmlStr: WideString; var Position: Integer): TNode;
var
  Start: Integer;
begin
  Start := Position;
  repeat
    Inc(Position)
  until (Position > Length(HtmlStr)) or IsStartMarkupChar(HtmlStr[Position]);
  Result := createTextNode(Copy(HtmlStr, Start, Position - Start))
end;

function THTMLDocument.GetAttrTextNode(const HtmlStr: WideString; var Position: Integer): TNode;
var
  Start: Integer;
begin
  Start := Position;
  repeat
    Inc(Position)
  until (Position > Length(HtmlStr)) or IsStartEntityChar(HtmlStr[Position]);
  Result := createTextNode(Copy(HtmlStr, Start, Position - Start))
end;

function THTMLDocument.GetHexEntityNode(const HtmlStr: WideString; var Position: Integer): TNode;
var
  Start: Integer;
  Value: Word;
begin
  Start := Position;
  Value := 0;
  while (Position <= Length(HtmlStr)) and IsHexDigit((HtmlStr[Position])) do
  begin
    Value := Value shl 4 + HexValue(HtmlStr[Position]);
    Inc(Position)
  end;
  if (Position <= Length(HtmlStr)) and IsEndEntityChar((HtmlStr[Position])) then
  begin
    Result := createTextNode(WideChar(Value));
    Inc(Position)
  end
  else
    Result := createTextNode(Copy(HtmlStr, Start, Position - Start))
end;

function THTMLDocument.GetDecEntityNode(const HtmlStr: WideString; var Position: Integer): TNode;
var
  Start: Integer;
  Value: Word;
begin
  Start := Position;
  Value := 0;
  while (Position <= Length(HtmlStr)) and IsDecDigit((HtmlStr[Position])) do
  begin
    Value := Value * 10 + DecValue(HtmlStr[Position]);
    Inc(Position)
  end;
  if (Position <= Length(HtmlStr)) and IsEndEntityChar((HtmlStr[Position])) then
  begin
    Result := createTextNode(WideChar(Value));
    Inc(Position)
  end
  else
    Result := createTextNode(Copy(HtmlStr, Start, Position - Start))
end;

function THTMLDocument.GetNumericEntityNode(const HtmlStr: WideString; var Position: Integer): TNode;
begin
  if IsHexEntity(HtmlStr[Position]) then
  begin
    Inc(Position);
    Result := GetHexEntityNode(HtmlStr, Position)
  end
  else
    Result := GetDecEntityNode(HtmlStr, Position)
end;

function THTMLDocument.GetNamedEntityNode(const HtmlStr: WideString; var Position: Integer): TNode;
var
  Start: Integer;
begin
  Start := Position;
  while (Position <= Length(HtmlStr)) and IsEntityChar((HtmlStr[Position])) do
    Inc(Position);
  if (Position <= Length(HtmlStr)) and IsEndEntityChar((HtmlStr[Position])) then
  begin
    Result := createEntityReference(Copy(HtmlStr, Start, Position - Start));
    Inc(Position)
  end
  else
    Result := createTextNode(Copy(HtmlStr, Start, Position - Start))
end;

function THTMLDocument.FindThisElement(const tagName: WideString): TElement;
var
  Node: TNode;
begin
  Node := FCurrentNode;
  while Node is TElement do
  begin
    Result := Node as TElement;
    if Result.tagName = tagName then
      Exit;
    Node := Node.parentNode
  end;
  Result := nil
end;

function THTMLDocument.FindParentElement(tagList: array of WideString): TElement;
var
  Node: TNode;
begin
  Node := FCurrentNode;
  while Node is TElement do
  begin
    Result := Node as TElement;
    if Search(Result.tagName, tagList) then
      Exit;
    Node := Node.parentNode
  end;
  Result := nil
end;

function THTMLDocument.FindBlockParent: TElement;
begin
  Result := FindParentElement(BlockTags);
  if Result = nil then
    Result := FindParentElement(BodyTags)
end;

function THTMLDocument.FindTableParent: TElement;
var
  Node: TNode;
begin
  Node := FCurrentNode;
  while Node is TElement do
  begin
    Result := Node as TElement;
    if (Result.tagName = 'td') or IsBlockTag(Result.tagName) then
      Exit;
    Node := Node.parentNode
  end;
  Result := FindParentElement(BodyTags)
end;

function THTMLDocument.FindParent(const tagName: WideString): TElement;
begin
  if (tagName = 'p') or IsBlockTag(tagName) then
    Result := FindBlockParent
  else
  if tagName = 'li' then
    Result := FindParentElement(ListItemParentTags)
  else
  if (tagName = 'dd') or (tagName = 'dt') then
    Result := FindParentElement(DefItemParentTags)
  else
  if (tagName = 'td') or (tagName = 'th') then
    Result := FindParentElement(CellParentTags)
  else
  if tagName = 'tr' then
    Result := FindParentElement(RowParentTags)
  else
  if tagName = 'col' then
    Result := FindParentElement(ColParentTags)
  else
  if (tagName = 'colgroup') or (tagName = 'thead') or (tagName = 'tfoot') or (tagName = 'tbody') then
    Result := FindParentElement(TableSectionParentTags)
  else
  if tagName = 'table' then
    Result := FindTableParent
  else
  if tagName = 'option' then
    Result := FindParentElement(OptionParentTags)
  else
    Result := nil
end;

function THTMLDocument.IsBlockTag(const tagName: WideString): Boolean;
begin
  Result := Search(tagName, BlockTags)
end;

function THTMLDocument.IsViewAsBlockTag(const tagName: WideString): Boolean;
begin
  Result := IsBlockTag(tagName) or Search(tagName, ViewAsBlockTags)
end;
                                       
function THTMLDocument.IsHiddenTag(const tagName: WideString): Boolean;
begin
  Result := Search(tagNAme, HiddenTags)
end;

function THTMLDocument.IsEmptyTag(const tagName: WideString): Boolean;
begin
  Result := Search(tagName, EmptyTags)
end;

function THTMLDocument.IsPreserveWhiteSpacesTag(const tagName: WideString): Boolean;
begin
  Result := Search(tagName, PreserveWhiteSpacesTags)
end;

function THTMLDocument.NeedFindParentTag(const tagName: WideString): Boolean;
begin
  Result := IsBlockTag(tagName) or Search(tagName, NeedFindParentTags)
end;

procedure THTMLDocument.ProcessEndTag(EndTag: TEndTag);
var
  Node: TElement;
begin                           
  if IsPreserveWhiteSpacesTag(EndTag.tagName) then
    FPreserveWhiteSpace := false;
  Node := FindThisElement(EndTag.tagName);
  if Node <> nil then
    FCurrentNode := Node.parentNode
  else
  if IsBlockTag(EndTag.tagName) then
    raise DomException.Create(HIERARCHY_REQUEST_ERR)
end;

procedure THTMLDocument.ProcessElement(Element: TElement);
var
  Node: TElement;
begin
  if IsPreserveWhiteSpacesTag(Element.tagName) then
    FPreserveWhiteSpace := true;
  if NeedFindParentTag(Element.tagName) then
  begin
    Node := FindParent(Element.tagName);
    if Node = nil then
      raise DomException.Create(HIERARCHY_REQUEST_ERR);
    FCurrentNode := Node
  end;
  FCurrentNode.appendChild(Element);
  if not (Element.IsEmpty or IsEmptyTag(Element.tagName)) then
    FCurrentNode := Element
end;

procedure THTMLDocument.ProcessTextNode(TextNode: TTextNode);
begin
  if FCurrentNode is TElement then
  begin
    if not FPreserveWhiteSpace then
      TextNode.normalizeWhiteSpace;
    if TextNode.length <> 0 then
    begin
      if FCurrentNode.lastChild is TTextNode then
      begin
        (FCurrentNode.lastChild as TTextNode).appendData(TextNode.data);
        TextNode.Free
      end
      else
        FCurrentNode.appendChild(TextNode)
    end
  end
end;

procedure THTMLDocument.ProcessDocumentType(DocumentType: TDocumentType);
begin
  doctype := DocumentType
end;

function THTMLDocument.loadHTML(const HtmlStr: WideString): Boolean;
var
  Node: TNode;
  Position: Integer;
//  F: TextFile;
begin
  Position := 1;
  try
    Clear;
    FCurrentNode := Self;
    Node := GetNode(HtmlStr, Position);
    while Node <> nil do
    begin
      if Node is TEndTag then
        ProcessEndTag(Node as TEndTag)
      else
      if Node is TElement then
        ProcessElement(Node as TElement)
      else
      if Node is TTextNode then
        ProcessTextNode(Node as TTextNode)
      else
      if Node is TDocumentType then
        ProcessDocumentType(Node as TDocumentType)
      else
        FCurrentNode.appendChild(Node);
      Node := GetNode(HtmlStr, Position)
    end;
    Result := true
  except
    Result := false
  end;
{  AssignFile(F, 'AD.dmp');
  Rewrite(F);
  PrintNode(F, Self);
  CloseFile(F)}
end;

procedure THTMLDocument.PrintNode(var F: TextFile; Node: TNode);
var
  S: String;
  I: Integer;
begin
  if Node is TElement then
  begin
    S := '<' + (Node as TElement).tagName;
    if (Node as TElement).IsEmpty then
      S := S + '/';
    S := S + '>';
    Write(F, S)
  end;
  for I := 0 to Node.childNodes.length - 1 do
    PrintNode(F, Node.childNodes.item(I));
  if Node is TElement then
  begin
    S := '</' + (Node as TElement).tagName;
    S := S + '>';
    Write(F, S)
  end;
end;

function AppendNewLine(const S: WideString): WideString;
begin
  if (S = '') or RightMatch(CRLF, S) then
    Result := S
  else
    Result := S + CRLF
end;

function AppendText(const S1, S2: WideString): WideString;
begin
  if (S1 = '') or IsWhiteSpace(S1[Length(S1)]) or RightMatch(CRLF, S1) then
    Result := S1 + TrimLeft(S2)
  else
    Result := S1 + S2
end;

function THTMLDocument.GetDefElementText(Node: TElement): WideString;
var
  childNode: TNode;
  S: WideString;
  I: Integer;
begin
  Result := '';
  if not IsHiddenTag(Node.tagName) then
    for I := 0 to Node.childNodes.length - 1 do
    begin
      childNode := Node.childNodes.item(I);
      S := GetNodeText(childNode);
      if (childNode is TElement) and IsViewAsBlockTag((childNode as TElement).tagName) then
      begin
        S := Trim(S);
        if S <> '' then
        begin
          Result := AppendNewLine(Result);
          Result := Result + S;
          Result := AppendNewLine(Result)
        end
      end
      else
        Result := AppendText(Result, S)
    end
end;

function THTMLDocument.GetAnchorText(Node: TElement): WideString;
var
  Attr: TAttr;
begin
  Result := GetDefElementText(Node);
  if Node.hasAttribute('href') then
  begin
    Attr := Node.getAttributeNode('href');
    if Attr.value <> Result then
      Result := Result + ' ' + Attr.value
  end
end;

function THTMLDocument.GetElementText(Node: TElement): WideString;
begin
  if Node.tagName = 'a' then
    Result := GetAnchorText(Node)
  else
    Result := GetDefElementText(Node)
end;

function THTMLDocument.GetNodeText(Node: TNode): WideString;
begin
  if Node is TElement then
    Result := GetElementText(Node as TElement)
  else
  if Node is TTextNode then
    Result := Node.nodeValue
  else
    Result := ''
end;

function THTMLDocument.GetText: WideString;
begin
  Result := GetNodeText(documentElement)
end;

end.
