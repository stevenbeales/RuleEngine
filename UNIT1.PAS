unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  RULEBASE, ExtCtrls;

type
  TForm1 = class(TForm)
    FactBase1: TFactBase;
    RuleBase1: TRuleBase;
    Image1: TImage;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.DFM}

end.
