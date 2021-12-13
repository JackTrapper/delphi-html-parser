unit HtmlDOM;

interface

uses
  DOMCore, DomTraversal, HtmlTags;

const
  NO_DOCTYPE         = 0;
  DTD_HTML_STRICT    = 1;
  DTD_HTML_LOOSE     = 2;
  DTD_HTML_FRAMESET  = 3;
  DTD_XHTML_STRICT   = 4;
  DTD_XHTML_LOOSE    = 5;
  DTD_XHTML_FRAMESET = 6;

  END_TAG_NODE       = 255;

type
  THtmlElement = class(TElement)
  private
    FHtmlTag: THtmlTag;
  protected
    constructor Create(ownerDocument: TDocument; const namespaceURI, qualifiedName: TDomString; withNS: Boolean);
  public
    property HtmlTag: THtmlTag read FHtmlTag;
  end;

  THtmlEndTag = class(THtmlElement)
  protected
    function GetNodeType: Integer; override;
  end;

  TCustomParser = class;
  TCustomFormatter = class;

  THtmlDocument = class(TDocumentTraversal)
  private
    FHtmlParser: TCustomParser;
    FHtmlFormatter: TCustomFormatter;
    FTextFormatter: TCustomFormatter;
    function GetHtml: TDomString;
    function GetText: TDomString;
    procedure SetHtml(const htmlStr: TDomString);
    destructor Destroy; override;
  public
    function createHtmlElement(const tagName: TDomString): THtmlElement;
    function createHtmlElementNS(const namespaceURI, qualifiedName: TDomString): THtmlElement;
    function createHtmlEndTag(const tagName: TDomString): THtmlElement;
    function loadHTML(const htmlStr: TDomString): Boolean;
    property htmlParser: TCustomParser read FHtmlParser write FHtmlParser;
    property htmlFormatter: TCustomFormatter read FHtmlFormatter write FHtmlFormatter;
    property textFormatter: TCustomFormatter read FTextFormatter write FTextFormatter;
    property html: TDomString read GetHtml write SetHtml;
    property text: TDomString read GetText;
  end;

  HtmlDomImplementation = class(DOMImplementation)
  private
    //class function createHtmlDocumentType(htmlDocType: Integer): TDocumentType;
  public
    class function createHtmlDocument(htmlDocType: Integer): THtmlDocument;
  end;

  TCustomParser = class
  private
    FHtmlDocument: THtmlDocument;
  public
    constructor Create(HtmlDocument: THtmlDocument);
    function loadHTML(const HtmlStr: TDomString): Boolean; virtual; abstract;
    property htmlDocument: THtmlDocument read FHtmlDocument;
  end;

  TCustomFormatter = class(TNodeFilter)
  private
    FHtmlDocument: THtmlDocument;
  public
    constructor Create(HtmlDocument: THtmlDocument);
    function getText: TDomString; virtual; abstract;
    property htmlDocument: THtmlDocument read FHtmlDocument;
  end;

implementation

uses
  SysUtils, HtmlParser, HtmlFormatter;
  
type
  TDTDParams = record
    PublicId: TDomString;
    SystemId: TDomString;
  end;

  TDTDList = array[DTD_HTML_STRICT..DTD_XHTML_FRAMESET] of TDTDParams;

const
  DTDList: TDTDList = (
    (publicId: '-//W3C//DTD HTML 4.01//EN';              systemId: 'http://www.w3.org/TR/html4/strict.dtd'),
    (publicId: '-//W3C//DTD HTML 4.01 Transitional//EN'; systemId: 'http://www.w3.org/TR/1999/REC-html401-19991224/loose.dtd'),
    (publicId: '-//W3C//DTD HTML 4.01 Frameset//EN';     systemId: 'http://www.w3.org/TR/1999/REC-html401-19991224/frameset.dtd'),
    (publicId: '-//W3C//DTD XHTML 1.0 Strict//EN';       systemId: 'http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd'),
    (publicId: '-//W3C//DTD XHTML 1.0 Transitional//EN'; systemId: 'http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd'),
    (publicId: '-//W3C//DTD XHTML 1.0 Frameset//EN';     systemId: 'http://www.w3.org/TR/xhtml1/DTD/xhtml1-frameset.dtd')
  );

  HTML_TAG_NAME = 'html';
  XHTML_NAMESPACE = 'http://www.w3.org/1999/xhtml';


constructor THtmlElement.Create(ownerDocument: TDocument; const namespaceURI, qualifiedName: TDomString; withNS: Boolean);
begin
  inherited Create(ownerDocument, namespaceURI, qualifiedName, withNS);
  FHtmlTag := HtmlTagList.GetTagByName(localName);
  if FHtmlTag = nil then
    raise Exception.Create(localName)
end;

function THtmlEndTag.GetNodeType: Integer;
begin
  Result := END_TAG_NODE
end;

destructor THtmlDocument.Destroy;
begin
  if Assigned(htmlParser) then
    htmlParser.Free;
  if Assigned(htmlFormatter) then
    htmlFormatter.Free;
  if Assigned(textFormatter) then
    textFormatter.Free;
  inherited Destroy
end;

function THtmlDocument.GetHtml: TDomString;
begin
  if Assigned(FHtmlFormatter) then
    Result := FHtmlFormatter.GetText
  //TODO
end;

function THtmlDocument.GetText: TDomString;
begin
  if Assigned(FTextFormatter) then
    Result := FTextFormatter.GetText
  //TODO
end;

procedure THtmlDocument.SetHtml(const htmlStr: TDomString);
begin
  loadHtml(htmlStr)
end;

function THtmlDocument.createHtmlElement(const tagName: TDomString): THtmlElement;
begin
  Result := THtmlElement.Create(Self, '', tagName, false)
end;

function THtmlDocument.createHtmlElementNS(const namespaceURI, qualifiedName: TDomString): THtmlElement;
begin
  Result := THtmlElement.Create(Self, namespaceURI, qualifiedName, true)
end;

function THtmlDocument.createHtmlEndTag(const tagName: TDomString): THtmlElement; 
begin
  Result := THtmlEndTag.Create(Self, '', tagName, false)
end;

function THtmlDocument.loadHTML(const htmlStr: TDomString): Boolean;
begin
  if FHtmlParser <> nil then
    Result := FHtmlParser.loadHtml(htmlStr)
  else
    Result := false
end;
{
class function HtmlDomImplementation.createHtmlDocumentType(htmlDocType: Integer): TDocumentType;
begin
  if htmlDocType in [DTD_HTML_STRICT..DTD_XHTML_FRAMESET] then
    with DTDList[htmlDocType] do
      Result := createDocumentType(HTML_TAG_NAME, publicId, systemId)
  else
    Result := nil
end;
}
class function HtmlDomImplementation.createHtmlDocument(htmlDocType: Integer): THtmlDocument;
begin
  Result := THtmlDocument.Create(nil); //TODO createHtmlDocumentType(htmlDocType));
  if htmlDocType in [DTD_HTML_STRICT..DTD_HTML_FRAMESET] then
    Result.appendChild(Result.createHtmlElement(HTML_TAG_NAME))
  else
    Result.appendChild(Result.createHtmlElementNS(XHTML_NAMESPACE, HTML_TAG_NAME))
end;

constructor TCustomParser.Create(HtmlDocument: THtmlDocument);
begin
  inherited Create;
  FHtmlDocument := HtmlDocument
end;

constructor TCustomFormatter.Create(HtmlDocument: THtmlDocument);
begin
  inherited Create;
  FHtmlDocument := HtmlDocument
end;

end.
