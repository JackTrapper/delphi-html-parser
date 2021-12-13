unit HTMLParser;

interface

uses
  Classes, DomCore, HtmlDom, HtmlTags;

type
  THtmlParser = class(TCustomParser)
  private
    FCurrentNode: TNode;
    FPreserveWhiteSpace: Boolean;
    function GetNode(const HtmlStr: TDomString; var Position: Integer): TNode;
    function GetTagNode(const HtmlStr: TDomString; var Position: Integer): TNode;
    function GetEndTagNode(const HtmlStr: TDomString; var Position: Integer): TNode;
    function GetElementNode(const HtmlStr: TDomString; var Position: Integer): TNode;
    function GetAttrNode(const HtmlStr: TDomString; var Position: Integer): TAttr;
    function GetSpecialNode(const HtmlStr: TDomString; var Position: Integer): TNode;
    function IsStartDocumentType(const HtmlStr: TDomString; var Position: Integer): Boolean;
    function IsStartCharacterData(const HtmlStr: TDomString; var Position: Integer): Boolean;
    function IsStartComment(const HtmlStr: TDomString; var Position: Integer): Boolean;
    function GetDocumentType(const HtmlStr: TDomString; var Position: Integer): TNode;
    function GetCharacterData(const HtmlStr: TDomString; var Position: Integer): TNode;
    function GetComment(const HtmlStr: TDomString; var Position: Integer): TNode;
    function GetEntityNode(const HtmlStr: TDomString; var Position: Integer): TNode;
    function GetNumericEntityNode(const HtmlStr: TDomString; var Position: Integer): TNode;
    function GetHexEntityNode(const HtmlStr: TDomString; var Position: Integer): TNode;
    function GetDecEntityNode(const HtmlStr: TDomString; var Position: Integer): TNode;
    function GetNamedEntityNode(const HtmlStr: TDomString; var Position: Integer): TNode;
    function GetTextNode(const HtmlStr: TDomString; var Position: Integer): TNode;
    function GetAttrTextNode(const HtmlStr: TDomString; var Position: Integer): TNode;
    function GetMainElement(const tagName: TDomString): THtmlElement;
    function FindThisElement(const tagName: TDomString): THtmlElement;
    function FindParent(Element: THtmlElement): THtmlElement;
    function FindDefParent(Element: THtmlElement): THtmlElement;
    function FindTableParent: THtmlElement;
    function FindParentElement(tagList: THtmlTagSet): THtmlElement;
    function IsBlockTag(Element: THtmlElement): Boolean;
    function IsHeadTag(Element: THtmlElement): Boolean;
    function IsEmptyTag(Element: THtmlElement): Boolean;
    function IsPreserveWhiteSpacesTag(Element: THtmlElement): Boolean;
    function NeedFindParentTag(Element: THtmlElement): Boolean;
    procedure ProcessEndTag(EndTag: THtmlElement);
    procedure ProcessElement(Element: THtmlElement);
    procedure ProcessTextNode(TextNode: TTextNode);
    procedure ProcessDocumentType(DocumentType: TDocumentType);
    procedure GetAttrValue(Attr: TAttr; const AttrValueStr: TDomString);
    procedure PrintNode(var F: TextFile; Node: TNode);
  public
    function loadHTML(const HtmlStr: TDomString): Boolean; override;
  end;

  TURLSchemes = class(TStringList)
  private
    FMaxLen: Integer;
  public
    function Add(const S: String): Integer; override;
    function IsURL(const S: String): Boolean;
    function GetScheme(const S: String): String;
    property MaxLen: Integer read FMaxLen;
  end;

var
  URLSchemes: TURLSchemes;

implementation

uses
  SysUtils, Entities;

const
{  BlockTagsCount = 19;
  BlockTags: array[0..BlockTagsCount - 1] of TDomString = (
    'address', 'blockquote', 'center', 'div', 'dl', 'fieldset', 'form', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'hr', 'noscript', 'ol', 'pre', 'table', 'ul'
  );

  BlockParentTagsCount = 19;
  BlockParentTags: array[0..BlockParentTagsCount - 1] of TDomString = (
    'address', 'blockquote', 'center', 'div', 'dl', 'fieldset', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'hr', 'noscript', 'ol', 'pre', 'td', 'th', 'ul'
  );

  HeadTagsCount = 6;
  HeadTags: array[0..HeadTagsCount - 1] of TDomString = (
    'base', 'link', 'meta', 'script', 'style', 'title'
  );

  EmptyTagsCount = 13;
  EmptyTags: array[0..EmptyTagsCount - 1] of TDomString = (
    'area', 'base', 'basefont', 'br', 'col', 'frame', 'hr', 'img', 'input', 'isindex', 'link', 'meta', 'param'
  );

  PreserveWhiteSpacesTagsCount = 1;
  PreserveWhiteSpacesTags: array[0..PreserveWhiteSpacesTagsCount - 1] of TDomString = (
    'pre'
  );
  
  NeedFindParentTagsCount = 14;
  NeedFindParentTags: array[0..NeedFindParentTagsCount - 1] of TDomString = (
    'col', 'colgroup', 'dd', 'dt', 'li', 'option', 'p', 'table', 'tbody', 'td', 'tfoot', 'th', 'thead', 'tr'
  );
  
  ListItemParentTagsCount = 4;
  ListItemParentTags: array[0..ListItemParentTagsCount - 1] of TDomString = (
    'dir', 'menu', 'ol', 'ul'
  );
  
  DefItemParentTagsCount = 1;
  DefItemParentTags: array[0..DefItemParentTagsCount - 1] of TDomString = (
    'dl'
  );
  
  TableSectionParentTagsCount = 1;
  TableSectionParentTags: array[0..TableSectionParentTagsCount - 1] of TDomString = (
    'table'
  );

  ColParentTagsCount = 1;
  ColParentTags: array[0..ColParentTagsCount - 1] of TDomString = (
    'colgroup'
  );

  RowParentTagsCount = 4;
  RowParentTags: array[0..RowParentTagsCount - 1] of TDomString = (
    'table', 'tbody', 'tfoot', 'thead'
  );
  
  CellParentTagsCount = 1;
  CellParentTags: array[0..CellParentTagsCount - 1] of TDomString = (
    'tr'
  );
  
  OptionParentTagsCount = 2;
  OptionParentTags: array[0..OptionParentTagsCount - 1] of TDomString = (
    'optgroup', 'select'
  );
}
  BlockTags: THtmlTagSet               = [ADDRESS_TAG, BLOCKQUOTE_TAG, CENTER_TAG, DIV_TAG, DL_TAG, FIELDSET_TAG, {FORM_TAG,} H1_TAG, H2_TAG, H3_TAG, H4_TAG, H5_TAG, H6_TAG, HR_TAG, NOSCRIPT_TAG, OL_TAG, PRE_TAG, TABLE_TAG, UL_TAG];
  BlockParentTags: THtmlTagSet         = [ADDRESS_TAG, BLOCKQUOTE_TAG, CENTER_TAG, DIV_TAG, DL_TAG, FIELDSET_TAG, H1_TAG, H2_TAG, H3_TAG, H4_TAG, H5_TAG, H6_TAG, HR_TAG, LI_TAG, NOSCRIPT_TAG, OL_TAG, PRE_TAG, TD_TAG, TH_TAG, UL_TAG];
  HeadTags: THtmlTagSet                = [BASE_TAG, LINK_TAG, META_TAG, SCRIPT_TAG, STYLE_TAG, TITLE_TAG];
  {Elements forbidden from having an end tag, and therefore are empty; from HTML 4.01 spec}
  EmptyTags: THtmlTagSet               = [AREA_TAG, BASE_TAG, BASEFONT_TAG, BR_TAG, COL_TAG, FRAME_TAG, HR_TAG, IMG_TAG, INPUT_TAG, ISINDEX_TAG, LINK_TAG, META_TAG, PARAM_TAG];
  PreserveWhiteSpacesTags: THtmlTagSet = [PRE_TAG];
  NeedFindParentTags: THtmlTagSet      = [COL_TAG, COLGROUP_TAG, DD_TAG, DT_TAG, LI_TAG, OPTION_TAG, P_TAG, TABLE_TAG, TBODY_TAG, TD_TAG, TFOOT_TAG, TH_TAG, THEAD_TAG, TR_TAG];
  ListItemParentTags: THtmlTagSet      = [DIR_TAG, MENU_TAG, OL_TAG, UL_TAG];
  DefItemParentTags: THtmlTagSet       = [DL_TAG];
  TableSectionParentTags: THtmlTagSet  = [TABLE_TAG];
  ColParentTags: THtmlTagSet           = [COLGROUP_TAG];
  RowParentTags: THtmlTagSet           = [TABLE_TAG, TBODY_TAG, TFOOT_TAG, THEAD_TAG];
  CellParentTags: THtmlTagSet          = [TR_TAG];
  OptionParentTags: THtmlTagSet        = [OPTGROUP_TAG, SELECT_TAG];

  startTag = Ord('<');
  endTag = Ord('>');
  specialTag = Ord('!');
  slashChar = Ord('/');
  equalChar = Ord('=');
  quotationChar = [Ord(''''), Ord('"')];
  tagDelimiter = [slashChar, endTag];
  tagNameDelimiter = WhiteSpace + tagDelimiter;
  attrNameDelimiter = tagNameDelimiter + [equalChar];
  attrValueDelimiter = WhiteSpace + [endTag];
  startEntity = Ord('&');
  startMarkup = [startTag, startEntity];
  endEntity = Ord(';');
  notEntity = [endEntity] + startMarkup + WhiteSpace;
  numericEntity = Ord('#');
  hexEntity = [Ord('x'), Ord('X')];
  decDigit = [Ord('0')..Ord('9')];
  hexDigit = decDigit + [Ord('a')..Ord('f'), Ord('A')..Ord('F')];

  htmlTagName = 'html';
  headTagName = 'head';
  bodyTagName = 'body';
  
  CRLF: TDomString = #13#10#13#10;
  DocTypeStartStr = 'DOCTYPE';
  DocTypeEndStr = '>';
  CDataStartStr = '[CDATA[';
  CDataEndStr = ']]>';
  CommentStartStr = '--';
  CommentEndStr = '-->';

type
  TDelimiters = set of Byte;

function Search(const tagName: TDomString; tagList: array of TDomString): Boolean;
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

function GetToken(const HtmlStr: TDomString; var Position: Integer; Delimiters: TDelimiters): TDomString;
var
  Start: Integer;
begin
  Start := Position;
  while (Position <= Length(HtmlStr)) and not (Ord(HtmlStr[Position]) in Delimiters) do
    Inc(Position);
  Result := Copy(HtmlStr, Start, Position - Start)
end;

procedure SkipWhiteSpaces(const HtmlStr: TDomString; var Position: Integer);
begin
  while (Position <= Length(HtmlStr)) and (Ord(HtmlStr[Position]) in WhiteSpace) do
    Inc(Position)
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

procedure SkipTo(const Signature, HtmlStr: TDomString; var Position: Integer);
begin
  while Position <= Length(HtmlStr) do
  begin
    if MatchAt(Signature, HtmlStr, Position, false) then
    begin
      Inc(Position, Length(Signature));
      Exit
    end;
    Inc(Position)
  end
end;

function GetQuotedValue(const HtmlStr: TDomString; var Position: Integer): TDomString;
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

function GetValue(const HtmlStr: TDomString; var Position: Integer): TDomString;
begin
  SkipWhiteSpaces(HtmlStr, Position);
  if Position <= Length(HtmlStr) then
  begin
    if IsQuotation(HtmlStr[Position]) then
      Result := GetQuotedValue(HtmlStr, Position)
    else
      Result := GetToken(HtmlStr, Position, attrValueDelimiter)
  end
end;

function THtmlParser.GetNode(const HtmlStr: TDomString; var Position: Integer): TNode;
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

function THtmlParser.GetTagNode(const HtmlStr: TDomString; var Position: Integer): TNode;
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

function THtmlParser.GetEndTagNode(const HtmlStr: TDomString; var Position: Integer): TNode;
begin
  Inc(Position);
  if Position < Length(HtmlStr) then
  begin
    Result := htmlDocument.createHtmlEndTag(LowerCase(GetToken(HtmlStr, Position, tagNameDelimiter)));
    SkipTo('>', HtmlStr, Position)
  end
  else
    Result := nil
end;

function THtmlParser.GetElementNode(const HtmlStr: TDomString; var Position: Integer): TNode;
var
  Attr: TAttr;
begin
  if Position < Length(HtmlStr) then
  begin
    Result := htmlDocument.createHtmlElement(LowerCase(GetToken(HtmlStr, Position, tagNameDelimiter)));
    with Result as THtmlElement do
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

function THtmlParser.GetAttrNode(const HtmlStr: TDomString; var Position: Integer): TAttr;
var
  name: TDomString;
begin
  SkipWhiteSpaces(HtmlStr, Position);
  name := GetToken(HtmlStr, Position, attrNameDelimiter);
  if name <> '' then
  begin
    Result := htmlDocument.createAttribute(LowerCase(name));
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

procedure THtmlParser.GetAttrValue(Attr: TAttr; const AttrValueStr: TDomString);
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

function THtmlParser.GetSpecialNode(const HtmlStr: TDomString; var Position: Integer): TNode;
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

function THtmlParser.IsStartDocumentType(const HtmlStr: TDomString; var Position: Integer): Boolean;
begin
  Result := MatchAt(DocTypeStartStr, HtmlStr, Position, true) 
end;

function THtmlParser.IsStartCharacterData(const HtmlStr: TDomString; var Position: Integer): Boolean;
begin
  Result := MatchAt(CDataStartStr, HtmlStr, Position, false)
end;

function THtmlParser.IsStartComment(const HtmlStr: TDomString; var Position: Integer): Boolean;
begin
  Result := MatchAt(CommentStartStr, HtmlStr, Position, false)
end;

function THtmlParser.GetDocumentType(const HtmlStr: TDomString; var Position: Integer): TNode;
var
  name, publicID, systemID: TDomString;
begin
  Inc(Position, Length(DocTypeStartStr));
  SkipWhiteSpaces(HtmlStr, Position);
  name := GetToken(HtmlStr, Position, tagNameDelimiter);
  SkipWhiteSpaces(HtmlStr, Position);
  GetToken(HtmlStr, Position, tagNameDelimiter);
  SkipWhiteSpaces(HtmlStr, Position);
  publicID := GetQuotedValue(HtmlStr, Position);
  SkipWhiteSpaces(HtmlStr, Position);
  if HtmlStr[Position] = '"' then
    systemID := GetQuotedValue(HtmlStr, Position)
  else
    systemID := '';
  Result := HtmlDomImplementation.createDocumentType(name, publicID, systemID);
  SkipTo(DocTypeEndStr, HtmlStr, Position)
end;

function THtmlParser.GetCharacterData(const HtmlStr: TDomString; var Position: Integer): TNode;
var
  StartPos: Integer;
begin
  Inc(Position, Length(CDataStartStr));
  StartPos := Position;
  SkipTo(CDataEndStr, HtmlStr, Position);
  Result := htmlDocument.createCDATASection(Copy(HtmlStr, StartPos, Position - StartPos - Length(CDataEndStr) + 1))
end;

function THtmlParser.GetComment(const HtmlStr: TDomString; var Position: Integer): TNode;
var
  StartPos: Integer;
begin
  Inc(Position, Length(CommentStartStr));
  StartPos := Position;
  SkipTo(CommentEndStr, HtmlStr, Position);
  Result := htmlDocument.createComment(Copy(HtmlStr, StartPos, Position - StartPos - Length(CommentEndStr)))
end;

function THtmlParser.GetEntityNode(const HtmlStr: TDomString; var Position: Integer): TNode;
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
    Result := htmlDocument.createTextNode(HtmlStr[Position])
end;

function THtmlParser.GetTextNode(const HtmlStr: TDomString; var Position: Integer): TNode;
var
  Start: Integer;
begin
  Start := Position;
  repeat
    Inc(Position)
  until (Position > Length(HtmlStr)) or IsStartMarkupChar(HtmlStr[Position]);
  Result := htmlDocument.createTextNode(Copy(HtmlStr, Start, Position - Start))
end;

function THtmlParser.GetAttrTextNode(const HtmlStr: TDomString; var Position: Integer): TNode;
var
  Start: Integer;
begin
  Start := Position;
  repeat
    Inc(Position)
  until (Position > Length(HtmlStr)) or IsStartEntityChar(HtmlStr[Position]);
  Result := htmlDocument.createTextNode(Copy(HtmlStr, Start, Position - Start))
end;

function THtmlParser.GetHexEntityNode(const HtmlStr: TDomString; var Position: Integer): TNode;
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
    Result := htmlDocument.createTextNode(WideChar(Value));
    Inc(Position)
  end
  else
    Result := htmlDocument.createTextNode(Copy(HtmlStr, Start, Position - Start))
end;

function THtmlParser.GetDecEntityNode(const HtmlStr: TDomString; var Position: Integer): TNode;
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
    Result := htmlDocument.createTextNode(WideChar(Value));
    Inc(Position)
  end
  else
    Result := htmlDocument.createTextNode(Copy(HtmlStr, Start, Position - Start))
end;

function THtmlParser.GetNumericEntityNode(const HtmlStr: TDomString; var Position: Integer): TNode;
begin
  if IsHexEntity(HtmlStr[Position]) then
  begin
    Inc(Position);
    Result := GetHexEntityNode(HtmlStr, Position)
  end
  else
    Result := GetDecEntityNode(HtmlStr, Position)
end;

function THtmlParser.GetNamedEntityNode(const HtmlStr: TDomString; var Position: Integer): TNode;
var
  Start: Integer;
begin
  Start := Position;
  while (Position <= Length(HtmlStr)) and IsEntityChar((HtmlStr[Position])) do
    Inc(Position);
  if (Position <= Length(HtmlStr)) and IsEndEntityChar((HtmlStr[Position])) then
  begin
    Result := htmlDocument.createEntityReference(Copy(HtmlStr, Start, Position - Start));
    Inc(Position)
  end
  else
    Result := htmlDocument.createTextNode(Copy(HtmlStr, Start, Position - Start))
end;
                                      
function THtmlParser.GetMainElement(const tagName: TDomString): THtmlElement;
var
  child: TNode;
  I: Integer;
begin
  if htmlDocument.documentElement = nil then
    htmlDocument.appendChild(htmlDocument.createHtmlElement(htmlTagName));
  for I := 0 to htmlDocument.documentElement.childNodes.length - 1 do
  begin
    child := htmlDocument.documentElement.childNodes.item(I);
    if (child.nodeType = ELEMENT_NODE) and (child.nodeName = tagName) then
    begin
      Result := child as THtmlElement;
      Exit
    end
  end;
  Result := htmlDocument.createHtmlElement(tagName);
  htmlDocument.documentElement.appendChild(Result)
end;

function THtmlParser.FindThisElement(const tagName: TDomString): THtmlElement;
var
  Node: TNode;
begin
  Node := FCurrentNode;
  while Node.nodeType = ELEMENT_NODE do
  begin
    Result := Node as THtmlElement;
    if Result.tagName = tagName then
      Exit;
    Node := Node.parentNode
  end;
  Result := nil
end;

function THtmlParser.FindParentElement(tagList: THtmlTagSet): THtmlElement;
var
  Node: TNode;
begin
  Node := FCurrentNode;
  while Node.nodeType = ELEMENT_NODE do
  begin
    Result := Node as THtmlElement;
    if Result.HtmlTag.Number in tagList then
    //if Search(Result.tagName, tagList) then
      Exit;
    Node := Node.parentNode
  end;
  Result := nil
end;

function THtmlParser.FindDefParent(Element: THtmlElement): THtmlElement;
begin
  if (Element.tagName = headTagName) or (Element.tagName = bodyTagName) then
    Result := htmlDocument.appendChild(htmlDocument.createHtmlElement(htmlTagName)) as THtmlElement
  else
  if IsHeadTag(Element) then
    Result := GetMainElement(headTagName)
  else
    Result := GetMainElement(bodyTagName)
end;

function THtmlParser.FindTableParent: THtmlElement;
var
  Node: TNode;
begin
  Node := FCurrentNode;
  while Node.nodeType = ELEMENT_NODE do
  begin
    Result := Node as THtmlElement;
    if (Result.tagName = 'td') or IsBlockTag(Result) then
      Exit;
    Node := Node.parentNode
  end;
  Result := GetMainElement(bodyTagName)
end;

function THtmlParser.FindParent(Element: THtmlElement): THtmlElement;
begin
  if (Element.tagName = 'p') or IsBlockTag(Element) then
    Result := FindParentElement(BlockParentTags)
  else
  if Element.tagName = 'li' then
    Result := FindParentElement(ListItemParentTags)
  else
  if (Element.tagName = 'dd') or (Element.tagName = 'dt') then
    Result := FindParentElement(DefItemParentTags)
  else
  if (Element.tagName = 'td') or (Element.tagName = 'th') then
    Result := FindParentElement(CellParentTags)
  else
  if Element.tagName = 'tr' then
    Result := FindParentElement(RowParentTags)
  else
  if Element.tagName = 'col' then
    Result := FindParentElement(ColParentTags)
  else
  if (Element.tagName = 'colgroup') or (Element.tagName = 'thead') or (Element.tagName = 'tfoot') or (Element.tagName = 'tbody') then
    Result := FindParentElement(TableSectionParentTags)
  else
  if Element.tagName = 'table' then
    Result := FindTableParent
  else
  if Element.tagName = 'option' then
    Result := FindParentElement(OptionParentTags)
  else
  if (Element.tagName = headTagName) or (Element.tagName = bodyTagName) then
    Result := htmlDocument.documentElement as THtmlElement
  else
    Result := nil;
  if Result = nil then
    Result := FindDefParent(Element)
end;

function THtmlParser.IsBlockTag(Element: THtmlElement): Boolean;
begin
  if (Element = nil) or (Element.HtmlTag = nil) then
    raise Exception.Create(Element.tagName);
  Result := Element.HtmlTag.Number in BlockTags //Search(tagName, BlockTags)
end;

function THtmlParser.IsHeadTag(Element: THtmlElement): Boolean;
begin
  Result := Element.HtmlTag.Number in HeadTags //Search(tagName, HeadTags)
end;

function THtmlParser.IsEmptyTag(Element: THtmlElement): Boolean;
begin
  Result := Element.HtmlTag.Number in EmptyTags //Search(tagName, EmptyTags)
end;

function THtmlParser.IsPreserveWhiteSpacesTag(Element: THtmlElement): Boolean;
begin
  Result := Element.HtmlTag.Number in PreserveWhiteSpacesTags //Search(tagName, PreserveWhiteSpacesTags)
end;

function THtmlParser.NeedFindParentTag(Element: THtmlElement): Boolean;
begin
  Result := IsBlockTag(Element) or (Element.HtmlTag.Number in NeedFindParentTags) //Search(Element.tagName, NeedFindParentTags)
end;

procedure THtmlParser.ProcessEndTag(EndTag: THtmlElement);
var
  Node: THtmlElement;
begin
  try
    if IsPreserveWhiteSpacesTag(EndTag) then
      FPreserveWhiteSpace := false;
{
  if EndTag.tagName = 'center' then
  begin
    FPreserveWhiteSpace := false;
  end;
}
    Node := FindThisElement(EndTag.tagName);
    if Node <> nil then
      FCurrentNode := Node.parentNode
    else
    if IsBlockTag(EndTag) then
      raise DomException.Create(HIERARCHY_REQUEST_ERR)
  finally
    EndTag.Free
  end
end;

procedure THtmlParser.ProcessElement(Element: THtmlElement);
var
  Node: THtmlElement;
begin
  Element.IsEmpty := IsEmptyTag(Element);
  if IsPreserveWhiteSpacesTag(Element) then
    FPreserveWhiteSpace := true;
  if NeedFindParentTag(Element) then
  begin
    Node := FindParent(Element);
    if Node = nil then
      raise DomException.Create(HIERARCHY_REQUEST_ERR);
    FCurrentNode := Node
  end;
  FCurrentNode.appendChild(Element);
  if not Element.IsEmpty then
    FCurrentNode := Element
end;

procedure THtmlParser.ProcessTextNode(TextNode: TTextNode);
begin
  if FCurrentNode.nodeType = ELEMENT_NODE then
  begin
    if not FPreserveWhiteSpace then
      TextNode.normalizeWhiteSpace;
    if TextNode.length <> 0 then
    begin
      if (FCurrentNode.lastChild <> nil) and (FCurrentNode.lastChild.nodeType = TEXT_NODE) then
      begin
        (FCurrentNode.lastChild as TTextNode).appendData(TextNode.data);
        TextNode.Free
      end
      else
        FCurrentNode.appendChild(TextNode)
    end
  end
end;

procedure THtmlParser.ProcessDocumentType(DocumentType: TDocumentType);
begin
  //TODO doctype := DocumentType
end;

function THtmlParser.loadHTML(const HtmlStr: TDomString): Boolean;
var
  Node: TNode;
  Position: Integer;
//  F: TextFile;
begin
  Position := 1;
  try
    htmlDocument.Clear;
    FCurrentNode := htmlDocument;
    Node := GetNode(HtmlStr, Position);
    while Node <> nil do
    begin
      if Node.nodeType = END_TAG_NODE then
        ProcessEndTag(Node as THtmlEndTag)
      else
      if Node.nodeType = ELEMENT_NODE then
        ProcessElement(Node as THtmlElement)
      else
      if Node.nodeType = TEXT_NODE then
        ProcessTextNode(Node as TTextNode)
      else
{      if Node is TEntityReference then
        ProcessEntity(Node as TEntityReference)
      else}
      if Node.nodeType = DOCUMENT_TYPE_NODE then
        ProcessDocumentType(Node as TDocumentType)
      else
        //Node.Free;
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

procedure THtmlParser.PrintNode(var F: TextFile; Node: TNode);
var
  S: String;
  I: Integer;
begin
  if Node.nodeType = ELEMENT_NODE then
  begin
    S := '<' + (Node as THtmlElement).tagName;
    if (Node as THtmlElement).IsEmpty then
      S := S + '/';
    S := S + '>';
    Write(F, S)
  end;
  for I := 0 to Node.childNodes.length - 1 do
    PrintNode(F, Node.childNodes.item(I));
  if Node.nodeType = ELEMENT_NODE then
  begin
    S := '</' + (Node as THtmlElement).tagName;
    S := S + '>';
    Write(F, S)
  end;
end;

function AppendNewLine(const S: TDomString): TDomString;
begin
  Result := S;
  if (S <> '') and not RightMatch(CRLF, S) then
    Result := Result + CRLF
end;

function TURLSchemes.Add(const S: String): Integer;
begin
  if Length(S) > FMaxLen then
    FMaxLen := Length(S);
  Result := inherited Add(S)
end;

function TURLSchemes.IsURL(const S: String): Boolean;
begin
  Result := IndexOf(LowerCase(S)) >= 0
end;

function TURLSchemes.GetScheme(const S: String): String;
const
  SchemeChars = [Ord('A')..Ord('Z'), Ord('a')..Ord('z')];
var
  I: Integer;
begin
  Result := '';
  for I := 1 to MaxLen + 1 do
  begin
    if I > Length(S) then
      Exit;
    if S[I] = ':' then
    begin
      if IsURL(Copy(S, 1, I - 1)) then
        Result := Copy(S, 1, I - 1);
      Exit
    end
  end
end;

initialization

  URLSchemes := TURLSchemes.Create;
  URLSchemes.Add('http');
  URLSchemes.Add('https');
  URLSchemes.Add('ftp');
  URLSchemes.Add('mailto');
  URLSchemes.Add('news');
  URLSchemes.Add('nntp');
  URLSchemes.Add('gopher');

finalization

  URLSchemes.Free

end.
