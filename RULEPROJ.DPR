program ruleproj;
{$APPTYPE CONSOLE}
uses
  Forms,
  ruledemo in 'ruledemo.pas' {Form1};

{$R *.RES}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
