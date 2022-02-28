unit HtmlParser;

interface

uses
	ActiveX, Classes, SysUtils, Contnrs,
	DomCore, Entities;

const
	CP_UTF16 = 1200;

type
	TTokenizerState = (
			tsDataState, 							// DoDataState; //13.2.5.1 Data state
			tsRCDataState, 						// DoRCDataState;	//13.2.5.2 RCDATA state
			tsRawTextState, 						// DoRawTextState;	 //13.2.5.3 RAWTEXT state
			tsScriptDataState, 					// DoScriptDataState; //13.2.5.4 Script data state
			tsPlaintextState, 					// DoPlaintextState; //13.2.5.5 PLAINTEXT state
			tsTagOpenState, 						// DoTagOpenState; //13.2.5.6 Tag open state
			tsEndTagOpenState, 					// DoEndTagOpenState; //13.2.5.7 End tag open state
			tsTagNameState, 						// DoTagNameState; //13.2.5.8 Tag name state
			tsRCDATALessThanSignState, 		// DoRCDATALessThanSignState; //13.2.5.9 RCDATA less-than sign state
			tsRCDATAEndTagOpenState, 			// DoRCDATAEndTagOpenState; //13.2.5.10 RCDATA end tag open state
			tsRCDATAEndTagNameState, 			// DoRCDATAEndTagNameState; //13.2.5.11 RCDATA end tag name state
			tsRAWTEXTLessThanSignState, 		// DoRAWTEXTLessThanSignState; //13.2.5.12 RAWTEXT less-than sign state
			tsRAWTEXTEndTagOpenState, 			// DoRAWTEXTEndTagOpenState; //13.2.5.13 RAWTEXT end tag open state
			tsRAWTEXTEndTagNameState, 			// DoRAWTEXTEndTagNameState; //13.2.5.14 RAWTEXT end tag name state
			tsScriptDataLessThanSignState, 	// DoScriptDataLessThanSignState; //13.2.5.15 Script data less-than sign state
			tsScriptDataEndTagOpenState, 		// DoScriptDataEndTagOpenState; //13.2.5.16 Script data end tag open state
			tsScriptDataEndTagNameState, 		// DoScriptDataEndTagNameState; //13.2.5.17 Script data end tag name state
			tsScriptDataEscapeStartState, 	// DoScriptDataEscapeStartState; //13.2.5.18 Script data escape start state
			tsScriptDataEscapeStartDashState,		// DoScriptDataEscapeStartDashState; //13.2.5.19 Script data escape start dash state
			tsScriptDataEscapedState, 					// DoScriptDataEscapedState; //13.2.5.20 Script data escaped state
			tsScriptDataEscapedDashState, 			// DoScriptDataEscapedDashState; //13.2.5.21 Script data escaped dash state
			tsScriptDataEscapedDashDashState, 		// DoScriptDataEscapedDashDashState; //13.2.5.22 Script data escaped dash dash state
			tsScriptDataEscapedLessThanSignState,	// DoScriptDataEscapedLessThanSignState; //13.2.5.23 Script data escaped less-than sign state
			tsScriptDataEscapedEndTagOpenState, 	// DoScriptDataEscapedEndTagOpenState; //13.2.5.24 Script data escaped end tag open state
			tsScriptDataEscapedEndTagNameState, 	// DoScriptDataEscapedEndTagNameState; //13.2.5.25 Script data escaped end tag name state
			tsScriptDataDoubleEscapeStartState, 	// DoScriptDataDoubleEscapeStartState; //13.2.5.26 Script data double escape start state
			tsScriptDataDoubleEscapedState, 			// DoScriptDataDoubleEscapedState; //13.2.5.27 Script data double escaped state
			tsScriptDataDoubleEscapedDashState, 	// DoScriptDataDoubleEscapedDashState; //13.2.5.28 Script data double escaped dash state
			tsScriptDataDoubleEscapedDashDashState, 			// DoScriptDataDoubleEscapedDashDashState; //13.2.5.29 Script data double escaped dash dash state
			tsScriptDataDoubleEscapedLessThanSignState, 		// DoScriptDataDoubleEscapedLessThanSignState; //13.2.5.30 Script data double escaped less-than sign state
			tsScriptDataDoubleEscapeEndState, 		// DoScriptDataDoubleEscapeEndState; //13.2.5.31 Script data double escape end state
			tsBeforeAttributeNameState, 				// DoBeforeAttributeNameState; //13.2.5.32 Before attribute name state
			tsAttributeNameState, 						// DoAttributeNameState; //13.2.5.33 Attribute name state
			tsAfterAttributeNameState, 				// DoAfterAttributeNameState; //13.2.5.34 After attribute name state
			tsBeforeAttributeValueState, 				// DoBeforeAttributeValueState; //13.2.5.35 Before attribute value state
			tsAttributeValueDoubleQuotedState, 		// DoAttributeValueDoubleQuotedState; //13.2.5.36 Attribute value (double-quoted) state
			tsAttributeValueSingleQuotedState, 		// DoAttributeValueSingleQuotedState; //13.2.5.37 Attribute value (single-quoted) state
			tsAttributeValueUnquotedState, 			// DoAttributeValueUnquotedState; //13.2.5.38 Attribute value (unquoted) state
			tsAfterAttributeValueQuotedState, 		// DoAfterAttributeValueQuotedState; //13.2.5.39 After attribute value (quoted) state
			tsSelfClosingStartTagState, 				// DoSelfClosingStartTagState; //13.2.5.40 Self-closing start tag state
			tsBogusCommentState, 						// DoBogusCommentState; //13.2.5.41 Bogus comment state
			tsMarkupDeclarationOpenState, 			// DoMarkupDeclarationOpenState; //13.2.5.42 Markup declaration open state
			tsCommentStartState, 						// DoCommentStartState; //13.2.5.43 Comment start state
			tsCommentStartDashState, 					// DoCommentStartDashState; //13.2.5.44 Comment start dash state
			tsCommentState, 								// DoCommentState; //13.2.5.45 Comment state
			tsCommentLessThanSignState, 				// DoCommentLessThanSignState; //13.2.5.46 Comment less-than sign state
			tsCommentLessThanSignBangState, 			// DoCommentLessThanSignBangState; //13.2.5.47 Comment less-than sign bang state
			tsCommentLessThanSignBangDashState, 	// DoCommentLessThanSignBangDashState; //13.2.5.48 Comment less-than sign bang dash state
			tsCommentLessThanSignBangDashDashState, 			// DoCommentLessThanSignBangDashDashState; //13.2.5.49 Comment less-than sign bang dash dash state
			tsCommentEndDashState, 						// DoCommentEndDashState; //13.2.5.50 Comment end dash state
			tsCommentEndState, 							// DoCommentEndState; //13.2.5.51 Comment end state
			tsCommentEndBangState, 						// DoCommentEndBangState; //13.2.5.52 Comment end bang state
			tsDOCTYPEState, 								// DoDOCTYPEState; //13.2.5.53 DOCTYPE state
			tsBeforeDOCTYPENameState, 					// DoBeforeDOCTYPENameState; //13.2.5.54 Before DOCTYPE name state
			tsDOCTYPENameState, 							// DoDOCTYPENameState; //13.2.5.55 DOCTYPE name state
			tsAfterDOCTYPENameState, 					// DoAfterDOCTYPENameState; //13.2.5.56 After DOCTYPE name state
			tsAfterDOCTYPEPublicKeywordState, 		// DoAfterDOCTYPEPublicKeywordState; //13.2.5.57 After DOCTYPE public keyword state
			tsBeforeDOCTYPEPublicIdentifierState, 	// DoBeforeDOCTYPEPublicIdentifierState; //13.2.5.58 Before DOCTYPE public identifier state
			tsDOCTYPEPublicIdentifierDoubleQuotedState, 			// DoDOCTYPEPublicIdentifierDoubleQuotedState; //13.2.5.59 DOCTYPE public identifier (double-quoted) state
			tsDOCTYPEPublicIdentifierSingleQuotedState, 			// DoDOCTYPEPublicIdentifierSingleQuotedState; //13.2.5.60 DOCTYPE public identifier (single-quoted) state
			tsAfterDOCTYPEPublicIdentifierState, 					// DoAfterDOCTYPEPublicIdentifierState; //13.2.5.61 After DOCTYPE public identifier state
			tsBetweenDOCTYPEPublicAndSystemIdentifiersState,	// DoBetweenDOCTYPEPublicAndSystemIdentifiersState; //13.2.5.62 Between DOCTYPE public and system identifiers state
			tsAfterDOCTYPESystemKeywordState, 						// DoAfterDOCTYPESystemKeywordState; //13.2.5.63 After DOCTYPE system keyword state
			tsBeforeDOCTYPESystemIdentifierState, 					// DoBeforeDOCTYPESystemIdentifierState; //13.2.5.64 Before DOCTYPE system identifier state
			tsDOCTYPESystemIdentifierDoubleQuotedState, 			// DoDOCTYPESystemIdentifierDoubleQuotedState; //13.2.5.65 DOCTYPE system identifier (double-quoted) state
			tsDOCTYPESystemIdentifierSingleQuotedState, 			// DoDOCTYPESystemIdentifierSingleQuotedState; //13.2.5.66 DOCTYPE system identifier (single-quoted) state
			tsAfterDOCTYPESystemIdentifierState, 	// DoAfterDOCTYPESystemIdentifierState; //13.2.5.67 After DOCTYPE system identifier state
			tsBogusDOCTYPEState, 						// DoBogusDOCTYPEState; //13.2.5.68 Bogus DOCTYPE state
			tsCDATASectionState, 						// DoCDATASectionState; //13.2.5.69 CDATA section state
			tsCDATASectionBracketState, 				// DoCDATASectionBracketState; //13.2.5.70 CDATA section bracket state
			tsCDATASectionEndState, 					// DoCDATASectionEndState; //13.2.5.71 CDATA section end state
			tsCharacterReferenceState, 				// DoCharacterReferenceState; //13.2.5.72 Character reference state
			tsNamedCharacterReferenceState, 			// DoNamedCharacterReferenceState; //13.2.5.73 Named character reference state
			tsAmbiguousAmpersandState, 				// DoAmbiguousAmpersandState; //13.2.5.74 Ambiguous ampersand state
			tsNumericCharacterReferenceState, 				// DoNumericCharacterReferenceState; //13.2.5.75 Numeric character reference state
			tsHexadecimalCharacterReferenceStartState, 	// DoHexadecimalCharacterReferenceStartState; //13.2.5.76 Hexadecimal character reference start state
			tsDecimalCharacterReferenceStartState, 		// DoDecimalCharacterReferenceStartState; //13.2.5.77 Decimal character reference start state
			tsHexadecimalCharacterReferenceState, 			// DoHexadecimalCharacterReferenceState; //13.2.5.78 Hexadecimal character reference state
			tsDecimalCharacterReferenceState, 				// DoDecimalCharacterReferenceState; //13.2.5.79 Decimal character reference state
			tsNumericCharacterReferenceEndState 			// DoNumericCharacterReferenceEndState; //13.2.5.80 Numeric character reference end state
	);

	TInsertionMode = (
			imInitial, 				//"initial"
			imBeforeHtml, 			//"before html"
			imBeforeHead, 			//"before head"
			imInHead, 				//"in head"
			imInHeadNoscript,		//"in head no script"
			imAfterHead,			//"after head",
			imInBody,				//"in body",
			imText,					//"text",
			imInTable,				//"in table",
			imInTableText,			//"in table text",
			imInCaption,			//"in caption",
			imInColumnGroup,		//"in column group",
			imInTableBody,			//"in table body",
			imInRow,					//"in row",
			imInCell,				//"in cell",
			imInSelect,				//"in select",
			imInSelectInTable,	//"in select in table",
			imInTemplate,			//"in template",
			imAfterBody,			//"after body",
			imInFrameset,			//"in frameset",
			imAfterFrameset,		//"after frameset",
			imAfterAfterBody,		//"after after body",
			imAfterAfterFrameset	//"after after frameset"
	);

	//The output of the tokenization step is a series of zero or more of the following tokens:
	THtmlTokenType = (
			ttDocType,		//DOCTYPE
			ttStartTag,		//start tag
			ttEndTag,		//end tag
			ttComment,		//comment
			ttCharacter,	//character
			ttEndOfFile		//end-of-file
	);

{
	The InputStream supplies a series of Unicode characters to the tokenizer.
	The InputStream also takes care of converting any CRLF into LF (as CR is never allowed to reach the HTML tokenizer)

}
	TInputStream = class
	private
		FStream: ISequentialStream;
		FEncoding: Word;
		FEOF: Boolean;

		FBuffer: UCS4String;
		FBufferPosition: Integer; //the index into FBuffer that is the "current" position
		FBufferSize: Integer; //the number of characters in the ring buffer (from FBufferPosition) that are valid
		function IsSurrogate(const n: Word): Boolean;
		function GetNextCharacterFromStream: UCS4Char;
		function GetNextUTF16Character: UCS4Char;

		function Consume: UCS4Char;
		function FetchNextCharacterInfoBuffer: Boolean;
		procedure LogFmt(const s: string; const Args: array of const);
	public
		constructor Create(const Html: UnicodeString); overload;
		constructor Create(ByteStream: ISequentialStream; Encoding: Word=CP_UTF16); overload;

		function TryRead(out ch: UCS4Char): Boolean; //Returns the next UCS4 character value.
		function Peek(k: Integer): UCS4Char; //peek the k-th upcoming character

		property EOF: Boolean read FEOF;
	end;

{
	Initially, the stack of open elements is empty.
	The stack grows downwards; the topmost node on the stack is the first one added to the stack,
	and the bottommost node of the stack is the most recently added node in the stack
	(notwithstanding when the stack is manipulated in a random access fashion as part of the handling for misnested tags).
}
	TElementStack = class(TList)
	private
		function GetItems(Index: Integer): TElement;
	public
		constructor Create;
		function TopMost: TElement;
		function BottomMost: TElement;
		property Items[Index: Integer]: TElement read GetItems;
	end;

{
	The base class for the tokens emitted by the tokenizer
		THtmlToken
			- TDocTypeToken
			- TTagToken
			- TStartTagToken
			- TEndTagToken
			- TCommentToken
			- TCharacterToken
			- TEndOfFileToken
}
	THtmlToken = class
	public
		TokenType: THtmlTokenType;
		constructor Create(ATokenType: THtmlTokenType);
	end;

	TDocTypeToken = class(THtmlToken)
	private
		FName: UnicodeString;
		FPublicIdentifier: UnicodeString;
		FSystemIdentifier: UnicodeString;
		FForceQuirks: Boolean;

		FNameMissing: Boolean;
		FPublicIdentifierMissing: Boolean;
		FSystemIdentifierMissing: Boolean;

		procedure SetPublicIdentifier(const Value: UnicodeString);
		procedure SetSystemIdentifier(const Value: UnicodeString);
		procedure SetName(const Value: UnicodeString);
	protected
		procedure AppendName(const ch: UCS4Char); //to the Name
		procedure AppendPublicIdentifier(const ch: UCS4Char);
		procedure AppendSystemIdentifier(const ch: UCS4Char);
	public

		constructor Create;

		property Name: UnicodeString read FName write SetName; 
		property PublicIdentifier: UnicodeString read FPublicIdentifier write SetPublicIdentifier;
		property SystemIdentifier: UnicodeString read FSystemIdentifier write SetSystemIdentifier;

		property NameMissing: Boolean read FNameMissing;
		property PublicIdentifierMissing: Boolean read FPublicIdentifierMissing;
		property SystemIdentifierMissing: Boolean read FSystemIdentifierMissing;
		property ForceQuirks: Boolean read FForceQuirks write FForceQuirks;
	end;

	//Base class of StartTagToken and EndTagToken
	TTagToken = class(THtmlToken)
	private
		FData: UCS4String;
		FAttributes: TList;
		FSelfClosing: Boolean;
		function GetTagName: UnicodeString;
	protected
		CurrentAttributeName: UnicodeString;
		CurrentAttributeValue: UnicodeString;

		procedure NewAttribute;
		procedure FinalizeAttributeName;
	public
		constructor Create(ATokenType: THtmlTokenType);
		destructor Destroy; override;
		procedure AppendCharacter(const ch: UCS4Char); //append to TagName

		property TagName: UnicodeString read GetTagName;
		property Attributes: TList read FAttributes;
		property SelfClosing: Boolean read FSelfClosing write FSelfClosing;
	end;

	TStartTagToken = class(TTagToken)
	public
		constructor Create;
	end;

	TEndTagToken = class(TTagToken)
	public
		constructor Create;
	end;

	TCommentToken = class(THtmlToken)
	private
		FData: UCS4String;
		function GetDataString: UnicodeString;
	public
		constructor Create;
		procedure AppendCharacter(const ch: UCS4Char); //to Data

		property DataString: UnicodeString read GetDataString;
	end;

	TCharacterToken = class(THtmlToken)
	private
		function GetDataString: UnicodeString;
	public
		Data: UCS4Char;
		constructor Create;
		property DataString: UnicodeString read GetDataString;
	end;

	TEndOfFileToken = class(THtmlToken)
	public
		Data: UCS4String;
		constructor Create;
	end;

	TTokenEvent = procedure(Sender: TObject; AToken: THtmlToken) of object;

	THtmlTokenizer = class
	private
		FStream: TInputStream;
		FState2: TTokenizerState;
		FReturnState2: TTokenizerState;
		FCurrentInputCharacter: UCS4Char;
		FCurrentToken: THtmlToken;
		FCharacterReferenceCode: Cardinal;
		FReconsume: Boolean;

		FEOF: Boolean;
		FTemporaryBuffer: UCS4String;
		FNameOfLastEmittedStartTag: string;

		FParserPause: Boolean;


		FOnToken: TTokenEvent; //event handler
		procedure AddNotImplementedParseError(const StateHandlerName: string);

		function GetNext: UCS4Char;
		procedure Initialize;

		procedure AddParseError(ParseErrorName: string);

		//The output of the tokenization step is a series of zero or more of the following tokens:
		//	DOCTYPE, start tag, end tag, comment, character, end-of-file.
		//	DOCTYPE tokens have a name, a public identifier, a system identifier, and a force-quirks flag.
		procedure EmitToken(const AToken: THtmlToken);
			procedure EmitCurrentDocTypeToken;	//Emit the current DOCTYPE token
			procedure EmitStartTag;					//Emit the current StartTag token
			procedure EmitEndTag;					//Emit the current EndTag token
			procedure EmitCurrentTagToken;		//Emits the current token (whether it be a StartTag or EndTag)
			procedure EmitCurrentCommentToken;	//Emit the current Comment token
			procedure EmitCharacter(const Character: UCS4Char); //Emit a Character token
			procedure EmitEndOfFileToken;			//Emit an EndOfFile token

		procedure Reconsume(NewTokenizerState: TTokenizerState);

		procedure SetState(const State: TTokenizerState);
		procedure SetReturnState(const State: TTokenizerState);
		function Consume: UCS4Char;

		function NextFewCharacters(const Value: UnicodeString; const CaseSensitive: Boolean; const IncludingCurrentInputCharacter: Boolean): Boolean;
		function GetCurrentTagToken: TTagToken;
		function TemporaryBufferIs(const Value: UnicodeString): Boolean;

		procedure AppendToTemporaryBuffer(const Value: UCS4Char);
		procedure AppendToCurrentAttributeName(const Value: UCS4Char); 
		procedure AppendToCurrentAttributeValue(const Value: UCS4Char); 
		procedure AppendToCurrentCommentData(const Value: UCS4Char);

		procedure FlushCodePointsConsumed;

		function IsAppropriateEndTag(const EndTagToken: TEndTagToken): Boolean;
		function IsConsumedAsPartOfAnAttribute: Boolean;


		procedure LogFmt(const Fmt: string; const Args: array of const);

		property CurrentInputCharacter: UCS4Char read FCurrentInputCharacter; //The current input character is the last character to have been consumed.
		property CurrentTagToken: TTagToken read GetCurrentTagToken; //The current tag token (either TStartTagtoken or TEndTagToken)
	private
		//Tokenizer state machine handlers
		procedure DoDataState; 			//13.2.5.1 Data state
		procedure DoRCDATAState;		//13.2.5.2 RCDATA state
		procedure DoRawTextState;		//13.2.5.3 RAWTEXT state
		procedure DoScriptDataState;	//13.2.5.4 Script data state
		procedure DoPlaintextState;	//13.2.5.5 PLAINTEXT state
		procedure DoTagOpenState;		//13.2.5.6 Tag open state
		procedure DoEndTagOpenState;	//13.2.5.7 End tag open state
		procedure DoTagNameState;		//13.2.5.8 Tag name state
		procedure DoRCDATALessThanSignState;			//13.2.5.9 RCDATA less-than sign state
		procedure DoRCDATAEndTagOpenState;				//13.2.5.10 RCDATA end tag open state
		procedure DoRCDATAEndTagNameState;				//13.2.5.11 RCDATA end tag name state
		procedure DoRAWTEXTLessThanSignState;			//13.2.5.12 RAWTEXT less-than sign state
		procedure DoRAWTEXTEndTagOpenState;				//13.2.5.13 RAWTEXT end tag open state
		procedure DoRAWTEXTEndTagNameState;				//13.2.5.14 RAWTEXT end tag name state
		procedure DoScriptDataLessThanSignState;		//13.2.5.15 Script data less-than sign state
		procedure DoScriptDataEndTagOpenState;			//13.2.5.16 Script data end tag open state
		procedure DoScriptDataEndTagNameState;			//13.2.5.17 Script data end tag name state
		procedure DoScriptDataEscapeStartState;		//13.2.5.18 Script data escape start state
		procedure DoScriptDataEscapeStartDashState;	//13.2.5.19 Script data escape start dash state
		procedure DoScriptDataEscapedState;				//13.2.5.20 Script data escaped state
		procedure DoScriptDataEscapedDashState;		//13.2.5.21 Script data escaped dash state
		procedure DoScriptDataEscapedDashDashState;	//13.2.5.22 Script data escaped dash dash state
		procedure DoScriptDataEscapedLessThanSignState;			//13.2.5.23 Script data escaped less-than sign state
		procedure DoScriptDataEscapedEndTagOpenState;			//13.2.5.24 Script data escaped end tag open state
		procedure DoScriptDataEscapedEndTagNameState;			//13.2.5.25 Script data escaped end tag name state
		procedure DoScriptDataDoubleEscapeStartState;			//13.2.5.26 Script data double escape start state
		procedure DoScriptDataDoubleEscapedState;					//13.2.5.27 Script data double escaped state
		procedure DoScriptDataDoubleEscapedDashState;			//13.2.5.28 Script data double escaped dash state
		procedure DoScriptDataDoubleEscapedDashDashState;		//13.2.5.29 Script data double escaped dash dash state
		procedure DoScriptDataDoubleEscapedLessThanSignState;	//13.2.5.30 Script data double escaped less-than sign state
		procedure DoScriptDataDoubleEscapeEndState;	//13.2.5.31 Script data double escape end state
		procedure DoBeforeAttributeNameState;			//13.2.5.32 Before attribute name state
		procedure DoAttributeNameState;					//13.2.5.33 Attribute name state
		procedure DoAfterAttributeNameState;			//13.2.5.34 After attribute name state
		procedure DoBeforeAttributeValueState;			//13.2.5.35 Before attribute value state
		procedure DoAttributeValueDoubleQuotedState;	//13.2.5.36 Attribute value (double-quoted) state

		procedure DoAttributeValueSingleQuotedState; //13.2.5.37 Attribute value (single-quoted) state
		procedure DoAttributeValueUnquotedState; //13.2.5.38 Attribute value (unquoted) state
		procedure DoAfterAttributeValueQuotedState; //13.2.5.39 After attribute value (quoted) state
		procedure DoSelfClosingStartTagState; //13.2.5.40 Self-closing start tag state
		procedure DoBogusCommentState; //13.2.5.41 Bogus comment state
		procedure DoMarkupDeclarationOpenState;
		procedure DoCommentStartState; //13.2.5.43 Comment start state
		procedure DoCommentStartDashState; //13.2.5.44 Comment start dash state
		procedure DoCommentState; //13.2.5.45 Comment state
		procedure DoCommentLessThanSignState; //13.2.5.46 Comment less-than sign state
		procedure DoCommentLessThanSignBangState; //13.2.5.47 Comment less-than sign bang state
		procedure DoCommentLessThanSignBangDashState; //13.2.5.48 Comment less-than sign bang dash state
		procedure DoCommentLessThanSignBangDashDashState; //13.2.5.49 Comment less-than sign bang dash dash state
		procedure DoCommentEndDashState; //13.2.5.50 Comment end dash state
		procedure DoCommentEndState; //13.2.5.51 Comment end state
		procedure DoCommentEndBangState; //13.2.5.52 Comment end bang state
		procedure DoDOCTYPEState; //13.2.5.53 DOCTYPE state
		procedure DoBeforeDOCTYPENameState; //13.2.5.54 Before DOCTYPE name state
		procedure DoDOCTYPENameState; //13.2.5.55 DOCTYPE name state
		procedure DoAfterDOCTYPENameState; //13.2.5.56 After DOCTYPE name state
		procedure DoAfterDOCTYPEPublicKeywordState; //13.2.5.57 After DOCTYPE public keyword state
		procedure DoBeforeDOCTYPEPublicIdentifierState; //13.2.5.58 Before DOCTYPE public identifier state
		procedure DoDOCTYPEPublicIdentifierDoubleQuotedState; //13.2.5.59 DOCTYPE public identifier (double-quoted) state
		procedure DoDOCTYPEPublicIdentifierSingleQuotedState; //13.2.5.60 DOCTYPE public identifier (single-quoted) state
		procedure DoAfterDOCTYPEPublicIdentifierState; //13.2.5.61 After DOCTYPE public identifier state
		procedure DoBetweenDOCTYPEPublicAndSystemIdentifiersState; //13.2.5.62 Between DOCTYPE public and system identifiers state
		procedure DoAfterDOCTYPESystemKeywordState; //13.2.5.63 After DOCTYPE system keyword state
		procedure DoBeforeDOCTYPESystemIdentifierState; //13.2.5.64 Before DOCTYPE system identifier state
		procedure DoDOCTYPESystemIdentifierDoubleQuotedState; //13.2.5.65 DOCTYPE system identifier (double-quoted) state
		procedure DoDOCTYPESystemIdentifierSingleQuotedState; //13.2.5.66 DOCTYPE system identifier (single-quoted) state
		procedure DoAfterDOCTYPESystemIdentifierState; //13.2.5.67 After DOCTYPE system identifier state
		procedure DoBogusDOCTYPEState; //13.2.5.68 Bogus DOCTYPE state
		procedure DoCDATASectionState; //13.2.5.69 CDATA section state
		procedure DoCDATASectionBracketState; //13.2.5.70 CDATA section bracket state
		procedure DoCDATASectionEndState; //13.2.5.71 CDATA section end state
		procedure DoCharacterReferenceState; //13.2.5.72 Character reference state
		procedure DoNamedCharacterReferenceState; //13.2.5.73 Named character reference state
		procedure DoAmbiguousAmpersandState; //13.2.5.74 Ambiguous ampersand state
		procedure DoNumericCharacterReferenceState; //13.2.5.75 Numeric character reference state
		procedure DoHexadecimalCharacterReferenceStartState; //13.2.5.76 Hexadecimal character reference start state
		procedure DoDecimalCharacterReferenceStartState; //13.2.5.77 Decimal character reference start state
		procedure DoHexadecimalCharacterReferenceState; //13.2.5.78 Hexadecimal character reference state
		procedure DoDecimalCharacterReferenceState; //13.2.5.79 Decimal character reference state
		procedure DoNumericCharacterReferenceEndState;	//13.2.5.80 Numeric character reference end state
	public
		constructor Create(Html: UnicodeString);

		procedure Parse;

		property ParserPause: Boolean read FParserPause write FParserPause;
		
		property OnToken: TTokenEvent read FOnToken write FOnToken;
	end;

	THtmlParser = class
	private
		FHtmlDocument: TDocument;
		FTokenizer: THtmlTokenizer;
		procedure Log(const s: string);
	private
		FOpenElements: TElementStack; //stack of open elements. FOpenElements[0] is the oldest, FOpenElements[Count] is the newest
		FActiveFormattingElements: TElementStack;

		FInsertionMode: TInsertionMode;
		FOriginalInsertionMode: TInsertionMode;
		FHead: TElement; //Once a head element has been parsed (whether implicitly or explicitly) the head element pointer gets set to point to this node.
		FForm: TElement; //The form element pointer points to the last form element that was opened and whose end tag has not yet been seen.
		FScripting: Boolean;
		FFramesetOK: Boolean;

		procedure ResetTheInsertionModeAppropriately;
		procedure SetInsertionMode(const Mode: TInsertionMode); // used to handle mis-nested formatting element tags.
	protected
		function ParseString(const htmlStr: TDomString): TDocument;

		procedure ProcessToken(Sender: TObject; AToken: THtmlToken);
			procedure ProcessDocTypeToken(AToken: TDocTypeToken);		//DOCTYPE
			procedure ProcessStartTagToken(AToken: TStartTagToken);	//start tag
			procedure ProcessEndTagToken(AToken: TEndTagToken);		//end tag
			procedure ProcessCommentToken(AToken: TCommentToken);		//comment
			procedure ProcessCharacterToken(AToken: TCharacterToken);	//character
			procedure ProcessEndOfFileToken(AToken: TEndOfFileToken);	//end-of-file

		property HtmlDocument: TDocument read FHtmlDocument;
	public
		constructor Create;

		class function Parse(const HtmlStr: TDomString): TDocument;

		property Scripting: Boolean read FScripting;
		property FramesetOK: Boolean read FFramesetOK;
	end;

{
	Delphi 5 had the issue with .Stat implementation:

		Potential issue in TStreamAdapter.Stat implementation
		http://qc.embarcadero.com/wc/qcmain.aspx?d=45528

		Alpha Blended Splash Screen in Delphi - Part 2
		http://melander.dk/articles/alphasplash2/2/

		The problem with TStreamAdapter is in its implementation of the IStream.stat
		method. The stat method takes two parameters: A STATSTG out parameter and a
		STATFLAG value. The STATFLAG value specifies if the stat method should return
		a value in the STATSTG.pwcsName member. If it does return a value, it is the
		responsibility of the called object (i.e. TStreamAdapter) to allocate memory
		for the string value, and the responsibility of the caller (i.e. GDI+) to
		deallocate the string. Now TStreamAdapter.stat completely ignores the STATFLAG
		parameter, which is understandable because it doesn’t know anything about
		filenames, but unfortunately it also fails to zero the STATSTG.pwcsName member.
		The result is that the caller (GDI+ in this case) receives an invalid string

	That was fixed by the time XE6 came along, but there's another bug (10.3)

	The .Read method is supposed to return S_FALSE if the number of bytes read
	was less than the number of bytes requested.
}
	TFixedStreamAdapter = class(TStreamAdapter)
	public
		function Read(pv: Pointer; cb: FixedUInt; pcbRead: PFixedUInt): HResult; override; stdcall;
	end;

	//Again, the version is Dephi is buggy. So we fix their bugs for them.
	function UCS4ToUnicodeString(const S: UCS4String): UnicodeString;

	procedure UCS4StrCat(var Dest: UCS4String; const Source: UCS4Char);				//similar to System._UStrCat
	procedure UCS4StrFromChar(var Dest: UCS4String; const Source: UCS4Char);		//similar to System._UStrFromChar
	procedure UCS4StrFromUStr(var Dest: UCS4String; const Source: UnicodeString);
	function UCS4StrCopy(const S: UCS4String; Index, Count: Integer): UCS4String; //similar to System._UStrCopy
	procedure UCS4StrFromPUCS4CharLen(var Dest: UCS4String; Source: PUCS4Char; CharLength: Integer); //similar to System._UStrFromPWCharLen
	function UCS4CharToUnicodeString(const ch: UCS4Char): UnicodeString; //either 1 or 2 WideChar
	

implementation

uses
	Windows, TypInfo, ComObj,
	HtmlParserTests,
	HtmlTags;

const
	//https://infra.spec.whatwg.org/#code-points
	asciiTabOrNewline		= [$0009, $000A, $000D]; 	//TAB, LF, CR. https://infra.spec.whatwg.org/#ascii-tab-or-newline
   asciiWhitespace      = [$0009, $000A, $000C, $000D, $0020]; //TAB, LF, FF, CR, SPACE. //https://infra.spec.whatwg.org/#ascii-whitespace
	asciiDigit				= [Ord('0')..Ord('9')]; //https://infra.spec.whatwg.org/#ascii-digit
	asciiUpperHexDigit	= [Ord('A')..Ord('F')]; //https://infra.spec.whatwg.org/#ascii-upper-hex-digit
	asciiLowerHexDigit	= [Ord('a')..Ord('f')]; //https://infra.spec.whatwg.org/#ascii-lower-hex-digit
	asciiHexDigit			= asciiUpperHexDigit + asciiLowerHexDigit; //https://infra.spec.whatwg.org/#ascii-hex-digit
	asciiUpperAlpha		= [Ord('A')..Ord('Z')]; //https://infra.spec.whatwg.org/#ascii-upper-alpha
	asciiLowerAlpha		= [Ord('a')..Ord('z')]; //https://infra.spec.whatwg.org/#ascii-lower-alpha
	asciiAlpha				= asciiUpperAlpha + asciiLowerAlpha; //https://infra.spec.whatwg.org/#ascii-alpha
	asciiAlphaNumeric		= asciiDigit + asciiAlpha; //https://infra.spec.whatwg.org/#ascii-alphanumeric

	UEOF = UCS4Char(-1); //A special EOF unicode character

{ THtmlParser }

procedure THtmlTokenizer.LogFmt(const Fmt: string; const Args: array of const);
var
	s: string;
begin
	if IsDebuggerPresent then
	begin
		s := Format(Fmt, Args);
		OutputDebugString(PChar(s));
	end;
end;

function THtmlTokenizer.NextFewCharacters(const Value: UnicodeString;
		const CaseSensitive: Boolean;
		const IncludingCurrentInputCharacter: Boolean): Boolean;
var
	ch: UCS4Char;
	wc: WideChar;
	i: Integer;
	nStart: Integer;
	peek: UnicodeString;
	peekOffset: Integer;
begin
	Result := False;

	if Value = '' then
		raise Exception.Create('NextFewCharacters peek value cannot be empty');

	SetLength(peek, Length(Value));

	nStart := 1;

	if IncludingCurrentInputCharacter then
	begin
		if FCurrentInputCharacter > $FFFF then
		begin
			LogFmt('Got extended unicode character while peeking. Leaving. (0x%.8x)', [FCurrentInputCharacter]);
			Exit;
		end;
		wc := WideChar(FCurrentInputCharacter);
		peek[1] := wc;
		Inc(nStart);
	end;

	peekOffset := 1;
	for i := nStart to Length(Value) do
	begin
		ch := FStream.Peek(peekOffset);
		if ch > $FFFF then
			Exit;

		wc := WideChar(ch);
		peek[i] := wc;
		Inc(peekOffset);
	end;

	if CaseSensitive then
		Result := (peek = Value)
	else
		Result := SameText(peek, Value);
end;

procedure THtmlTokenizer.AddNotImplementedParseError(const StateHandlerName: string);
begin
	AddParseError('not-implemented-'+StateHandlerName);
	raise ENotImplemented.Create(StateHandlerName);
end;

procedure THtmlTokenizer.AddParseError(ParseErrorName: string);
begin
	LogFmt('Parse Error: %s', [ParseErrorName]);
end;

procedure THtmlTokenizer.AppendToCurrentAttributeName(const Value: UCS4Char);
begin
	CurrentTagToken.CurrentAttributeName := CurrentTagToken.CurrentAttributeName + UCS4CharToUnicodeString(Value);
end;

procedure THtmlTokenizer.AppendToCurrentAttributeValue(const Value: UCS4Char);
begin
	CurrentTagToken.CurrentAttributeValue := CurrentTagToken.CurrentAttributeValue + UCS4CharToUnicodeString(Value);
end;

procedure THtmlTokenizer.AppendToCurrentCommentData(const Value: UCS4Char);
begin
	(FCurrentToken as TCommentToken).AppendCharacter(Value);
end;

procedure THtmlTokenizer.AppendToTemporaryBuffer(const Value: UCS4Char);
begin
	UCS4StrCat(FTemporaryBuffer, Value);
end;

function THtmlTokenizer.Consume: UCS4Char;
begin
	if (FReconsume) then
	begin
		FReconsume := False;
	end
	else
	begin
		FCurrentInputCharacter := Self.GetNext;
	end;

	Result := FCurrentInputCharacter;
	LogFmt('<== U+%.8x (''%s'')', [Result, WideChar(Result)]);
end;

constructor THtmlTokenizer.Create(Html: UnicodeString);
begin
	inherited Create;

	Initialize;

	FStream := TInputStream.Create(Html);
end;

procedure THtmlTokenizer.Parse;
begin
	while not FEOF do
	begin
{
		Before each step of the tokenizer,
		the user agent must first check the parser pause flag.
		If it is true, then the tokenizer must abort the processing of any nested
		invocations of the tokenizer, yielding control back to the caller.
}
		if ParserPause then
			Exit;

		case FState2 of
		tsDataState: 				DoDataState; //13.2.5.1 Data state
		tsRCDataState: 			DoRCDATAState;	//13.2.5.2 RCDATA state
		tsRawTextState: 			DoRawTextState;	 //13.2.5.3 RAWTEXT state
		tsScriptDataState: 		DoScriptDataState; //13.2.5.4 Script data state
		tsPlaintextState: 		DoPlaintextState; //13.2.5.5 PLAINTEXT state
		tsTagOpenState: 			DoTagOpenState; //13.2.5.6 Tag open state
		tsEndTagOpenState: 		DoEndTagOpenState; //13.2.5.7 End tag open state
		tsTagNameState: 			DoTagNameState; //13.2.5.8 Tag name state
		tsRCDATALessThanSignState:				DoRCDATALessThanSignState; //13.2.5.9 RCDATA less-than sign state
		tsRCDATAEndTagOpenState:				DoRCDATAEndTagOpenState; //13.2.5.10 RCDATA end tag open state
		tsRCDATAEndTagNameState:				DoRCDATAEndTagNameState; //13.2.5.11 RCDATA end tag name state
		tsRAWTEXTLessThanSignState:			DoRAWTEXTLessThanSignState; //13.2.5.12 RAWTEXT less-than sign state
		tsRAWTEXTEndTagOpenState:				DoRAWTEXTEndTagOpenState; //13.2.5.13 RAWTEXT end tag open state
		tsRAWTEXTEndTagNameState:				DoRAWTEXTEndTagNameState; //13.2.5.14 RAWTEXT end tag name state
		tsScriptDataLessThanSignState:		DoScriptDataLessThanSignState; //13.2.5.15 Script data less-than sign state
		tsScriptDataEndTagOpenState:			DoScriptDataEndTagOpenState; //13.2.5.16 Script data end tag open state
		tsScriptDataEndTagNameState:			DoScriptDataEndTagNameState; //13.2.5.17 Script data end tag name state
		tsScriptDataEscapeStartState:			DoScriptDataEscapeStartState; //13.2.5.18 Script data escape start state
		tsScriptDataEscapeStartDashState:	DoScriptDataEscapeStartDashState; //13.2.5.19 Script data escape start dash state
		tsScriptDataEscapedState:				DoScriptDataEscapedState; //13.2.5.20 Script data escaped state
		tsScriptDataEscapedDashState:			DoScriptDataEscapedDashState; //13.2.5.21 Script data escaped dash state
		tsScriptDataEscapedDashDashState:	DoScriptDataEscapedDashDashState; //13.2.5.22 Script data escaped dash dash state
		tsScriptDataEscapedLessThanSignState:	DoScriptDataEscapedLessThanSignState; //13.2.5.23 Script data escaped less-than sign state
		tsScriptDataEscapedEndTagOpenState:		DoScriptDataEscapedEndTagOpenState; //13.2.5.24 Script data escaped end tag open state
		tsScriptDataEscapedEndTagNameState:		DoScriptDataEscapedEndTagNameState; //13.2.5.25 Script data escaped end tag name state
		tsScriptDataDoubleEscapeStartState:	DoScriptDataDoubleEscapeStartState; //13.2.5.26 Script data double escape start state
		tsScriptDataDoubleEscapedState:			DoScriptDataDoubleEscapedState; //13.2.5.27 Script data double escaped state
		tsScriptDataDoubleEscapedDashState:		DoScriptDataDoubleEscapedDashState; //13.2.5.28 Script data double escaped dash state
		tsScriptDataDoubleEscapedDashDashState:		DoScriptDataDoubleEscapedDashDashState; //13.2.5.29 Script data double escaped dash dash state
		tsScriptDataDoubleEscapedLessThanSignState:	DoScriptDataDoubleEscapedLessThanSignState; //13.2.5.30 Script data double escaped less-than sign state
		tsScriptDataDoubleEscapeEndState:	DoScriptDataDoubleEscapeEndState; //13.2.5.31 Script data double escape end state
		tsBeforeAttributeNameState:			DoBeforeAttributeNameState; //13.2.5.32 Before attribute name state
		tsAttributeNameState:					DoAttributeNameState; //13.2.5.33 Attribute name state
		tsAfterAttributeNameState:				DoAfterAttributeNameState; //13.2.5.34 After attribute name state
		tsBeforeAttributeValueState:			DoBeforeAttributeValueState; //13.2.5.35 Before attribute value state
		tsAttributeValueDoubleQuotedState:	DoAttributeValueDoubleQuotedState; //13.2.5.36 Attribute value (double-quoted) state
		tsAttributeValueSingleQuotedState:	DoAttributeValueSingleQuotedState; //13.2.5.37 Attribute value (single-quoted) state
		tsAttributeValueUnquotedState: DoAttributeValueUnquotedState; //13.2.5.38 Attribute value (unquoted) state
		tsAfterAttributeValueQuotedState:	DoAfterAttributeValueQuotedState; //13.2.5.39 After attribute value (quoted) state
		tsSelfClosingStartTagState:			DoSelfClosingStartTagState; //13.2.5.40 Self-closing start tag state
		tsBogusCommentState:						DoBogusCommentState; //13.2.5.41 Bogus comment state
		tsMarkupDeclarationOpenState:			DoMarkupDeclarationOpenState; //13.2.5.42 Markup declaration open state
		tsCommentStartState:						DoCommentStartState; //13.2.5.43 Comment start state
		tsCommentStartDashState:				DoCommentStartDashState; //13.2.5.44 Comment start dash state
		tsCommentState:							DoCommentState; //13.2.5.45 Comment state
		tsCommentLessThanSignState:			DoCommentLessThanSignState; //13.2.5.46 Comment less-than sign state
		tsCommentLessThanSignBangState:		DoCommentLessThanSignBangState; //13.2.5.47 Comment less-than sign bang state
		tsCommentLessThanSignBangDashState:	DoCommentLessThanSignBangDashState; //13.2.5.48 Comment less-than sign bang dash state
		tsCommentLessThanSignBangDashDashState:	DoCommentLessThanSignBangDashDashState; //13.2.5.49 Comment less-than sign bang dash dash state
		tsCommentEndDashState:					DoCommentEndDashState; //13.2.5.50 Comment end dash state
		tsCommentEndState:						DoCommentEndState; //13.2.5.51 Comment end state
		tsCommentEndBangState:					DoCommentEndBangState; //13.2.5.52 Comment end bang state
		tsDOCTYPEState:							DoDOCTYPEState; //13.2.5.53 DOCTYPE state
		tsBeforeDOCTYPENameState:				DoBeforeDOCTYPENameState; //13.2.5.54 Before DOCTYPE name state
		tsDOCTYPENameState:						DoDOCTYPENameState; //13.2.5.55 DOCTYPE name state
		tsAfterDOCTYPENameState:				DoAfterDOCTYPENameState; //13.2.5.56 After DOCTYPE name state
		tsAfterDOCTYPEPublicKeywordState:	DoAfterDOCTYPEPublicKeywordState; //13.2.5.57 After DOCTYPE public keyword state
		tsBeforeDOCTYPEPublicIdentifierState:			DoBeforeDOCTYPEPublicIdentifierState; //13.2.5.58 Before DOCTYPE public identifier state
		tsDOCTYPEPublicIdentifierDoubleQuotedState:	DoDOCTYPEPublicIdentifierDoubleQuotedState; //13.2.5.59 DOCTYPE public identifier (double-quoted) state
		tsDOCTYPEPublicIdentifierSingleQuotedState:	DoDOCTYPEPublicIdentifierSingleQuotedState; //13.2.5.60 DOCTYPE public identifier (single-quoted) state
		tsAfterDOCTYPEPublicIdentifierState:			DoAfterDOCTYPEPublicIdentifierState; //13.2.5.61 After DOCTYPE public identifier state
		tsBetweenDOCTYPEPublicAndSystemIdentifiersState:	DoBetweenDOCTYPEPublicAndSystemIdentifiersState; //13.2.5.62 Between DOCTYPE public and system identifiers state
		tsAfterDOCTYPESystemKeywordState:				DoAfterDOCTYPESystemKeywordState; //13.2.5.63 After DOCTYPE system keyword state
		tsBeforeDOCTYPESystemIdentifierState:			DoBeforeDOCTYPESystemIdentifierState; //13.2.5.64 Before DOCTYPE system identifier state
		tsDOCTYPESystemIdentifierDoubleQuotedState:	DoDOCTYPESystemIdentifierDoubleQuotedState; //13.2.5.65 DOCTYPE system identifier (double-quoted) state
		tsDOCTYPESystemIdentifierSingleQuotedState:	DoDOCTYPESystemIdentifierSingleQuotedState; //13.2.5.66 DOCTYPE system identifier (single-quoted) state
		tsAfterDOCTYPESystemIdentifierState:			DoAfterDOCTYPESystemIdentifierState; //13.2.5.67 After DOCTYPE system identifier state
		tsBogusDOCTYPEState:					DoBogusDOCTYPEState; //13.2.5.68 Bogus DOCTYPE state
		tsCDATASectionState:					DoCDATASectionState; //13.2.5.69 CDATA section state
		tsCDATASectionBracketState:		DoCDATASectionBracketState; //13.2.5.70 CDATA section bracket state
		tsCDATASectionEndState:				DoCDATASectionEndState; //13.2.5.71 CDATA section end state
		tsCharacterReferenceState:			DoCharacterReferenceState; //13.2.5.72 Character reference state
		tsNamedCharacterReferenceState:	DoNamedCharacterReferenceState; //13.2.5.73 Named character reference state
		tsAmbiguousAmpersandState:			DoAmbiguousAmpersandState; //13.2.5.74 Ambiguous ampersand state
		tsNumericCharacterReferenceState:				DoNumericCharacterReferenceState; //13.2.5.75 Numeric character reference state
		tsHexadecimalCharacterReferenceStartState:	DoHexadecimalCharacterReferenceStartState; //13.2.5.76 Hexadecimal character reference start state
		tsDecimalCharacterReferenceStartState:			DoDecimalCharacterReferenceStartState; //13.2.5.77 Decimal character reference start state
		tsHexadecimalCharacterReferenceState:			DoHexadecimalCharacterReferenceState; //13.2.5.78 Hexadecimal character reference state
		tsDecimalCharacterReferenceState:				DoDecimalCharacterReferenceState; //13.2.5.79 Decimal character reference state
		tsNumericCharacterReferenceEndState:			DoNumericCharacterReferenceEndState; //13.2.5.80 Numeric character reference end state
		else
			//unknown state? There's no way out.
			AddParseError('Unknown-parser-state-'+TypInfo.GetEnumName(TypeInfo(TTokenizerState), Ord(FState2)));
			Break;
		end;
	end;
end;

procedure THtmlTokenizer.DoDataState;
var
	ch: UCS4Char;
begin
	//13.2.5.1 Data state
	//https://html.spec.whatwg.org/multipage/parsing.html#data-state
	ch := Consume; //consume the next input character
	case ch of
	$0026: //U+0026 AMPERSAND (&)
		begin
			SetReturnState(tsDataState);
			SetState(tsCharacterReferenceState);
		end;
	$003C: //U+003C LESS-THAN SIGN (<)
		begin
			SetState(tsTagOpenState);
		end;
	$0000: //U+0000 NULL
		begin
			AddParseError('unexpected-null-character');
			EmitCharacter(FCurrentInputCharacter);
		end;
	UEOF: EmitEndOfFileToken;
	else
		EmitCharacter(FCurrentInputCharacter);
	end;
end;

procedure THtmlTokenizer.DoRCDATAState;
var
	ch: UCS4Char;
begin
	//13.2.5.2 RCDATA state
	//https://html.spec.whatwg.org/multipage/parsing.html#rcdata-state
	ch := Consume; //consume the next input character
	case ch of
	$0026: //U+0026 AMPERSAND (&)
		begin
			SetReturnState(tsRCDATAState);
			SetState(tsCharacterReferenceState);
		end;
	$003C: SetReturnState(tsRCDATALessThanSignState); //U+003C LESS-THAN SIGN
	$0000: //U+0000 NULL
		begin
			AddParseError('unexpected-null-character');
			EmitCharacter($FFFD);
		end;
	UEOF: EmitEndOfFileToken;
	else
		EmitCharacter(FCurrentInputCharacter);
	end;
end;

procedure THtmlTokenizer.DoRawTextState;
var
	ch: UCS4Char;
begin
	//13.2.5.3 RAWTEXT state
	//https://html.spec.whatwg.org/multipage/parsing.html#rawtext-state
	ch := Consume; //consume the next input character
	case ch of
	Ord('<'): SetState(tsRawTextLessThanSignState);
	$0000: //U+0000 NULL
		begin
			AddParseError('unexpected-null-character');
			EmitCharacter($0000FFFD); //Emit a U+FFFD REPLACEMENT CHARACTER character token.
		end;
	UEOF: EmitEndOfFileToken;
	else
		EmitCharacter(FCurrentInputCharacter);
	end;
end;

procedure THtmlTokenizer.DoScriptDataState;
var
	ch: UCS4Char;
begin
	//13.2.5.4 Script data state
	//https://html.spec.whatwg.org/multipage/parsing.html#script-data-state
	ch := Consume; //consume the next input character
	case ch of
	$003C: SetState(tsScriptDataLessThanSignState); //U+003C LESS-THAN SIGN (<)
	$0000: //U+0000 NULL
		begin
			AddParseError('unexpected-null-character');
			EmitCharacter($0000FFFD); //Emit a U+FFFD REPLACEMENT CHARACTER character token.
		end;
	UEOF: EmitEndOfFileToken;
	else
		EmitCharacter(FCurrentInputCharacter);
	end;
end;

procedure THtmlTokenizer.DoPlaintextState;
var
	ch: UCS4Char;
begin
	//13.2.5.5 PLAINTEXT state
	//https://html.spec.whatwg.org/multipage/parsing.html#plaintext-state
	ch := Consume; //consume the next input character
	case ch of
	$0000: //U+0000 NULL
		begin
			AddParseError('unexpected-null-character');
			EmitCharacter($0000FFFD); //Emit a U+FFFD REPLACEMENT CHARACTER character token.
		end;
	UEOF: EmitEndOfFileToken;
	else
		EmitCharacter(FCurrentInputCharacter);
	end;
end;

procedure THtmlTokenizer.DoTagOpenState;
var
	ch: UCS4Char;
begin
	//13.2.5.6 Tag open state
	//https://html.spec.whatwg.org/multipage/parsing.html#tag-open-state
	ch := Consume; //consume the next input character

	if ch = Ord('!') then //U+0021 EXCLAMATION MARK (!)
	begin
		SetState(tsMarkupDeclarationOpenState); //Switch to the markup declaration open state.
	end
	else if ch = Ord('/') then //U+002F SOLIDUS (/)
	begin
		SetState(tsEndTagOpenState); //Switch to the end tag open state.
	end
	else if ch in asciiAlpha then
	begin
		FCurrentToken := TStartTagToken.Create; //Create a new start tag token, set its tag name to the empty string
		Reconsume(tsTagNameState); //Reconsume in the tag name state.
	end
	else if ch = Ord('?') then //U+003F QUESTION MARK (?)
	begin
		AddParseError('unexpected-question-mark-instead-of-tag-name'); //This is an unexpected-question-mark-instead-of-tag-name parse error
		FCurrentToken := TCommentToken.Create; //Create a comment token whose data is the empty string.
		Reconsume(tsBogusCommentState); //Reconsume in the bogus comment state.
	end
	else if ch = UEOF then
	begin
		AddParseError('eof-before-tag-name'); //This is an eof-before-tag-name parse error.
		EmitCharacter($003C); //Emit a U+003C LESS-THAN SIGN character token
		EmitCharacter(UEOF); //and an end-of-file token.
	end
	else
	begin
		AddParseError('invalid-first-character-of-tag-name'); //This is an eof-before-tag-name parse error.
		EmitCharacter($003C); //Emit a U+003C LESS-THAN SIGN character token
		Reconsume(tsDataState); //Reconsume in the data state.
	end;
end;

procedure THtmlTokenizer.DoEndTagOpenState;
var
	ch: UCS4Char;
begin
	//13.2.5.7 End tag open state
	//https://html.spec.whatwg.org/multipage/parsing.html#end-tag-open-state
	ch := Consume; //consume the next input character
	if ch in asciiAlpha then
	begin
		FCurrentToken := TEndTagToken.Create; //Create a new end tag token, set its tag name to the empty string.
		Reconsume(tsTagNameState); //Reconsume in the tag name state.
	end
	else if ch = Ord('>') then //U+003E GREATER-THAN SIGN (>)
	begin
		AddParseError('missing-end-tag-name');
		SetState(tsDataState);
	end
	else if ch = UEOF then
	begin
		AddParseError('eof-before-tag-name'); //This is an eof-before-tag-name parse error.
		EmitCharacter($003C); //Emit a U+003C LESS-THAN SIGN character token,
		EmitCharacter($002F); //a U+002F SOLIDUS character token
		EmitEndOfFileToken;   //and an end-of-file token
	end
	else
	begin
		AddParseError('invalid-first-character-of-tag-name'); //This is an invalid-first-character-of-tag-name parse error.
		FCurrentToken := TCommentToken.Create; //Create a comment token whose data is the empty string.
		Reconsume(tsBogusCommentState); //Reconsume in the bogus comment state.
	end;
end;

procedure THtmlTokenizer.DoTagNameState;
var
	ch: UCS4Char;
begin
	//13.2.5.8 Tag name state
	//https://html.spec.whatwg.org/multipage/parsing.html#tag-name-state
	ch := Consume; //consume the next input character
	if ch in [$0009, $000A, $000C, $0020] then
	begin
		//U+0009 CHARACTER TABULATION (tab)
		//U+000A LINE FEED (LF)
		//U+000C FORM FEED (FF)
		//U+0020 SPACE
		SetState(tsBeforeAttributeNameState); //Switch to the before attribute name state.
	end
	else if ch = $002F then //U+002F SOLIDUS (/)
	begin
		SetState(tsSelfClosingStartTagState); //Switch to the self-closing start tag state.
	end
	else if ch = $003E then //U+003E GREATER-THAN SIGN (>)
	begin
		SetState(tsDataState); //Switch to the data state.
		EmitCurrentTagToken; //Emit the current tag token.
	end
	else if ch in asciiUpperAlpha then
	begin
		//Append the lowercase version of the current input character (add 0x0020 to the character's code point)
		//to the current tag token's tag name.
		CurrentTagToken.AppendCharacter(ch + $0020);
	end
	else if ch = $0000 then //U+0000 NULL
	begin
		AddParseError('unexpected-null-character');
		CurrentTagToken.AppendCharacter($FFFD); //Append a U+FFFD REPLACEMENT CHARACTER character to the current tag token's tag name.
	end
	else if ch = UEOF then
	begin
		AddParseError('eof-in-tag');
		EmitEndOfFileToken; //Emit an end-of-file token.
	end
	else
	begin
		CurrentTagToken.AppendCharacter(FCurrentInputCharacter); //Append the current input character to the current tag token's tag name.
	end;
end;

procedure THtmlTokenizer.DoRCDATALessThanSignState;
var
	ch: UCS4Char;
begin
	//13.2.5.9 RCDATA less-than sign state
	//https://html.spec.whatwg.org/multipage/parsing.html#rcdata-less-than-sign-state
	ch := Consume; //consume the next input character
	case ch of
	$002F: //U+002F SOLIDUS (/)
		begin
			SetLength(FTemporaryBuffer, 0); //Set the temporary buffer to the empty string.
			SetState(tsRCDATAEndTagOpenState); //Switch to the RCDATA end tag open state.
		end;
	else
		EmitCharacter($003C); //Emit a U+003C LESS-THAN SIGN character token.
		Reconsume(tsRCDATAState); //Reconsume in the RCDATA state.
	end;
end;

procedure THtmlTokenizer.DoRCDATAEndTagOpenState;
var
	ch: UCS4Char;
begin
	//13.2.5.10 RCDATA end tag open state
	//https://html.spec.whatwg.org/multipage/parsing.html#rcdata-end-tag-open-state
	ch := Consume; //consume the next input character
	if ch in asciiAlpha then
	begin
		FCurrentToken := TEndTagToken.Create; //Create a new end tag token 
		//set its tag name to the empty string.
		Reconsume(tsRCDATAEndTagNameState); //Reconsume in the RCDATA end tag name state.
	end
	else
	begin
		EmitCharacter($003C); //Emit a U+003C LESS-THAN SIGN character token
		EmitCharacter($002F); //and a U+002F SOLIDUS character token.
		Reconsume(tsRCDATAState); //Reconsume in the RCDATA state.
	end;
end;

procedure THtmlTokenizer.DoRCDATAEndTagNameState;
var
	ch: UCS4Char;
	
	procedure AnythingElse;
	var
		i: Integer;
	begin
		EmitCharacter($003C); //Emit a U+003C LESS-THAN SIGN character token,
		EmitCharacter($002F); //a U+002F SOLIDUS character token,

		//and a character token for each of the characters in the temporary buffer (in the order they were added to the buffer).
		for i := 0 to Length(FTemporaryBuffer)-1 do
			EmitCharacter(FTemporaryBuffer[i]);

		Reconsume(tsRCDATAState); //Reconsume in the RCDATA state.
	end;

begin
	//13.2.5.11 RCDATA end tag name state
	//https://html.spec.whatwg.org/multipage/parsing.html#rcdata-end-tag-name-state
	ch := Consume; //consume the next input character
	if ch in [$0009, $000A, $000C, $0020] then
	begin
		//U+0009 CHARACTER TABULATION (tab)
		//U+000A LINE FEED (LF)
		//U+000C FORM FEED (FF)
		//U+0020 SPACE

		//If the current end tag token is an appropriate end tag token, 
		if IsAppropriateEndTag(FCurrentToken as TEndTagToken) then 
			SetState(tsBeforeAttributeNameState) //then switch to the before attribute name state.
		else
			AnythingElse; //Otherwise, treat it as per the "anything else" entry below.
	end
	else if ch = $002F then //U+002F SOLIDUS (/)
	begin
		//If the current end tag token is an appropriate end tag token,
		if IsAppropriateEndTag(FCurrentToken as TEndTagToken) then
			SetState(tsSelfClosingStartTagState) //then switch to the self-closing start tag state.
		else
			AnythingElse; //Otherwise, treat it as per the "anything else" entry below.
	end
	else if ch = $003E then //U+003E GREATER-THAN SIGN (>)
	begin
		//If the current end tag token is an appropriate end tag token,
		if IsAppropriateEndTag(FCurrentToken as TEndTagToken) then
		begin
			SetState(tsDataState); //then switch to the data state 
			EmitCurrentTagToken; //and emit the current tag token.
		end
		else
			AnythingElse; //Otherwise, treat it as per the "anything else" entry below.
	end
	else if ch in asciiUpperAlpha then
	begin
		(FCurrentToken as TTagToken).AppendCharacter(FCurrentInputCharacter + $0020); //Append the lowercase version of the current input character (add 0x0020 to the character's code point) to the current tag token's tag name.
		AppendToTemporaryBuffer(FCurrentInputCharacter); //Append the current input character to the temporary buffer.
	end
	else if ch in asciiLowerAlpha then
	begin
		(FCurrentToken as TTagToken).AppendCharacter(FCurrentInputCharacter); //Append the current input character to the current tag token's tag name.
		AppendToTemporaryBuffer(FCurrentInputCharacter); //Append the current input character to the temporary buffer.
	end
	else
		AnythingElse;
end;

procedure THtmlTokenizer.DoRAWTEXTLessThanSignState;
var
	ch: UCS4Char;
begin
	//13.2.5.12 RAWTEXT less-than sign state
	//https://html.spec.whatwg.org/multipage/parsing.html#rawtext-less-than-sign-state
	ch := Consume; //consume the next input character
	case ch of
	$002F: //U+002F SOLIDUS (/)
		begin
			SetLength(FTemporaryBuffer, 0); //Set the temporary buffer to the empty string.
			SetState(tsRAWTEXTEndTagOpenState); //Switch to the RAWTEXT end tag open state.
		end;
	else
		EmitCharacter($003C); //Emit a U+003C LESS-THAN SIGN character token.
		Reconsume(tsRAWTEXTState); //Reconsume in the RAWTEXT state.
	end;
end;

procedure THtmlTokenizer.DoRAWTEXTEndTagOpenState;
var
	ch: UCS4Char;
begin
	//13.2.5.13 RAWTEXT end tag open state
	//https://html.spec.whatwg.org/multipage/parsing.html#rawtext-end-tag-open-state
	ch := Consume; //consume the next input character
	if ch in asciiAlpha then
	begin
		FCurrentToken := TEndTagToken.Create; //Create a new end tag token, 
		//set its tag name to the empty string.
		Reconsume(tsRAWTEXTEndTagNameState); //Reconsume in the RAWTEXT end tag name state.
	end
	else
	begin
		EmitCharacter($003C); //Emit a U+003C LESS-THAN SIGN character token
		EmitCharacter($002F); //and a U+002F SOLIDUS character token.
		Reconsume(tsRAWTEXTState); //Reconsume in the RAWTEXT state.
	end;
end;

procedure THtmlTokenizer.DoRAWTEXTEndTagNameState;
var
	ch: UCS4Char;

	procedure AnythingElse;
	var
		i: Integer;
	begin
		EmitCharacter($003C); //Emit a U+003C LESS-THAN SIGN character token,
		EmitCharacter($002F); //a U+002F SOLIDUS character token,

		//and a character token for each of the characters in the temporary buffer (in the order they were added to the buffer).
		for i := 0 to Length(FTemporaryBuffer)-1 do
			EmitCharacter(FTemporaryBuffer[i]);

		Reconsume(tsRAWTEXTState); //Reconsume in the RAWTEXT state.
	end;

begin
	//13.2.5.14 RAWTEXT end tag name state
	//https://html.spec.whatwg.org/multipage/parsing.html#rawtext-end-tag-name-state
	ch := Consume; //consume the next input character
	if ch in [$0009, $000A, $000C, $0020] then
	begin
		//U+0009 CHARACTER TABULATION (tab)
		//U+000A LINE FEED (LF)
		//U+000C FORM FEED (FF)
		//U+0020 SPACE

		//If the current end tag token is an appropriate end tag token,
		if IsAppropriateEndTag(FCurrentToken as TEndTagToken) then
			SetState(tsBeforeAttributeNameState) //switch to the before attribute name state.
		else
			AnythingElse; //	treat it as per the "anything else" entry below.
	end
	else if ch = $002F then //U+002F SOLIDUS (/)
	begin
		//If the current end tag token is an appropriate end tag token,
		if IsAppropriateEndTag(FCurrentToken as TEndTagToken) then
			SetState(tsSelfClosingStartTagState) //switch to the self-closing start tag state.
		else
			AnythingElse; //	treat it as per the "anything else" entry below.
	end
	else if ch = $003E then //U+003E GREATER-THAN SIGN (>)
	begin
		//If the current end tag token is an appropriate end tag token,
		if IsAppropriateEndTag(FCurrentToken as TEndTagToken) then
		begin
			SetState(tsDataState); //switch to the data state 
			EmitCurrentTagToken; //and emit the current tag token.
		end
		else
			AnythingElse; //	treat it as per the "anything else" entry below.
	end
	else if ch in asciiUpperAlpha then
	begin
		(FCurrentToken as TTagToken).AppendCharacter(FCurrentInputCharacter + $0020); //Append the lowercase version of the current input character (add 0x0020 to the character's code point) to the current tag token's tag name.
		AppendToTemporaryBuffer(FCurrentInputCharacter); //Append the current input character to the temporary buffer.
	end
	else if ch in asciiLowerAlpha then
	begin
		(FCurrentToken as TTagToken).AppendCharacter(FCurrentInputCharacter); //Append the current input character to the current tag token's tag name.
		AppendToTemporaryBuffer(FCurrentInputCharacter); //Append the current input character to the temporary buffer.
	end
	else
		AnythingElse;
end;

procedure THtmlTokenizer.DoScriptDataLessThanSignState;
var
	ch: UCS4Char;
begin
	//13.2.5.15 Script data less-than sign state
	//https://html.spec.whatwg.org/multipage/parsing.html#script-data-less-than-sign-state
	ch := Consume; //consume the next input character
	if ch = $002F then //U+002F SOLIDUS (/)
	begin
		SetLength(FTemporaryBuffer, 0); //Set the temporary buffer to the empty string.
		SetState(tsScriptDataEndTagOpenState); //Switch to the script data end tag open state.
	end
	else if ch = $0021 then //U+0021 EXCLAMATION MARK (!)
	begin
		SetState(tsScriptDataEscapeStartState); //Switch to the script data escape start state.
		EmitCharacter($003C); //Emit a U+003C LESS-THAN SIGN character token
		EmitCharacter($0021); //and a U+0021 EXCLAMATION MARK character token.
	end
	else
	begin
		EmitCharacter($002C); //Emit a U+003C LESS-THAN SIGN character token.
		Reconsume(tsScriptDataState); //Reconsume in the script data state.
	end;
end;

procedure THtmlTokenizer.DoScriptDataEndTagOpenState;
var
	ch: UCS4Char;
	token: TEndTagToken;
begin
	//13.2.5.16 Script data end tag open state
	//https://html.spec.whatwg.org/multipage/parsing.html#script-data-end-tag-open-state
	ch := Consume; //consume the next input character
	if ch in asciiAlpha then
	begin
		token := TEndTagToken.Create; //Create a new end tag token
		//token.TagName := ''; //set its tag name to the empty string
		FCurrentToken := token;
		Reconsume(tsScriptDataEndTagNameState); //Reconsume in the script data end tag name state.
	end
	else
	begin
		EmitCharacter($003C); //Emit a U+003C LESS-THAN SIGN character token
		EmitCharacter($002F); //and a U+002F SOLIDUS character token.
		Reconsume(tsScriptDataState); //Reconsume in the script data state.
	end;
end;

procedure THtmlTokenizer.DoScriptDataEndTagNameState;
var
	ch: UCS4Char;

	procedure AnythingElse;
	var
		i: Integer;
	begin
		EmitCharacter($003C); //Emit a U+003C LESS-THAN SIGN character token,
		EmitCharacter($002F); //a U+002F SOLIDUS character token,

		//and a character token for each of the characters in the temporary buffer (in the order they were added to the buffer).
		for i := 0 to Length(FTemporaryBuffer)-1 do
			EmitCharacter(FTemporaryBuffer[i]);

		Reconsume(tsScriptDataState); //Reconsume in the script data state.
	end;

begin
	//13.2.5.17 Script data end tag name state
	//https://html.spec.whatwg.org/multipage/parsing.html#script-data-end-tag-name-state
	ch := Consume; //consume the next input character
	if ch in [$0009, $000A, $000C, $0020] then
	begin
		//U+0009 CHARACTER TABULATION (tab)
		//U+000A LINE FEED (LF)
		//U+000C FORM FEED (FF)
		//U+0020 SPACE

		//If the current end tag token is an appropriate end tag token,
		if IsAppropriateEndTag(FCurrentToken as TEndTagToken) then
			SetState(tsBeforeAttributeNameState) //switch to the before attribute name state.
		else
			AnythingElse; //treat it as per the "anything else" entry below.
	end
	else if ch = $002F then //U+002F SOLIDUS (/)
	begin
		//If the current end tag token is an appropriate end tag token,
		if IsAppropriateEndTag(FCurrentToken as TEndTagToken) then
			SetState(tsSelfClosingStartTagState) //switch to the self-closing start tag state.
		else
			AnythingElse; //treat it as per the "anything else" entry below.
	end
	else if ch = $003E then //U+003E GREATER-THAN SIGN (>)
	begin
		//If the current end tag token is an appropriate end tag token,
		if IsAppropriateEndTag(FCurrentToken as TEndTagToken) then
		begin
			SetState(tsDataState); //switch to the data state
			EmitCurrentTagToken; //and emit the current tag token.
		end
		else
			AnythingElse; //treat it as per the "anything else" entry below.
	end
	else if ch in asciiUpperAlpha then
	begin
		(FCurrentToken as TTagToken).AppendCharacter(FCurrentInputCharacter + $0020); //Append the lowercase version of the current input character (add 0x0020 to the character's code point) to the current tag token's tag name.
		AppendToTemporaryBuffer(FCurrentInputCharacter); //Append the current input character to the temporary buffer.
	end
	else if ch in asciiLowerAlpha then
	begin
		(FCurrentToken as TTagToken).AppendCharacter(FCurrentInputCharacter); //Append the current input character to the current tag token's tag name.
		AppendToTemporaryBuffer(FCurrentInputCharacter); //Append the current input character to the temporary buffer.
	end
	else
		AnythingElse;
end;

procedure THtmlTokenizer.DoScriptDataEscapeStartState;
var
	ch: UCS4Char;
begin
	//13.2.5.18 Script data escape start state
	ch := Consume; //consume the next input character
	case ch of
	$002D: //U+002D HYPHEN-MINUS (-)
		begin
			SetState(tsScriptDataEscapeStartDashState); //Switch to the script data escape start dash state.
			EmitCharacter($002D); //Emit a U+002D HYPHEN-MINUS character token.
		end;
	else
		Reconsume(tsScriptDataState); //Reconsume in the script data state.
	end;
end;

procedure THtmlTokenizer.DoScriptDataEscapeStartDashState;
var
	ch: UCS4Char;
begin
	//13.2.5.19 Script data escape start dash state
	//https://html.spec.whatwg.org/multipage/parsing.html#script-data-escape-start-dash-state
	ch := Consume; //consume the next input character
	case ch of
	$002D: //U+002D HYPHEN-MINUS (-)
		begin
			SetState(tsScriptDataEscapedDashDashState); //Switch to the script data escaped dash dash state.
			EmitCharacter($002D); //Emit a U+002D HYPHEN-MINUS character token.
		end;
	else
		Reconsume(tsScriptDataState); //Reconsume in the script data state.
	end;
end;

procedure THtmlTokenizer.DoScriptDataEscapedState;
var
	ch: UCS4Char;
begin
	//13.2.5.20 Script data escaped state
	//https://html.spec.whatwg.org/multipage/parsing.html#script-data-escaped-state
	ch := Consume; //consume the next input character
	case ch of
	$002D: //U+002D HYPHEN-MINUS (-)
		begin
			SetState(tsScriptDataEscapedDashState); //Switch to the script data escaped dash state.
			EmitCharacter($002D); //Emit a U+002D HYPHEN-MINUS character token.
		end;
	$003C: //U+003C LESS-THAN SIGN (<)
		begin
			SetState(tsScriptDataEscapedLessThanSignState); // Switch to the script data escaped less-than sign state.
		end;
	$0000: //U+0000 NULL
		begin
			AddParseError('unexpected-null-character'); //This is an unexpected-null-character parse error.
			EmitCharacter($FFFD); //Emit a U+FFFD REPLACEMENT CHARACTER character token.
		end;
	UEOF: //EOF
		begin
			AddParseError('eof-in-script-html-comment-like-text'); //This is an eof-in-script-html-comment-like-text parse error.
			EmitEndOfFileToken; //Emit an end-of-file token.
		end;
	else
		EmitCharacter(CurrentInputCharacter); //Emit the current input character as a character token.
	end;
end;

procedure THtmlTokenizer.DoScriptDataEscapedDashState;
var
	ch: UCS4Char;
begin
	//13.2.5.21 Script data escaped dash state
	//https://html.spec.whatwg.org/multipage/parsing.html#script-data-escaped-dash-state
	ch := Consume; //consume the next input character
	case ch of
	$002D: //U+002D HYPHEN-MINUS (-)
		begin
			SetState(tsScriptDataEscapedDashDashState); //Switch to the script data escaped dash dash state.
			EmitCharacter($002D); //Emit a U+002D HYPHEN-MINUS character token.
		end;
	$003C: //U+003C LESS-THAN SIGN (<)
		begin
			SetState(tsScriptDataEscapedLessThanSignState); //Switch to the script data escaped less-than sign state.
		end;
	$0000: //U+0000 NULL
		begin
			AddParseError('unexpected-null-character'); //This is an unexpected-null-character parse error.
			SetState(tsScriptDataEscapedState); //Switch to the script data escaped state.
			EmitCharacter($FFFD); //Emit a U+FFFD REPLACEMENT CHARACTER character token.
		end;
	UEOF:
		begin
			AddParseError('eof-in-script-html-comment-like-text'); //This is an eof-in-script-html-comment-like-text parse error.
			EmitEndOfFileToken; //Emit an end-of-file token.
		end;
	else
		//Switch to the script data escaped state.
		//Emit the current input character as a character token.
	end;
end;

procedure THtmlTokenizer.DoScriptDataEscapedDashDashState;
var
	ch: UCS4Char;
begin
	//13.2.5.22 Script data escaped dash dash state
	//https://html.spec.whatwg.org/multipage/parsing.html#script-data-escaped-dash-dash-state
	ch := Consume; //consume the next input character
	case ch of
	$002D: //U+002D HYPHEN-MINUS (-)
		begin
			EmitCharacter($002D); //Emit a U+002D HYPHEN-MINUS character token.
		end;
	$003C: //U+003C LESS-THAN SIGN (<)
		begin
			SetState(tsScriptDataEscapedLessThanSignState); //Switch to the script data escaped less-than sign state.
		end;
	$003E: //U+003E GREATER-THAN SIGN (>)
		begin
			SetState(tsScriptDataState); //Switch to the script data state.
			EmitCharacter($003E); //Emit a U+003E GREATER-THAN SIGN character token.
		end;
	$0000: //U+0000 NULL
		begin
			AddParseError('unexpected-null-character'); //This is an unexpected-null-character parse error.
			SetState(tsScriptDataEscapedState); //Switch to the script data escaped state.
			EmitCharacter($FFFD); //Emit a U+FFFD REPLACEMENT CHARACTER character token.
		end;
	UEOF: //EOF
		begin
			AddParseError('eof-in-script-html-comment-like-text'); //This is an eof-in-script-html-comment-like-text parse error.
			EmitEndOfFileToken; //Emit an end-of-file token.
		end;
	else
		SetState(tsScriptDataEscapedState); //Switch to the script data escaped state.
		EmitCharacter(CurrentInputCharacter); //Emit the current input character as a character token.
	end;
end;

procedure THtmlTokenizer.DoScriptDataEscapedLessThanSignState;
var
	ch: UCS4Char;
begin
	//13.2.5.23 Script data escaped less-than sign state
	//https://html.spec.whatwg.org/multipage/parsing.html#script-data-escaped-less-than-sign-state
	ch := Consume; //consume the next input character
	if ch = $002F then //U+002F SOLIDUS (/)
	begin
		SetLength(FTemporaryBuffer, 0); //Set the temporary buffer to the empty string. 
		SetState(tsScriptDataEscapedEndTagOpenState); //Switch to the script data escaped end tag open state.
	end
	else if ch in asciiAlpha then
	begin
		SetLength(FTemporaryBuffer, 0); //Set the temporary buffer to the empty string. 
		EmitCharacter($003C); //Emit a U+003C LESS-THAN SIGN character token. 
		Reconsume(tsScriptDataDoubleEscapeStartState); //Reconsume in the script data double escape start state.
	end
	else
	begin
		EmitCharacter($003C); //Emit a U+003C LESS-THAN SIGN character token. 
		Reconsume(tsScriptDataEscapedState); //Reconsume in the script data escaped state.
	end;
end;

procedure THtmlTokenizer.DoScriptDataEscapedEndTagOpenState;
var
	ch: UCS4Char;
begin
	//13.2.5.24 Script data escaped end tag open state
	//https://html.spec.whatwg.org/multipage/parsing.html#script-data-escaped-end-tag-open-state
	ch := Consume; //consume the next input character
	if ch in asciiAlpha then
	begin
		FCurrentToken := TEndTagToken.Create; //Create a new end tag token, 
		//set its tag name to the empty string.
		Reconsume(tsScriptDataEscapedEndTagNameState); //Reconsume in the script data escaped end tag name state.
	end
	else
	begin
		EmitCharacter($003C); //Emit a U+003C LESS-THAN SIGN character token
		EmitCharacter($002F); //and a U+002F SOLIDUS character token.
		Reconsume(tsScriptDataEscapedState); //Reconsume in the script data escaped state.
	end;
end;

procedure THtmlTokenizer.DoScriptDataEscapedEndTagNameState;
var
	ch: UCS4Char;

	procedure AnythingElse;
	var
		i: Integer;
	begin
		EmitCharacter($003C); //Emit a U+003C LESS-THAN SIGN character token,
		EmitCharacter($002F); //a U+002F SOLIDUS character token,

		//and a character token for each of the characters in the temporary buffer (in the order they were added to the buffer).
		for i := 0 to Length(FTemporaryBuffer)-1 do
			EmitCharacter(FTemporaryBuffer[i]);

		Reconsume(tsScriptDataEscapedState); //Reconsume in the script data escaped state.
	end;

begin
	//13.2.5.25 Script data escaped end tag name state
	//https://html.spec.whatwg.org/multipage/parsing.html#script-data-escaped-end-tag-name-state
	ch := Consume; //consume the next input character
	if ch in [$0009, $000A, $000C, $0020] then
	begin
		//U+0009 CHARACTER TABULATION (tab)
		//U+000A LINE FEED (LF)
		//U+000C FORM FEED (FF)
		//U+0020 SPACE
		//If the current end tag token is an appropriate end tag token,
		if IsAppropriateEndTag(FCurrentToken as TEndTagToken) then
			SetState(tsBeforeAttributeNameState) //then switch to the before attribute name state.
		else
			AnythingElse; //Otherwise, treat it as per the "anything else" entry below.
	end
	else if ch = $002F then //U+002F SOLIDUS (/)
	begin
		//If the current end tag token is an appropriate end tag token,
		if IsAppropriateEndTag(FCurrentToken as TEndTagToken) then
			SetState(tsSelfClosingStartTagState) //then switch to the self-closing start tag state.
		else
			AnythingElse; //Otherwise, treat it as per the "anything else" entry below.
	end
	else if ch = $003E then //U+003E GREATER-THAN SIGN (>)
	begin
		//If the current end tag token is an appropriate end tag token,
		if IsAppropriateEndTag(FCurrentToken as TEndTagToken) then
		begin			
			SetState(tsDataState); //then switch to the data state
			EmitCurrentTagToken; //and emit the current tag token.
		end
		else
			AnythingElse; //Otherwise, treat it as per the "anything else" entry below.
	end
	else if ch in asciiUpperAlpha then
	begin
		(FCurrentToken as TTagToken).AppendCharacter(FCurrentInputCharacter + $0020); //Append the lowercase version of the current input character (add 0x0020 to the character's code point) to the current tag token's tag name.
		AppendToTemporaryBuffer(FCurrentInputCharacter); //Append the current input character to the temporary buffer.
	end
	else if ch in asciiLowerAlpha then
	begin
		(FCurrentToken as TTagToken).AppendCharacter(FCurrentInputCharacter); //Append the current input character to the current tag token's tag name.
		AppendToTemporaryBuffer(FCurrentInputCharacter); //Append the current input character to the temporary buffer.
	end
	else
		AnythingElse;
end;

procedure THtmlTokenizer.DoScriptDataDoubleEscapeStartState;
var
	ch: UCS4Char;
begin
	//13.2.5.26 Script data double escape start state
	//https://html.spec.whatwg.org/multipage/parsing.html#script-data-double-escape-start-state
	ch := Consume; //consume the next input character
	if ch in [$0009, $000A, $000C, $0020, $002F, $003E] then
	begin
		//U+0009 CHARACTER TABULATION (tab)
		//U+000A LINE FEED (LF)
		//U+000C FORM FEED (FF)
		//U+0020 SPACE
		//U+002F SOLIDUS (/)
		//U+003E GREATER-THAN SIGN (>)
	
		//If the temporary buffer is the string "script"
		if TemporaryBufferIs('script') then
			SetState(tsScriptDataDoubleEscapedState) //then switch to the script data double escaped state.
		else
		begin
			SetState(tsScriptDataEscapedState); //Otherwise, switch to the script data escaped state.
			EmitCharacter(CurrentInputCharacter); //Emit the current input character as a character token.
		end;
	end
	else if ch in asciiUpperAlpha then
	begin
		AppendToTemporaryBuffer(FCurrentInputCharacter + $0020); //Append the lowercase version of the current input character (add 0x0020 to the character's code point) to the temporary buffer.
		EmitCharacter(CurrentInputCharacter); //Emit the current input character as a character token.
	end
	else if ch in asciiLowerAlpha then
	begin
		AppendToTemporaryBuffer(FCurrentInputCharacter); //Append the current input character to the temporary buffer.
		EmitCharacter(CurrentInputCharacter); //Emit the current input character as a character token.
	end
	else
		Reconsume(tsScriptDataEscapedState); //Reconsume in the script data escaped state.
end;

procedure THtmlTokenizer.DoScriptDataDoubleEscapedState;
var
	ch: UCS4Char;
begin
	//13.2.5.27 Script data double escaped state
	//https://html.spec.whatwg.org/multipage/parsing.html#script-data-double-escaped-state
	ch := Consume; //consume the next input character
	case ch of
	$002D: //U+002D HYPHEN-MINUS (-)
		begin
			SetState(tsScriptDataDoubleEscapedDashState); //Switch to the script data double escaped dash state.
			EmitCharacter($002D); //Emit a U+002D HYPHEN-MINUS character token.
		end;
	$003C: //U+003C LESS-THAN SIGN (<)
		begin
			SetState(tsScriptDataDoubleEscapedLessThanSignState); //Switch to the script data double escaped less-than sign state.
			EmitCharacter($003C); //Emit a U+003C LESS-THAN SIGN character token.
		end;
	$0000: //U+0000 NULL
		begin
			AddParseError('unexpected-null-character'); //This is an unexpected-null-character parse error.
			EmitCharacter($FFFD); //Emit a U+FFFD REPLACEMENT CHARACTER character token.
		end;
	UEOF:
		begin
			AddParseError('eof-in-script-html-comment-like-text'); //This is an eof-in-script-html-comment-like-text parse error.
			EmitEndOfFileToken; //Emit an end-of-file token.
		end;
	else
		EmitCharacter(CurrentInputCharacter); //Emit the current input character as a character token.
	end;
end;

procedure THtmlTokenizer.DoScriptDataDoubleEscapedDashState;
var
	ch: UCS4Char;
begin
	//13.2.5.28 Script data double escaped dash state
	// https://html.spec.whatwg.org/multipage/parsing.html#script-data-double-escaped-dash-state
	ch := Consume; //consume the next input character
	case ch of
	$002D: //U+002D HYPHEN-MINUS (-)
		begin
			SetState(tsScriptDataDoubleEscapedDashDashState); //Switch to the script data double escaped dash dash state.
			EmitCharacter($002D); //Emit a U+002D HYPHEN-MINUS character token.
		end;
	$003C: //U+003C LESS-THAN SIGN (<)
		begin
			SetState(tsScriptDataDoubleEscapedLessThanSignState); //Switch to the script data double escaped less-than sign state.
			EmitCharacter($003C); //Emit a U+003C LESS-THAN SIGN character token.
		end;
	$0000: //U+0000 NULL
		begin
			AddParseError('unexpected-null-character'); //This is an unexpected-null-character parse error.
			SetState(tsScriptDataDoubleEscapedState); //Switch to the script data double escaped state.
			EmitCharacter($FFFD); //Emit a U+FFFD REPLACEMENT CHARACTER character token.
		end;
	UEOF:
		begin
			AddParseError('eof-in-script-html-comment-like-text'); //This is an eof-in-script-html-comment-like-text parse error.
			EmitEndOfFileToken; //Emit an end-of-file token.
		end;
	else
		SetState(tsScriptDataDoubleEscapedState); //Switch to the script data double escaped state.
		EmitCharacter(CurrentInputCharacter); //Emit the current input character as a character token.
	end;
end;

procedure THtmlTokenizer.DoScriptDataDoubleEscapedDashDashState;
var
	ch: UCS4Char;
begin
	//13.2.5.29 Script data double escaped dash dash state
	//https://html.spec.whatwg.org/multipage/parsing.html#script-data-double-escaped-dash-dash-state
	ch := Consume; //consume the next input character
	case ch of
	$002D: //U+002D HYPHEN-MINUS (-)
		begin
			EmitCharacter($002D); //Emit a U+002D HYPHEN-MINUS character token.
		end;
	$003C: //U+003C LESS-THAN SIGN (<)
		begin
			SetState(tsScriptDataDoubleEscapedLessThanSignState);//Switch to the script data double escaped less-than sign state.
			EmitCharacter($003C); //Emit a U+003C LESS-THAN SIGN character token.
		end;
	$003E: //U+003E GREATER-THAN SIGN (>)
		begin
			SetState(tsScriptDataState); //Switch to the script data state.
			EmitCharacter($003E); //Emit a U+003E GREATER-THAN SIGN character token.
		end;
	$0000: //U+0000 NULL
		begin
			AddParseError('unexpected-null-character'); //This is an unexpected-null-character parse error.
			SetState(tsScriptDataDoubleEscapedState); //Switch to the script data double escaped state.
			EmitCharacter($FFFD); //Emit a U+FFFD REPLACEMENT CHARACTER character token.
		end;
	UEOF:
		begin
			AddParseError('eof-in-script-html-comment-like-text'); //This is an eof-in-script-html-comment-like-text parse error.
			EmitEndOfFileToken; //Emit an end-of-file token.
		end;
	else
		SetState(tsScriptDataDoubleEscapedState); //Switch to the script data double escaped state.
		EmitCharacter(CurrentInputCharacter); //Emit the current input character as a character token.
	end;
end;

procedure THtmlTokenizer.DoScriptDataDoubleEscapedLessThanSignState;
var
	ch: UCS4Char;
begin
	//13.2.5.30 Script data double escaped less-than sign state
	//https://html.spec.whatwg.org/multipage/parsing.html#script-data-double-escaped-less-than-sign-state
	ch := Consume; //consume the next input character
	case ch of
	$002F: //U+002F SOLIDUS (/)
		begin
			SetLength(FTemporaryBuffer, 0); //Set the temporary buffer to the empty string.
			SetState(tsScriptDataDoubleEscapeEndState); //Switch to the script data double escape end state.
			EmitCharacter($002F); //Emit a U+002F SOLIDUS character token.
		end;
	else
		Reconsume(tsScriptDataDoubleEscapedState); //Reconsume in the script data double escaped state.
	end;
end;

procedure THtmlTokenizer.DoScriptDataDoubleEscapeEndState;
var
	ch: UCS4Char;
begin
	//13.2.5.31 Script data double escape end state
	//https://html.spec.whatwg.org/multipage/parsing.html#script-data-double-escape-end-stat
	ch := Consume; //consume the next input character

	if ch in [$0009, $000A, $000C, $0020, $002F, $003E] then
	begin
		//U+0009 CHARACTER TABULATION (tab)
		//U+000A LINE FEED (LF)
		//U+000C FORM FEED (FF)
		//U+0020 SPACE
		//U+002F SOLIDUS (/)
		//U+003E GREATER-THAN SIGN (>)
		
		//If the temporary buffer is the string "script"
		if TemporaryBufferIs('script') then
			SetState(tsScriptDataEscapedState) //then switch to the script data escaped state.
		else
		begin
			SetState(tsScriptDataDoubleEscapedState); //Otherwise, switch to the script data double escaped state.
			EmitCharacter(CurrentInputCharacter); //Emit the current input character as a character token.
		end;
	end
	else if ch in asciiUpperAlpha then
	begin
		AppendToTemporaryBuffer(FCurrentInputCharacter + $0020); //Append the lowercase version of the current input character (add 0x0020 to the character's code point) to the temporary buffer.
		EmitCharacter(CurrentInputCharacter); //Emit the current input character as a character token.
	end
	else if ch in asciiLowerAlpha then
	begin
		AppendToTemporaryBuffer(FCurrentInputCharacter); //Append the current input character to the temporary buffer.
		EmitCharacter(CurrentInputCharacter); //Emit the current input character as a character token.
	end
	else
		Reconsume(tsScriptDataDoubleEscapedState); //Reconsume in the script data escaped state.
end;

procedure THtmlTokenizer.DoBeforeAttributeNameState;
var
	ch: UCS4Char;
begin
	//13.2.5.32 Before attribute name state
	//https://html.spec.whatwg.org/multipage/parsing.html#before-attribute-name-state
	ch := Consume; //Consume the next input character
	case ch of
	$0009, //U+0009 CHARACTER TABULATION (tab)
	$000A, //U+000A LINE FEED (LF)
	$000C, //U+000C FORM FEED (FF)
	$0020: //U+0020 SPACE
		begin
			//Ignore the character.
		end;
	$002F, //U+002F SOLIDUS (/)
	$003E, //U+003E GREATER-THAN SIGN (>)
	UEOF:
		begin
			Reconsume(tsAfterAttributeNameState); //Reconsume in the after attribute name state.
		end;
	$003D: //U+003D EQUALS SIGN (=)
		begin
			AddParseError('unexpected-equals-sign-before-attribute-name'); //This is an unexpected-equals-sign-before-attribute-name parse error.
			CurrentTagToken.NewAttribute; //Start a new attribute in the current tag token.
			CurrentTagToken.CurrentAttributeName := UCS4CharToUnicodeString(FCurrentInputCharacter); //Set that attribute's name to the current input character,
			CurrentTagToken.CurrentAttributeValue := ''; //and its value to the empty string.
			SetState(tsAttributeNameState); //Switch to the attribute name state.
		end;
	else
		CurrentTagToken.NewAttribute; //Start a new attribute in the current tag token.
		CurrentTagToken.CurrentAttributeName := ''; // Set that attribute name and value to the empty string.
		CurrentTagToken.CurrentAttributeValue := ''; // (and value!)
		Reconsume(tsAttributeNameState); //Reconsume in the attribute name state.
	end;
end;

procedure THtmlTokenizer.DoAttributeNameState;
var
	ch: UCS4Char;

	procedure AnythingElse;
	begin
		AppendToCurrentAttributeName(FCurrentInputCharacter); //Append the current input character to the current attribute's name.
	end;

begin
	//13.2.5.33 Attribute name state
	//https://html.spec.whatwg.org/multipage/parsing.html#attribute-name-state
	ch := Consume; //Consume the next input character
	if (ch in [$0009, $000A, $000C, $0020, $002F, $003E]) or (ch = UEOF) then
	begin
		//U+0009 CHARACTER TABULATION (tab)
		//U+000A LINE FEED (LF)
		//U+000C FORM FEED (FF)
		//U+0020 SPACE
		//U+002F SOLIDUS (/)
		//U+003E GREATER-THAN SIGN (>)
		//EOF
		CurrentTagToken.FinalizeAttributeName;
		Reconsume(tsAfterAttributeNameState); //Reconsume in the after attribute name state.
	end
	else if ch = $003D then //U+003D EQUALS SIGN (=)
	begin
		CurrentTagToken.FinalizeAttributeName;
		SetState(tsBeforeAttributeValueState); //Switch to the before attribute value state.
	end
	else if ch in asciiUpperAlpha then
	begin
		AppendToCurrentAttributeName(FCurrentInputCharacter + $0020); //Append the lowercase version of the current input character (add 0x0020 to the character's code point) to the current attribute's name.
	end
	else if ch = $0000 then //U+0000 NULL
	begin
		AddParseError('unexpected-null-character'); //This is an unexpected-null-character parse error.
		AppendToCurrentAttributeName($FFFD); //Append a U+FFFD REPLACEMENT CHARACTER character to the current attribute's name.
	end
	else if ch in [$0020, $0027, $003C] then
	begin
		//U+0022 QUOTATION MARK (")
		//U+0027 APOSTROPHE (')
		//U+003C LESS-THAN SIGN (<)
		AddParseError('unexpected-character-in-attribute-name'); //This is an unexpected-character-in-attribute-name parse error.
		AnythingElse; //Treat it as per the "anything else" entry below.
	end
	else
		AnythingElse;
end;

procedure THtmlTokenizer.DoAfterAttributeNameState;
var
	ch: UCS4Char;
begin
	//13.2.5.34 After attribute name state
	//https://html.spec.whatwg.org/multipage/parsing.html#after-attribute-name-state
	ch := Consume; //Consume the next input character
	case ch of
	$0009, //U+0009 CHARACTER TABULATION (tab)
	$000A, //U+000A LINE FEED (LF)
	$000C, //U+000C FORM FEED (FF)
	$0020: //U+0020 SPACE
		begin
			//Ignore the character.
		end;
	$002F: //U+002F SOLIDUS (/)
		begin
			SetState(tsSelfClosingStartTagState); //Switch to the self-closing start tag state.
		end;
	$003D: //U+003D EQUALS SIGN (=)
		begin
			SetState(tsBeforeAttributeValueState); //Switch to the before attribute value state.
		end;
	$003E: //U+003E GREATER-THAN SIGN (>)
		begin
			SetState(tsDataState); //Switch to the data state.
			EmitCurrentTagToken; //Emit the current tag token.
		end;
	UEOF:
		begin
			AddParseError('eof-in-tag'); //This is an eof-in-tag parse error.
			EmitEndOfFileToken; //Emit an end-of-file token.
		end;
	else
		CurrentTagToken.NewAttribute; //Start a new attribute in the current tag token.
		CurrentTagToken.CurrentAttributeName := ''; //Set that attribute name and value to the empty string.
		CurrentTagToken.CurrentAttributeValue := ''; //(and value!)
		Reconsume(tsAttributeNameState); //Reconsume in the attribute name state.
	end;
end;

procedure THtmlTokenizer.DoBeforeAttributeValueState;
var
	ch: UCS4Char;
begin
	//13.2.5.35 Before attribute value state
	//https://html.spec.whatwg.org/multipage/parsing.html#before-attribute-value-state
	ch := Consume; //Consume the next input character
	case ch of
	$0009, //U+0009 CHARACTER TABULATION (tab)
	$000A, //U+000A LINE FEED (LF)
	$000C, //U+000C FORM FEED (FF)
	$0020: //U+0020 SPACE
		begin
			//Ignore the character.
		end;
	$0022: //U+0022 QUOTATION MARK (")
		begin
			SetState(tsAttributeValueDoubleQuotedState); //Switch to the attribute value (double-quoted) state.
		end;
	$0027: //U+0027 APOSTROPHE (')
		begin
			SetState(tsAttributeValueSingleQuotedState); //Switch to the attribute value (single-quoted) state.
		end;
	$003E: //U+003E GREATER-THAN SIGN (>)
		begin
			AddParseError('missing-attribute-value'); //This is a missing-attribute-value parse error.
			SetState(tsDataState); //Switch to the data state.
			EmitCurrentTagToken; //Emit the current tag token.
		end;
	else
		Reconsume(tsAttributeValueUnquotedState); //Reconsume in the attribute value (unquoted) state.
	end;
end;

procedure THtmlTokenizer.DoAttributeValueDoubleQuotedState;
var
	ch: UCS4Char;
begin
	//13.2.5.36 Attribute value (double-quoted) state
	//https://html.spec.whatwg.org/multipage/parsing.html#attribute-value-(double-quoted)-state
	ch := Consume; //Consume the next input character:
	case ch of
	$0022: //U+0022 QUOTATION MARK (")
		begin
			SetState(tsAfterAttributeValueQuotedState); //Switch to the after attribute value (quoted) state.
		end;
	$0026: //U+0026 AMPERSAND (&)
		begin
			SetReturnState(tsAttributeValueDoubleQuotedState); //Set the return state to the attribute value (double-quoted) state.
			SetState(tsCharacterReferenceState); //Switch to the character reference state.
		end;
	$0000: //U+0000 NULL
		begin
			AddParseError('unexpected-null-character'); //This is an unexpected-null-character parse error.
			AppendToCurrentAttributeValue($FFFD); //Append a U+FFFD REPLACEMENT CHARACTER character to the current attribute's value.
		end;
	UEOF:
		begin
			AddParseError('eof-in-tag'); //This is an eof-in-tag parse error.
			EmitEndOfFileToken; //Emit an end-of-file token.
		end;
	else
		AppendToCurrentAttributeValue(FCurrentInputCharacter); //Append the current input character to the current attribute's value.
	end;
end;

procedure THtmlTokenizer.DoAttributeValueSingleQuotedState;
var
	ch: UCS4Char;
begin
	//13.2.5.37 Attribute value (single-quoted) state
	//https://html.spec.whatwg.org/multipage/parsing.html#attribute-value-(single-quoted)-state
	ch := Consume; // Consume the next input character:
	case ch of
	$0027: //U+0027 APOSTROPHE (')
		begin
			SetState(tsAfterattributeValueQuotedState); //Switch to the after attribute value (quoted) state.
		end;
	$0026: //U+0026 AMPERSAND (&)
		begin
			SetReturnState(tsAttributeValueSingleQuotedState); //Set the return state to the attribute value (single-quoted) state. 
			SetState(tsCharacterReferenceState); //Switch to the character reference state.
		end;
	$0000: //U+0000 NULL
		begin
			AddParseError('unexpected-null-character'); //This is an unexpected-null-character parse error. 
			AppendToCurrentAttributeValue($FFFD); //Append a U+FFFD REPLACEMENT CHARACTER character to the current attribute's value.
		end;
	UEOF:
		begin
			AddParseError('eof-in-tag'); //This is an eof-in-tag parse error. 
			EmitEndOfFileToken; //Emit an end-of-file token.
		end;
	else
		AppendToCurrentAttributeValue(FCurrentInputCharacter); //Append the current input character to the current attribute's value.
	end;
end;

procedure THtmlTokenizer.DoAttributeValueUnquotedState;
var
	ch: UCS4Char;
begin
	//13.2.5.38 Attribute value (unquoted) state
	//https://html.spec.whatwg.org/multipage/parsing.html#attribute-value-(unquoted)-state
	ch := Consume; // Consume the next input character:
	case ch of 
	$0009, //U+0009 CHARACTER TABULATION (tab)
	$000A, //U+000A LINE FEED (LF)
	$000C, //U+000C FORM FEED (FF)
	$0020: //U+0020 SPACE
		begin
			SetState(tsBeforeAttributeNameState); //Switch to the before attribute name state.
		end;
	$0026: //U+0026 AMPERSAND (&)
		begin
			SetReturnState(tsAttributeValueUnquotedState); //Set the return state to the attribute value (unquoted) state. 
			SetState(tsCharacterReferenceState); //Switch to the character reference state.
		end;
	$003E: //U+003E GREATER-THAN SIGN (>)
		begin
			SetSTate(tsDataState); //Switch to the data state. 
			EmitCurrentTagToken; //Emit the current tag token.	
		end;
	$0000: //U+0000 NULL
		begin
			AddParseError('unexpected-null-character'); //This is an unexpected-null-character parse error. 
			AppendToCurrentAttributeValue($FFFD); //Append a U+FFFD REPLACEMENT CHARACTER character to the current attribute's value.
		end;
	$0022, //U+0022 QUOTATION MARK (")
	$0027, //U+0027 APOSTROPHE (')
	$003C, //U+003C LESS-THAN SIGN (<)
	$003D, //U+003D EQUALS SIGN (=)
	$0060: //U+0060 GRAVE ACCENT (`)
		begin
			AddParseError('unexpected-character-in-unquoted-attribute-value'); //This is an unexpected-character-in-unquoted-attribute-value parse error. 
			AppendToCurrentAttributeValue(FCurrentInputCharacter); //Treat it as per the "anything else" entry below.
		end;
	UEOF:
		begin
			AddParseError('eof-in-tag'); //This is an eof-in-tag parse error. 
			EmitEndOfFileToken; //Emit an end-of-file token.
		end;
	else
		AppendToCurrentAttributeValue(FCurrentInputCharacter); //Append the current input character to the current attribute's value.
	end;
end;

procedure THtmlTokenizer.DoAfterAttributeValueQuotedState;
var
	ch: UCS4Char;
begin
	//13.2.5.39 After attribute value (quoted) state
	//https://html.spec.whatwg.org/multipage/parsing.html#after-attribute-value-(quoted)-state
	ch := Consume; //Consume the next input character:
	case ch of
	$0009, //U+0009 CHARACTER TABULATION (tab)
	$000A, //U+000A LINE FEED (LF)
	$000C, //U+000C FORM FEED (FF)
	$0020: //U+0020 SPACE
		begin
			SetState(tsBeforeAttributeNameState); //Switch to the before attribute name state.
		end;
	$002F: //U+002F SOLIDUS (/)
		begin
			SetState(tsSelfClosingStartTagState); //Switch to the self-closing start tag state.
		end;
	$003E: //U+003E GREATER-THAN SIGN (>)
		begin
			SetState(tsDataState); //Switch to the data state.
			EmitCurrentTagToken; //Emit the current tag token.
		end;
	UEOF:
		begin
			AddParseError('eof-in-tag'); //This is an eof-in-tag parse error.
			EmitEndOfFileToken; //Emit an end-of-file token.
		end;
	else
		AddParseError('missing-whitespace-between-attributes'); //This is a missing-whitespace-between-attributes parse error.
		Reconsume(tsBeforeAttributeNameState); //Reconsume in the before attribute name state.
	end;
end;

procedure THtmlTokenizer.DoSelfClosingStartTagState;
var
	ch: UCS4Char;
begin
	//13.2.5.40 Self-closing start tag state
	//https://html.spec.whatwg.org/multipage/parsing.html#self-closing-start-tag-state
	ch := Consume;
	case ch of
	$003E: //U+003E GREATER-THAN SIGN (>)
		begin
			CurrentTagToken.SelfClosing := True; //Set the self-closing flag of the current tag token.
			SetState(tsDataState); //Switch to the data state.
			EmitCurrentTagToken; //Emit the current tag token.
		end;
	UEOF:
		begin
			AddParseError('eof-in-tag'); //This is an eof-in-tag parse error.
			EmitEndOfFileToken; //Emit an end-of-file token.
		end;
	else
		AddParseError('unexpected-solidus-in-tag'); //This is an unexpected-solidus-in-tag parse error.
		Reconsume(tsBeforeAttributeNameState); //Reconsume in the before attribute name state.
	end;
end;

procedure THtmlTokenizer.DoBogusCommentState;
var
	ch: UCS4Char;
begin
	//13.2.5.41 Bogus comment state
	//https://html.spec.whatwg.org/multipage/parsing.html#bogus-comment-state
	ch := Consume; //Consume the next input character:
	case ch of
	$003E: // U+003E GREATER-THAN SIGN (>)
		begin
			SetState(tsDataState); //Switch to the data state.
			EmitCurrentCommentToken; //Emit the current comment token.
		end;
	UEOF:
		begin
			EmitCurrentCommentToken; //Emit the comment.
			EmitEndOfFileToken; //Emit an end-of-file token.
		end;
	$0000: //U+0000 NULL
		begin
			AddParseError('unexpected-null-character'); //This is an unexpected-null-character parse error.
			(FCurrentToken as TCommentToken).AppendCharacter($FFFD); //Append a U+FFFD REPLACEMENT CHARACTER character to the comment token's data.
		end;
	else
		//Append the current input character to the comment token's data.
		(FCurrentToken as TCommentToken).AppendCharacter(FCurrentInputCharacter);
	end;
end;

procedure THtmlTokenizer.DoMarkupDeclarationOpenState;
var
	newCommentToken: TCommentToken;
begin
	//13.2.5.42 Markup declaration open state
	//https://html.spec.whatwg.org/multipage/parsing.html#markup-declaration-open-state
	if NextFewCharacters('--', True, False) then //Two U+002D HYPHEN-MINUS characters (-)
	begin
		//Consume those two characters,
		Consume; //"-"
		Consume; //"-"
		FCurrentToken := TCommentToken.Create; //create a comment token whose data is the empty string//create a comment token whose data is the empty string,
		SetState(tsCommentStartState); //and switch to the comment start state.
	end
	else if NextFewCharacters('DOCTYPE', False, False) then
	begin
		//ASCII case-insensitive match for the word "DOCTYPE"

		//Consume those characters
		Consume; //D
		Consume; //O
		Consume; //C
		Consume; //T
		Consume; //Y
		Consume; //P
		Consume; //E

		SetState(tsDOCTYPEState); //and switch to the DOCTYPE state.
	end
	else if NextFewCharacters('[CDATA[', True, False) then
	begin
		//The string "[CDATA[" (the five uppercase letters "CDATA" with a U+005B LEFT SQUARE BRACKET character before and after)

		//Consume those characters.
		Consume; //[
		Consume; //C
		Consume; //D
		Consume; //A
		Consume; //T
		Consume; //A
		Consume; //[

		//TODO: If there is an [adjusted current node] and it is not an element in the [HTML namespace],
		//then switch to the [CDATA section state].
{		if (FAdjustedCurrentNode <> nil) and (FAdjustedCurrentNode.Namespace <> 'HTML') then
		begin
			SetState(tsCDATASectionState);
			Exit;
		end;}

		AddParseError('cdata-in-html-content'); //Otherwise, this is a cdata-in-html-content parse error.
		//Create a comment token whose data is the "[CDATA[" string.
		newCommentToken := TCommentToken.Create;
		newCommentToken.AppendCharacter(Ord('['));
		newCommentToken.AppendCharacter(Ord('C'));
		newCommentToken.AppendCharacter(Ord('D'));
		newCommentToken.AppendCharacter(Ord('A'));
		newCommentToken.AppendCharacter(Ord('T'));
		newCommentToken.AppendCharacter(Ord('A'));
		newCommentToken.AppendCharacter(Ord('['));

		FCurrentToken :=  newCommentToken;
		SetState(tsBogusCommentState); //Switch to the bogus comment state.
	end
	else
	begin
		AddParseError('incorrectly-opened-comment'); //This is an incorrectly-opened-comment parse error.
		FCurrentToken := TCommentToken.Create; //Create a comment token whose data is the empty string.
		SetState(tsBogusCommentState); //Switch to the bogus comment state (don't consume anything in the current state).
	end;
end;

procedure THtmlTokenizer.DoCommentStartState;
var
	ch: UCS4Char;
begin
	//13.2.5.43 Comment start state
   //https://html.spec.whatwg.org/multipage/parsing.html#comment-start-state
	ch := Consume; // Consume the next input character:
	case ch of
	$002D: //U+002D HYPHEN-MINUS (-)
		begin
			SetState(tsCommentStartDashState); //Switch to the comment start dash state.
		end;
	$003E: //U+003E GREATER-THAN SIGN (>)
		begin
			AddParseError('abrupt-closing-of-empty-comment'); //This is an abrupt-closing-of-empty-comment parse error. 
			SetState(tsDataState); //Switch to the data state. 
			EmitCurrentCommentToken; //Emit the current comment token.
		end;
	else
		Reconsume(tsCommentState); //Reconsume in the comment state.
	end;
end;

procedure THtmlTokenizer.DoCommentStartDashState;
var
	ch: UCS4Char;
begin
	//13.2.5.44 Comment start dash state
	//https://html.spec.whatwg.org/multipage/parsing.html#comment-start-dash-state
	ch := Consume; // Consume the next input character:
	case ch of
	$002D: //U+002D HYPHEN-MINUS (-)
		begin
			SetState(tsCommentEndState); //Switch to the comment end state.
		end;
	$003E: //U+003E GREATER-THAN SIGN (>)
		begin
			AddParseError('abrupt-closing-of-empty-comment'); //This is an abrupt-closing-of-empty-comment parse error. 
			SetState(tsDataState); //Switch to the data state. 
			EmitCurrentCommentToken; //Emit the current comment token.
		end;
	UEOF:
		begin
			AddParseError('eof-in-comment'); //This is an eof-in-comment parse error. 
			EmitCurrentCommentToken; //Emit the current comment token. 
			EmitEndOfFileToken; //Emit an end-of-file token.
		end;
	else
		AppendToCurrentCommentData($002D); //Append a U+002D HYPHEN-MINUS character (-) to the comment token's data. Reconsume in the comment state.
	end;
end;

procedure THtmlTokenizer.DoCommentState;
var
	ch: UCS4Char;
begin
	//13.2.5.45 Comment state
	//https://html.spec.whatwg.org/multipage/parsing.html#comment-state
	ch := Consume; // Consume the next input character:
	case ch of
	$003C: //U+003C LESS-THAN SIGN (<)
		begin
			AppendToCurrentCommentData(FCurrentInputCharacter); //Append the current input character to the comment token's data. 
			SetState(tsCommentLessThanSignState); //Switch to the comment less-than sign state.
		end;
	$002D: //U+002D HYPHEN-MINUS (-)
		begin
			SetState(tsCommentEndDashState); //Switch to the comment end dash state.
		end;
	$0000: //U+0000 NULL
		begin
			AddParseError('unexpected-null-character'); //This is an unexpected-null-character parse error. 
			AppendToCurrentCommentData($FFFD); //Append a U+FFFD REPLACEMENT CHARACTER character to the comment token's data.
		end;
	UEOF:
		begin
			AddParseError('eof-in-comment'); //This is an eof-in-comment parse error. 
			EmitCurrentCommentToken; //Emit the current comment token. 
			EmitEndOfFileToken; //Emit an end-of-file token.
		end;
	else
		AppendToCurrentCommentData(FCurrentInputCharacter); //Append the current input character to the comment token's data.
	end;
end;

procedure THtmlTokenizer.DoCommentLessThanSignState;
var
	ch: UCS4Char;
begin
	//13.2.5.46 Comment less-than sign state
	//https://html.spec.whatwg.org/multipage/parsing.html#comment-less-than-sign-state
	ch := Consume; // Consume the next input character:
	case ch of
	$0021: //U+0021 EXCLAMATION MARK (!)
		begin
			AppendToCurrentCommentData(FCurrentInputCharacter); //Append the current input character to the comment token's data. 
			SetState(tsCommentLessThanSignBangState); //Switch to the comment less-than sign bang state.
		end;
	$003C: //U+003C LESS-THAN SIGN (<)
		begin
			AppendToCurrentCommentData(FCurrentInputCharacter); //Append the current input character to the comment token's data.
		end;
	else
		Reconsume(tsCommentState); //Reconsume in the comment state.
	end;
end;

procedure THtmlTokenizer.DoCommentLessThanSignBangState;
var
	ch: UCS4Char;
begin
	//13.2.5.47 Comment less-than sign bang state
	//https://html.spec.whatwg.org/multipage/parsing.html#comment-less-than-sign-bang-state
	ch := Consume; // Consume the next input character:
	case ch of
	$002D: //U+002D HYPHEN-MINUS (-)
		begin
			SetState(tsCommentLessThanSignBangDashState); //Switch to the comment less-than sign bang dash state.
		end;
	else
		Reconsume(tsCommentState); //Reconsume in the comment state.
	end;
end;

procedure THtmlTokenizer.DoCommentLessThanSignBangDashState;
var
	ch: UCS4Char;
begin
	//13.2.5.48 Comment less-than sign bang dash state
	//https://html.spec.whatwg.org/multipage/parsing.html#comment-less-than-sign-bang-dash-state
	ch := Consume; // Consume the next input character:
	case ch of 
	$002D: //U+002D HYPHEN-MINUS (-)
		begin
			SetState(tsCommentLessThanSignBangDashDashState); //Switch to the comment less-than sign bang dash dash state.
		end;
	else
		Reconsume(tsCommentEndDashState); //Reconsume in the comment end dash state.
	end;
end;

procedure THtmlTokenizer.DoCommentLessThanSignBangDashDashState;
var
	ch: UCS4Char;
begin
	//13.2.5.49 Comment less-than sign bang dash dash state
	//https://html.spec.whatwg.org/multipage/parsing.html#comment-less-than-sign-bang-dash-dash-state
	ch := Consume; // Consume the next input character:
	case ch of 
	$003E, //U+003E GREATER-THAN SIGN (>)
	UEOF:
		begin
			Reconsume(tsCommentEndState); //Reconsume in the comment end state.
		end;
	else
		AddParseError('nested-comment'); //This is a nested-comment parse error. 
		Reconsume(tsCommentEndState); //Reconsume in the comment end state.
	end;
end;

procedure THtmlTokenizer.DoCommentEndDashState;
var
	ch: UCS4Char;
begin
	//13.2.5.50 Comment end dash state
	//https://html.spec.whatwg.org/multipage/parsing.html#comment-end-dash-state
	ch := Consume; // Consume the next input character:
	case ch of
	$002D: //U+002D HYPHEN-MINUS (-)
		begin
			SetState(tsCommentEndState); //Switch to the comment end state.
		end;
	UEOF:
		begin
			AddParseError('eof-in-comment'); //This is an eof-in-comment parse error. 
			EmitCurrentCommentToken; //Emit the current comment token. 
			EmitEndOfFileToken; //Emit an end-of-file token.
		end;
	else
		AppendToCurrentCommentData($002D); //Append a U+002D HYPHEN-MINUS character (-) to the comment token's data. 
		Reconsume(tsCommentState); //Reconsume in the comment state.
	end;
end;

procedure THtmlTokenizer.DoCommentEndState;
var
	ch: UCS4Char;
begin
	//13.2.5.51 Comment end state
	//https://html.spec.whatwg.org/multipage/parsing.html#comment-end-state
	ch := Consume; // Consume the next input character:
	case ch of 
	$003E: //U+003E GREATER-THAN SIGN (>)
		begin
			SetState(tsDataState); //Switch to the data state. 
			EmitCurrentCommentToken; //Emit the current comment token.
		end;
	$0021: //U+0021 EXCLAMATION MARK (!)
		begin
			SetState(tsCommentEndBangState); //Switch to the comment end bang state.
		end;
	$002D: //U+002D HYPHEN-MINUS (-)
		begin
			AppendToCurrentCommentData($002D); //Append a U+002D HYPHEN-MINUS character (-) to the comment token's data.
		end;
	UEOF:
		begin
			AddParseError('eof-in-comment'); //This is an eof-in-comment parse error. 
			EmitCurrentCommentToken; //Emit the current comment token. 
			EmitEndOfFileToken; //Emit an end-of-file token.
		end;
	else
		AppendToCurrentCommentData($002D); //Append two U+002D HYPHEN-MINUS characters (-) to the comment token's data. 
		AppendToCurrentCommentData($002D); //(two!)
		Reconsume(tsCommentState); //Reconsume in the comment state.
	end;
end;

procedure THtmlTokenizer.DoCommentEndBangState;
var
	ch: UCS4Char;
begin
	//13.2.5.52 Comment end bang state
	//https://html.spec.whatwg.org/multipage/parsing.html#comment-end-bang-state
	ch := Consume; // Consume the next input character:
	case ch of
	$002D: //U+002D HYPHEN-MINUS (-)
		begin
			AppendToCurrentCommentData($002D); //Append two U+002D HYPHEN-MINUS characters (-) 
			AppendToCurrentCommentData($002D); //(two!)
			AppendToCurrentCommentData($0021); //and a U+0021 EXCLAMATION MARK character (!) to the comment token's data. 
			
			SetState(tsCommentEndDashState); //Switch to the comment end dash state.
		end;
	$003E: //U+003E GREATER-THAN SIGN (>)
		begin
			AddParseError('incorrectly-closed-comment'); //This is an incorrectly-closed-comment parse error. 
			SetState(tsDataState); //Switch to the data state. 
			EmitCurrentCommentToken; //Emit the current comment token.
		end;
	UEOF:
		begin
			AddParseError('eof-in-comment'); //This is an eof-in-comment parse error. 
			EmitCurrentCommentToken; //Emit the current comment token. 
			EmitEndOfFileToken; //Emit an end-of-file token.
		end;
	else
		AppendToCurrentCommentData($002D); //Append two U+002D HYPHEN-MINUS characters (-) 
		AppendToCurrentCommentData($002D); //(two!)
		AppendToCurrentCommentData($0021); //and a U+0021 EXCLAMATION MARK character (!) to the comment token's data. 
		Reconsume(tsCommentState); //Reconsume in the comment state.
	end;
end;

procedure THtmlTokenizer.DoDOCTYPEState;
var
	ch: UCS4Char;
	token: TDocTypeToken;
begin
	//13.2.5.53 DOCTYPE state
	//https://html.spec.whatwg.org/multipage/parsing.html#doctype-state
	ch := Consume; //consume the next input character
	case ch of
	$0009, $000A, $000C, $0020:
		begin
			//U+0009 CHARACTER TABULATION (tab)
			//U+000A LINE FEED (LF)
			//U+000C FORM FEED (FF)
			//U+0020 SPACE
			SetState(tsBeforeDOCTYPENameState); //Switch to the before DOCTYPE name state.
		end;
	$003E: //U+003E GREATER-THAN SIGN (>)
		begin
			Reconsume(tsBeforeDOCTYPENameState); //Reconsume in the before DOCTYPE name state.
		end;
	UEOF:
		begin
			AddParseError('eof-in-doctype'); //This is an eof-in-doctype parse error.
			token := TDocTypeToken.Create; //Create a new DOCTYPE token.
			token.ForceQuirks := True; //Set its force-quirks flag to on.
			EmitToken(token); //Emit the current token.
			EmitEndOfFileToken; //Emit an end-of-file token.
		end;
	else
		AddParseError('missing-whitespace-before-doctype-name'); //This is a missing-whitespace-before-doctype-name parse error.
		Reconsume(tsBeforeDOCTYPENameState); //Reconsume in the before DOCTYPE name state.
	end;
end;

procedure THtmlTokenizer.DoBeforeDOCTYPENameState;
var
	ch: UCS4Char;
	token: TDocTypeToken;
begin
	//13.2.5.54 Before DOCTYPE name state
	//https://html.spec.whatwg.org/multipage/parsing.html#before-doctype-name-state
{
	QUESTION: U+003E GREATER-THAN SIGN (>) says to create a new doctype token,
				and then to emit the "currenttoken.
				Is the current token the new doctype token we just created,
				or is it previous current token?
}
	ch := Consume;
	if ch in [$0009, $000A, $000C, $0020] then
	begin
		//U+0009 CHARACTER TABULATION (tab)
		//U+000A LINE FEED (LF)
		//U+000C FORM FEED (FF)
		//U+0020 SPACE
		//Ignore the character.
	end
	else if ch in asciiUpperAlpha then
	begin
		token := TDoctypeToken.Create; //Create a new DOCTYPE token.
		token.Name := WideChar(ch + $0020); //Set the token's name to the lowercase version of the current input character (add 0x0020 to the character's code point).
		FCurrentToken := token;
		SetState(tsDOCTYPENameState); //Switch to the DOCTYPE name state.
	end
	else if ch = $0000 then //U+0000 NULL
	begin
		AddParseError('unexpected-null-character'); //This is an unexpected-null-character parse error.
		token := TDocTypeToken.Create; //Create a new DOCTYPE token.
		token.Name := WideChar($FFFD); //Set the token's name to a U+FFFD REPLACEMENT CHARACTER character.
		FCurrentToken := token;
		SetState(tsDOCTYPENameState); //Switch to the DOCTYPE name state.
	end
	else if ch = $003E then //U+003E GREATER-THAN SIGN (>)
	begin
		AddParseError('missing-doctype-name'); //This is a missing-doctype-name parse error.
		token := TDocTypeToken.Create; //Create a new DOCTYPE token.
		token.ForceQuirks := True; //Set its force-quirks flag to on.
		SetState(tsDataState); //Switch to the data state.
		EmitToken(token); //Emit the current token.
	end
	else if ch = UEOF then //EOF
	begin
		AddParseError('eof-in-doctype'); //This is an eof-in-doctype parse error.
		token := TDocTypeToken.Create; //Create a new DOCTYPE token.
		token.ForceQuirks := True; //Set its force-quirks flag to on.
		EmitToken(token); //Emit the current token.
		EmitEndOfFileToken; //Emit an end-of-file token.
	end
	else
	begin
		token := TDocTypeToken.Create; //Create a new DOCTYPE token.
		token.Name := UCS4CharToUnicodeString(FCurrentInputCharacter); //Set the token's name to the current input character.
		SetState(tsDOCTYPENameState); //Switch to the DOCTYPE name state.
	end;
end;

procedure THtmlTokenizer.DoDOCTYPENameState;
var
	ch: UCS4Char;

	function dt: TDocTypeToken;
	begin
		Result := FCurrentToken as TDocTypeToken;
	end;
begin
	//13.2.5.55 DOCTYPE name state
	//https://html.spec.whatwg.org/multipage/parsing.html#doctype-name-state
	ch := Consume; //consume the next input character
	if ch in [$0009, $000A, $000C, $0020] then
	begin
		//U+0009 CHARACTER TABULATION (tab)
		//U+000A LINE FEED (LF)
		//U+000C FORM FEED (FF)
		//U+0020 SPACE
		SetState(tsAfterDOCTYPENameState); //Switch to the after DOCTYPE name state.
	end
	else if ch = $003E then //U+003E GREATER-THAN SIGN (>)
	begin
		SetState(tsDataState); //Switch to the data state.
		EmitCurrentDocTypeToken; //Emit the current DOCTYPE token.
	end
	else if ch in asciiUpperAlpha then
	begin
		dt.AppendName(FCurrentInputCharacter + $0020); //Append the lowercase version of the current input character (add 0x0020 to the character's code point) to the current DOCTYPE token's name.
	end
	else if ch = $0000 then //U+0000 NULL
	begin
		AddParseError('unexpected-null-character'); //This is an unexpected-null-character parse error.
		dt.AppendName($FFFD); //Append a U+FFFD REPLACEMENT CHARACTER character to the current DOCTYPE token's name.
	end
	else if ch = UEOF then
	begin
		AddParseError('eof-in-doctype'); //This is an eof-in-doctype parse error.
		dt.ForceQuirks := True; //Set the current DOCTYPE token's force-quirks flag to on.
		EmitCurrentDoctypeToken; //Emit the current DOCTYPE token.
		EmitEndOfFileToken; //Emit an end-of-file token.
	end
	else
	begin
		dt.AppendName(FCurrentInputCharacter); //Append the current input character to the current DOCTYPE token's name.
	end;
end;

procedure THtmlTokenizer.DoAfterDOCTYPENameState;
var
	ch: UCS4Char;
begin
	//13.2.5.56 After DOCTYPE name state
	//https://html.spec.whatwg.org/multipage/parsing.html#after-doctype-name-state
	ch := Consume; //consume the next input character
	case ch of
	$0009, //U+0009 CHARACTER TABULATION (tab)
	$000A, //U+000A LINE FEED (LF)
	$000C, //U+000C FORM FEED (FF)
	$0020: //U+0020 SPACE
		begin
			//Ignore the character.
		end;
	$003E: //U+003E GREATER-THAN SIGN (>)
		begin
			SetState(tsDataState); //Switch to the data state.
			EmitCurrentDocTypeToken; //Emit the current DOCTYPE token.
		end;
	UEOF:
		begin
			AddParseError('eof-in-doctype'); //This is an eof-in-doctype parse error.
			(FCurrentToken as TDocTypeToken).ForceQuirks := True; //Set the current DOCTYPE token's force-quirks flag to on.
			EmitCurrentDocTypeToken; //Emit the current DOCTYPE token.
			EmitEndOfFileToken; //Emit an end-of-file token.
		end;
	else
		if NextFewCharacters('PUBLIC', False, True) then
		begin
			//If the six characters starting from the current input character
			//are an ASCII case-insensitive match for the word "PUBLIC",

			//then consume those characters
			//Consume; //P  don't consume this; it already is the "current" character.
			Consume; //U
			Consume; //B
			Consume; //L
			Consume; //I
			Consume; //C

			SetState(tsAfterDOCTYPEPublicKeywordState); //and switch to the after DOCTYPE public keyword state.
		end
		else if NextFewCharacters('SYSTEM', False, True) then
		begin
			//if the six characters starting from the current input character
			//are an ASCII case-insensitive match for the word "SYSTEM",

			//then consume those characters
			Consume; //S
			Consume; //Y
			Consume; //S
			Consume; //T
			Consume; //E
			Consume; //M

			SetState(tsAfterDOCTYPESystemKeywordState); //and switch to the after DOCTYPE system keyword state.
		end
		else
		begin
			//Otherwise,
			AddParseError('invalid-character-sequence-after-doctype-name'); //this is an invalid-character-sequence-after-doctype-name parse error.
			(FCurrentToken as TDocTypeToken).ForceQuirks := True; //Set the current DOCTYPE token's force-quirks flag to on.
			Reconsume(tsBogusDOCTYPEState); //Reconsume in the bogus DOCTYPE state.
		end;
	end;
end;

procedure THtmlTokenizer.DoAfterDOCTYPEPublicKeywordState;
var
	ch: UCS4Char;
	function dt: TDocTypeToken;
	begin
		Result := FCurrentToken as TDocTypeToken;
	end;
begin
	//13.2.5.57 After DOCTYPE public keyword state
	//https://html.spec.whatwg.org/multipage/parsing.html#after-doctype-public-keyword-state
	ch := Consume; //Consume the next input character:
	case ch of
	$0009, //U+0009 CHARACTER TABULATION (tab)
	$000A, //U+000A LINE FEED (LF)
	$000C, //U+000C FORM FEED (FF)
	$0020: //U+0020 SPACE
		begin
			SetState(tsBeforeDOCTYPEPublicIdentifierState); //Switch to the before DOCTYPE public identifier state.
		end;
	$0022: //U+0022 QUOTATION MARK (")
		begin
			AddParseError('missing-whitespace-after-doctype-public-keyword'); //This is a missing-whitespace-after-doctype-public-keyword parse error.
			dt.PublicIdentifier := ''; // Set the current DOCTYPE token's public identifier to the empty string (not missing), 
			SetState(tsDOCTYPEPublicIdentifierDoubleQuotedState); //then switch to the DOCTYPE public identifier (double-quoted) state.
		end;
	$0027: //U+0027 APOSTROPHE (')
		begin
			AddParseError('missing-whitespace-after-doctype-public-keyword'); //This is a missing-whitespace-after-doctype-public-keyword parse error.
			dt.PublicIdentifier := ''; // Set the current DOCTYPE token's public identifier to the empty string (not missing), 
			SetState(tsDOCTYPEPublicIdentifierSingleQuotedState); //then switch to the DOCTYPE public identifier (single-quoted) state.
		end;
	$003E: //U+003E GREATER-THAN SIGN (>)
		begin
			AddParseError('missing-doctype-public-identifier'); // This is a missing-doctype-public-identifier parse error. 
			(FCurrentToken as TDocTypeToken).ForceQuirks := True; //Set the current DOCTYPE token's force-quirks flag to on. 
			SetState(tsDataState); //Switch to the data state. 
			EmitCurrentDocTypeToken; //Emit the current DOCTYPE token.
		end;
	UEOF:
		begin
			AddParseError('eof-in-doctype'); //This is an eof-in-doctype parse error. 
			(FCurrentToken as TDocTypeToken).ForceQuirks := True; // Set the current DOCTYPE token's force-quirks flag to on.
			EmitCurrentDocTypeToken; //Emit the current DOCTYPE token. 
			EmitEndOfFileToken; //Emit an end-of-file token.
		end;
	else
		AddParseError('missing-quote-before-doctype-public-identifier'); //This is a missing-quote-before-doctype-public-identifier parse error. 
		(FCurrentToken as TDocTypeToken).ForceQuirks := True; //Set the current DOCTYPE token's force-quirks flag to on. 
		Reconsume(tsBogusDOCTYPEState); //Reconsume in the bogus DOCTYPE state.
	end;
end;

procedure THtmlTokenizer.DoBeforeDOCTYPEPublicIdentifierState;
var
	ch: UCS4Char; 

	function dt: TDocTypeToken;
	begin
		Result := FCurrentToken as TDocTypeToken;	
	end;
begin
	//13.2.5.58 Before DOCTYPE public identifier state
	//https://html.spec.whatwg.org/multipage/parsing.html#before-doctype-public-identifier-state
	ch := Consume; //Consume the next input character:
	case ch of
	$0009, //U+0009 CHARACTER TABULATION (tab)
	$000A, //U+000A LINE FEED (LF)
	$000C, //U+000C FORM FEED (FF)
	$0020: //U+0020 SPACE
		begin
			//Ignore the character.
		end;
	$0022: //U+0022 QUOTATION MARK (")
		begin
			dt.PublicIdentifier := ''; //Set the current DOCTYPE token's public identifier to the empty string (not missing),
			SetState(tsDOCTYPEPublicIdentifierDoubleQuotedState); //then switch to the DOCTYPE public identifier (double-quoted) state.
		end;
	$0027: //U+0027 APOSTROPHE (')
		begin
			dt.PublicIdentifier := ''; //Set the current DOCTYPE token's public identifier to the empty string (not missing), 
			SetState(tsDOCTYPEPublicIdentifierSingleQuotedState); //then switch to the DOCTYPE public identifier (single-quoted) state.
		end;
	$003E: //U+003E GREATER-THAN SIGN (>)
		begin
			AddParseError('missing-doctype-public-identifier'); //This is a missing-doctype-public-identifier parse error. 
			(FCurrentToken as TDocTypeToken).ForceQuirks := True; // the current DOCTYPE token's force-quirks flag to on. 
			SetState(tsDataState); //Switch to the data state. 
			EmitCurrentDocTypeToken; //Emit the current DOCTYPE token.
		end;
	UEOF:
		begin
			AddParseError('eof-in-doctype'); //This is an eof-in-doctype parse error. 
			(FCurrentToken as TDocTypeToken).ForceQuirks := True; //Set the current DOCTYPE token's force-quirks flag to on. 
			EmitCurrentDocTypeToken; // Emit the current DOCTYPE token. 
			EmitEndOfFileToken; //Emit an end-of-file token.
		end;
	else
		AddParseError('missing-quote-before-doctype-public-identifier'); //This is a missing-quote-before-doctype-public-identifier parse error. 
		(FCurrentToken as TDocTypeToken).ForceQuirks := True; //Set the current DOCTYPE token's force-quirks flag to on. 
		Reconsume(tsBogusDOCTYPEState); //Reconsume in the bogus DOCTYPE state.
	end;
end;

procedure THtmlTokenizer.DoDOCTYPEPublicIdentifierDoubleQuotedState;
var
	ch: UCS4Char; 

	function dt: TDocTypeToken;
	begin
		Result := FCurrentToken as TDocTypeToken;
	end;
begin
	//13.2.5.59 DOCTYPE public identifier (double-quoted) state
	//https://html.spec.whatwg.org/multipage/parsing.html#doctype-public-identifier-(double-quoted)-state
	ch := Consume; //Consume the next input character:
	case ch of
	$0022: //U+0022 QUOTATION MARK (")
		begin
			SetState(tsAfterDOCTYPEPublicIdentifierState); //Switch to the after DOCTYPE public identifier state.
		end;
	$0000: //U+0000 NULL
		begin
			AddParseError('unexpected-null-character'); //This is an unexpected-null-character parse error. 
			dt.PublicIdentifier := dt.PublicIdentifier + #$FFFD; // Append a U+FFFD REPLACEMENT CHARACTER character to the current DOCTYPE token's public identifier.
		end;
	$003E: //U+003E GREATER-THAN SIGN (>)
		begin
			AddParseError('abrupt-doctype-public-identifier'); //This is an abrupt-doctype-public-identifier parse error. 
			dt.ForceQuirks := True; // Set the current DOCTYPE token's force-quirks flag to on. 
			SetState(tsDataState); //Switch to the data state. 
			EmitCurrentDocTypeToken; //Emit the current DOCTYPE token.
		end;
	UEOF:
		begin
			AddParseError('eof-in-doctype'); //This is an eof-in-doctype parse error. 
			dt.ForceQuirks := True; //Set the current DOCTYPE token's force-quirks flag to on. 
			EmitCurrentDocTypeToken; //Emit the current DOCTYPE token. 
			EmitEndOfFileToken; //Emit an end-of-file token.
		end;
	else
		//Append the current input character to the current DOCTYPE token's public identifier.
		dt.AppendPublicIdentifier(CurrentInputCharacter);
	end;
end;

procedure THtmlTokenizer.DoDOCTYPEPublicIdentifierSingleQuotedState;
var
	ch: UCS4Char; 

	function dt: TDocTypeToken;
	begin
		Result := FCurrentToken as TDocTypeToken;
	end;
begin
	//13.2.5.60 DOCTYPE public identifier (single-quoted) state
	//https://html.spec.whatwg.org/multipage/parsing.html#doctype-public-identifier-(single-quoted)-state
	ch := Consume; //Consume the next input character:
	case ch of
	$0027: //U+0027 APOSTROPHE (')
		begin
			SetState(tsAfterDOCTYPEPublicIdentifierState); //Switch to the after DOCTYPE public identifier state.
		end;
	$0000: //U+0000 NULL
		begin
			AddParseError('unexpected-null-character'); //This is an unexpected-null-character parse error. 
			dt.PublicIdentifier := dt.PublicIdentifier + #$FFFD; //Append a U+FFFD REPLACEMENT CHARACTER character to the current DOCTYPE token's public identifier.
		end;
	$003E: //U+003E GREATER-THAN SIGN (>)
		begin
			AddParseError('abrupt-doctype-public-identifier'); //This is an abrupt-doctype-public-identifier parse error. 
			dt.ForceQuirks := True; //Set the current DOCTYPE token's force-quirks flag to on. 
			SetState(tsDataState); //Switch to the data state. 
			EmitCurrentDocTypeToken; //Emit the current DOCTYPE token.
		end;
	UEOF:
		begin
			AddParseError('eof-in-doctype'); //This is an eof-in-doctype parse error. 
			dt.ForceQuirks := True; //Set the current DOCTYPE token's force-quirks flag to on. 
			EmitCurrentDocTypeToken; //Emit the current DOCTYPE token. 
			EmitEndOfFileToken; //Emit an end-of-file token.
		end;
	else
		dt.PublicIdentifier := dt.PublicIdentifier + WideChar(FCurrentInputCharacter); //Append the current input character to the current DOCTYPE token's public identifier.
	end;
end;

procedure THtmlTokenizer.DoAfterDOCTYPEPublicIdentifierState;
var	
	ch: UCS4Char;

	function dt: TDocTypeToken;
	begin
		Result := FCurrentToken as TDocTypeToken;
	end;

begin
	//13.2.5.61 After DOCTYPE public identifier state
	//https://html.spec.whatwg.org/multipage/parsing.html#after-doctype-public-identifier-state
	ch := Consume; //Consume the next input character:
	case ch of
	$0009, //U+0009 CHARACTER TABULATION (tab)
	$000A, //U+000A LINE FEED (LF)
	$000C, //U+000C FORM FEED (FF)
	$0020: //U+0020 SPACE
		begin
			SetState(tsBetweenDOCTYPEPublicAndSystemIdentifiersState); //Switch to the between DOCTYPE public and system identifiers state.
		end;
	$003E: //U+003E GREATER-THAN SIGN (>)
		begin
			SetState(tsDataState); //Switch to the data state. 
			EmitCurrentDocTypeToken; //Emit the current DOCTYPE token.
		end;
	$0022: //U+0022 QUOTATION MARK (")
		begin
			AddParseError('missing-whitespace-between-doctype-public-and-system-identifiers'); //This is a missing-whitespace-between-doctype-public-and-system-identifiers parse error. 
			dt.SystemIdentifier := ''; //Set the current DOCTYPE token's system identifier to the empty string (not missing), 
			SetState(tsDOCTYPESystemIdentifierDoubleQuotedState); //then switch to the DOCTYPE system identifier (double-quoted) state.
		end;
	$0027: //U+0027 APOSTROPHE (')
		begin
			AddParseError('missing-whitespace-between-doctype-public-and-system-identifiers'); //This is a missing-whitespace-between-doctype-public-and-system-identifiers parse error. 
			dt.SystemIdentifier := ''; //Set the current DOCTYPE token's system identifier to the empty string (not missing), 
			SetState(tsDOCTYPESystemIdentifierSingleQuotedState); //then switch to the DOCTYPE system identifier (single-quoted) state.
		end;
	UEOF: 
		begin
			AddParseError('eof-in-doctype'); //This is an eof-in-doctype parse error.
			dt.ForceQuirks := True; //Set the current DOCTYPE token's force-quirks flag to on. 
			EmitCurrentDocTypeToken; //Emit the current DOCTYPE token. 
			EmitEndOfFileToken; // Emit an end-of-file token.
		end;
	else
		AddParseError('missing-quote-before-doctype-system-identifier'); //This is a missing-quote-before-doctype-system-identifier parse error. 
		dt.ForceQuirks := True; //Set the current DOCTYPE token's force-quirks flag to on. 
		Reconsume(tsBogusDOCTYPEState); //Reconsume in the bogus DOCTYPE state.
	end;
end;

procedure THtmlTokenizer.DoBetweenDOCTYPEPublicAndSystemIdentifiersState;
var
	ch: UCS4Char;
	function dt: TDocTypeToken;
	begin
		Result := FCurrentToken as TDocTypeToken;	
	end;
begin
	//13.2.5.62 Between DOCTYPE public and system identifiers state
	//https://html.spec.whatwg.org/multipage/parsing.html#between-doctype-public-and-system-identifiers-state
	ch := Consume; //Consume the next input character:
	case ch of
	$0009, //U+0009 CHARACTER TABULATION (tab)
	$000A, //U+000A LINE FEED (LF)
	$000C, //U+000C FORM FEED (FF)
	$0020: //U+0020 SPACE
		begin
			//Ignore the character.
		end;
	$003E: //U+003E GREATER-THAN SIGN (>)
		begin
			SetState(tsDataState); //Switch to the data state. 
			EmitCurrentDocTypeToken; //Emit the current DOCTYPE token.
		end;
	$0022: //U+0022 QUOTATION MARK (")
		begin
			dt.SystemIdentifier := ''; //Set the current DOCTYPE token's system identifier to the empty string (not missing), 
			SetState(tsDOCTYPESystemIdentifierDoubleQuotedState); //then switch to the DOCTYPE system identifier (double-quoted) state.
		end;
	$0027: //U+0027 APOSTROPHE (')
		begin
			dt.SystemIdentifier := ''; //Set the current DOCTYPE token's system identifier to the empty string (not missing), 
			SetState(tsDOCTYPESystemIdentifierSingleQuotedState); //then switch to the DOCTYPE system identifier (single-quoted) state.
		end;
	UEOF:
		begin
			AddParseError('eof-in-doctype'); //This is an eof-in-doctype parse error. 
			dt.ForceQuirks := True; //Set the current DOCTYPE token's force-quirks flag to on. 
			EmitCurrentDocTypeToken; //Emit the current DOCTYPE token. 	
			EmitEndOfFileToken; //Emit an end-of-file token.
		end;
	else
		AddParseError('missing-quote-before-doctype-system-identifier'); //This is a missing-quote-before-doctype-system-identifier parse error. 
		dt.ForceQuirks := True; //Set the current DOCTYPE token's force-quirks flag to on. 
		Reconsume(tsBogusDOCTYPEState); //Reconsume in the bogus DOCTYPE state.
	end;
end;

procedure THtmlTokenizer.DoAfterDOCTYPESystemKeywordState;
var
	ch: UCS4Char;
	
	function dt: TDocTypeToken;
	begin
		Result := FCurrentToken as TDocTypeToken;
	end;
begin
	//13.2.5.63 After DOCTYPE system keyword state
	//https://html.spec.whatwg.org/multipage/parsing.html#after-doctype-system-keyword-state
	ch := Consume; //Consume the next input character:
	case ch of
	$0009, //U+0009 CHARACTER TABULATION (tab)
	$000A, //U+000A LINE FEED (LF)
	$000C, //U+000C FORM FEED (FF)
	$0020: //U+0020 SPACE
		begin
			SetState(tsBeforeDOCTYPESystemIdentifierState); //Switch to the before DOCTYPE system identifier state.
		end;
	$0022: //U+0022 QUOTATION MARK (")
		begin
			AddParseError('missing-whitespace-after-doctype-system-keyword'); //This is a missing-whitespace-after-doctype-system-keyword parse error. 
			dt.SystemIdentifier := ''; //Set the current DOCTYPE token's system identifier to the empty string (not missing), 
			SetState(tsDOCTYPESystemIdentifierDoubleQuotedState); //switch to the DOCTYPE system identifier (double-quoted) state.
		end;
	$0027: //U+0027 APOSTROPHE (')
		begin
			AddParseError('missing-whitespace-after-doctype-system-keyword'); //This is a missing-whitespace-after-doctype-system-keyword parse error. 
			dt.SystemIdentifier := ''; //Set the current DOCTYPE token's system identifier to the empty string (not missing), 
			SetState(tsDOCTYPESystemIdentifierSingleQuotedState); //switch to the DOCTYPE system identifier (single-quoted) state.
		end;
	$003E: //U+003E GREATER-THAN SIGN (>)
		begin
			AddParseError('missing-doctype-system-identifier'); //This is a missing-doctype-system-identifier parse error. 
			dt.ForceQuirks := True; //Set the current DOCTYPE token's force-quirks flag to on. 
			SetState(tsDataState); //Switch to the data state. 
			EmitCurrentDocTypeToken; //Emit the current DOCTYPE token.
		end;
	UEOF:
		begin
			AddParseError('eof-in-doctype'); //This is an eof-in-doctype parse error. 
			dt.ForceQuirks := True; //Set the current DOCTYPE token's force-quirks flag to on. 
			EmitCurrentDoctypeToken; //Emit the current DOCTYPE token. 
			EmitEndOfFileToken; //Emit an end-of-file token.
		end;
	else
		AddParseError('missing-quote-before-doctype-system-identifier'); //This is a missing-quote-before-doctype-system-identifier parse error. 
		dt.ForceQuirks := True; //Set the current DOCTYPE token's force-quirks flag to on. 
		Reconsume(tsBogusDOCTYPEState); //Reconsume in the bogus DOCTYPE state.
	end;
end;

procedure THtmlTokenizer.DoBeforeDOCTYPESystemIdentifierState;
var
	ch: UCS4Char;

	function dt: TDocTypeToken;
	begin
		Result := FCurrentToken as TDocTypeToken;
	end;
begin
	//13.2.5.64 Before DOCTYPE system identifier state
	//https://html.spec.whatwg.org/multipage/parsing.html#before-doctype-system-identifier-state
	ch := Consume; //Consume the next input character:
	case ch of
	$0009, //U+0009 CHARACTER TABULATION (tab)
	$000A, //U+000A LINE FEED (LF)
	$000C, //U+000C FORM FEED (FF)
	$0020: //U+0020 SPACE
		begin
			//Ignore the character.
		end;
	$0022: //U+0022 QUOTATION MARK (")
		begin
			dt.SystemIdentifier := ''; //Set the current DOCTYPE token's system identifier to the empty string (not missing), 
			SetState(tsDOCTYPESystemIdentifierDoubleQuotedState); //switch to the DOCTYPE system identifier (double-quoted) state.
		end;
	$0027: //U+0027 APOSTROPHE (')
		begin
			dt.SystemIdentifier := ''; //Set the current DOCTYPE token's system identifier to the empty string (not missing), 
			SetState(tsDOCTYPESystemIdentifierSingleQuotedState); //switch to the DOCTYPE system identifier (single-quoted) state.	
		end;
	$003E: //U+003E GREATER-THAN SIGN (>)
		begin
			AddParseError('missing-doctype-system-identifier'); //This is a missing-doctype-system-identifier parse error. 
			dt.ForceQuirks := True; //Set the current DOCTYPE token's force-quirks flag to on. 
			SetState(tsDataState); //Switch to the data state. 
			EmitCurrentDoctypeToken; //Emit the current DOCTYPE token.	
		end;
	UEOF:
		begin
			AddParseError('eof-in-doctype'); //This is an eof-in-doctype parse error. 
			dt.ForceQuirks := True; //Set the current DOCTYPE token's force-quirks flag to on. 
			EmitCurrentDoctypeToken; //Emit the current DOCTYPE token. 
			EmitEndOfFileToken; //Emit an end-of-file token.
		end;
	else
		AddParseError('missing-quote-before-doctype-system-identifier'); //This is a missing-quote-before-doctype-system-identifier parse error. 
		dt.ForceQuirks := True; //Set the current DOCTYPE token's force-quirks flag to on. 
		Reconsume(tsBogusDOCTYPEState); //Reconsume in the bogus DOCTYPE state.
	end;
end;

procedure THtmlTokenizer.DoDOCTYPESystemIdentifierDoubleQuotedState;
var
	ch: UCS4Char;

	function dt: TDocTypeToken;
	begin
		Result := FCurrentToken as TDocTypeToken;
	end;
begin
	//13.2.5.65 DOCTYPE system identifier (double-quoted) state
	//https://html.spec.whatwg.org/multipage/parsing.html#doctype-system-identifier-(double-quoted)-state
	ch := Consume; //Consume the next input character:
	case ch of
	$0022: //U+0022 QUOTATION MARK (")
		begin
			SetState(tsAfterDOCTYPESystemIdentifierState); //Switch to the after DOCTYPE system identifier state.
		end;
	$0000: //U+0000 NULL
		begin
			AddParseError('unexpected-null-character'); //This is an unexpected-null-character parse error. 
			dt.SystemIdentifier := dt.SystemIdentifier + #$FFFD; // Append a U+FFFD REPLACEMENT CHARACTER character to the current DOCTYPE token's system identifier.
		end;
	$003E: //U+003E GREATER-THAN SIGN (>)
		begin
			AddParseError('abrupt-doctype-system-identifier'); //This is an abrupt-doctype-system-identifier parse error. 
			dt.ForceQuirks := True; //Set the current DOCTYPE token's force-quirks flag to on. 
			SetState(tsDataState); //Switch to the data state. 
			EmitCurrentDoctypeToken; //Emit the current DOCTYPE token.
		end;
	UEOF:
		begin
			AddParseError('eof-in-doctype'); //This is an eof-in-doctype parse error. 
			dt.ForceQuirks := True; //Set the current DOCTYPE token's force-quirks flag to on. 
			EmitCurrentDoctypeToken; //Emit the current DOCTYPE token. 
			EmitEndOfFileToken; //Emit an end-of-file token.
		end;
	else
		dt.AppendSystemIdentifier(FCurrentInputCharacter); //Append the current input character to the current DOCTYPE token's system identifier.
	end;
end;

procedure THtmlTokenizer.DoDOCTYPESystemIdentifierSingleQuotedState;
var
	ch: UCS4Char;
	function dt: TDocTypeToken;
	begin
		Result := FCurrentToken as TDocTypeToken;
	end;
begin
	//13.2.5.66 DOCTYPE system identifier (single-quoted) state
	//https://html.spec.whatwg.org/multipage/parsing.html#doctype-system-identifier-(single-quoted)-state
	ch := Consume; //Consume the next input character:
	case ch of
	$0027: //U+0027 APOSTROPHE (')
		begin
			SetState(tsAfterDOCTYPESystemIdentifierState); //Switch to the after DOCTYPE system identifier state.
		end;
	$0000: //U+0000 NULL
		begin
			AddParseError('unexpected-null-character'); //This is an unexpected-null-character parse error. 
			dt.AppendSystemIdentifier($FFFD); //Append a U+FFFD REPLACEMENT CHARACTER character to the current DOCTYPE token's system identifier.
		end;
	$003E: //U+003E GREATER-THAN SIGN (>)
		begin
			AddParseError('abrupt-doctype-system-identifier'); //This is an abrupt-doctype-system-identifier parse error. 
			dt.ForceQuirks := True; //Set the current DOCTYPE token's force-quirks flag to on. 
			SetState(tsDataState); //Switch to the data state. 
			EmitCurrentDoctypeToken; //Emit the current DOCTYPE token.
		end;
	UEOF:
		begin
			AddParseError('eof-in-doctype'); //This is an eof-in-doctype parse error. 
			dt.ForceQuirks := True; //Set the current DOCTYPE token's force-quirks flag to on. 
			EmitCurrentDoctypeToken; //Emit the current DOCTYPE token. 
			EmitEndOfFileToken; //Emit an end-of-file token.
		end;
	else
		dt.AppendSystemIdentifier(FCurrentInputCharacter); //Append the current input character to the current DOCTYPE token's system identifier.
	end;
end;

procedure THtmlTokenizer.DoAfterDOCTYPESystemIdentifierState;
var
	ch: UCS4Char;
	function dt: TDocTypeToken;
	begin
		Result := FCurrentToken as TDocTypeToken;
	end;
begin
	//13.2.5.67 After DOCTYPE system identifier state
	//https://html.spec.whatwg.org/multipage/parsing.html#after-doctype-system-identifier-state
	ch := Consume; //Consume the next input character:
	case ch of
	$0009, //U+0009 CHARACTER TABULATION (tab)
	$000A, //U+000A LINE FEED (LF)
	$000C, //U+000C FORM FEED (FF)
	$0020: //U+0020 SPACE
		begin
			//Ignore the character.
		end;
	$003E: //U+003E GREATER-THAN SIGN (>)
		begin
			SetState(tsDataState); //Switch to the data state. 
			EmitCurrentDoctypeToken; //Emit the current DOCTYPE token.
		end;
	UEOF:
		begin
			AddParseError('eof-in-doctype'); //This is an eof-in-doctype parse error. 
			dt.ForceQuirks := True; //Set the current DOCTYPE token's force-quirks flag to on. 
			EmitCurrentDoctypeToken; //Emit the current DOCTYPE token. 
			EmitEndOfFileToken; //Emit an end-of-file token.	
		end;
	else
		AddParseError('unexpected-character-after-doctype-system-identifier'); //This is an unexpected-character-after-doctype-system-identifier parse error. 
		Reconsume(tsBogusDOCTYPEState); //Reconsume in the bogus DOCTYPE state. 	
		//(This does not set the current DOCTYPE token's force-quirks flag to on.)
	end;
end;

procedure THtmlTokenizer.DoBogusDOCTYPEState;
var
	ch: UCS4Char;
begin
	//13.2.5.68 Bogus DOCTYPE state
	//https://html.spec.whatwg.org/multipage/parsing.html#bogus-doctype-state
	ch := Consume; //consume the next input character
	case ch of
	$003E: //U+003E GREATER-THAN SIGN (>)
		begin
			SetState(tsDataState); //Switch to the data state.
			EmitCurrentDocTypeToken; //Emit the DOCTYPE token.
		end;
	$0000: //U+0000 NULL
		begin
			AddParseError('unexpected-null-character'); //This is an unexpected-null-character parse error.
			//Ignore the character.
		end;
	UEOF:
		begin
			EmitCurrentDocTypeToken; //Emit the DOCTYPE token.
			EmitEndOfFileToken; //Emit an end-of-file token.
		end;
	else
		//Ignore the character.
	end;
end;

procedure THtmlTokenizer.DoCDATASectionState;
var
	ch: UCS4Char;
begin
	//13.2.5.69 CDATA section state
	//https://html.spec.whatwg.org/multipage/parsing.html#cdata-section-state
	ch := Consume; //Consume the next input character:
	case ch of
	$005D: //U+005D RIGHT SQUARE BRACKET (])
		begin
			SetState(tsCDATASectionBracketState); //Switch to the CDATA section bracket state.
		end;
	UEOF:
		begin
			AddParseError('eof-in-cdata'); //This is an eof-in-cdata parse error. 
			EmitEndOfFileToken; //Emit an end-of-file token.
		end;
	else
		EmitCharacter(FCurrentInputCharacter); //Emit the current input character as a character token.
	end;
end;

procedure THtmlTokenizer.DoCDATASectionBracketState;
var
	ch: UCS4Char;
begin
	//13.2.5.70 CDATA section bracket state
	//https://html.spec.whatwg.org/multipage/parsing.html#cdata-section-bracket-state
	ch := Consume; //Consume the next input character:
	case ch of 
	$005D: //U+005D RIGHT SQUARE BRACKET (])
		begin
			SetState(tsCDATASectionEndState); //Switch to the CDATA section end state.
		end;
	else
		EmitCharacter($005D); //Emit a U+005D RIGHT SQUARE BRACKET character token.
		Reconsume(tsCDATASectionState); //Reconsume in the CDATA section state.
	end;
end;

procedure THtmlTokenizer.DoCDATASectionEndState;
var
	ch: UCS4Char;
begin
	//13.2.5.71 CDATA section end state
	//https://html.spec.whatwg.org/multipage/parsing.html#cdata-section-end-state
	ch := Consume; //Consume the next input character:
	case ch of
	$005D: //U+005D RIGHT SQUARE BRACKET (])
		begin
			EmitCharacter($005D); //Emit a U+005D RIGHT SQUARE BRACKET character token.
		end;
	$003E: //U+003E GREATER-THAN SIGN character
		begin
			SetState(tsDataState); //Switch to the data state.
		end;
	else
		EmitCharacter($005D); //Emit two U+005D RIGHT SQUARE BRACKET character tokens. 
		EmitCharacter($005D); //(two!)
		Reconsume(tsCDataSEctionState); //Reconsume in the CDATA section state.
	end;
end;

procedure THtmlTokenizer.DoCharacterReferenceState;
var
	ch: UCS4Char;
begin
	//13.2.5.72 Character reference state
	//https://html.spec.whatwg.org/multipage/parsing.html#character-reference-state

	//Set the temporary buffer to the empty string.
	SetLength(FTemporaryBuffer, 0);
	AppendToTemporaryBuffer($0026); //Append a U+0026 AMPERSAND (&) character to the temporary buffer.

	ch := Consume; //Consume the next input character
	if ch in asciiAlphaNumeric then
	begin
		Reconsume(tsNamedCharacterReferenceState); //Reconsume in the named character reference state.
	end
	else if ch = $0023 then //U+0023 NUMBER SIGN (#)
	begin
		AppendToTemporaryBuffer(FCurrentInputCharacter); //Append the current input character to the temporary buffer.
		SetState(tsNumericCharacterReferenceState); //Switch to the numeric character reference state.
	end
	else
	begin
		//Flush code points consumed as a character reference.
		FlushCodePointsConsumed;
		Reconsume(FReturnState2); //Reconsume in the return state.
	end;
end;

procedure THtmlTokenizer.DoNamedCharacterReferenceState;
begin
	//13.2.5.73 Named character reference state
	//https://html.spec.whatwg.org/multipage/parsing.html#named-character-reference-state

{
	Consume the maximum number of characters possible,
	where the consumed characters are one of the identifiers in the first column
	of the named character references table.
	Append each character to the temporary buffer when it's consumed.
}
	//TODO: this whole thing
(*
	consumed := '';
	match := False;
	repeat
		ch := Consume;
		if ch > $FFFF then
			Break;
		match :=

	If there is a match
		If the character reference was consumed as part of an attribute,
		and the last character matched is not a U+003B SEMICOLON character (;),
		and the next input character is either a U+003D EQUALS SIGN character (=) or
		an ASCII alphanumeric, then, for historical reasons, flush code points consumed as a character reference and switch to the return state.

		Otherwise:
			1. If the last character matched is not a U+003B SEMICOLON character (;),
				then this is a missing-semicolon-after-character-reference parse error.
			2. Set the temporary buffer to the empty string.
				Append one or two characters corresponding to the character reference name
				(as given by the second column of the named character references table)
				to the temporary buffer.
			3. Flush code points consumed as a character reference.
				Switch to the return state.
	Otherwise
		Flush code points consumed as a character reference.
		Switch to the ambiguous ampersand state.
*)
end;

procedure THtmlTokenizer.DoAmbiguousAmpersandState;
var
	ch: UCS4Char;
begin
	//13.2.5.74 Ambiguous ampersand state
	//https://html.spec.whatwg.org/multipage/parsing.html#ambiguous-ampersand-state
	ch := Consume; //Consume the next input character:
	if ch in asciiAlphanumeric then
	begin
		//If the character reference was consumed as part of an attribute, then 
		if IsConsumedAsPartOfAnAttribute then
			CurrentTagToken.CurrentAttributeValue := CurrentTagToken.CurrentAttributeValue + UCS4CharToUnicodeString(FCurrentInputCharacter) //append the current input character to the current attribute's value. 
		else
			EmitCharacter(FCurrentInputCharacter); //emit the current input character as a character token.
	end
	else if ch = $003B then //U+003B SEMICOLON (;)
	begin
		AddParseError('unknown-named-character-reference'); //This is an unknown-named-character-reference parse error. 
		Reconsume(FReturnState2); //Reconsume in the return state.
	end
	else
		Reconsume(FReturnState2); //Reconsume in the return state.
end;

procedure THtmlTokenizer.DoNumericCharacterReferenceState;
var
	ch: UCS4Char;
begin
	//13.2.5.75 Numeric character reference state
	//https://html.spec.whatwg.org/multipage/parsing.html#numeric-character-reference-state
	FCharacterReferenceCode := 0; //Set the character reference code to zero (0).
	ch := Consume; //Consume the next input character:
	case ch of
	$0078, //U+0078 LATIN SMALL LETTER X
	$0058: //U+0058 LATIN CAPITAL LETTER X
		begin
			AppendToTemporaryBuffer(FCurrentInputCharacter); //Append the current input character to the temporary buffer.
			SetState(tsHexadecimalCharacterReferenceStartState); //Switch to the hexadecimal character reference start state.
		end;
	else
		Reconsume(tsDecimalCharacterReferenceStartState); //Reconsume in the decimal character reference start state.
	end;
end;

procedure THtmlTokenizer.DoHexadecimalCharacterReferenceStartState;
var
	ch: UCS4Char;
begin
	//13.2.5.76 Hexadecimal character reference start state
	//https://html.spec.whatwg.org/multipage/parsing.html#hexadecimal-character-reference-start-state
	ch := Consume; //Consume the next input character:
	if ch in asciiHexDigit then
	begin
		Reconsume(tsHexadecimalCharacterReferenceState); //Reconsume in the hexadecimal character reference state.
	end
	else
	begin
		AddParseError('absence-of-digits-in-numeric-character-reference'); //This is an absence-of-digits-in-numeric-character-reference parse error. 
		FlushCodePointsConsumed; //Flush code points consumed as a character reference. 
		Reconsume(FReturnState2); //Reconsume in the return state.
	end;
end;

procedure THtmlTokenizer.DoDecimalCharacterReferenceStartState;
var
	ch: UCS4Char;
begin
	//13.2.5.77 Decimal character reference start state
	//https://html.spec.whatwg.org/multipage/parsing.html#decimal-character-reference-start-state
	ch := Consume; //Consume the next input character:
	if ch in asciiDigit then
	begin
		Reconsume(tsDecimalCharacterReferenceState); //Reconsume in the decimal character reference state.
	end
	else
	begin
		AddParseError('absence-of-digits-in-numeric-character-reference'); //This is an absence-of-digits-in-numeric-character-reference parse error. 
		FlushCodePointsConsumed; //Flush code points consumed as a character reference. 
		Reconsume(FReturnState2); //Reconsume in the return state.
	end;
end;

procedure THtmlTokenizer.DoHexadecimalCharacterReferenceState;
var
	ch: UCS4Char;
begin
	//13.2.5.78 Hexadecimal character reference state
	//https://html.spec.whatwg.org/multipage/parsing.html#hexadecimal-character-reference-state
	ch := Consume; //Consume the next input character:
	if ch in asciiDigit then
	begin
		FCharacterReferenceCode := FCharacterReferenceCode * 16; //Multiply the character reference code by 16. 
		FCharacterReferenceCode := FCharacterReferenceCode + (ch - $0030); //Add a numeric version of the current input character (subtract 0x0030 from the character's code point) to the character reference code.
	end
	else if ch in asciiUpperHexDigit then
	begin
		FCharacterReferenceCode := FCharacterReferenceCode * 16; //Multiply the character reference code by 16. 
		FCharacterReferenceCode := FCharacterReferenceCode + (ch - $0037); //Add a numeric version of the current input character as a hexadecimal digit (subtract 0x0037 from the character's code point) to the character reference code.
	end
	else if ch in asciiLowerHexDigit then
	begin
		FCharacterReferenceCode := FCharacterReferenceCode * 16; //Multiply the character reference code by 16. 
		FCharacterReferenceCode := FCharacterReferenceCode + (ch - $0057); //Add a numeric version of the current input character as a hexadecimal digit (subtract 0x0057 from the character's code point) to the character reference code.
	end
	else if ch = $003B then //U+003B SEMICOLON
	begin
		SetState(tsNumericCharacterReferenceEndState); //Switch to the numeric character reference end state.
	end
	else
	begin
		AddParseError('missing-semicolon-after-character-reference'); //This is a missing-semicolon-after-character-reference parse error.
		Reconsume(tsNumericCharacterReferenceEndState); //Reconsume in the numeric character reference end state.
	end;
end;

procedure THtmlTokenizer.DoDecimalCharacterReferenceState;
var
	ch: UCS4Char;
begin
	//13.2.5.79 Decimal character reference state
	//https://html.spec.whatwg.org/multipage/parsing.html#decimal-character-reference-state
	ch := Consume; //Consume the next input character:
	if ch in asciiDigit then
	begin
		FCharacterReferenceCode := FCharacterReferenceCode * 10; //Multiply the character reference code by 10. 
		FCharacterReferenceCode := FCharacterReferenceCode + (ch - $0030); //Add a numeric version of the current input character (subtract 0x0030 from the character's code point) to the character reference code.
	end
	else if ch = $003B then // U+003B SEMICOLON
	begin
		SetState(tsNumericCharacterReferenceEndState); //Switch to the numeric character reference end state.
	end
	else
	begin
		AddParseError('missing-semicolon-after-character-reference'); //This is a missing-semicolon-after-character-reference parse error. 
		Reconsume(tsNumericCharacterReferenceEndState); //Reconsume in the numeric character reference end state.
	end;
end;

procedure THtmlTokenizer.DoNumericCharacterReferenceEndState;
begin
	//13.2.5.80 Numeric character reference end state
	//https://html.spec.whatwg.org/multipage/parsing.html#numeric-character-reference-end-state
(*
Check the character reference code:

If the number is 0x00, then this is a null-character-reference parse error. Set the character reference code to 0xFFFD.

If the number is greater than 0x10FFFF, then this is a character-reference-outside-unicode-range parse error. Set the character reference code to 0xFFFD.

If the number is a surrogate, then this is a surrogate-character-reference parse error. Set the character reference code to 0xFFFD.

If the number is a noncharacter, then this is a noncharacter-character-reference parse error.

If the number is 0x0D, or a control that's not ASCII whitespace, then this is a control-character-reference parse error. If the number is one of the numbers in the first column of the following table, then find the row with that number in the first column, and set the character reference code to the number in the second column of that row.

Number	Code point
0x80	0x20AC	EURO SIGN (€)
0x82	0x201A	SINGLE LOW-9 QUOTATION MARK (‚)
0x83	0x0192	LATIN SMALL LETTER F WITH HOOK (ƒ)
0x84	0x201E	DOUBLE LOW-9 QUOTATION MARK („)
0x85	0x2026	HORIZONTAL ELLIPSIS (…)
0x86	0x2020	DAGGER (†)
0x87	0x2021	DOUBLE DAGGER (‡)
0x88	0x02C6	MODIFIER LETTER CIRCUMFLEX ACCENT (ˆ)
0x89	0x2030	PER MILLE SIGN (‰)
0x8A	0x0160	LATIN CAPITAL LETTER S WITH CARON (Š)
0x8B	0x2039	SINGLE LEFT-POINTING ANGLE QUOTATION MARK (‹)
0x8C	0x0152	LATIN CAPITAL LIGATURE OE (Œ)
0x8E	0x017D	LATIN CAPITAL LETTER Z WITH CARON (Ž)
0x91	0x2018	LEFT SINGLE QUOTATION MARK (‘)
0x92	0x2019	RIGHT SINGLE QUOTATION MARK (’)
0x93	0x201C	LEFT DOUBLE QUOTATION MARK (“)
0x94	0x201D	RIGHT DOUBLE QUOTATION MARK (”)
0x95	0x2022	BULLET (•)
0x96	0x2013	EN DASH (–)
0x97	0x2014	EM DASH (—)
0x98	0x02DC	SMALL TILDE (˜)
0x99	0x2122	TRADE MARK SIGN (™)
0x9A	0x0161	LATIN SMALL LETTER S WITH CARON (š)
0x9B	0x203A	SINGLE RIGHT-POINTING ANGLE QUOTATION MARK (›)
0x9C	0x0153	LATIN SMALL LIGATURE OE (œ)
0x9E	0x017E	LATIN SMALL LETTER Z WITH CARON (ž)
0x9F	0x0178	LATIN CAPITAL LETTER Y WITH DIAERESIS (Ÿ)
Set the temporary buffer to the empty string. Append a code point equal to the character reference code to the temporary buffer. Flush code points consumed as a character reference. Switch to the return state.
*)
	AddNotImplementedParseError('NumericCharacterReferenceEndState');
end;

procedure THtmlTokenizer.EmitCharacter(const Character: UCS4Char);
var
	token: TCharacterToken;
begin
	//Emit a character token.
	token := TCharacterToken.Create;
	token.Data := Character;

	EmitToken(token);
end;

procedure THtmlTokenizer.EmitCurrentCommentToken;
begin
	//Emit the current token - which is assumed to be a Comment token.
	EmitToken(FCurrentToken as TCommentToken);
end;

procedure THtmlTokenizer.EmitCurrentTagToken;
begin
	//Emit the current token - which is assumed to be a either a StartTag or EndTag token.
	if FCurrentToken = nil then
		raise Exception.Create('EmitCurrentTagToken expected a current token');

	if FCurrentToken is TStartTagToken then
		EmitStartTag
	else if FCurrentToken is TEndTagToken then
		EmitEndTag
	else
		raise Exception.CreateFmt('EmitCurrentTagToken expected the current token to be a tag (was %s)', [FCurrentToken.ClassName]);
end;

procedure THtmlTokenizer.EmitCurrentDocTypeToken;
begin
	//Emit the current token - which is assumed to be a DOCTYPE token.
	EmitToken(FCurrentToken as TDocTypeToken);
end;

procedure THtmlTokenizer.EmitEndOfFileToken;
var
	token: TEndOfFileToken;
begin
	//Emit an End Of File token.
	token := TEndOfFileToken.Create;
	EmitToken(token);
end;

procedure THtmlTokenizer.EmitEndTag;
var
	token: TEndTagToken;
begin
{
	Emit the current token - which is assumed to be a EndTag token.
}
	token := FCurrentToken as TEndTagToken;
	if token = nil then 
		raise Exception.Create('Cannot emit end tag: CurrentToken is nil');

	//When an end tag token is emitted with attributes, 
	//that is an end-tag-with-attributes parse error.
	if token.Attributes.Count > 0 then
		AddParseError('end-tag-with-attributes');

	//When an end tag token is emitted with its self-closing flag set, 
	//that is an end-tag-with-trailing-solidus parse error.
	if token.SelfClosing then
		AddParseError('end-tag-with-trailing-solidus');

	EmitToken(token);
end;

procedure THtmlTokenizer.EmitStartTag;
var
	startTag: TStartTagToken;
begin
{
	Emit the current token - which is assumed to be a StartTag token.
}
	if not (FCurrentToken is TStartTagToken) then
		raise EConvertError.CreateFmt('Cannot cast %s object to type TStartTagToken', [FCurrentToken.ClassName]);

	startTag := FCurrentToken as TStartTagToken;
	startTag.FinalizeAttributeName;
	EmitToken(startTag);

{
	https://html.spec.whatwg.org/multipage/parsing.html#acknowledge-self-closing-flag

	When a start tag token is emitted with its [self-closing flag] set,
	if the flag is not **acknowledged** when it is processed by the tree construction stage,
	that is a [non-void-html-element-start-tag-with-trailing-solidus] [parse error].
}
	//I *guess* the tree builder acknowledges it by clearing the self-closing boolean?
	//I suppose there could also be some sort of StartTag.AcknowledgeSelfClosingFlag
	if startTag.SelfClosing = True then
		AddParseError('non-void-html-element-start-tag-with-trailing-solidus');
end;

procedure THtmlTokenizer.EmitToken(const AToken: THtmlToken);
begin
	if Assigned(FOnToken) then
		FOnToken(Self, AToken);
end;

procedure THtmlTokenizer.FlushCodePointsConsumed;
var
	i: Integer;
begin
{
	https://html.spec.whatwg.org/multipage/parsing.html#flush-code-points-consumed-as-a-character-reference

	When a state says to **flush code points consumed as a character reference**,
	it means that for each [code point] in the [temporary buffer]
	(in the order they were added to the buffer)
	user agent must append the code point from the buffer
	to the current attribute's value if the character reference was [consumed as part of an attribute],
	or emit the code point as a character token otherwise.
}
	if IsConsumedAsPartOfAnAttribute then
	begin
		for i := 0 to Length(FTemporaryBuffer)-1 do
			CurrentTagToken.CurrentAttributeValue := CurrentTagToken.CurrentAttributeValue + UCS4CharToUnicodeString(FTemporaryBuffer[i]);
	end
	else
	begin
{
		TODO: Implementation question. It says append all the character to the current attribute vulue,
		but it says otherwise emit the code point (singular) as a character token.
		Am i only emitting one character from the Temporary buffer? 
		Am i emitting all characters from the temporary buffer?
		Or am i only to emit the *"current input character"*
}
		for i := 0 to Length(FTemporaryBuffer)-1 do
			CurrentTagToken.CurrentAttributeValue := CurrentTagToken.CurrentAttributeValue + UCS4CharToUnicodeString(FTemporaryBuffer[i]);

	end;
end;

function THtmlTokenizer.GetCurrentTagToken: TTagToken;
begin
	Result := FCurrentToken as TTagToken;
end;

function THtmlTokenizer.GetNext: UCS4Char;
var
	res: Boolean;
begin
	res := FStream.TryRead({out}Result);
	if not res then
	begin
		Result := UEOF;
		FEOF := True;
		Exit;
	end;
end;

procedure THtmlTokenizer.Initialize;
begin
	FStream := nil;
	FState2 := tsDataState; //The state machine must start in the data state.
	FCurrentInputCharacter := MaxInt; //UCS4 doesn't allow negative, so we use $FFFFFFFF
end;

function THtmlTokenizer.IsAppropriateEndTag(const EndTagToken: TEndTagToken): Boolean;
begin
{
	https://html.spec.whatwg.org/multipage/parsing.html#appropriate-end-tag-token
	
	An **appropriate end tag token** is an end tag token whose 
	tag name matches the tag name of the last start tag to have been emitted from this tokenizer,
	if any. 
	If no start tag has been emitted from this tokenizer, 
	then no end tag token is appropriate.
}
	if EndTagToken = nil then
		raise EArgumentNilException.Create('EndTagToken');

	//TODO: Implementator's question: Should the tag name comparison case sensitive?
	Result := SameText(FNameOfLastEmittedStartTag, EndTagToken.TagName);
end;

function THtmlTokenizer.IsConsumedAsPartOfAnAttribute: Boolean;
begin
{
	https://html.spec.whatwg.org/multipage/parsing.html#charref-in-attribute
	
	A [character reference] is said to be **consumed as part of an attribute**
	if the return state is either 

		- [attribute value (double-quoted) state], 
		- [attribute value (single-quoted) state] or 
		- [attribute value (unquoted) state].
}
	Result := FReturnState2 in [
			tsAttributeValueDoubleQuotedState, 
			tsAttributeValueSingleQuotedState,
			tsAttributeValueUnquotedState];
end;

procedure THtmlTokenizer.Reconsume(NewTokenizerState: TTokenizerState);
begin
{
	When a state says to reconsume a matched character in a specified state,
	that means to switch to that state,
	but when it attempts to consume the next input character,
	provide it with the current input character instead.
}
	FReconsume := True;
	SetState(NewTokenizerState);
end;

procedure THtmlTokenizer.SetState(const State: TTokenizerState);
begin
	FState2 := State;

	LogFmt('    ==> %s', [TypInfo.GetEnumName(TypeInfo(TTokenizerState), Ord(State))]);
end;

function THtmlTokenizer.TemporaryBufferIs(const Value: UnicodeString): Boolean;
var
	tb: UnicodeString;
begin
	tb := UCS4StringToUnicodeString(FTemporaryBuffer);
		
	Result := SameText(tb, Value); //TODO: Implementor's question: should this be case sensitive?	
end;

procedure THtmlTokenizer.SetReturnState(const State: TTokenizerState);
begin
	FReturnState2 := State;

	LogFmt('    ReturnState ==> %s', [TypInfo.GetEnumName(TypeInfo(TTokenizerState), Ord(State))]);
end;

{ TCharacterReader }

function TInputStream.Consume: UCS4Char;
begin
{
	Extract the next character from our (possibly buffered) stream.
}
	//Get the next character from the ring buffer
	if FBufferSize > 0 then
	begin
		Result := FBuffer[FBufferPosition];
		Inc(FBufferPosition);
		if FBufferPosition >= Length(FBuffer) then //the ring part of ring-buffer
			FBufferPosition := 0;
		Dec(FBufferSize);
		Exit;
	end;

	Result := GetNextCharacterFromStream;
end;

constructor TInputStream.Create(ByteStream: ISequentialStream; Encoding: Word);
begin
	inherited Create;

	FStream := ByteStream;
	FEncoding := Encoding;
	FEOF := False;

	//FBuffer is a ring-buffer, with the current position at "FBufferPosition"
	//and there is FBufferSize valid characters
	SetLength(FBuffer, 1024);
	FBufferSize := 0;
	FBufferPosition := 0;
end;

function TInputStream.FetchNextCharacterInfoBuffer: Boolean;
var
	ch: UCS4Char;
	n: Integer;
begin
	ch := Self.GetNextCharacterFromStream;
	if ch = UEOF then
	begin
		Result := False;
		Exit;
	end;

	n := FBufferPosition + FBufferSize;
	if n > Length(FBuffer) then
		n := 0;
	FBuffer[n] := ch;
	Inc(FBufferSize);
	Result := True;
end;

function TInputStream.GetNextCharacterFromStream: UCS4Char;
begin
	case FEncoding of
	CP_UTF16: Result := Self.GetNextUTF16Character
	else
		raise Exception.Create('Unknown encoding');
	end;
end;

function TInputStream.GetNextUTF16Character: UCS4Char;
var
	wh, wl: Word;
	hr: HRESULT;
	cbRead: FixedUInt;
begin
{
	Get the next UTF-16 character from the stream.

	NOTE:	The next input character could be larger than 16-bits.
			That's because Unicode characters are larger than 16-bits.
			The common bug in .NET TextReader is that it will return a surrogate,
			rather than the actual character, if the character's numeric value is larger than 16-bits.

			For that reason we can't use TextReader/StreamReader/StringReader.
}
	hr := FStream.Read(@wh, sizeof(Word), @cbRead);
	OleCheck(hr);
	if hr = S_FALSE then
	begin
		Result := UEOF;
//		FEOF := True;	can't set this yet. We're not *really* at the end, because we might be peeking. Have to save setting EOF until we officially read it
		Exit;
	end;

	if IsSurrogate(wh) then
	begin
		//It's a surrogate pair. Read the 2nd character
		hr := FStream.Read(@wl, sizeof(Word), nil);
		OleCheck(hr);
		if hr = S_FALSE then //If we couldn't read it, then it's nonsense anyway
		begin
			//Invalid surrogate pair: the pair is missing
			FEOF := True;
			wl := $DC00; //so that when we subtract $DC00 it becomes zero (really: so that it doesn't become negative)
		end;

		wh := (wh - $D800) * $400;
		wl := (wl - $DC00);
		Result := wh+wl;
		Exit;
	end;

	//It's a regular-old character.
	Result := wh;
end;

constructor TInputStream.Create(const Html: UnicodeString);
var
	stream: TStream;
	stm: ISequentialStream;
begin
	stream := TStringStream.Create(Html, CP_UTF16);
	stm := TFixedStreamAdapter.Create(stream, soOwned) as IStream;

	Self.Create(stm, CP_UTF16);
end;

function TInputStream.IsSurrogate(const n: Word): Boolean;
begin
	case n of
	$D800..$DFFF: Result := True;
	else
		Result := False;
	end;
end;

function TInputStream.Peek(k: Integer): UCS4Char;
begin
//	Return the k-th character (e.g. 1st, 2nd, 3rd) without popping it.

{
	Ensure the ring buffer has at least k characters
	If k<n, that means k-th character is in the buffer.
	Then return the k-th character from the buffer.
}
	while k > FBufferSize do
	begin
		//If k > n, that means k-th character is not in the buffer.
		//Read up to the k-th character and add it to the buffer.
		//Since already n characters are in the buffer,
		//total k-n number of characters will be read.
		//Then return the k-th character from the buffer.
		if not FetchNextCharacterInfoBuffer then
		begin
			Result := UEOF;
			Exit;
		end;
	end;

	Result := FBuffer[FBufferPosition+(k-1)];

	LogFmt('    Peek: [%s]', []);
end;

procedure TInputStream.LogFmt(const s: string; const Args: array of const);
begin

end;

function TInputStream.TryRead(out ch: UCS4Char): Boolean;
begin
{
	Read the next unicode character from the input stream.
}
	Result := False;
	ch := Consume;

	if ch = UEOF then
	begin
		FEOF := True;
		Exit;
	end;

	//U+000D CARRIAGE RETURN (CR)
	if ch = $000D then
	begin
		{
			U+000D CARRIAGE RETURN (CR) characters and U+000A LINE FEED (LF) characters
			are treated specially.
		}
		if Peek(1) = $000A then //U+000A LINE FEED (LF)
		begin
			{
			Any LF character that immediately follows a CR character must be ignored,
			and all CR characters must then be converted to LF characters.
			Thus, newlines in HTML DOMs are represented by LF characters,
			and there are never any CR characters in the input to the tokenization stage.
			}
			Consume;
		end;
		ch := $000A; //U+000A LINE FEED (LF)
	end;

	Result := True;
end;

{ THtmlParser }

constructor THtmlParser.Create;
begin
	inherited Create;

	FInsertionMode := imInitial; //Initially, the insertion mode is "initial".
	FOriginalInsertionMode := imInitial;
	FActiveFormattingElements := TElementStack.Create;

	FHead := nil;
	FForm := nil;
end;

procedure THtmlParser.Log(const s: string);
begin
	OutputDebugString(PChar(s));
end;

class function THtmlParser.Parse(const HtmlStr: TDomString): TDocument;
var
	parser: THtmlParser;
begin
	parser := THtmlParser.Create;
	try
		Result := parser.ParseString(HtmlStr);
	finally
		parser.Free;
	end;
end;

function THtmlParser.ParseString(const htmlStr: TDomString): TDocument;
begin
	FTokenizer := THtmlTokenizer.Create(HtmlStr);
	FTokenizer.OnToken := ProcessToken;

	if FHtmlDocument <> nil then
		FreeAndNil(FHtmlDocument);

	FHtmlDocument := TDocument.Create;
	FTokenizer.Parse;
	Result := FHtmlDocument;
end;

procedure THtmlParser.ProcessDocTypeToken(AToken: TDocTypeToken);
begin
	Log('    ==> Emitted token DOCTYPE: '+AToken.Name);
end;

procedure THtmlParser.ProcessStartTagToken(AToken: TStartTagToken);
var
	s: string;
	i: Integer;
begin
	s := '<'+AToken.TagName;
	for i := 0 to AToken.Attributes.Count-1 do
		s := s+' key="value"';
	s := s+'>';

	Log('    ==> Emitted token StartTag: '+s);
end;

procedure THtmlParser.ProcessEndTagToken(AToken: TEndTagToken);
begin
	Log('    ==> Emitted token EndTag: </'+AToken.TagName+'>');
end;

procedure THtmlParser.ProcessCommentToken(AToken: TCommentToken);
begin
	Log('    ==> Emitted token #comment: '+AToken.DataString);
end;

procedure THtmlParser.ProcessCharacterToken(AToken: TCharacterToken);
begin
	Log('    ==> Emitted token #character: '+StringReplace(AToken.DataString, #$A, #$21b5, [rfReplaceAll]));
end;

procedure THtmlParser.ProcessEndOfFileToken(AToken: TEndOfFileToken);
begin
	Log('    ==> Emitted token End-of-file');
end;

procedure THtmlParser.ProcessToken(Sender: TObject; AToken: THtmlToken);
begin
	if AToken = nil then
		raise EArgumentNilException.Create('AToken');

	case AToken.TokenType of
	ttDocType: ProcessDocTypeToken(AToken as TDocTypeToken);		//DOCTYPE
	ttStartTag: ProcessStartTagToken(AToken as TStartTagToken);	//start tag
	ttEndTag: ProcessEndTagToken(AToken as TEndTagToken);		//end tag
	ttComment: ProcessCommentToken(AToken as TCommentToken);		//comment
	ttCharacter: ProcessCharacterToken(AToken as TCharacterToken);	//character
	ttEndOfFile: ProcessEndOfFileToken(AToken as TEndOfFileToken);	//end-of-file
	else
		raise Exception.CreateFmt('Unknown token type: %s', [AToken.ClassName]);
	end;
end;

procedure THtmlParser.ResetTheInsertionModeAppropriately;
var
	last: Boolean;
	node: TNode;
	nodeIndex: Integer;
	ancestorIndex: Integer;
	ancestor: TNode;
begin
{
	https://html.spec.whatwg.org/#reset-the-insertion-mode-appropriately

	When the steps below require the UA to **reset the insertion mode appropriately**,
	it means the UA must follow these steps:
}
	//last := False;

	nodeIndex := FOpenElements.Count-1;

	while True do
	begin
		node := FOpenElements.Items[nodeIndex];
		last := (nodeIndex = 0);

		case HtmlTagList.GetTagID(node.NodeName) of
		SELECT_TAG:
			begin
				if not last then
				begin
					ancestorIndex := nodeIndex;
					//ancestor := node;
					repeat
						if (ancestorIndex = 0) then
							Break;
						Dec(ancestorIndex);
						ancestor := FOpenElements[ancestorIndex];
						if SameText(ancestor.NodeName, 'TEMPLATE') then
							Break;
						if SameText(ancestor.NodeName, 'TABLE') then
						begin
							SetInsertionMode(imInSelectInTable);
							Exit;
						end;
					until (False);
				end;
				SetInsertionMode(imInSelect);
				Exit;
			end;
		TD_TAG, TH_TAG:
			begin
				if not last then
				begin
					SetInsertionMode(imInCell);
					Exit;
				end;
			end;
		TR_TAG:
			begin
				SetInsertionMode(imInRow);
				Exit;
			end;
		TBODY_TAG, THEAD_TAG, TFOOT_TAG:
			begin
				SetInsertionMode(imInTableBody);
				Exit;
			end;
		CAPTION_TAG:
			begin
				SetInsertionMode(imInCaption);
				Exit;
			end;
		COLGROUP_TAG:
			begin
				SetInsertionMode(imInColumnGroup);
				Exit;
			end;
		TABLE_TAG:
			begin
				SetInsertionMode(imInTable);
				Exit;
			end;
		TEMPLATE_TAG:
			begin
				SetInsertionMode(imInTemplate);
				Exit;
			end;
		HEAD_TAG:
			begin
				if not last then
				begin
					SetInsertionMode(imInHead);
					Exit;
				end;
			end;
		BODY_TAG:
			begin
				SetInsertionMode(imInBody);
				Exit;
			end;
		FRAMESET_TAG:
			begin
				SetInsertionMode(imInFrameset);
				Exit;
			end;
		HTML_TAG:
			begin
				if FHead = nil then
				begin
					SetInsertionMode(imBeforeHead);
					Exit;
				end
				else
				begin
					SetInsertionMode(imAfterHead);
					Exit;
				end;
			end;
		else
			if last then
			begin
				SetInsertionMode(imInBody);
				Exit;
			end;
		end;

		Dec(nodeIndex);
	end;
end;

procedure THtmlParser.SetInsertionMode(const Mode: TInsertionMode);
begin
{
	The insertion mode is a state variable that controls the primary operation of the tree construction stage.

	Initially, the insertion mode is "initial". It can change to

	- "before html"
	- "before head"
	- "in head"
	- "in head noscript"
	- "after head"
	- "in body"
	- "text"
	- "in table"
	- "in table text"
	- "in caption"
	- "in column group"
	- "in table body"
	- "in row"
	- "in cell"
	- "in select"
	- "in select in table"
	- "in template"
	- "after body",
	- "in frameset",
	- "after frameset",
	- "after after body",
	- "after after frameset"

	during the course of the parsing, as described in the tree construction stage.

	The insertion mode affects how tokens are processed and whether CDATA sections are supported.

	Several of these modes, namely "in head", "in body", "in table", and "in select", are special,
	in that the other modes defer to them at various times.

	When the algorithm below says that the user agent is to do something
	"using the rules for the m insertion mode", where m is one of these modes,
	the user agent must use the rules described under the m insertion mode's section,
	but must leave the insertion mode unchanged unless the rules in m themselves
	switch the insertion mode to a new value.
}
	FInsertionMode := Mode;
end;

{ TElementStack }

function TElementStack.BottomMost: TElement;
begin
	if Self.Count > 0 then
		Result := Self.Items[Count-1]
	else
		Result := nil;
end;

constructor TElementStack.Create;
begin
	inherited Create;
end;

function TElementStack.GetItems(Index: Integer): TElement;
begin
	Result := TObject(Self.Get(Index)) as TElement;
end;

function TElementStack.TopMost: TElement;
begin
	if Self.Count > 0 then
		Result := Self.Items[0]
	else
		Result := nil;
end;

{ TDocTypeToken }

procedure TDocTypeToken.AppendName(const ch: UCS4Char);
begin
	FName := FName + UCS4CharToUnicodeString(ch);
end;

procedure TDocTypeToken.AppendPublicIdentifier(const ch: UCS4Char);
begin
	FPublicIdentifier := FPublicIdentifier + UCS4CharToUnicodeString(ch);
end;

procedure TDocTypeToken.AppendSystemIdentifier(const ch: UCS4Char);
begin
	FSystemIdentifier := FSystemIdentifier + UCS4CharToUnicodeString(ch);
end;

constructor TDocTypeToken.Create;
begin
	inherited Create(ttDocType);

{
	When a DOCTYPE token is created, its
	name, public identifier, and system identifier
	must be marked as missing (which is a distinct state from the empty string),

	and the force-quirks flag must be set to off (its other state is on).
}
	FNameMissing := True;
	FPublicIdentifierMissing := True;
	FSystemIdentifierMissing := True;

	ForceQuirks := False;
end;

procedure TDocTypeToken.SetName(const Value: UnicodeString);
begin
	FName := Value;
	FNameMissing := False;
end;

procedure TDocTypeToken.SetPublicIdentifier(const Value: UnicodeString);
begin
	FPublicIdentifier := Value;
	FPublicIdentifierMissing := False;
end;

procedure TDocTypeToken.SetSystemIdentifier(const Value: UnicodeString);
begin
	FSystemIdentifier := Value;
	FSystemIdentifierMissing := False;
end;

{ TEndTagToken }

constructor TEndTagToken.Create;
begin
	inherited Create(ttEndTag);
end;

{ TStartTagToken }

constructor TStartTagToken.Create;
begin
	inherited Create(ttStartTag);
end;

{ THtmlToken }

constructor THtmlToken.Create(ATokenType: THtmlTokenType);
begin
	inherited Create;

	Self.TokenType := ATokenType;
end;

{ TCommentToken }

procedure TCommentToken.AppendCharacter(const ch: UCS4Char);
begin
	if ch > $FFFF then
		raise Exception.CreateFmt('Attempt to add extended character (%d) to comment token', [ch]);

	UCS4StrCat({var}FData, ch);
end;

constructor TCommentToken.Create;
begin
	inherited Create(ttComment);
end;

function TCommentToken.GetDataString: UnicodeString;
begin
	Result := UCS4ToUnicodeString(FData);
end;

{ TCharacterToken }

constructor TCharacterToken.Create;
begin
	inherited Create(ttCharacter);
end;

function TCharacterToken.GetDataString: UnicodeString;
var
	s: UCS4String;
begin
	SetLength(s, 1);
	s[0] := Self.Data;
	Result := UCS4StringToUnicodeString(s);
end;

{ TEndOfFileToken }

constructor TEndOfFileToken.Create;
begin
	inherited Create(ttEndOfFile);
end;


{ TFixedStreamAdapter }

function TFixedStreamAdapter.Read(pv: Pointer; cb: FixedUInt; pcbRead: PFixedUInt): HResult;
var
	bytesRead: FixedUInt;
begin
	try
		if pv = nil then
		begin
			Result := STG_E_INVALIDPOINTER; //One of the pointer values is invalid.
			Exit;
		end;

		bytesRead := Self.Stream.Read(pv^, cb);
		if pcbRead <> nil then
			pcbRead^ := bytesRead;

		//FIX: IStream must return S_FALSE if the number of bytes read is less than the number of bytes requested in cb.
		if bytesRead < cb then
		begin
			Result := S_FALSE;
			Exit;
		end;

		Result := S_OK;
	except
		Result := E_FAIL; //And we don't return S_FALSE (success) for an error, we return an error.
	end;
end;

function UCS4ToUnicodeString(const S: UCS4String): UnicodeString;
var
  I: Integer;
  CharCount: Integer;
  Tmp: array of WideChar; //should be
begin
  SetLength(Tmp, Length(S) * 2 - 1); //Maximum possible number of characters
  CharCount := -1;

  I := 0;
  while I <= Length(S)-1 do //FIX: less OR EQUAL than
  begin
    if S[I] >= $10000 then
    begin
		Inc(CharCount);
      Tmp[CharCount] := WideChar((((S[I] - $00010000) shr 10) and $000003FF) or $D800);
      Inc(CharCount);
      Tmp[CharCount] := WideChar(((S[I] - $00010000) and $000003FF)or $DC00);
    end
    else
	 begin
		Inc(CharCount);
		Tmp[CharCount] := WideChar(S[I]);
	 end;

	 Inc(I);
  end;

  SetString(Result, PChar(Tmp), CharCount + 1);
end;

procedure UCS4StrCat(var Dest: UCS4String; const Source: UCS4Char);
var
	n: Integer;
begin
{
	Concatenate two strings:

		Dest := Dest + Source;
}
	n := Length(Dest);
	SetLength(Dest, n+1);
	Dest[n] := Source;
end;

procedure UCS4StrFromChar(var Dest: UCS4String; const Source: UCS4Char);
begin
{
	Convert a single UCS4Char into a UCS4String.

	Similar to:
		System._UStrFromChar		UnicodeString <== AnsiChar
		System._UStrFromWChar	UnicodeString <== WideChar

		System._WStrFromChar		WideString    <== AnsiChar
		System._WStrFromWChar	WideString
}
	SetLength(Dest, 1);//
	Dest[0] := Source;
end;

procedure UCS4StrFromUStr(var Dest: UCS4String; const Source: UnicodeString);
var
	i: Integer;
	wh, wl: Word;
	ch: UCS4Char;
	n: Integer;

begin
	if Source = '' then
	begin
		SetLength(Dest, 0);
		Exit;
	end;

	i := 1;
	while i <= Length(Source) do
	begin
		wl := Word(Source[i]);

		//Check if wl is a surrogate apir
		case wl of
		$D800..$DFFF:
			begin
				//Is it a surrogate pair.
				//Push wl to the upper word, and read the lower word
				wh := (wl - $D800) * $400;
				if (i+1) <= Length(Source) then
					wl := Word(Source[i+1])
				else
					wl := 0;
				ch := wh+wl;
			end;
		else
			ch := wl;
		end;
		n := Length(Dest);
		SetLength(Dest, n+1);
		Dest[n] := ch;
	end;
end;

function UCS4StrCopy(const S: UCS4String; Index, Count: Integer): UCS4String; //similar to System._UStrCopy
begin
	Result := Copy(S, Index-1, Count);
end;

procedure UCS4StrFromPUCS4CharLen(var Dest: UCS4String; Source: PUCS4Char; CharLength: Integer); //similar to System._UStrFromPWCharLen
begin
	SetLength(Dest, CharLength);

	Move(Source^, Dest[0], CharLength*sizeof(UCS4Char));
end;

function UCS4CharToUnicodeString(const ch: UCS4Char): UnicodeString; //either 1 or 2 WideChar
var
	s: UCS4String;
begin
	UCS4StrFromChar({var}s, ch);

	Result := UCS4StringToUnicodeString(s);
end;

{ TTagToken }

procedure TTagToken.AppendCharacter(const ch: UCS4Char);
begin
	if ch > $FFFF then
		raise Exception.CreateFmt('Attempt to add extended character (%d) to tag token', [ch]);

	UCS4StrCat(FData, ch);	
end;

constructor TTagToken.Create(ATokenType: THtmlTokenType);
begin
	inherited Create(ATokenType);

	FSelfClosing := False; //self-closing flag must be unset (its other state is that it be set)
	FAttributes := TList.Create; //and its attributes list must be empty.
end;

destructor TTagToken.Destroy;
begin
	FreeAndNil(FAttributes);

	inherited;
end;

procedure TTagToken.FinalizeAttributeName;
begin
{
	TODO: When the user agent leaves the attribute name state
	(and before emitting the tag token, if appropriate),
	the complete attribute's name must be compared to the other attributes on the same token;
	if there is already an attribute on the token with the exact same name,
	then this is a duplicate-attribute parse error
	and the new attribute must be removed from the token.
}
end;

function TTagToken.GetTagName: UnicodeString;
begin
	Result := UCS4ToUnicodeString(FData); 
end;

procedure TTagToken.NewAttribute;
begin
	CurrentAttributeName := ''; 
	CurrentAttributeValue := '';
end;

end.
