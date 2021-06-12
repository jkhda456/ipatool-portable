unit IPAUtils;

interface

uses
  {$IFDEF MSWINDOWS}
  Windows,
  {$ENDIF}
  Classes, SysUtils, iTunesClient, StoreClient, httpsend, ssl_openssl, uJSON;

type
  TIPAUtils = class(TObject)
  private
    FSession: String;

    function GetMacAddress(): String;
    function DoDownload(targetUrl, outputFile: String): Integer;

    function LookupInfo(bundle_id, country: String; get_verid: Boolean; var out_appName, out_appVersion, out_message: String): Integer;
  public
    function Lookup(appId, country: String; get_verid: Boolean): String;
    function Search(keyword, country: String): String;

    function Download(appId, appleid, password, appVerId, outputDir, uuid: String): String;

    procedure Debug(caseType: Integer = 2);
  published
    property Session: String read FSession;
  end;

implementation

{ TIPAUtils }

procedure TIPAUtils.Debug(caseType: Integer);
var
  Test: TStorePayloadReq;
  TestReader: TStringList;
  TestStore: TStoreClient;
begin
  case caseType of
     0:
     begin
        Test := TStorePayloadReq.Create('','','','','','','');
        TestReader := TStringList.Create;
        TestReader.LoadFromFile('test2.txt');

        Test.UpdatePlist(TestReader.Text);

        Test.Free;
        TestReader.Free;
     end;
     1:
     begin
        TestStore := TStoreClient.Create('sess', 'uuid'); // MacAddress.
        try
           TestStore.Authenticate('appId', 'password');
           TestStore.Download('appId', 'appleid');
        finally
           TestStore.Free;
        end;
     end;
     2:
     begin
        writeln(GetMacAddress);
     end;
  end;
end;

function TIPAUtils.DoDownload(targetUrl, outputFile: String): Integer;
var
  HTTP: THTTPSend;
  HTTPRes: Boolean;
begin
  HTTP := THTTPSend.Create;
  try
     HTTP.UserAgent := 'Configurator/2.0 (Macintosh; OS X 10.12.6; 16G29) AppleWebKit/2603.3.8';
     HTTPRes := HTTP.HTTPMethod('GET', targetUrl);
     if HTTPRes then
        HTTP.Document.SaveToFile(outputFile);
  finally
     HTTP.Free;
  end;
end;

function TIPAUtils.Download(appId, appleid, password, appVerId,
  outputDir, uuid: String): String;
var
  Store: TStoreClient;
  LookupApp, LookupVer, LookupRes: String;
begin
  if uuid = '' then
     uuid := GetMacAddress;

  Store := TStoreClient.Create(Session, uuid); // MacAddress.
  try
     if LookupInfo(appId, '', True, LookupApp, LookupVer, LookupRes) <= 0 then
     begin
        Result := 'error : lookup failed';
        Exit;
     end;

     Result := Store.Authenticate(appleid, password);
     if Result = '' then
     begin
        LookupRes := Store.Download(appId, appVerId);
        if Pos('error : ', LookupRes) <= 0 then
        begin
           if ExtractFileExt(outputDir) <> '' then
           begin
              outputDir := outputDir + '\' + LookupApp + '_' + LookupVer+ '.ipa';
              Result := 'download : ' + outputDir + ' (' + LookupRes + ')';
           end;

           DoDownload(LookupRes, outputDir);
        end
        else
        begin
           Result := LookupRes;
        end;
     end;
  finally
     Store.Free;
  end;
end;

function TIPAUtils.GetMacAddress: String;
  {$IFDEF MSWINDOWS}
  function WinGetMacAddress: string;
  var
    UuidCreateFunc : function(var guid: TGUID): HRESULT; stdcall;
    hHandle : THandle;
    gGuid : TGUID;
    OSVer : TOSVersionInfo;
    I : Integer;
    hErrCode : HRESULT;
  begin
    Result := '';

    OSVer.dwOSVersionInfoSize := SizeOf(OSVer);
    GetVersionEx(OSVer);

    hHandle := LoadLibrary('RPCRT4.DLL');
    if OSVer.dwMajorVersion >= 5 then
       @UuidCreateFunc := GetProcAddress(hHandle, 'UuidCreateSequential')
    else
       @UuidCreateFunc := GetProcAddress(hHandle, 'UuidCreate');
    UuidCreateFunc(gGuid);

    for I := 2 to 7 do
       Result := Result + IntToHex(gGuid.d4[I], 2);
    FreeLibrary(hHandle);
  end;
  {$ENDIF}
begin

  Result := '000102030405'; // fake mac address

  {$IFDEF MSWINDOWS}
  Result := WinGetMacAddress();
  {$ENDIF}
end;

function TIPAUtils.Lookup(appId, country: String; get_verid: Boolean): String;
var
  ResApp, ResVer: String;
begin
  Result := '';
  LookupInfo(appId, country, get_verid, ResApp, ResVer, Result);
end;

function TIPAUtils.LookupInfo(bundle_id, country: String;
  get_verid: Boolean; var out_appName, out_appVersion, out_message: String): Integer;
var
  iTunes: TiTunesClient;
  ResStr: String;
  ResCount: Integer;
  ResJSON: TJSONObject;
  ResItem: TJSONObject;

  LoopVar: Integer;
begin
  Result := 0;
  if bundle_id = '' then
  begin
     out_message := 'error : need bundle_id';
     Exit;
  end;

  iTunes := TiTunesClient.Create(Session);
  Try
     ResStr := iTunes.Lookup(bundle_id, country);
     if ResStr = '' then
        out_message := 'error : Lookup failed'
     else
     begin
        try
           ResJSON := TJSONObject.create(ResStr);
        except
           on e: Exception do
           begin
              out_message := 'error : read json'#13#10;
              out_message := out_message + e.Message+#13#10+ResStr;
              Exit;
           end;
        end;

        ResCount := ResJSON.getIntSlient('resultCount');
        if ResCount <= 0 then
        begin
           out_message := 'error : Not exists';
           exit;
        end;

        out_message := 'Found '+IntToStr(ResCount)+' items'#13#10;

        for LoopVar := 0 to ResCount-1 do
        begin
           try
              ResItem := ResJSON.getJSONArray('results').getJSONObject(LoopVar);
              out_message := out_message + ' '+IntToStr(LoopVar+1)+'. ' +
                 ResItem.getStringSlient('bundleId') + #13#10'    ' +
                 'name : ' + ResItem.getStringSlient('trackName') +' / '+
                 'version : ' + ResItem.getStringSlient('version') +' '+
                 '(' + ResItem.getStringSlient('currentVersionReleaseDate') +')'+
                 #13#10;

              out_appName := ResItem.getStringSlient('trackName');
              out_appVersion := ResItem.getStringSlient('version');
              Inc(Result);
           except
              out_message := out_message + ' - error : Read error'#13#10;
           end;
        end;
     end;
  Finally
     iTunes.Free;
  End;
end;

function TIPAUtils.Search(keyword, country: String): String;
var
  iTunes: TiTunesClient;
  ResStr: String;
  ResCount: Integer;
  ResJSON: TJSONObject;
  ResItem: TJSONObject;

  LoopVar: Integer;
begin
  if keyword = '' then
  begin
     Result := 'error : need keyword';
     Exit;
  end;

  iTunes := TiTunesClient.Create(Session);
  Try
     ResStr := iTunes.Search(keyword, country);
     if ResStr = '' then
        Result := 'error : Search failed'
     else
     begin
        try
           ResJSON := TJSONObject.create(ResStr);
        except
           on e: Exception do
           begin
              Result := 'error : read json'#13#10;
              Result := Result + e.Message+#13#10+ResStr;
              Exit;
           end;
        end;

        ResCount := ResJSON.getIntSlient('resultCount');
        if ResCount <= 0 then
        begin
           Result := 'error : Not exists';
           exit;
        end;

        Result := 'Found '+IntToStr(ResCount)+' items'#13#10;

        for LoopVar := 0 to ResCount-1 do
        begin
           try
              ResItem := ResJSON.getJSONArray('results').getJSONObject(LoopVar);
              Result := Result + ' '+IntToStr(LoopVar+1)+'. ' +
                 ResItem.getStringSlient('bundleId') + #13#10'    ' +
                 'name : ' + ResItem.getStringSlient('trackName') +' / '+
                 'version : ' + ResItem.getStringSlient('version') +' '+
                 '(' + ResItem.getStringSlient('currentVersionReleaseDate') +')'+
                 #13#10;
           except
              Result := Result + ' - error : Read error'#13#10;
           end;
        end;
     end;

  Finally
     iTunes.Free;
  End;
end;

end.
