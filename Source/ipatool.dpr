program ipatool;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  Classes,
  SysUtils,
  IPAUtils in 'IPAUtils.pas',
  HTTPUtils in 'HTTPUtils.pas',
  StoreClient in 'StoreClient.pas';

const
  NameStr = 'IPA Tool portable';
  VersionStr = 'Version 0.1';
  HelpStr = #13#10'usage: %s (lookup|search|download) [params]';
  CommandHelpStr =
  #13#10'lookup'#13#10+
  ' --appid, -i        : app bundle id '#13#10+
  #13#10'search'#13#10+
  ' --keyword, -k      : search keyword '#13#10+
  #13#10'download'#13#10+
  ' --appid, -i        : app bundle id '#13#10+
  ' --appleid, -e      : apple user id '#13#10+
  ' --password, -p     : apple user password '#13#10+
  ' --outputdir, -o   : download path or download file name'#13#10+
  ' --uuid, -u         : MAC address of your owned Mac (without this parameter, use this PC''s MAC address)'#13#10+
  '';
  ParamRequireStr = 'need param - ';
  ErrorCodeStr = 'error : %d';

var
  ParamLoop: Integer;
  LoopVar: Integer;

  MainCommand,
  NextCommand: String;

  ParamsList: TStringList;
  IPAUtils: TIPAUtils;

  function CheckParams(ParamList: String): Boolean;
  var
    ParseBuffer: TStringList;
    SearchIdx,
    CheckLoop: Integer;
  begin
    Result := True;

    ParseBuffer := TStringList.Create;
    try
       ParseBuffer.Text := StringReplace(ParamList, ',', #13#10, [rfReplaceAll]);
       for CheckLoop := 0 to ParamsList.Count-1 do
       begin
          SearchIdx := ParseBuffer.IndexOf( ParamsList.Names[CheckLoop] );
          if SearchIdx >= 0 then
             ParseBuffer.Delete(SearchIdx);
       end;

       ParamList := Trim(StringReplace(ParseBuffer.Text, #13#10, '', [rfReplaceAll]));
       if ParamList <> '' then
       begin
          Result := False;
          writeln(ParamRequireStr + ParamList);
       end;
    finally
       ParseBuffer.Free;
    end;
  end;

begin
  writeln(NameStr + ' ' + VersionStr);

  NextCommand := '';
  MainCommand := '';
  ParamLoop := 1;

  if ParamCount < 1 Then
  begin
     writeln(Format(HelpStr, [ExtractFileName(ParamStr(0))]));
     writeln(CommandHelpStr);

     Exit;
  end;

  ParamsList := TStringList.create;
  try
     while (ParamCount >= ParamLoop) do
     begin
        if NextCommand <> '' Then
        begin
           if MainCommand = 'lookup' then
           begin
              if (NextCommand = '--appid') or (NextCommand = '-i') Then
                 ParamsList.Values['appid'] := ParamStr(ParamLoop)
              else
              if (NextCommand = '--country') or (NextCommand = '-c') Then
                 ParamsList.Values['country'] := ParamStr(ParamLoop)
              else
              if (NextCommand = '--getverid') Then
                 ParamsList.Values['getverid'] := ParamStr(ParamLoop);
           end
           else
           if MainCommand = 'search' then
           begin
              if (NextCommand = '--keyword') or (NextCommand = '-k') Then
                 ParamsList.Values['keyword'] := ParamStr(ParamLoop)
              else
              if (NextCommand = '--country') or (NextCommand = '-c') Then
                 ParamsList.Values['country'] := ParamStr(ParamLoop);
           end
           else
           if MainCommand= 'download' then
           begin
             if (NextCommand = '--appid') or (NextCommand = '-i') Then
                ParamsList.Values['appid'] := ParamStr(ParamLoop)
             else
             if (NextCommand = '--appleid') or (NextCommand = '-e') Then
                ParamsList.Values['appleid'] := ParamStr(ParamLoop)
             else
             if (NextCommand = '--password') or (NextCommand = '-p') Then
                ParamsList.Values['password'] := ParamStr(ParamLoop)
             else
             if (NextCommand = '--outputdir') or (NextCommand = '-o') Then
                ParamsList.Values['outputdir'] := ParamStr(ParamLoop)
             else
             if (NextCommand = '--uuid') or (NextCommand = '-u') Then
                ParamsList.Values['uuid'] := ParamStr(ParamLoop);
           end;

           NextCommand := '';
        end;

        if Copy(ParamStr(ParamLoop), 1, 1) = '-' Then
           NextCommand := LowerCase(ParamStr(ParamLoop))
        else if MainCommand = '' then
           MainCommand := ParamStr(ParamLoop);

        if (NextCommand = '--help') then
        begin
           writeln(CommandHelpStr);
           Exit;
        end;

        Inc(ParamLoop);
     end;

     if MainCommand = '' then Exit;

     IPAUtils := TIPAUtils.Create;
     try
        if (MainCommand = 'lookup') and CheckParams('appid') then
           writeln( IPAUtils.Lookup(ParamsList.Values['appid'], ParamsList.Values['country'], True) )

        else if (MainCommand = 'search') and CheckParams('keyword') then
           writeln( IPAUtils.Search(ParamsList.Values['keyword'], ParamsList.Values['country']) )

        else if (MainCommand = 'download') and CheckParams('appid,appleid,password,outputdir') then
           writeln( IPAUtils.Download(ParamsList.Values['appid'], ParamsList.Values['appleid'], ParamsList.Values['password'], ParamsList.Values['appverid'], ParamsList.Values['outputdir'], ParamsList.Values['uuid']) )

        else if (MainCommand = 'debug') and CheckParams('')  then
           IPAUtils.Debug;
     finally
        IPAUtils.Free;
     end;
  finally
     ParamsList.Free;
  end;
end.
