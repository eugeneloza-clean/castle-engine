{
  Copyright 2012-2017 Michalis Kamburelis.

  This file is part of "Castle Game Engine".

  "Castle Game Engine" is free software; see the file COPYING.txt,
  included in this distribution, for details about the copyright.

  "Castle Game Engine" is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

  ----------------------------------------------------------------------------
}

{ Test CastleRandom unit. }
unit TestCastleRandom;

interface

uses
  Classes, SysUtils, fpcunit, testutils, testregistry, CastleBaseTestCase;

type
  TTestCastleRandom = class(TCastleBaseTestCase)
  published
    procedure TestHash;
    procedure TestRandom;
  end;

implementation

uses CastleRandom;

procedure TTestCastleRandom.TestHash;
begin
  //zero string Hash
  AssertTrue(StringToHash('') = 0);
  AssertTrue(StringToHash('1') = %01001001001101000010111110101111);
  //zero seed Hash
  AssertTrue(StringToHash('String to hash test') = %11100000010001101011001110011100);
  //seeded hash
  AssertTrue(StringToHash('String to hash test',$9747b28c) = %01111101100111100000101011011100);
end;

procedure TTestCastleRandom.TestRandom;
const NTests = 10000000;
var Rnd: TCastleRandom;
    i: integer;
    Sum: double;
begin
  Rnd := TCastleRandom.Create;

  //test that random is in 0..1 limits
  for i := 0 to NTests do
    AssertTrue(Rnd.Random <= 1);
  for i := 0 to NTests do
    AssertTrue(Rnd.Random > 0);

  //test random homogeneity
  {p.s. I'm not exactly sure if this is the right way to do, because random
   is random, and therefore there's always a tiny chance that it'll fail the test}
  Sum := 0;
  for i := 0 to NTests*10 do
    Sum += Rnd.random;
  //checking random against shot noise
  AssertTrue(abs(Sum/(NTests*10)-0.5) <= 2/sqrt(NTests*10));

  FreeAndNil(Rnd);
end;


initialization
  RegisterTest(TTestCastleRandom);
end.
