unit RULEBASE;
{$IFDEF WIN32}
  {$R RULEBASE.D32}
{$ELSE}
  {$R RULEBASE.D16}
{$ENDIF}
interface
uses
  Classes, Forms, ExtCtrls, DB, DBTables, DBCtrls, Grids, DBGrids, SysUtils;

Type
  TBaseForm = class(TForm)
    Table1: TTable;
    DataSource1: TDataSource;
    Panel1: TPanel;
    DBNavigator1: TDBNavigator;
    DBGrid1: TDBGrid;
    procedure FormShow(Sender: TObject);
  end;

{$IFNDEF WIN32}
Type
  ShortString = String;
{$ENDIF}

Const
  MaxFact = High(Byte);
  MaxRule = High(Byte);

Type
  TName32 = String[32];
  TValue = ShortString;

Type
  TFact = class(TObject)
  private
    FFact: Integer;
    FGoal: Boolean;
    FName: TName32;
    FValue: TValue;
    FQuestion: ShortString;
  protected
    constructor Create(Table: TTable); virtual;
  public
    property Fact: Integer read FFact;
    property Goal: Boolean read FGoal;
    property Name: TName32 read FName;
    property Value: TValue read FValue write FValue;
    property Question: ShortString read FQuestion;
  end {TFact};

  TFactBase = class(TComponent)
  private
    FActive: Boolean;
    FFactBase: TFileName;
    FNumFact: Integer;
  protected
    FactTable: TTable;
    Facts: Array[0..MaxFact] of TFact;
  protected
    procedure SetFactBase(NewFactBase: TFileName);
    procedure SetActive(NewActive: Boolean);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  public
    procedure Open; virtual;
    procedure Close; virtual;
  public
    procedure NewFactBase;
    procedure Reset;
  published
    property Active: Boolean read FActive write SetActive;
    property FactBase: TFileName read FFactBase write SetFactBase;
    property NumFact: Integer read FNumFact;
  end {TFactBase};

Type
  TRule = class(TObject)
  private
    FRule: Integer;
    FCF:  SmallInt;
    FFact: Integer;
    FValue: TValue;
    FComments: ShortString;
  protected
    FFired: Boolean;
    constructor Create(Table: TTable); virtual;
  public
    property Rule: Integer read FRule;
    property CF:  SmallInt read FCF;
    property Fact: Integer read FFact;
    property Value: TValue read FValue;
    property Fired: Boolean read FFired write FFired;
    property Comments: ShortString read FComments;
  end {TRule};

  TRuleBase = class(TComponent)
  private
    FActive: Boolean;
    FRuleBase: TFileName;
    FFactBase: TFactBase;
    FNumRule: Integer;
  protected
    RuleMax: Integer;
    RuleTable: TTable;
    Rules: Array[0..MaxRule] of TRule;
  protected
    procedure SetFactBase(NewFactBase: TFactBase);
    procedure SetRuleBase(NewRuleBase: TFileName);
    procedure SetActive(NewActive: Boolean);
  protected
    function TestRule(RuleNr: Integer): Boolean;
    procedure FireRule(RuleNr: Integer);
    function Conclude(RuleNr, FactNr: Integer): Boolean;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  public
    procedure Open; virtual;
    procedure Close; virtual;
  public
    procedure NewRuleBase;
    procedure Reset;
  public
    function Forwards: Integer;
    procedure Backwards(Goal: Integer);
  published
    property Active: Boolean read FActive write SetActive;
    property NumRule: Integer read FNumRule;
    property RuleBase: TFileName read FRuleBase write SetRuleBase;
    property FactBase: TFactBase read FFactBase write SetFactBase;
  end {TRuleBase};

  procedure Register;

implementation
{$R *.DFM}
uses
  Controls, Dialogs, DsgnIntf;

procedure TBaseForm.FormShow(Sender: TObject);
begin
  Table1.Open
end;

{ TFact }

  constructor TFact.Create(Table: TTable);
  begin
    inherited Create;
    with Table do
    begin
      FFact := FieldByName('Fact').AsInteger;
      FGoal := FieldByName('Goal').AsBoolean;
      FName := FieldByName('Name').AsString;
      FValue := 'unknown';
      FQuestion := FieldByName('Question').AsString
    end
  end {Create};

{ TFactBase }

  constructor TFactBase.Create(AOwner: TComponent);
  begin
    inherited Create(AOwner);
    FactTable := TTable.Create(Self)
  end {Create};

  destructor TFactBase.Destroy;
  begin
    Close;
    FactTable.Free;
    FactTable := nil;
    inherited Destroy
  end {Destroy};

  procedure TFactBase.SetFactBase(NewFactBase: TFileName);
  begin
    if NewFactBase <> FFactBase then
    begin
      Close;
      FactTable.DataBaseName := ExtractFilePath(NewFactBase);
      FactTable.TableName := ExtractFileName(NewFactBase);
      FFactBase := NewFactBase
    end
  end {SetFactBase};

  procedure TFactBase.SetActive(NewActive: Boolean);
  var i: Integer;
  begin
    if not (csReading in ComponentState) then { skip loading }
    if NewActive <> FActive then
    begin
      if NewActive then
      begin
        FactTable.Open;
        FactTable.First;
        while not FactTable.Eof do
        begin
          if FactTable.FieldByName('Fact').AsInteger <> FNumFact then
            raise Exception.Create('Error: facts are not sorted...');
          Facts[FNumFact] := TFact.Create(FactTable);
          FactTable.Next;
          Inc(FNumFact)
        end;
        FActive := True
      end
      else { Close }
      begin
        FactTable.Close;
        for i:=0 to Pred(FNumFact) do
        begin
          Facts[i].Free;
          Facts[i] := nil
        end;
        FNumFact := 0;
        FActive := False
      end
    end
  end {SetActive};

  procedure TFactBase.Open;
  begin
    Active := True
  end {Open};

  procedure TFactBase.Close;
  begin
    Active := False
  end {Close};

  procedure TFactBase.NewFactBase;
  begin
    with FactTable do
    begin
      Active := False;
      TableType := ttParadox;
      TableName := FFactBase;
      with FieldDefs do
      begin
        Clear;
        Add('Fact', ftInteger, 0, TRUE);
        Add('Goal', ftBoolean, 0, TRUE);
        Add('Name', ftString, 32, TRUE);
        Add('Question', ftString, 255, FALSE)
      end;
      with IndexDefs do
      begin
        Clear;
        Add('index', 'Fact', [ixPrimary,ixUnique])
      end;
      CreateTable
    end
  end {CreateFACTS};

  procedure TFactBase.Reset;
  var i: Integer;
  begin
    for i:=0 to MaxFact do
      if Facts[i] <> nil then Facts[i].Value := 'unknown'
  end {Reset};

{ TRule }

  constructor TRule.Create(Table: TTable);
  begin
    inherited Create;
    with Table do
    begin
      FRule := FieldByName('Rule').AsInteger;
      FCF := FieldByName('CF').AsInteger;
      FFact := FieldByName('Fact').AsInteger;
      FValue := FieldByName('Value').AsString;
      FComments := FieldByName('Comments').AsString
    end
  end {Create};

{ TRuleBase }

  constructor TRuleBase.Create(AOwner: TComponent);
  begin
    inherited Create(AOwner);
    RuleTable := TTable.Create(Self)
  end {Create};

  destructor TRuleBase.Destroy;
  begin
    Close;
    RuleTable.Free;
    RuleTable := nil;
    inherited Destroy
  end {Destroy};

  procedure TRuleBase.SetFactBase(NewFactBase: TFactBase);
  begin
    FFactBase := NewFactBase
  end {SetFactBase};

  procedure TRuleBase.SetRuleBase(NewRuleBase: TFileName);
  begin
    if NewRuleBase <> FRuleBase then
    begin
      Close;
      RuleTable.DataBaseName := ExtractFilePath(NewRuleBase);
      RuleTable.TableName := ExtractFileName(NewRuleBase);
      FRuleBase := NewRuleBase
    end
  end {SetRuleBase};

  procedure TRuleBase.SetActive(NewActive: Boolean);
  var i: Integer;
  begin
    if not (csReading in ComponentState) then { skip loading }
    if NewActive <> FActive then
    begin
      if NewActive then
      begin
        RuleTable.Open;
        RuleTable.First;
        while not RuleTable.Eof do
        begin
          Rules[FNumRule] := TRule.Create(RuleTable);
          if Rules[FNumRule].Rule > RuleMax then
            RuleMax := Rules[FNumRule].Rule;
          RuleTable.Next;
          Inc(FNumRule)
        end;
        FActive := True
      end
      else { Close }
      begin
        RuleTable.Close;
        for i:=0 to MaxRule do
        begin
          Rules[i].Free;
          Rules[i] := nil
        end;
        FNumRule := 0;
        FActive := False
      end
    end
  end {SetActive};

  procedure TRuleBase.Open;
  begin
    Active := True
  end {Open};

  procedure TRuleBase.Close;
  begin
    Active := False
  end {Close};

  procedure TRuleBase.NewRuleBase;
  begin
    with RuleTable do
    begin
      Active := False;
      TableType := ttParadox;
      TableName := FRuleBase;
      with FieldDefs do
      begin
        Clear;
        Add('Rule', ftInteger, 0, TRUE);
        Add('CF',  ftSmallInt, 0, TRUE);
        Add('Fact', ftInteger, 0, TRUE);
        Add('Value', ftString, 255, FALSE);
        Add('Comments', ftString, 255, FALSE)
      end;
      with IndexDefs do
      begin
        Clear;
        Add('index', 'Rule;CF;Fact', [ixPrimary,ixUnique])
      end;
      CreateTable
    end
  end {CreateRULES};

  procedure TRuleBase.Reset;
  var i: Integer;
  begin
    if FFactBase <> nil then FFactBase.Reset;
    for i:=0 to MaxRule do
      if Rules[i] <> nil then Rules[i].Fired := False
  end {Reset};

  function TRuleBase.TestRule(RuleNr: Integer): Boolean;
  var i: Integer;
  begin
    Result := True;
    for i:=0 to Pred(FNumRule) do
      if (Rules[i].Rule = RuleNr) and (Rules[i].CF = 0) then { check }
        Result := Result AND
          (FFactBase.Facts[Rules[i].Fact].Value = Rules[i].Value)
         { NOTE: we need to compare two strings case-insensitive here... }
  end {TestRule};

  procedure TRuleBase.FireRule(RuleNr: Integer);
  var i: Integer;
  begin
    for i:=0 to Pred(FNumRule) do
      if (Rules[i].Rule = RuleNr) and
         (Rules[i].CF > 0) and not Rules[i].Fired then { fire }
      begin
        FFactBase.Facts[Rules[i].Fact].Value := Rules[i].Value;
        Rules[i].FFired := True
      end
  end {FireRule};

  function TRuleBase.Conclude(RuleNr, FactNr: Integer): Boolean;
  var i: Integer;
  begin
    Result := False;
    for i:=0 to Pred(FNumRule) do
      if (Rules[i].Rule = RuleNr) and
         (Rules[i].Fact = FactNr) and
         (Rules[i].CF > 0) then Result := True { rule can be used }
  end {Conclude};

  function TRuleBase.Forwards: Integer;
  var
    RulesFired,i: Integer;
  begin
    if (FFactBase = nil) then raise Exception.Create('no FactBase');
    if not FFactBase.Active then raise Exception.Create('FactBase not open');
    if not Active then raise Exception.Create('RuleBase not open');
    Result := 0;
    RulesFired := NumRule;
    while (Result = 0) and (RulesFired > 0) do
    begin
      RulesFired := 0;
      for i:=0 to RuleMax do { all rules }
      begin
        if TestRule(i) then
        begin
          FireRule(i);
          Inc(RulesFired)
        end
      end;
      Result := FFactBase.NumFact;
      while (Result > 0) and
            ((not FFactBase.Facts[Result].Goal) or
             ((FFactBase.Facts[Result].Goal) and
              (FFactBase.Facts[Result].Value = 'unknown'))) do Dec(Result)
    end
  end {Forwards};

  procedure TRuleBase.Backwards(Goal: Integer);
  Const Depth: Word = 0;
  var i,j: Integer;
  begin
    if (FFactBase = nil) then raise Exception.Create('no FactBase');
    if not FFactBase.Active then raise Exception.Create('FactBase not open');
    if not Active then raise Exception.Create('RuleBase not open');
    Inc(Depth);
    writeln(' ':Depth,Goal);
    i := 0;
    while i <= RuleMax do { all rules }
    begin
      if Conclude(i,Goal) then
      begin
        if TestRule(i) then FireRule(i)
        else { infer or ask }
        begin
          j := 0;
          while j < NumRule do
          begin
            if (Rules[j].Rule = i) and (Rules[j].CF = 0) and
               (FFactBase.Facts[Rules[j].Fact].Value = 'unknown') then
            begin
              Backwards(Rules[j].Fact); { infer }
              if TestRule(i) then j := NumRule
              else { ask }
              begin
                if FFactBase.Facts[Rules[j].Fact].Question <> '' then
                begin
                  writeln(' ':Depth,FFactBase.Facts[Rules[j].Fact].Question);
                  if MessageDlg(FFactBase.Facts[Rules[j].Fact].Question,
                                 mtConfirmation,[mbYes,mbNo],0) = mrYes then
                    FFactBase.Facts[Rules[j].Fact].Value := 'Yes'
                  else
                    FFactBase.Facts[Rules[j].Fact].Value := 'No'
                end;
                if TestRule(i) then j := NumRule
              end
            end;
            Inc(j)
          end;
          if TestRule(i) then
          begin
            FireRule(i);
            i := RuleMax
          end
        end
      end;
      Inc(i)
    end;
    Dec(Depth);
    if Depth = 0 then { final goal proven? }
    begin
      writeln;
      writeln(FFactBase.Facts[Goal].Name,': ',
              FFactBase.Facts[Goal].Value);
      ShowMessage(FFactBase.Facts[Goal].Name + #13 +
                  FFactBase.Facts[Goal].Value)
    end
  end {Backwards};

{ TFileNameProperty }

Type
  TFileNameProperty = class(TStringProperty)
  public
    function GetAttributes: TPropertyAttributes; override;
    procedure Edit; override;
  end;

  function TFileNameProperty.GetAttributes: TPropertyAttributes;
  begin
    Result := [paDialog]
  end {GetAttributes};

  procedure TFileNameProperty.Edit;
  begin
    with TOpenDialog.Create(nil) do
    try
      Title := GetName; { name of property as OpenDialog caption }
      Filename := GetValue;
      Filter := 'DB Files (*.DB)|*.DB';
      HelpContext := 0;
      Options := Options + [ofShowHelp, ofPathMustExist, ofFileMustExist];
      if Execute then SetValue(Filename)
    finally
      Free
    end
  end {Edit};

{ TFactBaseProperty }

Type
  TFactBaseProperty = class(TComponentProperty)
  public
    function GetAttributes: TPropertyAttributes; override;
    procedure GetValues(Proc: TGetStrProc); override;
  end;

  function TFactBaseProperty.GetAttributes: TPropertyAttributes;
  begin
    Result := [paValueList]
  end {GetAttributes};

(*
  procedure TFactBaseProperty.GetValues(Proc: TGetStrProc);
  var i: Integer;
      Component: TComponent;
  begin
    for i:=0 to Pred(Designer.Form.ComponentCount) do
    begin
      Component := Designer.Form.Components[i];
      if (Component IS TFactBase) and (Component.Name <> '') then
        Proc(Component.Name)
    end
  end {GetValues};
*)

  procedure TFactBaseProperty.GetValues(Proc: TGetStrProc);
  var i: Integer;
  begin
    with Designer.Form do
    begin
      for i:=0 to Pred(ComponentCount) do
      begin
        if (Components[i] IS TFactBase) and (Components[i].Name <> '') then
          Proc(Components[i].Name)
      end
    end
  end {GetValues};

{ TFactBaseComponentEditor }

Type
  TFactBaseComponentEditor = class(TComponentEditor)
  public
    procedure Edit; override;
  end;

  procedure TFactBaseComponentEditor.Edit;
  begin
    with TBaseForm.Create(nil) do
    try
      Caption := 'FactBase '+(Component AS TFactBase).FactBase;
      Table1.DataBaseName := (Component AS TFactBase).FactTable.DataBaseName;
      Table1.TableName := (Component AS TFactBase).FactTable.TableName;
      ShowModal
    finally
      Free
    end
  end {Edit};

{ TRuleBaseComponentEditor }

Type
  TRuleBaseComponentEditor = class(TComponentEditor)
  public
    procedure Edit; override;
  end;

  procedure TRuleBaseComponentEditor.Edit;
  begin
    with TBaseForm.Create(nil) do
    try
      Caption := 'RuleBase '+(Component AS TRuleBase).RuleBase;
      Table1.DataBaseName := (Component AS TRuleBase).RuleTable.DataBaseName;
      Table1.TableName := (Component AS TRuleBase).RuleTable.TableName;
      ShowModal
    finally
      Free
    end
  end {Edit};

{ register }

  procedure Register;
  begin
    RegisterComponents('Dr.Bob', [TFactBase, TRuleBase]);
    RegisterPropertyEditor(TypeInfo(TFileName), TFactBase, 'FactBase', TFileNameProperty);
    RegisterPropertyEditor(TypeInfo(TFileName), TRuleBase, 'RuleBase', TFileNameProperty);
    RegisterPropertyEditor(TypeInfo(TFactBase), TRuleBase, 'FactBase', TFactBaseProperty);
    RegisterComponentEditor(TFactBase, TFactBaseComponentEditor);
    RegisterComponentEditor(TRuleBase, TRuleBaseComponentEditor)
  end;
end.
