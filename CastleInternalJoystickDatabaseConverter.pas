program CastleInternalJoystickDatabaseConverter;

uses
  Classes, SysUtils, Generics.Collections,
  CastleDownload, CastleLog, CastleStringUtils, CastleUtils,
  CastleInternalJoystickRecord;

type
  TBuggyGuidDictionary = specialize TObjectDictionary<String, TStringList>;
  TAllJoysticks = specialize TObjectDictionary<String, TJoystickLayout>;

var
  BuggyGuids: TBuggyGuidDictionary;

type
  TJoystickParser = class(TJoystickLayout)
  protected
    function StrToJoystickEvent(const AString: String): TJoystickEvent;
  public
    { Platform of the database report }
    Platform: String;
    procedure Parse(const AString: String);
  end;

function TJoystickParser.StrToJoystickEvent(const AString: String): TJoystickEvent;
begin
  Result := unknownEvent; //this is an "error"
  case AString of
    'x': Result := padX; //note the mapping of ABYX is different for PC!
    'y': Result := padY;
    'a': Result := padA;
    'b': Result := padB;

    'back': Result := buttonBack;
    'start': Result := buttonStart;

    'rightshoulder': Result := buttonRightShoulder;
    'leftshoulder': Result := buttonLeftShoulder;
    'righttrigger': Result := buttonRightTrigger;
    'lefttrigger': Result := buttonLeftTrigger;

    'leftx': Result := axisLeftX;
    'lefty': Result := axisLeftY;
    'rightx': Result := axisRightX;
    'righty': Result := axisRightY;
    'leftstick': Result := buttonLeftStick;
    'rightstick': Result := buttonRightStick;

    'dpleft': Result := dpadLeft;
    'dpright': Result := dpadRight;
    'dpup': Result := dpadUp;
    'dpdown': Result := dpadDown;

    '+leftx': Result := axisLeftXPlus;
    '-leftx': Result := axisLeftXMinus;
    '+lefty': Result := axisLeftYPlus;
    '-lefty': Result := axisLeftYMinus;
    '+righty': Result := axisRightYPlus;
    '-righty': Result := axisRightYMinus;

    'guide': Result := buttonGuide;
    else
      WriteLnLog('ERROR: Unknown joystick JoystickEvent', AString);
  end;
end;

procedure TJoystickParser.Parse(const AString: String);

  type
    TStringPair = record
      Caption: String;
      Value: String;
    end;

  function SplitStringPair(const AString: String): TStringPair;
  var
    SemicolonPosition: Integer;
  begin
    SemicolonPosition := Pos(':', AString);
    Result.Caption := Copy(AString, 1, SemicolonPosition - 1);
    Result.Value := Copy(AString, SemicolonPosition + 1, Length(AString));
  end;
  type
    TValueType = (
      vtButton, vtBothAxes, vtDPad,
      vtAxisPlus, vtAxisMinus);
    TParsedValue = record
      ValueType: TValueType;
      Value: Integer;
      Invert: Boolean;
    end;

  function ParseValueType(const AString: String): TParsedValue;
  var
    Prefix: String;
    Value: String;
  begin
    if Copy(AString, 1, 1) = 'a' then
      Prefix := 'a'
    else
    if Copy(AString, 1, 1) = 'b' then
      Prefix := 'b'
    else
    if Copy(AString, 1, 3) = 'h0.' then
      Prefix := 'h0.'
    else
    if Copy(AString, 1, 2) = '+a' then
      Prefix := '+a'
    else
    if Copy(AString, 1, 2) = '-a' then
      Prefix := '-a'
    else
      ;

    case Prefix of
      'a': Result.ValueType := vtBothAxes;
      'b': Result.ValueType := vtButton;
      'h0.': Result.ValueType := vtDPad;
      '+a': Result.ValueType := vtAxisPlus;
      '-a': Result.ValueType := vtAxisMinus;
      else
        WriteLnLog('Unexpected prefix for joystick value', AString);
    end;
    Value := Copy(AString, Length(Prefix) + 1, Length(AString));
    if Pos('~', Value) > 0 then
    begin
      Result.Invert := true;
      Value := Copy(Value, 1, Pos('~', Value) - 1);
    end else
      Result.Invert := false;
    Result.Value := StrToInt(Value);
  end;

  procedure AddDictionaryEntry(const ADictionary: TJoystickDictionary;
    const AValue: Byte; const AEvent: TJoystickEvent);
  begin
    if ADictionary.ContainsKey(AValue) then
      if ADictionary.Items[AValue] <> AEvent then
      begin
        WriteLnLog('Warning', 'Joystick "' + JoystickName + '"' +
          ' has duplicate entry.' +
          ' The old value ' + JoystickEventToStr(ADictionary.Items[AValue]) +
          ' was overwritten with ' + JoystickEventToStr(AEvent) + '.');
        BuggyDuplicateEvents := true;
      end;
    ADictionary.AddOrSetValue(AValue, AEvent);
  end;

var
  Data: TStringList;
  J: Integer;
  Pair: TStringPair;
  VT: TParsedValue;
begin
  Data := CreateTokens(AString, [',']);
  begin
    Guid := Data[0];
    JoystickName := Data[1];
    for J := 2 to Pred(Data.Count) do
      if Data[J] <> '' then
      begin
        Pair := SplitStringPair(Data[J]);
        if Pair.Caption = 'platform' then
          Platform := Pair.Value
        else
        begin
          VT := ParseValueType(Pair.Value);

          if VT.Invert and (VT.ValueType <> vtBothAxes) then
            WriteLnLog('Error: A non-both-axis event is inverted!');

          case VT.ValueType of
            vtButton: AddDictionaryEntry(Buttons, VT.Value, StrToJoystickEvent(Pair.Caption));
            vtDPad: AddDictionaryEntry(DPad, VT.Value, StrToJoystickEvent(Pair.Caption));
            vtBothAxes: begin
                          AddDictionaryEntry(AxesPlus, VT.Value, StrToJoystickEvent(Pair.Caption));
                          AddDictionaryEntry(AxesMinus, VT.Value, StrToJoystickEvent(Pair.Caption));
                          if VT.Invert then
                          begin
                            if InvertAxes = nil then
                              InvertAxes := TInvertAxes.Create;
                            InvertAxes.Add(VT.Value);
                          end;
                        end;
            vtAxisPlus: AddDictionaryEntry(AxesPlus, VT.Value, StrToJoystickEvent(Pair.Caption));
            vtAxisMinus: AddDictionaryEntry(AxesMinus, VT.Value, StrToJoystickEvent(Pair.Caption));
          end;
        end;
      end;
  end;
  FreeAndNil(Data);

  //detect buggy duplicate axes
  CacheJoystickEvents;
  if (axisLeftX in JoystickHasEvents) and
    ((axisLeftXPlus in JoystickHasEvents) or (axisLeftXMinus in JoystickHasEvents)) then
      BuggyDuplicateAxes := true;
  if (axisLeftY in JoystickHasEvents) and
    ((axisLeftYPlus in JoystickHasEvents) or (axisLeftYMinus in JoystickHasEvents)) then
      BuggyDuplicateAxes := true;
  if (axisRightY in JoystickHasEvents) and
    ((axisRightYPlus in JoystickHasEvents) or (axisRightYMinus in JoystickHasEvents)) then
      BuggyDuplicateAxes := true;
  if BuggyDuplicateAxes then
    WriteLnLog('Warning', 'Joystick "' + JoystickName + '"' +
      ' has contradictive axes entry.');
end;

procedure GetBuggyGuids;
var
  SList: TStringList;
begin
  { for now - hardcoded, if we meet any other buggy GUIDs then we may consider
    storing those as an external file and read them here. }
  BuggyGuids := TBuggyGuidDictionary.Create([doOwnsValues]);
  SList := TStringList.Create;
  SList.Add('03000000790000000600000000000000');
  BuggyGuids.Add('Windows', SList);
  SList := TStringList.Create;
  SList.Add('03000000780000000600000010010000');
  BuggyGuids.Add('Linux', SList);
end;

function IsBuggyGuid(const ALayout: TJoystickParser): Boolean;
const
  BuggyGuidMarker = 'buggy';
var
  OS: String;
  G: String;
begin
  Result := false;
  if Copy(ALayout.Guid, 0, Length(BuggyGuidMarker)) = BuggyGuidMarker then
    Exit(true);
  for OS in BuggyGuids.Keys do
    if (OS = ALayout.Platform) then
      for G in BuggyGuids.Items[OS] do
        if (G = ALayout.Guid) then
          Exit(true);
end;

var
  Database: TAllJoysticks;

procedure ParseJoysticksDatabase(const URL: String);
var
  Stream: TStream;
  Strings: TStringList;
  I: Integer;
  Layout: TJoystickParser;
begin
  try
    Stream := Download(URL);
    Strings := TStringList.Create;
    Strings.LoadFromStream(Stream);
    for I := 0 to Pred(Strings.Count) do
      if (Strings[I] <> '') and (Copy(Strings[I], 0, 1) <> '#') then
      begin
        Layout := TJoystickParser.Create;
        Layout.Parse(Strings[I]);
        Database.Add(Layout.Guid + Layout.Platform, Layout);
      end;
    FreeAndNil(Strings);
  finally
    FreeAndNil(Stream);
  end;
end;

procedure WriteDatabase(const Platform: String);
var
  RecCount: Integer;

  function DatabaseToString: String;

    function DatabaseLayoutToString(const Layout: TJoystickParser): String;

      function JoyDictionaryToString(const AName: String; const ADictionary: TJoystickDictionary): String;
      var
        B: Byte;
      begin
        Result := '';
        for B in ADictionary.Keys do
          Result +=
            '  JoyData.' + AName + '.Add(' + IntToStr(B) + ', ' +
            JoystickEventToStr(ADictionary.Items[B]) + ');' +
            NL;
      end;

      function InvertedAxesToString(const AInvertAxes: TInvertAxes): String;
      var
        B: Byte;
      begin
        Result := '  JoyData.InvertAxes := TInvertAxes.Create;' + NL;
        for B in AInvertAxes do
          Result +=
            '  JoyData.InvertAxes.Add(' + IntToStr(B) + ');' + NL;
      end;

    begin
      Inc(RecCount);
      Result := NL +
        '  JoyData := TJoystickLayout.Create;' + NL +
        '  JoyData.JoystickName := ''' + StringReplace(Layout.JoystickName, '''', '''''', [rfReplaceAll]) + ''';' + NL +
        '  JoyData.Guid := ''' + Layout.Guid + ''';' + NL;
      if IsBuggyGuid(Layout) then
        Result +=
        '  JoyData.BuggyGuid := true;' + NL;
      if Layout.BuggyDuplicateEvents then
      Result +=
        '  JoyData.BuggyDuplicateEvents := true;' + NL;
      if Layout.BuggyDuplicateAxes then
      Result +=
        '  JoyData.BuggyDuplicateAxes := true;' + NL;
      Result += JoyDictionaryToString('Buttons', Layout.Buttons);
      Result += JoyDictionaryToString('AxesPlus', Layout.AxesPlus);
      Result += JoyDictionaryToString('AxesMinus', Layout.AxesMinus);
      Result += JoyDictionaryToString('DPad', Layout.DPad);
      if Layout.InvertAxes <> nil then
        Result += InvertedAxesToString(Layout.InvertAxes);
      Result +=
        '  JoyData.CacheJoystickEvents;' + NL;
      //duplicates allowed in names
      Result +=
        '  JoystickLayoutsByName.AddOrSetValue(JoyData.JoystickName, JoyData);' + NL;
      //duplicates not allowed in GUID
      Result +=
        '  JoystickLayoutsByGuid.Add(JoyData.Guid, JoyData);' + NL;
    end;
  var
    S: String;
  begin
    Result := NL +
      'procedure FreeJoysticksDatabase;' + NL +
      'begin' + NL +
      '  FreeAndNil(JoystickLayoutsByName);' + NL +
      '  FreeAndNil(JoystickLayoutsByGuid);' + NL +
      'end;' + NL +
      NL +
      'procedure InitJoysticksDatabase;' + NL +
      'var' + NL +
      '  JoyData: TJoystickLayout;' + NL +
      'begin' + NL +
      '  FreeJoysticksDatabase;' + NL +
      '  JoystickLayoutsByName := TJoystickDatabase.Create;' + NL + //owns nothing as contains duplicates
      '  JoystickLayoutsByGuid := TJoystickDatabase.Create([doOwnsValues]);' + NL;
    for S in Database.Keys do
      if (Database[S] as TJoystickParser).Platform = Platform then
        Result := Result + DatabaseLayoutToString((Database[S] as TJoystickParser));
    Result += 'end;' + NL;
  end;

var
  OutputUnit: TTextWriter;
  UnitName: String;
begin
  RecCount := 0;
  UnitName := 'CastleInternalJoystickDatabase' + Platform;
  OutputUnit := TTextWriter.Create(UnitName + '.pas');
  OutputUnit.Write(
    '{ -*- buffer-read-only: t -*- }' + NL +
    NL +
    '{ Unit automatically generated by CastleInternalJoystickDatabaseConverter tool,' + NL +
    '  to store converted version of https://github.com/gabomdq/SDL_GameControllerDB -' + NL +
    '  A community sourced database of game controller mappings' + NL +
    '  @exclude (Exclude this unit from PasDoc documentation.) }' + NL +
    'unit ' + UnitName + ';' + NL +
    NL +
    'interface' + NL +
    NL +
    'uses Generics.Collections, CastleInternalJoystickRecord;' + NL +
    NL);

  OutputUnit.Write(
    'type' + NL +
    '  TJoystickDatabase = specialize TObjectDictionary<String, TJoystickLayout>;' + NL +
    NL +
    'var' + NL +
    '  { Database of joysticks by name/GUID,' + NL +
    '    A database corresponding to the current OS will be loaded' + NL +
    '    As different OS report different GUIDs and names for the same joystick' + NL +
    '    Note that the database contains a large number of joysticks ' + NL +
    '    with identical "name" but different GUID. }' + NL +
    '  JoystickLayoutsByName, JoystickLayoutsByGuid: TJoystickDatabase;' + NL +
    NL +
    '{ Initialize (read) joysticks layout database.' + NL +
    '  Will also free previously loaded database. }' + NL +
    'procedure InitJoysticksDatabase;' + NL +
    '{ Free joysticks layout database. }' + NL +
    'procedure FreeJoysticksDatabase;' + NL +
    'implementation' + NL +
    NL +
    'uses SysUtils;' + NL);

  OutputUnit.Write(DatabaseToString);

  OutputUnit.Write(NL +
    'finalization' + NL +
    '  FreeJoysticksDatabase;' + NL +
    'end.');
  FreeAndNil(OutputUnit);
  WriteLnLog('Written ' + IntToStr(RecCount) + ' records for platform', Platform);
end;

begin
  InitializeLog;
  GetBuggyGuids;
  Database := TAllJoysticks.Create([doOwnsValues]);
  ParseJoysticksDatabase('castle-data:/gamecontrollerdb.txt');
  ParseJoysticksDatabase('castle-data:/buggyjoysticks.txt');
  WriteDatabase('Windows');
  WriteDatabase('Linux');
  FreeAndNil(BuggyGuids);
  FreeAndNil(Database);
end.

