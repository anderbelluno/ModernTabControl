# ModernTabControl

Um componente de abas totalmente customizável para **Lazarus / Free Pascal**, com visual moderno, suporte a temas escuros e integração nativa com `TNotebook`.

---

## Visão geral

`TModernTabControl` é um substituto direto ao `TPageControl` padrão do LCL, desenhado do zero com renderização própria via `TCustomControl`. Cada detalhe visual — cores, separadores, barra de acento, botão de fechar — é configurável por propriedades `published`, sem necessidade de subclasses ou hacks.

---

## Funcionalidades

| Recurso | Detalhe |
|---|---|
| **Paleta de cores completa** | 10 propriedades de cor expostas no Object Inspector |
| **Barra de acento** | Indicador colorido na aba ativa |
| **Botão fechar por aba** | Com highlight ao passar o mouse |
| **Drag & drop** | Reordene abas arrastando |
| **Scroll horizontal** | Botões `<` `>` aparecem automaticamente quando necessário |
| **Tooltips por aba** | `THintWindow` nativo, definido por aba via `SetTabHint` |
| **Integração com TNotebook** | Sincronização automática de páginas e índice ativo |
| **Separadores configuráveis** | Espessura e cor do separador entre abas |

---

## Propriedades

### Comportamento

| Propriedade | Tipo | Padrão | Descrição |
|---|---|---|---|
| `NoteBook` | `TNotebook` | `nil` | Notebook sincronizado com as abas |
| `ActiveTab` | `Integer` | `-1` | Índice da aba ativa |
| `TabHeight` | `Integer` | `36` | Altura da barra de abas em pixels |
| `SepWidth` | `Integer` | `1` | Largura do separador entre abas (0 = sem separador) |

### Cores

| Propriedade | Padrão (Dark) | Descrição |
|---|---|---|
| `ColorBackground` | `#202020` | Fundo da barra de abas |
| `ColorTabInactive` | `#2D2D2D` | Fundo de aba inativa |
| `ColorTabHover` | `#383838` | Fundo de aba com hover |
| `ColorTabActive` | `#424242` | Fundo de aba ativa |
| `ColorAccent` | `#CF6E27` | Barra de acento na aba ativa |
| `ColorTextInactive` | `#AAAAAA` | Texto de aba inativa |
| `ColorTextActive` | `#FFFFFF` | Texto de aba ativa |
| `ColorClose` | `#777777` | Ícone X da aba ativa |
| `ColorCloseHover` | `#0055FF` | Ícone X com hover |
| `ColorSeparator` | `#444444` | Separador entre abas |

---

## Eventos

| Evento | Assinatura | Descrição |
|---|---|---|
| `OnChange` | `TNotifyEvent` | Disparado ao trocar a aba ativa |
| `OnCloseTab` | `(Sender; TabIndex; var CanClose)` | Permite cancelar o fechamento de uma aba |
| `OnMoveTab` | `(Sender; OldIndex, NewIndex)` | Disparado ao reordenar abas por drag |
| `OnAddTab` | `TNotifyEvent` | Disparado ao clicar no botão `+` |

---

## API pública

```pascal
// Adiciona uma aba (retorna o índice)
function AddTab(const ACaption: string; const AHint: string = ''): Integer;

// Remove a aba no índice especificado
procedure DeleteTab(Index: Integer);

// Remove todas as abas
procedure Clear;

// Define o tooltip de uma aba específica
procedure SetTabHint(Index: Integer; const AHint: string);

// Acesso às abas individuais
property Tabs[Index: Integer]: TModernTab;  // read-only
property TabCount: Integer;                  // read-only
```

---

## Instalação

1. Abra o Lazarus e vá em **Package → Open Package File (.lpk)**
2. Selecione `ModernTabControl/moderncontrols.lpk`
3. Clique em **Compile** e depois em **Use → Install**
4. Confirme a recompilação do IDE
5. O componente aparecerá na paleta **Modern**

---

## Uso básico

1. Adicione um `TNotebook` ao formulário
2. Adicione um `TModernTabControl` e defina `Align = alTop`
3. Aponte a propriedade `NoteBook` para o `TNotebook`
4. As abas são sincronizadas automaticamente com as páginas do Notebook

```pascal
// Adicionando abas em runtime
ModernTabControl1.AddTab('Geral');
ModernTabControl1.AddTab('Configurações', 'Ajuste as preferências do sistema');
ModernTabControl1.AddTab('Sobre');

// Tema claro em runtime
ModernTabControl1.ColorBackground   := clWhite;
ModernTabControl1.ColorTabInactive  := $00F0F0F0;
ModernTabControl1.ColorTabActive    := clWhite;
ModernTabControl1.ColorTextInactive := clGray;
ModernTabControl1.ColorTextActive   := clBlack;
ModernTabControl1.ColorAccent       := clBlue;
```

---

## Requisitos

- Lazarus 2.x ou superior
- Free Pascal 3.x ou superior
- Plataformas: Windows, Linux, macOS (via LCL)

---

## Licença

MIT — use, modifique e distribua livremente.
