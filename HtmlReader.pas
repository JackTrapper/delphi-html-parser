unit HtmlReader;

{
	The THTMLReader parses an HTML string into tokens, and presents them to the
	caller using a SAX-like eventing model.

	Listeners attach to the various OnXxx events:

		rdr.OnDocType := DocType;
		rdr.OnElementStart := ElementStart;
		rdr.OnElementEnd := ElementEnd;
		rdr.OnAttributeStart := AttributeStart;
		rdr.OnAttributeEnd := AttributeEnd;
		rdr.OnCDataSection := CDataSection;
		rdr.OnComment := Comment;
		rdr.OnEndElement := EndElement;
		rdr.OnEntityReference := EntityReference;
		rdr.OnTextNode := TextNode;

	This class is used by THTMLParser to process a string into a TDocument.

	You should not need to use this class directly unless you need to stream
	processing of a very large HTML document.

	See THtmlParser.ParseString for complete example of usage.

		var
			rdr: THtmlReader;

		rdr := THtmlReader.Create;
		rdr.OnElementStart := ElementStart;
		rdr.HtmlStr := '<HTML><BODY>Hello, world!</BODY></HTML>';
		while rdr.Read do
		begin

		end;
		rdr.Free;

	TODO: Allow reading the HTML from a TStream.

	Version History
	===============
	1/7/2021
		- Removed ReadEntityNode, since entities are no longer separate nodes - but instead just text
	12/28/2021
		- Set NodeType property before firing OnDocType event
	12/22/2021
		- LowerCase the doctype name
		- Doctype publicid and systemid can also be enclosed in apostrophe in addition to QUOTATION MARK
	12/20/2021
		- Fixed ReadQuotedStr to not also return the final '"' character.
		  (only used by doctype reading)
}

interface

uses
	Classes, DomCore;

type
	TDelimiters = set of Byte;

	TReaderState = (rsInitial, rsBeforeAttr, rsBeforeValue, rsInValue, rsInQuotedValue);

	TStringGenerator = reference to function: UnicodeString;

	THtmlReader = class
	private
		FHtmlStr: TDomString; //the HTML string we are parsing
		FPosition: Integer;   //current index in HtmlStr

		FNodeType: TNodeType;
		FPrefix: TDomString;
		FLocalName: TDomString;
		FNodeValue: TDomString;
		FPublicID: TDomString;
		FSystemID: TDomString;
		FIsEmptyElement: Boolean;
		FState: TReaderState;
		FQuotation: Word;

		FOnDocType: TNotifyEvent;
		FOnElementStart: TNotifyEvent;
		FOnElementEnd: TNotifyEvent;
		FOnEndElement: TNotifyEvent;
		FOnAttributeStart: TNotifyEvent;
		FOnAttributeValue: TNotifyEvent;
		FOnAttributeEnd: TNotifyEvent;
		FOnCDataSection: TNotifyEvent;
		FOnComment: TNotifyEvent;
		FOnEntityReference: TNotifyEvent;
		//FOnNotation: TNotifyEvent;
		//FOnProcessingInstruction: TNotifyEvent;
		FOnTextNode: TNotifyEvent;

		procedure LogFmt(const fmt: string; const Args: array of const);
		procedure LogBack(Callback: TStringGenerator);

		procedure SetHtmlStr(const Value: TDomString);
		procedure SetNodeName(Value: TDomString);
		function GetNodeName: TDomString;

		function IsEOF: Boolean;

		function GetToken(Delimiters: TDelimiters): TDomString;
		function IsAttrTextChar: Boolean;
		function IsDigit(HexBase: Boolean): Boolean;	//current character is [0..9]
		function IsEndEntityChar: Boolean;				//current character is [;]
		function IsEntityChar: Boolean;
		function IsEqualChar: Boolean;					//current character is [=]
		function IsHexEntityChar: Boolean;
		function IsNumericEntity: Boolean;				//current character is [#]
		function IsQuotation: Boolean;
		function IsSlashChar: Boolean;					//current character is [/]
		function IsSpecialTagChar: Boolean;				//current character is [!]
		function IsStartCharacterData: Boolean;
		function IsStartComment: Boolean;
		function IsStartDocumentType: Boolean;
		function IsStartEntityChar: Boolean;			//current character is [&]
		function IsStartMarkupChar: Boolean;
		function IsStartTagChar: Boolean;
		function Match(const Signature: TDomString; IgnoreCase: Boolean): Boolean;

		function ReadElementNode: Boolean;			//fires OnElementStart (NodeName, NodeType)
		procedure ReadElementTail;						//fires OnElementEnd (NodeType)
		function ReadEndElementNode: Boolean;		//fires OnEndElement (NodeName, NodeType)
		function ReadAttrNode: Boolean; 				//fires OnAttributeStart (NodeName)
		function ReadAttrTextNode: Boolean;			//fires OnTextNode (NodeValue, NodeType)
		function ReadSpecialNode: Boolean;			//calls ReadComment, ReadCharacterData, or ReadDocumentType
		function ReadComment: Boolean;				//fires OnComment (NodeValue, NodeType)
		function ReadCharacterData: Boolean;		//fires OnCDataSection (NodeValue, NodeType)
		function ReadDocumentType: Boolean;			//fires OnDocType (NodeName, PublicID, SystemID)
		procedure ReadTextNode;							//fires OnTextNode (NodeValue, NodeType)

		function ReadQuotedValue(var Value: TDomString): Boolean;
		function ReadTagNode: Boolean;
		function ReadValueNode: Boolean;
		function SkipTo(const Signature: TDomString): Boolean;
		procedure SkipWhiteSpaces;

		//Event callers
		procedure DoDocType(const Name, PublicID, SystemID: UnicodeString);
		procedure DoElementStart(const TagName: UnicodeString);
		procedure DoElementEnd(IsEmptyElement: Boolean);
		procedure DoEndElement(const TagName: UnicodeString);
		procedure DoAttributeStart(const AttributeName: UnicodeString);
		procedure DoAttributeValue(const AttributeValue: UnicodeString);
		procedure DoAttributeEnd();
		procedure DoTextNode(const NodeValue: UnicodeString);
		procedure DoComment(const NodeValue: UnicodeString);
		procedure DoCDataSection(const NodeValue: UnicodeString);
	public
		constructor Create;

		function Read: Boolean;

		property HtmlStr: TDomString read FHtmlStr write SetHtmlStr;

		property Position: Integer read FPosition;
		property State: TReaderState read FState;

		// Properties of current read state
		property NodeType: TNodeType read FNodeType;
		property prefix: TDomString read FPrefix;
		property localName: TDomString read FLocalName;
		property nodeName: TDomString read GetNodeName; //synthetic from Prefix and LocalName
		property nodeValue: TDomString read FNodeValue;
		property publicID: TDomString read FPublicID;
		property systemID: TDomString read FSystemID;
		property isEmptyElement: Boolean read FIsEmptyElement;

		//SAX-like events
		property OnDocType: TNotifyEvent read FOnDocType write FOnDocType;
		property OnElementStart: TNotifyEvent read FOnElementStart write FOnElementStart;
		property OnElementEnd: TNotifyEvent read FOnElementEnd write FOnElementEnd; //nodeType, isEmptyElement
		property OnEndElement: TNotifyEvent read FOnEndElement write FOnEndElement;
		property OnAttributeStart: TNotifyEvent read FOnAttributeStart write FOnAttributeStart;
		property OnAttributeValue: TNotifyEvent read FOnAttributeValue write FOnAttributeValue;
		property OnAttributeEnd: TNotifyEvent read FOnAttributeEnd write FOnAttributeEnd;
		property OnTextNode: TNotifyEvent read FOnTextNode write FOnTextNode;
		property OnComment: TNotifyEvent read FOnComment write FOnComment;
		property OnEntityReference: TNotifyEvent read FOnEntityReference write FOnEntityReference;
		property OnCDataSection: TNotifyEvent read FOnCDataSection write FOnCDataSection; //Normally not allowed in HTML (only MathML and SVG elements)
		//property OnProcessingInstruction: TNotifyEvent read FOnProcessingInstruction write FOnProcessingInstruction; not allowed in HTML
	end;

implementation

uses
	SysUtils, Windows;

const
	startTagChar 			= Ord('<');
	endTagChar 				= Ord('>');
	specialTagChar 		= Ord('!');
	slashChar 				= Ord('/');
	equalChar 				= Ord('=');
	quotation 				= [Ord(''''), Ord('"')];
	tagDelimiter 			= [slashChar, endTagChar];
	tagNameDelimiter 		= whiteSpace + tagDelimiter;
	attrNameDelimiter 	= tagNameDelimiter + [equalChar];
	startEntity 			= Ord('&');
	startMarkup 			= [startTagChar, startEntity];
	endEntity 				= Ord(';');
	notEntity 				= [endEntity] + startMarkup + whiteSpace;
	notAttrText 			= whiteSpace + quotation + tagDelimiter;
	numericEntity 			= Ord('#');
	hexEntity 				= [Ord('x'), Ord('X')];
	decDigit 				= [Ord('0')..Ord('9')];
	hexDigit 				= [Ord('a')..Ord('f'), Ord('A')..Ord('F')];

const
	//https://infra.spec.whatwg.org/#code-points
	asciiDigit				= [Ord('0')..Ord('9')]; //https://infra.spec.whatwg.org/#ascii-digit
	asciiUpperHexDigit	= [Ord('A')..Ord('F')]; //https://infra.spec.whatwg.org/#ascii-upper-hex-digit
	asciiLowerHexDigit	= [Ord('a')..Ord('f')]; //https://infra.spec.whatwg.org/#ascii-lower-hex-digit
	asciiHexDigit			= asciiUpperHexDigit + asciiLowerHexDigit; //https://infra.spec.whatwg.org/#ascii-hex-digit
	asciiUpperAlpha		= [Ord('A')..Ord('Z')]; //https://infra.spec.whatwg.org/#ascii-upper-alpha
	asciiLowerAlpha		= [Ord('a')..Ord('z')]; //https://infra.spec.whatwg.org/#ascii-lower-alpha
	asciiAlpha				= asciiUpperAlpha + asciiLowerAlpha; //https://infra.spec.whatwg.org/#ascii-alpha
	asciiAlphaNumeric		= asciiDigit + asciiAlpha; //https://infra.spec.whatwg.org/#ascii-alphanumeric

const
	DocTypeStartStr 	= 'DOCTYPE';
	DocTypeEndStr 		= '>';
	CDataStartStr 		= '[CDATA[';
	CDataEndStr 		= ']]>';
	CommentStartStr 	= '--';
	CommentEndStr 		= '-->';

	SBoolean: array[Boolean] of string = ('False', 'True');

function DecValue(const Digit: WideChar): Word;
begin
	Result := Ord(Digit) - Ord('0')
end;

function HexValue(const HexChar: WideChar): Word;
var
	C: Char;
begin
	if Ord(HexChar) in decDigit then
		Result := Ord(HexChar) - Ord('0')
	else
	begin
		C := UpCase(Chr(Ord(HexChar)));
		Result := Ord(C) - Ord('A')
	end
end;

constructor THtmlReader.Create;
begin
	inherited Create;
	FHtmlStr := HtmlStr;
	FPosition := 1
end;

function THtmlReader.GetNodeName: TDomString;
begin
	if FPrefix <> '' then
		Result := FPrefix + ':' + FLocalName
	else
		Result := FLocalName
end;

function THtmlReader.GetToken(Delimiters: TDelimiters): TDomString;
var
	start: Integer;
begin
	start := FPosition;
	while (FPosition <= Length(FHtmlStr)) and not (Ord(FHtmlStr[FPosition]) in Delimiters) do
		Inc(FPosition);
	Result := Copy(FHtmlStr, start, FPosition - start)
end;

function THtmlReader.IsAttrTextChar: Boolean;
var
	wc: WideChar;
begin
	wc := FHtmlStr[FPosition];
	if FState = rsInQuotedValue then
		Result := (Ord(wc) <> FQuotation) // and (Ord(wc) <> startEntity)
	else
		Result := not (Ord(wc) in notAttrText)
end;

function THtmlReader.IsDigit(HexBase: Boolean): Boolean;
var
	wc: WideChar;
begin
	wc := FHtmlStr[FPosition];
	Result := Ord(wc) in decDigit;
	if not Result and HexBase then
		Result := Ord(wc) in hexDigit
end;

function THtmlReader.IsEndEntityChar: Boolean;
var
	wc: WideChar;
begin
	wc := FHtmlStr[FPosition];
	Result := (Ord(wc) = endEntity);
end;

function THtmlReader.IsEntityChar: Boolean;
var
	WC: WideChar;
begin
	WC := FHtmlStr[FPosition];
	Result := not (Ord(WC) in notEntity)
end;

function THtmlReader.IsEOF: Boolean;
begin
{
	Returns true if there are no more characters to read.
}
	Result := (FPosition > Length(FHtmlStr));
end;

function THtmlReader.IsEqualChar: Boolean;
var
	wc: WideChar;
begin
	wc := FHtmlStr[FPosition];
	Result := (Ord(wc) = equalChar);
end;

function THtmlReader.IsHexEntityChar: Boolean;
var
	WC: WideChar;
begin
	WC := FHtmlStr[FPosition];
	Result := Ord(WC) in hexEntity;
end;

function THtmlReader.IsNumericEntity: Boolean;
var
	WC: WideChar;
begin
	WC := FHtmlStr[FPosition];
	Result := Ord(WC) = numericEntity
end;

function THtmlReader.IsQuotation: Boolean;
var
	WC: WideChar;
begin
	WC := FHtmlStr[FPosition];
	if FQuotation = 0 then
		Result := Ord(WC) in quotation
	else
		Result := Ord(WC) = FQuotation
end;

function THtmlReader.IsSlashChar: Boolean;
var
	WC: WideChar;
begin
	WC := FHtmlStr[FPosition];
	Result := Ord(WC) = slashChar
end;

function THtmlReader.IsSpecialTagChar: Boolean;
var
	WC: WideChar;
begin
	WC := FHtmlStr[FPosition];
	Result := Ord(WC) = specialTagChar
end;

function THtmlReader.IsStartCharacterData: Boolean;
begin
	Result := Match(CDataStartStr, false)
end;

function THtmlReader.IsStartComment: Boolean;
begin
	Result := Match(CommentStartStr, false)
end;

function THtmlReader.IsStartDocumentType: Boolean;
begin
	Result := Match(DocTypeStartStr, true)
end;

function THtmlReader.IsStartEntityChar: Boolean;
var
	wc: WideChar;
begin
{
	Returns true if the current input character is "&" - the entity start character. E.g.:

		&amp;
		&lt;
		&#128169;
		&#x1f4a9;
}
	wc := FHtmlStr[FPosition];
	Result := (Ord(wc) = startEntity);
end;

function THtmlReader.IsStartMarkupChar: Boolean;
var
	WC: WideChar;
begin
	WC := FHtmlStr[FPosition];
	Result := Ord(WC) in startMarkup
end;

function THtmlReader.IsStartTagChar: Boolean;
var
	WC: WideChar;
begin
	WC := FHtmlStr[FPosition];
	Result := Ord(WC) = startTagChar
end;

procedure THtmlReader.LogBack(Callback: TStringGenerator);
//var
//	s: UnicodeString;
begin
	if IsDebuggerPresent then
	begin
//		s := Callback;
//		OutputDebugStringW(PWideChar(s));
	end;
end;

procedure THtmlReader.LogFmt(const fmt: string; const Args: array of const);
//var
//	s: string;
begin
	if True then
	begin
//		s := Format(fmt, Args);
//		OutputDebugString(PChar('[THtmlReader] '+s));
	end;
end;

function THtmlReader.Match(const Signature: TDomString; IgnoreCase: Boolean): Boolean;
var
	I, J: Integer;
	W1, W2: WideChar;
begin
	Result := false;
	for I := 1 to Length(Signature) do
	begin
		J := FPosition + I - 1;
		if (J < 1) or (J > Length(FHtmlStr)) then
			Exit;
		W1 := Signature[I];
		W2 := FHtmlStr[J];
		if (W1 <> W2) and (not IgnoreCase or (UpperCase(W1) <> UpperCase(W2))) then
			Exit
	end;
	Result := true
end;

function HtmlDecode(s: string): string;

	function UCS4CharToString(uch: UCS4Char): UnicodeString;
	var
		s: UCS4String;
	begin
		SetLength(s, 2);
		s[0] := uch;
		s[1] := 0; //null terminator
		Result := UCS4StringToUnicodeString(s);
	end;

	function GetCharRef(sValue: string; StartIndex: Integer; out CharRef: string): UnicodeString;
	var
		i: Integer;
		len: Integer;
		nChar: UCS4Char;
	begin
		{
			Character references come in either decimal or hex forms:

				&#9830;   //decimal
				&#x2666;  //hexidecimal

			As per the definition:

				CharRef  ::=  '&#' [0-9]+ ';'
								  |
								  '&#x' [0-9a-fA-F]+ ';'
		}
		Result := '';
		CharRef := '';

		len := Length(sValue) - StartIndex + 1;
		if len < 4 then
			Exit;
		i := StartIndex;
		if sValue[i] <> '&' then Exit;
		Inc(i);
		if sValue[i] <> '#' then Exit;
		Inc(i);

		if sValue[i] = 'x' then
		begin
			{
				Hex character reference

					CharRef ::= '&#x' [0-9a-fA-F]+ ';'

				E.g. &#x2666;
			}
			Inc(i); //skip the x
			while CharInSet(sValue[i], ['0'..'9', 'a'..'f', 'A'..'F']) do
			begin
				Inc(i);
				if i > Length(sValue) then
					Exit;
			end;
			if sValue[i] <> ';' then
				Exit;

			charRef := Copy(sValue, StartIndex, (i-StartIndex)+1);
			nChar := StrToInt('$'+Copy(charRef, 4, Length(charRef)-4));
		end
		else
		begin
			{
				Decimal character reference

					CharRef  ::=  '&#' [0-9]+ ';'

				E.g. &#9830;
			}

			while CharInSet(sValue[i], ['0'..'9']) do
			begin
				Inc(i);
				if i > Length(sValue) then
					Exit;
			end;
			if sValue[i] <> ';' then
				Exit;

			charRef := Copy(sValue, StartIndex, (i-StartIndex)+1);
			nChar := StrToInt(Copy(charRef, 3, Length(charRef)-3));
		end;
		Result := UCS4CharToString(nChar);
	end;

	function GetEntityRef(sValue: string; StartIndex: Integer; out CharRef: string): UnicodeString;

		function IsNameStartChar(ch: WideChar): Boolean;
		begin
			{
				NameStartChar ::= ":" | [A-Z] | "_" | [a-z] | [#xC0-#xD6] | [#xD8-#xF6] | [#xF8-#x2FF] | [#x370-#x37D] | [#x37F-#x1FFF] | [#x200C-#x200D] | [#x2070-#x218F] | [#x2C00-#x2FEF] | [#x3001-#xD7FF] | [#xF900-#xFDCF] | [#xFDF0-#xFFFD] | [#x10000-#xEFFFF]
			}
			Result := False;

			case ch of
			':', 'A'..'Z', '_', 'a'..'z', #$C0..#$D6, #$D8..#$F6, #$F8..#$FF: Result := True;
			#$100..#$2FF, #$370..#$37D, #$37F..#$FFF: Result := True;
			#$1000..#$1FFF, #$200C..#$200D, #$2070..#$218F, #$2C00..#$2FEF, #$3001..#$D7FF, #$F900..#$FDCF, #$FDF0..#$FFFD: Result := True;
			else
				//We assume strings are UTF-16. But by assuming one 16-bit word is the same as one character is just wrong.
				//UTF-16, like UTF-8 can be multi-byte.
				//But it's just so haaaard to support.
				//The correct action is to convert the string to UCS4, where one code-point is always one character.
				case Integer(ch) of
				$10000..$EFFFF: Result := True;
				end;
			end;
		end;

		function IsNameChar(ch: WideChar): Boolean;
		begin
			if IsNameStartChar(ch) then
			begin
				Result := True;
				Exit;
			end;

			case ch of
			'-', '.', '0'..'9', #$B7, #$0300..#$036F, #$203F..#$2040: Result := True;
			else
				Result := False;
			end;
		end;

		type
			THtmlEntity = record
				entity: string;
				ch: UCS4Char;
			end;
		const
			//https://www.w3.org/TR/html4/sgml/entities.html#sym
			//html entities are case sensitive (e.g. "larr" is different from "lArr")
			HtmlEntities: array[0..252] of THtmlEntity = (
				(entity: 'apos';		ch: 39;	), // apostrophe (originally only existed in xml, and not in HTML. Was added to HTML5

				//24.2 Character entity references for ISO 8859-1 characters
				(entity: 'nbsp';		ch: 160;	),	// no-break space = non-breaking space,    U+00A0
				(entity: 'iexcl';		ch: 161;	),	// inverted exclamation mark, U+00A1
				(entity: 'cent';		ch: 162;	),	// cent sign, U+00A2
				(entity: 'pound';		ch: 163;	),	// pound sign, U+00A3
				(entity: 'curren';	ch: 164;	),	// currency sign, U+00A4
				(entity: 'yen';		ch: 165;	),	// yen sign = yuan sign, U+00A5
				(entity: 'brvbar';	ch: 166;	),	// broken bar = broken vertical bar,    U+00A6
				(entity: 'sect';		ch: 167;	),	// section sign, U+00A7
				(entity: 'uml';		ch: 168;	),	// diaeresis = spacing diaeresis,    U+00A8
				(entity: 'copy';		ch: 169;	),	// copyright sign, U+00A9
				(entity: 'ordf';		ch: 170;	),	// feminine ordinal indicator, U+00AA
				(entity: 'laquo';		ch: 171;	),	// left-pointing double angle quotation mark = left pointing guillemet, U+00AB
				(entity: 'not';		ch: 172;	),	// not sign, U+00AC
				(entity: 'shy';		ch: 173;	),	// soft hyphen = discretionary hyphen,    U+00AD
				(entity: 'reg';		ch: 174;	),	// registered sign = registered trade mark sign,    U+00AE
				(entity: 'macr';		ch: 175;	),	// macron = spacing macron = overline  = APL overbar, U+00AF
				(entity: 'deg';		ch: 176;	),	// degree sign, U+00B0
				(entity: 'plusmn';	ch: 177;	),	// plus-minus sign = plus-or-minus sign,    U+00B1
				(entity: 'sup2';		ch: 178;	),	// superscript two = superscript digit two  = squared, U+00B2
				(entity: 'sup3';		ch: 179;	),	// superscript three = superscript digit three  = cubed, U+00B3
				(entity: 'acute';		ch: 180;	),	// acute accent = spacing acute,    U+00B4
				(entity: 'micro';		ch: 181;	),	// micro sign, U+00B5
				(entity: 'para';		ch: 182;	),	// pilcrow sign = paragraph sign,    U+00B6
				(entity: 'middot';	ch: 183;	),	// middle dot = Georgian comma = Greek middle dot, U+00B7
				(entity: 'cedil';		ch: 184;	),	// cedilla = spacing cedilla, U+00B8
				(entity: 'sup1';		ch: 185;	),	// superscript one = superscript digit one,    U+00B9
				(entity: 'ordm';		ch: 186;	),	// masculine ordinal indicator,    U+00BA
				(entity: 'raquo';		ch: 187;	),	// right-pointing double angle quotation mark =  right pointing guillemet, U+00BB
				(entity: 'frac14';	ch: 188;	),	// vulgar fraction one quarter  = fraction one quarter, U+00BC
				(entity: 'frac12';	ch: 189;	),	// vulgar fraction one half  = fraction one half, U+00BD
				(entity: 'frac34';	ch: 190;	),	// vulgar fraction three quarters  = fraction three quarters, U+00BE
				(entity: 'iquest';	ch: 191;	),	// inverted question mark  = turned question mark, U+00BF
				(entity: 'Agrave';	ch: 192;	),	// latin capital letter A with grave  = latin capital letter A grave,    U+00C0
				(entity: 'Aacute';	ch: 193;	),	// latin capital letter A with acute,    U+00C1
				(entity: 'Acirc';		ch: 194;	),	// latin capital letter A with circumflex,    U+00C2
				(entity: 'Atilde';	ch: 195;	),	// latin capital letter A with tilde,    U+00C3
				(entity: 'Auml';		ch: 196;	),	// latin capital letter A with diaeresis,    U+00C4
				(entity: 'Aring';		ch: 197;	),	// latin capital letter A with ring above  = latin capital letter A ring,    U+00C5
				(entity: 'AElig';		ch: 198;	),	// latin capital letter AE  = latin capital ligature AE,    U+00C6
				(entity: 'Ccedil';	ch: 199;	),	// latin capital letter C with cedilla,    U+00C7
				(entity: 'Egrave';	ch: 200;	),	// latin capital letter E with grave,    U+00C8
				(entity: 'Eacute';	ch: 201;	),	// latin capital letter E with acute,    U+00C9
				(entity: 'Ecirc';		ch: 202;	),	// latin capital letter E with circumflex,    U+00CA
				(entity: 'Euml';		ch: 203;	),	// latin capital letter E with diaeresis,    U+00CB
				(entity: 'Igrave';	ch: 204;	),	// latin capital letter I with grave,    U+00CC
				(entity: 'Iacute';	ch: 205;	),	// latin capital letter I with acute,    U+00CD
				(entity: 'Icirc';		ch: 206;	),	// latin capital letter I with circumflex,    U+00CE
				(entity: 'Iuml';		ch: 207;	),	// latin capital letter I with diaeresis,    U+00CF
				(entity: 'ETH';		ch: 208;	),	// latin capital letter ETH, U+00D0
				(entity: 'Ntilde';	ch: 209;	),	// latin capital letter N with tilde,    U+00D1
				(entity: 'Ograve';	ch: 210;	),	// latin capital letter O with grave,    U+00D2
				(entity: 'Oacute';	ch: 211;	),	// latin capital letter O with acute,    U+00D3
				(entity: 'Ocirc';		ch: 212;	),	// latin capital letter O with circumflex,    U+00D4
				(entity: 'Otilde';	ch: 213;	),	// latin capital letter O with tilde,    U+00D5
				(entity: 'Ouml';		ch: 214;	),	// latin capital letter O with diaeresis,    U+00D6
				(entity: 'times';		ch: 215;	),	// multiplication sign, U+00D7
				(entity: 'Oslash';	ch: 216;	),	// latin capital letter O with stroke  = latin capital letter O slash,    U+00D8
				(entity: 'Ugrave';	ch: 217;	),	// latin capital letter U with grave,    U+00D9
				(entity: 'Uacute';	ch: 218;	),	// latin capital letter U with acute,    U+00DA
				(entity: 'Ucirc';		ch: 219;	),	// latin capital letter U with circumflex,    U+00DB
				(entity: 'Uuml';		ch: 220;	),	// latin capital letter U with diaeresis,    U+00DC
				(entity: 'Yacute';	ch: 221;	),	// latin capital letter Y with acute,    U+00DD
				(entity: 'THORN';		ch: 222;	),	// latin capital letter THORN,    U+00DE
				(entity: 'szlig';		ch: 223;	),	// latin small letter sharp s = ess-zed,    U+00DF
				(entity: 'agrave';	ch: 224;	),	// latin small letter a with grave  = latin small letter a grave,    U+00E0
				(entity: 'aacute';	ch: 225;	),	// latin small letter a with acute,    U+00E1
				(entity: 'acirc';		ch: 226;	),	// latin small letter a with circumflex,    U+00E2
				(entity: 'atilde';	ch: 227;	),	// latin small letter a with tilde,    U+00E3
				(entity: 'auml';		ch: 228;	),	// latin small letter a with diaeresis,    U+00E4
				(entity: 'aring';		ch: 229;	),	// latin small letter a with ring above  = latin small letter a ring,    U+00E5
				(entity: 'aelig';		ch: 230;	),	// latin small letter ae  = latin small ligature ae, U+00E6
				(entity: 'ccedil';	ch: 231;	),	// latin small letter c with cedilla,    U+00E7
				(entity: 'egrave';	ch: 232;	),	// latin small letter e with grave,    U+00E8
				(entity: 'eacute';	ch: 233;	),	// latin small letter e with acute,    U+00E9
				(entity: 'ecirc';		ch: 234;	),	// latin small letter e with circumflex,    U+00EA
				(entity: 'euml';		ch: 235;	),	// latin small letter e with diaeresis,    U+00EB
				(entity: 'igrave';	ch: 236;	),	// latin small letter i with grave,    U+00EC
				(entity: 'iacute';	ch: 237;	),	// latin small letter i with acute,    U+00ED
				(entity: 'icirc';		ch: 238;	),	// latin small letter i with circumflex,    U+00EE
				(entity: 'iuml';		ch: 239;	),	// latin small letter i with diaeresis,    U+00EF
				(entity: 'eth';		ch: 240;	),	// latin small letter eth, U+00F0
				(entity: 'ntilde';	ch: 241;	),	// latin small letter n with tilde,    U+00F1
				(entity: 'ograve';	ch: 242;	),	// latin small letter o with grave,    U+00F2
				(entity: 'oacute';	ch: 243;	),	// latin small letter o with acute,    U+00F3
				(entity: 'ocirc';		ch: 244;	),	// latin small letter o with circumflex,    U+00F4
				(entity: 'otilde';	ch: 245;	),	// latin small letter o with tilde,    U+00F5
				(entity: 'ouml';		ch: 246;	),	// latin small letter o with diaeresis,    U+00F6
				(entity: 'divide';	ch: 247;	),	// division sign, U+00F7
				(entity: 'oslash';	ch: 248;	),	// latin small letter o with stroke,    = latin small letter o slash,    U+00F8
				(entity: 'ugrave';	ch: 249;	),	// latin small letter u with grave,    U+00F9
				(entity: 'uacute';	ch: 250;	),	// latin small letter u with acute,    U+00FA
				(entity: 'ucirc';		ch: 251;	),	// latin small letter u with circumflex,    U+00FB
				(entity: 'uuml';		ch: 252;	),	// latin small letter u with diaeresis,    U+00FC
				(entity: 'yacute';	ch: 253;	),	// latin small letter y with acute,    U+00FD
				(entity: 'thorn';		ch: 254;	),	// latin small letter thorn,    U+00FE
				(entity: 'yuml';		ch: 255;	),	// latin small letter y with diaeresis,    U+00FF

				//24.3 Character entity references for symbols, mathematical symbols, and Greek letters
				(entity: 'fnof';		ch: 402;	),	// latin small f with hook = function  = florin, U+0192
				(entity: 'Alpha';		ch: 913;	),	// greek capital letter alpha, U+0391
				(entity: 'Beta';		ch: 914;	),	// greek capital letter beta, U+0392
				(entity: 'Gamma';		ch: 915;	),	// greek capital letter gamma,    U+0393
				(entity: 'Delta';		ch: 916;	),	// greek capital letter delta,    U+0394
				(entity: 'Epsilon';	ch: 917;	),	// greek capital letter epsilon, U+0395
				(entity: 'Zeta';		ch: 918;	),	// greek capital letter zeta, U+0396
				(entity: 'Eta';		ch: 919;	),	// greek capital letter eta, U+0397
				(entity: 'Theta';		ch: 920;	),	// greek capital letter theta,    U+0398
				(entity: 'Iota';		ch: 921;	),	// greek capital letter iota, U+0399
				(entity: 'Kappa';		ch: 922;	),	// greek capital letter kappa, U+039A
				(entity: 'Lambda';	ch: 923;	),	// greek capital letter lambda,    U+039B
				(entity: 'Mu';			ch: 924;	),	// greek capital letter mu, U+039C
				(entity: 'Nu';			ch: 925;	),	// greek capital letter nu, U+039D
				(entity: 'Xi';			ch: 926;	),	// greek capital letter xi, U+039E
				(entity: 'Omicron';	ch: 927;	),	// greek capital letter omicron, U+039F
				(entity: 'Pi';			ch: 928;	),	// greek capital letter pi, U+03A0
				(entity: 'Rho';		ch: 929;	),	// greek capital letter rho, U+03A1
				// there is no Sigmaf, and no U+03A2 character either
				(entity: 'Sigma';		ch: 931;	),	// greek capital letter sigma,    U+03A3
				(entity: 'Tau';		ch: 932;	),	// greek capital letter tau, U+03A4
				(entity: 'Upsilon';	ch: 933;	),	// greek capital letter upsilon,    U+03A5
				(entity: 'Phi';		ch: 934;	),	// greek capital letter phi,    U+03A6
				(entity: 'Chi';		ch: 935;	),	// greek capital letter chi, U+03A7
				(entity: 'Psi';		ch: 936;	),	// greek capital letter psi,    U+03A8
				(entity: 'Omega';		ch: 937;	),	// greek capital letter omega,    U+03A9
				(entity: 'alpha';		ch: 945;	),	// greek small letter alpha,    U+03B1
				(entity: 'beta';		ch: 946;	),	// greek small letter beta, U+03B2
				(entity: 'gamma';		ch: 947;	),	// greek small letter gamma,    U+03B3
				(entity: 'delta';		ch: 948;	),	// greek small letter delta,    U+03B4
				(entity: 'epsilon';	ch: 949;	),	// greek small letter epsilon,    U+03B5
				(entity: 'zeta';		ch: 950;	),	// greek small letter zeta, U+03B6
				(entity: 'eta';		ch: 951;	),	// greek small letter eta, U+03B7
				(entity: 'theta';		ch: 952;	),	// greek small letter theta,    U+03B8
				(entity: 'iota';		ch: 953;	),	// greek small letter iota, U+03B9
				(entity: 'kappa';		ch: 954;	),	// greek small letter kappa,    U+03BA
				(entity: 'lambda';	ch: 955;	),	// greek small letter lambda,    U+03BB
				(entity: 'mu';			ch: 956;	),	// greek small letter mu, U+03BC
				(entity: 'nu';			ch: 957;	),	// greek small letter nu, U+03BD
				(entity: 'xi';			ch: 958;	),	// greek small letter xi, U+03BE
				(entity: 'omicron';	ch: 959;	),	// greek small letter omicron, U+03BF NEW
				(entity: 'pi';			ch: 960;	),	// greek small letter pi, U+03C0
				(entity: 'rho';		ch: 961;	),	// greek small letter rho, U+03C1
				(entity: 'sigmaf';	ch: 962;	),	// greek small letter final sigma,    U+03C2
				(entity: 'sigma';		ch: 963;	),	// greek small letter sigma,    U+03C3
				(entity: 'tau';		ch: 964;	),	// greek small letter tau, U+03C4
				(entity: 'upsilon';	ch: 965;	),	// greek small letter upsilon,    U+03C5
				(entity: 'phi';		ch: 966;	),	// greek small letter phi, U+03C6
				(entity: 'chi';		ch: 967;	),	// greek small letter chi, U+03C7
				(entity: 'psi';		ch: 968;	),	// greek small letter psi, U+03C8
				(entity: 'omega';		ch: 969;	),	// greek small letter omega,    U+03C9
				(entity: 'thetasym';	ch: 977;	),	// greek small letter theta symbol,    U+03D1 NEW
				(entity: 'upsih';		ch: 978;	),	// greek upsilon with hook symbol,    U+03D2 NEW
				(entity: 'piv';		ch: 982;	),	// greek pi symbol, U+03D6
				(entity: 'bull';		ch: 8226;	),	// bullet = black small circle,  U+2022
				(entity: 'hellip';	ch: 8230;	),	// horizontal ellipsis = three dot leader,  U+2026
				(entity: 'prime';		ch: 8242;	),	// prime = minutes = feet, U+2032
				(entity: 'Prime';		ch: 8243;	),	// double prime = seconds = inches,  U+2033
				(entity: 'oline';		ch: 8254;	),	// overline = spacing overscore,  U+203E NEW
				(entity: 'frasl';		ch: 8260;	),	// fraction slash, U+2044 NEW
				(entity: 'weierp';	ch: 8472;	),	// script capital P = power set   = Weierstrass p, U+2118
				(entity: 'image';		ch: 8465;	),	// blackletter capital I = imaginary part,  U+2111
				(entity: 'real';		ch: 8476;	),	// blackletter capital R = real part symbol,  U+211C
				(entity: 'trade';		ch: 8482;	),	// trade mark sign, U+2122
				(entity: 'alefsym';	ch: 8501;	),	// alef symbol = first transfinite cardinal,  U+2135 NEW  (alef symbol is NOT the same as hebrew letter alef, U+05D0 although the same glyph could be used to depict both characters)
				(entity: 'larr';		ch: 8592;	),	// leftwards arrow, U+2190
				(entity: 'uarr';		ch: 8593;	),	// upwards arrow, U+2191
				(entity: 'rarr';		ch: 8594;	),	// rightwards arrow, U+2192
				(entity: 'darr';		ch: 8595;	),	// downwards arrow, U+2193
				(entity: 'harr';		ch: 8596;	),	// left right arrow, U+2194
				(entity: 'crarr';		ch: 8629;	),	// downwards arrow with corner leftwards   = carriage return, U+21B5 NEW
				(entity: 'lArr';		ch: 8656;	),	// leftwards double arrow, U+21D0
				(entity: 'uArr';		ch: 8657;	),	// upwards double arrow, U+21D1
				(entity: 'rArr';		ch: 8658;	),	// rightwards double arrow,  U+21D2
				(entity: 'dArr';		ch: 8659;	),	// downwards double arrow, U+21D3
				(entity: 'hArr';		ch: 8660;	),	// left right double arrow,  U+21D4
				(entity: 'forall';	ch: 8704;	),	// for all, U+2200
				(entity: 'part';		ch: 8706;	),	// partial differential, U+2202
				(entity: 'exist';		ch: 8707;	),	// there exists, U+2203
				(entity: 'empty';		ch: 8709;	),	// empty set = null set = diameter,  U+2205
				(entity: 'nabla';		ch: 8711;	),	// nabla = backward difference,  U+2207
				(entity: 'isin';		ch: 8712;	),	// element of, U+2208
				(entity: 'notin';		ch: 8713;	),	// not an element of, U+2209
				(entity: 'ni';			ch: 8715;	),	// contains as member, U+220B
				(entity: 'prod';		ch: 8719;	),	// n-ary product = product sign,  U+220F
				(entity: 'sum';		ch: 8721;	),	// n-ary sumation, U+2211
				(entity: 'minus';		ch: 8722;	),	// minus sign, U+2212
				(entity: 'lowast';	ch: 8727;	),	// asterisk operator, U+2217
				(entity: 'radic';		ch: 8730;	),	// square root = radical sign,  U+221A
				(entity: 'prop';		ch: 8733;	),	// proportional to, U+221D
				(entity: 'infin';		ch: 8734;	),	// infinity, U+221E
				(entity: 'ang';		ch: 8736;	),	// angle, U+2220
				(entity: 'and';		ch: 8743;	),	// logical and = wedge, U+2227
				(entity: 'or';			ch: 8744;	),	// logical or = vee, U+2228
				(entity: 'cap';		ch: 8745;	),	// intersection = cap, U+2229
				(entity: 'cup';		ch: 8746;	),	// union = cup, U+222A
				(entity: 'int';		ch: 8747;	),	// integral, U+222B
				(entity: 'there4';	ch: 8756;	),	// therefore, U+2234
				(entity: 'sim';		ch: 8764;	),	// tilde operator = varies with = similar to,  U+223C
				(entity: 'cong';		ch: 8773;	),	// approximately equal to, U+2245
				(entity: 'asymp';		ch: 8776;	),	// almost equal to = asymptotic to,  U+2248
				(entity: 'ne';			ch: 8800;	),	// not equal to, U+2260
				(entity: 'equiv';		ch: 8801;	),	// identical to, U+2261
				(entity: 'le';			ch: 8804;	),	// less-than or equal to, U+2264
				(entity: 'ge';			ch: 8805;	),	// greater-than or equal to,  U+2265
				(entity: 'sub';		ch: 8834;	),	// subset of, U+2282
				(entity: 'sup';		ch: 8835;	),	// superset of, U+2283
				(entity: 'nsub';		ch: 8836;	),	// not a subset of, U+2284
				(entity: 'sube';		ch: 8838;	),	// subset of or equal to, U+2286
				(entity: 'supe';		ch: 8839;	),	// superset of or equal to,  U+2287
				(entity: 'oplus';		ch: 8853;	),	// circled plus = direct sum,  U+2295
				(entity: 'otimes';	ch: 8855;	),	// circled times = vector product,  U+2297
				(entity: 'perp';		ch: 8869;	),	// up tack = orthogonal to = perpendicular,  U+22A5
				(entity: 'sdot';		ch: 8901;	),	// dot operator, U+22C5
				(entity: 'lceil';		ch: 8968;	),	// left ceiling = apl upstile,  U+2308
				(entity: 'rceil';		ch: 8969;	),	// right ceiling, U+2309
				(entity: 'lfloor';	ch: 8970;	),	// left floor = apl downstile,  U+230A
				(entity: 'rfloor';	ch: 8971;	),	// right floor, U+230B
				(entity: 'lang';		ch: 9001;	),	// left-pointing angle bracket = bra,  U+2329
				(entity: 'rang';		ch: 9002;	),	// right-pointing angle bracket = ket,  U+232A
				(entity: 'loz';		ch: 9674;	),	// lozenge, U+25CA
				(entity: 'spades';	ch: 9824;	),	// black spade suit, U+2660
				(entity: 'clubs';		ch: 9827;	),	// black club suit = shamrock,  U+2663
				(entity: 'hearts';	ch: 9829;	),	// black heart suit = valentine,  U+2665
				(entity: 'diams';		ch: 9830;	),	// black diamond suit, U+2666

				//24.4 Character entity references for markup-significant and internationalization characters
				(entity: 'quot';		ch: 34;	),	// quotation mark = APL quote, U+0022
				(entity: 'amp';		ch: 38;	),	// ampersand, U+0026
				(entity: 'lt';			ch: 60;	),	// less-than sign, U+003C
				(entity: 'gt';			ch: 62;	),	// greater-than sign, U+003E
				(entity: 'OElig';		ch: 338;	),	// latin capital ligature OE, U+0152
				(entity: 'oelig';		ch: 339;	),	// latin small ligature oe, U+0153
				(entity: 'Scaron';	ch: 352;	),	// latin capital letter S with caron, U+0160
				(entity: 'scaron';	ch: 353;	),	// latin small letter s with caron, U+0161
				(entity: 'Yuml';		ch: 376;	),	// latin capital letter Y with diaeresis, U+0178
				(entity: 'circ';		ch: 710;	),	// modifier letter circumflex accent, U+02C6
				(entity: 'tilde';		ch: 732;	),	// small tilde, U+02DC
				(entity: 'ensp';		ch: 8194;	),	// en space, U+2002
				(entity: 'emsp';		ch: 8195;	),	// em space, U+2003
				(entity: 'thinsp';	ch: 8201;	),	// thin space, U+2009
				(entity: 'zwnj';		ch: 8204;	),	// zero width non-joiner, U+200C NEW RFC 2070
				(entity: 'zwj';		ch: 8205;	),	// zero width joiner, U+200D NEW RFC 2070
				(entity: 'lrm';		ch: 8206;	),	// left-to-right mark, U+200E NEW RFC 2070
				(entity: 'rlm';		ch: 8207;	),	// right-to-left mark, U+200F NEW RFC 2070
				(entity: 'ndash';		ch: 8211;	),	// en dash, U+2013
				(entity: 'mdash';		ch: 8212;	),	// em dash, U+2014
				(entity: 'lsquo';		ch: 8216;	),	// left single quotation mark, U+2018
				(entity: 'rsquo';		ch: 8217;	),	// right single quotation mark, U+2019
				(entity: 'sbquo';		ch: 8218;	),	// single low-9 quotation mark, U+201A NEW
				(entity: 'ldquo';		ch: 8220;	),	// left double quotation mark, U+201C
				(entity: 'rdquo';		ch: 8221;	),	// right double quotation mark, U+201D
				(entity: 'bdquo';		ch: 8222;	),	// double low-9 quotation mark, U+201E NEW
				(entity: 'dagger';	ch: 8224;	),	// dagger, U+2020
				(entity: 'Dagger';	ch: 8225;	),	// double dagger, U+2021
				(entity: 'permil';	ch: 8240;	),	// per mille sign, U+2030
				(entity: 'lsaquo';	ch: 8249;	),	// single left-pointing angle quotation mark, U+2039
				(entity: 'rsaquo';	ch: 8250;	),	// single right-pointing angle quotation mark, U+203A
				(entity: 'euro';		ch: 8364;	)	// euro sign, U+20AC NEW
			);


	var
		i: Integer;
		len: Integer;
		nChar: UCS4Char;
		runEntity: string;
	begin
		{
			EntityRef  ::=  '&' Name ';'

				Name    ::=  NameStartChar (NameChar)*

					NameStartChar  ::=  ":" | [A-Z] | "_" | [a-z] | [#xC0-#xD6] | [#xD8-#xF6] | [#xF8-#x2FF] | [#x370-#x37D] | [#x37F-#x1FFF] | [#x200C-#x200D] | [#x2070-#x218F] | [#x2C00-#x2FEF] | [#x3001-#xD7FF] | [#xF900-#xFDCF] | [#xFDF0-#xFFFD] | [#x10000-#xEFFFF]
					NameChar	      ::=  NameStartChar | "-" | "." | [0-9] | #xB7 | [#x0300-#x036F] | [#x203F-#x2040]
		}
		Result := '';
		CharRef := '';

		len := Length(sValue) - StartIndex + 1;
		if len < 4 then
			Exit;
		i := StartIndex;
		if sValue[i] <> '&' then Exit;
		Inc(i);

		if not IsNameStartChar(sValue[i]) then
			Exit;

		Inc(i);
		while IsNameChar(sValue[i]) do
		begin
			Inc(i);
			if i > Length(sValue) then
				Exit;
		end;
		if sValue[i] <> ';' then
			Exit;

		charRef := Copy(sValue, StartIndex, (i-StartIndex)+1);

		for i := Low(HtmlEntities) to High(HtmlEntities) do
		begin
			//now strip off the & and ;
			runEntity := Copy(charRef, 2, Length(charRef)-2);

			//Case sensitive check; as entites are case sensitive
			if runEntity = HtmlEntities[i].entity then
			begin
				nChar := HtmlEntities[i].ch;
				Result := UCS4CharToString(nChar);
				Exit;
			end;
		end;

		//It looks like a valid entity reference, but we don't recognize the text.
		//It's probably garbage that we might be able to fix
		if IsDebuggerPresent then
			OutputDebugString(PChar('HtmlDecode: Unknown HTML entity reference: "'+charRef+'"'));
	end;

var
	i: Integer;
	entity: string;
	entityChar: string;
begin
	i := 1;
	Result := '';

	while i <= Length(s) do
	begin
		if s[i] <> '&' then
		begin
			Result := Result + s[i];
			Inc(i);
			Continue;
		end;

		entityChar := GetCharRef(s, i, {out}entity);
		if entityChar <> '' then
		begin
			Result := Result + entityChar;
			Inc(i, Length(entity));
			Continue;
		end;

		entityChar := GetEntityRef(s, i, {out}entity);
		if entityChar <> '' then
		begin
			Result := Result + entityChar;
			Inc(i, Length(entity));
			Continue;
		end;

		Result := Result + s[i];
		Inc(i);
	end;
end;

function THtmlReader.ReadAttrNode: Boolean;
var
	attrName: TDomString;
begin
	Result := false;
	SkipWhiteSpaces;
	attrName := LowerCase(GetToken(attrNameDelimiter));
	if attrName = '' then
		Exit;
	SetNodeName(attrName);

	DoAttributeStart(attrName);

	FState := rsBeforeValue;
	FQuotation := 0;

	Result := True
end;

function THtmlReader.ReadAttrTextNode: Boolean;
var
	start: Integer;
	attrValue: UnicodeString;
begin
	Result := False;
	start := FPosition;
	while (not IsEOF) and IsAttrTextChar do
		Inc(FPosition);
	if FPosition = start then
		Exit;
	FNodeType := TEXT_NODE;

	attrValue := Copy(FHtmlStr, start, FPosition - start);
	attrValue := HtmlDecode(attrValue); //decode entity references
	FNodeValue:= attrValue;
	DoAttributeValue(FNodeValue);
	Result := true
end;

function THtmlReader.ReadCharacterData: Boolean;
var
	startPos: Integer;
begin
	Inc(FPosition, Length(CDataStartStr));
	startPos := FPosition;
	Result := SkipTo(CDataEndStr);
	if Result then
	begin
		FNodeType := CDATA_SECTION_NODE;
		FNodeValue := Copy(FHtmlStr, startPos, FPosition - startPos - Length(CDataEndStr));
		DoCDataSection(FNodeValue);
	end
end;

function THtmlReader.ReadComment: Boolean;
var
	startPos: Integer;
begin
	Inc(FPosition, Length(CommentStartStr));
	startPos := FPosition;
	Result := SkipTo(CommentEndStr);
	if Result then
	begin
		FNodeType := COMMENT_NODE;
		FNodeValue := Copy(FHtmlStr, startPos, FPosition - startPos - Length(CommentEndStr));
		DoComment(FNodeValue);
	end
end;

function THtmlReader.ReadDocumentType: Boolean;
var
	name: TDomString;
	keyword: TDomString;
	publicID, systemID: TDomString;
begin
{
	Valid reader properties during the OnDocType event:

		- NodeType	e.g. DOCUMENT_TYPE_NODE (10)
		- NodeName	e.g. "html"
		- PublicID	e.g. "-//W3C//DTD HTML 4.01//EN"
		- SystemID	e.g. "http://www.w3.org/TR/html4/strict.dtd"


	Recommended list of Doctype declarations
	-----------------------------------------

	From: https://www.w3.org/QA/2002/04/valid-dtd-list.html

	HTML 5:
		<!DOCTYPE HTML>

	HTML 4.01
		<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
		<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
		<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Frameset//EN" "http://www.w3.org/TR/html4/frameset.dtd">

	XHTML 1.0
		<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
		<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
		<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Frameset//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-frameset.dtd">

	MathML 2.0
		<!DOCTYPE math PUBLIC "-//W3C//DTD MathML 2.0//EN" "http://www.w3.org/Math/DTD/mathml2/mathml2.dtd">

	MathML 1.0
		<!DOCTYPE math SYSTEM "http://www.w3.org/Math/DTD/mathml1/mathml.dtd">

	SVG 1.1 Full
		<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">
}
	Result := False;
	Inc(FPosition, Length(DocTypeStartStr));
	SkipWhiteSpaces;
	name := GetToken(tagNameDelimiter); //"HTML"
	if name = '' then
		Exit;

	//https://html.spec.whatwg.org/#before-doctype-name-state
	//doctype names are to be lowercased.
	//Set the token's name to the lowercase version of the current input character (add 0x0020 to the character's code point)
	name := Lowercase(name);
	SkipWhiteSpaces;
	keyword := GetToken(tagNameDelimiter); //"PUBLIC" or "SYSTEM"
	SkipWhiteSpaces;

	if SameText(keyword, 'PUBLIC') then
	begin
		if not ReadQuotedValue({var}publicID) then //  "-//x3C//DTD HTML 4.01 Transitional//EN"
			publicID := ''; //12/20/2021  Support for '<!doctype html>' where there is no public ID
	end;

	SkipWhiteSpaces;

	//https://html.spec.whatwg.org/#before-doctype-system-identifier-state
	//Both QUOTATION MARK and APOSTROPHE are allowed
	if (FHtmlStr[FPosition] = '"') or (FHtmlStr[FPosition] = '''') then
	begin
		if not ReadQuotedValue({var}systemID) then
			systemID := '';
	end;
	Result := SkipTo(DocTypeEndStr);

	FNodeType := DOCUMENT_TYPE_NODE;
	SetNodeName(name);
	FPublicID := publicID;
	FSystemID := systemID;

	DoDocType(name, publicID, systemID);
end;

function THtmlReader.ReadElementNode: Boolean;
var
	tagName: TDomString;
begin
	Result := False;
	if FPosition > Length(FHtmlStr) then
		Exit;

	tagName := GetToken(tagNameDelimiter);
	if tagName = '' then
		Exit;

	FNodeType := ELEMENT_NODE;
	SetNodeName(tagName);
	FState := rsBeforeAttr;

	DoElementStart(tagName);
	Result := True;
end;

function THtmlReader.ReadEndElementNode: Boolean;
var
	tagName: TDomString;
begin
	Result := false;
	Inc(FPosition);
	if IsEOF then
		Exit;
	tagName := LowerCase(GetToken(tagNameDelimiter));
	if tagName = '' then
		Exit;
	Result := SkipTo(WideChar(endTagChar));
	if Result then
	begin
		FNodeType := END_ELEMENT_NODE;
		SetNodeName(tagName);
		DoEndElement(tagName);
		Result := true
	end
end;

function THtmlReader.ReadQuotedValue(var Value: TDomString): Boolean;
var
	quotedChar: WideChar;
	start: Integer;
begin
	quotedChar := FHtmlStr[FPosition]; //the quotation character will usually be " (quotation mark), but can also be ' (apostrophe)
	Inc(FPosition);
	start := FPosition;
	Result := SkipTo(quotedChar);
	if Result then
		Value := Copy(FHtmlStr, start, FPosition - start-1); // -1 ==> don't include the trailing quote in the returned string
end;

function THtmlReader.ReadSpecialNode: Boolean;
begin
	Result := false;
	Inc(FPosition);
	if IsEOF then
		Exit;

	if IsStartDocumentType then
		Result := ReadDocumentType
	else if IsStartCharacterData then
		Result := ReadCharacterData
	else if IsStartComment then
		Result := ReadComment
end;

function THtmlReader.ReadTagNode: Boolean;
var
	currPos: Integer;
begin
	Result := False;
	currPos := FPosition;
	Inc(FPosition);
	if IsEOF then
		Exit;
	if IsSlashChar then
		Result := ReadEndElementNode
	else if IsSpecialTagChar then
		Result := ReadSpecialNode
	else
		Result := ReadElementNode;

	if not Result then
		FPosition := currPos;
end;

function THtmlReader.SkipTo(const Signature: TDomString): Boolean;
begin
	while FPosition <= Length(FHtmlStr) do
	begin
		if Match(Signature, false) then
		begin
			Inc(FPosition, Length(Signature));
			Result := true;
			Exit
		end;
		Inc(FPosition)
	end;
	Result := false
end;

procedure THtmlReader.DoAttributeEnd;
begin
	LogFmt('AttributeEnd', []);
	if Assigned(OnAttributeEnd) then
		OnAttributeEnd(Self);
end;

procedure THtmlReader.DoAttributeStart(const AttributeName: UnicodeString);
begin
	LogFmt('AttributeStart (Name="%s")', [AttributeName]);
	if Assigned(OnAttributeStart) then
		OnAttributeStart(Self);
end;

procedure THtmlReader.DoAttributeValue(const AttributeValue: UnicodeString);
begin
	LogFmt('AttributeValue (Value="%s")', [AttributeValue]);
	if Assigned(OnAttributeValue) then
		OnAttributeValue(Self);
end;

procedure THtmlReader.DoCDataSection(const NodeValue: UnicodeString);
begin
{
	NOTE: HTML does not normally allow CDATA sections.

	https://html.spec.whatwg.org/#cdata-sections

	> CDATA sections can only be used in foreign content (MathML or SVG).
	> In this example, a CDATA section is used to escape the contents of a MathML ms element
	>
	>     <p>You can add a string to a number, but this stringifies the number:</p>
	>     <math>
	>      <ms><![CDATA[x<y]]></ms>
	>      <mo>+</mo>
	>      <mn>3</mn>
	>      <mo>=</mo>
	>      <ms><![CDATA[x<y3]]></ms>
	>     </math>
}

	LogFmt('CDataSection (NodeValue="%s")', [NodeValue]);
	if Assigned(OnCDataSection) then
		OnCDataSection(Self);
end;

procedure THtmlReader.DoComment(const NodeValue: UnicodeString);
begin
	LogFmt('Comment (NodeValue="%s")', [NodeValue]);
	if Assigned(OnComment) then
		OnComment(Self);
end;

procedure THtmlReader.DoDocType(const Name, PublicID, SystemID: UnicodeString);
begin
	LogFmt('DocType (Name="%s", PublicID="%s", SystemID="%s")', [Name, PublicID, SystemID]);

	if Assigned(OnDocType) then
		OnDocType(Self);
end;

procedure THtmlReader.DoElementEnd(IsEmptyElement: Boolean);
begin
{
	When we've reached the end of an element's start tag.

		<DIV lang="en" id="pnlMain">
											^__ IsEmtpyElement: False

		<BR/>
		    ^__ IsEmptyElement: True
}
	LogFmt('ElementEnd (IsEmptyElement=%s)', [SBoolean[IsEmptyElement]]);
	if Assigned(OnElementEnd) then
		OnElementEnd(Self);
end;

procedure THtmlReader.DoElementStart(const TagName: UnicodeString);
begin
{
	Occurs on an element start tag.
}
	LogFmt('ElementStart (Name="%s")', [TagName]);
	if Assigned(OnElementStart) then
		OnElementStart(Self);
end;

procedure THtmlReader.DoEndElement(const TagName: UnicodeString);
begin
{
	Occurs on an element's end tag.
}
	LogFmt('EndElement (Name="%s")', [TagName]);

	if Assigned(OnEndElement) then
		OnEndElement(Self);
end;

procedure THtmlReader.DoTextNode(const NodeValue: UnicodeString);
var
	s: UnicodeString;
begin
//	LogFmt('TextNode(NodeValue="%s")', [NodeValue]);
	LogBack(function: string
		begin
			s := NodeValue;
			s := StringReplace(s, #13#10, #$23CE, [rfReplaceAll]); //U+23CE RETURN SYMBOL
			s := StringReplace(s, #13, #$23CE, [rfReplaceAll]); //U+23CE RETURN SYMBOL
			s := StringReplace(s, #10, #$23CE, [rfReplaceAll]); //U+23CE RETURN SYMBOL
			s := StringReplace(s, ' ', #$2423, [rfReplaceAll]); //U+2423 OPEN BOX

			Result := 'TextNode (NodeValue="'+s+'")';
		end);

	if Assigned(OnTextNode) then
		OnTextNode(Self);
end;

function THtmlReader.read: Boolean;
begin
	Result := False;

	//Reset current state
	FNodeType := NONE;
	FPrefix := '';
	FLocalName := '';
	FNodeValue := '';
	FPublicID := '';
	FSystemID := '';
	FIsEmptyElement := False;

	if IsEOF then
		Exit;

	Result := True;

	if FState in [rsBeforeValue, rsInValue, rsInQuotedValue] then
	begin
		if ReadValueNode then
			Exit;
		if FState = rsInQuotedValue then
			Inc(FPosition);
		FNodeType := ATTRIBUTE_NODE;
		DoAttributeEnd();
		FState := rsBeforeAttr;
	end
	else if FState = rsBeforeAttr then
	begin
		if ReadAttrNode then
			Exit;
		ReadElementTail;
		FState := rsInitial;
	end
	else if IsStartTagChar then
	begin
		if ReadTagNode then
			Exit;
		Inc(FPosition);
	end
	else
		ReadTextNode;
end;

procedure THtmlReader.ReadTextNode;
var
	start: Integer;
	data: TDomString;
begin
	start := FPosition;
	repeat
		Inc(FPosition)
	until IsEOF or IsStartMarkupChar;
	FNodeType := TEXT_NODE;

	data := Copy(FHtmlStr, start, FPosition - start);
	data := HtmlDecode(data); //decode entity references
	FNodeValue:= data;
	DoTextNode(FNodeValue);
end;

function THtmlReader.ReadValueNode: Boolean;
begin
	Result := False;

	if FState = rsBeforeValue then
	begin
		SkipWhiteSpaces;
		if IsEOF then
			Exit;
		if not IsEqualChar then
			Exit;
		Inc(FPosition);
		SkipWhiteSpaces;
		if IsEOF then
			 Exit;
		if IsQuotation then
		begin
			FQuotation := Ord(FHtmlStr[FPosition]);
			Inc(FPosition);
			FState := rsInQuotedValue
		end
		else
			FState := rsInValue
	end;

	if IsEOF then
		Exit;

	Result := ReadAttrTextNode;
end;

procedure THtmlReader.ReadElementTail;
begin
{
	Reading the closing > of an element's opening tag:

		<SPAN>
			  ^

	If the element is self-closing (i.e. "<SPAN/>")
	then IsElementEmpty will be true

	Reader properties:

		- NodeType (ELEMNET_NODE)
		- IsElementEmpty: if the element was self-closed
}
	SkipWhiteSpaces;
	if (FPosition <= Length(FHtmlStr)) and IsSlashChar then
	begin
		FIsEmptyElement := True;
		Inc(FPosition)
	end;
	SkipTo(WideChar(endTagChar));
	FNodeType := ELEMENT_NODE;

	DoElementEnd(IsEmptyElement);
end;

procedure THtmlReader.SetHtmlStr(const Value: TDomString);
begin
	FHtmlStr := Value;
	FPosition := 1
end;

procedure THtmlReader.SetNodeName(Value: TDomString);
var
	I: Integer;
begin
{
	Split Value into Prefix and LocalName

	NodeName is sythesized as Prefix:LocalName

	If Prefix is empty, then NodeName is just LocalName.
}
	I := Pos(':', Value);
	if I > 0 then
	begin
		FPrefix := Copy(Value, 1, I - 1);
		FLocalName := Copy(Value, I + 1, Length(Value) - I)
	end
	else
	begin
		FPrefix := '';
		FLocalName := Value
	end
end;

procedure THtmlReader.SkipWhiteSpaces;
begin
	while (FPosition <= Length(FHtmlStr)) and (Ord(FHtmlStr[FPosition]) in whiteSpace) do
		Inc(FPosition)
end;

end.
