program Viewer;

uses
  Vcl.Forms,
  UViewerMain in 'UViewerMain.pas' {MainForm},
  UJSON in 'UJSON.pas',
  UHTML in 'UHTML.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
