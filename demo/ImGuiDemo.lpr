{
  FreePascal bindings for ImGui

  Copyright (C) 2023 Coldzer0 <Coldzer0 [at] protonmail.ch>

  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU LESSER GENERAL PUBLIC LICENSE as published by
  the Free Software Foundation, version 3 of the License.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU LESSER GENERAL PUBLIC LICENSE for more details.
}

Program ImGuiDemo;
{$IFDEF FPC}
  {$mode objfpc}{$H+}{$J-}
{$ENDIF}
{$IfDef LINUX}
  {$LinkLib m}
{$EndIf}
{$IfOpt D-}
  {$IfDef MSWINDOWS}
    {$AppType GUI}
  {$EndIf}
{$ELSE}
{$IfDef MSWINDOWS}
  {$AppType console}
{$EndIf}
{$EndIf}

Uses
  SysUtils,
  sdl2,
  glad_gl,
  PasImGui,
  PasImGui.Apis,
  PasImGui.Types,
  PasImGui.Enums,
  OpenGl3.Loader,
  PasImGui.SDL2,
  CImGui.Impl.OpenGL3,
  imgui_extra,
  TestWindow;

Var
  counter: Integer;
  showPascalDemoWindow: Boolean = False;
  showAnotherWindow: Boolean = False;
  showDemoWindow: Boolean = False;
  clearColor: ImVec4;
  float_value : Single;

Var
  ImGuiCtx : PImGuiContext;
  ioptr: PImGuiIO;
  quit: Boolean;
  window: PSDL_Window;
  e: TSDL_Event;
  testwin : TTestWindow;
  backup_current_window: PSDL_Window;
  backup_current_context: TSDL_GLContext;
  current: TSDL_DisplayMode;
  flags: Longword;
  gl_context: TSDL_GLContext;
  w, h: Integer;
  glsl_version: PChar = '';



  Procedure ShowGreetingWindows;
  Var
    draw_list: PImDrawList;
    pos: ImVec2;
  Const
    HelloPascal: PChar = ' Hello From FreePascal ';
  Begin
    Begin
      //ImGui.SetWindowPos(ImVec2.New(100, 100), ImGuiCond_FirstUseEver);
      ImGui.SetNextWindowPosCenter(ImGuiCond_FirstUseEver);
      if not ImGui.Begin_('Greeting') then
      Begin
        // Early out if the window is collapsed, as an optimization.
        ImGui.End_;
        exit;
      End;
      ImGui.Text('Hello, world %d', [counter]);
      If ImGui.Button('Add') Then
      Begin
        //button was pressed, do something special!
        Inc(counter);
      End;
      If ImGui.IsItemHovered(ImGuiHoveredFlags_RectOnly) Then
      Begin
        ImGui.SameLine();
        ImGui.Text('button hovered');
      End;

      ImGui.SameLine();
      pos := ImGui.GetCursorScreenPos();

      draw_list := ImGui.GetWindowDrawList();
      draw_list^.AddRectFilled(pos, ImVec2.New(pos.x + 50, pos.y + 20), $88000055);

      pos := ImVec2.New(pos.x + 50 + 20, pos.y);
      ImGui.SetCursorScreenPos(pos);

      draw_list^.AddRectFilled(pos, ImVec2.New(pos.x +
        ImGui.CalcTextSize(HelloPascal).x, pos.y + 20), $88005500);
      ImGui.Text(HelloPascal);

      If ImGui.IsWindowHovered() Then
        ImGui.Text('window hovered')
      Else If ImGui.IsWindowHovered(ImGuiHoveredFlags_AnyWindow) Then
        ImGui.Text('some window hovered');
      ImGui.End_;
    End;
    Pos := ImGui.GetCenterViewPort(ImGui.GetMainViewport());
    Pos.y += 100;
    ImGui.SetNextWindowPos(Pos,ImGuiCond_FirstUseEver, ImVec2.New(0.5, 0.5));
    begin
      ImGui.Begin_('Another greeting');
      ImGui.SetWindowPos(ImVec2.New(400, 200), ImGuiCond_FirstUseEver);
      ImGui.Text('Hello, next world %d', [counter]);
      If ImGui.Button('Not OK!') Then
      Begin
        Dec(counter);
      End;
      ImGui.End_;
    end;
  End;

  procedure RenderPascalCode();
  var
    Pos : ImVec2;
  begin
    //draw your scene or simple windows
    Pos := ImGui.GetCenterViewPort(ImGui.GetMainViewport());
    Pos.y -= 160;
    ImGui.SetNextWindowPos(Pos,ImGuiCond_FirstUseEver, ImVec2.New(0.5, 0.5));
    Begin
      ImGui.Begin_('Hello From FreePascal', nil, ImGuiWindowFlags_None);
      ImGui.Text('This is some useful text', []);
      ImGui.Checkbox('Demo window', @showDemoWindow);
      ImGui.Checkbox('Another Pascal window', @showAnotherWindow);
      ImGui.Checkbox('Pascal Demo Window', @showPascalDemoWindow);

      ImGui.SliderFloat('Float', @float_value, 0.0, 1.0, '%.3f', ImGuiSliderFlags_None);
      ImGui.ColorEdit3('Background color', @clearColor, ImGuiColorEditFlags_None);

      If (ImGui.Button('Button')) Then
        counter += 1;

      ImGui.SameLine(0.0, -1.0);
      ImGui.Text('counter = %d', [counter]);

      ImGui.Text('Application average %.3f ms/frame (%.1f FPS)',
        [1000.0 / ioptr^.Framerate, ioptr^.Framerate]);

      ImGui.End_();
    End;

    If showAnotherWindow Then
    begin
      ShowGreetingWindows;
    end;

    If showDemoWindow Then
    begin
      ImGui.ShowDemoWindow();
    end;
  end;

  Function PasAllocMem(sz: size_t; {%H-}user_data: Pointer): Pointer; Cdecl;
  Begin
    Result := AllocMem(sz);
  End;

  Procedure PasFreeMem(ptr: Pointer; {%H-}user_data: Pointer); Cdecl;
  Begin
    Freemem(ptr);
  End;

Var
  saved_FpuFlags: Cardinal;

{$R *.res}

Begin
  { TODO: This is here for testing - Remove this later :V }
  //DeleteFile('imgui.ini');

  // Set the Default Alloc & Free to point to Pascal Allocators
  igSetAllocatorFunctions(@PasAllocMem, @PasFreeMem, nil);

  //prevent SDL from raising a debugger exception to name threads
  SDL_SetHint(SDL_HINT_WINDOWS_DISABLE_THREAD_NAMING, '1');

  //open new SDL window with OpenGL rendering support
  If SDL_Init(SDL_INIT_VIDEO) < 0 Then
  Begin
    SDL_Log('failed to init: %s', [SDL_GetError()]);
  End;

  // Decide GL+GLSL versions
  {$IfDef DARWIN}
  // GL 3.2 Core + GLSL 150
  // Always required on Mac
  glsl_version = '#version 150';
  SDL_GL_SetAttribute(SDL_GL_CONTEXT_FLAGS, SDL_GL_CONTEXT_FORWARD_COMPATIBLE_FLAG);
  SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE);
  SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 3);
  SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 2);
  {$ELSE}
  // GL 3.0 + GLSL 130
  glsl_version := '#version 130';
  SDL_GL_SetAttribute(SDL_GL_CONTEXT_FLAGS, 0);
  SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE);
  SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 3);
  SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 0);
  {$EndIf}

  SDL_SetHint(SDL_HINT_RENDER_DRIVER, 'opengl');
  SDL_GL_SetAttribute(SDL_GL_DEPTH_SIZE, 24);
  SDL_GL_SetAttribute(SDL_GL_STENCIL_SIZE, 8);
  SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);
  SDL_GetCurrentDisplayMode(0, @current);

  flags := SDL_WINDOW_SHOWN Or SDL_WINDOW_OPENGL Or SDL_WINDOW_RESIZABLE;
  //flags := flags or SDL_WINDOW_FULLSCREEN_DESKTOP;

  h := 768;
  w := 1024;
  window := SDL_CreateWindow('Hello From FreePascal', SDL_WINDOWPOS_CENTERED,
    SDL_WINDOWPOS_CENTERED, w, h, flags);
  If window = nil Then
  Begin
    SDL_Log('Failed to create window: %s', [SDL_GetError()]);
    halt;
  End;

  gl_context := SDL_GL_CreateContext(window);
  SDL_GL_SetSwapInterval(1); //enable VSync


  // Loading OpenGL APIs
  If Not ImGLInit() Then
  Begin
    SDL_Log('Error while Loading OpenGL3', []);
  End;

  // Show opengl version sdl uses
  SDL_Log('opengl version: %s', [glGetString(GL_VERSION)]);

  // setup imgui
  ImGui.CreateContext(nil);

  //set docking
  ioptr := ImGui.GetIO();

  // Enable Logging
  ImGuiCtx := ImGui.GetCurrentContext();
  ImGuiCtx^.LogEnabled := True;

  // Enable Keyboard Controls
  ioptr^.ConfigFlags := ioptr^.ConfigFlags Or ImGuiConfigFlags_NavEnableKeyboard;
  // Enable Docking
  ioptr^.ConfigFlags := ioptr^.ConfigFlags Or ImGuiConfigFlags_DockingEnable;
  // Enable Multi-Viewport / Platform Windows
  ioptr^.ConfigFlags := ioptr^.ConfigFlags Or ImGuiConfigFlags_ViewportsEnable;


  // Init ImGui SDL2 OpenGL using Pure Pascal
  ImGui_ImplSDL2_InitForOpenGL_Pas(window, gl_context);
  ImGui_Impl_OpenGL3_Init(glsl_version);


  { uncomment to set a different gui theme }
  SetupImGuiStyle2(); // Using imgui_easy_theming
  //Imgui.StyleColorsDark(nil);
  //Imgui.StyleColorsLight(ImGui.GetStyle());


  // Background Color
  clearColor.x := 0.45;
  clearColor.y := 0.55;
  clearColor.z := 0.60;
  clearColor.w := 1.00;

  testwin := TTestWindow.Create;
  counter := 0;
  quit := False;
  While Not quit Do
  Begin
    //handle input
    While SDL_PollEvent(@e) <> 0 Do
    Begin
      ImGui_ImplSDL2_ProcessEvent_Pas(@e);
      If e.type_ = SDL_QUITEV Then
        quit := True;
      If (e.type_ = SDL_WINDOWEVENT) And (e.window.event = SDL_WINDOWEVENT_CLOSE) And
        (e.window.windowID = SDL_GetWindowID(window)) Then
        quit := True;
    End;

    // start imgui frame
    ImGui_Impl_OpenGL3_NewFrame();
    ImGui_ImplSDL2_NewFrame_Pas();
    ImGui.NewFrame();

    // Main UI Code
    begin
      RenderPascalCode();
      if showPascalDemoWindow then
        testwin.Show(showPascalDemoWindow);
    end;

    // render
    ImGui.Render();
    SDL_GL_MakeCurrent(window, gl_context);


    saved_FpuFlags := SetFpuFlags();
    glViewport(0, 0, Trunc(ioptr^.DisplaySize.x), Trunc(ioptr^.DisplaySize.y));
    glClearColor(clearColor.x, clearColor.y, clearColor.z, clearColor.w);
    glClear(GL_COLOR_BUFFER_BIT);
    ResetFpuFlags(saved_FpuFlags);

    ImGui_Impl_OpenGL3_RenderDrawData(ImGui.GetDrawData());



    // IMGUI_DOCK
    If Ord(ioptr^.ConfigFlags And ImGuiConfigFlags_ViewportsEnable) <> 0 Then
    Begin
      backup_current_window := SDL_GL_GetCurrentWindow();
      backup_current_context := SDL_GL_GetCurrentContext();
      ImGui.UpdatePlatformWindows();
      ImGui.RenderPlatformWindowsDefault(nil, nil);
      SDL_GL_MakeCurrent(backup_current_window, backup_current_context);
    End;

    //show frame on display
    SDL_GL_SwapWindow(window);
    //Assert(glGetError() = GL_NO_ERROR);
  End;
  testwin.Free;

  // clean up
  ImGui_Impl_OpenGL3_Shutdown();
  ImGui_ImplSDL2_Shutdown_Pas();
  ImGui.DestroyContext(nil);

  SDL_GL_DeleteContext(gl_context);
  If window <> nil Then
  Begin
    SDL_DestroyWindow(window);
    window := nil;
  End;
  SDL_Quit();
End.
