unit HtmlTags;

interface

uses
	Classes, DomCore;

{
	Provides a singleton database of known HTML tag, and information about them.
	
	The list of known HTML tags are provided through the global function:
	
		function HtmlTagList: THtmlTagList;

	And known list of URL schemes through:

		function URLSchemes: TURLSchemes;

	Version history
	---------------
	
	12/21/2021
		- Changed from global variables to singleton functions.
		- URLSchemes now, like HtmlTagList, populates itself during its constructor.
		- Searching for tag names in HtmlTagList is now case insensitive
}

type
	TTagID = type Integer;
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
	PRE_TAG        = 66;
	Q_TAG          = 67;
	S_TAG          = 68;
	SAMP_TAG       = 69;
	SCRIPT_TAG     = 70;
	SELECT_TAG     = 71;
	SMALL_TAG      = 72;
	SPAN_TAG       = 73;
	STRIKE_TAG     = 74;
	STRONG_TAG     = 75;
	STYLE_TAG      = 76;
	SUB_TAG        = 77;
	SUP_TAG        = 78;
	TABLE_TAG      = 79;
	TBODY_TAG      = 80;
	TD_TAG         = 81;
	TEXTAREA_TAG   = 82;
	TFOOT_TAG      = 83;
	TH_TAG         = 84;
	THEAD_TAG      = 85;
	TITLE_TAG      = 86;
	TR_TAG         = 87;
	TT_TAG         = 88;
	U_TAG          = 89;
	UL_TAG         = 90;
	VAR_TAG        = 91;
	TEMPLATE_TAG	= 92;

	BlockTags               = [ADDRESS_TAG, BLOCKQUOTE_TAG, CENTER_TAG, DIV_TAG, DL_TAG, FIELDSET_TAG, {FORM_TAG,} H1_TAG, H2_TAG, H3_TAG, H4_TAG, H5_TAG, H6_TAG, HR_TAG, NOSCRIPT_TAG, OL_TAG, PRE_TAG, TABLE_TAG, UL_TAG];
	BlockParentTags         = [ADDRESS_TAG, BLOCKQUOTE_TAG, CENTER_TAG, DIV_TAG, DL_TAG, FIELDSET_TAG, H1_TAG, H2_TAG, H3_TAG, H4_TAG, H5_TAG, H6_TAG, HR_TAG, LI_TAG, NOSCRIPT_TAG, OL_TAG, PRE_TAG, TD_TAG, TH_TAG, UL_TAG];
	HeadTags                = [BASE_TAG, LINK_TAG, META_TAG, SCRIPT_TAG, STYLE_TAG, TITLE_TAG];
	{Elements forbidden from having an end tag, and therefore are empty; from HTML 4.01 spec}
	EmptyTags               = [AREA_TAG, BASE_TAG, BASEFONT_TAG, BR_TAG, COL_TAG, FRAME_TAG, HR_TAG, IMG_TAG, INPUT_TAG, ISINDEX_TAG, LINK_TAG, META_TAG, PARAM_TAG];
	PreserveWhiteSpaceTags  = [PRE_TAG];
	NeedFindParentTags      = [COL_TAG, COLGROUP_TAG, DD_TAG, DT_TAG, LI_TAG, OPTION_TAG, P_TAG, TABLE_TAG, TBODY_TAG, TD_TAG, TFOOT_TAG, TH_TAG, THEAD_TAG, TR_TAG];
	ListItemParentTags      = [DIR_TAG, MENU_TAG, OL_TAG, UL_TAG];
	DefItemParentTags       = [DL_TAG]; //<dl name="Description list"><dt name="Description term">word</dt><dd name="Decription details">definition</dd></dl>
	TableSectionParentTags  = [TABLE_TAG];
	ColParentTags           = [COLGROUP_TAG];
	RowParentTags           = [TABLE_TAG, TBODY_TAG, TFOOT_TAG, THEAD_TAG];
	CellParentTags          = [TR_TAG];
	OptionParentTags        = [OPTGROUP_TAG, SELECT_TAG];

const
	MAX_TAGS_COUNT  = 128;
	MAX_FLAGS_COUNT = 32;

type
	THtmlTagSet = set of 0..MAX_TAGS_COUNT - 1;
	THtmlTagFlags = set of 0..MAX_FLAGS_COUNT - 1;

	THtmlTag = class
	private
		FName: TDomString;
		FNumber: TTagID;
		FParserFlags: THtmlTagFlags;
		FFormatterFlags: THtmlTagFlags;
	public
		constructor Create(const AName: TDomString; ANumber: Integer; AParserFlags, AFormatterFlags: THtmlTagFlags);
		property Name: TDomString read FName;
		property Number: TTagID read FNumber;
		property ParserFlags: THtmlTagFlags read FParserFlags;
		property FormatterFlags: THtmlTagFlags read FFormatterFlags;
	end;

	TCompareTag = function(Tag: THtmlTag): Integer of object;

	THtmlTagList = class
	private
		FList: TList;
		FUnknownTag: THtmlTag;
		FSearchName: TDomString;
		FSearchNumber: Integer;
		function CompareName(Tag: THtmlTag): Integer;
		function CompareNumber(Tag: THtmlTag): Integer;
		function GetTag(Compare: TCompareTag): THtmlTag;
		procedure InitializeTagList(AList: TList);
	public
		constructor Create;
		destructor Destroy; override;
		function GetTagByName(const Name: TDomString): THtmlTag;
		function GetTagID(const Name: UnicodeString): TTagID;
		function GetTagByNumber(Number: Integer): THtmlTag;
	end;

	TURLSchemes = class(TStringList)
	private
		FMaxLen: Integer;
	public
		constructor Create;
		function Add(const S: String): Integer; override;
		function IsURL(const S: String): Boolean;
		function GetScheme(const S: String): String;
		property MaxLen: Integer read FMaxLen;
	end;

	//Global singleton lists of HTML tags and URL schemes
	function HtmlTagList: THtmlTagList;
	function URLSchemes: TURLSchemes;


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

{
	HTML tag names in HTML are returned as canonical UPPERCASE.

	https://www.w3.org/TR/DOM-Level-3-Core/core.html#ID-104682815

	> The HTML DOM returns the tagName of an HTML element in the canonical uppercase form,
	> regardless of the case in the source HTML document.
}
	FList := TList.Create;
	InitializeTagList(FList);
	FUnknownTag := THtmlTag.Create('', UNKNOWN_TAG, [], [])
end;

procedure THtmlTagList.InitializeTagList(AList: TList);
begin
	AList.Capacity := MAX_TAGS_COUNT;
	AList.Add(THtmlTag.Create('a',          A_TAG,          [], []));
	AList.Add(THtmlTag.Create('abbr',       ABBR_TAG,       [], []));
	AList.Add(THtmlTag.Create('acronym',    ACRONYM_TAG,    [], [])); //16.2. Non-conforming. Use ABBR instead.
	AList.Add(THtmlTag.Create('address',    ADDRESS_TAG,    [], []));
	AList.Add(THtmlTag.Create('applet',     APPLET_TAG,     [], [])); //16.2. Non-confirming. Use EMBED or OBJECT instead. HTMLUnknownElement
	AList.Add(THtmlTag.Create('area',       AREA_TAG,       [], []));
	AList.Add(THtmlTag.Create('b',          B_TAG,          [], []));
	AList.Add(THtmlTag.Create('base',       BASE_TAG,       [], []));
	AList.Add(THtmlTag.Create('basefont',   BASEFONT_TAG,   [], []));
	AList.Add(THtmlTag.Create('bdo',        BDO_TAG,        [], []));
	AList.Add(THtmlTag.Create('big',        BIG_TAG,        [], []));
	AList.Add(THtmlTag.Create('blockquote', BLOCKQUOTE_TAG, [], []));
	AList.Add(THtmlTag.Create('body',       BODY_TAG,       [], []));
	AList.Add(THtmlTag.Create('br',         BR_TAG,         [], []));
	AList.Add(THtmlTag.Create('button',     BUTTON_TAG,     [], []));
	AList.Add(THtmlTag.Create('caption',    CAPTION_TAG,    [], []));
	AList.Add(THtmlTag.Create('center',     CENTER_TAG,     [], []));
	AList.Add(THtmlTag.Create('cite',       CITE_TAG,       [], []));
	AList.Add(THtmlTag.Create('code',       CODE_TAG,       [], []));
	AList.Add(THtmlTag.Create('col',        COL_TAG,        [], []));
	AList.Add(THtmlTag.Create('colgroup',   COLGROUP_TAG,   [], []));
	AList.Add(THtmlTag.Create('dd',         DD_TAG,         [], []));
	AList.Add(THtmlTag.Create('del',        DEL_TAG,        [], []));
	AList.Add(THtmlTag.Create('dfn',        DFN_TAG,        [], []));
	AList.Add(THtmlTag.Create('dir',        DIR_TAG,        [], [])); //16.2. Non-conforming. Use UL instead.
	AList.Add(THtmlTag.Create('div',        DIV_TAG,        [], []));
	AList.Add(THtmlTag.Create('dl',         DL_TAG,         [], []));
	AList.Add(THtmlTag.Create('dt',         DT_TAG,         [], []));
	AList.Add(THtmlTag.Create('em',         EM_TAG,         [], []));
	AList.Add(THtmlTag.Create('fieldset',   FIELDSET_TAG,   [], []));
	AList.Add(THtmlTag.Create('font',       FONT_TAG,       [], []));
	AList.Add(THtmlTag.Create('form',       FORM_TAG,       [], []));
	AList.Add(THtmlTag.Create('frame',      FRAME_TAG,      [], [])); //16.3. Non-conforming. Either use IFRAME and CSS instead, or use server-side includes
	AList.Add(THtmlTag.Create('frameset',   FRAMESET_TAG,   [], [])); //16.3. Non-conforming. Either use IFRAME and CSS instead, or use server-side includes
	AList.Add(THtmlTag.Create('h1',         H1_TAG,         [], []));
	AList.Add(THtmlTag.Create('h2',         H2_TAG,         [], []));
	AList.Add(THtmlTag.Create('h3',         H3_TAG,         [], []));
	AList.Add(THtmlTag.Create('h4',         H4_TAG,         [], []));
	AList.Add(THtmlTag.Create('h5',         H5_TAG,         [], []));
	AList.Add(THtmlTag.Create('h6',         H6_TAG,         [], []));
	AList.Add(THtmlTag.Create('head',       HEAD_TAG,       [], []));
	AList.Add(THtmlTag.Create('hr',         HR_TAG,         [], []));
	AList.Add(THtmlTag.Create('html',       HTML_TAG,       [], []));
	AList.Add(THtmlTag.Create('i',          I_TAG,          [], []));
	AList.Add(THtmlTag.Create('iframe',     IFRAME_TAG,     [], []));
	AList.Add(THtmlTag.Create('img',        IMG_TAG,        [], []));
	AList.Add(THtmlTag.Create('input',      INPUT_TAG,      [], []));
	AList.Add(THtmlTag.Create('ins',        INS_TAG,        [], []));
	AList.Add(THtmlTag.Create('isindex',    ISINDEX_TAG,    [], [])); //16.3. Non-conforming. Use an explicit form and text control combination instead.
	AList.Add(THtmlTag.Create('kbd',        KBD_TAG,        [], []));
	AList.Add(THtmlTag.Create('label',      LABEL_TAG,      [], []));
	AList.Add(THtmlTag.Create('legend',     LEGEND_TAG,     [], []));
	AList.Add(THtmlTag.Create('li',         LI_TAG,         [], []));
	AList.Add(THtmlTag.Create('link',       LINK_TAG,       [], []));
	AList.Add(THtmlTag.Create('map',        MAP_TAG,        [], []));
	AList.Add(THtmlTag.Create('menu',       MENU_TAG,       [], []));
	AList.Add(THtmlTag.Create('meta',       META_TAG,       [], []));
	AList.Add(THtmlTag.Create('noframes',   NOFRAMES_TAG,   [], [])); //16.3. Non-conforming. Either use IFRAME and CSS instead, or use server-side includes
	AList.Add(THtmlTag.Create('noscript',   NOSCRIPT_TAG,   [], []));
	AList.Add(THtmlTag.Create('object',     OBJECT_TAG,     [], []));
	AList.Add(THtmlTag.Create('ol',         OL_TAG,         [], []));
	AList.Add(THtmlTag.Create('optgroup',   OPTGROUP_TAG,   [], []));
	AList.Add(THtmlTag.Create('option',     OPTION_TAG,     [], []));
	AList.Add(THtmlTag.Create('p',          P_TAG,          [], []));
	AList.Add(THtmlTag.Create('param',      PARAM_TAG,      [], []));
	AList.Add(THtmlTag.Create('pre',        PRE_TAG,        [], []));
	AList.Add(THtmlTag.Create('q',          Q_TAG,          [], []));
	AList.Add(THtmlTag.Create('s',          S_TAG,          [], []));
	AList.Add(THtmlTag.Create('samp',       SAMP_TAG,       [], []));
	AList.Add(THtmlTag.Create('script',     SCRIPT_TAG,     [], []));
	AList.Add(THtmlTag.Create('select',     SELECT_TAG,     [], []));
	AList.Add(THtmlTag.Create('small',      SMALL_TAG,      [], []));
	AList.Add(THtmlTag.Create('span',       SPAN_TAG,       [], []));
	AList.Add(THtmlTag.Create('strike',     STRIKE_TAG,     [], []));
	AList.Add(THtmlTag.Create('strong',     STRONG_TAG,     [], []));
	AList.Add(THtmlTag.Create('style',      STYLE_TAG,      [], []));
	AList.Add(THtmlTag.Create('sub',        SUB_TAG,        [], []));
	AList.Add(THtmlTag.Create('sup',        SUP_TAG,        [], []));
	AList.Add(THtmlTag.Create('table',      TABLE_TAG,      [], []));
	AList.Add(THtmlTag.Create('tbody',      TBODY_TAG,      [], []));
	AList.Add(THtmlTag.Create('td',         TD_TAG,         [], []));
	AList.Add(THtmlTag.Create('template',   TEMPLATE_TAG,   [], []));
	AList.Add(THtmlTag.Create('textarea',   TEXTAREA_TAG,   [], []));
	AList.Add(THtmlTag.Create('tfoot',      TFOOT_TAG,      [], []));
	AList.Add(THtmlTag.Create('th',         TH_TAG,         [], []));
	AList.Add(THtmlTag.Create('thead',      THEAD_TAG,      [], []));
	AList.Add(THtmlTag.Create('title',      TITLE_TAG,      [], []));
	AList.Add(THtmlTag.Create('tr',         TR_TAG,         [], []));
	AList.Add(THtmlTag.Create('tt',         TT_TAG,         [], []));
	AList.Add(THtmlTag.Create('u',          U_TAG,          [], []));
	AList.Add(THtmlTag.Create('ul',         UL_TAG,         [], []));
	AList.Add(THtmlTag.Create('var',        VAR_TAG,        [], []));
end;

destructor THtmlTagList.Destroy;
var
	I: Integer;
begin
	for I := FList.Count - 1 downto 0 do
		THtmlTag(FList[I]).Free;
	FList.Free;
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
//	Result := CompareStr(FSearchName, Tag.Name)
	Result := CompareText(FSearchName, Tag.Name); //html is case insensitive
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

function THtmlTagList.GetTagID(const Name: UnicodeString): TTagID;
begin
	//returns 0 for unknown tags
	Result := GetTagByName(Name).Number;
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

constructor TURLSchemes.Create;
begin
	inherited Create;

	Self.Add('http');
	Self.Add('https');
	Self.Add('ftp');
	Self.Add('mailto');
	Self.Add('news');
	Self.Add('nntp');
	Self.Add('gopher');
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

var
	g_HtmlTagList: THtmlTagList = nil;

function HtmlTagList: THtmlTagList;
var
	list: THtmlTagList;
begin
	if g_HtmlTagList = nil then
	begin
		list := THtmlTagList.Create;
		g_HtmlTagList := list;
	end;

	Result := g_HtmlTagList;
end;

var
	g_URLSchemes: TURLSchemes = nil;

function URLSchemes: TURLSchemes;
var
	list: TUrlSchemes;
begin
	if g_URLSchemes = nil then
	begin
		list := TURLSchemes.Create;
		g_URLSchemes := list;
	end;

	Result := g_URLSchemes;
end;

initialization

finalization
	FreeAndNil(g_HtmlTagList);
	FreeAndNil(g_URLSchemes);

end.
