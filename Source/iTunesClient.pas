unit iTunesClient;

interface

uses
  SysUtils, Classes, httpsend, ssl_openssl;

type
  TiTunesClient = class(TObject)
  private
    Session: String;
  public
    constructor Create(Session: String);

    function Search(term, country: String; limit: Integer = 5; media: String = 'software'): String;
    function Lookup(bundleId, country: String; limit: Integer = 1; media: String = 'software'): String;
  end;


implementation

uses
  HTTPUtils;

{ TiTunesClient }

constructor TiTunesClient.Create(Session: String);
begin
  inherited Create;
end;

function TiTunesClient.Lookup(bundleId, country: String; limit: Integer;
  media: String): String;
var
  HTTP: THTTPSend;
  MethodRes: Boolean;
  Response: TStringList;
  Params: String;
begin
  HTTP := THTTPSend.Create;
  Response := TStringList.Create;
  try
     HTTP.MimeType := 'application/x-www-form-urlencoded';
     Params := '';

     AddParams(Params, 'bundleId', bundleId);
     AddParams(Params, 'country', country);
     AddParams(Params, 'limit', IntToStr(limit));
     AddParams(Params, 'media', media);

     MethodRes := HTTP.HTTPMethod('GET', 'https://itunes.apple.com/lookup?'+Params);
     if MethodRes then
     begin
        {$IFDEF FPC}
        Response.LoadFromStream(HTTP.Document);
        {$ELSE}
        Response.LoadFromStream(HTTP.Document, TEncoding.UTF8);
        {$ENDIF}
        Result := Response.Text;
     end;
  finally
     Response.Free;
     HTTP.Free;
  end;
end;

function TiTunesClient.Search(term, country: String; limit: Integer;
  media: String): String;
var
  HTTP: THTTPSend;
  MethodRes: Boolean;
  Response: TStringList;
  Params: String;
begin
  HTTP := THTTPSend.Create;
  Response := TStringList.Create;
  try
     HTTP.MimeType := 'application/x-www-form-urlencoded';
     Params := '';

     AddParams(Params, 'term', term);
     AddParams(Params, 'country', country);
     AddParams(Params, 'limit', IntToStr(limit));
     AddParams(Params, 'media', media);

     MethodRes := HTTP.HTTPMethod('GET', 'https://itunes.apple.com/search?'+Params);
     if MethodRes then
     begin
        {$IFDEF FPC}
        Response.LoadFromStream(HTTP.Document);
        {$ELSE}
        Response.LoadFromStream(HTTP.Document, TEncoding.UTF8);
        {$ENDIF}
        Result := Response.Text;
     end;
  finally
     Response.Free;
     HTTP.Free;
  end;

end;

end.
