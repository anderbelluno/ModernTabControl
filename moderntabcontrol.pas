unit ModernTabControl;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, Graphics, Forms, LCLType, ExtCtrls, Types,
  LResources, LCLIntf, ImgList, Menus, Math
  {$IFDEF WINDOWS}, Windows{$ENDIF};

type
  TTabCloseEvent    = procedure(Sender: TObject; TabIndex: Integer; var CanClose: Boolean) of object;
  TTabMoveEvent     = procedure(Sender: TObject; OldIndex, NewIndex: Integer) of object;

  // Posição das abas
  TModernTabPosition = (mtpTop, mtpBottom, mtpLeft, mtpRight);

  // Estilo visual da aba
  TModernTabShape = (mtsRect, mtsRounded, mtsTrapezoid, mtsChrome);

  // Quando mostrar botão X
  TModernShowClose = (mscAll, mscActive, mscHover, mscActiveAndHover, mscNone);

  // Posição do ícone
  TModernIconPosition = (mipLeft, mipRight, mipCenter);

  TModernTabControl = class;

  // ---------------------------------------------------------------------------
  //  TModernTabItem  –  item da coleção (visível no Object Inspector)
  // ---------------------------------------------------------------------------
  TModernTabItem = class(TCollectionItem)
  private
    FCaption:         string;
    FCustomCaption:   string;
    FHint:            string;
    FTabRect:         TRect;
    FCloseRect:       TRect;
    FTabColor:        TColor;
    FTabColorActive:  TColor;
    FTabColorHover:   TColor;
    FFontColor:       TColor;
    FFontStyle:       TFontStyles;
    FModified:        Boolean;
    FVisible:         Boolean;
    FPinned:          Boolean;
    FHideClose:       Boolean;
    FImageIndex:      Integer;
    function  GetDisplayCaption: string;
    procedure SetCaption(const Value: string);
    procedure SetCustomCaption(const Value: string);
    procedure SetTabColor(Value: TColor);
    procedure SetTabColorActive(Value: TColor);
    procedure SetTabColorHover(Value: TColor);
    procedure SetModified(Value: Boolean);
    procedure SetVisible(Value: Boolean);
    procedure SetFontColor(Value: TColor);
    procedure SetFontStyle(Value: TFontStyles);
    procedure SetImageIndex(Value: Integer);
    procedure SetPinned(Value: Boolean);
    procedure SetHideClose(Value: Boolean);
    procedure NotifyOwner;
  public
    constructor Create(ACollection: TCollection); override;
    property TabRect:        TRect  read FTabRect   write FTabRect;
    property CloseRect:      TRect  read FCloseRect write FCloseRect;
    property DisplayCaption: string read GetDisplayCaption;
  published
    { Caption espelha o nome da página do TNotebook. }
    property Caption:        string      read FCaption        write SetCaption;
    { CustomCaption sobrescreve a exibição sem alterar o TNotebook. }
    property CustomCaption:  string      read FCustomCaption  write SetCustomCaption;
    property Hint:           string      read FHint           write FHint;
    { Cor de fundo individual (clNone = usa cor global). }
    property TabColor:       TColor      read FTabColor       write SetTabColor       default clNone;
    property TabColorActive: TColor      read FTabColorActive write SetTabColorActive default clNone;
    property TabColorHover:  TColor      read FTabColorHover  write SetTabColorHover  default clNone;
    { Cor e estilo da fonte individual. }
    property FontColor:      TColor      read FFontColor      write SetFontColor      default clNone;
    property FontStyle:      TFontStyles read FFontStyle      write SetFontStyle      default [];
    { Indicador de modificação (ponto/círculo sobre o X). }
    property Modified:       Boolean     read FModified       write SetModified       default False;
    { Ocultar/exibir aba sem deletar. }
    property Visible:        Boolean     read FVisible        write SetVisible        default True;
    { Aba fixada – não pode ser fechada nem reordenada. }
    property Pinned:         Boolean     read FPinned         write SetPinned         default False;
    { Ocultar botão fechar individualmente. }
    property HideClose:      Boolean     read FHideClose      write SetHideClose      default False;
    { Índice no ImageList do controle pai (-1 = sem ícone). }
    property ImageIndex:     Integer     read FImageIndex     write SetImageIndex     default -1;
  end;

  // ---------------------------------------------------------------------------
  //  TModernTabCollection
  // ---------------------------------------------------------------------------
  TModernTabCollection = class(TCollection)
  private
    FOwner: TModernTabControl;
  protected
    function  GetOwner: TPersistent; override;
  public
    constructor Create(AOwner: TModernTabControl);
    function  Add: TModernTabItem;
    function  GetItem(Index: Integer): TModernTabItem;
    procedure SetItem(Index: Integer; Value: TModernTabItem);
    property  Items[Index: Integer]: TModernTabItem read GetItem write SetItem; default;
  end;

  // ---------------------------------------------------------------------------
  //  TModernTabControl
  // ---------------------------------------------------------------------------
  TModernTabControl = class(TCustomControl)
  private
    FTabs:            TModernTabCollection;
    FActiveTab:       Integer;
    FTabHeight:       Integer;
    FHoverTab:        Integer;
    FHoverClose:      Integer;
    FNoteBook:        TNotebook;
    FScrollOffset:    Integer;
    FSepWidth:        Integer;

    // Aparência
    FTabPosition:     TModernTabPosition;
    FTabShape:        TModernTabShape;
    FShowClose:       TModernShowClose;
    FIconPosition:    TModernIconPosition;
    FTrapezoidSlant:  Integer;   // largura da inclinação trapezoidal (px)
    FCornerRadius:    Integer;   // raio do arredondamento (px)
    FAccentBarSize:   Integer;   // espessura da barra de acento (px)
    FShowModifiedDot: Boolean;   // mostrar ponto de modificado
    FPinnedText:      string;    // prefixo de aba fixada

    // ImageList
    FImages:          TCustomImageList;

    // Arrastar
    FDragTab:         Integer;
    FDragStartX:      Integer;
    FDragging:        Boolean;

    // Tooltip
    FHintWindow:      THintWindow;
    FLastHintTab:     Integer;

    // Cores globais
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
    FColorScrollBtn:    TColor;
    FColorModifiedDot:  TColor;

    // Scroll
    FScrollLeftRect:   TRect;
    FScrollRightRect:  TRect;
    FHoverScrollLeft:  Boolean;
    FHoverScrollRight: Boolean;

    // Eventos
    FOnChange:   TNotifyEvent;
    FOnCloseTab: TTabCloseEvent;
    FOnMoveTab:  TTabMoveEvent;
    FOnAddTab:   TNotifyEvent;

    // --- Getters/Setters internos ---
    function  GetTabCount: Integer;
    procedure SetActiveTab(Value: Integer);
    procedure SetNoteBook(Value: TNotebook);
    procedure SetTabHeight(Value: Integer);
    procedure SetTabItems(Value: TModernTabCollection);
    procedure SetTabPosition(Value: TModernTabPosition);
    procedure SetTabShape(Value: TModernTabShape);
    procedure SetShowClose(Value: TModernShowClose);
    procedure SetTrapezoidSlant(Value: Integer);
    procedure SetCornerRadius(Value: Integer);
    procedure SetAccentBarSize(Value: Integer);
    procedure SetImages(Value: TCustomImageList);
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
    procedure SetShowModifiedDot(Value: Boolean);
    procedure SetPinnedText(const Value: string);

    // --- Helpers internos ---
    procedure RecalcTabRects;
    function  FindTabAt(X, Y: Integer): Integer;
    function  FindCloseAt(X, Y: Integer): Integer;
    procedure SyncFromNoteBook;
    procedure ScrollLeft;
    procedure ScrollRight;
    function  TotalTabsWidth: Integer;
    function  VisibleWidth: Integer;
    procedure ShowTabHint(TabIndex: Integer);
    procedure HideHint;
    procedure MoveTab(OldIndex, NewIndex: Integer);
    function  IsCloseVisible(TabIndex: Integer): Boolean;

    // --- Pintura ---
    procedure PaintTabShape(ACanvas: TCanvas; ARect: TRect; ABgColor: TColor; AActive: Boolean);
    procedure PaintRoundedCorners(ACanvas: TCanvas; ARect: TRect; ABgColor, ATabColor: TColor);
    procedure PaintTrapezoidTab(ACanvas: TCanvas; ARect: TRect; ABgColor: TColor; AActive: Boolean);
    procedure PaintCloseButton(ACanvas: TCanvas; ACloseRect: TRect; AColor: TColor; AModified: Boolean);
    procedure PaintScrollButtons(ACanvas: TCanvas; NeedScroll: Boolean; ScrollAreaW: Integer);
    procedure PaintChromeTab(ACanvas: TCanvas; ARect: TRect; ABgColor: TColor; AActive: Boolean);
    procedure PaintIcon(ACanvas: TCanvas; ATabRect: TRect; AImageIndex: Integer; var ATextLeft: Integer);

    // Mapeamento de coordenadas para posição Left/Right
    function  IsVertical: Boolean;
    function  AdjustedX(X, Y: Integer): Integer;
    function  AdjustedY(X, Y: Integer): Integer;

  protected
    procedure Paint; override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseLeave; override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure Resize; override;
    procedure Loaded; override;

  public
    constructor Create(AOwner: TComponent); override;
    destructor  Destroy; override;

    function  AddTab(const ACaption: string; const AHint: string = ''): Integer;
    procedure DeleteTab(Index: Integer);
    procedure Clear;
    procedure SetTabCaption(Index: Integer; const ACaption: string);
    procedure SetTabHint(Index: Integer; const AHint: string);
    procedure ShowTab(Index: Integer);
    procedure HideTab(Index: Integer);

    property TabCount: Integer read GetTabCount;

  published
    property NoteBook:  TNotebook            read FNoteBook    write SetNoteBook;
    property TabItems:  TModernTabCollection read FTabs        write SetTabItems;
    property Images:    TCustomImageList     read FImages      write SetImages;

    property ActiveTab:       Integer              read FActiveTab      write SetActiveTab;
    property TabHeight:       Integer              read FTabHeight      write SetTabHeight      default 36;
    property SepWidth:        Integer              read FSepWidth       write SetSepWidth       default 1;
    property TabPosition:     TModernTabPosition   read FTabPosition    write SetTabPosition    default mtpTop;
    property TabShape:        TModernTabShape      read FTabShape       write SetTabShape       default mtsRect;
    property ShowClose:       TModernShowClose     read FShowClose      write SetShowClose      default mscAll;
    property IconPosition:    TModernIconPosition  read FIconPosition   write FIconPosition     default mipLeft;
    property TrapezoidSlant:  Integer              read FTrapezoidSlant write SetTrapezoidSlant default 8;
    property CornerRadius:    Integer              read FCornerRadius   write SetCornerRadius   default 4;
    property AccentBarSize:   Integer              read FAccentBarSize  write SetAccentBarSize  default 3;
    property ShowModifiedDot: Boolean              read FShowModifiedDot write SetShowModifiedDot default True;
    property PinnedText:      string               read FPinnedText     write SetPinnedText;

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
    property ColorModifiedDot:  TColor read FColorModifiedDot  write FColorModifiedDot;

    property Align;
    property Anchors;
    property Enabled;
    property Font;
    property Height;
    property Width;
    property Visible;
    property ShowHint;
    property ParentShowHint;

    property OnChange:   TNotifyEvent   read FOnChange   write FOnChange;
    property OnCloseTab: TTabCloseEvent read FOnCloseTab write FOnCloseTab;
    property OnMoveTab:  TTabMoveEvent  read FOnMoveTab  write FOnMoveTab;
    property OnAddTab:   TNotifyEvent   read FOnAddTab   write FOnAddTab;
  end;

procedure Register;

// =============================================================================
implementation
// =============================================================================

procedure Register;
begin
  RegisterComponents('Modern', [TModernTabControl]);
end;

function PointInRect(const R: TRect; const P: TPoint): Boolean; inline;
begin
  Result := (P.X >= R.Left) and (P.X < R.Right) and
            (P.Y >= R.Top)  and (P.Y < R.Bottom);
end;

// =============================================================================
//  TModernTabItem
// =============================================================================

constructor TModernTabItem.Create(ACollection: TCollection);
begin
  inherited Create(ACollection);
  FTabColor       := clNone;
  FTabColorActive := clNone;
  FTabColorHover  := clNone;
  FFontColor      := clNone;
  FFontStyle      := [];
  FModified       := False;
  FVisible        := True;
  FPinned         := False;
  FHideClose      := False;
  FImageIndex     := -1;
end;

function TModernTabItem.GetDisplayCaption: string;
begin
  if FCustomCaption <> '' then
    Result := FCustomCaption
  else
    Result := FCaption;
end;

procedure TModernTabItem.NotifyOwner;
var
  Ctrl: TModernTabControl;
begin
  if not Assigned(Collection) then Exit;
  Ctrl := TModernTabCollection(Collection).FOwner;
  if not Assigned(Ctrl) then Exit;
  Ctrl.RecalcTabRects;
  Ctrl.Invalidate;
end;

procedure TModernTabItem.SetCaption(const Value: string);
begin
  if FCaption = Value then Exit;
  FCaption := Value;
  NotifyOwner;
end;

procedure TModernTabItem.SetCustomCaption(const Value: string);
begin
  if FCustomCaption = Value then Exit;
  FCustomCaption := Value;
  NotifyOwner;
end;

procedure TModernTabItem.SetTabColor(Value: TColor);
begin if FTabColor = Value then Exit; FTabColor := Value; NotifyOwner; end;

procedure TModernTabItem.SetTabColorActive(Value: TColor);
begin if FTabColorActive = Value then Exit; FTabColorActive := Value; NotifyOwner; end;

procedure TModernTabItem.SetTabColorHover(Value: TColor);
begin if FTabColorHover = Value then Exit; FTabColorHover := Value; NotifyOwner; end;

procedure TModernTabItem.SetModified(Value: Boolean);
begin if FModified = Value then Exit; FModified := Value; NotifyOwner; end;

procedure TModernTabItem.SetVisible(Value: Boolean);
begin if FVisible = Value then Exit; FVisible := Value; NotifyOwner; end;

procedure TModernTabItem.SetFontColor(Value: TColor);
begin if FFontColor = Value then Exit; FFontColor := Value; NotifyOwner; end;

procedure TModernTabItem.SetFontStyle(Value: TFontStyles);
begin if FFontStyle = Value then Exit; FFontStyle := Value; NotifyOwner; end;

procedure TModernTabItem.SetImageIndex(Value: Integer);
begin if FImageIndex = Value then Exit; FImageIndex := Value; NotifyOwner; end;

procedure TModernTabItem.SetPinned(Value: Boolean);
begin if FPinned = Value then Exit; FPinned := Value; NotifyOwner; end;

procedure TModernTabItem.SetHideClose(Value: Boolean);
begin if FHideClose = Value then Exit; FHideClose := Value; NotifyOwner; end;

// =============================================================================
//  TModernTabCollection
// =============================================================================

constructor TModernTabCollection.Create(AOwner: TModernTabControl);
begin
  inherited Create(TModernTabItem);
  FOwner := AOwner;
end;

function TModernTabCollection.GetOwner: TPersistent;
begin
  Result := FOwner;
end;

function TModernTabCollection.Add: TModernTabItem;
begin
  Result := TModernTabItem(inherited Add);
end;

function TModernTabCollection.GetItem(Index: Integer): TModernTabItem;
begin
  Result := TModernTabItem(inherited GetItem(Index));
end;

procedure TModernTabCollection.SetItem(Index: Integer; Value: TModernTabItem);
begin
  inherited SetItem(Index, Value);
end;

// =============================================================================
//  TModernTabControl
// =============================================================================

constructor TModernTabControl.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  FTabs             := TModernTabCollection.Create(Self);
  FNoteBook         := nil;
  FActiveTab        := -1;
  FHoverTab         := -1;
  FHoverClose       := -1;
  FScrollOffset     := 0;
  FDragTab          := -1;
  FDragging         := False;
  FLastHintTab      := -1;
  FHoverScrollLeft  := False;
  FHoverScrollRight := False;

  FTabHeight        := 36;
  FSepWidth         := 1;
  FTabPosition      := mtpTop;
  FTabShape         := mtsRect;
  FShowClose        := mscAll;
  FIconPosition     := mipLeft;
  FTrapezoidSlant   := 8;
  FCornerRadius     := 4;
  FAccentBarSize    := 3;
  FShowModifiedDot  := True;
  FPinnedText       := '● ';

  Height := FTabHeight;

  // Paleta Dark padrão
  FColorBackground   := $00202020;
  FColorTabInactive  := $002D2D2D;
  FColorTabHover     := $00383838;
  FColorTabActive    := $00424242;
  FColorAccent       := $00CF6E27;
  FColorTextInactive := $00AAAAAA;
  FColorTextActive   := $00FFFFFF;
  FColorClose        := $00777777;
  FColorCloseHover   := $000055FF;
  FColorSeparator    := $00444444;
  FColorScrollBtn    := $00383838;
  FColorModifiedDot  := $0040A0FF;

  ControlStyle := ControlStyle + [csOpaque];
  FHintWindow  := THintWindow.Create(Self);
end;

destructor TModernTabControl.Destroy;
begin
  HideHint;
  FHintWindow.Free;
  FreeAndNil(FTabs);
  inherited Destroy;
end;

procedure TModernTabControl.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if Operation = opRemove then
  begin
    if AComponent = FNoteBook then FNoteBook := nil;
    if AComponent = FImages   then FImages   := nil;
  end;
end;

// --- Setters simples ----------------------------------------------------------

procedure TModernTabControl.SetTabHeight(Value: Integer);
begin
  if Value = FTabHeight then Exit;
  FTabHeight := Value;
  if not IsVertical then Height := FTabHeight
  else                   Width  := FTabHeight;
  RecalcTabRects;
  Invalidate;
end;

procedure TModernTabControl.SetSepWidth(Value: Integer);
begin if Value = FSepWidth then Exit; FSepWidth := Value; RecalcTabRects; Invalidate; end;

procedure TModernTabControl.SetTabPosition(Value: TModernTabPosition);
begin if Value = FTabPosition then Exit; FTabPosition := Value; RecalcTabRects; Invalidate; end;

procedure TModernTabControl.SetTabShape(Value: TModernTabShape);
begin if Value = FTabShape then Exit; FTabShape := Value; Invalidate; end;

procedure TModernTabControl.SetShowClose(Value: TModernShowClose);
begin if Value = FShowClose then Exit; FShowClose := Value; Invalidate; end;

procedure TModernTabControl.SetTrapezoidSlant(Value: Integer);
begin if Value = FTrapezoidSlant then Exit; FTrapezoidSlant := Max(0, Value); RecalcTabRects; Invalidate; end;

procedure TModernTabControl.SetCornerRadius(Value: Integer);
begin if Value = FCornerRadius then Exit; FCornerRadius := Max(0, Value); Invalidate; end;

procedure TModernTabControl.SetAccentBarSize(Value: Integer);
begin if Value = FAccentBarSize then Exit; FAccentBarSize := Max(0, Value); Invalidate; end;

procedure TModernTabControl.SetImages(Value: TCustomImageList);
begin
  if FImages = Value then Exit;
  if Assigned(FImages) then FImages.RemoveFreeNotification(Self);
  FImages := Value;
  if Assigned(FImages) then FImages.FreeNotification(Self);
  RecalcTabRects;
  Invalidate;
end;

procedure TModernTabControl.SetShowModifiedDot(Value: Boolean);
begin if Value = FShowModifiedDot then Exit; FShowModifiedDot := Value; Invalidate; end;

procedure TModernTabControl.SetPinnedText(const Value: string);
begin if Value = FPinnedText then Exit; FPinnedText := Value; RecalcTabRects; Invalidate; end;

procedure TModernTabControl.SetTabItems(Value: TModernTabCollection);
begin
  FTabs.Assign(Value);
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

// --- Notebook -----------------------------------------------------------------

procedure TModernTabControl.SetNoteBook(Value: TNotebook);
begin
  if FNoteBook = Value then Exit;
  if Assigned(FNoteBook) then
    FNoteBook.RemoveFreeNotification(Self);
  FNoteBook := Value;
  if not Assigned(FNoteBook) then Exit;
  FNoteBook.FreeNotification(Self);
  if not (csLoading in ComponentState) then
    SyncFromNoteBook;
end;

procedure TModernTabControl.SyncFromNoteBook;
var
  i:   Integer;
  Tab: TModernTabItem;
begin
  if not Assigned(FTabs) then Exit;
  if not Assigned(FNoteBook) then Exit;
  if not Assigned(FNoteBook.Pages) then Exit;

  // Sincroniza a quantidade de abas sem limpar a coleção
  while FTabs.Count > FNoteBook.Pages.Count do
    FTabs.Delete(FTabs.Count - 1);

  while FTabs.Count < FNoteBook.Pages.Count do
    FTabs.Add;

  // Atualiza apenas os captions, preservando cores, ícones e outros estados
  for i := 0 to FNoteBook.Pages.Count - 1 do
  begin
    Tab := FTabs[i];
    Tab.FCaption := FNoteBook.Pages[i];
  end;

  if FTabs.Count > 0 then
  begin
    if (FActiveTab < 0) or (FActiveTab >= FTabs.Count) then
      FActiveTab := FNoteBook.PageIndex;
  end
  else
    FActiveTab := -1;

  FScrollOffset := 0;
  RecalcTabRects;
  Invalidate;
end;

procedure TModernTabControl.SetActiveTab(Value: Integer);
var
  i: Integer;
begin
  if Value = FActiveTab then Exit;
  // Ignorar abas ocultas
  if (Value >= 0) and (Value < FTabs.Count) then
    if not FTabs[Value].FVisible then Exit;
  if (Value < 0) or (Value >= FTabs.Count) then Exit;
  FActiveTab := Value;
  if Assigned(FNoteBook) then
    FNoteBook.PageIndex := FActiveTab;
  Invalidate;
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

function TModernTabControl.GetTabCount: Integer;
begin
  Result := FTabs.Count;
end;

// --- Tabs públicos ------------------------------------------------------------

function TModernTabControl.AddTab(const ACaption: string; const AHint: string = ''): Integer;
var
  Tab: TModernTabItem;
begin
  Tab := FTabs.Add;
  Tab.FCaption := ACaption;
  Tab.FHint    := AHint;
  Result := FTabs.Count - 1;

  if Assigned(FNoteBook) then
  begin
    FNoteBook.Pages.Add(ACaption);
    FNoteBook.PageIndex := Result;
  end;

  if FActiveTab = -1 then
    FActiveTab := 0;

  RecalcTabRects;
  Invalidate;

  if Assigned(FOnAddTab) then
    FOnAddTab(Self);
end;

procedure TModernTabControl.SetTabCaption(Index: Integer; const ACaption: string);
begin
  if (Index < 0) or (Index >= FTabs.Count) then Exit;
  FTabs[Index].CustomCaption := ACaption;
end;

procedure TModernTabControl.SetTabHint(Index: Integer; const AHint: string);
begin
  if (Index < 0) or (Index >= FTabs.Count) then Exit;
  FTabs[Index].FHint := AHint;
end;

procedure TModernTabControl.ShowTab(Index: Integer);
begin
  if (Index < 0) or (Index >= FTabs.Count) then Exit;
  FTabs[Index].FVisible := True;
  RecalcTabRects;
  Invalidate;
end;

procedure TModernTabControl.HideTab(Index: Integer);
begin
  if (Index < 0) or (Index >= FTabs.Count) then Exit;
  FTabs[Index].FVisible := False;
  if FActiveTab = Index then
  begin
    // Ativa a próxima aba visível
    if Index + 1 < FTabs.Count then SetActiveTab(Index + 1)
    else if Index > 0           then SetActiveTab(Index - 1);
  end;
  RecalcTabRects;
  Invalidate;
end;

procedure TModernTabControl.DeleteTab(Index: Integer);
begin
  if (Index < 0) or (Index >= FTabs.Count) then Exit;

  FTabs.Delete(Index);

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
begin
  if not Assigned(FTabs) then Exit;
  FTabs.Clear;
  FActiveTab    := -1;
  FScrollOffset := 0;
  if Assigned(FNoteBook) then
    FNoteBook.Pages.Clear;
  Invalidate;
end;

procedure TModernTabControl.MoveTab(OldIndex, NewIndex: Integer);
var
  SaveCaption, SaveCustom, SaveHint: string;
  SaveColor, SaveColorA, SaveColorH, SaveFontColor: TColor;
  SaveFontStyle: TFontStyles;
  SaveMod, SaveVis, SavePin, SaveHide: Boolean;
  SaveImgIdx: Integer;
  PageText: string;
  Step, i: Integer;
begin
  if OldIndex = NewIndex then Exit;
  if (OldIndex < 0) or (OldIndex >= FTabs.Count) then Exit;
  if (NewIndex < 0) or (NewIndex >= FTabs.Count) then Exit;
  // Aba fixada não pode ser reordenada
  if FTabs[OldIndex].FPinned then Exit;

  SaveCaption    := FTabs[OldIndex].FCaption;
  SaveCustom     := FTabs[OldIndex].FCustomCaption;
  SaveHint       := FTabs[OldIndex].FHint;
  SaveColor      := FTabs[OldIndex].FTabColor;
  SaveColorA     := FTabs[OldIndex].FTabColorActive;
  SaveColorH     := FTabs[OldIndex].FTabColorHover;
  SaveFontColor  := FTabs[OldIndex].FFontColor;
  SaveFontStyle  := FTabs[OldIndex].FFontStyle;
  SaveMod        := FTabs[OldIndex].FModified;
  SaveVis        := FTabs[OldIndex].FVisible;
  SavePin        := FTabs[OldIndex].FPinned;
  SaveHide       := FTabs[OldIndex].FHideClose;
  SaveImgIdx     := FTabs[OldIndex].FImageIndex;

  if OldIndex < NewIndex then Step := 1 else Step := -1;

  i := OldIndex;
  while i <> NewIndex do
  begin
    FTabs[i].FCaption       := FTabs[i + Step].FCaption;
    FTabs[i].FCustomCaption := FTabs[i + Step].FCustomCaption;
    FTabs[i].FHint          := FTabs[i + Step].FHint;
    FTabs[i].FTabColor      := FTabs[i + Step].FTabColor;
    FTabs[i].FTabColorActive:= FTabs[i + Step].FTabColorActive;
    FTabs[i].FTabColorHover := FTabs[i + Step].FTabColorHover;
    FTabs[i].FFontColor     := FTabs[i + Step].FFontColor;
    FTabs[i].FFontStyle     := FTabs[i + Step].FFontStyle;
    FTabs[i].FModified      := FTabs[i + Step].FModified;
    FTabs[i].FVisible       := FTabs[i + Step].FVisible;
    FTabs[i].FPinned        := FTabs[i + Step].FPinned;
    FTabs[i].FHideClose     := FTabs[i + Step].FHideClose;
    FTabs[i].FImageIndex    := FTabs[i + Step].FImageIndex;
    Inc(i, Step);
  end;

  FTabs[NewIndex].FCaption       := SaveCaption;
  FTabs[NewIndex].FCustomCaption := SaveCustom;
  FTabs[NewIndex].FHint          := SaveHint;
  FTabs[NewIndex].FTabColor      := SaveColor;
  FTabs[NewIndex].FTabColorActive:= SaveColorA;
  FTabs[NewIndex].FTabColorHover := SaveColorH;
  FTabs[NewIndex].FFontColor     := SaveFontColor;
  FTabs[NewIndex].FFontStyle     := SaveFontStyle;
  FTabs[NewIndex].FModified      := SaveMod;
  FTabs[NewIndex].FVisible       := SaveVis;
  FTabs[NewIndex].FPinned        := SavePin;
  FTabs[NewIndex].FHideClose     := SaveHide;
  FTabs[NewIndex].FImageIndex    := SaveImgIdx;

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

// --- Helpers de layout --------------------------------------------------------

function TModernTabControl.IsVertical: Boolean;
begin
  Result := FTabPosition in [mtpLeft, mtpRight];
end;

{ Para abas verticais rotacionamos o conceito: X vira Y e vice-versa }
function TModernTabControl.AdjustedX(X, Y: Integer): Integer;
begin
  if IsVertical then Result := Y else Result := X;
end;

function TModernTabControl.AdjustedY(X, Y: Integer): Integer;
begin
  if IsVertical then Result := X else Result := Y;
end;

function TModernTabControl.IsCloseVisible(TabIndex: Integer): Boolean;
var
  Tab: TModernTabItem;
begin
  Result := False;
  if (TabIndex < 0) or (TabIndex >= FTabs.Count) then Exit;
  Tab := FTabs[TabIndex];
  if Tab.FHideClose or Tab.FPinned then Exit;
  case FShowClose of
    mscAll:              Result := True;
    mscActive:           Result := TabIndex = FActiveTab;
    mscHover:            Result := TabIndex = FHoverTab;
    mscActiveAndHover:   Result := (TabIndex = FActiveTab) or (TabIndex = FHoverTab);
    mscNone:             Result := False;
  end;
end;

// --- Recalc -------------------------------------------------------------------

procedure TModernTabControl.RecalcTabRects;
const
  TabPadL   = 12;
  TabPadR   = 8;
  CloseSize = 14;
  CloseGap  = 6;
  IconGap   = 4;
var
  i, Pos, TabW, ImgW: Integer;
  Tab: TModernTabItem;
  Cap: string;
begin
  if not Assigned(FTabs) then Exit;
  if not HandleAllocated then Exit;

  Pos := 0;
  Canvas.Font.Assign(Font);

  ImgW := 0;
  if Assigned(FImages) then
    ImgW := FImages.Width + IconGap;

  for i := 0 to FTabs.Count - 1 do
  begin
    Tab := FTabs[i];

    if not Tab.FVisible then
    begin
      Tab.TabRect   := Rect(0, 0, 0, 0);
      Tab.CloseRect := Rect(0, 0, 0, 0);
      Continue;
    end;

    // Caption com prefixo de pinned
    Canvas.Font.Style := Tab.FFontStyle;
    Cap := Tab.DisplayCaption;
    if Tab.FPinned and (FPinnedText <> '') then
      Cap := FPinnedText + Cap;

    TabW := TabPadL + ImgW + Canvas.TextWidth(Cap) + TabPadR;
    // Espaço extra para o botão X (sempre reserva largura, visibilidade é no Paint)
    if not Tab.FHideClose and not Tab.FPinned then
      TabW := TabW + CloseSize + CloseGap;
    // Espaço do trapézio ou chrome
    if FTabShape in [mtsTrapezoid, mtsChrome] then
      TabW := TabW + FTrapezoidSlant * 2;

    if not IsVertical then
    begin
      Tab.TabRect := Rect(Pos, 0, Pos + TabW, FTabHeight);
      Tab.CloseRect := Rect(
        Tab.TabRect.Right - CloseSize - CloseGap,
        (FTabHeight - CloseSize) div 2,
        Tab.TabRect.Right - CloseGap,
        (FTabHeight - CloseSize) div 2 + CloseSize
      );
    end
    else
    begin
      // Vertical: X = 0..FTabHeight (largura), Y = Pos..Pos+TabW (comprimento)
      Tab.TabRect := Rect(0, Pos, FTabHeight, Pos + TabW);
      Tab.CloseRect := Rect(
        (FTabHeight - CloseSize) div 2,
        Tab.TabRect.Bottom - CloseSize - CloseGap,
        (FTabHeight - CloseSize) div 2 + CloseSize,
        Tab.TabRect.Bottom - CloseGap
      );
    end;

    Pos := Pos + TabW;
    if FSepWidth > 0 then
      Pos := Pos + FSepWidth;
  end;
end;

procedure TModernTabControl.Resize;
begin
  inherited Resize;
  RecalcTabRects;
  Invalidate;
end;

procedure TModernTabControl.Loaded;
begin
  inherited Loaded;
  if Assigned(FNoteBook) then
    SyncFromNoteBook;
end;

// --- Scroll -------------------------------------------------------------------

function TModernTabControl.TotalTabsWidth: Integer;
var
  i: Integer;
  Tab: TModernTabItem;
begin
  Result := 0;
  if not Assigned(FTabs) then Exit;
  for i := 0 to FTabs.Count - 1 do
  begin
    Tab := FTabs[i];
    if not Tab.FVisible then Continue;
    if IsVertical then
      Result := Result + (Tab.TabRect.Bottom - Tab.TabRect.Top)
    else
      Result := Result + (Tab.TabRect.Right  - Tab.TabRect.Left);
  end;
end;

function TModernTabControl.VisibleWidth: Integer;
begin
  if IsVertical then Result := Height else Result := Width;
  if TotalTabsWidth > Result then
    Result := Result - 48;
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

// --- Hint ---------------------------------------------------------------------

procedure TModernTabControl.ShowTabHint(TabIndex: Integer);
var
  Tab: TModernTabItem;
  R:   TRect;
  P:   TPoint;
begin
  if (TabIndex < 0) or (TabIndex >= FTabs.Count) then begin HideHint; Exit; end;
  Tab := FTabs[TabIndex];
  if Tab.FHint = '' then begin HideHint; Exit; end;
  if TabIndex = FLastHintTab then Exit;
  FLastHintTab := TabIndex;
  P := ClientToScreen(Point(Tab.TabRect.Left - FScrollOffset, FTabHeight + 2));
  R := FHintWindow.CalcHintRect(300, Tab.FHint, nil);
  OffsetRect(R, P.X, P.Y);
  FHintWindow.ActivateHint(R, Tab.FHint);
end;

procedure TModernTabControl.HideHint;
begin
  FLastHintTab := -1;
  if Assigned(FHintWindow) then FHintWindow.Visible := False;
end;

// =============================================================================
//  Pintura
// =============================================================================

{ Não usado diretamente — lógica de arredondamento está em PaintTabShape }
procedure TModernTabControl.PaintRoundedCorners(ACanvas: TCanvas; ARect: TRect;
  ABgColor, ATabColor: TColor);
begin
  // Reservado para uso futuro
end;

{ Pinta o fundo de uma aba retangular simples }
procedure TModernTabControl.PaintTabShape(ACanvas: TCanvas; ARect: TRect;
  ABgColor: TColor; AActive: Boolean);
begin
  ACanvas.Brush.Color := ABgColor;
  ACanvas.Pen.Color   := ABgColor;

  case FTabShape of
    mtsRect:
    begin
      ACanvas.FillRect(ARect);
    end;

    mtsRounded:
    begin
      ACanvas.Brush.Color := ABgColor;
      ACanvas.Pen.Color   := ABgColor;
      if FCornerRadius <= 0 then
      begin
        ACanvas.FillRect(ARect);
      end
      else
      begin
        // Para manter apenas alguns cantos arredondados, estendemos o retângulo
        // além da área visível no lado que deve permanecer reto.
        case FTabPosition of
          mtpTop:
            ACanvas.RoundRect(ARect.Left, ARect.Top, ARect.Right, ARect.Bottom + FCornerRadius, FCornerRadius, FCornerRadius);
          mtpBottom:
            ACanvas.RoundRect(ARect.Left, ARect.Top - FCornerRadius, ARect.Right, ARect.Bottom, FCornerRadius, FCornerRadius);
          mtpLeft:
            ACanvas.RoundRect(ARect.Left, ARect.Top, ARect.Right + FCornerRadius, ARect.Bottom, FCornerRadius, FCornerRadius);
          mtpRight:
            ACanvas.RoundRect(ARect.Left - FCornerRadius, ARect.Top, ARect.Right, ARect.Bottom, FCornerRadius, FCornerRadius);
        end;
      end;
    end;

    mtsTrapezoid:
      PaintTrapezoidTab(ACanvas, ARect, ABgColor, AActive);

    mtsChrome:
      PaintChromeTab(ACanvas, ARect, ABgColor, AActive);
  end;
end;

procedure TModernTabControl.PaintChromeTab(ACanvas: TCanvas; ARect: TRect;
  ABgColor: TColor; AActive: Boolean);
var
  S, R: Integer;
begin
  S := FTrapezoidSlant;
  R := FCornerRadius;
  if R < 2 then R := 4; // Valor mínimo para o efeito chrome ficar visível

  ACanvas.Brush.Color := ABgColor;
  ACanvas.Pen.Color   := ABgColor;

  if not IsVertical then
  begin
    // Corpo principal (trapézio arredondado)
    // Usamos RoundRect estendido para baixo para manter a base reta antes das curvas invertidas
    ACanvas.RoundRect(ARect.Left + 1, ARect.Top, ARect.Right - 1, ARect.Bottom + R, R, R);

    // Curvas invertidas na base (Left)
    ACanvas.Brush.Color := FColorBackground;
    ACanvas.FillRect(Rect(ARect.Left, ARect.Bottom - R, ARect.Left + R, ARect.Bottom));
    ACanvas.Brush.Color := ABgColor;
    ACanvas.Ellipse(ARect.Left - R, ARect.Bottom - R * 2, ARect.Left + R, ARect.Bottom);

    // Curvas invertidas na base (Right)
    ACanvas.Brush.Color := FColorBackground;
    ACanvas.FillRect(Rect(ARect.Right - R, ARect.Bottom - R, ARect.Right, ARect.Bottom));
    ACanvas.Brush.Color := ABgColor;
    ACanvas.Ellipse(ARect.Right - R, ARect.Bottom - R * 2, ARect.Right + R, ARect.Bottom);
  end
  else
  begin
    // Para vertical simplificamos para o trapézio por enquanto ou um rounded estendido
    PaintTrapezoidTab(ACanvas, ARect, ABgColor, AActive);
  end;
end;

{ Pinta uma aba no formato trapézio (estilo Chrome/navegador) }
procedure TModernTabControl.PaintTrapezoidTab(ACanvas: TCanvas; ARect: TRect;
  ABgColor: TColor; AActive: Boolean);
var
  Pts: array[0..3] of TPoint;
  S: Integer;
begin
  S := FTrapezoidSlant;
  ACanvas.Brush.Color := ABgColor;
  ACanvas.Pen.Color   := ABgColor;

  case FTabPosition of
    mtpTop:
    begin
      Pts[0] := Point(ARect.Left,          ARect.Bottom);
      Pts[1] := Point(ARect.Left  + S,     ARect.Top);
      Pts[2] := Point(ARect.Right - S,     ARect.Top);
      Pts[3] := Point(ARect.Right,         ARect.Bottom);
    end;
    mtpBottom:
    begin
      Pts[0] := Point(ARect.Left,          ARect.Top);
      Pts[1] := Point(ARect.Left  + S,     ARect.Bottom);
      Pts[2] := Point(ARect.Right - S,     ARect.Bottom);
      Pts[3] := Point(ARect.Right,         ARect.Top);
    end;
    mtpLeft:
    begin
      Pts[0] := Point(ARect.Right,         ARect.Top);
      Pts[1] := Point(ARect.Left,          ARect.Top + S);
      Pts[2] := Point(ARect.Left,          ARect.Bottom - S);
      Pts[3] := Point(ARect.Right,         ARect.Bottom);
    end;
    mtpRight:
    begin
      Pts[0] := Point(ARect.Left,          ARect.Top);
      Pts[1] := Point(ARect.Right,         ARect.Top + S);
      Pts[2] := Point(ARect.Right,         ARect.Bottom - S);
      Pts[3] := Point(ARect.Left,          ARect.Bottom);
    end;
  end;

  ACanvas.Polygon(Pts);
end;

{ Pinta ícone de uma aba e ajusta a posição inicial do texto }
procedure TModernTabControl.PaintIcon(ACanvas: TCanvas; ATabRect: TRect;
  AImageIndex: Integer; var ATextLeft: Integer);
var
  IW, IH, IY, IX: Integer;
begin
  if not Assigned(FImages) then Exit;
  if (AImageIndex < 0) or (AImageIndex >= FImages.Count) then Exit;

  IW := FImages.Width;
  IH := FImages.Height;
  IY := ATabRect.Top + (FTabHeight - IH) div 2;

  case FIconPosition of
    mipLeft:
    begin
      IX := ATextLeft;
      FImages.Draw(ACanvas, IX, IY, AImageIndex);
      ATextLeft := ATextLeft + IW + 4;
    end;
    mipRight:
    begin
      IX := ATabRect.Right - IW - 8;
      FImages.Draw(ACanvas, IX, IY, AImageIndex);
      // Não altera ATextLeft
    end;
    mipCenter:
    begin
      IX := ATabRect.Left + (ATabRect.Right - ATabRect.Left - IW) div 2;
      FImages.Draw(ACanvas, IX, IY, AImageIndex);
    end;
  end;
end;

{ Pinta o botão X (com indicador de modificado se necessário) }
procedure TModernTabControl.PaintCloseButton(ACanvas: TCanvas; ACloseRect: TRect;
  AColor: TColor; AModified: Boolean);
var
  cx, cy, DotR: Integer;
begin
  cx := (ACloseRect.Left + ACloseRect.Right)  div 2;
  cy := (ACloseRect.Top  + ACloseRect.Bottom) div 2;

  if AModified and FShowModifiedDot then
  begin
    // Mostra ponto colorido ao invés do X quando modificado
    DotR := 4;
    ACanvas.Brush.Color := FColorModifiedDot;
    ACanvas.Pen.Color   := FColorModifiedDot;
    ACanvas.Ellipse(cx - DotR, cy - DotR, cx + DotR, cy + DotR);
  end
  else
  begin
    ACanvas.Pen.Color := AColor;
    ACanvas.Pen.Width := 2;
    ACanvas.MoveTo(cx - 4, cy - 4); ACanvas.LineTo(cx + 5, cy + 5);
    ACanvas.MoveTo(cx + 4, cy - 4); ACanvas.LineTo(cx - 5, cy + 5);
    ACanvas.Pen.Width := 1;
  end;
end;

{ Pinta os botões de scroll (esquerda/direita ou cima/baixo) }
procedure TModernTabControl.PaintScrollButtons(ACanvas: TCanvas; NeedScroll: Boolean;
  ScrollAreaW: Integer);
const
  ScrollBtnW = 24;
var
  cx, cy: Integer;
begin
  if not NeedScroll then
  begin
    FScrollLeftRect  := Rect(0, 0, 0, 0);
    FScrollRightRect := Rect(0, 0, 0, 0);
    Exit;
  end;

  if not IsVertical then
  begin
    FScrollLeftRect  := Rect(0, 0, ScrollBtnW, FTabHeight);
    FScrollRightRect := Rect(Width - ScrollBtnW, 0, Width, FTabHeight);
  end
  else
  begin
    FScrollLeftRect  := Rect(0, 0, FTabHeight, ScrollBtnW);
    FScrollRightRect := Rect(0, Height - ScrollBtnW, FTabHeight, Height);
  end;

  // Botão esquerdo/cima
  ACanvas.Brush.Color := FColorScrollBtn;
  ACanvas.Pen.Color   := FColorScrollBtn;
  ACanvas.FillRect(FScrollLeftRect);
  ACanvas.Pen.Color := FColorTextActive;
  ACanvas.Pen.Width := 2;
  cx := FScrollLeftRect.Left + (FScrollLeftRect.Right - FScrollLeftRect.Left) div 2;
  cy := FScrollLeftRect.Top  + (FScrollLeftRect.Bottom - FScrollLeftRect.Top) div 2;
  if not IsVertical then
  begin
    ACanvas.MoveTo(cx + 5, cy - 5); ACanvas.LineTo(cx - 3, cy);
    ACanvas.MoveTo(cx - 3, cy);     ACanvas.LineTo(cx + 5, cy + 5);
  end
  else
  begin
    ACanvas.MoveTo(cx - 5, cy + 5); ACanvas.LineTo(cx, cy - 3);
    ACanvas.MoveTo(cx, cy - 3);     ACanvas.LineTo(cx + 5, cy + 5);
  end;

  // Botão direito/baixo
  ACanvas.Brush.Color := FColorScrollBtn;
  ACanvas.Pen.Color   := FColorScrollBtn;
  ACanvas.FillRect(FScrollRightRect);
  ACanvas.Pen.Color := FColorTextActive;
  cx := FScrollRightRect.Left + (FScrollRightRect.Right - FScrollRightRect.Left) div 2;
  cy := FScrollRightRect.Top  + (FScrollRightRect.Bottom - FScrollRightRect.Top) div 2;
  if not IsVertical then
  begin
    ACanvas.MoveTo(cx - 5, cy - 5); ACanvas.LineTo(cx + 3, cy);
    ACanvas.MoveTo(cx + 3, cy);     ACanvas.LineTo(cx - 5, cy + 5);
  end
  else
  begin
    ACanvas.MoveTo(cx - 5, cy - 5); ACanvas.LineTo(cx, cy + 3);
    ACanvas.MoveTo(cx, cy + 3);     ACanvas.LineTo(cx + 5, cy - 5);
  end;
  ACanvas.Pen.Width := 1;
end;

// --- Paint principal ----------------------------------------------------------

procedure TModernTabControl.Paint;
const
  ScrollBtnW = 24;
var
  i, OffX, ScrollAreaW: Integer;
  Tab: TModernTabItem;
  IsActive, IsHover: Boolean;
  BgColor, TxtColor, CloseColor: TColor;
  TxtRect, TabR, CloseR: TRect;
  TxtX, TxtY: Integer;
  NeedScroll: Boolean;
  Cap: string;
  Bmp: TBitmap;
  C: TCanvas;
  BarW, BarLen, BarPos, TotalW, VisW: Integer;
begin
  if not Assigned(FTabs) then Exit;

  // Usa double-buffer para evitar flickering
  Bmp := TBitmap.Create;
  try
    Bmp.Width  := Width;
    Bmp.Height := Height;
    C := Bmp.Canvas;
    C.Font.Assign(Font);

    if IsVertical then
      NeedScroll := TotalTabsWidth > Height
    else
      NeedScroll := TotalTabsWidth > Width;
    ScrollAreaW := 0;
    if NeedScroll then ScrollAreaW := ScrollBtnW * 2;

    // Fundo
    C.Brush.Color := FColorBackground;
    C.FillRect(Rect(0, 0, Width, Height));

    // Barra de scroll indicator (mini scrollbar)
    if NeedScroll and (TotalTabsWidth > 0) then
    begin
      BarW   := 3;
      TotalW := TotalTabsWidth;
      VisW   := VisibleWidth;
      if VisW < TotalW then
      begin
        BarLen := Max(20, VisW * VisW div TotalW);
        BarPos := 0;
        if TotalW - VisW > 0 then
          BarPos := FScrollOffset * (VisW - BarLen) div (TotalW - VisW);
        C.Brush.Color := FColorAccent;
        C.Pen.Color   := FColorAccent;
        if not IsVertical then
          C.FillRect(Rect(ScrollAreaW + BarPos, Height - BarW, ScrollAreaW + BarPos + BarLen, Height))
        else
          C.FillRect(Rect(Width - BarW, ScrollAreaW + BarPos, Width, ScrollAreaW + BarPos + BarLen));
      end;
    end;

    // Desenha abas
    for i := 0 to FTabs.Count - 1 do
    begin
      Tab := FTabs[i];
      if not Tab.FVisible then Continue;

      OffX := -FScrollOffset + ScrollAreaW;

      TabR   := Tab.TabRect;
      CloseR := Tab.CloseRect;

      if not IsVertical then
      begin
        OffsetRect(TabR,   OffX, 0);
        OffsetRect(CloseR, OffX, 0);
        if TabR.Right  < ScrollAreaW            then Continue;
        if TabR.Left   > Width - ScrollAreaW    then Continue;
      end
      else
      begin
        OffsetRect(TabR,   0, OffX);
        OffsetRect(CloseR, 0, OffX);
        if TabR.Bottom < ScrollAreaW            then Continue;
        if TabR.Top    > Height - ScrollAreaW   then Continue;
      end;

      IsActive := (i = FActiveTab);
      IsHover  := (i = FHoverTab) and not IsActive;

      // Cor de fundo (individual tem prioridade)
      if IsActive then
      begin
        if Tab.FTabColorActive <> clNone then BgColor := Tab.FTabColorActive
        else                                  BgColor := FColorTabActive;
      end
      else if IsHover then
      begin
        if Tab.FTabColorHover <> clNone then BgColor := Tab.FTabColorHover
        else                                 BgColor := FColorTabHover;
      end
      else
      begin
        if Tab.FTabColor <> clNone then BgColor := Tab.FTabColor
        else                            BgColor := FColorTabInactive;
      end;

      C.Brush.Color := BgColor;
      C.Pen.Color   := BgColor;

      // Forma da aba
      case FTabShape of
        mtsRect:      PaintTabShape(C, TabR, BgColor, IsActive);
        mtsRounded:   PaintTabShape(C, TabR, BgColor, IsActive);
        mtsTrapezoid: PaintTrapezoidTab(C, TabR, BgColor, IsActive);
      end;

      // Barra de acento (aba ativa)
      if IsActive and (FAccentBarSize > 0) then
      begin
        C.Brush.Color := FColorAccent;
        C.Pen.Color   := FColorAccent;
        case FTabPosition of
          mtpTop:    C.FillRect(Rect(TabR.Left, TabR.Bottom - FAccentBarSize, TabR.Right, TabR.Bottom));
          mtpBottom: C.FillRect(Rect(TabR.Left, TabR.Top, TabR.Right, TabR.Top + FAccentBarSize));
          mtpLeft:   C.FillRect(Rect(TabR.Right - FAccentBarSize, TabR.Top, TabR.Right, TabR.Bottom));
          mtpRight:  C.FillRect(Rect(TabR.Left, TabR.Top, TabR.Left + FAccentBarSize, TabR.Bottom));
        end;
      end;

      // Separador
      if (FSepWidth > 0) and (i < FTabs.Count - 1) then
      begin
        C.Brush.Color := FColorSeparator;
        C.Pen.Color   := FColorSeparator;
        if not IsVertical then
          C.FillRect(Rect(TabR.Right, TabR.Top + 4, TabR.Right + FSepWidth, TabR.Bottom - 4))
        else
          C.FillRect(Rect(TabR.Left + 4, TabR.Bottom, TabR.Right - 4, TabR.Bottom + FSepWidth));
      end;

      // Cor/estilo da fonte (individual tem prioridade)
      if Tab.FFontColor <> clNone then
        TxtColor := Tab.FFontColor
      else if IsActive then
        TxtColor := FColorTextActive
      else
        TxtColor := FColorTextInactive;

      C.Font.Color := TxtColor;
      if Tab.FFontStyle <> [] then
        C.Font.Style := Tab.FFontStyle
      else
        C.Font.Style := Font.Style;
      C.Brush.Style := bsClear;

      // Área de texto
      TxtRect := TabR;
      TxtX    := TabR.Left + 12;
      if FTabShape = mtsTrapezoid then
        TxtX := TxtX + FTrapezoidSlant;

      // Ícone
      PaintIcon(C, TabR, Tab.FImageIndex, TxtX);

      // Caption com prefixo pinned
      Cap := Tab.DisplayCaption;
      if Tab.FPinned and (FPinnedText <> '') then
        Cap := FPinnedText + Cap;

      TxtRect.Left  := TxtX;
      TxtRect.Right := CloseR.Left - 4;
      if not IsCloseVisible(i) then
        TxtRect.Right := TabR.Right - 8;

      TxtY := TabR.Top + (FTabHeight - C.TextHeight(Cap)) div 2;

      if not IsVertical then
        C.TextRect(TxtRect, TxtX, TxtY, Cap)
      else
      begin
        // Para abas verticais, rotaciona o texto
        C.Font.Orientation := 900; // 90 graus anti-horário
        C.TextOut(TabR.Left + (FTabHeight - C.TextHeight(Cap)) div 2,
                  TabR.Bottom - 8, Cap);
        C.Font.Orientation := 0;
      end;

      C.Brush.Style := bsSolid;
      C.Font.Style  := Font.Style;

      // Botão fechar
      if IsCloseVisible(i) then
      begin
        if i = FHoverClose then       CloseColor := FColorCloseHover
        else if IsActive then          CloseColor := FColorClose
        else                           CloseColor := $00555555;

        PaintCloseButton(C, CloseR, CloseColor, Tab.FModified);
      end;
    end;

    // Botões de scroll
    PaintScrollButtons(C, NeedScroll, ScrollAreaW);

    // Copia buffer para canvas real
    Canvas.Draw(0, 0, Bmp);
  finally
    Bmp.Free;
  end;
end;

// --- Mouse --------------------------------------------------------------------

procedure TModernTabControl.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  NewHoverTab, NewHoverClose: Integer;
  NeedScroll: Boolean;
  AdjX, AdjY: Integer;
  NewHoverSL, NewHoverSR: Boolean;
  MainSize: Integer;
begin
  MainSize   := IfThen(IsVertical, Height, Width);
  NeedScroll := TotalTabsWidth > MainSize;

  NewHoverSL := NeedScroll and PointInRect(FScrollLeftRect,  Point(X, Y));
  NewHoverSR := NeedScroll and PointInRect(FScrollRightRect, Point(X, Y));

  // Arrastar
  if FDragging and (FDragTab >= 0) then
  begin
    AdjX := X + FScrollOffset - IfThen(NeedScroll, 24, 0);
    AdjY := Y + FScrollOffset - IfThen(NeedScroll, 24, 0);
    if IsVertical then
      NewHoverTab := FindTabAt(AdjX, AdjY)
    else
      NewHoverTab := FindTabAt(AdjX, Y);
    if (NewHoverTab >= 0) and (NewHoverTab <> FDragTab) then
      MoveTab(FDragTab, NewHoverTab);
    FDragTab := FActiveTab;
    inherited;
    Exit;
  end;

  AdjX := X + FScrollOffset - IfThen(NeedScroll, 24, 0);
  AdjY := Y + FScrollOffset - IfThen(NeedScroll, 24, 0);

  if IsVertical then
    NewHoverClose := FindCloseAt(X, AdjY)
  else
    NewHoverClose := FindCloseAt(AdjX, Y);

  if NewHoverClose >= 0 then
    NewHoverTab := NewHoverClose
  else
  begin
    if IsVertical then
      NewHoverTab := FindTabAt(X, AdjY)
    else
      NewHoverTab := FindTabAt(AdjX, Y);
  end;

  if (NewHoverTab <> FHoverTab) or (NewHoverClose <> FHoverClose)
  or (NewHoverSL <> FHoverScrollLeft) or (NewHoverSR <> FHoverScrollRight) then
  begin
    FHoverTab         := NewHoverTab;
    FHoverClose       := NewHoverClose;
    FHoverScrollLeft  := NewHoverSL;
    FHoverScrollRight := NewHoverSR;
    Invalidate;
  end;

  if (NewHoverTab >= 0) and (NewHoverClose < 0) then
    ShowTabHint(NewHoverTab)
  else
    HideHint;

  inherited;
end;

procedure TModernTabControl.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  CloseIdx, TabIdx: Integer;
  CanClose:   Boolean;
  NeedScroll: Boolean;
  AdjX, AdjY: Integer;
  MainSize:   Integer;
begin
  if Button = mbLeft then
  begin
    MainSize   := IfThen(IsVertical, Height, Width);
    NeedScroll := TotalTabsWidth > MainSize;

    if NeedScroll and PointInRect(FScrollLeftRect, Point(X, Y)) then
    begin ScrollLeft; Exit; end;

    if NeedScroll and PointInRect(FScrollRightRect, Point(X, Y)) then
    begin ScrollRight; Exit; end;

    AdjX := X + FScrollOffset - IfThen(NeedScroll, 24, 0);
    AdjY := Y + FScrollOffset - IfThen(NeedScroll, 24, 0);

    if IsVertical then
    begin
      CloseIdx := FindCloseAt(X, AdjY);
      if CloseIdx < 0 then
        TabIdx := FindTabAt(X, AdjY)
      else
        TabIdx := -1;
    end
    else
    begin
      CloseIdx := FindCloseAt(AdjX, Y);
      if CloseIdx < 0 then
        TabIdx := FindTabAt(AdjX, Y)
      else
        TabIdx := -1;
    end;

    if CloseIdx >= 0 then
    begin
      // Aba fixada não pode ser fechada
      if FTabs[CloseIdx].FPinned then Exit;
      CanClose := True;
      if Assigned(FOnCloseTab) then
        FOnCloseTab(Self, CloseIdx, CanClose);
      if CanClose then
        DeleteTab(CloseIdx);
    end
    else if TabIdx >= 0 then
    begin
      SetActiveTab(TabIdx);
      if not FTabs[TabIdx].FPinned then
      begin
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

// --- Find ---------------------------------------------------------------------

function TModernTabControl.FindTabAt(X, Y: Integer): Integer;
var
  i: Integer;
begin
  Result := -1;
  if not Assigned(FTabs) then Exit;
  for i := 0 to FTabs.Count - 1 do
    if FTabs[i].FVisible and PointInRect(FTabs[i].TabRect, Point(X, Y)) then
    begin Result := i; Exit; end;
end;

function TModernTabControl.FindCloseAt(X, Y: Integer): Integer;
var
  i: Integer;
begin
  Result := -1;
  if not Assigned(FTabs) then Exit;
  for i := 0 to FTabs.Count - 1 do
    if FTabs[i].FVisible and IsCloseVisible(i) and
       PointInRect(FTabs[i].CloseRect, Point(X, Y)) then
    begin Result := i; Exit; end;
end;

initialization
  {$I ModernTabControl.lrs}

end.
