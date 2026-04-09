unit ModernTabControl;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, Graphics, Forms, LCLType, ExtCtrls, Types,
  LResources, LCLIntf, Menus, Math
  {$IFDEF WINDOWS}, Windows{$ENDIF};

type
  TTabCloseEvent    = procedure(Sender: TObject; TabIndex: Integer; var CanClose: Boolean) of object;
  TTabMoveEvent     = procedure(Sender: TObject; OldIndex, NewIndex: Integer) of object;

  TModernTab = class
  public
    Caption:   string;
    Hint:      string;
    TabRect:   TRect;
    CloseRect: TRect;
  end;

  TModernTabControl = class(TCustomControl)
  private
    FTabs:          TList;
    FActiveTab:     Integer;
    FTabHeight:     Integer;
    FHoverTab:      Integer;
    FHoverClose:    Integer;
    FNoteBook:      TNotebook;
    FScrollOffset:  Integer;
    FShowAddButton: Boolean;
    FAddBtnRect:    TRect;
    FSepWidth:      Integer;

    // Arrastar
    FDragTab:       Integer;
    FDragStartX:    Integer;
    FDragging:      Boolean;

    // Tooltip
    FHintWindow:    THintWindow;
    FLastHintTab:   Integer;

    // Cores
    FColorBackground:   TColor;
    FColorTabInactive:  TColor;
    FColorTabHover:     TColor;
    FColorTabActive:    TColor;
    FColorAccent:       TColor;
    FColorTextInactive: TColor;
    FColorTextActive:   TColor;
    FColorClose:        TColor;
    FColorCloseHover:   TColor;
    FColorSeparator:    TColor;
    FColorAddButton:    TColor;
    FColorScrollBtn:    TColor;

    // Scroll
    FScrollLeftRect:  TRect;
    FScrollRightRect: TRect;
    FHoverScrollLeft: Boolean;
    FHoverScrollRight:Boolean;

    FOnChange:    TNotifyEvent;
    FOnCloseTab:  TTabCloseEvent;
    FOnMoveTab:   TTabMoveEvent;
    FOnAddTab:    TNotifyEvent;

    function GetTab(Index: Integer): TModernTab;
    function GetTabCount: Integer;
    procedure SetActiveTab(Value: Integer);
    procedure SetNoteBook(Value: TNotebook);
    procedure SetTabHeight(Value: Integer);
    procedure SetColorBackground(Value: TColor);
    procedure SetColorTabInactive(Value: TColor);
    procedure SetColorTabHover(Value: TColor);
    procedure SetColorTabActive(Value: TColor);
    procedure SetColorAccent(Value: TColor);
    procedure SetColorTextInactive(Value: TColor);
    procedure SetColorTextActive(Value: TColor);
    procedure SetColorClose(Value: TColor);
    procedure SetColorCloseHover(Value: TColor);
    procedure SetColorSeparator(Value: TColor);
    procedure SetSepWidth(Value: Integer);
    procedure RecalcTabRects;
    function FindTabAt(X, Y: Integer): Integer;
    function FindCloseAt(X, Y: Integer): Integer;
    procedure SyncFromNoteBook;
    procedure ScrollLeft;
    procedure ScrollRight;
    function TotalTabsWidth: Integer;
    function VisibleWidth: Integer;
    procedure ShowTabHint(TabIndex: Integer);
    procedure HideHint;
    procedure MoveTab(OldIndex, NewIndex: Integer);

  protected
    procedure Paint; override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseLeave; override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure Resize; override;

  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    function AddTab(const ACaption: string; const AHint: string = ''): Integer;
    procedure DeleteTab(Index: Integer);
    procedure Clear;
    procedure SetTabHint(Index: Integer; const AHint: string);

    property Tabs[Index: Integer]: TModernTab read GetTab;
    property TabCount: Integer read GetTabCount;

  published
    // Notebook
    property NoteBook: TNotebook read FNoteBook write SetNoteBook;

    // Comportamento
    property ActiveTab:  Integer read FActiveTab  write SetActiveTab;
    property TabHeight:  Integer read FTabHeight  write SetTabHeight   default 36;
    property SepWidth:   Integer read FSepWidth   write SetSepWidth    default 1;

    // Cores
    property ColorBackground:   TColor read FColorBackground   write SetColorBackground;
    property ColorTabInactive:  TColor read FColorTabInactive  write SetColorTabInactive;
    property ColorTabHover:     TColor read FColorTabHover     write SetColorTabHover;
    property ColorTabActive:    TColor read FColorTabActive    write SetColorTabActive;
    property ColorAccent:       TColor read FColorAccent       write SetColorAccent;
    property ColorTextInactive: TColor read FColorTextInactive write SetColorTextInactive;
    property ColorTextActive:   TColor read FColorTextActive   write SetColorTextActive;
    property ColorClose:        TColor read FColorClose        write SetColorClose;
    property ColorCloseHover:   TColor read FColorCloseHover  write SetColorCloseHover;
    property ColorSeparator:    TColor read FColorSeparator    write SetColorSeparator;

    // Padrão
    property Align;
    property Anchors;
    property Enabled;
    property Font;
    property Height;
    property Width;
    property Visible;
    property ShowHint;
    property ParentShowHint;

    // Eventos
    property OnChange:   TNotifyEvent    read FOnChange   write FOnChange;
    property OnCloseTab: TTabCloseEvent  read FOnCloseTab write FOnCloseTab;
    property OnMoveTab:  TTabMoveEvent   read FOnMoveTab  write FOnMoveTab;
    property OnAddTab:   TNotifyEvent    read FOnAddTab   write FOnAddTab;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Modern', [TModernTabControl]);
end;

function PointInRect(const R: TRect; const P: TPoint): Boolean;
begin
  Result := (P.X >= R.Left) and (P.X < R.Right) and
            (P.Y >= R.Top)  and (P.Y < R.Bottom);
end;

{ TModernTabControl }

constructor TModernTabControl.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  FTabs           := TList.Create;
  FNoteBook       := nil;
  FOnChange       := nil;
  FOnCloseTab     := nil;
  FOnMoveTab      := nil;
  FOnAddTab       := nil;
  FActiveTab      := -1;
  FHoverTab       := -1;
  FHoverClose     := -1;
  FScrollOffset   := 0;
  FDragTab        := -1;
  FDragging       := False;
  FLastHintTab    := -1;
  FHoverScrollLeft  := False;
  FHoverScrollRight := False;
  FTabHeight      := 36;
  FSepWidth       := 1;
  Height          := FTabHeight;

  // Paleta Dark
  FColorBackground    := $00202020;
  FColorTabInactive   := $002D2D2D;
  FColorTabHover      := $00383838;
  FColorTabActive     := $00424242;
  FColorAccent        := $00CF6E27;
  FColorTextInactive  := $00AAAAAA;
  FColorTextActive    := $00FFFFFF;
  FColorClose         := $00777777;
  FColorCloseHover    := $000055FF;
  FColorSeparator     := $00444444;
  FColorAddButton     := $00383838;
  FColorScrollBtn     := $00383838;

  ControlStyle := ControlStyle + [csOpaque];

  FHintWindow := THintWindow.Create(Self);
end;

destructor TModernTabControl.Destroy;
begin
  HideHint;
  FHintWindow.Free;
  Clear;
  FreeAndNil(FTabs);
  inherited Destroy;
end;

procedure TModernTabControl.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and (AComponent = FNoteBook) then
    FNoteBook := nil;
end;

function TModernTabControl.GetTab(Index: Integer): TModernTab;
begin
  Result := TModernTab(FTabs[Index]);
end;

function TModernTabControl.GetTabCount: Integer;
begin
  Result := FTabs.Count;
end;

// --- Setters de cor e propriedades ---

procedure TModernTabControl.SetTabHeight(Value: Integer);
begin
  if Value = FTabHeight then Exit;
  FTabHeight := Value;
  Height := FTabHeight;
  RecalcTabRects;
  Invalidate;
end;

procedure TModernTabControl.SetSepWidth(Value: Integer);
begin
  if Value = FSepWidth then Exit;
  FSepWidth := Value;
  RecalcTabRects;
  Invalidate;
end;

procedure TModernTabControl.SetColorBackground(Value: TColor);
begin if FColorBackground = Value then Exit; FColorBackground := Value; Invalidate; end;

procedure TModernTabControl.SetColorTabInactive(Value: TColor);
begin if FColorTabInactive = Value then Exit; FColorTabInactive := Value; Invalidate; end;

procedure TModernTabControl.SetColorTabHover(Value: TColor);
begin if FColorTabHover = Value then Exit; FColorTabHover := Value; Invalidate; end;

procedure TModernTabControl.SetColorTabActive(Value: TColor);
begin if FColorTabActive = Value then Exit; FColorTabActive := Value; Invalidate; end;

procedure TModernTabControl.SetColorAccent(Value: TColor);
begin if FColorAccent = Value then Exit; FColorAccent := Value; Invalidate; end;

procedure TModernTabControl.SetColorTextInactive(Value: TColor);
begin if FColorTextInactive = Value then Exit; FColorTextInactive := Value; Invalidate; end;

procedure TModernTabControl.SetColorTextActive(Value: TColor);
begin if FColorTextActive = Value then Exit; FColorTextActive := Value; Invalidate; end;

procedure TModernTabControl.SetColorClose(Value: TColor);
begin if FColorClose = Value then Exit; FColorClose := Value; Invalidate; end;

procedure TModernTabControl.SetColorCloseHover(Value: TColor);
begin if FColorCloseHover = Value then Exit; FColorCloseHover := Value; Invalidate; end;

procedure TModernTabControl.SetColorSeparator(Value: TColor);
begin if FColorSeparator = Value then Exit; FColorSeparator := Value; Invalidate; end;

// --- NoteBook ---

procedure TModernTabControl.SetNoteBook(Value: TNotebook);
begin
  if FNoteBook = Value then Exit;
  FNoteBook := Value;
  if not Assigned(FNoteBook) then Exit;
  FNoteBook.FreeNotification(Self);
  SyncFromNoteBook;
end;

procedure TModernTabControl.SyncFromNoteBook;
var
  i: Integer;
  Tab: TModernTab;
begin
  if not Assigned(FTabs) then Exit;
  if not Assigned(FNoteBook) then Exit;
  if not Assigned(FNoteBook.Pages) then Exit;

  for i := 0 to FTabs.Count - 1 do
    TModernTab(FTabs[i]).Free;
  FTabs.Clear;

  for i := 0 to FNoteBook.Pages.Count - 1 do
  begin
    Tab := TModernTab.Create;
    Tab.Caption := FNoteBook.Pages[i];
    Tab.Hint    := '';
    FTabs.Add(Tab);
  end;

  if FTabs.Count > 0 then
    FActiveTab := FNoteBook.PageIndex
  else
    FActiveTab := -1;

  FScrollOffset := 0;
  RecalcTabRects;
  Invalidate;
end;

procedure TModernTabControl.SetActiveTab(Value: Integer);
begin
  if Value = FActiveTab then Exit;
  if (Value < 0) or (Value >= FTabs.Count) then Exit;
  FActiveTab := Value;
  if Assigned(FNoteBook) then
    FNoteBook.PageIndex := FActiveTab;
  Invalidate;
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

// --- Tabs ---

function TModernTabControl.AddTab(const ACaption: string; const AHint: string = ''): Integer;
var
  Tab: TModernTab;
begin
  Tab := TModernTab.Create;
  Tab.Caption := ACaption;
  Tab.Hint    := AHint;
  Result := FTabs.Add(Tab);

  if Assigned(FNoteBook) then
  begin
    FNoteBook.Pages.Add(ACaption);
    FNoteBook.PageIndex := Result;
  end;

  if FActiveTab = -1 then
    FActiveTab := 0;

  RecalcTabRects;
  Invalidate;
end;

procedure TModernTabControl.SetTabHint(Index: Integer; const AHint: string);
begin
  if (Index < 0) or (Index >= FTabs.Count) then Exit;
  TModernTab(FTabs[Index]).Hint := AHint;
end;

procedure TModernTabControl.DeleteTab(Index: Integer);
var
  Tab: TModernTab;
begin
  if (Index < 0) or (Index >= FTabs.Count) then Exit;

  Tab := TModernTab(FTabs[Index]);
  FTabs.Delete(Index);
  Tab.Free;

  if Assigned(FNoteBook) then
    FNoteBook.Pages.Delete(Index);

  if FActiveTab >= FTabs.Count then
    FActiveTab := FTabs.Count - 1;

  if Assigned(FNoteBook) and (FActiveTab >= 0) then
    FNoteBook.PageIndex := FActiveTab;

  RecalcTabRects;
  Invalidate;
end;

procedure TModernTabControl.Clear;
var
  i: Integer;
begin
  if not Assigned(FTabs) then Exit;
  for i := 0 to FTabs.Count - 1 do
    TModernTab(FTabs[i]).Free;
  FTabs.Clear;
  FActiveTab    := -1;
  FScrollOffset := 0;
  if Assigned(FNoteBook) then
    FNoteBook.Pages.Clear;
  Invalidate;
end;

procedure TModernTabControl.MoveTab(OldIndex, NewIndex: Integer);
var
  Tab: TModernTab;
  PageText: string;
begin
  if OldIndex = NewIndex then Exit;
  if (OldIndex < 0) or (OldIndex >= FTabs.Count) then Exit;
  if (NewIndex < 0) or (NewIndex >= FTabs.Count) then Exit;

  Tab := TModernTab(FTabs[OldIndex]);
  FTabs.Delete(OldIndex);
  FTabs.Insert(NewIndex, Tab);

  if Assigned(FNoteBook) then
  begin
    PageText := FNoteBook.Pages[OldIndex];
    FNoteBook.Pages.Delete(OldIndex);
    FNoteBook.Pages.Insert(NewIndex, PageText);
  end;

  FActiveTab := NewIndex;
  if Assigned(FNoteBook) then
    FNoteBook.PageIndex := FActiveTab;

  if Assigned(FOnMoveTab) then
    FOnMoveTab(Self, OldIndex, NewIndex);

  RecalcTabRects;
  Invalidate;
end;

// --- Scroll ---

function TModernTabControl.TotalTabsWidth: Integer;
var
  i: Integer;
begin
  Result := 0;
  if not Assigned(FTabs) then Exit;
  for i := 0 to FTabs.Count - 1 do
    Result := Result + (TModernTab(FTabs[i]).TabRect.Right - TModernTab(FTabs[i]).TabRect.Left);
  if FSepWidth > 0 then
    Result := Result + (FTabs.Count - 1) * FSepWidth;
end;

function TModernTabControl.VisibleWidth: Integer;
begin
  Result := Width;
  // Desconta botões de scroll se necessário
  if TotalTabsWidth > Width then
    Result := Width - 48; // 2 botões de scroll de 24px cada
end;

procedure TModernTabControl.ScrollLeft;
begin
  if FScrollOffset <= 0 then Exit;
  FScrollOffset := Max(0, FScrollOffset - 80);
  Invalidate;
end;

procedure TModernTabControl.ScrollRight;
var
  MaxOffset: Integer;
begin
  MaxOffset := TotalTabsWidth - VisibleWidth;
  if MaxOffset <= 0 then Exit;
  FScrollOffset := Min(MaxOffset, FScrollOffset + 80);
  Invalidate;
end;

// --- Layout ---

procedure TModernTabControl.RecalcTabRects;
const
  TabPadding  = 16;
  CloseSize   = 14;
  CloseMargin = 6;
var
  i, X, TabW: Integer;
  Tab: TModernTab;
begin
  if not Assigned(FTabs) then Exit;
  if not HandleAllocated then Exit;

  X := 0;
  Canvas.Font := Font;
  for i := 0 to FTabs.Count - 1 do
  begin
    Tab  := TModernTab(FTabs[i]);
    TabW := Canvas.TextWidth(Tab.Caption) + TabPadding * 2 + CloseSize + CloseMargin + 8;

    Tab.TabRect := Rect(X, 0, X + TabW, FTabHeight);

    Tab.CloseRect := Rect(
      Tab.TabRect.Right - CloseSize - CloseMargin,
      (FTabHeight - CloseSize) div 2,
      Tab.TabRect.Right - CloseMargin,
      (FTabHeight - CloseSize) div 2 + CloseSize
    );

    X := X + TabW;
    if FSepWidth > 0 then
      X := X + FSepWidth;
  end;
end;

procedure TModernTabControl.Resize;
begin
  inherited Resize;
  RecalcTabRects;
  Invalidate;
end;

// --- Hint ---

procedure TModernTabControl.ShowTabHint(TabIndex: Integer);
var
  Tab: TModernTab;
  HintStr: string;
  R: TRect;
  P: TPoint;
begin
  if (TabIndex < 0) or (TabIndex >= FTabs.Count) then
  begin
    HideHint;
    Exit;
  end;

  Tab := TModernTab(FTabs[TabIndex]);
  HintStr := Tab.Hint;
  if HintStr = '' then
  begin
    HideHint;
    Exit;
  end;

  if TabIndex = FLastHintTab then Exit;
  FLastHintTab := TabIndex;

  P := ClientToScreen(Point(Tab.TabRect.Left - FScrollOffset, FTabHeight + 2));
  R := FHintWindow.CalcHintRect(300, HintStr, nil);
  OffsetRect(R, P.X, P.Y);
  FHintWindow.ActivateHint(R, HintStr);
end;

procedure TModernTabControl.HideHint;
begin
  FLastHintTab := -1;
  if Assigned(FHintWindow) then
    FHintWindow.Visible := False;
end;

// --- Paint ---

procedure TModernTabControl.Paint;
const
  AccentBarH  = 3;
  ScrollBtnW  = 24;
var
  i, OffX: Integer;
  Tab: TModernTab;
  IsActive, IsHover: Boolean;
  TxtColor, BgColor, CloseColor: TColor;
  TxtRect, TabR, CloseR: TRect;
  cx, cy, TxtY: Integer;
  NeedScroll: Boolean;
  ScrollAreaW: Integer;
begin
  if not Assigned(FTabs) then Exit;

  NeedScroll  := TotalTabsWidth > Width;
  ScrollAreaW := 0;
  if NeedScroll then ScrollAreaW := ScrollBtnW * 2;

  // Fundo geral
  Canvas.Brush.Color := FColorBackground;
  Canvas.FillRect(ClientRect);
  Canvas.Font := Font;

  // Clip de desenho para área das abas
  Canvas.ClipRect := Rect(ScrollAreaW, 0, Width - ScrollAreaW, Height);

  for i := 0 to FTabs.Count - 1 do
  begin
    Tab := TModernTab(FTabs[i]);

    // Offset de scroll
    OffX := -FScrollOffset + ScrollAreaW;
    TabR  := Tab.TabRect;
    OffsetRect(TabR, OffX, 0);
    CloseR := Tab.CloseRect;
    OffsetRect(CloseR, OffX, 0);

    // Pula abas fora da área visível
    if TabR.Right < ScrollAreaW then Continue;
    if TabR.Left  > Width - ScrollAreaW then Continue;

    IsActive := (i = FActiveTab);
    IsHover  := (i = FHoverTab) and not IsActive;

    if IsActive then BgColor := FColorTabActive
    else if IsHover then BgColor := FColorTabHover
    else BgColor := FColorTabInactive;

    Canvas.Brush.Color := BgColor;
    Canvas.Pen.Color   := BgColor;
    Canvas.Rectangle(TabR);

    // Barra acento
    if IsActive then
    begin
      Canvas.Brush.Color := FColorAccent;
      Canvas.Pen.Color   := FColorAccent;
      Canvas.Rectangle(TabR.Left, TabR.Bottom - AccentBarH, TabR.Right, TabR.Bottom);
    end;

    // Separador direito
    if (FSepWidth > 0) and (i < FTabs.Count - 1) then
    begin
      Canvas.Brush.Color := FColorSeparator;
      Canvas.Pen.Color   := FColorSeparator;
      Canvas.Rectangle(TabR.Right, 4, TabR.Right + FSepWidth, FTabHeight - 4);
    end;

    // Texto
    TxtColor := FColorTextActive;
    if not IsActive then TxtColor := FColorTextInactive;
    Canvas.Font.Color  := TxtColor;
    Canvas.Brush.Style := bsClear;

    TxtRect       := TabR;
    TxtRect.Left  := TabR.Left + 12;
    TxtRect.Right := CloseR.Left - 4;
    TxtY := TxtRect.Top + (FTabHeight - Canvas.TextHeight(Tab.Caption)) div 2;
    Canvas.TextRect(TxtRect, TxtRect.Left, TxtY, Tab.Caption);

    Canvas.Brush.Style := bsSolid;

    // Botão X
    if i = FHoverClose then CloseColor := FColorCloseHover
    else if IsActive then CloseColor := FColorClose
    else CloseColor := $00555555;

    Canvas.Pen.Color := CloseColor;
    Canvas.Pen.Width := 2;
    cx := (CloseR.Left + CloseR.Right)  div 2;
    cy := (CloseR.Top  + CloseR.Bottom) div 2;
    Canvas.MoveTo(cx - 4, cy - 4); Canvas.LineTo(cx + 4, cy + 4);
    Canvas.MoveTo(cx + 4, cy - 4); Canvas.LineTo(cx - 4, cy + 4);
    Canvas.Pen.Width := 1;
  end;

  // Botões de scroll
  if NeedScroll then
  begin
    FScrollLeftRect  := Rect(0, 0, ScrollBtnW, FTabHeight);
    FScrollRightRect := Rect(Width - ScrollBtnW, 0, Width, FTabHeight);

    // Esquerda
    Canvas.Brush.Color := FColorScrollBtn;
    Canvas.Pen.Color   := FColorScrollBtn;
    Canvas.Rectangle(FScrollLeftRect);
    Canvas.Pen.Color := FColorTextActive;
    Canvas.Pen.Width := 2;
    cx := ScrollBtnW div 2;
    cy := FTabHeight div 2;
    Canvas.MoveTo(cx + 5, cy - 5); Canvas.LineTo(cx - 3, cy);
    Canvas.MoveTo(cx - 3, cy);     Canvas.LineTo(cx + 5, cy + 5);
    Canvas.Pen.Width := 1;

    // Direita
    Canvas.Brush.Color := FColorScrollBtn;
    Canvas.Pen.Color   := FColorScrollBtn;
    Canvas.Rectangle(FScrollRightRect);
    Canvas.Pen.Color := FColorTextActive;
    Canvas.Pen.Width := 2;
    cx := Width - ScrollBtnW div 2;
    Canvas.MoveTo(cx - 5, cy - 5); Canvas.LineTo(cx + 3, cy);
    Canvas.MoveTo(cx + 3, cy);     Canvas.LineTo(cx - 5, cy + 5);
    Canvas.Pen.Width := 1;
  end else
  begin
    FScrollLeftRect  := Rect(0, 0, 0, 0);
    FScrollRightRect := Rect(0, 0, 0, 0);
  end;
end;

// --- Mouse ---

procedure TModernTabControl.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  NewHoverTab, NewHoverClose: Integer;
  NeedScroll: Boolean;
  AdjX: Integer;
  NewHoverSL, NewHoverSR: Boolean;
begin
  NeedScroll := TotalTabsWidth > Width;

  NewHoverSL := NeedScroll and PointInRect(FScrollLeftRect,  Point(X, Y));
  NewHoverSR := NeedScroll and PointInRect(FScrollRightRect, Point(X, Y));

  // Arrastar
  if FDragging and (FDragTab >= 0) then
  begin
    AdjX := X + FScrollOffset - (ifthen (NeedScroll, 24, 0));
    NewHoverTab := FindTabAt(AdjX, Y);
    if (NewHoverTab >= 0) and (NewHoverTab <> FDragTab) then
      MoveTab(FDragTab, NewHoverTab);
    FDragTab := FActiveTab;
    inherited;
    Exit;
  end;

  AdjX := X + FScrollOffset - (ifthen (NeedScroll, 24, 0));

  NewHoverClose := FindCloseAt(AdjX, Y);
  if NewHoverClose >= 0 then
    NewHoverTab := NewHoverClose
  else
    NewHoverTab := FindTabAt(AdjX, Y);

  if (NewHoverTab <> FHoverTab) or (NewHoverClose <> FHoverClose)
  or (NewHoverSL <> FHoverScrollLeft) or (NewHoverSR <> FHoverScrollRight) then
  begin
    FHoverTab         := NewHoverTab;
    FHoverClose       := NewHoverClose;
    FHoverScrollLeft  := NewHoverSL;
    FHoverScrollRight := NewHoverSR;
    Invalidate;
  end;

  // Tooltip
  if (NewHoverTab >= 0) and (NewHoverClose < 0) then
    ShowTabHint(NewHoverTab)
  else
    HideHint;

  inherited;
end;

procedure TModernTabControl.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  CloseIdx, TabIdx: Integer;
  CanClose: Boolean;
  NeedScroll: Boolean;
  AdjX: Integer;
begin
  if Button = mbLeft then
  begin
    NeedScroll := TotalTabsWidth > Width;

    // Scroll buttons
    if NeedScroll and PointInRect(FScrollLeftRect, Point(X, Y)) then
    begin
      ScrollLeft;
      Exit;
    end;
    if NeedScroll and PointInRect(FScrollRightRect, Point(X, Y)) then
    begin
      ScrollRight;
      Exit;
    end;

    AdjX := X + FScrollOffset - (ifthen (NeedScroll, 24, 0));

    CloseIdx := FindCloseAt(AdjX, Y);
    if CloseIdx >= 0 then
    begin
      CanClose := True;
      if Assigned(FOnCloseTab) then
        FOnCloseTab(Self, CloseIdx, CanClose);
      if CanClose then
        DeleteTab(CloseIdx);
    end
    else
    begin
      TabIdx := FindTabAt(AdjX, Y);
      if TabIdx >= 0 then
      begin
        SetActiveTab(TabIdx);
        // Inicia drag
        FDragTab    := TabIdx;
        FDragStartX := X;
        FDragging   := False;
      end;
    end;
  end;
  inherited;
end;

procedure TModernTabControl.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  FDragging := False;
  FDragTab  := -1;
  inherited;
end;

procedure TModernTabControl.MouseLeave;
begin
  FHoverTab         := -1;
  FHoverClose       := -1;
  FHoverScrollLeft  := False;
  FHoverScrollRight := False;
  FDragging         := False;
  FDragTab          := -1;
  HideHint;
  Invalidate;
  inherited;
end;

// --- Find ---

function TModernTabControl.FindTabAt(X, Y: Integer): Integer;
var
  i: Integer;
begin
  Result := -1;
  if not Assigned(FTabs) then Exit;
  for i := 0 to FTabs.Count - 1 do
    if PointInRect(TModernTab(FTabs[i]).TabRect, Point(X, Y)) then
    begin
      Result := i;
      Exit;
    end;
end;

function TModernTabControl.FindCloseAt(X, Y: Integer): Integer;
var
  i: Integer;
begin
  Result := -1;
  if not Assigned(FTabs) then Exit;
  for i := 0 to FTabs.Count - 1 do
    if PointInRect(TModernTab(FTabs[i]).CloseRect, Point(X, Y)) then
    begin
      Result := i;
      Exit;
    end;
end;

initialization
  {$I ModernTabControl.lrs}

end.
