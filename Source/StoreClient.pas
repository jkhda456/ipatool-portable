unit StoreClient;

interface

uses
  SysUtils, Classes, httpsend, ssl_openssl, ZLib, Synacode;

type
  TStorePayloadReq = class(TObject)
  private
    FDatas: TStringList;

    function _escape(AValue: String): AnsiString;
  public
    appleId: String;
    attempt: String;
    createSession: String;
    password: String;
    rmp: String;
    why: String;

    guid: String;

    creditDisplay: String;
    salableAdamId: String;
    appExtVrsId: String;

    customerMessage: String;

    constructor Create(appleId, password, attempt, createSession, guid, rmp, why: String); overload;
    constructor Create(creditDisplay, guid, salableAdamId, appExtVrsId: String); overload;
    destructor Destroy; override;

    function GetAuthPayload(): AnsiString;
    function GetDownloadPayload(): AnsiString;

    function UpdatePlist(buffer: AnsiString): Integer;

    property Datas: TStringList read FDatas;
  end;

  TStoreClient = class(TObject)
  private
    sess: String;
    guid: String;
    dsid: String;
    storeFront: String;
    accountName: String;

    HTTP: THTTPSend;
  public
    constructor Create(Session, Guid: String);
    destructor Destroy; override;

    function Authenticate(appleId, password: String): String;
    function Download(appId: String; appVerId: String = ''): String;
  end;


implementation

{ TStoreAuthenticateReq }

constructor TStorePayloadReq.Create(appleId, password, attempt, createSession, guid,
   rmp, why: String);
begin
  FDatas := TStringList.Create;

  self.appleId := appleId;
  self.attempt := attempt;
  self.createSession := createSession;
  self.guid := guid;
  self.password := password;
  self.rmp := rmp;
  self.why := why;
end;

constructor TStorePayloadReq.Create(creditDisplay, guid, salableAdamId,
  appExtVrsId: String);
begin
  FDatas := TStringList.Create;

  self.creditDisplay := creditDisplay;
  self.guid := guid;
  self.salableAdamId := salableAdamId;
  self.appExtVrsId := appExtVrsId;
end;

destructor TStorePayloadReq.Destroy;
begin
  FDatas.Free;

  inherited;
end;

function TStorePayloadReq.GetAuthPayload: AnsiString;
begin
  Result := UTF8Encode(
    '<?xml version="1.0" encoding="UTF-8"?>'#10+
    '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">'#10+
    '<plist version="1.0">'#10+
    '<dict>'#10+
    #9'<key>appleId</key>'#10+
    #9'<string>'+_escape(appleId)+'</string>'#10+
    #9'<key>attempt</key>'#10+
    #9'<string>'+_escape(attempt)+'</string>'#10+
    #9'<key>createSession</key>'#10+
    #9'<string>'+_escape(createSession)+'</string>'#10+
    #9'<key>guid</key>'#10+
    #9'<string>'+_escape(guid)+'</string>'#10+
    #9'<key>password</key>'#10+
    #9'<string>'+_escape(password)+'</string>'#10+
    #9'<key>rmp</key>'#10+
    #9'<string>'+_escape(rmp)+'</string>'#10+
    #9'<key>why</key>'#10+
    #9'<string>'+_escape(why)+'</string>'#10+
    '</dict>'#10+
    '</plist>'#10);

end;

function TStorePayloadReq.GetDownloadPayload: AnsiString;
begin
  Result := UTF8Encode(
    '<?xml version="1.0" encoding="UTF-8"?>'#10+
    '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">'#10+
    '<plist version="1.0">'#10+
    '<dict>'#10+
    #9'<key>creditDisplay</key>'#10+
    #9'<string>'+_escape(creditDisplay)+'</string>'#10+
    #9'<key>guid</key>'#10+
    #9'<string>'+_escape(guid)+'</string>'#10+
    #9'<key>salableAdamId</key>'#10+
    #9'<string>'+_escape(salableAdamId)+'</string>'#10+
    '</dict>'#10+
    '</plist>'#10);
end;

function TStorePayloadReq.UpdatePlist(buffer: AnsiString): Integer;
var
  LoopVar: Integer;

  tagFlag, valueFlag: Integer;
  processBuffer, valueBuffer,
  keyName, lastKey, prefixKey: AnsiString;

  PrefixList,
  SimpleParser: TStringList;
begin
  Result := -1;

  // Brutal XML Parsing by jkh. only FAST process.
  processBuffer := '';
  tagFlag := 0;
  valueFlag := 0;
  lastKey := '';
  prefixKey := '';

  SimpleParser := TStringList.Create;
  PrefixList := TStringList.Create;
  try

     for LoopVar := 1 to Length(buffer) do
     begin
        case buffer[LoopVar] of
           '<':
           begin
              if tagFlag = 0 then
                 tagFlag := 1;
           end;
           '>':
           begin
              if tagFlag = 1 then
              begin
                 if processBuffer = 'key' then
                 begin
                    valueBuffer := '';
                    valueFlag := 1;
                 end
                 else if processBuffer = 'string' then
                 begin
                    valueBuffer := '';
                    valueFlag := 2;
                 end
                 else if processBuffer = 'integer' then
                 begin
                    valueBuffer := '';
                    valueFlag := 3;
                 end
                 else if processBuffer = 'true/' then
                 begin
                    valueBuffer := '';
                    valueFlag := 10;
                    SimpleParser.Values[prefixKey+lastKey] := 'true';
                    lastKey := '';
                 end
                 else if processBuffer = 'false/' then
                 begin
                    valueBuffer := '';
                    valueFlag := 10;
                    SimpleParser.Values[prefixKey+lastKey] := 'false';
                    lastKey := '';
                 end
                 else if processBuffer = 'dict' then
                 begin
                    valueBuffer := '';
                    if lastKey <> '' then
                    begin
                       valueFlag := 100;
                       PrefixList.Add(lastKey);
                       prefixKey := StringReplace(Trim(PrefixList.Text), #13#10, '_', [rfReplaceAll]);
                       if prefixKey <> '' then
                          prefixKey := prefixKey + '_';
                    end;
                    lastKey := '';
                 end
                 else if copy(processBuffer, 1, 1) = '/' then
                 begin
                    if valueFlag = 1 then
                    begin
                       lastKey := valueBuffer;
                    end
                    else if (processBuffer = '/dict') and (PrefixList.Count > 0) then
                    begin
                       PrefixList.Delete(PrefixList.Count-1);
                       prefixKey := StringReplace(Trim(PrefixList.Text), #13#10, '_', [rfReplaceAll]);
                       if prefixKey <> '' then
                          prefixKey := prefixKey + '_';
                    end
                    else
                    begin
                       SimpleParser.Values[prefixKey+lastKey] := valueBuffer;
                       lastKey := '';
                    end;

                    valueBuffer := '';
                    valueFlag := 0;
                 end;

                 processBuffer := '';
                 tagFlag := 0;
              end;
           end;
        else
           if tagFlag = 1 then
              processBuffer := processBuffer + buffer[LoopVar]
           else if (tagFlag = 0) and (valueFlag > 0) then
              valueBuffer := valueBuffer + buffer[LoopVar];
        end;
     end;

     for LoopVar := 0 to SimpleParser.Count-1 do
     begin
        keyName := SimpleParser.Names[LoopVar];
        valueBuffer := SimpleParser.ValueFromIndex[LoopVar];

        if keyName = 'appleId' then
           Self.appleId := valueBuffer
        else if keyName = 'attempt' then
           Self.attempt := valueBuffer
        else if keyName = 'createSession' then
           Self.createSession := valueBuffer
        else if keyName = 'guid' then
           Self.guid := valueBuffer
        else if keyName = 'password' then
           Self.password := valueBuffer
        else if keyName = 'rmp' then
           Self.rmp := valueBuffer
        else if keyName = 'why' then
           Self.why := valueBuffer
        else if keyName = 'customerMessage' then
           Self.customerMessage := valueBuffer;
     end;

     FDatas.Assign(SimpleParser);
     Result := 1;
  finally
     SimpleParser.Free;
     PrefixList.Free;
  end;
end;

function TStorePayloadReq._escape(AValue: String): AnsiString;
begin
  Result := AValue;
  Result := StringReplace(Result, #13#10, #13, [rfReplaceAll]);
  Result := StringReplace(Result, #13, #10, [rfReplaceAll]);
  Result := StringReplace(Result, '&', '&amp;', [rfReplaceAll]);
  Result := StringReplace(Result, '<', '&lt;', [rfReplaceAll]);
  Result := StringReplace(Result, '>', '&gt;', [rfReplaceAll]);
end;


{ TStoreClient }

function TStoreClient.Authenticate(appleId, password: String): String;
var
  MethodRes: Boolean;
  Response: TStringList;
  Body: AnsiString;
  Params: String;

  Url: String;
  Req: TStorePayloadReq;

  function parseHeader(searchHeader: String): String;
  var
    LoopVar: Integer;
    Line: String;
  begin
    for LoopVar := 0 to HTTP.Headers.Count-1 do
    begin
       Line := HTTP.Headers[LoopVar];
       if LowerCase(Copy(Line, 1, Length(searchHeader))) = searchHeader then
          Result := Trim(Copy(Line, Length(searchHeader)+2, Length(Line)-Length(searchHeader)-1));
    end;
  end;

  procedure updateUrl;
  begin
    Url := parseHeader('location');
  end;

begin
  Response := TStringList.Create;
  Req := TStorePayloadReq.Create(appleId, password, '4', 'true', guid, '0', 'signIn');
  Try
     Url := 'https://p46-buy.itunes.apple.com/WebObjects/MZFinance.woa/wa/authenticate?guid=' + guid;

     while True do
     begin
        HTTP.Headers.Clear;
        HTTP.UserAgent := 'Configurator/2.0 (Macintosh; OS X 10.12.6; 16G29) AppleWebKit/2603.3.8';
        HTTP.MimeType := 'application/x-www-form-urlencoded';
        HTTP.Headers.Add(
           'Accept: */*'
           );

        Body := Req.GetAuthPayload;
        HTTP.Document.Size := 0;
        HTTP.Document.Write(Body[1], Length(Body));
        MethodRes := HTTP.HTTPMethod('POST', Url);

        if not MethodRes then break;

        if HTTP.ResultCode = 302 then
        begin
           updateUrl;

           continue;
        end;

        break;
     end;

     if MethodRes then
     begin
        SetLength(Body, HTTP.Document.Size);
        HTTP.Document.Read(Body[1], HTTP.Document.Size);

        if Pos('We are unable to find iTunes on your computer.', Body) > 0 then
        begin
           Result := 'error : UUID not valid';
           exit;
        end;

        if Req.UpdatePlist(Body) < 0 then
        begin
           Result := 'error : communicate error.'#13#10+Body;
        end
        else if Req.Datas.Values['m-allowed'] = 'true' then
        begin
           dsid := Req.Datas.Values['download-queue-info_dsid'];
           storeFront := parseHeader('x-set-apple-store-front');
           accountName := Req.Datas.Values['accountInfo_address_firstName'] + ' ' + Req.Datas.Values['accountInfo_address_lastName'];
           Result := '';
        end
        else
        begin
           Result := 'error : '#13#10+Req.customerMessage;
        end;
     end;
  Finally
     Response.Free;
     Req.Free;
  End;
end;

constructor TStoreClient.Create(Session, Guid: String);
begin
  inherited Create;

  HTTP := THTTPSend.Create;

  self.sess := Session;
  self.guid := UpperCase(guid);
end;

destructor TStoreClient.Destroy;
begin
  HTTP.Free;

  inherited;
end;

function TStoreClient.Download(appId, appVerId: String): String;
var
  MethodRes: Boolean;
  Response: TStringList;
  Body: AnsiString;
  Params: String;

  Url: String;
  Req: TStorePayloadReq;
begin
  Response := TStringList.Create;
  Req := TStorePayloadReq.Create('', guid, appId, appVerId);
  Try
     Url := 'https://p25-buy.itunes.apple.com/WebObjects/MZFinance.woa/wa/volumeStoreDownloadProduct?guid=' + guid;

     HTTP.Headers.Clear;
     HTTP.UserAgent := 'Configurator/2.0 (Macintosh; OS X 10.12.6; 16G29) AppleWebKit/2603.3.8';
     HTTP.MimeType := 'application/x-www-form-urlencoded';
     HTTP.Headers.Add(
        'iCloud-DSID: ' + dsid + #13#10+
        'X-Dsid: ' + dsid + #13#10+
        'Accept: */*'
        );

     Body := Req.GetDownloadPayload;
     HTTP.Document.Size := 0;
     HTTP.Document.Write(Body[1], Length(Body));
     MethodRes := HTTP.HTTPMethod('POST', Url);

     if MethodRes then
     begin
        SetLength(Body, HTTP.Document.Size);
        HTTP.Document.Read(Body[1], HTTP.Document.Size);

        if Req.UpdatePlist(Body) < 0 then
        begin
           Result := 'error : communicate error.'#13#10+Body;
        end
        else if Req.Datas.Values['m-allowed'] = 'true' then
        begin
           Result := Req.Datas.Values['songList'];
        end
        else
        begin
           Result := 'error : '#13#10+Req.customerMessage;
        end;
     end;
  Finally
     Response.Free;
     Req.Free;
  End;

end;

end.
