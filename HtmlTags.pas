unit HtmlTags;

interface

uses
  Classes, DomCore;

const
  MAX_TAGS_COUNT  = 128;
  MAX_FLAGS_COUNT = 32;

type
  THtmlTagSet = set of 0..MAX_TAGS_COUNT - 1;

  THtmlTagFlags = set of 0..MAX_FLAGS_COUNT - 1;

  THtmlTag = class
  private
    FName: TDomString;
    FNumber: Integer;
    FParserFlags: THtmlTagFlags;
    FFormatterFlags: THtmlTagFlags;
  public
    constructor Create(const AName: TDomString; ANumber: Integer; AParserFlags, AFormatterFlags: THtmlTagFlags);
    property Name: TDomString read FName;
    property Number: Integer read FNumber;
    property ParserFlags: THtmlTagFlags read FParserFlags;
    property FormatterFlags: THtmlTagFlags read FFormatterFlags;
  end;

  TCompareTag = function(Tag: THtmlTag): Integer of object;

  THtmlTagList = class
  private
    FList: TList;
    FUnknownTag: THtmlTag;
    FSearchName: WideString;
    FSearchNumber: Integer;
    function CompareName(Tag: THtmlTag): Integer;
    function CompareNumber(Tag: THtmlTag): Integer;
    function GetTag(Compare: TCompareTag): THtmlTag;
  public
    constructor Create;
    destructor Destroy; override;
    function GetTagByName(const Name: TDomString): THtmlTag;
    function GetTagByNumber(Number: Integer): THtmlTag;
  end;

var
  HtmlTagList: THtmlTagList;

const
  UNKNOWN_TAG    = 0;
  A_TAG          = 1;
  ABBR_TAG       = 2;
  ACRONYM_TAG    = 3;
  ADDRESS_TAG    = 4;
  APPLET_TAG     = 5;
  AREA_TAG       = 6;
  B_TAG          = 7;
  BASE_TAG       = 8;
  BASEFONT_TAG   = 9;
  BDO_TAG        = 10;
  BIG_TAG        = 11;
  BLOCKQUOTE_TAG = 12;
  BODY_TAG       = 13;
  BR_TAG         = 14;
  BUTTON_TAG     = 15;
  CAPTION_TAG    = 16;
  CENTER_TAG     = 17;
  CITE_TAG       = 18;
  CODE_TAG       = 19;
  COL_TAG        = 20;
  COLGROUP_TAG   = 21;
  DD_TAG         = 22;
  DEL_TAG        = 23;
  DFN_TAG        = 24;
  DIR_TAG        = 25;
  DIV_TAG        = 26;
  DL_TAG         = 27;
  DT_TAG         = 28;
  EM_TAG         = 29;
  FIELDSET_TAG   = 30;
  FONT_TAG       = 31;
  FORM_TAG       = 32;
  FRAME_TAG      = 33;
  FRAMESET_TAG   = 34;
  H1_TAG         = 35;
  H2_TAG         = 36;
  H3_TAG         = 37;
  H4_TAG         = 38;
  H5_TAG         = 39;
  H6_TAG         = 40;
  HEAD_TAG       = 41;
  HR_TAG         = 42;
  HTML_TAG       = 43;
  I_TAG          = 44;
  IFRAME_TAG     = 45;
  IMG_TAG        = 46;
  INPUT_TAG      = 47;
  INS_TAG        = 48;
  ISINDEX_TAG    = 49;
  KBD_TAG        = 50;
  LABEL_TAG      = 51;
  LEGEND_TAG     = 52;
  LI_TAG         = 53;
  LINK_TAG       = 54;
  MAP_TAG        = 55;
  MENU_TAG       = 56;
  META_TAG       = 57;
  NOFRAMES_TAG   = 58;
  NOSCRIPT_TAG   = 59;
  OBJECT_TAG     = 60;
  OL_TAG         = 61;
  OPTGROUP_TAG   = 62;
  OPTION_TAG     = 63;
  P_TAG          = 64;
  PARAM_TAG      = 65;
  PRE_TAG        = 65;
  Q_TAG          = 66;
  S_TAG          = 67;
  SAMP_TAG       = 68;
  SCRIPT_TAG     = 69;
  SELECT_TAG     = 70;
  SMALL_TAG      = 71;
  SPAN_TAG       = 72;
  STRIKE_TAG     = 73;
  STRONG_TAG     = 74;
  STYLE_TAG      = 75;
  SUB_TAG        = 76;
  SUP_TAG        = 77;
  TABLE_TAG      = 78;
  TBODY_TAG      = 79;
  TD_TAG         = 80;
  TEXTAREA_TAG   = 81;
  TFOOT_TAG      = 82;
  TH_TAG         = 83;
  THEAD_TAG      = 84;
  TITLE_TAG      = 85;
  TR_TAG         = 86;
  TT_TAG         = 87;
  U_TAG          = 88;
  UL_TAG         = 89;
  VAR_TAG        = 90;

implementation

uses
  SysUtils;
  
constructor THtmlTag.Create(const AName: TDomString; ANumber: Integer; AParserFlags, AFormatterFlags: THtmlTagFlags);
begin
  inherited Create;
  FName := AName;
  FNumber := ANumber
end;

constructor THtmlTagList.Create;
begin
  inherited Create;
  FList := TList.Create;
  FList.Capacity := MAX_TAGS_COUNT;
  FList.Add(THtmlTag.Create('a',          A_TAG,          [], []));
  FList.Add(THtmlTag.Create('abbr',       ABBR_TAG,       [], []));
  FList.Add(THtmlTag.Create('acronym',    ACRONYM_TAG,    [], []));
  FList.Add(THtmlTag.Create('address',    ADDRESS_TAG,    [], []));
  FList.Add(THtmlTag.Create('applet',     APPLET_TAG,     [], []));
  FList.Add(THtmlTag.Create('area',       AREA_TAG,       [], []));
  FList.Add(THtmlTag.Create('b',          B_TAG,          [], []));
  FList.Add(THtmlTag.Create('base',       BASE_TAG,       [], []));
  FList.Add(THtmlTag.Create('basefont',   BASEFONT_TAG,   [], []));
  FList.Add(THtmlTag.Create('bdo',        BDO_TAG,        [], []));
  FList.Add(THtmlTag.Create('big',        BIG_TAG,        [], []));
  FList.Add(THtmlTag.Create('blockquote', BLOCKQUOTE_TAG, [], []));
  FList.Add(THtmlTag.Create('body',       BODY_TAG,       [], []));
  FList.Add(THtmlTag.Create('br',         BR_TAG,         [], []));
  FList.Add(THtmlTag.Create('button',     BUTTON_TAG,     [], []));
  FList.Add(THtmlTag.Create('caption',    CAPTION_TAG,    [], []));
  FList.Add(THtmlTag.Create('center',     CENTER_TAG,     [], []));
  FList.Add(THtmlTag.Create('cite',       CITE_TAG,       [], []));
  FList.Add(THtmlTag.Create('code',       CODE_TAG,       [], []));
  FList.Add(THtmlTag.Create('col',        COL_TAG,        [], []));
  FList.Add(THtmlTag.Create('colgroup',   COLGROUP_TAG,   [], []));
  FList.Add(THtmlTag.Create('dd',         DD_TAG,         [], []));
  FList.Add(THtmlTag.Create('del',        DEL_TAG,        [], []));
  FList.Add(THtmlTag.Create('dfn',        DFN_TAG,        [], []));
  FList.Add(THtmlTag.Create('dir',        DIR_TAG,        [], []));
  FList.Add(THtmlTag.Create('div',        DIV_TAG,        [], []));
  FList.Add(THtmlTag.Create('dl',         DL_TAG,         [], []));
  FList.Add(THtmlTag.Create('dt',         DT_TAG,         [], []));         
  FList.Add(THtmlTag.Create('em',         EM_TAG,         [], []));
  FList.Add(THtmlTag.Create('fieldset',   FIELDSET_TAG,   [], []));
  FList.Add(THtmlTag.Create('font',       FONT_TAG,       [], []));
  FList.Add(THtmlTag.Create('form',       FORM_TAG,       [], []));
  FList.Add(THtmlTag.Create('frame',      FRAME_TAG,      [], []));
  FList.Add(THtmlTag.Create('frameset',   FRAMESET_TAG,   [], []));
  FList.Add(THtmlTag.Create('h1',         H1_TAG,         [], []));
  FList.Add(THtmlTag.Create('h2',         H2_TAG,         [], []));
  FList.Add(THtmlTag.Create('h3',         H3_TAG,         [], []));
  FList.Add(THtmlTag.Create('h4',         H4_TAG,         [], []));
  FList.Add(THtmlTag.Create('h5',         H5_TAG,         [], []));
  FList.Add(THtmlTag.Create('h6',         H6_TAG,         [], []));
  FList.Add(THtmlTag.Create('head',       HEAD_TAG,       [], []));
  FList.Add(THtmlTag.Create('hr',         HR_TAG,         [], []));
  FList.Add(THtmlTag.Create('html',       HTML_TAG,       [], []));
  FList.Add(THtmlTag.Create('i',          I_TAG,          [], []));
  FList.Add(THtmlTag.Create('iframe',     IFRAME_TAG,     [], []));
  FList.Add(THtmlTag.Create('img',        IMG_TAG,        [], []));
  FList.Add(THtmlTag.Create('input',      INPUT_TAG,      [], []));
  FList.Add(THtmlTag.Create('ins',        INS_TAG,        [], []));
  FList.Add(THtmlTag.Create('isindex',    ISINDEX_TAG,    [], []));
  FList.Add(THtmlTag.Create('kbd',        KBD_TAG,        [], []));
  FList.Add(THtmlTag.Create('label',      LABEL_TAG,      [], []));
  FList.Add(THtmlTag.Create('legend',     LEGEND_TAG,     [], []));
  FList.Add(THtmlTag.Create('li',         LI_TAG,         [], []));
  FList.Add(THtmlTag.Create('link',       LINK_TAG,       [], []));
  FList.Add(THtmlTag.Create('map',        MAP_TAG,        [], []));
  FList.Add(THtmlTag.Create('menu',       MENU_TAG,       [], []));
  FList.Add(THtmlTag.Create('meta',       META_TAG,       [], []));
  FList.Add(THtmlTag.Create('noframes',   NOFRAMES_TAG,   [], []));
  FList.Add(THtmlTag.Create('noscript',   NOSCRIPT_TAG,   [], []));
  FList.Add(THtmlTag.Create('object',     OBJECT_TAG,     [], []));
  FList.Add(THtmlTag.Create('ol',         OL_TAG,         [], []));
  FList.Add(THtmlTag.Create('optgroup',   OPTGROUP_TAG,   [], []));
  FList.Add(THtmlTag.Create('option',     OPTION_TAG,     [], []));
  FList.Add(THtmlTag.Create('p',          P_TAG,          [], []));
  FList.Add(THtmlTag.Create('param',      PARAM_TAG,      [], []));
  FList.Add(THtmlTag.Create('pre',        PRE_TAG,        [], []));
  FList.Add(THtmlTag.Create('q',          Q_TAG,          [], []));          
  FList.Add(THtmlTag.Create('s',          S_TAG,          [], []));
  FList.Add(THtmlTag.Create('samp',       SAMP_TAG,       [], []));
  FList.Add(THtmlTag.Create('script',     SCRIPT_TAG,     [], []));
  FList.Add(THtmlTag.Create('select',     SELECT_TAG,     [], []));
  FList.Add(THtmlTag.Create('small',      SMALL_TAG,      [], []));
  FList.Add(THtmlTag.Create('span',       SPAN_TAG,       [], []));
  FList.Add(THtmlTag.Create('strike',     STRIKE_TAG,     [], []));
  FList.Add(THtmlTag.Create('strong',     STRONG_TAG,     [], []));
  FList.Add(THtmlTag.Create('style',      STYLE_TAG,      [], []));
  FList.Add(THtmlTag.Create('sub',        SUB_TAG,        [], []));
  FList.Add(THtmlTag.Create('sup',        SUP_TAG,        [], []));
  FList.Add(THtmlTag.Create('table',      TABLE_TAG,      [], []));
  FList.Add(THtmlTag.Create('tbody',      TBODY_TAG,      [], []));
  FList.Add(THtmlTag.Create('td',         TD_TAG,         [], []));
  FList.Add(THtmlTag.Create('textarea',   TEXTAREA_TAG,   [], []));
  FList.Add(THtmlTag.Create('tfoot',      TFOOT_TAG,      [], []));
  FList.Add(THtmlTag.Create('th',         TH_TAG,         [], []));
  FList.Add(THtmlTag.Create('thead',      THEAD_TAG,      [], []));
  FList.Add(THtmlTag.Create('title',      TITLE_TAG,      [], []));
  FList.Add(THtmlTag.Create('tr',         TR_TAG,         [], []));
  FList.Add(THtmlTag.Create('tt',         TT_TAG,         [], []));
  FList.Add(THtmlTag.Create('u',          U_TAG,          [], []));
  FList.Add(THtmlTag.Create('ul',         UL_TAG,         [], []));
  FList.Add(THtmlTag.Create('var',        VAR_TAG,        [], []));
  FUnknownTag := THtmlTag.Create('', UNKNOWN_TAG, [], [])
end;

destructor THtmlTagList.Destroy;
begin
  //TODO
  FUnknownTag.Free;
  inherited Destroy
end;

function THtmlTagList.GetTag(Compare: TCompareTag): THtmlTag;
var
  I, Low, High, Rel: Integer;
begin
  Low := -1;
  High := FList.Count - 1;
  while High - Low > 1 do
  begin
    I := (High + Low) div 2;
    Result := FList[I];
    Rel := Compare(Result);
    if Rel < 0 then
      High := I
    else
    if Rel > 0 then
      Low := I
    else
      Exit
  end;
  if High >= 0 then
  begin
    Result := FList[High];
    if Compare(Result) = 0 then
      Exit
  end;
  Result := nil
end;

function THtmlTagList.CompareName(Tag: THtmlTag): Integer;
begin
  Result := CompareStr(FSearchName, Tag.Name)
end;

function THtmlTagList.CompareNumber(Tag: THtmlTag): Integer;
begin
  Result := FSearchNumber - Tag.Number
end;

function THtmlTagList.GetTagByName(const Name: TDomString): THtmlTag;
begin
  FSearchName := Name;
  Result := GetTag(CompareName);
  if Result = nil then
    Result := FUnknownTag
end;

function THtmlTagList.GetTagByNumber(Number: Integer): THtmlTag;
begin
  FSearchNumber := Number;
  Result := GetTag(CompareNumber)
end;

initialization

  HtmlTagList := THtmlTagList.Create;

finalization

  HtmlTagList.Free

end.
