unit UHTML;
interface

uses
  SysUtils,Classes,Generics.Collections;

{$REGION ' About '}
///////////////////////////////////////////////////////////////////////////////////////////////////////
///  Автор: Григорьев Е.В.
///  Описание: Библиотека для работы с HTML обьектами
///  email: jhonny_@mail.ru
///
///////////////////////////////////////////////////////////////////////////////////////////////////////
{$ENDREGION}

type

  IHTMLObject = interface
    function GetAttr(Index: string): string;
    function GetInnerText: string;
    procedure Parse(var CurrentPosition : integer);
    function GetChilds(Index: integer): IHTMLObject; overload;
    function GetCount: integer;
    function GetTag: string;
    function GetHTML: string;
    function GetLevel: Integer;
    function GetParent: IHTMLObject;
    function GetStart : integer;
    function GetOwner: IHTMLObject;
    function GetFinish : integer;
    function GetElements(ATag : string) : TList<IHTMLObject>; overload;
    function GetElements(ATag,AAttribute,AValue: string; ADue : boolean = false) : TList<IHTMLObject>; overload;
    function GetElement(ATag,Attribute,AValue : string; ADue : boolean = false) : IHTMLObject; overload;
    function GetElement(ATag,AText : string; ADue : boolean = false) : IHTMLObject; overload;
    property Count : integer read GetCount; // количество дочерних обьектов
    property Parent : IHTMLObject read GetParent; // Родительский объект
    property Level : Integer read GetLevel; // уровень вложенности
    property HTML : string read GetHTML; // полный HTML код объекта
    property InnerText : string read GetInnerText;
    property Attr[Index : string] : string read GetAttr;
    property Items[Index : integer] : IHTMLObject read GetChilds; default;// Дочерние объекты по порядковому индексу
    property Start : integer read GetStart; // начальный текстовый индекс обьекта
    property Finish : Integer read GetFinish; // конечный текстовый индекс обьекта
    property Tag : string read GetTag;
    property Owner : IHTMLObject read GetOwner;
    //property Obj : TObject read GetObj write SetObj;
  end;

  EHTMLException = class(Exception);
  EHTMLConvertError = class(EHTMLException);

function ParseHTML(AHTML : string) : IHTMLObject; // Разбор строки
function LoadHTML(AFileName : string) : IHTMLObject; //Загрузка файла с разбором

implementation

var

  HTMLCodes : TDictionary<string,string>;

  {$REGION 'arrCodes'}
  const
    EXT_CODES : array [0..237] of array[0..1] of string = ( ('"','&#34;'),('''','&#39;'),('&','&#38;'),('<','&#60;'),('>','&#62;'),(' ','&#160;'),('¡','&#161;'),
    ('¢','&#162;'),('£','&#163;'),('¤','&#164;'),('¥','&#165;'),('¦','&#166;'),('§','&#167;'),('¨','&#168;'),('©','&#169;'),('ª','&#170;'),('«','&#171;'),('¬','&#172;'),
    ('®','&#174;'),('¯','&#175;'),('°','&#176;'),('±','&#177;'),('²','&#178;'),('³','&#179;'),('´','&#180;'),('µ','&#181;'),('¶','&#182;'),('·','&#183;'),('¸','&#184;'),('¹','&#185;'),
    ('º','&#186;'),('»','&#187;'),('¼','&#188;'),('½','&#189;'),('¾','&#190;'),('¿','&#191;'),('×','&#215;'),('÷','&#247;'),('Œ','&#338;'),('œ','&#339;'),('Š','&#352;'),
    ('š','&#353;'),('Ÿ','&#376;'),('ƒ','&#402;'),('ˆ','&#710;'),('˜','&#732;'),('–','&#8211;'),('—','&#8212;'),('‘','&#8216;'),('’','&#8217;'),('‚','&#8218;'),('“','&#8220;'),
    ('”','&#8221;'),('„','&#8222;'),('†','&#8224;'),('‡','&#8225;'),('•','&#8226;'),('…','&#8230;'),('‰','&#8240;'),('′','&#8242;'),('″','&#8243;'),('‹','&#8249;'),
    ('›','&#8250;'),('‾','&#8254;'),('€','&#8364;'),('™','&#8482;'),('™','&#153;'),('←','&#8592;'),('↑','&#8593;'),('→','&#8594;'),('↓','&#8595;'),('↔','&#8596;'),('↵','&#8629;'),
    ('⌈','&#8968;'),('⌉','&#8969;'),('⌊','&#8970;'),('⌋','&#8971;'),('◊','&#9674;'),('♠','&#9824;'),('♣','&#9827;'),('♥','&#9829;'),('♦','&#9830;'),('∀','&#8704;'),
    ('∂','&#8706;'),('∃','&#8707;'),('∅','&#8709;'),('∇','&#8711;'),('∈','&#8712;'),('∉','&#8713;'),('∋','&#8715;'),('∏','&#8719;'),('∑','&#8721;'),('−','&#8722;'),
    ('∗','&#8727;'),('√','&#8730;'),('∝','&#8733;'),('∞','&#8734;'),('∠','&#8736;'),('∧','&#8743;'),('∨','&#8744;'),('∩','&#8745;'),('∪','&#8746;'),('∫','&#8747;'),
    ('∴','&#8756;'),('∼','&#8764;'),('≅','&#8773;'),('≈','&#8776;'),('≠','&#8800;'),('≡','&#8801;'),('≤','&#8804;'),('≥','&#8805;'),('⊂','&#8834;'),('⊃','&#8835;'),
    ('⊄','&#8836;'),('⊆','&#8838;'),('⊇','&#8839;'),('⊕','&#8853;'),('⊗','&#8855;'),('⊥','&#8869;'),('⋅','&#8901;'),
    ('"','&quot;'),('''','&apos;'),('&','&amp;'),('<','&lt;'),('>','&gt;'),(' ','&nbsp;'),('¡','&iexcl;'),('¢','&cent;'),
    ('£','&pound;'),('¤','&curren;'),('¥','&yen;'),('¦','&brvbar;'),('§','&sect;'),('¨','&uml;'),('©','&copy;'),('ª','&ordf;'),('«','&laquo;'),('¬','&not;'),('®','&reg;'),('¯','&macr;'),
    ('°','&deg;'),('±','&plusmn;'),('²','&sup2;'),('³','&sup3;'),('´','&acute;'),('µ','&micro;'),('¶','&para;'),('·','&middot;'),('¸','&cedil;'),('¹','&sup1;'),('º','&ordm;'),('»','&raquo;'),
    ('¼','&frac14;'),('½','&frac12;'),('¾','&frac34;'),('¿','&iquest;'),('÷','&divide;'),('Œ','&OElig;'),('œ','&oelig;'),('Š','&Scaron;'),('š','&scaron;'),
    ('Ÿ','&Yuml;'),('ƒ','&fnof;'),('ˆ','&circ;'),('˜','&tilde;'),('–','&ndash;'),('—','&mdash;'),('‘','&lsquo;'),('’','&rsquo;'),('‚','&sbquo;'),('“','&ldquo;'),('”','&rdquo;'),
    ('„','&bdquo;'),('†','&dagger;'),('‡','&Dagger;'),('•','&bull;'),('…','&hellip;'),('‰','&permil;'),('′','&prime;'),('″','&Prime;'),('‹','&lsaquo;'),('›','&rsaquo;'),
    ('‾','&oline;'),('€','&euro;'),('←','&larr;'),('↑','&uarr;'),('→','&rarr;'),('↓','&darr;'),('↔','&harr;'),('↵','&crarr;'),('⌈','&lceil;'),('⌉','&rceil;'),
    ('⌊','&lfloor;'),('⌋','&rfloor;'),('◊','&loz;'),('♠','&spades;'),('♣','&clubs;'),('♥','&hearts;'),('♦','&diams;'),('∀','&forall;'),('∂','&part;'),('∃','&exist;'),
    ('∅','&empty;'),('∇','&nabla;'),('∈','&isin;'),('∉','&notin;'),('∋','&ni;'),('∏','&prod;'),('∑','&sum;'),('−','&minus;'),('∗','&lowast;'),('×','&times;'),('√','&radic;'),
    ('∝','&prop;'),('∞','&infin;'),('∠','&ang;'),('∧','&and;'),('∨','&or;'),('∩','&cap;'),('∪','&cup;'),('∫','&int;'),('∴','&there4;'),('∼','&sim;'),('≅','&cong;'),
    ('≈','&asymp;'),('≠','&ne;'),('≡','&equiv;'),('≤','&le;'),('≥','&ge;'),('⊂','&sub;'),('⊃','&sup;'),('⊄','&nsub;'),('⊆','&sube;'),('⊇','&supe;'),('⊕','&oplus;'),
    ('⊗','&otimes;'),('⊥','&perp;'),('⋅','&sdot;'));
  {$ENDREGION}

type

  TStringElement = packed record
    Start,Finish : integer;
  end;

  THTML = class;

  TAttributeElement = record
    Name : TStringElement;
    Value : TStringElement;
  end;

  THTMLObject = class(TInterfacedObject,IHTMLObject)
  private
    FOwner : THTML;
    FHTML : TStringElement;
    FTag : TStringElement;
    FLevel : Integer;
    FChilds : TList<IHTMLObject>;
    FAttributes : TList<TAttributeElement>;
    FParentObj: THTMLObject;
    FClosed: boolean;
    function GetStrValue(AStrElement : TStringElement) : string;
    function GetObj: THTMLObject;
    procedure SetParentObj(const Value: THTMLObject);
    procedure SetClosed(const Value: boolean);
    function GetOwner: IHTMLObject;
  protected
    function GetAttr(Index: string): string;
    function GetInnerText: string;
    procedure Parse(var CurrentPosition : integer);
    procedure ReadHeader(var CurrentPosition : integer);
    procedure ReadNodes(var CurrentPosition : integer);
    procedure ReadsAttributes(var CurrentPosition : integer);
    function GetChilds(Index: integer): IHTMLObject; overload;
    function GetCount: integer;
    function GetTag: string; virtual;
    function GetHTML: string; virtual;
    function GetLevel: Integer;
    function GetParent: IHTMLObject;
    function GetStart : integer;
    function GetFinish : integer;
    function GetElements(ATag : string) : TList<IHTMLObject>; overload;
    function GetElements(ATag,AAttribute,AValue: string; ADue : boolean = true) : TList<IHTMLObject>; overload;
    function GetElement(ATag,Attribute,AValue : string; ADue : boolean = false) : IHTMLObject; overload;
    function GetElement(ATag,AText : string; ADue : boolean = false) : IHTMLObject; overload;
  public
    constructor Create(AOwner : THTML); overload; virtual;
    destructor Destroy; override;
    property ParentObj : THTMLObject read FParentObj write SetParentObj;
    property Closed : boolean read FClosed write SetClosed;
    property Owner : IHTMLObject read GetOwner;
  end;


  THTML = class(THTMLObject)
  private
  protected
    function GetTag: string; override;
    function GetHTML: string; override;
  public
    FText: string;
    FTagStack : TList<THTMLObject>;
    constructor Create; overload;
    destructor Destroy; override;
    procedure LoadFromFile(AFileName : string);
    procedure LoadFromString(AString : string);
  end;

function LoadHTML(AFileName : string) : IHTMLObject;
var
  tmpHTML : THTML;
begin
  tmpHTML := THTML.Create;
  tmpHTML.LoadFromFile(AFileName);
  Result := tmpHTML;
end;

function ParseHTML(AHTML : string) : IHTMLObject;
var
  tmpHTML : THTML;
begin
  tmpHTML := THTML.Create;
  tmpHTML.LoadFromString(AHTML);
  Result := tmpHTML;
end;

procedure SkipSymbols(var CurrentPosition : integer; AData : string; ASymbol : Char);
var
  I: Integer;
begin
  for I := CurrentPosition to High(AData) do
    if AData[I] <> ASymbol then
    begin
      CurrentPosition := I;
      Exit;
    end;
end;

procedure SkipTo(var CurrentPosition : integer; AData : string; ASymbol : Char);
var
  I: Integer;
begin
  for I := CurrentPosition to High(AData) do
    if (AData[I] = ASymbol) then
    begin
      CurrentPosition := I;
      Exit;
    end;
end;

procedure SkipNoText(var CurrentPosition : integer; AData : string);
var
  I: Integer;
begin
  for I := CurrentPosition to High(AData) do
    if not (AData[i] in [' ',#9,#10,#13]) then
    begin
      CurrentPosition := I;
      Exit;
    end;
end;



{ THTML }

destructor THTML.Destroy;
begin
  FreeAndNil(FTagStack);
  inherited;
end;

function THTML.GetHTML: string;
begin
  Result := FText;
end;

function THTML.GetTag: string;
begin
  Result := 'Root';
end;

procedure THTML.LoadFromFile(AFileName: string);
var
  tmpFile : TStringStream;
begin
  tmpFile := TStringStream.Create;
  try
    tmpFile.LoadFromFile(AFileName);
    LoadFromString(tmpFile.DataString);
  finally
    FreeAndNil(tmpFile);
  end;
end;

constructor THTML.Create;
begin
  inherited Create(Self);
  FTagStack := TList<THTMLObject>.Create;
  FTagStack.Add(Self);
end;

procedure THTML.LoadFromString(AString: string);
var
  tmpCur : integer;
  tmpObj : THTMLObject;
  I: Integer;
begin
  FText := AString;
 // Clear(FText);
  tmpCur := 1;
  ReadNodes(tmpCur);
  for I := 1 to FTagStack.Count - 1 do
    FChilds.Add(FTagStack[I]);
  FTagStack.Clear;
end;

{ THTMLObject }

function THTMLObject.GetAttr(Index: string): string;
var
  I: Integer;
begin
  Result := '';
  for I := 0 to FAttributes.Count - 1 do
    if GetStrValue(FAttributes[i].Name).ToUpperInvariant = Index.ToUpperInvariant then
    begin
      Result := GetStrValue(FAttributes[i].Value);
      Break;
    end;
end;

function THTMLObject.GetChilds(Index: integer): IHTMLObject;
begin
  Result := FChilds[Index];
end;

constructor THTMLObject.Create(AOwner: THTML);
begin
  FOwner := AOwner;
  FChilds := TList<IHTMLObject>.Create;
  FAttributes := TList<TAttributeElement>.Create;
end;

destructor THTMLObject.Destroy;
begin
  FreeAndNil(FChilds);
  FreeAndNil(FAttributes);
  inherited;
end;

function THTMLObject.GetCount: integer;
begin
  Result := FChilds.Count;
end;

function THTMLObject.GetElement(ATag, Attribute, AValue: string; ADue: boolean): IHTMLObject;
var
  tmpElements : TList<IHTMLObject>;
begin
  Result := nil;
  tmpElements := GetElements(ATag,Attribute,AValue,ADue);
  if not Assigned(tmpElements) then Exit;
  try
    if tmpElements.Count > 0 then
      Result := tmpElements[0];
  finally
    FreeAndNil(tmpElements);
  end;
end;

function THTMLObject.GetElement(ATag, AText: string; ADue: boolean): IHTMLObject;
var
  i : integer;
  tmpList : TList<IHTMLObject>;
begin
  Result := nil;
  tmpList := GetElements(ATag);
  try
    for I := 0 to tmpList.Count - 1 do
    begin
      Result := tmpList[i];
      if not ADue then
      begin
        if Pos(AText.ToUpperInvariant,Result.innerText.ToUpperInvariant) > 0 then Exit
        else Result := nil;
      end
      else
      begin
        if AText.ToUpperInvariant = (string(Result.innerText)).ToUpperInvariant then Exit
        else Result := nil;
      end;
    end;
  finally
    FreeAndNil(tmpList);
  end;
end;

function THTMLObject.GetElements(ATag, AAttribute, AValue: string;  ADue: boolean): TList<IHTMLObject>;
var
  I: Integer;
  tmpList : TList<IHTMLObject>;
  tmpValue : string;
begin
  tmpValue := AValue.ToUpperInvariant;
  Result := TList<IHTMLObject>.Create;
  for I := 0 to FChilds.Count - 1 do
    if FChilds[i].Tag <> '' then
    begin
      if FChilds[I].Tag.ToUpperInvariant = ATag.ToUpperInvariant then
        if ADue then
        begin
          if FChilds[I].Attr[AAttribute].ToUpperInvariant = tmpValue then
            Result.Add(FChilds[I]);
        end
        else
        begin
          if Pos(tmpValue,FChilds[I].Attr[AAttribute].ToUpperInvariant) > 0  then
            Result.Add(FChilds[I]);
        end;
      tmpList := FChilds[I].GetElements(ATag,AAttribute,AValue,ADue);
      Result.AddRange(tmpList);
      FreeAndNil(tmpList);
    end;
end;

function THTMLObject.GetElements(ATag: string): TList<IHTMLObject>;
var
  I: Integer;
  tmpList : TList<IHTMLObject>;
begin
  Result := TList<IHTMLObject>.Create;
  for I := 0 to FChilds.Count - 1 do
    if FChilds[i].Tag <> '' then
    begin
      if FChilds[I].Tag.ToUpperInvariant = ATag.ToUpperInvariant then
        Result.Add(FChilds[I]);
      tmpList := FChilds[I].GetElements(ATag);
      Result.AddRange(tmpList);
      FreeAndNil(tmpList);
    end;
end;

function THTMLObject.GetFinish: integer;
begin
  Result := FHTML.Finish;
end;

function THTMLObject.GetLevel: Integer;
begin
  Result := FLevel;
end;

function THTMLObject.GetObj: THTMLObject;
begin
  Result := Self;
end;

function THTMLObject.GetOwner: IHTMLObject;
begin
  Result := FOwner;
end;

function THTMLObject.GetParent: IHTMLObject;
begin
  Result := FParentObj;
end;

function THTMLObject.GetStart: integer;
begin
  Result := FHTML.Start;
end;

function THTMLObject.GetStrValue(AStrElement: TStringElement): string;
begin
  Result := '';
  if AStrElement.Start = 0 then Exit;
  Result := Trim(Copy(FOwner.FText,AStrElement.Start,AStrElement.Finish - AStrElement.Start + 1));
end;

function THTMLObject.GetTag: string;
begin
  Result := GetStrValue(FTag)
end;

function THTMLObject.GetHTML: string;
begin
  Result := GetStrValue(FHTML)
end;

function THTMLObject.GetInnerText: string;
var
  I,J,K: Integer;
  tmpText,tmpCorrectText,tmpCode,tmpCodeTr : string;
begin
  Result := '';
  for I := 0 to FChilds.Count - 1 do
  begin
    if FChilds[i].Tag <> '' then
      Result := Result + FChilds[i].InnerText
    else
    begin
      tmpCorrectText := FChilds[i].HTML;
      {tmpText := FChilds[i].HTML;
      J := 1;
      while J <= Length(tmpText) do
      begin
        if tmpText[J] = '&' then
        begin
          K := Pos(';',tmpText,J) - J + 1;
          tmpCode := Copy(tmpText,J,K);
          Inc(J,K);
          if not HTMLCodes.TryGetValue(tmpCode,tmpCodeTr) then
            tmpCodeTr := tmpCode;
          tmpCorrectText := tmpCorrectText + tmpCodeTr;
        end
        else
        begin
          tmpCorrectText := tmpCorrectText + tmpText[J];
          Inc(J);
        end;
      end;  }
      Result := Result + tmpCorrectText;
    end;
  end;
end;

procedure THTMLObject.Parse(var CurrentPosition: integer);
begin
  SkipTo(CurrentPosition,FOwner.FText,'<');
  FHTML.Start := CurrentPosition;
  Inc(CurrentPosition);
  ReadHeader(CurrentPosition);
  FHTML.Finish := CurrentPosition;
  FOwner.FTagStack.Add(Self);
  if FOwner.FText[CurrentPosition - 1] = '/' then
  begin
    Inc(CurrentPosition);
    FHTML.Finish := CurrentPosition - 1;
  end
  else
  begin
    Inc(CurrentPosition);
    ReadNodes(CurrentPosition);
  end;
end;

procedure THTMLObject.ReadHeader(var CurrentPosition: integer);
var
  i,k : integer;
  tmpIsAttr : boolean;
begin
  SkipNoText(CurrentPosition,FOwner.FText);
  FTag.Start := CurrentPosition;
  k := Pos('>',FOwner.FText,CurrentPosition);
  tmpIsAttr := false;
  for I := CurrentPosition to K - 1 do
    if FOwner.FText[i] = '=' then
    begin
      tmpIsAttr := true;
      Break;
    end;

  if tmpIsAttr then
  begin
    SkipTo(CurrentPosition,FOwner.FText,' ');
    FTag.Finish := CurrentPosition - 1;
    ReadsAttributes(CurrentPosition);
    CurrentPosition := k;
  end
  else
  begin
    CurrentPosition := k;
    FTag.Finish := FOwner.FText.IndexOfAny([' ','/','>'],FTag.Start);
  end;
end;

procedure THTMLObject.ReadNodes(var CurrentPosition: integer);
var
  tmpObj : THTMLObject;
  tmpTag,tmp : string;
  l : integer;
  I: Integer;
begin
  while CurrentPosition < Length(FOwner.FText) do
  begin
    while (not ((FOwner.FText[CurrentPosition] = '<') and (FOwner.FText[CurrentPosition + 1] = '/'))) do
    begin
      if CurrentPosition >= Length(FOwner.FText) then Exit;
      if FOwner.FText[CurrentPosition] <> '<' then
      begin
        tmpObj := THTMLObject.Create(FOwner);
        tmpObj.ParentObj := Self;
        tmpObj.FHTML.Start := CurrentPosition;
        SkipTo(CurrentPosition,FOwner.FText,'<');
        tmpObj.FHTML.Finish := CurrentPosition - 1;
        if tmpObj.GetHTML.Trim = '' then
          FreeAndNil(tmpObj)
        else
          FOwner.FTagStack.Add(tmpObj);
      end
      else
      begin
        tmpObj := THTMLObject.Create(FOwner);
        tmpObj.Parse(CurrentPosition);
      end;
    end;

    Inc(CurrentPosition);
    Inc(CurrentPosition);
    L := CurrentPosition;
    SkipTo(CurrentPosition,FOwner.FText,'>');
    tmpTag := Copy(FOwner.FText,L,CurrentPosition - L);

    Inc(CurrentPosition);
    L := -1;
    for I := FOwner.FTagStack.Count - 1 downto 1 do
      if (tmpTag = FOwner.FTagStack[I].GetTag) and (not FOwner.FTagStack[I].Closed) then
      begin
        L := I;
        FOwner.FTagStack[I].Closed := true;
        FOwner.FTagStack[I].FHTML.Finish := CurrentPosition - 1;
        Break;
      end;

    if L <> -1 then
    begin
      for I := L + 1 to FOwner.FTagStack.Count - 1 do
      begin
        FOwner.FTagStack[L].FChilds.Add(FOwner.FTagStack[I]);
        FOwner.FTagStack[I].ParentObj := FOwner.FTagStack[L];
      end;
      FOwner.FTagStack.DeleteRange(L + 1,FOwner.FTagStack.Count - L - 1);
      Exit;
    end;
  end;
end;


procedure THTMLObject.ReadsAttributes(var CurrentPosition: integer);
var
  tmpAttr : TAttributeElement;
  tmpStrFl : boolean;
  K : integer;
begin
  SkipNoText(CurrentPosition,FOwner.FText);
  if FOwner.FText[CurrentPosition] in ['/','>'] then
  begin
    Exit;
  end;

  tmpAttr.Name.Start := CurrentPosition;
  SkipTo(CurrentPosition,FOwner.FText,'=');
  tmpAttr.Name.Finish := CurrentPosition - 1;
  Inc(CurrentPosition);
  SkipNoText(CurrentPosition,FOwner.FText);
  tmpStrFl := FOwner.FText[CurrentPosition]= '"';
  if tmpStrFl then
    Inc(CurrentPosition);

  tmpAttr.Value.Start := CurrentPosition;
  if tmpStrFl then
  begin
    SkipTo(CurrentPosition,FOwner.FText,'"');
    Inc(CurrentPosition);
  end
  else
  begin
    k :=  FOwner.FText.IndexOfAny([' ','/','>'],CurrentPosition) + 1;
    if (FOwner.FText[k+1] <> '>') and (FOwner.FText[k] = '/') then
    begin
      CurrentPosition := k;
      SkipTo(CurrentPosition,FOwner.FText,' ');
    end
    else
      CurrentPosition := k;
  end;

  tmpAttr.Value.Finish := CurrentPosition - 1;

  if tmpStrFl then
    tmpAttr.Value.Finish := tmpAttr.Value.Finish - 1;

  FAttributes.Add(tmpAttr);

  if not (FOwner.FText[CurrentPosition] in ['/','>']) then
    ReadsAttributes(CurrentPosition);

end;

procedure THTMLObject.SetClosed(const Value: boolean);
begin
  FClosed := Value;
end;

procedure THTMLObject.SetParentObj(const Value: THTMLObject);
begin
  FParentObj := Value;
  FLevel := FParentObj.GetLevel + 1;
end;

var
  tmpCodeCounter : Integer;
initialization

  HTMLCodes := TDictionary<string,string>.Create;
  for tmpCodeCounter := 0 to High(EXT_CODES) do
  begin
    HTMLCodes.Add(EXT_CODES[tmpCodeCounter][1],EXT_CODES[tmpCodeCounter][0]);
  end;


finalization

  FreeAndNil(HTMLCodes);

end.
