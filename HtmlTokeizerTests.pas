unit HtmlTokeizerTests;

interface

uses
	Classes, Contnrs,
	TestFramework,
	DomCore, HtmlTokenizer, System.JSON;

type
	THtmlTokenizerTests = class(TTestCase)
	private
		FTokens: TObjectList;
		procedure GotToken(Sender: TObject; Token: THtmlToken);
		function GetToken(i: Integer): THtmlToken;
    procedure CheckSyntaxError(s: string);
		property Tokens[i: Integer]: THtmlToken read GetToken;

		procedure Tokenize(szHtml: UnicodeString; InitialTokenizerState: TTokenizerState=tsDataState);

		procedure CheckTokensEqual(const ExpectedTokens: array of string; const MessageText: string='');

		function doctype(): string;
		function startTag(TagName: string): string; overload;
		function startTag(TagName: string; Attributes: array of UnicodeString; SelfClosing: Boolean): string; overload;
		function endtag(TagName: string): string;
		function charToken(ch: UnicodeString): string;
//		function chars(text: UnicodeString): string;
		function comment(data: string): string;

//		function locInfo(Expected: string; StartLine, StartColumn, EndLine, EndColumn: Integer): string;
		procedure RunTestCase(test: TJsonObject);
	protected
		procedure SetUp; override;
		procedure TearDown; override;

		//Tests line/column metadata associated with each token; which we don't do.
//		procedure Test_LinesAreCountedCorrectly;
//		procedure Test_TokensChars;
//		procedure Test_TokensCharsStartTagChars;
//		procedure TestTokensStartTagStartTag;
//		procedure Test_TokensHtmlCharRefStartTag;
//		procedure Test_tokensCharsStartTagCharsStartTag;
//		procedure Test_TokensCommentStartTagCharsEndTag;
	published
		procedure TestEmptyDocument;
		procedure TestMalformedDocType; //because i messed it up

		// These are specific cases from the official tests that the tokenizer to handle.
		// See, test vectors work.
		procedure TestUnfinishedCommentAfterStartOfNestedComment;
		procedure TestLessThanInScriptData;
		procedure TestEndTagInScriptHTMLComment;
		procedure TestAmpersandEOF;
		procedure TestUnfinishedEntity;
		procedure TestASCIIDecimalEntity;

		procedure Official_TestA;

		{ https://github.com/tildeio/simple-html-tokenizer/blob/master/tests/tokenizer-tests.ts }
		procedure TestDocType;
		procedure TestSimpleContent;
		procedure TestASimpleTag;
		procedure TestASimpleTagWithTrailingSpaces;
		procedure TestAPairOfHyphenatedTags;

		procedure Test_ATagWithASingleQuotedAttribute;
		procedure Test_ATagWithADoubleQuotedAttribute;
		procedure Test_ATagWithADoubleQuotedEmptyAttribute;
		procedure Test_ATagWithUnquotedAttribute;
		procedure Test_ATagWithValuelessAttributes;
		procedure Test_MissingAttributeName;
		procedure Test_InvalidCharacterInAttributeName;
		procedure Test_ATagWithMultipleAttributes;
		procedure Test_ATagWithCapitalizationInAttributes;
		procedure Test_ATagWithCapitalizationInTheTag;
		procedure Test_ASelfClosingTag;
		procedure TestASelfClosingTagWithValuelessAttributesRegression;
		procedure Teset_ASelfClosingTagWithValuelessAttributesWithoutSpaceBeforeClosingRegression;
		procedure Test_ASelfClosingTagWithAnAttributeWithUnquotedValueWithoutSpaceBeforeClosingRegression;
		procedure Test_ATagWithASlashInTheMiddle;
		procedure Test_AnOpeningAndClosingTagWithSomeContent;
		procedure Test_AComment;
		procedure Test_ABuggyCommentWithNoEndingDoubleDash;
		procedure Test_ACommentThatImmediatelyCloses;
		procedure Test_ACommentThatContainsADash;
		procedure Test_ABuggyCommentThatContainsTwoDashes;
		procedure Test_CharacterReferencesAreExpanded;

		procedure Test_ANewlineImmediatelyFollowingAPreTagIsStripped;
		procedure Test_ANewlineImmediatelyFollowingAClosingPreTagIsNotStripped;
		procedure Test_ANewlineImmediatelyFollowingAnUppercasePreTagIsStripped;
		procedure Test_ANewlineImmediatelyFollowingATextareaTagIsStripped;

		procedure Test_TheTitleElementContentIsAlwaysText;
		procedure Test_TitleElementContentIsNotText;
		procedure Test_TheStyleElementContentIsAlwaysText;
		procedure Test_TheScriptElementContentRestrictions;
		procedure Test_TwoFollowingScriptTags;
		procedure Test_AnEmberishNamedArgInvocation;
		procedure Test_ParsingScriptsOutOfAcomplexHTMLDocument;
		procedure Test_CarriageReturnsAreReplacedWithLineFeeds;

	end;

implementation

uses
	SysUtils, System.Generics.Collections;

const
	CR  = #$0D; // "\r"
	LF  = #$0A; // "\n"
	TAB = #$09; // "\t"
	CRLF = #$0D#$0A; // "\r\n"


type
	TObjectHolder = class(TInterfacedObject)
	private
		FValue: TObject;
	public
		constructor Create(AObject: TObject);
		destructor Destroy; override;
	end;

function AutoFree(AObject: TObject): IUnknown;
begin
	if AObject <> nil then
		Result := TObjectHolder.Create(AObject)
	else
		Result := nil;
end;

{ TObjectHolder }

constructor TObjectHolder.Create(AObject: TObject);
begin
	inherited Create;

	FValue := AObject;
end;

destructor TObjectHolder.Destroy;
begin
	FValue.Free;
	FValue := nil;

	inherited;
end;

{ THtmlTokenizerTests }

//function THtmlTokenizerTests.chars(text: UnicodeString): string;
//begin
	//
//end;

function THtmlTokenizerTests.charToken(ch: UnicodeString): string;
var
	t: TCharacterToken;
begin
	t := TCharacterToken.Create;
	try
		t.Data := ch;
		Result := t.Description;
	finally
		t.Free;
	end;
end;

procedure THtmlTokenizerTests.CheckSyntaxError(s: string);
begin

end;

procedure THtmlTokenizerTests.CheckTokensEqual(const ExpectedTokens: array of string;
		const MessageText: string);
var
	token: THtmlToken;
	i: Integer;
	expected, actual: string;
begin
	CheckEquals(Length(ExpectedTokens)+1, FTokens.Count);

	for i := 0 to High(ExpectedTokens) do
	begin
		expected := ExpectedTokens[i];
		actual := Tokens[i].Description;
		CheckEquals(expected, actual, 'Tokens['+IntToStr(i)+']');
	end;

	token := FTokens[FTokens.Count-1] as THtmlToken;
	CheckEquals('[End-of-File]', token.Description);
end;

function THtmlTokenizerTests.comment(data: string): string;
var
	t: TCommentToken;
begin
	t := TCommentToken.Create;
	try
		t.DataString := data;
		Result := t.Description;
	finally
		t.Free;
	end;
end;

function THtmlTokenizerTests.doctype(): string;
var
	t: TDocTypeToken;
begin
//	if Name = '' then
//		Name := 'html';

	t := TDocTypeToken.Create;
	try
		t.Name := 'html'; //Name;
		Result := t.Description;
	finally
		t.Free;
	end;
end;

function THtmlTokenizerTests.endtag(TagName: string): string;
var
	t: TEndTagToken;
begin
	t := TEndTagToken.Create;
	try
		t.TagName := TagName;
		Result := t.Description;
	finally
		t.Free;
	end;
end;

function THtmlTokenizerTests.GetToken(i: Integer): THtmlToken;
begin
	if i < 0 then
		raise Exception.Create('i < 0');
	if i >= FTokens.Count then
		raise Exception.Create('i >= FTokens.Count');

	Result := TObject(FTokens[i]) as THtmlToken;
end;

procedure THtmlTokenizerTests.GotToken(Sender: TObject; Token: THtmlToken);
begin
	if FTokens = nil then
		raise Exception.Create('FTokens list is nil');

	FTokens.Add(Token);
end;

procedure THtmlTokenizerTests.Official_TestA;
var
	i: Integer;
	tests: TJsonArray;
	value: TJSonValue;
	test: TJsonObject;
begin
	value := TJsonObject.ParseJsonValue(
			'{"tests": ['+CRLF+
			''+CRLF+
			'{"description":"Correct Doctype lowercase",'+CRLF+
			'"input":"<!DOCTYPE html>",'+CRLF+
			'"output":[["DOCTYPE", "html", null, null, true]]},'+CRLF+
			''+CRLF+
			''+CRLF+
			'{"description":"Correct Doctype uppercase",'+CRLF+
			'"input":"<!DOCTYPE HTML>",'+CRLF+
			'"output":[["DOCTYPE", "html", null, null, true]]},'+CRLF+
			''+CRLF+
			'{"description":"Correct Doctype mixed case",'+CRLF+
			'"input":"<!DOCTYPE HtMl>",'+CRLF+
			'"output":[["DOCTYPE", "html", null, null, true]]},'+CRLF+
			''+CRLF+
			'{"description":"Correct Doctype case with EOF",'+CRLF+
			'"input":"<!DOCTYPE HtMl",'+CRLF+
			'"output":[["DOCTYPE", "html", null, null, false]],'+CRLF+
			'"errors":['+CRLF+
				'{ "code": "eof-in-doctype", "line": 1, "col": 15 }'+CRLF+
			']},'+CRLF+
			''+CRLF+
			'{"description":"Truncated doctype start",'+CRLF+
			'"input":"<!DOC>",'+CRLF+
			'"output":[["Comment", "DOC"]],'+CRLF+
			'"errors":['+CRLF+
				'{ "code": "incorrectly-opened-comment", "line": 1, "col": 3 }'+CRLF+
			']},'+CRLF+
			''+CRLF+
			'{"description":"Doctype in error",'+CRLF+
			'"input":"<!DOCTYPE foo>",'+CRLF+
			'"output":[["DOCTYPE", "foo", null, null, true]]},'+CRLF+
			''+CRLF+
			'{"description":"Single Start Tag",'+CRLF+
			'"input":"<h>",'+CRLF+
			'"output":[["StartTag", "h", {}]]},'+CRLF+
			''+CRLF+
			'{"description":"Empty end tag",'+CRLF+
			'"input":"</>",'+CRLF+
			'"output":[],'+CRLF+
			'"errors":['+CRLF+
				'{ "code": "missing-end-tag-name", "line": 1, "col": 3 }'+CRLF+
			']},'+CRLF+
			''+CRLF+
			'{"description":"Empty start tag",'+CRLF+
			'"input":"<>",'+CRLF+
			'"output":[["Character", "<>"]],'+CRLF+
			'"errors":['+CRLF+
				'{ "code": "invalid-first-character-of-tag-name", "line": 1, "col": 2 }'+CRLF+
			']},'+CRLF+
			''+CRLF+
			'{"description":"Start Tag w/attribute",'+CRLF+
			'"input":"<h a=''b''>",'+CRLF+
			'"output":[["StartTag", "h", {"a":"b"}]]},'+CRLF+
			''+CRLF+
			'{"description":"Start Tag w/attribute no quotes",'+CRLF+
			'"input":"<h a=b>",'+CRLF+
			'"output":[["StartTag", "h", {"a":"b"}]]},'+CRLF+
			''+CRLF+
			'{"description":"Start/End Tag",'+CRLF+
			'"input":"<h></h>",'+CRLF+
			'"output":[["StartTag", "h", {}], ["EndTag", "h"]]},'+CRLF+
			''+CRLF+
			'{"description":"Two unclosed start tags",'+CRLF+
			'"input":"<p>One<p>Two",'+CRLF+
			'"output":[["StartTag", "p", {}], ["Character", "One"], ["StartTag", "p", {}], ["Character", "Two"]]},'+CRLF+
			''+CRLF+
			'{"description":"End Tag w/attribute",'+CRLF+
			'"input":"<h></h a=''b''>",'+CRLF+
			'"output":[["StartTag", "h", {}], ["EndTag", "h"]],'+CRLF+
			'"errors":['+CRLF+
				'{ "code": "end-tag-with-attributes", "line": 1, "col": 13 }'+CRLF+
			']},'+CRLF+
			''+CRLF+
			'{"description":"Multiple atts",'+CRLF+
			'"input":"<h a=''b'' c=''d''>",'+CRLF+
			'"output":[["StartTag", "h", {"a":"b", "c":"d"}]]},'+CRLF+
			''+CRLF+
			'{"description":"Multiple atts no space",'+CRLF+
			'"input":"<h a=''b''c=''d''>",'+CRLF+
			'"output":[["StartTag", "h", {"a":"b", "c":"d"}]],'+CRLF+
			'"errors":['+CRLF+
				'{ "code": "missing-whitespace-between-attributes", "line": 1, "col": 9 }'+CRLF+
			']},'+CRLF+
			''+CRLF+
			'{"description":"Repeated attr",'+CRLF+
			'"input":"<h a=''b'' a=''d''>",'+CRLF+
			'"output":[["StartTag", "h", {"a":"b"}]],'+CRLF+
			'"errors":['+CRLF+
				'{ "code": "duplicate-attribute", "line": 1, "col": 11 }'+CRLF+
			']},'+CRLF+
			''+CRLF+
			'{"description":"Simple comment",'+CRLF+
			'"input":"<!--comment-->",'+CRLF+
			'"output":[["Comment", "comment"]]},'+CRLF+
			''+CRLF+
			'{"description":"Comment, Central dash no space",'+CRLF+
			'"input":"<!----->",'+CRLF+
			'"output":[["Comment", "-"]]},'+CRLF+
			''+CRLF+
			'{"description":"Comment, two central dashes",'+CRLF+
			'"input":"<!-- --comment -->",'+CRLF+
			'"output":[["Comment", " --comment "]]},'+CRLF+
			''+CRLF+
			'{"description":"Comment, central less-than bang",'+CRLF+
			'"input":"<!--<!-->",'+CRLF+
			'"output":[["Comment", "<!"]]},'+CRLF+
			''+CRLF+
			'{"description":"Unfinished comment",'+CRLF+
			'"input":"<!--comment",'+CRLF+
			'"output":[["Comment", "comment"]],'+CRLF+
			'"errors":['+CRLF+
				'{ "code": "eof-in-comment", "line": 1, "col": 12 }'+CRLF+
			']},'+CRLF+
			''+CRLF+
			'{"description":"Unfinished comment after start of nested comment",'+CRLF+
			'"input":"<!-- <!--",'+CRLF+
			'"output":[["Comment", " <!"]],'+CRLF+
			'"errors":['+CRLF+
				'{ "code": "eof-in-comment", "line": 1, "col": 10 }'+CRLF+
			']},'+CRLF+
			''+CRLF+
			'{"description":"Start of a comment",'+CRLF+
			'"input":"<!-",'+CRLF+
			'"output":[["Comment", "-"]],'+CRLF+
			'"errors":['+CRLF+
				'{ "code": "incorrectly-opened-comment", "line": 1, "col": 3 }'+CRLF+
			']},'+CRLF+
			''+CRLF+
			'{"description":"Short comment",'+CRLF+
			'"input":"<!-->",'+CRLF+
			'"output":[["Comment", ""]],'+CRLF+
			'"errors":['+CRLF+
				'{ "code": "abrupt-closing-of-empty-comment", "line": 1, "col": 5 }'+CRLF+
			']},'+CRLF+
			''+CRLF+
			'{"description":"Short comment two",'+CRLF+
			'"input":"<!--->",'+CRLF+
			'"output":[["Comment", ""]],'+CRLF+
			'"errors":['+CRLF+
				'{ "code": "abrupt-closing-of-empty-comment", "line": 1, "col": 6 }'+CRLF+
			']},'+CRLF+
			''+CRLF+
			'{"description":"Short comment three",'+CRLF+
			'"input":"<!---->",'+CRLF+
			'"output":[["Comment", ""]]},'+CRLF+
			''+CRLF+
			'{"description":"< in comment",'+CRLF+
			'"input":"<!-- <test-->",'+CRLF+
			'"output":[["Comment", " <test"]]},'+CRLF+
			''+CRLF+
			'{"description":"<! in comment",'+CRLF+
			'"input":"<!-- <!test-->",'+CRLF+
			'"output":[["Comment", " <!test"]]},'+CRLF+
			''+CRLF+
			'{"description":"<!- in comment",'+CRLF+
			'"input":"<!-- <!-test-->",'+CRLF+
			'"output":[["Comment", " <!-test"]]},'+CRLF+
			''+CRLF+
			'{"description":"Nested comment",'+CRLF+
			'"input":"<!-- <!--test-->",'+CRLF+
			'"output":[["Comment", " <!--test"]],'+CRLF+
			'"errors":['+CRLF+
				'{ "code": "nested-comment", "line": 1, "col": 10 }'+CRLF+
			']},'+CRLF+
			''+CRLF+
			'{"description":"Nested comment with extra <",'+CRLF+
			'"input":"<!-- <<!--test-->",'+CRLF+
			'"output":[["Comment", " <<!--test"]],'+CRLF+
			'"errors":['+CRLF+
				'{ "code": "nested-comment", "line": 1, "col": 11 }'+CRLF+
			']},'+CRLF+
			''+CRLF+
			'{"description":"< in script data",'+CRLF+
			'"initialStates":["Script data state"],'+CRLF+
			'"input":"<test-->",'+CRLF+
			'"output":[["Character", "<test-->"]]},'+CRLF+
			''+CRLF+
			'{"description":"<! in script data",'+CRLF+
			'"initialStates":["Script data state"],'+CRLF+
			'"input":"<!test-->",'+CRLF+
			'"output":[["Character", "<!test-->"]]},'+CRLF+
			''+CRLF+
			'{"description":"<!- in script data",'+CRLF+
			'"initialStates":["Script data state"],'+CRLF+
			'"input":"<!-test-->",'+CRLF+
			'"output":[["Character", "<!-test-->"]]},'+CRLF+
			''+CRLF+
			'{"description":"Escaped script data",'+CRLF+
			'"initialStates":["Script data state"],'+CRLF+
			'"input":"<!--test-->",'+CRLF+
			'"output":[["Character", "<!--test-->"]]},'+CRLF+
			''+CRLF+
			'{"description":"< in script HTML comment",'+CRLF+
			'"initialStates":["Script data state"],'+CRLF+
			'"input":"<!-- < test -->",'+CRLF+
			'"output":[["Character", "<!-- < test -->"]]},'+CRLF+
			''+CRLF+
			'{"description":"</ in script HTML comment",'+CRLF+
			'"initialStates":["Script data state"],'+CRLF+
			'"input":"<!-- </ test -->",'+CRLF+
			'"output":[["Character", "<!-- </ test -->"]]},'+CRLF+
			''+CRLF+
			'{"description":"Start tag in script HTML comment",'+CRLF+
			'"initialStates":["Script data state"],'+CRLF+
			'"input":"<!-- <test> -->",'+CRLF+
			'"output":[["Character", "<!-- <test> -->"]]},'+CRLF+
			''+CRLF+
			'{"description":"End tag in script HTML comment",'+CRLF+
			'"initialStates":["Script data state"],'+CRLF+
			'"input":"<!-- </test> -->",'+CRLF+
			'"output":[["Character", "<!-- </test> -->"]]},'+CRLF+
			''+CRLF+
			'{"description":"- in script HTML comment double escaped",'+CRLF+
			'"initialStates":["Script data state"],'+CRLF+
			'"input":"<!--<script>-</script>-->",'+CRLF+
			'"output":[["Character", "<!--<script>-</script>-->"]]},'+CRLF+
			''+CRLF+
			'{"description":"-- in script HTML comment double escaped",'+CRLF+
			'"initialStates":["Script data state"],'+CRLF+
			'"input":"<!--<script>--</script>-->",'+CRLF+
			'"output":[["Character", "<!--<script>--</script>-->"]]},'+CRLF+
			''+CRLF+
			'{"description":"--- in script HTML comment double escaped",'+CRLF+
			'"initialStates":["Script data state"],'+CRLF+
			'"input":"<!--<script>---</script>-->",'+CRLF+
			'"output":[["Character", "<!--<script>---</script>-->"]]},'+CRLF+
			''+CRLF+
			'{"description":"- spaced in script HTML comment double escaped",'+CRLF+
			'"initialStates":["Script data state"],'+CRLF+
			'"input":"<!--<script> - </script>-->",'+CRLF+
			'"output":[["Character", "<!--<script> - </script>-->"]]},'+CRLF+
			''+CRLF+
			'{"description":"-- spaced in script HTML comment double escaped",'+CRLF+
			'"initialStates":["Script data state"],'+CRLF+
			'"input":"<!--<script> -- </script>-->",'+CRLF+
			'"output":[["Character", "<!--<script> -- </script>-->"]]},'+CRLF+
			''+CRLF+
			'{"description":"Ampersand EOF",'+CRLF+
			'"input":"&",'+CRLF+
			'"output":[["Character", "&"]]},'+CRLF+
			''+CRLF+
			'{"description":"Ampersand ampersand EOF",'+CRLF+
			'"input":"&&",'+CRLF+
			'"output":[["Character", "&&"]]},'+CRLF+
			''+CRLF+
			'{"description":"Ampersand space EOF",'+CRLF+
			'"input":"& ",'+CRLF+
			'"output":[["Character", "& "]]},'+CRLF+
			''+CRLF+
			'{"description":"Unfinished entity",'+CRLF+
			'"input":"&f",'+CRLF+
			'"output":[["Character", "&f"]]},'+CRLF+
			''+CRLF+
			'{"description":"Ampersand, number sign",'+CRLF+
			'"input":"&#",'+CRLF+
			'"output":[["Character", "&#"]],'+CRLF+
			'"errors":['+CRLF+
				'{ "code": "absence-of-digits-in-numeric-character-reference", "line": 1, "col": 3 }'+CRLF+
			']},'+CRLF+
			''+CRLF+
			'{"description":"Unfinished numeric entity",'+CRLF+
			'"input":"&#x",'+CRLF+
			'"output":[["Character", "&#x"]],'+CRLF+
			'"errors":['+CRLF+
				'{ "code": "absence-of-digits-in-numeric-character-reference", "line": 1, "col": 4 }'+CRLF+
			']},'+CRLF+
			''+CRLF+
			'{"description":"Entity with trailing semicolon (1)",'+CRLF+
			'"input":"I''m &not;it",'+CRLF+
			'"output":[["Character","I''m \u00ACit"]]},'+CRLF+
			''+CRLF+
			'{"description":"Entity with trailing semicolon (2)",'+CRLF+
			'"input":"I''m &notin;",'+CRLF+
			'"output":[["Character","I''m \u2209"]]},'+CRLF+
			''+CRLF+
			'{"description":"Entity without trailing semicolon (1)",'+CRLF+
			'"input":"I''m &notit",'+CRLF+
			'"output":[["Character","I''m \u00ACit"]],'+CRLF+
			'"errors": ['+CRLF+
				'{"code" : "missing-semicolon-after-character-reference", "line": 1, "col": 9 }'+CRLF+
			']},'+CRLF+
			''+CRLF+
			'{"description":"Entity without trailing semicolon (2)",'+CRLF+
			'"input":"I''m &notin",'+CRLF+
			'"output":[["Character","I''m \u00ACin"]],'+CRLF+
			'"errors": ['+CRLF+
				'{"code" : "missing-semicolon-after-character-reference", "line": 1, "col": 9 }'+CRLF+
			']},'+CRLF+
			''+CRLF+
			'{"description":"Partial entity match at end of file",'+CRLF+
			'"input":"I''m &no",'+CRLF+
			'"output":[["Character","I''m &no"]]},'+CRLF+
			''+CRLF+
			'{"description":"Non-ASCII character reference name",'+CRLF+
			'"input":"&\u00AC;",'+CRLF+
			'"output":[["Character", "&\u00AC;"]]},'+CRLF+
			''+CRLF+
			'{"description":"ASCII decimal entity",'+CRLF+
			'"input":"&#0036;",'+CRLF+
			'"output":[["Character","$"]]},'+CRLF+
			''+CRLF+
			'{"description":"ASCII hexadecimal entity",'+CRLF+
			'"input":"&#x3f;",'+CRLF+
			'"output":[["Character","?"]]},'+CRLF+
			''+CRLF+
			'{"description":"Hexadecimal entity in attribute",'+CRLF+
			'"input":"<h a=''&#x3f;''></h>",'+CRLF+
			'"output":[["StartTag", "h", {"a":"?"}], ["EndTag", "h"]]},'+CRLF+
			''+CRLF+
			'{"description":"Entity in attribute without semicolon ending in x",'+CRLF+
			'"input":"<h a=''&notx''>",'+CRLF+
			'"output":[["StartTag", "h", {"a":"&notx"}]]},'+CRLF+
			''+CRLF+
			'{"description":"Entity in attribute without semicolon ending in 1",'+CRLF+
			'"input":"<h a=''&not1''>",'+CRLF+
			'"output":[["StartTag", "h", {"a":"&not1"}]]},'+CRLF+
			''+CRLF+
			'{"description":"Entity in attribute without semicolon ending in i",'+CRLF+
			'"input":"<h a=''&noti''>",'+CRLF+
			'"output":[["StartTag", "h", {"a":"&noti"}]]},'+CRLF+
			''+CRLF+
			'{"description":"Entity in attribute without semicolon",'+CRLF+
			'"input":"<h a=''&COPY''>",'+CRLF+
			'"output":[["StartTag", "h", {"a":"\u00A9"}]],'+CRLF+
			'"errors": ['+CRLF+
				'{"code" : "missing-semicolon-after-character-reference", "line": 1, "col": 12 }'+CRLF+
			']},'+CRLF+
			''+CRLF+
			'{"description":"Unquoted attribute ending in ampersand",'+CRLF+
			'"input":"<s o=& t>",'+CRLF+
			'"output":[["StartTag","s",{"o":"&","t":""}]]},'+CRLF+
			''+CRLF+
			'{"description":"Unquoted attribute at end of tag with final character of &, with tag followed by characters",'+CRLF+
			'"input":"<a a=a&>foo",'+CRLF+
			'"output":[["StartTag", "a", {"a":"a&"}], ["Character", "foo"]]},'+CRLF+
			''+CRLF+
			'{"description":"plaintext element",'+CRLF+
			'"input":"<plaintext>foobar",'+CRLF+
			'"output":[["StartTag","plaintext",{}], ["Character","foobar"]]},'+CRLF+
			''+CRLF+
			'{"description":"Open angled bracket in unquoted attribute value state",'+CRLF+
			'"input":"<a a=f<>",'+CRLF+
			'"output":[["StartTag", "a", {"a":"f<"}]],'+CRLF+
			'"errors":['+CRLF+
				'{ "code": "unexpected-character-in-unquoted-attribute-value", "line": 1, "col": 7 }'+CRLF+
			']}'+CRLF+
			''+CRLF+
			']}');

	tests := value.FindValue('tests') as TJsonArray;

	Status('Description  Input');
	for i := 0 to tests.Count-1 do
	begin
		test := tests.Items[i] as TJsonObject;
		Status(test.GetValue<String>('description')+'   '+
			test.GetValue<string>('input'));
		RunTestCase(test);
//		Status((testCase.GetValue('description') as TJSONString).Value);
//		Status((testCase.GetValue('input') as TJsonString).Value);
	end;

end;

procedure THtmlTokenizerTests.RunTestCase(test: TJsonObject);
var
	testDescription: string;
	html: UnicodeString;
	output: TJsonArray;
	i: Integer;
	expectedToken: TJsonArray;
	tokenType: THtmlTokenType;
	initialStates: TJsonArray;
	initialState: string;
	ts: TTokenizerState;

	function TokenNameToType(s: string): THtmlTokenType;
	begin
		if s = 'DOCTYPE' then 			//(TDocTypeToken)
			Result := ttDocType
		else if s = 'StartTag' then	// (TStartTagToken)
			Result := ttStartTag
		else if s = 'EndTag' then		// (TEndTagToken)
			Result := ttEndTag
		else if s = 'Comment' then		//(TCommentToken)
			Result := ttComment
		else if s = 'Character' then	//(TCharacterToken)
			Result := ttCharacter
		else
			raise Exception.CreateFmt('Unknown test case token type "%s"', [s]);
	end;

	function StrToTokenizerState(TokenizerStateStr: string): TTokenizerState;
	begin
		if TokenizerStateStr = 'Data state' then
			Result := tsDataState
		else if TokenizerStateStr = 'PLAINTEXT state' then
			Result := tsPlaintextState
		else if TokenizerStateStr = 'RCDATA state' then
			Result := tsRCDataState
		else if TokenizerStateStr = 'RAWTEXT state' then
			Result := tsRawTextState
		else if TokenizerStateStr = 'Script data state' then
			Result := tsScriptDataState
		else if TokenizerStateStr = 'CDATA section state' then
			Result := tsCDATASectionState
		else
			raise Exception.CreateFmt('Unknown initial state "%s"', [TokenizerStateStr]);
	end;

	procedure RunSingleTest(TokenizerInitialState: TTokenizerState);
	var
		i: Integer;
	begin
		Tokenize(html, TokenizerInitialState);

		//Add one, because we also include the EOF token
		CheckEquals(output.Count+1, FTokens.Count, 'Test case "'+testDescription+'" number of tokens mismatch');

		for i := 0 to output.Count-1 do
		begin
			expectedToken := output[i] as TJsonArray;

			tokenType := TokenNameToType(expectedToken[0].GetValue<string>);

			case tokenType of
			ttDocType:		CheckTrue(Tokens[i] is TDocTypeToken);
			ttStartTag:		CheckTrue(Tokens[i] is TStartTagToken);
			ttEndTag:		CheckTrue(Tokens[i] is TEndTagToken);
			ttComment:		CheckTrue(Tokens[i] is TCommentToken);
			ttCharacter:	CheckTrue(Tokens[i] is TCharacterToken);
			else
				CheckTrue(False, 'Unknown token type');
			end;
		end;
	end;

begin
	testDescription := test.GetValue<string>('description');
	Status('Test Description: '+testDescription);

	html := test.GetValue<string>('input');
	Status('Input: "'+html+'"');

(*
	The output is an array of token information

		description:		'Two unclosed start tags'
		input:				'<p>One<p>Two'
		output:				[
									["StartTag", "p", {}],
									["Character", "One"],
									["StartTag", "p", {}],
									["Character", "Two"]
								]
		initialStates:		[
									"Script data state"
								]
*)

	output := test.GetValue('output') as TJsonArray;

	initialStates := test.GetValue('initialStates') as TJsonArray;
	if (initialStates = nil) or (initialStates.Count = 0) then
	begin
		RunSingleTest(tsDataState);
		Exit;
	end;

	for i := 0 to initialStates.Count-1 do
	begin
		initialState := (initialStates[i] as TJsonString).Value;
		ts := StrToTokenizerState(initialState);
		RunSingleTest(ts);
	end;
end;

procedure THtmlTokenizerTests.SetUp;
var
	o: TObject;
begin
	inherited;

	o := FTokens;
	FTokens := TObjectList.Create(True); //owns objects

	o.Free;
end;

function THtmlTokenizerTests.startTag(TagName: string): string;
var
	t: TStartTagToken;
begin
	t := TStartTagToken.Create;
	try
		t.TagName := TagName;
		Result := t.Description;
	finally
		t.Free;
	end;
end;

function THtmlTokenizerTests.startTag(TagName: string; Attributes: array of UnicodeString; SelfClosing: Boolean): string;
var
	t: TStartTagToken;
	i: Integer;
begin
	if (Length(Attributes) mod 2) <> 0 then
		raise Exception.Create('Attributes must come in pairs');

	t := TStartTagToken.Create;
	try
		t.TagName := TagName;

		i := 0;
		while i < Length(Attributes) do
		begin
			t.AddAttribute(Attributes[i], Attributes[i+1]);
			Inc(i, 2);
		end;

		Result := t.Description;
	finally
		t.Free;
	end;
end;

procedure THtmlTokenizerTests.TearDown;
var
	o: TObjectList;
begin
	o := FTokens;
	FTokens := nil;

	if o <> nil then
	begin
		try
			o.Free;
		except
			raise Exception.Create('Error freeing tokens list');
		end;
	end;

	inherited;
end;

procedure THtmlTokenizerTests.Tokenize(szHtml: UnicodeString; InitialTokenizerState: TTokenizerState=tsDataState);
var
	tokenizer: THtmlTokenizer;
begin
	FTokens.Clear;
	tokenizer := THtmlTokenizer.Create(szHtml);
	try
		tokenizer.SetState(InitialTokenizerState);
		tokenizer.OnToken := GotToken;
		tokenizer.Parse;
	finally
		tokenizer.Free;
	end;
end;

procedure THtmlTokenizerTests.TestEmptyDocument;
var
	expected: array of string;
begin
	Tokenize(
			'<!doctype html>'+CRLF+
			'<html>'+CRLF+
			'<head></head>'+CRLF+
			'<body></body>'+CRLF+
			'</html>');

	expected := [
			doctype(), charToken(LF),
			startTag('html'), charToken(LF),
			startTag('head'),
			endTag('head'), charToken(LF),
			startTag('body'),
			endTag('body'), charToken(LF),
			endTag('html')
	];

	CheckTokensEqual(expected);
end;

procedure THtmlTokenizerTests.TestEndTagInScriptHTMLComment;
var
	html: string;
begin
(*
	{
		"description":		"End tag in script HTML comment",
		"initialStates":	["Script data state"]
		"input":				"<!-- </test> -->"
		"output":			[
									["Character", "<!-- </test> -->"]
								]
*)
	html := '<!-- </test> -->';
	Tokenize(html, tsScriptDataState);

	CheckTokensEqual([
			charToken('<!-- </test> -->')
	]);
end;

procedure THtmlTokenizerTests.TestLessThanInScriptData;
var
	html: string;
begin
(*
			'{"description":"< in script data",'+CRLF+
			'"initialStates":["Script data state"],'+CRLF+
			'"input":"<test-->",'+CRLF+
			'"output":[["Character", "<test-->"]]},'+CRLF+
*)
	html := '<test-->';
	Tokenize(html, tsScriptDataState);

	CheckTokensEqual([
			charToken('<test-->')
	]);
end;

procedure THtmlTokenizerTests.TestAmpersandEOF;
begin
(*
	{
		"description":	"Ampersand EOF"
		"input":			"&"
		"output":		[
								["Character", "&"]
							]
	}
*)
	Tokenize('&');

	CheckTokensEqual([
			charToken('&')
	]);
end;

procedure THtmlTokenizerTests.TestAPairOfHyphenatedTags;
begin
	Tokenize('<x-foo></x-foo>');

	CheckTokensEqual([
			startTag('x-foo'),
			endTag('x-foo')
	]);
end;

procedure THtmlTokenizerTests.TestASimpleTag;
begin
	Tokenize('<div>');

	CheckTokensEqual([
			startTag('div')
	]);
end;

procedure THtmlTokenizerTests.TestASimpleTagWithTrailingSpaces;
begin
	Tokenize('</div   '+TAB+LF+'>');

	CheckTokensEqual([
			startTag('div')
	]);
end;

procedure THtmlTokenizerTests.TestDocType;
begin
	//https://github.com/tildeio/simple-html-tokenizer/blob/master/tests/tokenizer-tests.ts
	Tokenize('<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">');

	CheckTokensEqual([
			doctype()
	]);


	Tokenize('<!-- comment --><!DOCTYPE html PUBLIC >');
	CheckTokensEqual([
			comment(' comment '),
			doctype()
	]);
end;

procedure THtmlTokenizerTests.TestMalformedDocType;
const
	html =
			'<doctype html>'+CRLF+  //oops, forgot the exclamation point (!)
			'<html>'+CRLF+
			'<head></head>'+CRLF+
			'<body></body>'+CRLF+
			'</html>';
begin
	tokenize(html);

	CheckTokensEqual([
			startTag('doctype'),
			charToken(LF),
			startTag('html'),
			charToken(LF),
			startTag('head'),
			endTag('head'),
			charToken(LF),
			startTag('body'),
			endTag('body'),
			charToken(LF),
			endTag('html')
	]);
end;

procedure THtmlTokenizerTests.TestSimpleContent;
begin
	Tokenize('hello');
	CheckTokensEqual([
			charToken('hello')
	]);
end;

procedure THtmlTokenizerTests.TestUnfinishedCommentAfterStartOfNestedComment;
var
	html: string;
begin
	html := '<!-- <!--';
	//Error: "eof-in-comment"
	Tokenize(html);

	CheckTokensEqual([
			comment(' <!')
	]);
end;

procedure THtmlTokenizerTests.TestUnfinishedEntity;
begin
(*
	{
		"description":		"Unfinished entity"
		"input":				"&f"
		"output":			[
									["Character", "&f"]
								]
	}
*)
	Tokenize('&f');
	CheckTokensEqual([
			charToken('&f')
   ]);
end;

procedure THtmlTokenizerTests.Test_ATagWithASingleQuotedAttribute;
begin
	Tokenize('<div id=''foo''>');
	CheckTokensEqual([
			startTag('div', ['id', 'foo'], True)
	]);
end;

procedure THtmlTokenizerTests.Test_ATagWithADoubleQuotedAttribute;
begin
	Tokenize('<div id="foo">');
	CheckTokensEqual([
			startTag('div', ['id', 'foo'], True)
	]);
end;

procedure THtmlTokenizerTests.Test_ATagWithADoubleQuotedEmptyAttribute;
begin
	Tokenize('<div id="">');
	CheckTokensEqual([
			startTag('div', ['id', ''], False)
	]);
end;

procedure THtmlTokenizerTests.Test_ATagWithUnquotedAttribute;
begin
	Tokenize('<div id=foo>');
	CheckTokensEqual([
			startTag('div', ['id', 'foo'], False)
	]);
end;

procedure THtmlTokenizerTests.Test_ATagWithValuelessAttributes;
begin
	Tokenize('<div foo bar>');
	CheckTokensEqual([
			startTag('div', ['foo', '', 'bar', ''], False)
	]);
end;

procedure THtmlTokenizerTests.Test_MissingAttributeName;
begin
	Tokenize('<div =foo>');
	CheckTokensEqual([
			startTag('div', ['=foo', ''], False)
	]);

	CheckSyntaxError('attribute name cannot start with equals sign');
end;

procedure THtmlTokenizerTests.Test_InvalidCharacterInAttributeName;
begin
	Tokenize('<div ">');
	CheckTokensEqual([
			startTag('div', ['"', ''], False)
	]);

	CheckSyntaxError('" is not a valid character within attribute names');
end;

procedure THtmlTokenizerTests.Test_ATagWithMultipleAttributes;
begin
	Tokenize('<div id=foo class="bar baz" href=\''bat\''>');

	CheckTokensEqual([
			startTag('div', ['id', 'foo', 'class', 'bar baz', 'href', 'bat'], False)
	]);
end;

procedure THtmlTokenizerTests.Test_ATagWithCapitalizationInAttributes;
begin
	Tokenize('<svg viewBox="0 0 0 0">');
	CheckTokensEqual([
			startTag('svg', ['viewBox', '0 0 0 0'], False)
	]);
end;

procedure THtmlTokenizerTests.Test_ATagWithCapitalizationInTheTag;
begin
	Tokenize('<linearGradient>');
	CheckTokensEqual([
			startTag('lineargradient')
	]);
end;

procedure THtmlTokenizerTests.Test_ASelfClosingTag;
begin
	Tokenize('<img />');
	CheckTokensEqual([
			startTag('img', [], true)
	]);
end;

procedure THtmlTokenizerTests.TestASCIIDecimalEntity;
begin
(*
	"description":		"ASCII decimal entity",'+CRLF+
	"input":				"&#0036;"
	"output"				[
								["Character","$"]
							]
*)
	Tokenize('&#0036;');
	CheckTokensEqual([
			charToken('$')
	]);
end;

procedure THtmlTokenizerTests.TestASelfClosingTagWithValuelessAttributesRegression;
begin
	Tokenize('<input disabled />');
	CheckTokensEqual([
			startTag('input', ['disabled', ''], True)
	]);
end;

procedure THtmlTokenizerTests.Teset_ASelfClosingTagWithValuelessAttributesWithoutSpaceBeforeClosingRegression;
begin
	Tokenize('<input disabled/>');
	CheckTokensEqual([
			startTag('input', ['disabled', ''], True)
	]);
end;

procedure THtmlTokenizerTests.Test_ASelfClosingTagWithAnAttributeWithUnquotedValueWithoutSpaceBeforeClosingRegression;
begin
	Tokenize('<input data-foo=bar/>');
	CheckTokensEqual([
			startTag('input', ['data-foo', 'bar'], True)
	]);
end;

procedure THtmlTokenizerTests.Test_ATagWithASlashInTheMiddle;
begin
	Tokenize('<img / src="foo.png">');
	CheckTokensEqual([
			startTag('img', ['src', 'foo.png'], False)
	]);
end;

procedure THtmlTokenizerTests.Test_AnOpeningAndClosingTagWithSomeContent;
begin
	Tokenize('<div id=''foo'' class=''{{bar}} baz''>Some content</div>');
	CheckTokensEqual([
			startTag('div', ['id', 'foo', 'class', '{{bar}} baz'], False),
			//chars('Some content'),
			charToken('Some content'),
			endTag('div')
	]);
end;

procedure THtmlTokenizerTests.Test_AComment;
begin
	Tokenize('<!-- hello -->');
	CheckTokensEqual([
			comment(' hello ')
	]);
end;

procedure THtmlTokenizerTests.Test_ABuggyCommentWithNoEndingDoubleDash;
begin
	Tokenize('<!-->');
	CheckTokensEqual([
			comment('')
	]);
end;

procedure THtmlTokenizerTests.Test_ACommentThatImmediatelyCloses;
begin
	Tokenize('<!---->');
	CheckTokensEqual([
			comment('')
	]);
end;

procedure THtmlTokenizerTests.Test_ACommentThatContainsADash;
begin
	Tokenize('<!-- A perfectly legal - appears -->');
	CheckTokensEqual([
			comment(' A perfectly legal - appears ')
	]);
end;

procedure THtmlTokenizerTests.Test_ABuggyCommentThatContainsTwoDashes;
begin
	Tokenize('<!-- A questionable -- appears -->');
	CheckTokensEqual([
			comment(' A questionable -- appears ')
	]);
end;

procedure THtmlTokenizerTests.Test_CharacterReferencesAreExpanded;
const
	blk12 = #$2592; // U+2592 MEDIUM SHADE
	NotGreaterFullEqual = #$2267+#$0338; // U+2267 GREATER-THAN OVER EQUAL TO | U+0338 COMBINING LONG SOLIDUS OVERLAY
	nleqq = #$2266#$0338; // U+02266 | U+00338
begin
	Tokenize('&quot;Foo &amp; Bar&quot; &lt; &#60;&#x3c; &#x3C; &LT; &NotGreaterFullEqual; &Borksnorlax; &nleqq;');
	CheckTokensEqual([
			charToken('"Foo & Bar" < '#60#$3c' < '+NotGreaterFullEqual+' &Borksnorlax; '+nleqq)
	]);

	Tokenize('<div title=''&quot;Foo &amp; Bar&quot; &blk12; &lt; &#60;&#x3c; &#x3C; &LT; &NotGreaterFullEqual; &Borksnorlax; &nleqq;''>');
	CheckTokensEqual([
			startTag('div', ['title', '"Foo & Bar" '+blk12+' < '#60#$3c' '#$3c' < '+NotGreaterFullEqual+' &Borksnorlax; '+nleqq], False)
	]);
end;

procedure THtmlTokenizerTests.Test_ANewlineImmediatelyFollowingAPreTagIsStripped;
begin
// https://html.spec.whatwg.org/multipage/syntax.html#element-restrictions
{
	A single newline may be placed immediately after the start tag of pre and textarea elements.
	This does not affect the processing of the element.
	The otherwise optional newline must be included if the element's contents
	themselves start with a newline (because otherwise the leading newline in the
	contents would be treated like the optional newline, and ignored).

	NOTE: I know this texts is called "is stripped". That's because the tokenizer i took
	this from decided it should be stripped. I'm certain that's a function of the
	tree construction stage, and not the tokenizer.

	TODO: Confirm that the *tokenizer* shold include the newline that occurs immediately
		after the start tag of a PRE element.
}
	Tokenize('<pre>'+LF+'hello</pre>');
	CheckTokensEqual([
			startTag('pre'),
			charToken(LF+'hello'),
			endTag('pre')
	]);
end;

procedure THtmlTokenizerTests.Test_ANewlineImmediatelyFollowingAClosingPreTagIsNotStripped;
begin
	Tokenize(LF+'<pre>'+LF+'hello</pre>'+LF);
	CheckTokensEqual([
			charToken(LF),
			startTag('pre'),
			charToken(LF+'hello'),
			endTag('pre'),
			charToken(LF)
	]);
end;

procedure THtmlTokenizerTests.Test_ANewlineImmediatelyFollowingAnUppercasePreTagIsStripped;
begin
// https://html.spec.whatwg.org/multipage/syntax.html#element-restrictions
	Tokenize('<PRE>'+LF+'hello</PRE>');
	CheckTokensEqual([
			startTag('pre'),
			charToken(LF+'hello'),
			endTag('pre')
	]);
end;

// https://html.spec.whatwg.org/multipage/syntax.html#element-restrictions
procedure THtmlTokenizerTests.Test_ANewlineImmediatelyFollowingATextareaTagIsStripped;
begin
	Tokenize('<textarea>'+LF+'hello</textarea>');
	CheckTokensEqual([
			startTag('textarea'),
			charToken(LF+'hello'),
			endTag('textarea')
	]);
end;

// https://html.spec.whatwg.org/multipage/semantics.html#the-title-element
procedure THtmlTokenizerTests.Test_TheTitleElementContentIsAlwaysText;
begin
	Tokenize('<title>&quot;hey <b>there</b><!-- comment --></title>');
	CheckTokensEqual([
			startTag('title'),
			charToken('"hey <b>there</b><!-- comment -->'),
			endTag('title')
	]);
end;

// https://github.com/emberjs/ember.js/issues/18530
procedure THtmlTokenizerTests.Test_TitleElementContentIsNotText;
begin
	Tokenize('<Title><!-- hello --></Title>');
	CheckTokensEqual([
			startTag('title'),
			comment(' hello '),
			endTag('title')
	]);
end;

// https://html.spec.whatwg.org/multipage/semantics.html#the-style-element
procedure THtmlTokenizerTests.Test_TheStyleElementContentIsAlwaysText;
begin
	Tokenize('<style>&quot;hey <b>there</b><!-- comment --></style>');
	CheckTokensEqual([
			startTag('style'),
			charToken('"hey <b>there</b><!-- comment -->'),
			endTag('style')
	]);
end;

// https://html.spec.whatwg.org/multipage/scripting.html#restrictions-for-contents-of-script-elements
procedure THtmlTokenizerTests.Test_TheScriptElementContentRestrictions;
begin
	Tokenize('<script>&quot;hey <b>there</b><!-- comment --></script>');
	CheckTokensEqual([
			startTag('script'),
			charToken('"hey <b>there</b><!-- comment -->'),
			endTag('script')
	]);
end;

procedure THtmlTokenizerTests.Test_TwoFollowingScriptTags;
begin
	Tokenize('<script><!-- comment --></script> <script>second</script>');

	CheckTokensEqual([
			startTag('script'),
			charToken('<!-- comment -->'),
			endTag('script'),
			charToken(' '),
			startTag('script'),
			charToken('second'),
			endTag('script')
	]);
end;

// https://github.com/emberjs/rfcs/blob/master/text/0311-angle-bracket-invocation.md#dynamic-invocations
procedure THtmlTokenizerTests.Test_AnEmberishNamedArgInvocation;
begin
	Tokenize('<@foo></@foo>');
	CheckTokensEqual([
			charToken('<@foo>'),
			comment('@foo')
	]);

{
	TODO: His test says it should be:

		- StartTag: @foo
		- EndTag:   @foo

	Actual:

		- characters: <@foo>
		- Comment:    @foo
}
end;

procedure THtmlTokenizerTests.Test_ParsingScriptsOutOfAcomplexHTMLDocument;
begin
	Tokenize('<!DOCTYPE html><html><head><script src="/foo.js"></script><script src="/bar.js"></script><script src="/baz.js"></script></head></html>');
	CheckTokensEqual([
			doctype(),
			startTag('html'),
			startTag('head'),
			startTag('script', ['src','/foo.js'], False),
			endTag('script'),
			startTag('script', ['src','/bar.js'], True),
			endTag('script'),
			startTag('script', ['src','/baz.js'], True),
			endTag('script'),
			endTag('head'),
			endTag('html')
	]);
end;

procedure THtmlTokenizerTests.Test_CarriageReturnsAreReplacedWithLineFeeds;
begin
//	Tokenize('\r\r\n\r\r\n\n');
	Tokenize(CR+CR+LF+CR+CR+LF+LF); //  \r \r \n \r \r \n \n
	CheckTokensEqual([
			//chars('\n\n\n\n\n')
			charToken(LF+LF+LF+LF+LF)
	]);
end;

{procedure THtmlTokenizerTests.Test_LinesAreCountedCorrectly;
begin
	Tokenize('\r\r\n\r\r\n\n'); // loc: true
	CheckTokensEqual([
			locInfo(
				//chars('\n\n\n\n\n')
			charToken(LF),
			charToken(LF),
			charToken(LF),
			charToken(LF),
			charToken(LF), 1, 0, 6, 0)
	]);
end;}

{procedure THtmlTokenizerTests.Test_TokensChars;
begin
	Tokenize('Chars'); // loc: true
	CheckTokensEqual([
			locInfo(chars('Chars'), 1, 0, 1, 5)
	]);
end;}

{procedure THtmlTokenizerTests.Test_TokensCharsStartTagChars;
begin
	Tokenize('Chars<div>Chars'); // loc: true
	CheckTokensEqual([
			locInfo(chars('Chars'), 1, 0, 1, 5),
			locInfo(startTag('div'), 1, 5, 1, 10),
			locInfo(chars('Chars'), 1, 10, 1, 15)
	]);
end;}

{procedure THtmlTokenizerTests.TestTokensStartTagStartTag;
begin
	Tokenize('<div><div>'); // loc: true
	CheckTokensEqual([
			locInfo(startTag('div'), 1, 0, 1, 5),
			locInfo(startTag('div'), 1, 5, 1, 10)
  ]);
end;}

{procedure THtmlTokenizerTests.Test_TokensHtmlCharRefStartTag;
begin
	Tokenize('&gt;<div>'); // loc: true
	CheckTokensEqual([
			locInfo(chars('>'), 1, 0, 1, 4),
			locInfo(startTag('div'), 1, 4, 1, 9)
	]);
end;}

{procedure THtmlTokenizerTests.Test_tokensCharsStartTagCharsStartTag;
begin
	Tokenize('Chars\n<div>Chars\n<div>'); // loc: true
	CheckTokensEqual([
			locInfo(chars('Chars\n'), 1, 0, 2, 0),
			locInfo(startTag('div'), 2, 0, 2, 5),
			locInfo(chars('Chars\n'), 2, 5, 3, 0),
			locInfo(startTag('div'), 3, 0, 3, 5)
	]);
end;}

{procedure THtmlTokenizerTests.Test_TokensCommentStartTagCharsEndTag;
begin
	Tokenize('<!-- multline\ncomment --><div foo=bar>Chars\n</div>'); // loc: true
	CheckTokensEqual([
			locInfo(comment(' multline\ncomment '), 1, 0, 2, 11),
			locInfo(startTag('div', ['foo', 'bar'], False), 2, 11, 2, 24),
			locInfo(chars('Chars\n'), 2, 24, 3, 0),
			locInfo(endTag('div'), 3, 0, 3, 6)
	]);
end;}

initialization
	TestFramework.RegisterTest('HTMLParser\THtmlTokenizerTests', THtmlTokenizerTests.Suite);

end.
