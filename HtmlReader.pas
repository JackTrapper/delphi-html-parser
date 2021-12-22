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
		//rdr.OnNotation := Notation;
		rdr.OnProcessingInstruction := ProcessingInstruction;
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

	THtmlReader = class
	private
		FHtmlStr: TDomString; //the HTML string we are parsing
		FPosition: Integer;   //current index in HtmlStr

		FNodeType: Integer;
		FPrefix: TDomString;
		FLocalName: TDomString;
		FNodeValue: TDomString;
		FPublicID: TDomString;
		FSystemID: TDomString;
		FIsEmptyElement: Boolean;
		FState: TReaderState;
		FQuotation: Word;

		FOnAttributeEnd: TNotifyEvent;
		FOnAttributeStart: TNotifyEvent;
		FOnCDataSection: TNotifyEvent;
		FOnComment: TNotifyEvent;
		FOnDocType: TNotifyEvent;
		FOnElementStart: TNotifyEvent;
		FOnElementEnd: TNotifyEvent;
		FOnEndElement: TNotifyEvent;
		FOnEntityReference: TNotifyEvent;
		//FOnNotation: TNotifyEvent;
		FOnProcessingInstruction: TNotifyEvent;
		FOnTextNode: TNotifyEvent;

		procedure SetHtmlStr(const Value: TDomString);
		procedure SetNodeName(Value: TDomString);
		function GetNodeName: TDomString;
		procedure FireEvent(Event: TNotifyEvent);

		function GetToken(Delimiters: TDelimiters): TDomString;
		function IsAttrTextChar: Boolean;
		function IsDigit(HexBase: Boolean): Boolean;
		function IsEndEntityChar: Boolean;
		function IsEntityChar: Boolean;
		function IsEqualChar: Boolean;
		function IsHexEntityChar: Boolean;
		function IsNumericEntity: Boolean;
		function IsQuotation: Boolean;
		function IsSlashChar: Boolean;
		function IsSpecialTagChar: Boolean;
		function IsStartCharacterData: Boolean;
		function IsStartComment: Boolean;
		function IsStartDocumentType: Boolean;
		function IsStartEntityChar: Boolean;
		function IsStartMarkupChar: Boolean;
		function IsStartTagChar: Boolean;
		function Match(const Signature: TDomString; IgnoreCase: Boolean): Boolean;

		function ReadAttrNode: Boolean; 				//fires OnAttributeStart (NodeName)
		function ReadAttrTextNode: Boolean;			//fires OnTextNode (NodeValue, NodeType)
		function ReadSpecialNode: Boolean;			//calls ReadComment, ReadCharacterData, or ReadDocumentType
		function ReadComment: Boolean;				//fires OnComment (NodeValue, NodeType)
		function ReadCharacterData: Boolean;		//fires OnCDataSection (NodeValue, NodeType)
		function ReadDocumentType: Boolean;			//fires OnDocType (NodeName, PublicID, SystemID)
		procedure ReadTextNode;							//fires OnTextNode (NodeValue, NodeType)
		function ReadElementNode: Boolean;			//fires OnElementStart (NodeName, NodeType)
		function ReadEndElementNode: Boolean;		//fires OnEndElement (NodeName, NodeType)
		procedure ReadElementTail;						//fires OnElementEnd (NodeType)
		function ReadEntityNode: Boolean;
		function ReadNamedEntityNode: Boolean;		//fires OnEntityReference (NodeName, NodeType)
		function ReadNumericEntityNode: Boolean;	//fires OnTextNode (NodeValue, NodeType)

		function ReadQuotedValue(var Value: TDomString): Boolean;
		function ReadTagNode: Boolean;
		function ReadValueNode: Boolean;
		function SkipTo(const Signature: TDomString): Boolean;
		procedure SkipWhiteSpaces;

	public
		constructor Create;

		function Read: Boolean;

		property HtmlStr: TDomString read FHtmlStr write SetHtmlStr;

		property Position: Integer read FPosition;
		property State: TReaderState read FState;

		// Properties of current read state
		property nodeType: Integer read FNodeType;
		property prefix: TDomString read FPrefix;
		property localName: TDomString read FLocalName;
		property nodeName: TDomString read GetNodeName; //synthetic from Prefix and LocalName
		property nodeValue: TDomString read FNodeValue;
		property publicID: TDomString read FPublicID;
		property systemID: TDomString read FSystemID;
		property isEmptyElement: Boolean read FIsEmptyElement;

		//SAX-like events
		property OnAttributeStart: TNotifyEvent read FOnAttributeStart write FOnAttributeStart;
		property OnAttributeEnd: TNotifyEvent read FOnAttributeEnd write FOnAttributeEnd;
		property OnCDataSection: TNotifyEvent read FOnCDataSection write FOnCDataSection;
		property OnComment: TNotifyEvent read FOnComment write FOnComment;
		property OnDocType: TNotifyEvent read FOnDocType write FOnDocType;
		property OnElementStart: TNotifyEvent read FOnElementStart write FOnElementStart;
		property OnElementEnd: TNotifyEvent read FOnElementEnd write FOnElementEnd; //nodeType, isEmptyElement
		property OnEndElement: TNotifyEvent read FOnEndElement write FOnEndElement;
		property OnEntityReference: TNotifyEvent read FOnEntityReference write FOnEntityReference;
		//property OnNotation: TNotifyEvent read FOnNotation write FOnNotation;
		property OnProcessingInstruction: TNotifyEvent read FOnProcessingInstruction write FOnProcessingInstruction;
		property OnTextNode: TNotifyEvent read FOnTextNode write FOnTextNode;
	end;

implementation

uses
	SysUtils;

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

	DocTypeStartStr 	= 'DOCTYPE';
	DocTypeEndStr 		= '>';
	CDataStartStr 		= '[CDATA[';
	CDataEndStr 		= ']]>';
	CommentStartStr 	= '--';
	CommentEndStr 		= '-->';

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
	WC: WideChar;
begin
	WC := FHtmlStr[FPosition];
	if FState = rsInQuotedValue then
		Result := (Ord(WC) <> FQuotation) and (Ord(WC) <> startEntity)
	else
		Result := not (Ord(WC) in notAttrText)
end;

function THtmlReader.IsDigit(HexBase: Boolean): Boolean;
var
	WC: WideChar;
begin
	WC := FHtmlStr[FPosition];
	Result := Ord(WC) in decDigit;
	if not Result and HexBase then
		Result := Ord(WC) in hexDigit
end;

function THtmlReader.IsEndEntityChar: Boolean;
var
	WC: WideChar;
begin
	WC := FHtmlStr[FPosition];
	Result := Ord(WC) = endEntity
end;

function THtmlReader.IsEntityChar: Boolean;
var
	WC: WideChar;
begin
	WC := FHtmlStr[FPosition];
	Result := not (Ord(WC) in notEntity)
end;

function THtmlReader.IsEqualChar: Boolean;
var
	WC: WideChar;
begin
	WC := FHtmlStr[FPosition];
	Result := Ord(WC) = equalChar
end;

function THtmlReader.IsHexEntityChar: Boolean;
var
	WC: WideChar;
begin
	WC := FHtmlStr[FPosition];
	Result := Ord(WC) in hexEntity
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
	WC: WideChar;
begin
	WC := FHtmlStr[FPosition];
	Result := Ord(WC) = startEntity
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
	FireEvent(FOnAttributeStart);
	FState := rsBeforeValue;
	FQuotation := 0;
	Result := true
end;

function THtmlReader.ReadAttrTextNode: Boolean;
var
	start: Integer;
begin
	Result := false;
	start := FPosition;
	while (FPosition <= Length(FHtmlStr)) and IsAttrTextChar do
		Inc(FPosition);
	if FPosition = start then
		Exit;
	FNodeType := TEXT_NODE;
	FNodeValue:= Copy(FHtmlStr, start, FPosition - start);
	FireEvent(FOnTextNode);
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
		FireEvent(FOnCDataSection)
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
		FireEvent(FOnComment)
	end
end;

function THtmlReader.ReadDocumentType: Boolean;
var
	name: TDomString;
	keyword: TDomString;
begin
{
	Recommended list of Doctype declarations
	https://www.w3.org/QA/2002/04/valid-dtd-list.html

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
	SetNodeName(LowerCase(name));
	SkipWhiteSpaces;
	keyword := GetToken(tagNameDelimiter); //"PUBLIC" or "SYSTEM"
	SkipWhiteSpaces;

	if SameText(keyword, 'PUBLIC') then
	begin
		if not ReadQuotedValue({var}FPublicID) then //  "-//x3C//DTD HTML 4.01 Transitional//EN"
			FPublicID := ''; //12/20/2021  Support for '<!doctype html>' where there is no public ID
	end;

	SkipWhiteSpaces;

	//https://html.spec.whatwg.org/#before-doctype-system-identifier-state
	//Both QUOTATION MARK and APOSTROPHE are allowed
	if (FHtmlStr[FPosition] = '"') or (FHtmlStr[FPosition] = '''') then
	begin
		if not ReadQuotedValue(FSystemID) then
			FSystemID := '';
	end;
	Result := SkipTo(DocTypeEndStr);

	FireEvent(FOnDocType);
end;

function THtmlReader.ReadElementNode: Boolean;
var
	tagName: TDomString;
begin
	Result := False;
	if FPosition >= Length(FHtmlStr) then
		Exit;

	tagName := GetToken(tagNameDelimiter);
	if tagName = '' then
		Exit;
	FNodeType := ELEMENT_NODE;
	SetNodeName(tagName);
	FState := rsBeforeAttr;
	FireEvent(FOnElementStart);
	Result := True
end;

function THtmlReader.ReadEndElementNode: Boolean;
var
	TagName: TDomString;
begin
	Result := false;
	Inc(FPosition);
	if FPosition > Length(FHtmlStr) then
		Exit;
	TagName := LowerCase(GetToken(tagNameDelimiter));
	if TagName = '' then
		Exit;
	Result := SkipTo(WideChar(endTagChar));
	if Result then
	begin
		FNodeType := END_ELEMENT_NODE;
		SetNodeName(TagName);
		FireEvent(FOnEndElement);
		Result := true
	end
end;

function THtmlReader.ReadEntityNode: Boolean;
var
	currPos: Integer;
begin
	Result := false;
	currPos := FPosition;
	Inc(FPosition);
	if FPosition > Length(FHtmlStr) then
		Exit;
	if IsNumericEntity then
	begin
		Inc(FPosition);
		Result := ReadNumericEntityNode
	end
	else
		Result := ReadNamedEntityNode;
	if Result then
	begin
		FNodeType := ENTITY_REFERENCE_NODE;
		//FireEvent(FOnEntityReference);  VVV - remove, entity node is added in ReadXXXEntityNode
	end
	else
		FPosition := currPos
end;

function THtmlReader.ReadNamedEntityNode: Boolean;
var
	start: Integer;
begin
	Result := false;
	if FPosition > Length(FHtmlStr) then
		Exit;
	start := FPosition;
	while (FPosition <= Length(FHtmlStr)) and IsEntityChar do
		Inc(FPosition);
	if (FPosition > Length(FHtmlStr)) or not IsEndEntityChar then
		Exit;
	FNodeType := ENTITY_REFERENCE_NODE;
	SetNodeName(Copy(FHtmlStr, start, FPosition - start));
	Inc(FPosition);
	FireEvent(FOnEntityReference);
	Result := true
end;

function THtmlReader.ReadNumericEntityNode: Boolean;
var
	value: Word;
	hexBase: Boolean;
begin
	Result := false;
	if FPosition > Length(FHtmlStr) then
		Exit;
	hexBase := IsHexEntityChar;
	if hexBase then
		Inc(FPosition);
	value := 0;
	while (FPosition <= Length(FHtmlStr)) and IsDigit(hexBase) do
	begin
		try
			if hexBase then
				value := value * 16 + HexValue(FHtmlStr[FPosition])
			else
				value := value * 10 + DecValue(FHtmlStr[FPosition])
		except
			Exit
		end;
		Inc(FPosition)
	end;
	if (FPosition > Length(FHtmlStr)) or not IsEndEntityChar then
		Exit;
	Inc(FPosition);
	FNodeType := TEXT_NODE;
	FNodeValue := WideChar(value);
	FireEvent(FOnTextNode);
	Result := true
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
	if FPosition > Length(FHtmlStr) then
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
	if FPosition > Length(FHtmlStr) then
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

procedure THtmlReader.FireEvent(Event: TNotifyEvent);
begin
	if Assigned(Event) then
		Event(Self)
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

	if FPosition > Length(FHtmlStr) then
		Exit;

	Result := True;

	if FState in [rsBeforeValue, rsInValue, rsInQuotedValue] then
	begin
		if ReadValueNode then
			Exit;
		if FState = rsInQuotedValue then
			Inc(FPosition);
		FNodeType := ATTRIBUTE_NODE;
		FireEvent(FOnAttributeEnd);
		FState := rsBeforeAttr
	end
	else
	if FState = rsBeforeAttr then
	begin
		if ReadAttrNode then
			Exit;
		ReadElementTail;
		FState := rsInitial;
	end
	else
	if IsStartTagChar then
	begin
		if ReadTagNode then
			Exit;
		Inc(FPosition);
		FNodeType := ENTITY_REFERENCE_NODE;
		SetNodeName('lt');
		FireEvent(FOnEntityReference);
	end
	else
	if IsStartEntityChar then
	begin
		if ReadEntityNode then
			Exit;
		Inc(FPosition);
		FNodeType := ENTITY_REFERENCE_NODE;
		SetNodeName('amp');
		FireEvent(FOnEntityReference)
	end
	else
		ReadTextNode
end;

procedure THtmlReader.ReadTextNode;
var
	start: Integer;
begin
	start := FPosition;
	repeat
		Inc(FPosition)
	until (FPosition > Length(FHtmlStr)) or IsStartMarkupChar;
	FNodeType := TEXT_NODE;
	FNodeValue:= Copy(FHtmlStr, start, FPosition - start);
	FireEvent(FOnTextNode)
end;

function THtmlReader.ReadValueNode: Boolean;
begin
	Result := false;
	if FState = rsBeforeValue then
	begin
		SkipWhiteSpaces;
		if FPosition > Length(FHtmlStr) then
			Exit;
		if not IsEqualChar then
			Exit;
		Inc(FPosition);
		SkipWhiteSpaces;
		if FPosition > Length(FHtmlStr) then
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
	if FPosition > Length(FHtmlStr) then
		Exit;
	if IsStartEntityChar then
	begin
		Result := true;
		if ReadEntityNode then
			Exit;
		Inc(FPosition);
		FNodeType := ENTITY_REFERENCE_NODE;
		SetNodeName('amp');
		FireEvent(FOnEntityReference)
	end
	else
		Result := ReadAttrTextNode
end;

procedure THtmlReader.ReadElementTail;
begin
{
	Reading the closing > of an element's opening tag:

		<SPAN>
			  ^
			  ^
}
	SkipWhiteSpaces;
	if (FPosition <= Length(FHtmlStr)) and IsSlashChar then
	begin
		FIsEmptyElement := true;
		Inc(FPosition)
	end;
	SkipTo(WideChar(endTagChar));
	FNodeType := ELEMENT_NODE;
	FireEvent(FOnElementEnd)
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
