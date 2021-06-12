unit HTTPUtils;

interface

procedure AddParams(var Params: String; NewName, NewValue: String);

implementation

uses
  Synacode;

procedure AddParams(var Params: String; NewName, NewValue: String);
begin
  if NewValue = '' then Exit;
  if Params <> '' then Params := Params + '&';
  Params := Params + NewName + '=' + EncodeURLElement(UTF8Encode(NewValue));
end;

end.
