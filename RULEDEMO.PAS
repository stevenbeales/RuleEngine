unit ruledemo;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  RULEBASE, StdCtrls;

type
  TForm1 = class(TForm)
    FactBase1: TFactBase;
    RuleBase1: TRuleBase;
    Button1: TButton;
    procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.DFM}

procedure TForm1.Button1Click(Sender: TObject);
begin
  RuleBase1.Reset;
  RuleBase1.Backwards(0)
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  FactBase1.Open;
  RuleBase1.Open
end;

end.
