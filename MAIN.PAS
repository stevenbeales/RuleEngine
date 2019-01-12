{$IFDEF WIN32}
  {$APPTYPE CONSOLE}
  uses
    RuleBase;
{$ELSE}
  uses
    WinCrt, RuleBase;
{$ENDIF}

var FactBase1: TFactBase;
    RuleBase1: TRuleBase;
begin
  FactBase1 := TFactBase.Create(nil);
  FactBase1.FactBase := 'FACTS.DB';
  FactBase1.Open;
  RuleBase1 := TRuleBase.Create(nil);
  RuleBase1.RuleBase := 'RULES.DB';
  RuleBase1.Open;
  RuleBase1.FactBase := FactBase1;
  RuleBase1.Backwards(0)
end.
