{
  Copyright 2009-2017 Michalis Kamburelis.

  This file is part of "Castle Game Engine".

  "Castle Game Engine" is free software; see the file COPYING.txt,
  included in this distribution, for details about the copyright.

  "Castle Game Engine" is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

  ----------------------------------------------------------------------------
}

{ OpenAL EFX (Effects Extension) API.

  Documentation is in OpenAL SDK for Windows (installable under Linux
  through wine).

  TODO: This functionality is NOT yet available through the public
  Castle Game Engine API in CastleSoundEngine. For now, you need to use
  this unit directly, see efx_demo in engine examples. }
unit CastleInternalEFX;

{$I castleconf.inc}

interface

uses CastleVectors, CastleInternalOpenAL, Math;

{$ifndef PASDOC}
{$I castleinternalefx_api.inc}
{$I castleinternalefx_api_creative.inc}
{$endif PASDOC}

{ Checks is EFX extension, along with all it's entry points, present
  for given OpenAL device. If true, it will also initialize the entry
  points of all EFX functions in this unit.

  Note that if even OpenAL is not avaiable (ALInitialized = @false), then this
  will also always return @false. }
function Load_EFX(Device: PALCDevice): boolean;

implementation

function Load_EFX(Device: PALCDevice): boolean;
begin
  Result := ALInitialized and alcIsExtensionPresent(Device, ALC_EXT_EFX_NAME);

  if Result then
  begin
    {$ifdef CASTLE_OBJFPC}Pointer{$endif} (alGenEffects) := alGetProcAddress('alGenEffects'); if not Assigned(alGenEffects) then Exit(false);
    {$ifdef CASTLE_OBJFPC}Pointer{$endif} (alDeleteEffects) := alGetProcAddress('alDeleteEffects'); if not Assigned(alDeleteEffects) then Exit(false);
    {$ifdef CASTLE_OBJFPC}Pointer{$endif} (alIsEffect) := alGetProcAddress('alIsEffect'); if not Assigned(alIsEffect) then Exit(false);
    {$ifdef CASTLE_OBJFPC}Pointer{$endif} (alEffecti) := alGetProcAddress('alEffecti'); if not Assigned(alEffecti) then Exit(false);
    {$ifdef CASTLE_OBJFPC}Pointer{$endif} (alEffectiv) := alGetProcAddress('alEffectiv'); if not Assigned(alEffectiv) then Exit(false);
    {$ifdef CASTLE_OBJFPC}Pointer{$endif} (alEffectf) := alGetProcAddress('alEffectf'); if not Assigned(alEffectf) then Exit(false);
    {$ifdef CASTLE_OBJFPC}Pointer{$endif} (alEffectfv) := alGetProcAddress('alEffectfv'); if not Assigned(alEffectfv) then Exit(false);
    {$ifdef CASTLE_OBJFPC}Pointer{$endif} (alGetEffecti) := alGetProcAddress('alGetEffecti'); if not Assigned(alGetEffecti) then Exit(false);
    {$ifdef CASTLE_OBJFPC}Pointer{$endif} (alGetEffectiv) := alGetProcAddress('alGetEffectiv'); if not Assigned(alGetEffectiv) then Exit(false);
    {$ifdef CASTLE_OBJFPC}Pointer{$endif} (alGetEffectf) := alGetProcAddress('alGetEffectf'); if not Assigned(alGetEffectf) then Exit(false);
    {$ifdef CASTLE_OBJFPC}Pointer{$endif} (alGetEffectfv) := alGetProcAddress('alGetEffectfv'); if not Assigned(alGetEffectfv) then Exit(false);
    {$ifdef CASTLE_OBJFPC}Pointer{$endif} (alGenFilters) := alGetProcAddress('alGenFilters'); if not Assigned(alGenFilters) then Exit(false);
    {$ifdef CASTLE_OBJFPC}Pointer{$endif} (alDeleteFilters) := alGetProcAddress('alDeleteFilters'); if not Assigned(alDeleteFilters) then Exit(false);
    {$ifdef CASTLE_OBJFPC}Pointer{$endif} (alIsFilter) := alGetProcAddress('alIsFilter'); if not Assigned(alIsFilter) then Exit(false);
    {$ifdef CASTLE_OBJFPC}Pointer{$endif} (alFilteri) := alGetProcAddress('alFilteri'); if not Assigned(alFilteri) then Exit(false);
    {$ifdef CASTLE_OBJFPC}Pointer{$endif} (alFilteriv) := alGetProcAddress('alFilteriv'); if not Assigned(alFilteriv) then Exit(false);
    {$ifdef CASTLE_OBJFPC}Pointer{$endif} (alFilterf) := alGetProcAddress('alFilterf'); if not Assigned(alFilterf) then Exit(false);
    {$ifdef CASTLE_OBJFPC}Pointer{$endif} (alFilterfv) := alGetProcAddress('alFilterfv'); if not Assigned(alFilterfv) then Exit(false);
    {$ifdef CASTLE_OBJFPC}Pointer{$endif} (alGetFilteri) := alGetProcAddress('alGetFilteri'); if not Assigned(alGetFilteri) then Exit(false);
    {$ifdef CASTLE_OBJFPC}Pointer{$endif} (alGetFilteriv) := alGetProcAddress('alGetFilteriv'); if not Assigned(alGetFilteriv) then Exit(false);
    {$ifdef CASTLE_OBJFPC}Pointer{$endif} (alGetFilterf) := alGetProcAddress('alGetFilterf'); if not Assigned(alGetFilterf) then Exit(false);
    {$ifdef CASTLE_OBJFPC}Pointer{$endif} (alGetFilterfv) := alGetProcAddress('alGetFilterfv'); if not Assigned(alGetFilterfv) then Exit(false);
    {$ifdef CASTLE_OBJFPC}Pointer{$endif} (alGenAuxiliaryEffectSlots) := alGetProcAddress('alGenAuxiliaryEffectSlots'); if not Assigned(alGenAuxiliaryEffectSlots) then Exit(false);
    {$ifdef CASTLE_OBJFPC}Pointer{$endif} (alDeleteAuxiliaryEffectSlots) := alGetProcAddress('alDeleteAuxiliaryEffectSlots'); if not Assigned(alDeleteAuxiliaryEffectSlots) then Exit(false);
    {$ifdef CASTLE_OBJFPC}Pointer{$endif} (alIsAuxiliaryEffectSlot) := alGetProcAddress('alIsAuxiliaryEffectSlot'); if not Assigned(alIsAuxiliaryEffectSlot) then Exit(false);
    {$ifdef CASTLE_OBJFPC}Pointer{$endif} (alAuxiliaryEffectSloti) := alGetProcAddress('alAuxiliaryEffectSloti'); if not Assigned(alAuxiliaryEffectSloti) then Exit(false);
    {$ifdef CASTLE_OBJFPC}Pointer{$endif} (alAuxiliaryEffectSlotiv) := alGetProcAddress('alAuxiliaryEffectSlotiv'); if not Assigned(alAuxiliaryEffectSlotiv) then Exit(false);
    {$ifdef CASTLE_OBJFPC}Pointer{$endif} (alAuxiliaryEffectSlotf) := alGetProcAddress('alAuxiliaryEffectSlotf'); if not Assigned(alAuxiliaryEffectSlotf) then Exit(false);
    {$ifdef CASTLE_OBJFPC}Pointer{$endif} (alAuxiliaryEffectSlotfv) := alGetProcAddress('alAuxiliaryEffectSlotfv'); if not Assigned(alAuxiliaryEffectSlotfv) then Exit(false);
    {$ifdef CASTLE_OBJFPC}Pointer{$endif} (alGetAuxiliaryEffectSloti) := alGetProcAddress('alGetAuxiliaryEffectSloti'); if not Assigned(alGetAuxiliaryEffectSloti) then Exit(false);
    {$ifdef CASTLE_OBJFPC}Pointer{$endif} (alGetAuxiliaryEffectSlotiv) := alGetProcAddress('alGetAuxiliaryEffectSlotiv'); if not Assigned(alGetAuxiliaryEffectSlotiv) then Exit(false);
    {$ifdef CASTLE_OBJFPC}Pointer{$endif} (alGetAuxiliaryEffectSlotf) := alGetProcAddress('alGetAuxiliaryEffectSlotf'); if not Assigned(alGetAuxiliaryEffectSlotf) then Exit(false);
    {$ifdef CASTLE_OBJFPC}Pointer{$endif} (alGetAuxiliaryEffectSlotfv) := alGetProcAddress('alGetAuxiliaryEffectSlotfv'); if not Assigned(alGetAuxiliaryEffectSlotfv) then Exit(false);
  end;
end;

end.
