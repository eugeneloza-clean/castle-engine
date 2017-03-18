{
  Copyright 2017-2017 Michalis Kamburelis.

  This file is part of "Castle Game Engine".

  "Castle Game Engine" is free software; see the file COPYING.txt,
  included in this distribution, for details about the copyright.

  "Castle Game Engine" is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

  ----------------------------------------------------------------------------
}

{ This unit implements the game logic, independent from mobile / standalone. }
unit Game;

interface

uses CastleWindow;

var
  Window: TCastleWindow;

implementation

uses SysUtils, Classes, CastleScene, CastleControls, CastleLog, CastleSceneCore,
  CastleFilesUtils, CastleUtils, CastleXMLUtils, CastleConfig,
  CastleTextureFontData, CastleFonts, CastleUnicode, CastleStringUtils,
  X3DNodes, CastleUIControls, CastleColors, CastleVectors,
  Font_DejaVuSans, Font_DroidSansFallback;

{ TFontContainer ------------------------------------------------------------- }

type
  TFontContainer = class
  strict private
    procedure LoadFinish;
    procedure Load(const URL: string);
    procedure Load(const FontData: TTextureFontData);
  public
    MyFontData: TTextureFontData;
    MyFont: TTextureFont;
    constructor Create;
    destructor Destroy; override;
    procedure GetFont(const FontStyle: TFontStyleNode; var Font: TTextureFontData);
    procedure ButtonExternalFontClick(Sender: TObject);
    procedure ButtonExternalFontChineseClick(Sender: TObject);
    procedure ButtonEmbeddedFontClick(Sender: TObject);
    procedure ButtonEmbeddedFontChineseClick(Sender: TObject);
  end;

var
  FontContainer: TFontContainer;

constructor TFontContainer.Create;
begin
  inherited;
  MyFont := TTextureFont.Create(TComponent(nil));
end;

destructor TFontContainer.Destroy;
begin
  FreeAndNil(MyFont);
  inherited;
end;

procedure TFontContainer.GetFont(const FontStyle: TFontStyleNode; var Font: TTextureFontData);
begin
  Font := MyFontData;
end;

procedure TFontContainer.Load(const URL: string);
var
  AllCharacters: TUnicodeCharList;
begin
  try
    { Load from TTF font with support for international characters.
      See https://castle-engine.sourceforge.io/manual_text.php

      Note that in case of EFreeTypeLibraryNotFound in TTextureFontData.Create,
      no state is modified (MyFontData and MyFont stay unchanged). }

    AllCharacters := TUnicodeCharList.Create;
    try
      AllCharacters.Add(SimpleAsciiCharacters);
      AllCharacters.Add('你好世界');
      AllCharacters.Add('Γειασουκόσμε');
      AllCharacters.Add('Здравствуймир');
      AllCharacters.Add('ŚĆĘĄŹŁŻÓŃśćęąźłżóń');
      MyFontData := TTextureFontData.Create(URL, 20, true, AllCharacters);
    finally FreeAndNil(AllCharacters) end;

    MyFont.Load(MyFontData, true);
    LoadFinish;
  except
    on E: EFreeTypeLibraryNotFound do
      Window.MessageOK(E.Message, mtWarning);
  end;
end;

procedure TFontContainer.Load(const FontData: TTextureFontData);
begin
  MyFontData := FontData;
  MyFont.Load(FontData, false);
  LoadFinish;
end;

procedure TFontContainer.LoadFinish;
var
  I: Integer;
begin
  { use custom font by default in all TCastleLabel }
  UIFont := FontContainer.MyFont;
  { this is necessary to recalculate button sizes after UIFont measurements changed }
  for I := 0 to Window.Controls.Count - 1 do
    if Window.Controls[I] is TUIControlFont then
      TUIControlFont(Window.Controls[I]).FontChanged;

  { use custom font by default when rendering X3D text }
  TFontStyleNode.OnFont := @FontContainer.GetFont;
  { this is necessary to recalculate 3D shape of the text after font changes }
  if Window.SceneManager.MainScene <> nil then
    Window.SceneManager.MainScene.FontChanged;
end;

procedure TFontContainer.ButtonExternalFontClick(Sender: TObject);
begin
  FontContainer.Load(ApplicationData('DejaVuSans.ttf'));
end;

procedure TFontContainer.ButtonExternalFontChineseClick(Sender: TObject);
begin
  FontContainer.Load(ApplicationData('DroidSansFallback.ttf'));
end;

procedure TFontContainer.ButtonEmbeddedFontClick(Sender: TObject);
begin
  FontContainer.Load(TextureFont_DejaVuSans_20);
end;

procedure TFontContainer.ButtonEmbeddedFontChineseClick(Sender: TObject);
begin
  FontContainer.Load(TextureFont_DroidSansFallback_20);
end;

{ initialization ------------------------------------------------------------- }

{ One-time initialization of resources. }
procedure ApplicationInitialize;
var
  Scene: TCastleScene;
  TestLabel: TCastleLabel;
  Config: TCastleConfig;
  Y: Integer;
  ButtonExternalFont, ButtonExternalFontChinese: TCastleButton;
  ButtonEmbeddedFont, ButtonEmbeddedFontChinese: TCastleButton;
begin
  FontContainer := TFontContainer.Create;
  FontContainer.ButtonEmbeddedFontClick(nil);

  Window.Controls.InsertBack(TCastleSimpleBackground.Create(Application));

  Scene := TCastleScene.Create(Application);
  Scene.Load(ApplicationData('scene.x3dv'));
  Scene.Spatial := [ssRendering, ssDynamicCollisions];
  Scene.ProcessEvents := true;
  Window.SceneManager.Items.Add(Scene);
  Window.SceneManager.MainScene := Scene;

  Window.SceneManager.FullSize := false;
  Window.SceneManager.Anchor(hpMiddle);
  Window.SceneManager.Anchor(vpTop, -10);
  Window.SceneManager.Width := 1400;
  Window.SceneManager.Height := 400;
  Window.SceneManager.BackgroundColor := Gray;
  Window.SceneManager.RequiredCamera.SetView(
    Vector3Single(2, -2, 10),
    Vector3Single(0.5, 0, -1),
    Vector3Single(0, 1, 0)
  );

  Y := 10;

  ButtonExternalFont := TCastleButton.Create(Application);
  ButtonExternalFont.Caption := 'Switch to external font (without Chinese chars)';
  ButtonExternalFont.OnClick := @FontContainer.ButtonExternalFontClick;
  ButtonExternalFont.Left := 10;
  ButtonExternalFont.Bottom := Y;
  Window.Controls.InsertFront(ButtonExternalFont);
  Y += ButtonExternalFont.CalculatedHeight + 10;

  ButtonExternalFontChinese := TCastleButton.Create(Application);
  ButtonExternalFontChinese.Caption := 'Switch to external font (with Chinese chars)';
  ButtonExternalFontChinese.OnClick := @FontContainer.ButtonExternalFontChineseClick;
  ButtonExternalFontChinese.Left := 10;
  ButtonExternalFontChinese.Bottom := Y;
  Window.Controls.InsertFront(ButtonExternalFontChinese);
  Y += ButtonExternalFontChinese.CalculatedHeight + 10;

  ButtonEmbeddedFont := TCastleButton.Create(Application);
  ButtonEmbeddedFont.Caption := 'Switch to embedded font (without Chinese chars)';
  ButtonEmbeddedFont.OnClick := @FontContainer.ButtonEmbeddedFontClick;
  ButtonEmbeddedFont.Left := 10;
  ButtonEmbeddedFont.Bottom := Y;
  Window.Controls.InsertFront(ButtonEmbeddedFont);
  Y += ButtonEmbeddedFont.CalculatedHeight + 10;

  ButtonEmbeddedFontChinese := TCastleButton.Create(Application);
  ButtonEmbeddedFontChinese.Caption := 'Switch to embedded font (with Chinese chars)';
  ButtonEmbeddedFontChinese.OnClick := @FontContainer.ButtonEmbeddedFontChineseClick;
  ButtonEmbeddedFontChinese.Left := 10;
  ButtonEmbeddedFontChinese.Bottom := Y;
  Window.Controls.InsertFront(ButtonEmbeddedFontChinese);
  Y += ButtonEmbeddedFontChinese.CalculatedHeight + 10;

  TestLabel := TCastleLabel.Create(Application);
  TestLabel.Caption := 'String hardcoded in Pascal sources:' + NL +
    'Chinese: 你好世界' + NL +
    'Greek: Γεια σου κόσμε!' + NL +
    'Russian: Здравствуй, мир!' + NL +
    'Polish: Witaj świecie! Oraz: źrebię ćma koń wężyk dąb!';
  TestLabel.Bottom := Y;
  TestLabel.Left := 100;
  Window.Controls.InsertFront(TestLabel);
  Y += 200;

  Config := TCastleConfig.Create(application);
  try
    Config.Load(ApplicationData('example_config.xml'));

    TestLabel := TCastleLabel.Create(Application);
    TestLabel.Caption := Config.GetStringNonEmpty('value');
    TestLabel.Bottom := Y;
    TestLabel.Left := 100;
    Window.Controls.InsertFront(TestLabel);
    Y += 200;
  finally FreeAndNil(Config) end;
end;

function MyGetApplicationName: string;
begin
  Result := 'test_local_characters';
end;

initialization
  { This sets SysUtils.ApplicationName.
    It is useful to make sure it is correct (as early as possible)
    as our log routines use it. }
  OnGetApplicationName := @MyGetApplicationName;

  InitializeLog;

  { initialize Application callbacks }
  Application.OnInitialize := @ApplicationInitialize;

  { create Window }
  Window := TCastleWindow.Create(Application);
  Window.Container.UIScaling := usEncloseReferenceSize;
  Window.Container.UIReferenceWidth := 1600;
  Window.Container.UIReferenceHeight := 900;
  Application.MainWindow := Window;
finalization
  FreeAndNil(FontContainer);
end.