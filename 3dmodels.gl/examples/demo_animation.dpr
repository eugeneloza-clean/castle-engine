{ Demo of TVRMLGLAnimation class.

  Run this passing 2 command-line parameters: filenames of two 3D files
  that have identical structure. Effect: this will display nice animation
  that animates between 1st model and 2nd.

  I prepared two sets of sample models in this directory. Try these commands
    ./demo_animation sphere_1.wrl sphere_2.wrl
    ./demo_animation raptor_1.wrl raptor_2.wrl

  You can navigate in the scene using the standard arrow keys, escape exits.
  (for full list of supported keys -- see view3dscene documentation,
  [http://www.camelot.homedns.org/~michalis/view3dscene.php],
  at Walk navigation method).

  You may notice that the 1st pass of the animation is much slower than the
  following ones, that's because in the 1st pass OpenGL display lists
  are created, in later passes they are only used.
  (Of course this strange effect is avoidable, that's the purpose
  of TVRMLFlatSceneGL.PrepareRender -- in real program you should
  first prepare all animation scenes, because usually user prefers
  to wait some time "while the level is loading" and then have a smooth
  play. I didn't implement this in this demo program for simplicity.)
}

program demo_animation;

uses VectorMath, Boxes3d, VRMLNodes, VRMLOpenGLRenderer, OpenGLh, GLWindow,
  GLW_Navigated, KambiClassUtils, KambiUtils, SysUtils, Classes, Object3dAsVRML,
  KambiGLUtils, VRMLFlatScene, VRMLFlatSceneGL, MatrixNavigation, VRMLGLAnimation;

const
  { This is the number of animation frames constructed.
    Increase this to get more smooth animation.
    Note that this will also make animation run in longer time -- you
    can balance this by changing also AnimationSpeed. }
  ScenesCount = 100;

  { How fast animation frames change. }
  AnimationSpeed = 0.4;

var
  Animation: TVRMLGLAnimation;
  { We keep this as Float, to easily increase it in Idle.
    But actually this will be always Rounded when used to choose
    a particular animation frame. }
  AnimationPosition: Float = 0.0;

procedure Draw(glwin: TGLWindow);
var
  Pos, RoundedAnimationPosition: Integer;
begin
 glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);
 glLoadMatrix(glw.Navigator.Matrix);

 RoundedAnimationPosition := Round(AnimationPosition);
 Pos := RoundedAnimationPosition mod ScenesCount;
 { In the odd rounds, we run the same animation backwards. }
 if Odd(RoundedAnimationPosition div ScenesCount) then
  Pos := ScenesCount - 1 - Pos;
 Animation.Scenes[Pos].Render(nil);
end;

procedure Idle(glwin: TGLWindow);
begin
 AnimationPosition += AnimationSpeed * glwin.FpsCompSpeed;
end;

procedure Init(glwin: TGLWindow);
begin
 glEnable(GL_LIGHTING);
 glEnable(GL_LIGHT0);
end;

procedure Close(glwin: TGLWindow);
begin
 Animation.ScenesCloseGLAll;
end;

procedure Resize(glwin: TGLWindow);
begin
 glViewport(0, 0, glwin.Width, glwin.Height);
 ProjectionGLPerspective(45.0, glwin.Width/glwin.Height,
   Box3dMaxSize(Animation.Scenes[0].BoundingBox) * 0.05,
   Box3dMaxSize(Animation.Scenes[0].BoundingBox) * 3.0);
end;

var
  CamPos, CamDir, CamUp: TVector3Single;
begin
 ParCountEqual(2);
 try
  VRMLNonFatalError := VRMLNonFatalError_WarningWrite;

  Animation := TVRMLGLAnimation.Create(
    LoadAsVRML(ParStr(1), false), true,
    LoadAsVRML(ParStr(2), false), true,
    ScenesCount,
    roSceneAsAWhole);

  { get camera from 1st scene in Animation }
  Animation.Scenes[0].GetPerspectiveCamera(CamPos, CamDir, CamUp);

  { init Glw.Navigator }
  Glw.Navigator := TMatrixWalker.Create(Glw.PostRedisplayOnMatrixChanged);
  Glw.NavWalker.Init(CamPos, VectorAdjustToLength(CamDir,
    Box3dAvgSize(Animation.Scenes[0].BoundingBox) * 0.01*0.4), CamUp);

  Glw.AutoRedisplay := true;
  Glw.OnInit := Init;
  Glw.OnClose := Close;
  Glw.OnResize := Resize;
  Glw.OnIdle := Idle;
  Glw.InitLoop(ProgramName, Draw);
 finally Animation.Free end;
end.
