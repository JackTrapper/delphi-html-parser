unit HtmlParser;

interface

uses
	ActiveX, Classes, SysUtils, Contnrs,
	DomCore, Entities, HtmlTokenizer;

type
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


{
	Initially, the stack of open elements is empty.
	The stack grows downwards; the topmost node on the stack is the first one added to the stack,
	and the bottommost node of the stack is the most recently added node in the stack
	(notwithstanding when the stack is manipulated in a random access fashion as part of the handling for misnested tags).
}
	TElementStack = class(TList)
	private
		function GetItems(Index: Integer): TElement;
		function GetIsEmpty: Boolean;
	public
		constructor Create;
		function TopMost: TElement;
		function BottomMost: TElement;
		procedure Pop;
		property Items[Index: Integer]: TElement read GetItems;
		property IsEmpty: Boolean read GetIsEmpty;
	end;

	THtmlParser = class
	private
		FHtmlDocument: TDocument;

		{ State }
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

		procedure AddParseError(const s: UnicodeString); overload;
		procedure AddParseError(const Token: THtmlToken; ErrorMessage: string=''); overload;
		procedure ResetTheInsertionModeAppropriately;
		procedure SetInsertionMode(const Mode: TInsertionMode); // used to handle mis-nested formatting element tags.
		function CreateElementForToken(const Node: THtmlToken): TElement;
		procedure InsertComment(const Token: THtmlToken; Parent: TNode=nil);
		procedure InsertCharacter(const Token: THtmlToken; Parent: TNode=nil);
		procedure InsertAnHtmlElement(const Token: THtmlToken; Parent: TNode=nil);

		procedure AddMarkerToActiveFormattingElements;

		procedure GenericParsingAlgorithm(const Token: THtmlToken; NextTokenizerState: TTokenizerState);
			procedure GenericRCDATAElementParsingAlgorithm(const Token: THtmlToken; Parent: TNode);

		procedure AddNotImplementedParseError(const InsertionModeHandlerName: string);
		function TextIs(const Left: UnicodeString; const Right: array of UnicodeString): Boolean;

		procedure ProcessNodeAccordingToInsertionMode(const Node: THtmlToken; AInsertionMode: TInsertionMode);

		procedure DoInitialInsertionMode(Node: THtmlToken); 				//13.2.6.4.1 The "initial" insertion mode
		procedure DoBeforeHtmlInsertionMode(Node: THtmlToken);			//13.2.6.4.2 The "before html" insertion mode
		procedure DoBeforeHeadInsertionMode(Node: THtmlToken);			//13.2.6.4.3 The "before head" insertion mode
		procedure DoInHeadInsertionMode(Node: THtmlToken);					//13.2.6.4.4 The "in head" insertion mode
		procedure DoInHeadNoscriptInsertionMode(Node: THtmlToken);		//13.2.6.4.5 The "in head noscript" insertion mode
		procedure DoAfterHeadInsertionMode(Node: THtmlToken);				//13.2.6.4.6 The "after head" insertion mode
		procedure DoInBodyInsertionMode(Node: THtmlToken);					//13.2.6.4.7 The "in body" insertion mode
		procedure DoTextInsertionMode(Node: THtmlToken);					//13.2.6.4.8 The "text" insertion mode
		procedure DoInTableInsertionMode(Node: THtmlToken);				//13.2.6.4.9 The "in table" insertion mode
		procedure DoInTableTextInsertionMode(Node: THtmlToken);			//13.2.6.4.10 The "in table text" insertion mode
		procedure DoInCaptionInsertionMode(Node: THtmlToken);				//13.2.6.4.11 The "in caption" insertion mode
		procedure DoInColumnGroupInsertionMode(Node: THtmlToken);		//13.2.6.4.12 The "in column group" insertion mode
		procedure DoInTableBodyInsertionMode(Node: THtmlToken);			//13.2.6.4.13 The "in table body" insertion mode
		procedure DoInRowInsertionMode(Node: THtmlToken);					//13.2.6.4.14 The "in row" insertion mode
		procedure DoInCellInsertionMode(Node: THtmlToken);					//13.2.6.4.15 The "in cell" insertion mode
		procedure DoInSelectInsertionMode(Node: THtmlToken);				//13.2.6.4.16 The "in select" insertion mode
		procedure DoInSelectInTableInsertionMode(Node: THtmlToken);		//13.2.6.4.17 The "in select in table" insertion mode
		procedure DoInTemplateInsertionMode(Node: THtmlToken);			//13.2.6.4.18 The "in template" insertion mode
		procedure DoAfterBodyInsertionMode(Node: THtmlToken);				//13.2.6.4.19 The "after body" insertion mode
		procedure DoInFramesetInsertionMode(Node: THtmlToken);			//13.2.6.4.20 The "in frameset" insertion mode
		procedure DoAfterFramesetInsertionMode(Node: THtmlToken);		//13.2.6.4.21 The "after frameset" insertion mode
		procedure DoAfterAfterBodyInsertionMode(Node: THtmlToken);		//13.2.6.4.22 The "after after body" insertion mode
		procedure DoAfterAfterFrameseInsertionMode(Node: THtmlToken);  //13.2.6.4.23 The "after after frameset" insertion mode
	protected
		function ParseString(const htmlStr: TDomString): TDocument;

		procedure ProcessToken(Sender: TObject; AToken: THtmlToken);

		property Document: TDocument read FHtmlDocument;
	public
		constructor Create;
		destructor Destroy; override;

		class function Parse(const HtmlStr: TDomString): TDocument;

		property Scripting: Boolean read FScripting write FScripting;
		property FramesetOK: Boolean read FFramesetOK;
	end;

implementation

uses
	Windows, TypInfo, ComObj,
	HtmlParserTests,
	HtmlTags;

{ THtmlParser }

constructor THtmlParser.Create;
begin
	inherited Create;

	FInsertionMode := imInitial; //Initially, the insertion mode is "initial".
	FOriginalInsertionMode := imInitial;
	FActiveFormattingElements := TElementStack.Create;
	FOpenElements := TElementStack.Create;
	FScripting := False;

	FHead := nil;
	FForm := nil;
end;

procedure THtmlParser.AddParseError(const s: UnicodeString);
begin
	Log('Parse-Error: '+s);
end;

procedure THtmlParser.AddParseError(const Token: THtmlToken; ErrorMessage: string='');
var
	s: string;
begin
{
	The error you're having is that this Token type is not allowed in the current insertion mode
}
	if ErrorMessage = '' then
		ErrorMessage := 'Token not allowed in insertion mode %s';

	s := '';
	if Token <> nil then
		s := Token.ClassName;

	AddParseError(s+' '+ErrorMessage);
end;

procedure THtmlParser.AddNotImplementedParseError(const InsertionModeHandlerName: string);
begin
	AddParseError('not-implemented-'+InsertionModeHandlerName);
	raise ENotImplemented.Create(InsertionModeHandlerName);
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
		parser.Scripting := False;
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

procedure THtmlParser.ProcessToken(Sender: TObject; AToken: THtmlToken);
begin
	if AToken = nil then
		raise EArgumentNilException.Create('AToken');

	Log('    ==> Emitted token '+AToken.Description);

	ProcessNodeAccordingToInsertionMode(AToken, FInsertionMode);
end;

procedure THtmlParser.ProcessNodeAccordingToInsertionMode(const Node: THtmlToken; AInsertionMode: TInsertionMode);
begin
	case AInsertionMode of
	imInitial:					DoInitialInsertionMode(Node); 				//"initial"
	imBeforeHtml:				DoBeforeHtmlInsertionMode(Node); 			//"before html"
	imBeforeHead:				DoBeforeHeadInsertionMode(Node); 			//"before head"
	imInHead:					DoInHeadInsertionMode(Node); 					//"in head"
	imInHeadNoscript:			DoInHeadNoscriptInsertionMode(Node);		//"in head no script"
	imAfterHead:				DoAfterHeadInsertionMode(Node);				//"after head",
	imInBody:					DoInBodyInsertionMode(Node);					//"in body",
	imText:						DoTextInsertionMode(Node);						//"text",
	imInTable:					DoInTableInsertionMode(Node);					//"in table",
	imInTableText:				DoInTableTextInsertionMode(Node);			//"in table text",
	imInCaption:				DoInCaptionInsertionMode(Node);				//"in caption",
	imInColumnGroup:			DoInColumnGroupInsertionMode(Node);			//"in column group",
	imInTableBody:				DoInTableBodyInsertionMode(Node);			//"in table body",
	imInRow:						DoInRowInsertionMode(Node);					//"in row",
	imInCell:					DoInCellInsertionMode(Node);					//"in cell",
	imInSelect:					DoInSelectInsertionMode(Node);				//"in select",
	imInSelectInTable:		DoInSelectInTableInsertionMode(Node);		//"in select in table",
	imInTemplate:				DoInTemplateInsertionMode(Node);				//"in template",
	imAfterBody:				DoAfterBodyInsertionMode(Node);			  	//"after body",
	imInFrameset:				DoInFramesetInsertionMode(Node);				//"in frameset",
	imAfterFrameset:			DoAfterFramesetInsertionMode(Node);			//"after frameset",
	imAfterAfterBody:			DoAfterAfterBodyInsertionMode(Node);		//"after after body",
	imAfterAfterFrameset:  	DoAfterAfterFrameseInsertionMode(Node);	//"after after frameset"
	else
		raise Exception.Create('Unknown insertion mode');
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

//*** Insertion Mode Handlers ***

procedure THtmlParser.DoInitialInsertionMode(Node: THtmlToken);
var
	dt: TDocTypeToken;
	doctype: TDocumentType;
begin
	//13.2.6.4.1 The "initial" insertion mode
	//https://html.spec.whatwg.org/multipage/parsing.html#the-initial-insertion-mode

	//A Document object has an associated parser cannot change the mode flag (a boolean).
	//It is initially false.

	//A character token that is one of U+0009 CHARACTER TABULATION, U+000A LINE FEED (LF), U+000C FORM FEED (FF), U+000D CARRIAGE RETURN (CR), or U+0020 SPACE
	if (node is TCharacterToken) and TextIs((node as TCharacterToken).Data, [#$0009, #$000A, #$000C, #$000D, #$0020]) then
	begin
		//ignore the token
	end
	else if (node is TCommentToken) then
	begin
		//Insert a comment as the last child of the Document object.
		InsertComment(node, Document);
	end
	else if (node is TDocTypeToken) then
	begin
		dt := Node as TDocTypeToken;
		if (not SameText(dt.Name, 'html')) then
			AddParseError('DOCTYPE name is not "html"')
		else if (not dt.PublicIdentifierMissing) then
			AddParseError('DOCTYPE public identifier is not missing')
		else if (not dt.SystemIdentifierMissing) then
		begin
			if not SameText(dt.SystemIdentifier, 'about:legacy-compat') then
				AddParseError('DOCTYPE system identifier is not missing or "about:legacy-compat"');
		end;

{		Append a DocumentType node to the Document node,
		with its name set to the name given in the DOCTYPE token,
		or the empty string if the name was missing;
		its public ID set to the public identifier given in the DOCTYPE token,
		or the empty string if the public identifier was missing;
		and its system ID set to the system identifier given in the DOCTYPE token,
		or the empty string if the system identifier was missing.
}
		docType := DomImplementation.createDocumentType(dt.Name, dt.PublicIdentifier, dt.SystemIdentifier);
		Document.AppendChild(docType);

{
		TODO:
		Then, if the document is not an iframe srcdoc document, and the parser cannot change the mode flag is false, and the DOCTYPE token matches one of the conditions in the following list, then set the Document to quirks mode:

		The force-quirks flag is set to on.
		The name is not "html".
		The public identifier is set to: "-//W3O//DTD W3 HTML Strict 3.0//EN//"
		The public identifier is set to: "-/W3C/DTD HTML 4.0 Transitional/EN"
		The public identifier is set to: "HTML"
		The system identifier is set to: "http://www.ibm.com/data/dtd/v11/ibmxhtml1-transitional.dtd"
		The public identifier starts with: "+//Silmaril//dtd html Pro v0r11 19970101//"
		The public identifier starts with: "-//AS//DTD HTML 3.0 asWedit + extensions//"
		The public identifier starts with: "-//AdvaSoft Ltd//DTD HTML 3.0 asWedit + extensions//"
		The public identifier starts with: "-//IETF//DTD HTML 2.0 Level 1//"
		The public identifier starts with: "-//IETF//DTD HTML 2.0 Level 2//"
		The public identifier starts with: "-//IETF//DTD HTML 2.0 Strict Level 1//"
		The public identifier starts with: "-//IETF//DTD HTML 2.0 Strict Level 2//"
		The public identifier starts with: "-//IETF//DTD HTML 2.0 Strict//"
		The public identifier starts with: "-//IETF//DTD HTML 2.0//"
		The public identifier starts with: "-//IETF//DTD HTML 2.1E//"
		The public identifier starts with: "-//IETF//DTD HTML 3.0//"
		The public identifier starts with: "-//IETF//DTD HTML 3.2 Final//"
		The public identifier starts with: "-//IETF//DTD HTML 3.2//"
		The public identifier starts with: "-//IETF//DTD HTML 3//"
		The public identifier starts with: "-//IETF//DTD HTML Level 0//"
		The public identifier starts with: "-//IETF//DTD HTML Level 1//"
		The public identifier starts with: "-//IETF//DTD HTML Level 2//"
		The public identifier starts with: "-//IETF//DTD HTML Level 3//"
		The public identifier starts with: "-//IETF//DTD HTML Strict Level 0//"
		The public identifier starts with: "-//IETF//DTD HTML Strict Level 1//"
		The public identifier starts with: "-//IETF//DTD HTML Strict Level 2//"
		The public identifier starts with: "-//IETF//DTD HTML Strict Level 3//"
		The public identifier starts with: "-//IETF//DTD HTML Strict//"
		The public identifier starts with: "-//IETF//DTD HTML//"
		The public identifier starts with: "-//Metrius//DTD Metrius Presentational//"
		The public identifier starts with: "-//Microsoft//DTD Internet Explorer 2.0 HTML Strict//"
		The public identifier starts with: "-//Microsoft//DTD Internet Explorer 2.0 HTML//"
		The public identifier starts with: "-//Microsoft//DTD Internet Explorer 2.0 Tables//"
		The public identifier starts with: "-//Microsoft//DTD Internet Explorer 3.0 HTML Strict//"
		The public identifier starts with: "-//Microsoft//DTD Internet Explorer 3.0 HTML//"
		The public identifier starts with: "-//Microsoft//DTD Internet Explorer 3.0 Tables//"
		The public identifier starts with: "-//Netscape Comm. Corp.//DTD HTML//"
		The public identifier starts with: "-//Netscape Comm. Corp.//DTD Strict HTML//"
		The public identifier starts with: "-//O'Reilly and Associates//DTD HTML 2.0//"
		The public identifier starts with: "-//O'Reilly and Associates//DTD HTML Extended 1.0//"
		The public identifier starts with: "-//O'Reilly and Associates//DTD HTML Extended Relaxed 1.0//"
		The public identifier starts with: "-//SQ//DTD HTML 2.0 HoTMetaL + extensions//"
		The public identifier starts with: "-//SoftQuad Software//DTD HoTMetaL PRO 6.0::19990601::extensions to HTML 4.0//"
		The public identifier starts with: "-//SoftQuad//DTD HoTMetaL PRO 4.0::19971010::extensions to HTML 4.0//"
		The public identifier starts with: "-//Spyglass//DTD HTML 2.0 Extended//"
		The public identifier starts with: "-//Sun Microsystems Corp.//DTD HotJava HTML//"
		The public identifier starts with: "-//Sun Microsystems Corp.//DTD HotJava Strict HTML//"
		The public identifier starts with: "-//W3C//DTD HTML 3 1995-03-24//"
		The public identifier starts with: "-//W3C//DTD HTML 3.2 Draft//"
		The public identifier starts with: "-//W3C//DTD HTML 3.2 Final//"
		The public identifier starts with: "-//W3C//DTD HTML 3.2//"
		The public identifier starts with: "-//W3C//DTD HTML 3.2S Draft//"
		The public identifier starts with: "-//W3C//DTD HTML 4.0 Frameset//"
		The public identifier starts with: "-//W3C//DTD HTML 4.0 Transitional//"
		The public identifier starts with: "-//W3C//DTD HTML Experimental 19960712//"
		The public identifier starts with: "-//W3C//DTD HTML Experimental 970421//"
		The public identifier starts with: "-//W3C//DTD W3 HTML//"
		The public identifier starts with: "-//W3O//DTD W3 HTML 3.0//"
		The public identifier starts with: "-//WebTechs//DTD Mozilla HTML 2.0//"
		The public identifier starts with: "-//WebTechs//DTD Mozilla HTML//"
		The system identifier is missing and the public identifier starts with: "-//W3C//DTD HTML 4.01 Frameset//"
		The system identifier is missing and the public identifier starts with: "-//W3C//DTD HTML 4.01 Transitional//"
		Otherwise, if the document is not an iframe srcdoc document, and the parser cannot change the mode flag is false, and the DOCTYPE token matches one of the conditions in the following list, then then set the Document to limited-quirks mode:

		The public identifier starts with: "-//W3C//DTD XHTML 1.0 Frameset//"
		The public identifier starts with: "-//W3C//DTD XHTML 1.0 Transitional//"
		The system identifier is not missing and the public identifier starts with: "-//W3C//DTD HTML 4.01 Frameset//"
		The system identifier is not missing and the public identifier starts with: "-//W3C//DTD HTML 4.01 Transitional//"
		The system identifier and public identifier strings must be compared to the values given in the lists above in an ASCII case-insensitive manner. A system identifier whose value is the empty string is not considered missing for the purposes of the conditions above.
		}

		SetInsertionMode(imBeforeHtml);
	end
	else
	begin
	{
		TODO: If the document is not [an iframe srcdoc] document,
				then this is a parse error;
			if the [parser cannot change the mode flag] is false,
					set the Document to [quirks mode].
	}

		SetInsertionMode(imBeforeHtml); //In any case, switch the insertion mode to "before html",
		ProcessNodeAccordingToInsertionMode(node, FInsertionMode); //then reprocess the token.
	end;
end;

procedure THtmlParser.DoBeforeHtmlInsertionMode(Node: THtmlToken);
var
	element: TElement;
begin
	//13.2.6.4.2 The "before html" insertion mode
	//https://html.spec.whatwg.org/multipage/parsing.html#the-before-html-insertion-mode
	if Node is TDocTypeToken then
	begin
		AddParseError('doctype node in BeforeHtml insertion mode');
	end
	else if Node is TCommentToken then
	begin
		//Insert a comment as the last child of the Document object.
		InsertComment(Node, Document);
	end
	else if (Node is TCharacterToken) and TextIs((Node as TCharacterToken).Data, [#$0009, #$000A, #$000C, #$000D, #$0020]) then
	begin
		//Ignore the token
	end
	else if (Node is TStartTagToken) and ((Node as TStartTagToken).TagName = 'html') then
	begin
		element := CreateElementForToken(Node);
		Document.AppendChild(element);
		FOpenElements.Add(element);

		SetInsertionMode(imBeforeHead);
	end;
end;

procedure THtmlParser.DoBeforeHeadInsertionMode(Node: THtmlToken);
begin
	//13.2.6.4.3 The "before head" insertion mode
	//https://html.spec.whatwg.org/multipage/parsing.html#the-before-head-insertion-mode
	AddNotImplementedParseError('DoBeforeHeadInsertionMode');
{
When the user agent is to apply the rules for the "before head" insertion mode, the user agent must handle the token as follows:

A character token that is one of U+0009 CHARACTER TABULATION, U+000A LINE FEED (LF), U+000C FORM FEED (FF), U+000D CARRIAGE RETURN (CR), or U+0020 SPACE
Ignore the token.

A comment token
Insert a comment.

A DOCTYPE token
Parse error. Ignore the token.

A start tag whose tag name is "html"
Process the token using the rules for the "in body" insertion mode.

A start tag whose tag name is "head"
Insert an HTML element for the token.

Set the head element pointer to the newly created head element.

Switch the insertion mode to "in head".

An end tag whose tag name is one of: "head", "body", "html", "br"
Act as described in the "anything else" entry below.

Any other end tag
Parse error. Ignore the token.

Anything else
Insert an HTML element for a "head" start tag token with no attributes.

Set the head element pointer to the newly created head element.

Switch the insertion mode to "in head".

Reprocess the current token.
}
end;

procedure THtmlParser.DoInHeadInsertionMode(Node: THtmlToken);

	function IsStartTag(const List: array of UnicodeString): Boolean;
	begin
		if not (Node is TStartTagToken) then
		begin
			Result := False;
			Exit;
		end;

		if Length(List) = 0 then
		begin
			Result := True;
			Exit;
		end;

		Result := TextIs((Node as TStartTagToken).TagName, List);
	end;

	function IsEndTag(const List: array of UnicodeString): Boolean;
	begin
		if not (Node is TEndTagToken) then
		begin
			Result := False;
			Exit;
		end;

		if Length(List) = 0 then
		begin
			Result := True;
			Exit;
		end;

		Result := TextIs((Node as TEndTagToken).TagName, List);
	end;

	procedure AnythingElse;
	begin
		FOpenElements.Pop; //Pop the current node (which will be the head element) off the stack of open elements.
		SetInsertionMode(imAfterHead); // Switch the insertion mode to "after head".
		ProcessNodeAccordingToInsertionMode(node, FInsertionMode); //Reprocess the token.
	end;

	procedure InsertScriptElement;
	begin
{
		Run these steps:

Let the adjusted insertion location be the appropriate place for inserting a node.

Create an element for the token in the HTML namespace, with the intended parent being the element in which the adjusted insertion location finds itself.

Set the element's parser document to the Document, and unset the element's "non-blocking" flag.

This ensures that, if the script is external, any document.write() calls in the script will execute in-line, instead of blowing the document away, as would happen in most other cases. It also prevents the script from executing until the end tag is seen.

If the parser was created as part of the HTML fragment parsing algorithm, then mark the script element as "already started". (fragment case)

If the parser was invoked via the document.write() or document.writeln() methods, then optionally mark the script element as "already started". (For example, the user agent might use this clause to prevent execution of cross-origin scripts inserted via document.write() under slow network conditions, or when the page has already taken a long time to load.)

Insert the newly created element at the adjusted insertion location.

Push the element onto the stack of open elements so that it is the new current node.

Switch the tokenizer to the script data state.

Let the original insertion mode be the current insertion mode.

Switch the insertion mode to "text".
}
		raise ENotImplemented.Create('InsertScriptElemetn');
	end;

	function st: TStartTagToken;
	begin
		Result := (node as TStartTagToken);
	end;
begin
	//13.2.6.4.4 The "in head" insertion mode
	//https://html.spec.whatwg.org/multipage/parsing.html#parsing-main-inhead
	AddNotImplementedParseError('DoInHeadInsertionMode');

	if (node is TCharacterToken) and TextIs((node as TCharacterToken).Data, [#$0009, #$000A, #$000C, #$000D, #$0020]) then
	begin
		//A character token that is one of U+0009 CHARACTER TABULATION, U+000A LINE FEED (LF), U+000C FORM FEED (FF), U+000D CARRIAGE RETURN (CR), or U+0020 SPACE
		InsertCharacter(Node); //Insert the character.
	end
	else if node is TCommentToken then
	begin
		InsertComment(Node, nil); //Insert a comment.
	end
	else if node is TDocTypeToken then
	begin
		AddParseError(Node); //Parse error.
		//Ignore the token.
	end
	else if IsStartTag(['html']) then
	begin
		//A start tag whose tag name is "html"
		//Process the token using the rules for the "in body" insertion mode.
		ProcessNodeAccordingToInsertionMode(node, imInBody);
	end
	else if IsStartTag(['base', 'basefont', 'bgsound', 'link']) then
	begin
		//A start tag whose tag name is one of: "base", "basefont", "bgsound", "link"
		//Insert an HTML element for the token.
		InsertAnHtmlElement(node);

		//Immediately pop the current node off the stack of open elements.
		FOpenElements.Pop;

		 //Acknowledge the token's self-closing flag, if it is set.
		if (node as TStartTagToken).SelfClosing then
			(node as TStartTagToken).AcknowledgeSelfClosing;
	end
	else if IsStartTag(['meta']) then
	begin
		//A start tag whose tag name is "meta"
		InsertAnHtmlElement(node); //Insert an HTML element for the token

		FOpenElements.Pop; //Immediately pop the current node off the stack of open elements.
		if st.SelfClosing then
			st.AcknowledgeSelfClosing; // Acknowledge the token's self-closing flag, if it is set.

		//TODO: If the active speculative HTML parser is null, then:
{		if FActiveSpeculationHtmlParser = nil then
		begin
			//If the element has a charset attribute, and getting an encoding
			//from its value results in an encoding, and the confidence is currently
			//tentative,
				then change the encoding to the resulting encoding.
			else
				Otherwise, if the element has an http-equiv attribute whose value is
				an ASCII case-insensitive match for the string "Content-Type",
				and the element has a content attribute, and applying the algorithm
				for extracting a character encoding from a meta element to that
				attribute's value returns an encoding, and the confidence is currently
				tentative,
					then change the encoding to the extracted encoding.
		end;}
	end
	else if IsStartTag(['title']) then
	begin
		//A start tag whose tag name is "title"
		GenericRCDATAElementParsingAlgorithm(node, nil); //Follow the generic RCDATA element parsing algorithm.
	end
	else if (Scripting and (isStartTag(['noscript'])))
				or IsStartTag(['noframes', 'style']) then
	begin
		//A start tag whose tag name is "noscript", if the scripting flag is enabled
		//A start tag whose tag name is one of: "noframes", "style"
		GenericParsingAlgorithm(node, tsRawTextState); //Follow the generic raw text element parsing algorithm.
	end
	else if (not Scripting) and (st.TagName = 'noscript') then
	begin
		//A start tag whose tag name is "noscript", if the scripting flag is disabled
		InsertAnHtmlElement(node); //Insert an HTML element for the token.
		SetInsertionMode(imInHeadNoscript); //Switch the insertion mode to "in head noscript".
	end
	else if IsStartTag(['script']) then
	begin
		//A start tag whose tag name is "script"
		InsertScriptElement;
	end
	else if IsEndTag(['head']) then
	begin
		//An end tag whose tag name is "head"
		FOpenElements.Pop; // Pop the current node (which will be the head element) off the stack of open elements.
		SetInsertionMode(imAfterHead); //Switch the insertion mode to "after head".
	end
	else if IsEndTag(['body', 'html', 'br']) then
	begin
		//An end tag whose tag name is one of: "body", "html", "br"
		AnythingElse; //Act as described in the "anything else" entry below.
	end
	else if IsStartTag(['template']) then
	begin
		//A start tag whose tag name is "template"
		InsertAnHtmlElement(node); // Insert an HTML element for the token.

		AddMarkerToActiveFormattingElements; //Insert a marker at the end of the list of active formatting elements.

		FFramesetOK := False; //Set the frameset-ok flag to "not ok".

		SetInsertionMode(imInTemplate); // Switch the insertion mode to "in template".

		//TODO: Push "in template" onto the stack of template insertion modes so that it is the new current template insertion mode.
	end
	else if IsEndTag(['template']) then
	begin
		//An end tag whose tag name is "template"

		if (True {there is no template element on the stack of open elements}) then
		begin
			AddParseError(node); //this is a parse error;
			Exit; //ignore the token.
		end;

//		TODO: Generate all implied end tags thoroughly.

		If (True {the current node is not a template element}) then
		begin
			AddParseError(Node, 'Current node is not a template element'); //this is a parse error.
		end;

		//TODO: Pop elements from the stack of open elements until a template element has been popped from the stack.

		//TODO: Clear the list of active formatting elements up to the last marker.

		//TODO: Pop the current template insertion mode off the stack of template insertion modes.

		ResetTheInsertionModeAppropriately; //Reset the insertion mode appropriately.
	end
	else if IsStartTag(['head']) or (Node is TEndTagToken) then
	begin
		//A start tag whose tag name is "head"
		//Any other end tag
		AddParseError(node);// Parse error.
		Exit; //Ignore the token.
	end
	else
		AnythingElse;
end;

procedure THtmlParser.DoInHeadNoscriptInsertionMode(Node: THtmlToken);
begin
	//13.2.6.4.5 The "in head noscript" insertion mode
	//https://html.spec.whatwg.org/multipage/parsing.html#parsing-main-inheadnoscript
	AddNotImplementedParseError('DoInHeadNoscriptInsertionMode');
{
When the user agent is to apply the rules for the "in head noscript" insertion mode, the user agent must handle the token as follows:

A DOCTYPE token
Parse error. Ignore the token.

A start tag whose tag name is "html"
Process the token using the rules for the "in body" insertion mode.

An end tag whose tag name is "noscript"
Pop the current node (which will be a noscript element) from the stack of open elements; the new current node will be a head element.

Switch the insertion mode to "in head".

A character token that is one of U+0009 CHARACTER TABULATION, U+000A LINE FEED (LF), U+000C FORM FEED (FF), U+000D CARRIAGE RETURN (CR), or U+0020 SPACE
A comment token
A start tag whose tag name is one of: "basefont", "bgsound", "link", "meta", "noframes", "style"
Process the token using the rules for the "in head" insertion mode.

An end tag whose tag name is "br"
Act as described in the "anything else" entry below.

A start tag whose tag name is one of: "head", "noscript"
Any other end tag
Parse error. Ignore the token.

Anything else
Parse error.

Pop the current node (which will be a noscript element) from the stack of open elements; the new current node will be a head element.

Switch the insertion mode to "in head".

Reprocess the token.
}
end;

procedure THtmlParser.DoAfterHeadInsertionMode(Node: THtmlToken);
begin
	//13.2.6.4.6 The "after head" insertion mode
	//https://html.spec.whatwg.org/multipage/parsing.html#the-after-head-insertion-mode
	AddNotImplementedParseError('DoAfterHeadInsertionMode');
{
When the user agent is to apply the rules for the "after head" insertion mode, the user agent must handle the token as follows:

A character token that is one of U+0009 CHARACTER TABULATION, U+000A LINE FEED (LF), U+000C FORM FEED (FF), U+000D CARRIAGE RETURN (CR), or U+0020 SPACE
Insert the character.

A comment token
Insert a comment.

A DOCTYPE token
Parse error. Ignore the token.

A start tag whose tag name is "html"
Process the token using the rules for the "in body" insertion mode.

A start tag whose tag name is "body"
Insert an HTML element for the token.

Set the Document's awaiting parser-inserted body flag to false.

Set the frameset-ok flag to "not ok".

Switch the insertion mode to "in body".

A start tag whose tag name is "frameset"
Insert an HTML element for the token.

Set the Document's awaiting parser-inserted body flag to false.

The awaiting parser-inserted body flag is exclusively used by render-blocking, for which the presence of either a frameset or a body element indicates that there is content to render, so we simply treat them as the same.

Switch the insertion mode to "in frameset".

A start tag whose tag name is one of: "base", "basefont", "bgsound", "link", "meta", "noframes", "script", "style", "template", "title"
Parse error.

Push the node pointed to by the head element pointer onto the stack of open elements.

Process the token using the rules for the "in head" insertion mode.

Remove the node pointed to by the head element pointer from the stack of open elements. (It might not be the current node at this point.)

The head element pointer cannot be null at this point.

An end tag whose tag name is "template"
Process the token using the rules for the "in head" insertion mode.

An end tag whose tag name is one of: "body", "html", "br"
Act as described in the "anything else" entry below.

A start tag whose tag name is "head"
Any other end tag
Parse error. Ignore the token.

Anything else
Insert an HTML element for a "body" start tag token with no attributes.

Set the Document's awaiting parser-inserted body flag to false.

Switch the insertion mode to "in body".

Reprocess the current token.
}
end;

procedure THtmlParser.DoInBodyInsertionMode(Node: THtmlToken);
begin
	//13.2.6.4.7 The "in body" insertion mode
	//https://html.spec.whatwg.org/multipage/parsing.html#parsing-main-inbody
	AddNotImplementedParseError('DoInBodyInsertionMode');
{
When the user agent is to apply the rules for the "in body" insertion mode, the user agent must handle the token as follows:

A character token that is U+0000 NULL
Parse error. Ignore the token.

A character token that is one of U+0009 CHARACTER TABULATION, U+000A LINE FEED (LF), U+000C FORM FEED (FF), U+000D CARRIAGE RETURN (CR), or U+0020 SPACE
Reconstruct the active formatting elements, if any.

Insert the token's character.

Any other character token
Reconstruct the active formatting elements, if any.

Insert the token's character.

Set the frameset-ok flag to "not ok".

A comment token
Insert a comment.

A DOCTYPE token
Parse error. Ignore the token.

A start tag whose tag name is "html"
Parse error.

If there is a template element on the stack of open elements, then ignore the token.

Otherwise, for each attribute on the token, check to see if the attribute is already present on the top element of the stack of open elements. If it is not, add the attribute and its corresponding value to that element.

A start tag whose tag name is one of: "base", "basefont", "bgsound", "link", "meta", "noframes", "script", "style", "template", "title"
An end tag whose tag name is "template"
Process the token using the rules for the "in head" insertion mode.

A start tag whose tag name is "body"
Parse error.

If the second element on the stack of open elements is not a body element, if the stack of open elements has only one node on it, or if there is a template element on the stack of open elements, then ignore the token. (fragment case)

Otherwise, set the frameset-ok flag to "not ok"; then, for each attribute on the token, check to see if the attribute is already present on the body element (the second element) on the stack of open elements, and if it is not, add the attribute and its corresponding value to that element.

A start tag whose tag name is "frameset"
Parse error.

If the stack of open elements has only one node on it, or if the second element on the stack of open elements is not a body element, then ignore the token. (fragment case)

If the frameset-ok flag is set to "not ok", ignore the token.

Otherwise, run the following steps:

Remove the second element on the stack of open elements from its parent node, if it has one.

Pop all the nodes from the bottom of the stack of open elements, from the current node up to, but not including, the root html element.

Insert an HTML element for the token.

Switch the insertion mode to "in frameset".

An end-of-file token
If the stack of template insertion modes is not empty, then process the token using the rules for the "in template" insertion mode.

Otherwise, follow these steps:

If there is a node in the stack of open elements that is not either a dd element, a dt element, an li element, an optgroup element, an option element, a p element, an rb element, an rp element, an rt element, an rtc element, a tbody element, a td element, a tfoot element, a th element, a thead element, a tr element, the body element, or the html element, then this is a parse error.

Stop parsing.

An end tag whose tag name is "body"
If the stack of open elements does not have a body element in scope, this is a parse error; ignore the token.

Otherwise, if there is a node in the stack of open elements that is not either a dd element, a dt element, an li element, an optgroup element, an option element, a p element, an rb element, an rp element, an rt element, an rtc element, a tbody element, a td element, a tfoot element, a th element, a thead element, a tr element, the body element, or the html element, then this is a parse error.

Switch the insertion mode to "after body".

An end tag whose tag name is "html"
If the stack of open elements does not have a body element in scope, this is a parse error; ignore the token.

Otherwise, if there is a node in the stack of open elements that is not either a dd element, a dt element, an li element, an optgroup element, an option element, a p element, an rb element, an rp element, an rt element, an rtc element, a tbody element, a td element, a tfoot element, a th element, a thead element, a tr element, the body element, or the html element, then this is a parse error.

Switch the insertion mode to "after body".

Reprocess the token.

A start tag whose tag name is one of: "address", "article", "aside", "blockquote", "center", "details", "dialog", "dir", "div", "dl", "fieldset", "figcaption", "figure", "footer", "header", "hgroup", "main", "menu", "nav", "ol", "p", "section", "summary", "ul"
If the stack of open elements has a p element in button scope, then close a p element.

Insert an HTML element for the token.

A start tag whose tag name is one of: "h1", "h2", "h3", "h4", "h5", "h6"
If the stack of open elements has a p element in button scope, then close a p element.

If the current node is an HTML element whose tag name is one of "h1", "h2", "h3", "h4", "h5", or "h6", then this is a parse error; pop the current node off the stack of open elements.

Insert an HTML element for the token.

A start tag whose tag name is one of: "pre", "listing"
If the stack of open elements has a p element in button scope, then close a p element.

Insert an HTML element for the token.

If the next token is a U+000A LINE FEED (LF) character token, then ignore that token and move on to the next one. (Newlines at the start of pre blocks are ignored as an authoring convenience.)

Set the frameset-ok flag to "not ok".

A start tag whose tag name is "form"
If the form element pointer is not null, and there is no template element on the stack of open elements, then this is a parse error; ignore the token.

Otherwise:

If the stack of open elements has a p element in button scope, then close a p element.

Insert an HTML element for the token, and, if there is no template element on the stack of open elements, set the form element pointer to point to the element created.

A start tag whose tag name is "li"
Run these steps:

Set the frameset-ok flag to "not ok".

Initialize node to be the current node (the bottommost node of the stack).

Loop: If node is an li element, then run these substeps:

Generate implied end tags, except for li elements.

If the current node is not an li element, then this is a parse error.

Pop elements from the stack of open elements until an li element has been popped from the stack.

Jump to the step labeled done below.

If node is in the special category, but is not an address, div, or p element, then jump to the step labeled done below.

Otherwise, set node to the previous entry in the stack of open elements and return to the step labeled loop.

Done: If the stack of open elements has a p element in button scope, then close a p element.

Finally, insert an HTML element for the token.

A start tag whose tag name is one of: "dd", "dt"
Run these steps:

Set the frameset-ok flag to "not ok".

Initialize node to be the current node (the bottommost node of the stack).

Loop: If node is a dd element, then run these substeps:

Generate implied end tags, except for dd elements.

If the current node is not a dd element, then this is a parse error.

Pop elements from the stack of open elements until a dd element has been popped from the stack.

Jump to the step labeled done below.

If node is a dt element, then run these substeps:

Generate implied end tags, except for dt elements.

If the current node is not a dt element, then this is a parse error.

Pop elements from the stack of open elements until a dt element has been popped from the stack.

Jump to the step labeled done below.

If node is in the special category, but is not an address, div, or p element, then jump to the step labeled done below.

Otherwise, set node to the previous entry in the stack of open elements and return to the step labeled loop.

Done: If the stack of open elements has a p element in button scope, then close a p element.

Finally, insert an HTML element for the token.

A start tag whose tag name is "plaintext"
If the stack of open elements has a p element in button scope, then close a p element.

Insert an HTML element for the token.

Switch the tokenizer to the PLAINTEXT state.

Once a start tag with the tag name "plaintext" has been seen, that will be the last token ever seen other than character tokens (and the end-of-file token), because there is no way to switch out of the PLAINTEXT state.

A start tag whose tag name is "button"
If the stack of open elements has a button element in scope, then run these substeps:

Parse error.

Generate implied end tags.

Pop elements from the stack of open elements until a button element has been popped from the stack.

Reconstruct the active formatting elements, if any.

Insert an HTML element for the token.

Set the frameset-ok flag to "not ok".

An end tag whose tag name is one of: "address", "article", "aside", "blockquote", "button", "center", "details", "dialog", "dir", "div", "dl", "fieldset", "figcaption", "figure", "footer", "header", "hgroup", "listing", "main", "menu", "nav", "ol", "pre", "section", "summary", "ul"
If the stack of open elements does not have an element in scope that is an HTML element with the same tag name as that of the token, then this is a parse error; ignore the token.

Otherwise, run these steps:

Generate implied end tags.

If the current node is not an HTML element with the same tag name as that of the token, then this is a parse error.

Pop elements from the stack of open elements until an HTML element with the same tag name as the token has been popped from the stack.

An end tag whose tag name is "form"
If there is no template element on the stack of open elements, then run these substeps:

Let node be the element that the form element pointer is set to, or null if it is not set to an element.

Set the form element pointer to null.

If node is null or if the stack of open elements does not have node in scope, then this is a parse error; return and ignore the token.

Generate implied end tags.

If the current node is not node, then this is a parse error.

Remove node from the stack of open elements.

If there is a template element on the stack of open elements, then run these substeps instead:

If the stack of open elements does not have a form element in scope, then this is a parse error; return and ignore the token.

Generate implied end tags.

If the current node is not a form element, then this is a parse error.

Pop elements from the stack of open elements until a form element has been popped from the stack.

An end tag whose tag name is "p"
If the stack of open elements does not have a p element in button scope, then this is a parse error; insert an HTML element for a "p" start tag token with no attributes.

Close a p element.

An end tag whose tag name is "li"
If the stack of open elements does not have an li element in list item scope, then this is a parse error; ignore the token.

Otherwise, run these steps:

Generate implied end tags, except for li elements.

If the current node is not an li element, then this is a parse error.

Pop elements from the stack of open elements until an li element has been popped from the stack.

An end tag whose tag name is one of: "dd", "dt"
If the stack of open elements does not have an element in scope that is an HTML element with the same tag name as that of the token, then this is a parse error; ignore the token.

Otherwise, run these steps:

Generate implied end tags, except for HTML elements with the same tag name as the token.

If the current node is not an HTML element with the same tag name as that of the token, then this is a parse error.

Pop elements from the stack of open elements until an HTML element with the same tag name as the token has been popped from the stack.

An end tag whose tag name is one of: "h1", "h2", "h3", "h4", "h5", "h6"
If the stack of open elements does not have an element in scope that is an HTML element and whose tag name is one of "h1", "h2", "h3", "h4", "h5", or "h6", then this is a parse error; ignore the token.

Otherwise, run these steps:

Generate implied end tags.

If the current node is not an HTML element with the same tag name as that of the token, then this is a parse error.

Pop elements from the stack of open elements until an HTML element whose tag name is one of "h1", "h2", "h3", "h4", "h5", or "h6" has been popped from the stack.

An end tag whose tag name is "sarcasm"
Take a deep breath, then act as described in the "any other end tag" entry below.

A start tag whose tag name is "a"
If the list of active formatting elements contains an a element between the end of the list and the last marker on the list (or the start of the list if there is no marker on the list), then this is a parse error; run the adoption agency algorithm for the token, then remove that element from the list of active formatting elements and the stack of open elements if the adoption agency algorithm didn't already remove it (it might not have if the element is not in table scope).

In the non-conforming stream <a href="a">a<table><a href="b">b</table>x, the first a element would be closed upon seeing the second one, and the "x" character would be inside a link to "b", not to "a". This is despite the fact that the outer a element is not in table scope (meaning that a regular </a> end tag at the start of the table wouldn't close the outer a element). The result is that the two a elements are indirectly nested inside each other — non-conforming markup will often result in non-conforming DOMs when parsed.

Reconstruct the active formatting elements, if any.

Insert an HTML element for the token. Push onto the list of active formatting elements that element.

A start tag whose tag name is one of: "b", "big", "code", "em", "font", "i", "s", "small", "strike", "strong", "tt", "u"
Reconstruct the active formatting elements, if any.

Insert an HTML element for the token. Push onto the list of active formatting elements that element.

A start tag whose tag name is "nobr"
Reconstruct the active formatting elements, if any.

If the stack of open elements has a nobr element in scope, then this is a parse error; run the adoption agency algorithm for the token, then once again reconstruct the active formatting elements, if any.

Insert an HTML element for the token. Push onto the list of active formatting elements that element.

An end tag whose tag name is one of: "a", "b", "big", "code", "em", "font", "i", "nobr", "s", "small", "strike", "strong", "tt", "u"
Run the adoption agency algorithm for the token.

A start tag whose tag name is one of: "applet", "marquee", "object"
Reconstruct the active formatting elements, if any.

Insert an HTML element for the token.

Insert a marker at the end of the list of active formatting elements.

Set the frameset-ok flag to "not ok".

An end tag token whose tag name is one of: "applet", "marquee", "object"
If the stack of open elements does not have an element in scope that is an HTML element with the same tag name as that of the token, then this is a parse error; ignore the token.

Otherwise, run these steps:

Generate implied end tags.

If the current node is not an HTML element with the same tag name as that of the token, then this is a parse error.

Pop elements from the stack of open elements until an HTML element with the same tag name as the token has been popped from the stack.

Clear the list of active formatting elements up to the last marker.
A start tag whose tag name is "table"
If the Document is not set to quirks mode, and the stack of open elements has a p element in button scope, then close a p element.

Insert an HTML element for the token.

Set the frameset-ok flag to "not ok".

Switch the insertion mode to "in table".

An end tag whose tag name is "br"
Parse error. Drop the attributes from the token, and act as described in the next entry; i.e. act as if this was a "br" start tag token with no attributes, rather than the end tag token that it actually is.

A start tag whose tag name is one of: "area", "br", "embed", "img", "keygen", "wbr"
Reconstruct the active formatting elements, if any.

Insert an HTML element for the token. Immediately pop the current node off the stack of open elements.

Acknowledge the token's self-closing flag, if it is set.

Set the frameset-ok flag to "not ok".

A start tag whose tag name is "input"
Reconstruct the active formatting elements, if any.

Insert an HTML element for the token. Immediately pop the current node off the stack of open elements.

Acknowledge the token's self-closing flag, if it is set.

If the token does not have an attribute with the name "type", or if it does, but that attribute's value is not an ASCII case-insensitive match for the string "hidden", then: set the frameset-ok flag to "not ok".

A start tag whose tag name is one of: "param", "source", "track"
Insert an HTML element for the token. Immediately pop the current node off the stack of open elements.

Acknowledge the token's self-closing flag, if it is set.

A start tag whose tag name is "hr"
If the stack of open elements has a p element in button scope, then close a p element.

Insert an HTML element for the token. Immediately pop the current node off the stack of open elements.

Acknowledge the token's self-closing flag, if it is set.

Set the frameset-ok flag to "not ok".

A start tag whose tag name is "image"
Parse error. Change the token's tag name to "img" and reprocess it. (Don't ask.)

A start tag whose tag name is "textarea"
Run these steps:

Insert an HTML element for the token.

If the next token is a U+000A LINE FEED (LF) character token, then ignore that token and move on to the next one. (Newlines at the start of textarea elements are ignored as an authoring convenience.)

Switch the tokenizer to the RCDATA state.

Let the original insertion mode be the current insertion mode.

Set the frameset-ok flag to "not ok".

Switch the insertion mode to "text".

A start tag whose tag name is "xmp"
If the stack of open elements has a p element in button scope, then close a p element.

Reconstruct the active formatting elements, if any.

Set the frameset-ok flag to "not ok".

Follow the generic raw text element parsing algorithm.

A start tag whose tag name is "iframe"
Set the frameset-ok flag to "not ok".

Follow the generic raw text element parsing algorithm.

A start tag whose tag name is "noembed"
A start tag whose tag name is "noscript", if the scripting flag is enabled
Follow the generic raw text element parsing algorithm.

A start tag whose tag name is "select"
Reconstruct the active formatting elements, if any.

Insert an HTML element for the token.

Set the frameset-ok flag to "not ok".

If the insertion mode is one of "in table", "in caption", "in table body", "in row", or "in cell", then switch the insertion mode to "in select in table". Otherwise, switch the insertion mode to "in select".

A start tag whose tag name is one of: "optgroup", "option"
If the current node is an option element, then pop the current node off the stack of open elements.

Reconstruct the active formatting elements, if any.

Insert an HTML element for the token.

A start tag whose tag name is one of: "rb", "rtc"
If the stack of open elements has a ruby element in scope, then generate implied end tags. If the current node is not now a ruby element, this is a parse error.

Insert an HTML element for the token.

A start tag whose tag name is one of: "rp", "rt"
If the stack of open elements has a ruby element in scope, then generate implied end tags, except for rtc elements. If the current node is not now a rtc element or a ruby element, this is a parse error.

Insert an HTML element for the token.

A start tag whose tag name is "math"
Reconstruct the active formatting elements, if any.

Adjust MathML attributes for the token. (This fixes the case of MathML attributes that are not all lowercase.)

Adjust foreign attributes for the token. (This fixes the use of namespaced attributes, in particular XLink.)

Insert a foreign element for the token, in the MathML namespace.

If the token has its self-closing flag set, pop the current node off the stack of open elements and acknowledge the token's self-closing flag.

A start tag whose tag name is "svg"
Reconstruct the active formatting elements, if any.

Adjust SVG attributes for the token. (This fixes the case of SVG attributes that are not all lowercase.)

Adjust foreign attributes for the token. (This fixes the use of namespaced attributes, in particular XLink in SVG.)

Insert a foreign element for the token, in the SVG namespace.

If the token has its self-closing flag set, pop the current node off the stack of open elements and acknowledge the token's self-closing flag.

A start tag whose tag name is one of: "caption", "col", "colgroup", "frame", "head", "tbody", "td", "tfoot", "th", "thead", "tr"
Parse error. Ignore the token.

Any other start tag
Reconstruct the active formatting elements, if any.

Insert an HTML element for the token.

This element will be an ordinary element.

Any other end tag
Run these steps:

Initialize node to be the current node (the bottommost node of the stack).

Loop: If node is an HTML element with the same tag name as the token, then:

Generate implied end tags, except for HTML elements with the same tag name as the token.

If node is not the current node, then this is a parse error.

Pop all the nodes from the current node up to node, including node, then stop these steps.

Otherwise, if node is in the special category, then this is a parse error; ignore the token, and return.

Set node to the previous entry in the stack of open elements.

Return to the step labeled loop.

When the steps above say the user agent is to close a p element, it means that the user agent must run the following steps:

Generate implied end tags, except for p elements.

If the current node is not a p element, then this is a parse error.

Pop elements from the stack of open elements until a p element has been popped from the stack.

The adoption agency algorithm, which takes as its only argument a token token for which the algorithm is being run, consists of the following steps:

Let subject be token's tag name.

If the current node is an HTML element whose tag name is subject, and the current node is not in the list of active formatting elements, then pop the current node off the stack of open elements and return.

Let outer loop counter be 0.

While true:

If outer loop counter is greater than or equal to 8, then return.

Increment outer loop counter by 1.

Let formatting element be the last element in the list of active formatting elements that:

is between the end of the list and the last marker in the list, if any, or the start of the list otherwise, and
has the tag name subject.
If there is no such element, then return and instead act as described in the "any other end tag" entry above.

If formatting element is not in the stack of open elements, then this is a parse error; remove the element from the list, and return.

If formatting element is in the stack of open elements, but the element is not in scope, then this is a parse error; return.

If formatting element is not the current node, this is a parse error. (But do not return.)

Let furthest block be the topmost node in the stack of open elements that is lower in the stack than formatting element, and is an element in the special category. There might not be one.

If there is no furthest block, then the UA must first pop all the nodes from the bottom of the stack of open elements, from the current node up to and including formatting element, then remove formatting element from the list of active formatting elements, and finally return.

Let common ancestor be the element immediately above formatting element in the stack of open elements.

Let a bookmark note the position of formatting element in the list of active formatting elements relative to the elements on either side of it in the list.

Let node and last node be furthest block.

Let inner loop counter be 0.

While true:

Increment inner loop counter by 1.

Let node be the element immediately above node in the stack of open elements, or if node is no longer in the stack of open elements (e.g. because it got removed by this algorithm), the element that was immediately above node in the stack of open elements before node was removed.

If node is formatting element, then break.

If inner loop counter is greater than 3 and node is in the list of active formatting elements, then remove node from the list of active formatting elements.

If node is not in the list of active formatting elements, then remove node from the stack of open elements and continue.

Create an element for the token for which the element node was created, in the HTML namespace, with common ancestor as the intended parent; replace the entry for node in the list of active formatting elements with an entry for the new element, replace the entry for node in the stack of open elements with an entry for the new element, and let node be the new element.

If last node is furthest block, then move the aforementioned bookmark to be immediately after the new node in the list of active formatting elements.

Append last node to node.

Set last node to node.

Insert whatever last node ended up being in the previous step at the appropriate place for inserting a node, but using common ancestor as the override target.

Create an element for the token for which formatting element was created, in the HTML namespace, with furthest block as the intended parent.

Take all of the child nodes of furthest block and append them to the element created in the last step.

Append that new element to furthest block.

Remove formatting element from the list of active formatting elements, and insert the new element into the list of active formatting elements at the position of the aforementioned bookmark.

Remove formatting element from the stack of open elements, and insert the new element into the stack of open elements immediately below the position of furthest block in that stack.

This algorithm's name, the "adoption agency algorithm", comes from the way it causes elements to change parents, and is in contrast with other possible algorithms for dealing with misnested content.
}
end;

procedure THtmlParser.DoTextInsertionMode(Node: THtmlToken);
begin
	//13.2.6.4.8 The "text" insertion mode
	//https://html.spec.whatwg.org/multipage/parsing.html#parsing-main-incdata
	AddNotImplementedParseError('DoTextInsertionMode');
{
When the user agent is to apply the rules for the "text" insertion mode, the user agent must handle the token as follows:

A character token
Insert the token's character.

This can never be a U+0000 NULL character; the tokenizer converts those to U+FFFD REPLACEMENT CHARACTER characters.

An end-of-file token
Parse error.

If the current node is a script element, mark the script element as "already started".

Pop the current node off the stack of open elements.

Switch the insertion mode to the original insertion mode and reprocess the token.

An end tag whose tag name is "script"
If the active speculative HTML parser is null and the JavaScript execution context stack is empty, then perform a microtask checkpoint.

Let script be the current node (which will be a script element).

Pop the current node off the stack of open elements.

Switch the insertion mode to the original insertion mode.

Let the old insertion point have the same value as the current insertion point. Let the insertion point be just before the next input character.

Increment the parser's script nesting level by one.

If the active speculative HTML parser is null, then prepare the script. This might cause some script to execute, which might cause new characters to be inserted into the tokenizer, and might cause the tokenizer to output more tokens, resulting in a reentrant invocation of the parser.

Decrement the parser's script nesting level by one. If the parser's script nesting level is zero, then set the parser pause flag to false.

Let the insertion point have the value of the old insertion point. (In other words, restore the insertion point to its previous value. This value might be the "undefined" value.)

At this stage, if there is a pending parsing-blocking script, then:

If the script nesting level is not zero:
Set the parser pause flag to true, and abort the processing of any nested invocations of the tokenizer, yielding control back to the caller. (Tokenization will resume when the caller returns to the "outer" tree construction stage.)

The tree construction stage of this particular parser is being called reentrantly, say from a call to document.write().

Otherwise:
Run these steps:

Let the script be the pending parsing-blocking script. There is no longer a pending parsing-blocking script.

Start the speculative HTML parser for this instance of the HTML parser.

Block the tokenizer for this instance of the HTML parser, such that the event loop will not run tasks that invoke the tokenizer.

If the parser's Document has a style sheet that is blocking scripts or the script's "ready to be parser-executed" flag is not set: spin the event loop until the parser's Document has no style sheet that is blocking scripts and the script's "ready to be parser-executed" flag is set.

If this parser has been aborted in the meantime, return.

This could happen if, e.g., while the spin the event loop algorithm is running, the browsing context gets closed, or the document.open() method gets invoked on the Document.

Stop the speculative HTML parser for this instance of the HTML parser.

Unblock the tokenizer for this instance of the HTML parser, such that tasks that invoke the tokenizer can again be run.

Let the insertion point be just before the next input character.

Increment the parser's script nesting level by one (it should be zero before this step, so this sets it to one).

Execute the script.

Decrement the parser's script nesting level by one. If the parser's script nesting level is zero (which it always should be at this point), then set the parser pause flag to false.

Let the insertion point be undefined again.

If there is once again a pending parsing-blocking script, then repeat these steps from step 1.

Any other end tag
Pop the current node off the stack of open elements.

Switch the insertion mode to the original insertion mode.
}
end;

procedure THtmlParser.GenericParsingAlgorithm(const Token: THtmlToken; NextTokenizerState: TTokenizerState);
begin
{
	The generic raw text element parsing algorithm and the generic RCDATA element
	parsing algorithm consist of the following steps. These algorithms are always invoked in response to a start tag token.
}
	InsertAnHtmlElement(Token, nil); //Insert an HTML element for the token.

//	If the algorithm that was invoked is the generic raw text element parsing algorithm,
//		FTokenizer.SetState(tsRAWTEXTState) // switch the tokenizer to the RAWTEXT state;
//	else
		//otherwise the algorithm invoked was the generic RCDATA element parsing algorithm,
//		FTokenizer.SetState(tsRCDATAState); // switch the tokenizer to the RCDATA state.
	FTokenizer.SetState(NextTokenizerState);

	FOriginalInsertionMode := FInsertionMode; // Let the original insertion mode be the current insertion mode.

	SetInsertionMode(imText); // Then, switch the insertion mode to "text".
end;

procedure THtmlParser.GenericRCDATAElementParsingAlgorithm(const Token: THtmlToken; Parent: TNode);
begin
	//13.2.6.2 Parsing elements that contain only text
	//https://html.spec.whatwg.org/multipage/parsing.html#generic-rcdata-element-parsing-algorithm

{
	The generic raw text element parsing algorithm and the generic RCDATA element
	parsing algorithm consist of the following steps. These algorithms are always invoked in response to a start tag token.
}
	Self.GenericParsingAlgorithm(Token, tsRCDATAState);
end;

procedure THtmlParser.DoInTableInsertionMode(Node: THtmlToken);
begin
	//13.2.6.4.9 The "in table" insertion mode
	//https://html.spec.whatwg.org/multipage/parsing.html#parsing-main-intable
	AddNotImplementedParseError('DoInTableInsertionMode');
{
When the user agent is to apply the rules for the "in table" insertion mode, the user agent must handle the token as follows:

A character token, if the current node is table, tbody, tfoot, thead, or tr element
Let the pending table character tokens be an empty list of tokens.

Let the original insertion mode be the current insertion mode.

Switch the insertion mode to "in table text" and reprocess the token.

A comment token
Insert a comment.

A DOCTYPE token
Parse error. Ignore the token.

A start tag whose tag name is "caption"
Clear the stack back to a table context. (See below.)

Insert a marker at the end of the list of active formatting elements.

Insert an HTML element for the token, then switch the insertion mode to "in caption".

A start tag whose tag name is "colgroup"
Clear the stack back to a table context. (See below.)

Insert an HTML element for the token, then switch the insertion mode to "in column group".

A start tag whose tag name is "col"
Clear the stack back to a table context. (See below.)

Insert an HTML element for a "colgroup" start tag token with no attributes, then switch the insertion mode to "in column group".

Reprocess the current token.

A start tag whose tag name is one of: "tbody", "tfoot", "thead"
Clear the stack back to a table context. (See below.)

Insert an HTML element for the token, then switch the insertion mode to "in table body".

A start tag whose tag name is one of: "td", "th", "tr"
Clear the stack back to a table context. (See below.)

Insert an HTML element for a "tbody" start tag token with no attributes, then switch the insertion mode to "in table body".

Reprocess the current token.

A start tag whose tag name is "table"
Parse error.

If the stack of open elements does not have a table element in table scope, ignore the token.

Otherwise:

Pop elements from this stack until a table element has been popped from the stack.

Reset the insertion mode appropriately.

Reprocess the token.

An end tag whose tag name is "table"
If the stack of open elements does not have a table element in table scope, this is a parse error; ignore the token.

Otherwise:

Pop elements from this stack until a table element has been popped from the stack.

Reset the insertion mode appropriately.

An end tag whose tag name is one of: "body", "caption", "col", "colgroup", "html", "tbody", "td", "tfoot", "th", "thead", "tr"
Parse error. Ignore the token.

A start tag whose tag name is one of: "style", "script", "template"
An end tag whose tag name is "template"
Process the token using the rules for the "in head" insertion mode.

A start tag whose tag name is "input"
If the token does not have an attribute with the name "type", or if it does, but that attribute's value is not an ASCII case-insensitive match for the string "hidden", then: act as described in the "anything else" entry below.

Otherwise:

Parse error.

Insert an HTML element for the token.

Pop that input element off the stack of open elements.

Acknowledge the token's self-closing flag, if it is set.

A start tag whose tag name is "form"
Parse error.

If there is a template element on the stack of open elements, or if the form element pointer is not null, ignore the token.

Otherwise:

Insert an HTML element for the token, and set the form element pointer to point to the element created.

Pop that form element off the stack of open elements.

An end-of-file token
Process the token using the rules for the "in body" insertion mode.

Anything else
Parse error. Enable foster parenting, process the token using the rules for the "in body" insertion mode, and then disable foster parenting.

When the steps above require the UA to clear the stack back to a table context, it means that the UA must, while the current node is not a table, template, or html element, pop elements from the stack of open elements.

This is the same list of elements as used in the has an element in table scope steps.

The current node being an html element after this process is a fragment case.
}
end;

procedure THtmlParser.DoInTableTextInsertionMode(Node: THtmlToken);
begin
	//13.2.6.4.10 The "in table text" insertion mode
	//https://html.spec.whatwg.org/multipage/parsing.html#parsing-main-intabletext
	AddNotImplementedParseError('DoInTableTextInsertionMode');
{
When the user agent is to apply the rules for the "in table text" insertion mode, the user agent must handle the token as follows:

A character token that is U+0000 NULL
Parse error. Ignore the token.

Any other character token
Append the character token to the pending table character tokens list.

Anything else
If any of the tokens in the pending table character tokens list are character tokens that are not ASCII whitespace, then this is a parse error: reprocess the character tokens in the pending table character tokens list using the rules given in the "anything else" entry in the "in table" insertion mode.

Otherwise, insert the characters given by the pending table character tokens list.

Switch the insertion mode to the original insertion mode and reprocess the token.
}
end;

procedure THtmlParser.DoInCaptionInsertionMode(Node: THtmlToken);
begin
	//13.2.6.4.11 The "in caption" insertion mode
	//https://html.spec.whatwg.org/multipage/parsing.html#parsing-main-incaption
	AddNotImplementedParseError('DoInCaptionInsertionMode');
{
When the user agent is to apply the rules for the "in caption" insertion mode, the user agent must handle the token as follows:

An end tag whose tag name is "caption"
If the stack of open elements does not have a caption element in table scope, this is a parse error; ignore the token. (fragment case)

Otherwise:

Generate implied end tags.

Now, if the current node is not a caption element, then this is a parse error.

Pop elements from this stack until a caption element has been popped from the stack.

Clear the list of active formatting elements up to the last marker.

Switch the insertion mode to "in table".

A start tag whose tag name is one of: "caption", "col", "colgroup", "tbody", "td", "tfoot", "th", "thead", "tr"
An end tag whose tag name is "table"
If the stack of open elements does not have a caption element in table scope, this is a parse error; ignore the token. (fragment case)

Otherwise:

Generate implied end tags.

Now, if the current node is not a caption element, then this is a parse error.

Pop elements from this stack until a caption element has been popped from the stack.

Clear the list of active formatting elements up to the last marker.

Switch the insertion mode to "in table".

Reprocess the token.

An end tag whose tag name is one of: "body", "col", "colgroup", "html", "tbody", "td", "tfoot", "th", "thead", "tr"
Parse error. Ignore the token.

Anything else
Process the token using the rules for the "in body" insertion mode.
}
end;

procedure THtmlParser.DoInColumnGroupInsertionMode(Node: THtmlToken);
begin
	//13.2.6.4.12 The "in column group" insertion mode
	//https://html.spec.whatwg.org/multipage/parsing.html#parsing-main-incolgroup
	AddNotImplementedParseError('DoInColumnGroupInsertionMode');
{
When the user agent is to apply the rules for the "in column group" insertion mode, the user agent must handle the token as follows:

A character token that is one of U+0009 CHARACTER TABULATION, U+000A LINE FEED (LF), U+000C FORM FEED (FF), U+000D CARRIAGE RETURN (CR), or U+0020 SPACE
Insert the character.

A comment token
Insert a comment.

A DOCTYPE token
Parse error. Ignore the token.

A start tag whose tag name is "html"
Process the token using the rules for the "in body" insertion mode.

A start tag whose tag name is "col"
Insert an HTML element for the token. Immediately pop the current node off the stack of open elements.

Acknowledge the token's self-closing flag, if it is set.

An end tag whose tag name is "colgroup"
If the current node is not a colgroup element, then this is a parse error; ignore the token.

Otherwise, pop the current node from the stack of open elements. Switch the insertion mode to "in table".

An end tag whose tag name is "col"
Parse error. Ignore the token.

A start tag whose tag name is "template"
An end tag whose tag name is "template"
Process the token using the rules for the "in head" insertion mode.

An end-of-file token
Process the token using the rules for the "in body" insertion mode.

Anything else
If the current node is not a colgroup element, then this is a parse error; ignore the token.

Otherwise, pop the current node from the stack of open elements.

Switch the insertion mode to "in table".

Reprocess the token.
}
end;

procedure THtmlParser.DoInTableBodyInsertionMode(Node: THtmlToken);
begin
	//13.2.6.4.13 The "in table body" insertion mode
	//https://html.spec.whatwg.org/multipage/parsing.html#parsing-main-intbody
	AddNotImplementedParseError('DoInTableBodyInsertionMode');
{
When the user agent is to apply the rules for the "in table body" insertion mode, the user agent must handle the token as follows:

A start tag whose tag name is "tr"
Clear the stack back to a table body context. (See below.)

Insert an HTML element for the token, then switch the insertion mode to "in row".

A start tag whose tag name is one of: "th", "td"
Parse error.

Clear the stack back to a table body context. (See below.)

Insert an HTML element for a "tr" start tag token with no attributes, then switch the insertion mode to "in row".

Reprocess the current token.

An end tag whose tag name is one of: "tbody", "tfoot", "thead"
If the stack of open elements does not have an element in table scope that is an HTML element with the same tag name as the token, this is a parse error; ignore the token.

Otherwise:

Clear the stack back to a table body context. (See below.)

Pop the current node from the stack of open elements. Switch the insertion mode to "in table".

A start tag whose tag name is one of: "caption", "col", "colgroup", "tbody", "tfoot", "thead"
An end tag whose tag name is "table"
If the stack of open elements does not have a tbody, thead, or tfoot element in table scope, this is a parse error; ignore the token.

Otherwise:

Clear the stack back to a table body context. (See below.)

Pop the current node from the stack of open elements. Switch the insertion mode to "in table".

Reprocess the token.

An end tag whose tag name is one of: "body", "caption", "col", "colgroup", "html", "td", "th", "tr"
Parse error. Ignore the token.

Anything else
Process the token using the rules for the "in table" insertion mode.

When the steps above require the UA to clear the stack back to a table body context, it means that the UA must, while the current node is not a tbody, tfoot, thead, template, or html element, pop elements from the stack of open elements.

The current node being an html element after this process is a fragment case.
}
end;

procedure THtmlParser.DoInRowInsertionMode(Node: THtmlToken);
begin
	//13.2.6.4.14 The "in row" insertion mode
	//https://html.spec.whatwg.org/multipage/parsing.html#parsing-main-intr
	AddNotImplementedParseError('DoInRowInsertionMode');
{
When the user agent is to apply the rules for the "in row" insertion mode, the user agent must handle the token as follows:

A start tag whose tag name is one of: "th", "td"
Clear the stack back to a table row context. (See below.)

Insert an HTML element for the token, then switch the insertion mode to "in cell".

Insert a marker at the end of the list of active formatting elements.

An end tag whose tag name is "tr"
If the stack of open elements does not have a tr element in table scope, this is a parse error; ignore the token.

Otherwise:

Clear the stack back to a table row context. (See below.)

Pop the current node (which will be a tr element) from the stack of open elements. Switch the insertion mode to "in table body".

A start tag whose tag name is one of: "caption", "col", "colgroup", "tbody", "tfoot", "thead", "tr"
An end tag whose tag name is "table"
If the stack of open elements does not have a tr element in table scope, this is a parse error; ignore the token.

Otherwise:

Clear the stack back to a table row context. (See below.)

Pop the current node (which will be a tr element) from the stack of open elements. Switch the insertion mode to "in table body".

Reprocess the token.

An end tag whose tag name is one of: "tbody", "tfoot", "thead"
If the stack of open elements does not have an element in table scope that is an HTML element with the same tag name as the token, this is a parse error; ignore the token.

If the stack of open elements does not have a tr element in table scope, ignore the token.

Otherwise:

Clear the stack back to a table row context. (See below.)

Pop the current node (which will be a tr element) from the stack of open elements. Switch the insertion mode to "in table body".

Reprocess the token.

An end tag whose tag name is one of: "body", "caption", "col", "colgroup", "html", "td", "th"
Parse error. Ignore the token.

Anything else
Process the token using the rules for the "in table" insertion mode.

When the steps above require the UA to clear the stack back to a table row context, it means that the UA must, while the current node is not a tr, template, or html element, pop elements from the stack of open elements.

The current node being an html element after this process is a fragment case.
}
end;

procedure THtmlParser.DoInCellInsertionMode(Node: THtmlToken);
begin
	//13.2.6.4.15 The "in cell" insertion mode
	//https://html.spec.whatwg.org/multipage/parsing.html#parsing-main-intd
	AddNotImplementedParseError('DoInCellInsertionMode');
{
When the user agent is to apply the rules for the "in cell" insertion mode, the user agent must handle the token as follows:

An end tag whose tag name is one of: "td", "th"
If the stack of open elements does not have an element in table scope that is an HTML element with the same tag name as that of the token, then this is a parse error; ignore the token.

Otherwise:

Generate implied end tags.

Now, if the current node is not an HTML element with the same tag name as the token, then this is a parse error.

Pop elements from the stack of open elements stack until an HTML element with the same tag name as the token has been popped from the stack.

Clear the list of active formatting elements up to the last marker.

Switch the insertion mode to "in row".

A start tag whose tag name is one of: "caption", "col", "colgroup", "tbody", "td", "tfoot", "th", "thead", "tr"
If the stack of open elements does not have a td or th element in table scope, then this is a parse error; ignore the token. (fragment case)

Otherwise, close the cell (see below) and reprocess the token.

An end tag whose tag name is one of: "body", "caption", "col", "colgroup", "html"
Parse error. Ignore the token.

An end tag whose tag name is one of: "table", "tbody", "tfoot", "thead", "tr"
If the stack of open elements does not have an element in table scope that is an HTML element with the same tag name as that of the token, then this is a parse error; ignore the token.

Otherwise, close the cell (see below) and reprocess the token.

Anything else
Process the token using the rules for the "in body" insertion mode.

Where the steps above say to close the cell, they mean to run the following algorithm:

Generate implied end tags.

If the current node is not now a td element or a th element, then this is a parse error.

Pop elements from the stack of open elements stack until a td element or a th element has been popped from the stack.

Clear the list of active formatting elements up to the last marker.

Switch the insertion mode to "in row".

The stack of open elements cannot have both a td and a th element in table scope at the same time, nor can it have neither when the close the cell algorithm is invoked.
}
end;

procedure THtmlParser.DoInSelectInsertionMode(Node: THtmlToken);
begin
	//13.2.6.4.16 The "in select" insertion mode
	//https://html.spec.whatwg.org/multipage/parsing.html#parsing-main-inselect
	AddNotImplementedParseError('DoInSelectInsertionMode');
{
When the user agent is to apply the rules for the "in select" insertion mode, the user agent must handle the token as follows:

A character token that is U+0000 NULL
Parse error. Ignore the token.

Any other character token
Insert the token's character.

A comment token
Insert a comment.

A DOCTYPE token
Parse error. Ignore the token.

A start tag whose tag name is "html"
Process the token using the rules for the "in body" insertion mode.

A start tag whose tag name is "option"
If the current node is an option element, pop that node from the stack of open elements.

Insert an HTML element for the token.

A start tag whose tag name is "optgroup"
If the current node is an option element, pop that node from the stack of open elements.

If the current node is an optgroup element, pop that node from the stack of open elements.

Insert an HTML element for the token.

An end tag whose tag name is "optgroup"
First, if the current node is an option element, and the node immediately before it in the stack of open elements is an optgroup element, then pop the current node from the stack of open elements.

If the current node is an optgroup element, then pop that node from the stack of open elements. Otherwise, this is a parse error; ignore the token.

An end tag whose tag name is "option"
If the current node is an option element, then pop that node from the stack of open elements. Otherwise, this is a parse error; ignore the token.

An end tag whose tag name is "select"
If the stack of open elements does not have a select element in select scope, this is a parse error; ignore the token. (fragment case)

Otherwise:

Pop elements from the stack of open elements until a select element has been popped from the stack.

Reset the insertion mode appropriately.

A start tag whose tag name is "select"
Parse error.

If the stack of open elements does not have a select element in select scope, ignore the token. (fragment case)

Otherwise:

Pop elements from the stack of open elements until a select element has been popped from the stack.

Reset the insertion mode appropriately.

It just gets treated like an end tag.

A start tag whose tag name is one of: "input", "keygen", "textarea"
Parse error.

If the stack of open elements does not have a select element in select scope, ignore the token. (fragment case)

Otherwise:

Pop elements from the stack of open elements until a select element has been popped from the stack.

Reset the insertion mode appropriately.

Reprocess the token.

A start tag whose tag name is one of: "script", "template"
An end tag whose tag name is "template"
Process the token using the rules for the "in head" insertion mode.

An end-of-file token
Process the token using the rules for the "in body" insertion mode.

Anything else
Parse error. Ignore the token.
}
end;

procedure THtmlParser.DoInSelectInTableInsertionMode(Node: THtmlToken);
begin
	//13.2.6.4.17 The "in select in table" insertion mode
	//https://html.spec.whatwg.org/multipage/parsing.html#parsing-main-inselectintable
	AddNotImplementedParseError('DoInSelectInTableInsertionMode');
{
When the user agent is to apply the rules for the "in select in table" insertion mode, the user agent must handle the token as follows:

A start tag whose tag name is one of: "caption", "table", "tbody", "tfoot", "thead", "tr", "td", "th"
Parse error.

Pop elements from the stack of open elements until a select element has been popped from the stack.

Reset the insertion mode appropriately.

Reprocess the token.

An end tag whose tag name is one of: "caption", "table", "tbody", "tfoot", "thead", "tr", "td", "th"
Parse error.

If the stack of open elements does not have an element in table scope that is an HTML element with the same tag name as that of the token, then ignore the token.

Otherwise:

Pop elements from the stack of open elements until a select element has been popped from the stack.

Reset the insertion mode appropriately.

Reprocess the token.

Anything else
Process the token using the rules for the "in select" insertion mode.
}
end;

procedure THtmlParser.DoInTemplateInsertionMode(Node: THtmlToken);
begin
	//13.2.6.4.18 The "in template" insertion mode
	//https://html.spec.whatwg.org/multipage/parsing.html#parsing-main-intemplate
	AddNotImplementedParseError('DoInTemplateInsertionMode');
{
When the user agent is to apply the rules for the "in template" insertion mode, the user agent must handle the token as follows:

A character token
A comment token
A DOCTYPE token
Process the token using the rules for the "in body" insertion mode.

A start tag whose tag name is one of: "base", "basefont", "bgsound", "link", "meta", "noframes", "script", "style", "template", "title"
An end tag whose tag name is "template"
Process the token using the rules for the "in head" insertion mode.

A start tag whose tag name is one of: "caption", "colgroup", "tbody", "tfoot", "thead"
Pop the current template insertion mode off the stack of template insertion modes.

Push "in table" onto the stack of template insertion modes so that it is the new current template insertion mode.

Switch the insertion mode to "in table", and reprocess the token.

A start tag whose tag name is "col"
Pop the current template insertion mode off the stack of template insertion modes.

Push "in column group" onto the stack of template insertion modes so that it is the new current template insertion mode.

Switch the insertion mode to "in column group", and reprocess the token.

A start tag whose tag name is "tr"
Pop the current template insertion mode off the stack of template insertion modes.

Push "in table body" onto the stack of template insertion modes so that it is the new current template insertion mode.

Switch the insertion mode to "in table body", and reprocess the token.

A start tag whose tag name is one of: "td", "th"
Pop the current template insertion mode off the stack of template insertion modes.

Push "in row" onto the stack of template insertion modes so that it is the new current template insertion mode.

Switch the insertion mode to "in row", and reprocess the token.

Any other start tag
Pop the current template insertion mode off the stack of template insertion modes.

Push "in body" onto the stack of template insertion modes so that it is the new current template insertion mode.

Switch the insertion mode to "in body", and reprocess the token.

Any other end tag
Parse error. Ignore the token.

An end-of-file token
If there is no template element on the stack of open elements, then stop parsing. (fragment case)

Otherwise, this is a parse error.

Pop elements from the stack of open elements until a template element has been popped from the stack.

Clear the list of active formatting elements up to the last marker.

Pop the current template insertion mode off the stack of template insertion modes.

Reset the insertion mode appropriately.

Reprocess the token.
}
end;

procedure THtmlParser.DoAfterBodyInsertionMode(Node: THtmlToken);
begin
	//13.2.6.4.19 The "after body" insertion mode
	//https://html.spec.whatwg.org/multipage/parsing.html#parsing-main-afterbody
	AddNotImplementedParseError('DoAfterBodyInsertionMode');
{
When the user agent is to apply the rules for the "after body" insertion mode, the user agent must handle the token as follows:

A character token that is one of U+0009 CHARACTER TABULATION, U+000A LINE FEED (LF), U+000C FORM FEED (FF), U+000D CARRIAGE RETURN (CR), or U+0020 SPACE
Process the token using the rules for the "in body" insertion mode.

A comment token
Insert a comment as the last child of the first element in the stack of open elements (the html element).

A DOCTYPE token
Parse error. Ignore the token.

A start tag whose tag name is "html"
Process the token using the rules for the "in body" insertion mode.

An end tag whose tag name is "html"
If the parser was created as part of the HTML fragment parsing algorithm, this is a parse error; ignore the token. (fragment case)

Otherwise, switch the insertion mode to "after after body".

An end-of-file token
Stop parsing.

Anything else
Parse error. Switch the insertion mode to "in body" and reprocess the token.
}
end;

procedure THtmlParser.DoInFramesetInsertionMode(Node: THtmlToken);
begin
	//13.2.6.4.20 The "in frameset" insertion mode
	//https://html.spec.whatwg.org/multipage/parsing.html#parsing-main-inframeset
	AddNotImplementedParseError('DoInFramesetInsertionMode');
{
When the user agent is to apply the rules for the "in frameset" insertion mode, the user agent must handle the token as follows:

A character token that is one of U+0009 CHARACTER TABULATION, U+000A LINE FEED (LF), U+000C FORM FEED (FF), U+000D CARRIAGE RETURN (CR), or U+0020 SPACE
Insert the character.

A comment token
Insert a comment.

A DOCTYPE token
Parse error. Ignore the token.

A start tag whose tag name is "html"
Process the token using the rules for the "in body" insertion mode.

A start tag whose tag name is "frameset"
Insert an HTML element for the token.

An end tag whose tag name is "frameset"
If the current node is the root html element, then this is a parse error; ignore the token. (fragment case)

Otherwise, pop the current node from the stack of open elements.

If the parser was not created as part of the HTML fragment parsing algorithm (fragment case), and the current node is no longer a frameset element, then switch the insertion mode to "after frameset".

A start tag whose tag name is "frame"
Insert an HTML element for the token. Immediately pop the current node off the stack of open elements.

Acknowledge the token's self-closing flag, if it is set.

A start tag whose tag name is "noframes"
Process the token using the rules for the "in head" insertion mode.

An end-of-file token
If the current node is not the root html element, then this is a parse error.

The current node can only be the root html element in the fragment case.

Stop parsing.

Anything else
Parse error. Ignore the token.
}
end;

procedure THtmlParser.DoAfterFramesetInsertionMode(Node: THtmlToken);
begin
	//13.2.6.4.21 The "after frameset" insertion mode
	//https://html.spec.whatwg.org/multipage/parsing.html#parsing-main-afterframeset
	AddNotImplementedParseError('DoAfterFramesetInsertionMode');
{
When the user agent is to apply the rules for the "after frameset" insertion mode, the user agent must handle the token as follows:

A character token that is one of U+0009 CHARACTER TABULATION, U+000A LINE FEED (LF), U+000C FORM FEED (FF), U+000D CARRIAGE RETURN (CR), or U+0020 SPACE
Insert the character.

A comment token
Insert a comment.

A DOCTYPE token
Parse error. Ignore the token.

A start tag whose tag name is "html"
Process the token using the rules for the "in body" insertion mode.

An end tag whose tag name is "html"
Switch the insertion mode to "after after frameset".

A start tag whose tag name is "noframes"
Process the token using the rules for the "in head" insertion mode.

An end-of-file token
Stop parsing.

Anything else
Parse error. Ignore the token.
}
end;

destructor THtmlParser.Destroy;
begin
	FreeAndNil(FOpenElements);
	FreeAndNil(FActiveFormattingElements);

	inherited;
end;

procedure THtmlParser.DoAfterAfterBodyInsertionMode(Node: THtmlToken);
begin
	//13.2.6.4.22 The "after after body" insertion mode
	//https://html.spec.whatwg.org/multipage/parsing.html#the-after-after-body-insertion-mode
	AddNotImplementedParseError('DoAfterAfterBodyInsertionMode');
{
When the user agent is to apply the rules for the "after after body" insertion mode, the user agent must handle the token as follows:

A comment token
Insert a comment as the last child of the Document object.

A DOCTYPE token
A character token that is one of U+0009 CHARACTER TABULATION, U+000A LINE FEED (LF), U+000C FORM FEED (FF), U+000D CARRIAGE RETURN (CR), or U+0020 SPACE
A start tag whose tag name is "html"
Process the token using the rules for the "in body" insertion mode.

An end-of-file token
Stop parsing.

Anything else
Parse error. Switch the insertion mode to "in body" and reprocess the token.
}
end;

procedure THtmlParser.DoAfterAfterFrameseInsertionMode(Node: THtmlToken);
begin
	//13.2.6.4.23 The "after after frameset" insertion mode
	//https://html.spec.whatwg.org/multipage/parsing.html#the-after-after-frameset-insertion-mode
	AddNotImplementedParseError('DoAfterAfterFrameseInsertionMode');
{
When the user agent is to apply the rules for the "after after frameset" insertion mode, the user agent must handle the token as follows:

A comment token
Insert a comment as the last child of the Document object.

A DOCTYPE token
A character token that is one of U+0009 CHARACTER TABULATION, U+000A LINE FEED (LF), U+000C FORM FEED (FF), U+000D CARRIAGE RETURN (CR), or U+0020 SPACE
A start tag whose tag name is "html"
Process the token using the rules for the "in body" insertion mode.

An end-of-file token
Stop parsing.

A start tag whose tag name is "noframes"
Process the token using the rules for the "in head" insertion mode.

Anything else
Parse error. Ignore the token.
}
end;

procedure THtmlParser.InsertAnHtmlElement(const Token: THtmlToken; Parent: TNode);
begin
	//https://html.spec.whatwg.org/multipage/parsing.html#insert-an-html-element
{
	When the steps below require the user agent to insert an HTML element for a token,
	the user agent must insert a foreign element for the token, in the HTML namespace.
}
	AddNotImplementedParseError('InsertAnHtmlElement');
end;

procedure THtmlParser.InsertCharacter(const Token: THtmlToken; Parent: TNode);
begin
//https://html.spec.whatwg.org/multipage/parsing.html#insert-a-character
	AddNotImplementedParseError('InsertCharacter');
{
When the steps below require the user agent to insert a character while processing a token, the user agent must run the following steps:

Let data be the characters passed to the algorithm, or, if no characters were explicitly specified, the character of the character token being processed.

Let the adjusted insertion location be the appropriate place for inserting a node.

If the adjusted insertion location is in a Document node, then return.

The DOM will not let Document nodes have Text node children, so they are dropped on the floor.

If there is a Text node immediately before the adjusted insertion location, then append data to that Text node's data.

Otherwise, create a new Text node whose data is data and whose node document is the same as that of the element in which the adjusted insertion location finds itself, and insert the newly created node at the adjusted insertion location.

Here are some sample inputs to the parser and the corresponding number of Text nodes that they result in, assuming a user agent that executes scripts.

Input	Number of Text nodes
A<script>
var script = document.getElementsByTagName('script')[0];
document.body.removeChild(script);
</script>B
One Text node in the document, containing "AB".
A<script>
var text = document.createTextNode('B');
document.body.appendChild(text);
</script>C
Three Text nodes; "A" before the script, the script's contents, and "BC" after the script (the parser appends to the Text node created by the script).
A<script>
var text = document.getElementsByTagName('script')[0].firstChild;
text.data = 'B';
document.body.appendChild(text);
</script>C
Two adjacent Text nodes in the document, containing "A" and "BC".
A<table>B<tr>C</tr>D</table>
One Text node before the table, containing "ABCD". (This is caused by foster parenting.)
A<table><tr> B</tr> C</table>
One Text node before the table, containing "A B C" (A-space-B-space-C). (This is caused by foster parenting.)
A<table><tr> B</tr> </em>C</table>
One Text node before the table, containing "A BC" (A-space-B-C), and one Text node inside the table (as a child of a tbody) with a single space character. (Space characters separated from non-space characters by non-character tokens are not affected by foster parenting, even if those other tokens then get ignored.)
When the steps below require the user agent to insert a comment while processing a comment token, optionally with an explicitly insertion position position, the user agent must run the following steps:

Let data be the data given in the comment token being processed.

If position was specified, then let the adjusted insertion location be position. Otherwise, let adjusted insertion location be the appropriate place for inserting a node.

Create a Comment node whose data attribute is set to data and whose node document is the same as that of the node in which the adjusted insertion location finds itself.

Insert the newly created node at the adjusted insertion location.

DOM mutation events must not fire for changes caused by the UA parsing the document. This includes the parsing of any content inserted using document.write() and document.writeln() calls. [UIEVENTS]

However, mutation observers do fire, as required by DOM .
}
end;

procedure THtmlParser.InsertComment(const Token: THtmlToken; Parent: TNode);
begin
	//https://html.spec.whatwg.org/multipage/parsing.html#insert-a-comment
	AddNotImplementedParseError('InsertComment');
{
	TODO: When the steps below require the user agent to insert a comment while processing a comment token, optionally with an explicitly insertion position position, the user agent must run the following steps:

Let data be the data given in the comment token being processed.

If position was specified, then let the adjusted insertion location be position. Otherwise, let adjusted insertion location be the appropriate place for inserting a node.

Create a Comment node whose data attribute is set to data and whose node document is the same as that of the node in which the adjusted insertion location finds itself.

Insert the newly created node at the adjusted insertion location.
}
end;

function THtmlParser.CreateElementForToken(const Node: THtmlToken): TElement;
begin
	//https://html.spec.whatwg.org/multipage/parsing.html#create-an-element-for-the-token
{
	TODO: No shit
When the steps below require the UA to create an element for a token in a particular given namespace and with a particular intended parent, the UA must run the following steps:

If the active speculative HTML parser is not null, then return the result of creating a speculative mock element given given namespace, the tag name of the given token, and the attributes of the given token.

Otherwise, optionally create a speculative mock element given given namespace, the tag name of the given token, and the attributes of the given token.

The result is not used. This step allows for a speculative fetch to be initiated from non-speculative parsing. The fetch is still speculative at this point, because, for example, by the time the element is inserted, intended parent might have been removed from the document.

Let document be intended parent's node document.

Let local name be the tag name of the token.

Let is be the value of the "is" attribute in the given token, if such an attribute exists, or null otherwise.

Let definition be the result of looking up a custom element definition given document, given namespace, local name, and is.

If definition is non-null and the parser was not created as part of the HTML fragment parsing algorithm, then let will execute script be true. Otherwise, let it be false.

If will execute script is true, then:

Increment document's throw-on-dynamic-markup-insertion counter.

If the JavaScript execution context stack is empty, then perform a microtask checkpoint.

Push a new element queue onto document's relevant agent's custom element reactions stack.

Let element be the result of creating an element given document, localName, given namespace, null, and is. If will execute script is true, set the synchronous custom elements flag; otherwise, leave it unset.

This will cause custom element constructors to run, if will execute script is true. However, since we incremented the throw-on-dynamic-markup-insertion counter, this cannot cause new characters to be inserted into the tokenizer, or the document to be blown away.

Append each attribute in the given token to element.

This can enqueue a custom element callback reaction for the attributeChangedCallback, which might run immediately (in the next step).

Even though the is attribute governs the creation of a customized built-in element, it is not present during the execution of the relevant custom element constructor; it is appended in this step, along with all other attributes.

If will execute script is true, then:

Let queue be the result of popping from document's relevant agent's custom element reactions stack. (This will be the same element queue as was pushed above.)

Invoke custom element reactions in queue.

Decrement document's throw-on-dynamic-markup-insertion counter.

If element has an xmlns attribute in the XMLNS namespace whose value is not exactly the same as the element's namespace, that is a parse error. Similarly, if element has an xmlns:xlink attribute in the XMLNS namespace whose value is not the XLink Namespace, that is a parse error.

If element is a resettable element, invoke its reset algorithm. (This initializes the element's value and checkedness based on the element's attributes.)

If element is a form-associated element and not a form-associated custom element, the form element pointer is not null, there is no template element on the stack of open elements, element is either not listed or doesn't have a form attribute, and the intended parent is in the same tree as the element pointed to by the form element pointer, then associate element with the form element pointed to by the form element pointer and set element's parser inserted flag.

Return element.}
	Result := Document.createElement((Node as TStartTagToken).TagName);
end;

procedure THtmlParser.AddMarkerToActiveFormattingElements;
begin
	AddNotImplementedParseError('AddMarkerToActiveFormattingElements');
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

function THtmlParser.TextIs(const Left: UnicodeString; const Right: array of UnicodeString): Boolean;
var
	i: Integer;
begin
	Result := False;

	for i := 0 to High(Right) do
	begin
		Result := SameText(Left, Right[i]);
		if Result then
			Exit;
	end;
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

function TElementStack.GetIsEmpty: Boolean;
begin
	Result := Self.Count = 0;
end;

function TElementStack.GetItems(Index: Integer): TElement;
begin
	Result := TObject(Self.Get(Index)) as TElement;
end;

procedure TElementStack.Pop;
begin

end;

function TElementStack.TopMost: TElement;
begin
	if Self.Count > 0 then
		Result := Self.Items[0]
	else
		Result := nil;
end;

end.
